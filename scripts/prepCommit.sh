source ./dotFileList.sh

for i in ${!dotFile[@]}; do
    echo "cp ~/.${dotFile[i]} ../${dotFile[i]}"
    cp "${HOME}/.${dotFile[i]}" "../${dotFile[i]}"
done

sudo pacman -Qe > ../packagelist
