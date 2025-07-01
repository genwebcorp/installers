#!/bin/bash -i

info() {
  echo -e "\033[1;34m[INFO]\033[0m $1"
}

if hash conda 2>/dev/null; then
  conda init >/dev/null 2>&1
  conda deactivate >/dev/null 2>&1
  conda config --set auto_activate_base false
fi



# Install pixi
info "Installing pixi..."
curl -fsSL https://pixi.sh/install.sh | bash || error_exit "Failed to install pixi."
info "Sourcing bashrc..."
source ~/.bashrc

info "Updating pixi..."
pixi global update || error_exit "Failed to update pixi."

# Install GitHub CLI
info "Installing GitHub CLI..."
pixi global install gh || error_exit "Failed to install GitHub CLI."
gh auth login -p https --web || error_exit "Failed to authenticate GitHub CLI."

info "Installing git..."
pixi global install git || error_exit "Failed to install git."

info "Authenticating gcloud..."
gcloud auth login --update-adc --force


echo "=== Git Identity Setup ==="

# Prompt for name
read -rp "Enter your Git user name: " NAME

# Prompt for email
read -rp "Enter your Git email address: " EMAIL

# Prompt for scope
while true; do
  read -rp "Apply settings globally? (y/n): " SCOPE
  case "$SCOPE" in
    [Yy]* )
      git config --global user.name "$NAME"
      git config --global user.email "$EMAIL"
      echo "✅ Set Git global name and email."
      break;;
    [Nn]* )
      git config user.name "$NAME"
      git config user.email "$EMAIL"
      echo "✅ Set Git local name and email (for this repo only)."
      break;;
    * ) echo "Please answer y (yes) or n (no).";;
  esac
done


info "Installing lazygit..."
pixi global install lazygit || error_exit "Failed to install lazygit."

info "Installing pre-commit..."
pixi global install pre-commit || error_exit "Failed to install pre-commit."

info "Cloning rnd..."
git clone https://github.com/genwebcorp/rnd.git
cd rnd

info "Setting up pre-commit hooks..."
pre-commit install || error_exit "Failed to install pre-commit hooks."

info "Installing pixi environment..."
pixi install || error_exit "Failed to install pixi environment."

info "Pulling bucket..."
pixi run pull || error_exit "Failed to pull bucket."

