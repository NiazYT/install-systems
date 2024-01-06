#!/bin/bash
#part1
echo "Installing base packages"
user=$(whoami)
if [[ "$user" != "root" ]]
then
	echo "Running this script as root, write password of user:"
	sudo $0
	exit 0
fi
echo "What's your username"
read username
echo
xbps-install -Syu
xbps-install -y git void-repo-nonfree
xbps-install -Syu
echo "checking cpu"
vendor=$(lscpu | grep "Vendor" | awk '{print $3}')
case $vendor in
	*Intel* | *Iotel* )
		echo "Your processor is intel!"
		xbps-install -y intel-ucode linux-firmware-intel
		;;
	*AMD* )
		echo "Your processor is AMD!"
		xbps-install -y linux-firmware-amd
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
			xbps-install -y nvidia nvidia-vaapi-driver
			echo "omit_drivers+=" nouveau "" > /etc/dracut.conf.d/nouveau.conf
		fi
		;;
	AMD | amd | [Aa] )
		xbps-install -y linux-firmware-amd mesa-dri vulkan-loader mesa-vulkan-radeon xf86-video-amdgpu mesa-vaapi mesa-vdpau
		;;
	[Ii]ntel | [Ii] )
		xbps-install -y linux-firmware-intel mesa-dri vulkan-loader mesa-vulkan-intel intel-video-accel
		;;
esac
echo "Installing other packages"
xbps-install -y xorg neovim sddm alacritty dmenu termdown yt-dlp mpv xdg-user-dirs nerd-fonts ripgrep gcc make cmake
ln -s /etc/sv/sddm /etc/runit/runsvdir/default/

#part2
echo "Pre-Installation Finish Reboot now"
ai2_path=/home/$username/install_user.bash
sed '1,/^#part2$/d' install_user.bash > $ai3_path
chown $username:$username $ai3_path
chmod +x $ai3_path
su -c $ai3_path -s /bin/bash $username

echo "Installing dwm, dmenu, dwmblocks"
mkdir -p ~/.local/src
git clone --depth=1 "https://github.com/NiazYT/dwm" ~/.local/src/dwm

git clone --depth=1 "https://github.com/NiazYT/dwmblocks" ~/.local/src/dwmblocks

echo "Installing configfiles"
cd $HOME
git clone --separate-git-dir=$HOME/.dotfiles https://github.com/NiazYT/dotfiles.git tmpdotfiles
rsync --recursive --verbose --exclude '.git' tmpdotfiles/ $HOME/
rm -r tmpdotfiles
git clone https://github.com/NvChad/NvChad ~/.config/nvim --depth 1
xdg-user-dirs-update

ln -s ~/.config/x11/xinitrc .xinitrc
ln -s ~/.config/shell/profile .zprofile
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
mv ~/.oh-my-zsh ~/.config/zsh/oh-my-zsh
rm ~/.zshrc ~/.zsh_history
alias dots='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
dots config --local status.showUntrackedFiles no

echo "Installing scripts"
echo "Would you like to reboot? (Recommend) (Y/n)"
read doreboot
case $doreboot in
	"[Yy]" )
		sudo shutdown -r now
		;;
esac
