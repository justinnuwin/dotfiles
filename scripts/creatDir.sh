if [ ! -d ~/.config ]; then 
	mkdir ~/.config;
fi

dir=(compton gtk-3.0 i3 polybar termite)
for i in $dir; do
	if [ ! -d ~/.config/$i ]; then 
		echo "creating $i"
		mkdir ~/.config/$i
	fi
done
