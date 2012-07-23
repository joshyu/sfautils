#!/bin/bash
GITDIR=/e/_joshyu_/data/IBM_projects/sfa/gitrepos/Mango
LOCATIONDIR=/e/_joshyu_/data/IBM_projects/sfa/builds
BUILDPHPDIR=$GITDIR/build/rome
flavor="ult"
version="6.4.0"

pushd $BUILDPHPDIR > /dev/null 2>&1
php -n build.php --clean=0  --dir="$GITDIR/sugarcrm" --flav="$flavor" --cleanCache=1 --base_dir="$GITDIR" --build_dir="$LOCATIONDIR" --ver="$version"
popd > /dev/null 2>&1
