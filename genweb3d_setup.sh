#!/usr/bin/env bash
info() {
  echo -e "\033[1;34m[INFO]\033[0m $1"
}
# Install pixi
info "Installing pixi..."
curl -fsSL https://pixi.sh/install.sh | bash || error_exit "Failed to install pixi."
if ! grep -q 'eval "$(pixi completion --shell bash)"' "$BASHRC"; then
  echo 'eval "$(pixi completion --shell bash)"' >>"$BASHRC"
fi

info "Updating pixi..."
pixi global update || error_exit "Failed to update pixi."

# Install GitHub CLI
info "Installing GitHub CLI..."
pixi global install gh || error_exit "Failed to install GitHub CLI."
gh auth login --web || error_exit "Failed to authenticate GitHub CLI."

info "Installing git..."
pixi global install git || error_exit "Failed to install git."

info "Authenticating gcloud..."
if gcloud auth list --filter=status:ACTIVE --format="get(account)" 2>/dev/null | grep -q .; then
  info "gcloud is already authenticated."
else
  info "Authenticating gcloud..."
  gcloud auth login --update-adc --force || error_exit "Failed to authenticate gcloud."
fi


info "Checking git configuration..."
if git config --global user.name &>/dev/null; then
  GIT_USER_NAME=$(git config --global user.name)
  info "git username already configured: $GIT_USER_NAME"
else
  read -p "Enter your git username: " GIT_USER_NAME
  git config --global user.name "$GIT_USER_NAME" || error_exit "Failed to set git username."
  info "git username configured: $GIT_USER_NAME"
fi


if git config --global user.email &>/dev/null; then
  GIT_USER_EMAIL=$(git config --global user.email)
  info "git email already configured: $GIT_USER_EMAIL"
else
  read -p "Enter your git email: " GIT_USER_EMAIL
  git config --global user.email "$GIT_USER_EMAIL" || error_exit "Failed to set git email."
  info "git email configured: $GIT_USER_EMAIL"
fi


info "Installing lazygit..."
pixi global install lazygit || error_exit "Failed to install lazygit."

info "Installing pre-commit..."
pixi global install pre-commit || error_exit "Failed to install pre-commit."

info "Cloning genweb3d..."
git clone https://github.com/nishad-genweb/genweb3d.git
cd genweb3d

info "Setting up pre-commit hooks..."
pre-commit install || error_exit "Failed to install pre-commit hooks."

info "Installing pixi environment..."
pixi install || error_exit "Failed to install pixi environment."

info "Pulling bucket..."
pixi run pull || error_exit "Failed to pull bucket."

info "Running tests..."
pixi run test || error_exit "Failed to run tests."