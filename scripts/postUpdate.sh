source ./dotFileList.sh

./backupLocal.sh

for i in ${!dotFile[@]}; do
    echo "cp ../${dotFile[i]} ~/${dotFile[i]}"
    yes | cp "../${dotFile[i]}" "${HOME}/.${dotFile[i]}"
done
