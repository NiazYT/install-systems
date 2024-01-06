#!/bin/bash
#part1
echo "Installing base packages"
user=$(whoami)
if [[ "$user" != "root" ]]
then
	echo "Running this script as root, write password of user:"
	sudo $0 $user
	exit 0
fi
username=$1
echo
pacman -Syu archlinux-keyring
echo "checking cpu"
vendor=$(lscpu | grep "Vendor" | awk '{print $3}')
case $vendor in
	*Intel* | *Iotel* )
		echo "Your processor is intel!"
		pacman -Sy intel-ucode 
		;;
	*AMD* )
		echo "Your processor is AMD!"
		pacman -Sy amd-ucode 
    ;;
	* )
		echo "I don't sure what your cpu is, exiting..."
		exit 1
		;;
esac
echo "checking graphics card"
echo "Can you tell me what your graphics card is?([N]vidia/[A]MD/[I]ntel/[S]kip)"
read graphic
echo
case $graphic in
	[Nn]vidia | [Nn] )
		echo "Warning! If you have nvidia card <800 you need install different driver. Continue? (Y/n)"
		read notlegacy
		if [[ $notlegacy = "Y" || $notlegacy = "y" ]]
		then
			pacman -Sy nvidia libva-nvidia-driver libvdpau ffnvcodec-headers cuda cuda-tools
      echo "blacklist nouveau" > /etc/modprobe.d/nouveau_blacklist.conf
		fi
		;;
	AMD | amd | [Aa] )
		pacman -Sy mesa-dri vulkan-loader mesa-vulkan-radeon xf86-video-amdgpu mesa-vaapi mesa-vdpau
		;;
	[Ii]ntel | [Ii] )
		pacman -Sy mesa-dri vulkan-loader mesa-vulkan-intel intel-video-accel
		;;
esac
echo "Installing other packages"
pacman -Sy neovim termdown yt-dlp mpv xdg-user-dirs zsh \
  # Xorg
  xorg dmenu alacritty obsidian discord firefox keepassxc telegram-desktop picom dunst \
  xwallpaper python-pywal \
  # Development
  ttf-nerd-fonts-symbols ripgrep gcc make cmake clang  \
  # Sound
  pipewire pipewire-alsa pipewire-pulse wireplumber helvum mpd ncmpcpp obs-studio ffmpeg

#part2
# Run as username
echo "Pre-Installation Finish Reboot now"
ai2_path=/home/$username/install_user.bash
sed '1,/^#part2$/d' install_artix.bash > $ai3_path
chown $username:$username $ai3_path
chmod +x $ai3_path
su -c $ai3_path -s /bin/bash $username

echo "Installing dwm, dmenu, dwmblocks"
mkdir -p ~/.local/src
git clone --depth=1 "https://github.com/NiazYT/dwm" ~/.local/src/dwm

git clone --depth=1 "https://github.com/NiazYT/dwmblocks" ~/.local/src/dwmblocks

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

# AUR installation
pacman -S --needed git base-devel
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si

# Yay 
yay -Y --gendb
yay -Syu --devel
yay -Y --devel --https://github.com/settings/ssh/newsave

# AUR packages
yay xremap-x11-bin 


echo "Installing scripts"

echo "Installation Finishw"
ai2_path=/home/$username/afterall.bash
sed '1,/^#part3$/d' install_user.bash > $ai3_path
chown $username:$username $ai3_path
chmod +x $ai3_path
su -c $ai3_path -s /bin/bash $username
echo 

echo "Would you like to reboot? (Recommend) (Y/n)"
read doreboot
case $doreboot in
	"[Yy]" )
		sudo shutdown -r now
		;;
esac
exit 0

#part3
ssh-keygen -t ed25519 -C "andreymishurin.work@gmail.com" -f .ssh/github -q -N ""
echo "Add this key to your github account(https://github.com/settings/ssh/new):"
cat .ssh/github.pub
