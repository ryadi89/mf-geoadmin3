#!/bin/bash

T="$(date +%s)"

#bail out on any error
set -o errexit

# Check if snapshot parameter is supplied and there are 2 parameters
if [ "$2" != "int" ] && [ "$2" != "prod" ]
then
  echo "Error: Please specify 1) snapshot directoy and 2) target."
  exit 1
fi

SNAPSHOTDIR=/var/www/vhosts/mf-geoadmin3/private/snapshots/$1

# we assure that snapshot is re-build with new version
cwd=$(pwd)
cd $SNAPSHOTDIR/geoadmin/code/geoadmin
KEEP_VERSION=false
make all
cd $cwd

sudo -u deploy deploy -r deploy/deploy.cfg $2 $SNAPSHOTDIR

VARNISH_FLUSH_FILE=rc_int

if [ "$2" == "prod" ]
then
  VARNISH_FLUSH_FILE=rc_prod
fi

echo "Flushing varnishes"
source $VARNISH_FLUSH_FILE
for VARNISHHOST in ${VARNISH_HOSTS[@]}
do
  ./scripts/flushvarnish.sh $VARNISHHOST "${API_URL////}"
  echo "Flushed varnish at: ${VARNISHHOST}"
done

T="$(($(date +%s)-T))"

printf "Deploy time: %02d:%02d:%02d\n" "$((T/3600%24))" "$((T/60%60))" "$((T%60))"

