#!/usr/bin/bash
mkdir actions-runner && cd actions-runner# Download the latest runner package
curl -o actions-runner-linux-x64-2.332.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.332.0/actions-runner-linux-x64-2.332.0.tar.gz\
# Optional: Validate the hash
echo "f2094522a6b9afeab07ffb586d1eb3f190b6457074282796c497ce7dce9e0f2a  actions-runner-linux-x64-2.332.0.tar.gz" | shasum -a 256 -c
# Extract the installer
tar xzf ./actions-runner-linux-x64-2.332.0.tar.gz
#Configure
# Create the runner and start the configuration experience
./config.sh --url https://github.com/lancer1977/channel-cheevos --token $GITHUB_RUNNER_TOKEN
# Last step, run it!
./run.sh

