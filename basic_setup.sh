#!/bin/bash

# Install pixi
curl -fsSL https://pixi.sh/install.sh | bash || error_exit "Failed to install pixi."
source ~/.bashrc

# Install GitHub CLI
pixi global install gh || error_exit "Failed to install GitHub CLI."
gh auth login --web || error_exit "Failed to authenticate GitHub CLI."

# Install gcloud
gcloud init
