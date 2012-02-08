#!/bin/bash
GITDIR=/F/_joshyu_/data/IBM_projects/sfa/gitrepos/Mango
LOCATIONDIR=/F/_joshyu_/data/IBM_projects/sfa/builds
BUILDPHPDIR=$GITDIR/build/rome

cd $BUILDPHPDIR
php build.php -clean=0  --dir="$GITDIR" --flav="ult" --cleanCache=1 --base_dir="$GITDIR" --build_dir="$LOCATIONDIR" --ver="6.4.0"