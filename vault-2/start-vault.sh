#!/bin/bash
export VAULT_ADDR=https://vault_2:8200
export VAULT_CACERT=/vault/ssl/ca.crt

echo "Entering Vault 2 startup script"

check_vault_initialized() {
    vault status -format=json | jq -r '.initialized' 2>/dev/null
}

check_vault_sealed() {
    vault status -format=json | jq -r '.sealed' 2>/dev/null
}

wait_for_vault1_ready() {
    echo "[vault_2] Waiting for vault_1 to be reachable and initialized..."
    while true; do
        # Check if vault_1 is initialized
        status=$(curl -sk --cacert /vault/ssl/ca.crt https://vault_1:8200/v1/sys/health)
        if echo "$status" | grep -q '"initialized":true'; then
            echo "[vault_2] vault_1 is initialized."
            break
        fi
        echo "[vault_2] vault_1 not ready yet. Sleeping..."
        sleep 3
    done
}

start_vault() {
    local config_file="/vault/config/vault_2.hcl"
    local log_file="/vault/logs/vault_2.log"
    echo "[vault_2] Starting Vault server..."
    vault server -log-level=info -config="$config_file" > "$log_file" 2>&1 &
    VAULT_PID=$!
    sleep 5
}

wait_for_vault1_ready
start_vault

# Wait for Vault API to be up (accept 501 Not Implemented as "up but not initialized")
echo "[vault_2] Waiting for Vault API to be up..."
until curl -fsk --cacert /vault/ssl/ca.crt https://vault_2:8200/v1/sys/health || \
      curl -fsk -o /dev/null -w "%{http_code}" --cacert /vault/ssl/ca.crt https://vault_2:8200/v1/sys/health | grep -E '200|429|501|503'; do
    sleep 2
done

if [ "$(check_vault_initialized)" = "false" ]; then
    echo "[vault_2] Vault not initialized. Joining raft cluster..."
    export VAULT_TOKEN=$(cat /vault/token/root_token-vault_1)
    vault operator raft join https://vault_1:8200 || {
        echo "[vault_2] Failed to join raft cluster!"
        kill $VAULT_PID
        exit 1
    }
    UNSEAL_KEY=$(cat /vault/token/unseal_key-vault_1)
    for i in {1..5}; do
        vault operator unseal "$UNSEAL_KEY" && break
        echo "[vault_2] Unseal attempt $i failed, retrying..."
        sleep 2
    done
    echo "[vault_2] Joined raft cluster and unsealed."
else
    echo "[vault_2] Vault already initialized."
    export VAULT_TOKEN=$(cat /vault/token/root_token-vault_1)
    if [ "$(check_vault_sealed)" = "true" ]; then
        UNSEAL_KEY=$(cat /vault/token/unseal_key-vault_1)
        for i in {1..5}; do
            vault operator unseal "$UNSEAL_KEY" && break
            echo "[vault_2] Unseal attempt $i failed, retrying..."
            sleep 2
        done
        echo "[vault_2] Vault unsealed."
    fi
fi

echo "[vault_2] Vault status:"
vault status

echo "[vault_2] Vault initialized and configured. Tailing logs..."
wait $VAULT_PID