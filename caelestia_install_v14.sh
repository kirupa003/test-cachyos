#!/bin/bash

# Caelestia Hyprland Installer for CachyOS
# Simple installation script for Arch-based systems
# Updated: August 2025

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[*]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root"
   exit 1
fi

# Check if on Arch-based system
print_status "Checking system compatibility..."
if ! command -v pacman &> /dev/null; then
    print_error "This script is for Arch-based systems (CachyOS). Pacman not found!"
    exit 1
fi

print_status "Updating system packages..."
sudo pacman -Syu --noconfirm

print_status "Installing Hyprland and essential packages..."
sudo pacman -S --needed --noconfirm \
    hyprland \
    kitty \
    wofi \
    waybar \
    swaybg \
    swaylock-effects \
    wlogout \
    grim \
    slurp \
    wl-clipboard \
    cliphist \
    polkit-kde-agent \
    qt5-wayland \
    qt6-wayland \
    xdg-desktop-portal-hyprland

print_status "Installing display manager (greetd + regreet)..."
sudo pacman -S --needed --noconfirm greetd regreet

print_status "Installing additional utilities and applications..."
sudo pacman -S --needed --noconfirm \
    fish \
    thunar \
    thunar-volman \
    thunar-archive-plugin \
    file-roller \
    firefox \
    neovim \
    fastfetch \
    htop \
    tree \
    git \
    curl \
    wget \
    unzip

print_status "Installing fonts and themes..."
sudo pacman -S --needed --noconfirm \
    ttf-font-awesome \
    ttf-jetbrains-mono-nerd \
    noto-fonts \
    noto-fonts-emoji

print_status "Installing audio system..."
sudo pacman -S --needed --noconfirm \
    pipewire \
    pipewire-alsa \
    pipewire-pulse \
    pipewire-jack \
    wireplumber \
    pavucontrol

print_status "Cloning Caelestia dotfiles..."
cd "$HOME"
if [[ -d "caelestia" ]]; then
    print_warning "Existing caelestia directory found. Backing up..."
    mv caelestia "caelestia_backup_$(date +%Y%m%d_%H%M%S)"
fi

git clone https://github.com/caelestia-dots/caelestia.git
cd caelestia

print_status "Installing Caelestia configuration..."
# Create config directory if it doesn't exist
mkdir -p "$HOME/.config"

# Run the Caelestia install script if it exists
if [[ -f "install.sh" ]]; then
    chmod +x install.sh
    print_status "Running Caelestia install script..."
    fish install.sh
elif [[ -f "install" ]]; then
    chmod +x install
    print_status "Running Caelestia install script..."
    fish install
elif [[ -f "install.fish" ]]; then
    chmod +x install.fish
    fish install.fish
else
    print_warning "No install script found. Copying configs manually..."
    if [[ -d ".config" ]]; then
        # Backup existing configs
        for config_dir in .config/*/; do
            config_name=$(basename "$config_dir")
            if [[ -d "$HOME/.config/$config_name" ]]; then
                print_warning "Backing up existing $config_name config..."
                mv "$HOME/.config/$config_name" "$HOME/.config/${config_name}_backup_$(date +%Y%m%d_%H%M%S)"
            fi
        done
        cp -r .config/* "$HOME/.config/"
        print_success "Configuration files copied"
    fi
fi

print_status "Configuring greetd with regreet..."
sudo mkdir -p /etc/greetd
sudo tee /etc/greetd/config.toml > /dev/null <<EOF
[terminal]
vt = 1

[default_session]
command = "regreet"
user = "greeter"
EOF

print_status "Enabling greetd service..."
sudo systemctl enable greetd

print_status "Setting up Fish shell..."
print_warning "Would you like to set Fish as your default shell? (Y/n)"
read -r response
if [[ "$response" =~ ^[Nn]$ ]]; then
    print_status "Keeping current shell"
else
    chsh -s "$(which fish)"
    print_success "Default shell changed to Fish"
fi

print_status "Enabling user services..."
# Enable pipewire services
systemctl --user enable pipewire pipewire-pulse wireplumber

print_status "Setting up directories..."
mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.local/share/applications"
mkdir -p "$HOME/Pictures/Screenshots"

print_success "Caelestia installation completed!"
echo ""
print_status "🎉 Next steps:"
echo "1. Log out of your current session"
echo "2. Select 'Hyprland' at the login screen"
echo "3. Enjoy your Caelestia desktop!"
echo ""
print_status "📱 Key shortcuts (once logged into Hyprland):"
echo "• Super + Enter       → Open terminal (Kitty)"
echo "• Super + D           → Application launcher (Wofi)"
echo "• Super + Q           → Close window"
echo "• Super + M           → Exit Hyprland"
echo "• Super + V           → Toggle floating mode"
echo "• Super + Arrow keys  → Move focus"
echo ""
print_warning "📁 Important notes:"
echo "• Configuration files are in ~/.config/"
echo "• Don't delete ~/caelestia folder (contains linked configs)"
echo "• Screenshots saved to ~/Pictures/Screenshots/"
echo "• For help: https://github.com/caelestia-dots/caelestia"
echo ""
print_status "All done! 🚀 Logout and select Hyprland to start using Caelestia!"