#!/bin/sh

# Wait infinitely for Vault to be ready
while true; do
  for NODE in $VAULT_NODES; do
    echo "Trying to connect to \"$NODE\"..."
    if curl -fs -k --cacert /vault/ssl/ca.crt https://$NODE:8200/v1/sys/health; then
      echo "$NODE is reachable."
    else
      echo "$NODE is not reachable. Retrying..."
      continue
    fi
    # Check if the node is initialized and unsealed
    if curl -fs -k --cacert /vault/ssl/ca.crt https://$NODE:8200/v1/sys/health | grep -q '"sealed":false'; then
      echo "$NODE is unsealed."
    else
      echo "$NODE is sealed. Retrying..."
      continue
    fi
    # Check if the node is active
    if curl -fs -k --cacert /vault/ssl/ca.crt https://$NODE:8200/v1/sys/health | grep -q '"standby":false'; then
      echo "$NODE is active."
    else
      echo "$NODE is standby. Retrying..."
      continue
    fi
    if [ -f "/vault/token/grafana/grafana-token" ]; then
      VAULT_TOKEN=$(cat /vault/token/grafana/grafana-token)
      if curl -fs -k -H "X-Vault-Token: $VAULT_TOKEN" --cacert /vault/ssl/ca.crt https://$NODE:8200/v1/secret/data/ft_wheel/database | grep -q '"data"'; then
        echo "$NODE is ready and secrets are configured. Proceeding with startup."
        VAULT_ADDR="https://$NODE:8200"
        break
      else
        echo "$NODE is ready but secrets are not configured. Retrying..."
        continue
      fi
    fi
  done
  echo "VAULT ADDR: $VAULT_ADDR"
  if [ -n "$VAULT_ADDR" ]; then
    break
  fi
  sleep 10
done

if [ -z "$VAULT_ADDR" ]; then
  echo "ERROR: No Vault node is available!"
  exit 1
fi

SECRETS=$(curl -s -k -H "X-Vault-Token: $VAULT_TOKEN" --cacert /vault/ssl/ca.crt $VAULT_ADDR/v1/secret/data/ft_wheel/database | jq -r '.data.data')
export GRAFANA_ADMIN_PASSWORD=$(echo $SECRETS | jq -r '.GRAFANA_ADMIN_PASSWORD')
export GRAFANA_USER_USERNAME=$(echo $SECRETS | jq -r '.GRAFANA_USER_USERNAME')
export GRAFANA_USER_PASSWORD=$(echo $SECRETS | jq -r '.GRAFANA_USER_PASSWORD')

# Execute main entrypoint
sh /run.sh &
GRAFANA_PID=$!

# Wait for Grafana to be ready
while ! curl -s "localhost:3000/api/health" | grep -q '"database": "ok"'; do
  echo "Waiting for Grafana to be up..."
  sleep 2
done

echo "--------------------------------"
echo "Changing admin password"
echo "--------------------------------"
grafana-cli admin reset-admin-password "$GRAFANA_ADMIN_PASSWORD"

echo "--------------------------------"
echo "Creating user $GRAFANA_USER_USERNAME"
echo "--------------------------------"
# Create a new user with GRANFANA_USER_USERNAME and GRAFANA_USER_PASSWORD

REPONSE=$(curl -s -X POST "http://admin:$GRAFANA_ADMIN_PASSWORD@localhost:3000/api/admin/users" \
  -H "Content-Type: application/json" \
  -d '{
    "login": "'"$GRAFANA_USER_USERNAME"'",
    "email": "'"$GRAFANA_USER_USERNAME"'@example.com",
    "name": "'"$GRAFANA_USER_USERNAME"'",
    "password": "'"$GRAFANA_USER_PASSWORD"'"
  }')

echo "--------------------------------"
echo "User created: $REPONSE"
echo "--------------------------------"

# Wait for Grafana process to exit
wait $GRAFANA_PID
