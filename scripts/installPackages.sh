# I want to use args to make sure people don't acidentally install a bunch
# of binarys they don't want.
if [[ $1 == "" ]]; then
	echo "use this -i to install packages from the list";
	exit;
fi
while getopts "ih" opt; do
	case $opt in
		i)
			echo "Installing from packagelist";
			pacman -S --needed - < ../packagelist
			;;
		h)
			echo "use -i to install from packagelist" 
			;;
	esac
done
