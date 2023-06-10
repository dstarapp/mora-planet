# planet

Mora planet canister

Every planet is a canister that owned by user and assigned by argeement, it contains articles, subcribers, comments.

A user has many planets. it is created by user canister.

## local test canister deploy

1. edit build/config_local.mo, replace yours canister ids.
2. build and deploy by using below command.

```sh
./build.sh -r local

# please replace argument with yours 
dfx deploy planet --argument '(principal "owner_principal", "planet_name", "planet_avatar_url", "planet_desc", blob "payee_account_id")'
```
