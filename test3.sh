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

print_status "Updating system..."
sudo pacman -Syu --noconfirm

print_warning "Removing all packages except base and base-devel..."
sudo pacman -Rns --noconfirm $(comm -23 <(pacman -Qq | sort) <(echo -e "base\nbase-devel" | sort))

print_status "Reinstalling base essentials..."
sudo pacman -S --needed --noconfirm base base-devel linux linux-firmware vim

print_status "Installing display server + login manager..."
sudo pacman -S --needed --noconfirm xorg-server xorg-xinit sddm
sudo systemctl enable sddm

print_status "Installing Hyprland + GUI environment..."
sudo pacman -S --needed --overwrite="*" --noconfirm \
    hyprland kitty wofi waybar swaybg swaylock-effects wlogout grim slurp \
    wl-clipboard cliphist polkit-kde-agent qt5-wayland qt6-wayland \
    xdg-desktop-portal-hyprland

print_status "Installing utilities..."
sudo pacman -S --needed --overwrite="*" --noconfirm \
    thunar thunar-volman thunar-archive-plugin file-roller \
    firefox neovim fastfetch htop tree git curl wget unzip

print_status "Installing fonts..."
sudo pacman -S --needed --overwrite="*" --noconfirm \
    ttf-font-awesome ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji

print_status "Installing PipeWire audio..."
sudo pacman -S --needed --overwrite="*" --noconfirm \
    pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber pavucontrol

print_status "Cloning Caelestia..."
cd "$HOME"
git clone https://github.com/caelestia-dots/caelestia.git
cd caelestia

print_status "Installing Fish shell..."
sudo pacman -S --needed --noconfirm fish
chsh -s "$(which fish)"

print_status "Running Caelestia install script..."
if [[ -f "install.sh" ]]; then
    chmod +x install.sh
    fish install.sh
else
    cp -r .config/* "$HOME/.config/"
fi

print_status "Enabling user services..."
systemctl --user enable pipewire pipewire-pulse wireplumber

print_success "Done! Reboot now and log in via SDDM -> Hyprland."
