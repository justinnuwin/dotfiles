source ./dotFileList.sh

for i in ${!dotFile[@]}; do
    echo "cp ../backup/${dotFile[i]} ~/${dotFile[i]}"
    yes | cp "../backup/${dotFile[i]}" "${HOME}/.${dotFile[i]}"
done
