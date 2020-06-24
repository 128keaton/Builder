function transfer() {
  if [ "$SCP" == true ]; then
    tput bel
    scp -r ./Products/"$NAME".nbi "$SCP_TO_USERNAME"@"$SCP_TO":"$SCP_TO_FOLDER"
  fi
}
