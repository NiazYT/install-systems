#!/bin/bash
#part1
printf '\033c'
echo "Welcome to niaz's artix installer script"
sed -i "s/^#ParallelDownloads = 5$/ParallelDownloads = 3/" /etc/pacman.conf
loadkeys us
rc-service ntpd start
lsblk
echo "Enter the drive: "
read drive
cfdisk $drive
lsblk
echo "Enter the linux partition: "
read partition
mkfs.ext4 $partition
read -p "Did you also create efi partition? [y/n]" answer
if [[ $answer = y ]]; then
	lsblk
	echo "Enter EFI partition: "
	read efipartition
	mkfs.vfat -F 32 $efipartition
fi
read -p "Did you also create efi partition? [y/n]" answer
if [[ $answer = y ]]; then
	lsblk
	echo "Enter swap partition: "
	read swappartition
	mkswap $swappartition
	swapon $swappartition
fi
mount $partition /mnt
basestrap /mnt base base-devel linux linux-firmware
fstabgen -U /mnt >>/mnt/etc/fstab
# Run part 2
sed '1,/^#part2$/d' $(basename $0) >/mnt/artix_install2.bash
chmod +x /mnt/artix_install2.bash
artix-chroot /mnt ./artix_install2.bash
read -p "Would you like to reboot? (Recommend) (Y/n)" doreboot
case $doreboot in
"[Yy]")
	umount /mnt/boot/efi
	umount /mnt
	shutdown -r now
	;;
esac
exit 0

#part2
printf '\033c'
ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
hwclock --systohc

pacman -Sy --noconfirm sed
sed -i "s/^#en_US.UTF-8 UTF-8$/en_US.UTF-8 UTF-8/" /etc/pacman.conf
sed -i "s/^#ru_RU.UTF-8 UTF-8$/ru_RU.UTF-8 UTF-8/" /etc/pacman.conf
locale-gen
echo 'export LANG="en_US.UTF-8"
export LC_COLLATE="C"' >/etc/locale.conf
echo "LANG=en_US.UTF-8" >/etc/locale.conf
echo "KEYMAP=us" >/etc/vconsole.conf

echo "Hostname: "
read hostname
echo $hostname >/etc/hostname
echo "127.0.0.1       localhost" >>/etc/hosts
echo "::1             localhost" >>/etc/hosts
echo "127.0.1.1       $hostname.localdomain $hostname" >>/etc/hosts
mkinitcpio -P

pacman -Sy --noconfirm grub os-prober efibootmgr
lsblk
echo "Enter EFI partition: "
read efipartition
mkdir /boot/efi
mount $efipartition /boot/efi
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
sed -i 's/quiet/pci=noaer/g' /etc/default/grub
sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/g' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

echo "Installing arch linux repositories"
sed -i "s/^#ParallelDownloads = 5$/ParallelDownloads = 3/" /etc/pacman.conf
pacman -Sy --noconfirm artix-archlinux-support
echo '
# Arch
[extra]
Include = /etc/pacman.d/mirrorlist-arch

[multilib]
Include = /etc/pacman.d/mirrorlist-arch' >>/etc/pacman.conf
pacman-key --init
pacman-key --populate archlinux
pacman -Syu --noconfirm archlinux-keyring

# TODO: Replace xdotool
pacman -Syu --noconfirm zsh terminus-font neovim termdown ripgrep gcc make cmake clang \
	xdg-user-dirs polkit-kde-agent qt5-wayland qt6-wayland sddm \
	noto-fonts noto-fonts-emoji noto-fonts-cjk ttf-jetbrains-mono ttf-joypixels ttf-font-awesome ttf-meslo-nerd ttf-noto-nerd ttf-jetbrains-mono-nerd \
	imv mpv mpd ncmpcpp zathura zathura-pdf-mupdf ffmpeg imagemagick alacritty keepassxc obsidian firefox discord dmenu telegram-desktop \
	fzf man-db unclutter xclip maim yt-dlp \
	zip unzip unrar p7zip xdotool dosfstools ntfs-3g git sxhkd pipewire pipewire-alsa pipewire-pulse wireplumber helvum \
	rsync qutebrowser dash xcompmgr picom libnotify slock jq aria2 cowsay \
	dhcpcd connman wpa_supplicant pamixer libconfig \
	bluez bluez-utils base-devel opendoas qt5ct

setfont ter-i18n.psf.gz

echo 'Root password:'
passwd

echo 'Enter username:'
read username
useradd -m -G wheel,video,audio,input,power,storage,optical,lp,scanner,dbus,uucp -s /bin/zsh $username
echo "Enter $username password:"
passwd $username

touch /etc/doas.conf
chown -c root:root /etc/doas.conf
chmod 600 /etc/doas.conf
echo 'permit persist setenv { PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin XAUTHORITY LANG LC_ALL } :wheel' >/etc/doas.conf
chmod -c 0400 /etc/doas.conf
ln -s $(which doas) /usr/bin/sudo

echo "Installing sinit"
mkdir /tmp
cd /tmp
# sinit
git clone https://git.suckless.org/sinit
cd sinit/
make
make install
cd ..
# daemontools-encore
git clone https://github.com/bruceg/daemontools-encore
cd daemontools-encore/
./makemake
make
make install
cd ..
# LittKit
curl -o littkit.tgz http://troubleshooters.com/projects/littkit/downloads/littkit_0_90.tgz
tar xvf littkit.tgz
cd littkit_0_90
cp lk_* /usr/local/bin
cd ..

git clone https://github.com/Andrey0189/sinit-scripts
cd sinit-scripts/
yes | ./install.sh
cd ..
rm -rf /tmp/*

cd /

mkdir /var/rc/pipewire
echo '
exec pipewire
' >/var/rc/pipewire/run
chmod u+x /var/rc/pipewire/run
ln -s /var/rc/pipewire /etc/rc/
# Pipewire-pulse service
mkdir /var/rc/pipewire-pulse
echo '
exec pipewire-pulse
' >/var/rc/pipewire-pulse/run
chmod u+x /var/rc/pipewire-pulse/run
ln -s /var/rc/pipewire-pulse /etc/rc/
# Wireplumber service
mkdir /var/rc/wireplumber
echo '
exec wireplumber
' >/var/rc/wireplumber/run
chmod u+x /var/rc/wireplumber/run
ln -s /var/rc/wireplumber /etc/rc/
echo "Add to config 'lk_prepare /etc/rc/{pipewire,pipewire-pulse,wireplumber,sddm}' and log if you want. Type anything: "
read fuck
nvim /etc/rc/dtinit/dtinit.sh

echo "checking cpu"
vendor=$(lscpu | grep "Vendor" | awk '{print $3}')
case $vendor in
*Intel* | *Iotel*)
	echo "Your processor is intel!"
	pacman -Sy --noconfirm intel-ucode
	;;
*AMD*)
	echo "Your processor is AMD!"
	pacman -Sy --noconfirm amd-ucode
	;;
*)
	echo "I don't sure what your cpu is, exiting..."
	exit 1
	;;
esac
echo "checking graphics card"
echo "Can you tell me what your graphics card is?([N]vidia/[A]MD/[I]ntel/[S]kip)"
read graphic
echo
case $graphic in
[Nn]vidia | [Nn])
	echo "Warning! If you have nvidia card <800 you need install different driver. Continue? (Y/n)"
	read notlegacy
	if [[ $notlegacy = "Y" || $notlegacy = "y" ]]; then
		pacman -Sy --noconfirm nvidia-dkms libva libva-nvidia-driver libvdpau ffnvcodec-headers nvidia-settings
		echo "blacklist nouveau" >/etc/modprobe.d/nouveau_blacklist.conf
		sed -i 's/pci=noaer/pci=noaer nvidia_drm.modeset=1/g' /etc/default/grub
		grub-mkconfig -o /boot/grub/grub.cfg
		sed -i 's/MODULES=()/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/g' /etc/mkinitcpio.conf
		mkinitcpio --config /etc/mkinitcpio.conf --generate /boot/initramfs-custom.img
		echo 'options nvidia-drm modeset=1' >/etc/modprobe.d/nvidia.conf
	fi
	;;
AMD | amd | [Aa])
	# FIXME: Replace packages
	pacman -Sy --noconfirm mesa-dri vulkan-loader mesa-vulkan-radeon xf86-video-amdgpu mesa-vaapi mesa-vdpau
	;;
[Ii]ntel | [Ii])
	pacman -Sy --noconfirm mesa vulkan-intel intel-media-driver libva-intel-driver
	mkdir -p /etc/X11/xorg.conf.d
	echo 'Section "Device"
  Identifier "Intel Graphics"
  Driver "modesetting"
EndSection' >/etc/X11/xorg.conf.d/20-intel.conf
	;;
esac

# Run 3rd part
echo "Pre-Installation Finish"
ai3_path=/home/$username/install_user.bash
sed '1,/^#part3$/d' artix_install2.bash >$ai3_path
chown $username:$username $ai3_path
chmod +x $ai3_path
su -c $ai3_path -s /bin/bash $username
exit 0

#part3
printf '\033c'
echo "Installing hyprland"
mkdir -p ~/.local/src

pacman -Sy --noconfirm gdb ninja gcc cmake meson libxcb xcb-proto xcb-util xcb-util-keysyms libxfixes libx11 libxcomposite xorg-xinput libxrender pixman wayland-protocols cairo pango seatd libxkbcommon xcb-util-wm xorg-xwayland libinput libliftoff libdisplay-info cpio tomlplusplus

# Hyprland
git clone --depth=1 --recursive https://github.com/hyprwm/Hyprland ~/.local/src/hyprland
cd ~/.local/src/hyprland
mkdir -p build && cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -DNO_SYSTEMD:STRING=true -H./ -B./build -G Ninja
# Building
cmake --build ./build --config Release --target all -j $(nproc)
# Installing
sudo cp ./build/Hyprland /usr/bin
sudo cp ./example/hyprland.desktop /usr/share/wayland-sessions

git clone --depth=1 --recursive https://github.com/Alexays/Waybar ~/.local/src/waybar
sed -i -e 's/zext_workspace_handle_v1_activate(workspace_handle_);/const std::string command = "hyprctl dispatch workspace " + name_;\n\tsystem(command.c_str());/g' src/modules/wlr/workspace_manager.cpp
meson --prefix=/usr --buildtype=plain --auto-features=enabled --wrap-mode=nodownload build
meson configure -Dexperimental=true build
sudo ninja -C build install

git clone --depth=1 --recursive https://github.com/Aylur/ags.git ~/.local/src/ags
cd ~/.local/src/ags
npm install
meson setup build
sudo meson install -C build # When asked to use sudo, make sure you say yes

echo "Installing configfiles"
# Dotfiles repository
cd $HOME
git clone --separate-git-dir=$HOME/.dotfiles https://github.com/NiazYT/dotfiles.git tmpdotfiles
rsync --recursive --verbose --exclude '.git' tmpdotfiles/ $HOME/
rm -r tmpdotfiles

xdg-user-dirs-update

ln -s ~/.config/x11/xinitrc .xinitrc
ln -s ~/.config/shell/profile .zprofile
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
mv ~/.oh-my-zsh ~/.config/zsh/oh-my-zsh
rm ~/.zshrc ~/.zsh_history
alias dots='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
dots config --local status.showUntrackedFiles no

# Yay installation
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si

# Yay
yay -Y --gendb
yay -Syu --devel
yay -Y --devel

# AUR packages
yay -S xremap-hypr-bin xdg-desktop-portal-hyprland-git fish foot fuzzel gjs gnome-bluetooth-3.0 gnome-control-center gnome-keyring gobject-introspection grim gtk3 gtk-layer-shell libdbusmenu-gtk3 meson npm plasma-browser-integration playerctl polkit-gnome python-pywal ripgrep sassc slurp starship swayidle typescript upower xorg-xrandr webp-pixbuf-loader wget wireplumber wl-clipboard tesseract tesseract-data-eng tesseract-data-rus yad ydotool adw-gtk3-git cava gojq gradience-git hyprpicker-git lexend-fonts-git python-material-color-utilities python-pywal python-poetry python-build python-pillow swww ttf-material-symbols-variable-git ttf-space-mono-nerd swaylock-effects-git ttf-jetbrains-mono-nerd wayland-idle-inhibitor-git wlogout wlsunset-git swaync

echo "Installing scripts"
chmod +x ~/.local/bin -R

echo "Installation Finish"
ai4_path=/home/$username/afterall.bash
sed '1,/^#part4$/d' install_user.bash >$ai4_path
chown $username:$username $ai4_path
chmod +x $ai4_path
exit 0

#part4
printf '\033c'
echo "Write username for git:"
read gitusername
echo "Write email for git:"
read email
git config --global user.name $gitusername
git config --global user.email $email
ssh-keygen -t ed25519 -C $email -f .ssh/github -q -N ""
echo "Add this key to your github account(https://github.com/settings/ssh/new):"
cat .ssh/github.pub
