#!/bin/bash

# Fetch the latest Go version dynamically
echo "Fetching the latest Go version..."
LATEST_VERSION=$(curl -s https://go.dev/dl/ | grep -oP 'go[0-9]+\.[0-9]+\.[0-9]+\.src.tar.gz' | head -1 | sed 's/\.src.tar\.gz//')
GO_TARBALL="${LATEST_VERSION}.src.tar.gz"
GO_URL="https://go.dev/dl/${GO_TARBALL}"
INSTALL_DIR="/usr/local/go"

# If latest version could not be determined, exit
if [[ -z "$LATEST_VERSION" ]]; then
    echo "Failed to fetch the latest Go version. Please check your internet connection or try again later."
    exit 1
fi

echo "Latest Go version: ${LATEST_VERSION#go}"

# Check if Go is already installed
if command -v go &> /dev/null; then
    CURRENT_VERSION=$(go version | awk '{print $3}')
    echo "Go is already installed: $CURRENT_VERSION"
    
    # Compare versions and prompt user
    if [[ "$CURRENT_VERSION" == "$LATEST_VERSION" ]]; then
        echo "You already have the latest version installed."
        exit 0
    fi

    read -p "A newer version ($LATEST_VERSION) is available. Do you want to update? (y/n): " RESPONSE
    if [[ "$RESPONSE" != "y" ]]; then
        echo "Installation aborted. Keeping the existing Go version."
        exit 0
    fi
    
    echo "Proceeding with the update to Go $LATEST_VERSION..."
    sudo rm -rf "$INSTALL_DIR"  # Remove existing installation
fi

# Update system and install dependencies
echo "Updating system and installing dependencies..."
sudo apt update
sudo apt install -y build-essential gcc wget curl

# Download Go source code
echo "Downloading Go $LATEST_VERSION source code..."
wget -q --show-progress "$GO_URL"

# Extract the tarball
echo "Extracting Go source code..."
tar -xzf "$GO_TARBALL"

# Move Go to installation directory
echo "Moving Go to $INSTALL_DIR..."
sudo mv go "$INSTALL_DIR"

# Build Go from source
echo "Building Go from source..."
cd "$INSTALL_DIR/src" || { echo "Failed to enter Go source directory"; exit 1; }
sudo ./make.bash

# Set up environment variables
echo "Setting up Go environment variables..."
echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee -a /etc/profile > /dev/null
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc

# Verify installation
echo "Verifying Go installation..."
go version

echo "Go $LATEST_VERSION installed successfully!"

