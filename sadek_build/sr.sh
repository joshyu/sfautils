# Specific to sadek's machine - change for your machine
gitbase="/home/sadek/www/git"
webbase="/home/sadek/www/html"

# defaults - change if you like
instance="ibm"
flavor="ent"
version="6.3.0"
silent="yes"
dir=""

usage="Usage: $0 INSTANCE_NAME DIR_TO_BUILD INSTALL VERSION_NUMBER FLAVOR\n   Defaults: INSTANCE_NAME=$instance DIR_TO_BUILD=<full build> SILENT_INSTALL=$silent VERSION_NUMBER=$version FLAVOR=$flavor"

if [ ! -z "$1" -a "$1" == "-h" ]
then
echo -e "$usage" ;
exit ;
fi

if [ ! -z "$1" ]
then
instance="$1" ;
fi

if [ ! -z "$2" ]
then
dir="$2" ;
fi

if [ ! -z "$3" ]
then
silent="$3" ;
fi

if [ ! -z "$4" ]
then
version="$4" ;
fi

if [ ! -z "$5" ]
then
flavor="$5"
fi

gitdir="$gitbase/$instance"
webdir="$webbase/$instance"

if [ ! -d "$webbase" ]
then
echo "Git directory $webbase doesn't exist. Check out a Sugar git repository to this directory or correct the repo name" ;
exit ;
fi

if [ ! -d "$gitdir" ]
then
echo "Git directory $gitdir doesn't exist. Check out a Sugar git repository to this directory or correct the repo name" ;
exit ;
fi

if [ ! -z "$dir" -a ! -e "$gitdir/sugarcrm/$dir" ]
then
echo "File or dir $gitdir/sugarcrm/$dir does not exist for building. Exiting." ;
exit ;
fi

echo "$0: Building from $gitdir" ;
echo "$0: Building to $webdir" ;

tempvar_two="$PWD";

if [ -d "$webdir/$flavor" -a -e "$webdir/$flavor/config.php" -a -z "$dir" ]
then
haswebdir="true"
echo "$0: Backing up config from $webdir/$flavor" ;
mv "$webdir/$flavor/config.php" "$webbase" ;
	if [ -e "$webdir/$flavor/config_override.php" ]
	then
	mv "$webdir/$flavor/config_override.php" "$webbase" ;
	fi
rm -rf "$webdir" ;
fi

cd "$gitdir/build/rome" ;
if [ -z "$dir" ]
then
php build.php --dir="$gitdir/sugarcrm" --flav="$flavor" --cleanCache=1 --base_dir="$gitdir/sugarcrm" --build_dir="$webdir" --ver="$version" ;
else
php build.php --dir="$gitdir/sugarcrm/$dir" --flav="$flavor" --cleanCache=1 --base_dir="$gitdir/sugarcrm" --build_dir="$webdir" --ver="$version" ;
fi

if [ ! -z "$haswebdir" ]
then
echo "$0: Restoring config to $webdir/$flavor" ;
mv "$webbase/config.php" "$webdir/$flavor/" ;
	if [ -e "$webbase/config_override.php" ]
	then
	mv "$webbase/config_override.php" "$webdir/$flavor/" ;
	fi
fi

if [ "$silent" == "yes" -a -e "$gitbase/config_si.php" ]
then
cp "$gitbase/config_si.php" "$webdir/$flavor/" ;
fi

## commands specific to sadek's system
echo "$0: Fixing permissions" ;
sudo chown sadek:www-data -R "$webdir" ;
sudo chmod 2777 -R "$webdir" ;

cd $tempvar_two ;
