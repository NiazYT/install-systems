#!/bin/bash
#part1
printf '\033c'
echo "Welcome to niaz's arch installer script"
sed -i "s/^#ParallelDownloads = 5$/ParallelDownloads = 8/" /etc/pacman.conf
loadkeys us
rc-service ntpd start
lsblk
echo "Enter the drive: "
read drive
cfdisk $drive
echo "Enter the linux partition: "
read partition
mkfs.ext4 $partition
read -p "Did you also create efi partition? [y/n]" answer
if [[ $answer = y ]]; then
	echo "Enter EFI partition: "
	read efipartition
	mkfs.vfat -F 32 $efipartition
fi
mount $partition /mnt
basestrap /mnt base base-devel linux linux-firmware
fstabgen -U /mnt >>/mnt/etc/fstab
# Run part 2
sed '1,/^#part2$/d' $(basename $0) >/mnt/artix_install2.bash
chmod +x /mnt/artix_install2.bash
artix-chroot /mnt ./artix_install2.bash
echo "Would you like to reboot? (Recommend) (Y/n)"
read doreboot
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
echo "Enter EFI partition: "
read efipartition
mkdir /boot/efi
mount $efipartition /boot/efi
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
sed -i 's/quiet/pci=noaer/g' /etc/default/grub
sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/g' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

echo "Installing arch linux repositories"
sed -i "s/^#ParallelDownloads = 5$/ParallelDownloads = 8/" /etc/pacman.conf
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
	xorg-server xorg-xinit xorg-xkill xorg-xsetroot xorg-xbacklight xorg-xprop xdg-user-dirs \
	noto-fonts noto-fonts-emoji noto-fonts-cjk ttf-jetbrains-mono ttf-joypixels ttf-font-awesome ttf-meslo-nerd ttf-noto-nerd ttf-jetbrains-mono-nerd \
	imv mpv mpd ncmpcpp zathura zathura-pdf-mupdf ffmpeg imagemagick alacritty keepassxc obsidian firefox discord dmenu telegram-desktop \
	fzf man-db xwallpaper python-pywal unclutter xclip maim yt-dlp \
	zip unzip unrar p7zip xdotool dosfstools ntfs-3g git sxhkd pipewire pipewire-alsa pipewire-pulse wireplumber helvum \
	rsync qutebrowser dash xcompmgr picom libnotify dunst slock jq aria2 cowsay \
	dhcpcd connman wpa_supplicant pamixer libconfig \
	bluez bluez-utils base-devel opendoas

setfont ter-i18n.psf.gz

echo 'Root password:'
passwd

echo 'Enter username:'
read username
useradd -m -G wheel,video,audio,input,power,storage,optical,lp,scanner,dbus,uucp -s /bin/zsh $username
echo "Enter $username password:"
passwd $username

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

# TODO: Add services

cd /

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
		pacman -Sy --noconfirm nvidia libva-nvidia-driver libvdpau ffnvcodec-headers nvidia-settings
		echo "blacklist nouveau" >/etc/modprobe.d/nouveau_blacklist.conf
	fi
	;;
AMD | amd | [Aa])
	# FIXME: Replace packages
	pacman -Sy --noconfirm mesa-dri vulkan-loader mesa-vulkan-radeon xf86-video-amdgpu mesa-vaapi mesa-vdpau
	;;
[Ii]ntel | [Ii])
	# FIXME: Replace packages
	pacman -Sy --noconfirm mesa-dri vulkan-loader mesa-vulkan-intel intel-video-accel
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
echo "Installing dwm, dmenu, dwmblocks"
mkdir -p ~/.local/src

git clone --depth=1 "https://github.com/NiazYT/dwm" ~/.local/src/dwm
sudo make -C ~/.local/src/dwm install

git clone --depth=1 "https://github.com/NiazYT/dwmblocks" ~/.local/src/dwmblocks
sudo make -C ~/.local/src/dwmblocks install

echo "Installing configfiles"
# Dotfiles repository
cd $HOME
git clone --separate-git-dir=$HOME/.dotfiles https://github.com/NiazYT/dotfiles.git tmpdotfiles
rsync --recursive --verbose --exclude '.git' tmpdotfiles/ $HOME/
rm -r tmpdotfiles

# Neovim
git clone https://github.com/NvChad/NvChad ~/.config/nvim --depth 1

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
yay -S xremap-x11-bin

echo "Installing scripts"
chmod +x ~/.local/bin -R

echo "Installation Finish"
ai4_path=/home/$username/afterall.bash
sed '1,/^#part4$/d' install_user.bash >$ai4_path
chown $username:$username $ai4_path
chmod +x $ai4_path
su -c $ai4_path -s /bin/bash $username
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
