#!/bin/bash -i

set -e

info() {
  echo -e "\033[1;34m[INFO]\033[0m $1"
}
error_exit() {
  echo -e "\033[1;31m[ERROR]\033[0m $1"
  exit 1
}

# 1. Ask user for the absolute path to the genweb3d repo (default: $HOME/genweb3d)
echo -n "Enter the absolute path to your genweb3d repository [${HOME}/genweb3d]: "
read USER_GENWEB3D_DIR
if [ -z "$USER_GENWEB3D_DIR" ]; then
  GENWEB3D_DIR="$HOME/genweb3d"
else
  GENWEB3D_DIR="$USER_GENWEB3D_DIR"
fi
ORIG_DIR="$(pwd)"
if [ ! -d "$GENWEB3D_DIR" ]; then
  error_exit "Directory $GENWEB3D_DIR does not exist. Please clone the repository to this location."
fi
cd "$GENWEB3D_DIR"
if pixi run python -c "import genweb3d" 2>/dev/null; then
  info "genweb3d is installed and importable."
else
  error_exit "genweb3d is not installed or not importable. Please install the repository and ensure 'genweb3d' is available before running this script."
fi

# 2. Check if user is logged in to Hugging Face CLI; if not, prompt for token and log in
if pixi run huggingface-cli whoami 2>/dev/null | grep -q "Not logged in"; then
  echo -n "Enter your Hugging Face access token (it will be invisible): "
  read -s HF_TOKEN
  echo
  pixi run huggingface-cli login --token "$HF_TOKEN"
  info "Logged in to Hugging Face CLI."
else
  info "Already logged in to Hugging Face CLI."
fi

# 3. Prompt user to ensure they have requested access to Llama 3.1 8B
info "Please make sure you have requested access to the Llama 3.1 8B model on Hugging Face."
echo "  Request access here: https://huggingface.co/meta-llama/Meta-Llama-3.1-8B-Instruct"
echo -n "Press Enter to continue after you have requested and been granted access..."
read

cd "$ORIG_DIR"

# 4. Create the systemd service file
SERVICE_FILE="/etc/systemd/system/genlm-server.service"
USER_NAME=$(whoami)
WORKING_DIR="$GENWEB3D_DIR"

# Collect all arguments passed to this script (for server options)
SERVER_ARGS="$*"
EXEC_CMD="pixi run python -m genweb3d.lang.server $SERVER_ARGS"

info "Creating systemd service file at $SERVICE_FILE..."

sudo bash -c "cat > $SERVICE_FILE" <<EOF
[Unit]
Description=GenLM Server
After=network.target

[Service]
User=$USER_NAME
WorkingDirectory=$WORKING_DIR
ExecStart=/bin/bash -ic '$EXEC_CMD'
Restart=always
RestartSec=5
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOF

# 5. Reload systemd, enable, and start the service
info "Reloading systemd daemon..."
sudo systemctl daemon-reload

info "Enabling genlm-server service..."
sudo systemctl enable genlm-server

info "Starting genlm-server service..."
sudo systemctl restart genlm-server

info "Service status:"
sudo systemctl status genlm-server --no-pager

echo -e "\033[1;32m[SUCCESS]\033[0m GenLM server setup and started as a systemd service"

echo -e "\n\033[1;34m[INFO]\033[0m You can manage the GenLM server with the following commands:" 
echo "  Check status:    sudo systemctl status genlm-server" 
echo "  View live logs:  sudo journalctl -u genlm-server -f" 
echo "  View all logs:   sudo journalctl -u genlm-server" 
echo "  Restart:         sudo systemctl restart genlm-server" 
echo "  Stop:            sudo systemctl stop genlm-server" 
echo "  Start:           sudo systemctl start genlm-server" 
echo "  Enable on boot:  sudo systemctl enable genlm-server" 
echo "  Disable on boot: sudo systemctl disable genlm-server"
