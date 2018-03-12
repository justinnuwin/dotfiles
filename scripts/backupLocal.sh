source ./dotFileList.sh

for i in ${!dotFile[@]}; do
    echo "cp ~/.${dotFile[i]} ../backup/${dotFile[i]}"
    mkdir -p "../backup/${dotFile[i]}"
    cp "${HOME}/.${dotFile[i]}" "../backup/${dotFile[i]}"
done
