#!/bin/bash

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[*]${NC} $1"; }
print_success() { echo -e "${GREEN}[✓]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }

# Check root
if [[ $EUID -eq 0 ]]; then
    echo "Do not run as root"
    exit 1
fi

# Check Arch-based
print_status "Checking system compatibility..."
if ! command -v pacman &> /dev/null; then
    echo "Pacman not found — must be Arch-based"
    exit 1
fi

# Full system update
print_status "Updating system packages..."
sudo pacman -Syu --noconfirm

# Remove known conflicts for GUI stack
print_status "Removing packages that conflict with Hyprland environment..."
sudo pacman -Rdd --noconfirm \
    pulseaudio pulseaudio-alsa pipewire-media-session \
    swaybg swaylock xdg-desktop-portal xdg-desktop-portal-wlr \
    2>/dev/null || true

# Install Hyprland + essentials
print_status "Installing Hyprland and essential packages..."
sudo pacman -S --needed --overwrite="*" --noconfirm \
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

# Install additional utilities
print_status "Installing additional utilities and applications..."
sudo pacman -S --needed --overwrite="*" --noconfirm \
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

# Fonts
print_status "Installing fonts and themes..."
sudo pacman -S --needed --overwrite="*" --noconfirm \
    ttf-font-awesome \
    ttf-jetbrains-mono-nerd \
    noto-fonts \
    noto-fonts-emoji

# Audio stack
print_status "Installing PipeWire audio..."
sudo pacman -S --needed --overwrite="*" --noconfirm \
    pipewire \
    pipewire-alsa \
    pipewire-pulse \
    pipewire-jack \
    wireplumber \
    pavucontrol

# Clone Caelestia
print_status "Cloning Caelestia dotfiles..."
cd "$HOME"
if [[ -d "caelestia" ]]; then
    print_warning "Existing caelestia directory found. Backing up..."
    mv caelestia "caelestia_backup_$(date +%Y%m%d_%H%M%S)"
fi

git clone https://github.com/caelestia-dots/caelestia.git
cd caelestia

print_status "Installing Caelestia configuration..."
mkdir -p "$HOME/.config"

print_warning "Caelestia includes Fish shell configurations."
print_status "Would you like to install Fish shell? (Y/n)"
read -r fish_response

if [[ ! "$fish_response" =~ ^[Nn]$ ]]; then
    print_status "Installing Fish shell..."
    sudo pacman -S --needed --overwrite="*" --noconfirm fish
    INSTALL_WITH_FISH=true
else
    print_status "Skipping Fish shell installation"
    INSTALL_WITH_FISH=false
fi

# Run Caelestia install script
if [[ -f "install.sh" ]]; then
    chmod +x install.sh
    if [[ "$INSTALL_WITH_FISH" == true ]]; then
        fish install.sh
    else
        bash install.sh 2>/dev/null || MANUAL_INSTALL=true
    fi
elif [[ -f "install" ]]; then
    chmod +x install
    if [[ "$INSTALL_WITH_FISH" == true ]]; then
        fish install
    else
        bash install 2>/dev/null || MANUAL_INSTALL=true
    fi
elif [[ -f "install.fish" ]]; then
    if [[ "$INSTALL_WITH_FISH" == true ]]; then
        chmod +x install.fish
        fish install.fish
    else
        MANUAL_INSTALL=true
    fi
else
    MANUAL_INSTALL=true
fi

# Manual config copy
if [[ "$MANUAL_INSTALL" == true ]]; then
    if [[ -d ".config" ]]; then
        for config_dir in .config/*/; do
            config_name=$(basename "$config_dir")
            if [[ -d "$HOME/.config/$config_name" ]]; then
                mv "$HOME/.config/$config_name" "$HOME/.config/${config_name}_backup_$(date +%Y%m%d_%H%M%S)"
            fi
        done
        if [[ "$INSTALL_WITH_FISH" == false ]]; then
            for config_dir in .config/*/; do
                config_name=$(basename "$config_dir")
                if [[ "$config_name" != "fish" ]]; then
                    cp -r ".config/$config_name" "$HOME/.config/"
                fi
            done
        else
            cp -r .config/* "$HOME/.config/"
        fi
        print_success "Configuration files copied"
    fi
fi

# Default shell
print_status "Would you like to set Fish as your default shell? (Y/n)"
read -r response
if [[ ! "$response" =~ ^[Nn]$ ]]; then
    chsh -s "$(which fish)"
    print_success "Default shell changed to Fish"
fi

# Enable services
print_status "Enabling user services..."
systemctl --user enable pipewire pipewire-pulse wireplumber

# Setup dirs
mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.local/share/applications"
mkdir -p "$HOME/Pictures/Screenshots"

print_success "Caelestia installation completed!"
echo "Logout, select Hyprland at login, and enjoy!"
