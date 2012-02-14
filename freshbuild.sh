#!/bin/bash
GITDIR=/F/_joshyu_/data/IBM_projects/sfa/gitrepos/Mango
LOCATIONDIR=/F/_joshyu_/data/IBM_projects/sfa/builds
BUILDPHPDIR=$GITDIR/build/rome
flavor="ult"
version="6.4.0"
silent="yes"
location_sugarbase=$LOCATIONDIR/$flavor/sugarcrm

#backup the config file.
if [ -d "$location_sugarbase" -a -e "$location_sugarbase/config.php"]
then
    haswebdir="true"
    echo "$0: Backing up config from $location_sugarbase" ;
    mv "$location_sugarbase/config.php" "/tmp" ;
        if [ -e "$location_sugarbase/config_override.php" ]
        then
        mv "$location_sugarbase/config_override.php" "/tmp" ;
        fi
    rm -rf "$location_sugarbase" ;
fi

pushd $BUILDPHPDIR > /dev/null 2>&1
php -n build.php --clean=0  --dir="$GITDIR/sugarcrm" --flav="$flavor" --cleanCache=1 --base_dir="$GITDIR" --build_dir="$LOCATIONDIR" --ver="$version"
popd > /dev/null 2>&1

if [ ! -z "$haswebdir" ]
then
echo "$0: Restoring config to $location_sugarbase" ;
mv "/tmp/config.php" "$location_sugarbase" ;
	if [ -e "/tmp/config_override.php" ]
	then
	mv "/tmp/config_override.php" "$location_sugarbase" ;
	fi
fi

if [ "$silent" == "yes" -a -e "./config_si.php" ]
then
cp "./config_si.php" "$location_sugarbase" ;
fi
