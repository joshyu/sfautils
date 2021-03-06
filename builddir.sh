#!/bin/bash
LOCATIONDIR=/F/_joshyu_/data/IBM_projects/sfa/builds
FILE=sugarcrm/$1
DIR=$GITDIR/sugarcrm/$1

pushd $BUILDPHPDIR > /dev/null 2>&1
php build.php -clean=0  --dir="$DIR" --flav="ult" --cleanCache=1 --base_dir="$GITDIR" --build_dir="$LOCATIONDIR" --ver="6.4.0" 
popd > /dev/null 2>&1
