#!/bin/bash

export VAULT_ADDR=https://vault_1:8200
export VAULT_CACERT=/vault/ssl/ca.crt


echo "Entering Vault 1 startup script"


check_vault_initialized() {
    vault status -format=json | jq -r '.initialized' 2>/dev/null
}


check_vault_sealed() {
    vault status -format=json | jq -r '.sealed' 2>/dev/null
}


start_vault() {
    local config_file="/vault/config/vault_1.hcl"
    local log_file="/vault/logs/vault_1.log"
    echo "[vault_1] Starting Vault server..."
    vault server -log-level=info -config="$config_file" > "$log_file" 2>&1 &
    VAULT_PID=$!
    sleep 5
}


start_vault


# Wait for Vault API to be up (accept 501 Not Implemented as "up but not initialized")
echo "[vault_1] Waiting for Vault API to be up..."
until curl -fsk --cacert /vault/ssl/ca.crt https://vault_1:8200/v1/sys/health || \
      curl -fsk -o /dev/null -w "%{http_code}" --cacert /vault/ssl/ca.crt https://vault_1:8200/v1/sys/health | grep -E '200|429|501|503'; do
    sleep 2
done


# Vault initialization
######################
if [ "$(check_vault_initialized)" = "false" ]; then


    # Create directories for tokens and logs
    ###################################################
    echo "[vault_1] Vault not initialized. Initializing..."
    vault operator init -key-shares=1 -key-threshold=1 -format=json > /vault/token/init1.json
    chmod 600 /vault/token/init1.json
    jq -r '.unseal_keys_b64[0]' /vault/token/init1.json > /vault/token/unseal_key-vault_1
    jq -r '.root_token' /vault/token/init1.json > /vault/token/root_token-vault_1
    chmod 600 /vault/token/unseal_key-vault_1 /vault/token/root_token-vault_1
    export VAULT_TOKEN=$(cat /vault/token/root_token-vault_1)
    UNSEAL_KEY=$(cat /vault/token/unseal_key-vault_1)
    for i in {1..5}; do
        vault operator unseal "$UNSEAL_KEY" && break
        echo "[vault_1] Unseal attempt $i failed, retrying..."
        sleep 2
    done
    echo "[vault_1] Vault initialized and unsealed."
    ###################################################


   sleep 5 


    # Enable KV v2 secrets engine
    ###################################################
    echo "[vault_1] Enabling KV v2 secrets engine..."
    if curl -s --cacert $VAULT_CACERT -H "X-Vault-Token: $VAULT_TOKEN" $VAULT_ADDR/v1/sys/mounts | jq -e '.data."secret/" == null' > /dev/null; then
        curl -s -o /dev/null --cacert $VAULT_CACERT -H "X-Vault-Token: $VAULT_TOKEN" -X POST -d '{"type":"kv", "options": {"version": "2"}}' $VAULT_ADDR/v1/sys/mounts/secret
        echo "KV v2 secrets engine enabled at path 'secret'"
    else
        echo "KV secrets engine already exists at path 'secret'"
    fi
    ###################################################


    # Setting Grafana's secrets
    ###################################################
    echo "[vault_1] Setting Grafana's secrets..."
    if ! curl -s --cacert $VAULT_CACERT -H "X-Vault-Token: $VAULT_TOKEN" $VAULT_ADDR/v1/sys/mounts | jq -e '.data."secret/"' > /dev/null 2>&1; then
        curl -s -o /dev/null --cacert $VAULT_CACERT -H "X-Vault-Token: $VAULT_TOKEN" -X POST -d '{"type":"kv-v2"}' $VAULT_ADDR/v1/sys/mounts/secret
    fi
    curl -s -o /dev/null --cacert $VAULT_CACERT -H "X-Vault-Token: $VAULT_TOKEN" -X POST -d "{
        \"data\": {
            \"GRAFANA_USER_USERNAME\": \"$GRAFANA_USER_USERNAME\",
            \"GRAFANA_USER_PASSWORD\": \"$GRAFANA_USER_PASSWORD\",
            \"GRAFANA_ADMIN_PASSWORD\": \"$GRAFANA_ADMIN_PASSWORD\"
        }
    }" $VAULT_ADDR/v1/secret/data/ft_wheel/database
    echo "Secrets setup completed."
    ###################################################


    # Setup Grafana Policy
    ###################################################
    echo "[vault_1] Setting up Grafana policy..."
    curl -s -o /dev/null --cacert $VAULT_CACERT -H "X-Vault-Token: $VAULT_TOKEN" -X PUT -d '{
        "policy": "path \"secret/data/ft_wheel/*\" { capabilities = [\"read\"] }"
    }' $VAULT_ADDR/v1/sys/policies/acl/grafana-policy

    export GRAFANA_VAULT_TOKEN=$(curl -s --cacert $VAULT_CACERT -H "X-Vault-Token: $VAULT_TOKEN" -X POST -d '{
        "policies": ["grafana-policy"]
    }' $VAULT_ADDR/v1/auth/token/create | jq -r '.auth.client_token')
    mkdir -p /vault/token/grafana
    echo "$GRAFANA_VAULT_TOKEN" > /vault/token/grafana/grafana-token
    chmod 600 /vault/token/grafana/grafana-token
    chmod +r /vault/token/grafana/grafana-token
    echo "GRAFANA policy setup completed."
    ###################################################

else

    # Vault already initialized
    echo "[vault_1] Vault already initialized."
    export VAULT_TOKEN=$(cat /vault/token/root_token-vault_1)
    if [ "$(check_vault_sealed)" = "true" ]; then
        UNSEAL_KEY=$(cat /vault/token/unseal_key-vault_1)
        for i in {1..5}; do
            vault operator unseal "$UNSEAL_KEY" && break
            echo "[vault_1] Unseal attempt $i failed, retrying..."
            sleep 2
        done
        echo "[vault_1] Vault unsealed."

    fi

fi

echo "[vault_1] Vault status:"
vault status

echo "[vault_1] Vault initialized and configured. Tailing logs..."
wait $VAULT_PID
