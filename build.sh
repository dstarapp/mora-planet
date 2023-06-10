#/bin/sh

NETWORK=""
while getopts "r:" opt
do
  case $opt in
    r)
      NETWORK=${OPTARG}
    ;;
  esac
done

if [ -z "$NETWORK" ]
then
  echo "must be usage -r"
  exit 1
fi

# echo $NETWORK;
\cp -f build/config_$NETWORK.mo src/planet/config.mo

dfx build --network $NETWORK

\cp -f .dfx/$NETWORK/canisters/planet/planet.wasm ../mora-dao/bin/planet_$NETWORK.wasm
cd ../mora-dao/bin/
gzip -k -n planet_$NETWORK.wasm