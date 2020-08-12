# Blockchain Nodes (and support ones)

## Vault

After the pod for the vault has been initiated, make sure you do:
- Make a port-forward to the vault.
- Make sure you set an environment variable called VAULT_URL with the url from the port-forward.
- `source services/bios/utils/vault.sh` and call the `init` function passing the path where you wanto to store the keys file `init vault_keys.json` which should not only create the keys but unseal the vault and leave it ready to store and serve secrets
