#!/bin/bash
set -e

cleanup() {
  if [ -e config.sh ]; then
    print_header "Cleanup. Removing Azure Pipelines agent..."

    # If the agent has some running jobs, the configuration removal process will fail.
    # So, give it some time to finish the job.
    while true; do
      ./config.sh remove --unattended --auth PAT --token $(cat "$AZP_TOKEN_FILE") && break

      echo "Retrying in 30 seconds..."
      sleep 30
    done
  fi
}
# Run external setup scripts.
./runscripts.sh | true
print_header() {
  lightcyan='\033[1;36m'
  nocolor='\033[0m'
  echo -e "${lightcyan}$1${nocolor}"
}


if [ -z "$AZP_URL" ]; then
  echo 1>&2 "error: missing AZP_URL environment variable"
  exit 1
fi

if [ -z "$AZP_TOKEN_FILE" ]; then
  if [ -z "$AZP_TOKEN" ]; then
    echo 1>&2 "error: missing AZP_TOKEN environment variable"
    exit 1
  fi

  AZP_TOKEN_FILE=/azp/.token
  echo -n $AZP_TOKEN > "$AZP_TOKEN_FILE"
fi

unset AZP_TOKEN

if [ -n "$AZP_WORK" ]; then
  mkdir -p "$AZP_WORK"
fi

export AGENT_ALLOW_RUNASROOT="1"



# Let the agent ignore the token env variables
export VSO_AGENT_IGNORE=AZP_TOKEN,AZP_TOKEN_FILE

print_header "1. Determining matching Azure Pipelines agent..."
AZP_MERGED_URL="$AZP_URL/_apis/distributedtask/packages/agent?platform=$TARGETARCH&top=1"
AZP_AGENT_PACKAGES=$(curl -LsS -u user:$(cat "$AZP_TOKEN_FILE") -H 'Accept:application/json;' "$AZP_MERGED_URL")
AZP_AGENT_PACKAGE_LATEST_URL=$(echo "$AZP_AGENT_PACKAGES" | jq -r '.value[0].downloadUrl')
echo "$AZP_AGENT_PACKAGE_LATEST_URL"
if [ -z "$AZP_AGENT_PACKAGE_LATEST_URL" -o "$AZP_AGENT_PACKAGE_LATEST_URL" == "null" ]; then
  echo 1>&2 "error: could not determine a matching Azure Pipelines agent"
  echo 1>&2 "check that account '$AZP_URL' is correct and the token is valid for that account"
  exit 1
fi

print_header "2. Downloading and extracting Azure Pipelines agent..."

curl -LsS "$AZP_AGENT_PACKAGE_LATEST_URL" | tar -xz & wait $!
source ./env.sh

print_header "2.1. Adding dev nuget source..."
dotnet nuget add source $NUGET_SOURCE -n $NUGET_NAME -u dev -p $(cat "$AZP_TOKEN_FILE") --store-password-in-clear-text || true
nuget sources add -Source $NUGET_SOURCE -Name $NUGET_NAME -UserName dev -Password $(cat "$AZP_TOKEN_FILE") || true

print_header "2.2. Adding docker support..."
docker login -u $DOCKER_USERNAME -p "$DOCKER_PAT" || true

print_header "3. Configuring Azure Pipelines agent..."
./config.sh --unattended \
  --agent "${AZP_AGENT_NAME:-$(hostname)}" \
  --url "$AZP_URL" \
  --auth PAT \
  --token $(cat "$AZP_TOKEN_FILE") \
  --pool "${AZP_POOL:-Default}" \
  --work "${AZP_WORK:-_work}" \
  --replace \
  --acceptTeeEula & wait $!

print_header "4. Running Azure Pipelines agent... YOU SHOULD NOT READ THIS!!!!!!!"
./run.sh & wait $!

trap 'cleanup; exit 0' EXIT
trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM
sleep infinity


