#!/bin/bash
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[*]${NC} $1"; }
print_success() { echo -e "${GREEN}[✓]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }

if [[ $EUID -eq 0 ]]; then
    echo "Do not run as root"
    exit 1
fi

if ! command -v pacman &> /dev/null; then
    echo "Pacman not found — must be Arch-based"
    exit 1
fi

print_status "Updating system packages..."
sudo pacman -Syu --noconfirm

# --- Install display manager and enable GUI boot ---
print_status "Installing SDDM (graphical login manager)..."
sudo pacman -S --needed --noconfirm sddm
sudo systemctl enable sddm
sudo systemctl set-default graphical.target

# --- Remove known conflicts ---
print_status "Removing conflicting packages..."
sudo pacman -Rdd --noconfirm pulseaudio pulseaudio-alsa pipewire-media-session swaybg swaylock xdg-desktop-portal xdg-desktop-portal-wlr 2>/dev/null || true

# --- Install Hyprland desktop stack ---
print_status "Installing Hyprland and essentials..."
sudo pacman -S --needed --overwrite="*" --noconfirm \
    hyprland kitty wofi waybar swaybg swaylock-effects wlogout \
    grim slurp wl-clipboard cliphist polkit-kde-agent \
    qt5-wayland qt6-wayland xdg-desktop-portal-hyprland

# --- Additional utilities ---
print_status "Installing utilities..."
sudo pacman -S --needed --overwrite="*" --noconfirm \
    thunar thunar-volman thunar-archive-plugin file-roller \
    firefox neovim fastfetch htop tree git curl wget unzip

# --- Fonts ---
print_status "Installing fonts..."
sudo pacman -S --needed --overwrite="*" --noconfirm \
    ttf-font-awesome ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji

# --- Audio ---
print_status "Installing PipeWire audio..."
sudo pacman -S --needed --overwrite="*" --noconfirm \
    pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber pavucontrol

# --- Clone Caelestia configs ---
print_status "Cloning Caelestia dotfiles..."
cd "$HOME"
if [[ -d "caelestia" ]]; then
    print_warning "Existing caelestia directory found. Backing up..."
    mv caelestia "caelestia_backup_$(date +%Y%m%d_%H%M%S)"
fi
git clone https://github.com/caelestia-dots/caelestia.git
cd caelestia
mkdir -p "$HOME/.config"

# --- Fish shell choice ---
print_warning "Caelestia includes Fish shell configurations."
print_status "Would you like to install Fish shell? (Y/n)"
read -r fish_response
if [[ ! "$fish_response" =~ ^[Nn]$ ]]; then
    sudo pacman -S --needed --noconfirm fish
    chsh -s "$(which fish)"
    INSTALL_WITH_FISH=true
else
    INSTALL_WITH_FISH=false
fi

# --- Run Caelestia install ---
if [[ -f "install.sh" ]]; then
    chmod +x install.sh
    if [[ "$INSTALL_WITH_FISH" == true ]]; then
        fish install.sh
    else
        bash install.sh 2>/dev/null || MANUAL_INSTALL=true
    fi
else
    MANUAL_INSTALL=true
fi

# --- Manual config copy if needed ---
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
                [[ "$(basename "$config_dir")" != "fish" ]] && cp -r "$config_dir" "$HOME/.config/"
            done
        else
            cp -r .config/* "$HOME/.config/"
        fi
    fi
fi

# --- Enable user services ---
print_status "Enabling user services..."
systemctl --user enable pipewire pipewire-pulse wireplumber

# --- Final message ---
print_success "Caelestia + Hyprland + SDDM installed!"
echo "Reboot now, and you'll get a graphical login screen."
echo "Select 'Hyprland' in SDDM and log in."

