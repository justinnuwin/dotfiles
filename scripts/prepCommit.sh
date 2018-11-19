source ./dotFileList.sh

for i in ${!dotFile[@]}; do
    echo "cp ~/.${dotFile[i]} ../${dotFile[i]}"
    cp "${HOME}/.${dotFile[i]}" "../${dotFile[i]}"
done

# Changed to Qqe so pacman can read via
# pacman -S --needed - < ../packagelist
sudo pacman -Qqe > ../packagelist

