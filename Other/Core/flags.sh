# flags.sh

for i in "$@"
do
case $i in
    -skippkg=*|--skip-packages=*)
    SKIP_PACKAGE_INSTALL="${i#*=}"
    shift # past argument=value
    ;;
    -dmg=*|--base-disk-image=*)
    BASE_SYSTEM_PATH="${i#*=}"
    shift # past argument=value
    ;;
    *)
          # unknown option
    ;;
esac
done
