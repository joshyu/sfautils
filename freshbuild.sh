#!/bin/bash
SFABASE="/e/_joshyu_/data/IBM_projects/sfa"
GITDIR="$SFABASE/gitrepos/Mango"
BUILDPHPDIR="$GITDIR/build/rome"
SFAUTIL="$SFABASE/gitrepos/sfautils"
WEBSUGARROOT="$SFABASE/builds/ult/sugarcrm"

GITDIR=$SFABASE/gitrepos/Mango
LOCATIONDIR=$SFABASE/builds
BUILDPHPDIR=$GITDIR/build/rome
MYSQLBIN="/e/server/mysql55/bin"
MYSQLUNAME='root'
MYSQLUPASS='joshyupeng'
flavor="ult"
version="6.4.0"
location_sugarbase=$LOCATIONDIR/$flavor/sugarcrm
INSTALL_URL="http://localhost:81/install.php?goto=SilentInstall&cli=true";
installType="$1"
haswebdir='';

#=========================================================================================
#   subs
#=========================================================================================
do_dropdatabase(){
    echo "now drop database sugarcrm";
    pushd $MYSQLBIN > /dev/null 2>&1
    mysql -u$MYSQLUNAME -p$MYSQLUPASS -C -e"drop database sugarcrm";
    errorcode=$?;
    popd > /dev/null 2>&1

    if [ $errorcode == 0 ];then
        echo "drop database OK";
    else
        echo "drop database Fail.";
        return 255;
    fi
}


do_cover(){
    echo "cover config_si file to sugarcrm build";
    if [ -e "$SFAUTIL/config_si.php" ]
    then
        cp "$SFAUTIL/config_si.php" "$location_sugarbase" ;
    fi
}

do_restore(){
    if [ ! -z "$haswebdir" ]
    then
    echo "Restoring config to $location_sugarbase" ;
    mv "/tmp/config.php" "$location_sugarbase" ;
        if [ -e "/tmp/config_override.php" ]
        then
            mv "/tmp/config_override.php" "$location_sugarbase" ;
        fi
    fi

    if [ $? == 0 ];then
        echo "Restoring config OK";
    else
        echo "Restoring config Fail.";
    fi

}

do_cleanConfig(){
    pushd $location_sugarbase > /dev/null 2>&1
    if [ -e "config.php" ];then
        echo "remove config.php file";
        rm config.php;
    else
        echo "config.php not exist";
    fi

    if [ -e "config_override.php" ];then
        echo "remove config_override.php file";
        rm config_override.php
    else
        echo "config_override.php not exist";
    fi

    popd > /dev/null 2>&1  
}

do_backup(){
    #backup the config file.
    if [ -d "$location_sugarbase" -a -e "$location_sugarbase/config.php" ]
    then
        haswebdir="true";
        echo "Backing up config from $location_sugarbase" ;
        mv "$location_sugarbase/config.php" "/tmp" ;
        if [ -e "$locatinon_sugarbase/config_override.php" ]
        then
            mv "$location_sugarbase/config_override.php" "/tmp" ;
        fi
        #rm -rf "$location_sugarbase" ;
    fi
    
    if [ $? == 0 ];then
        echo "Backing up config OK";
    else
        echo "Backing up config Fail.";
    fi
}

do_build(){
    echo "now building new sugar build";
    pushd $BUILDPHPDIR > /dev/null 2>&1
    php -n build.php --clean=0  --dir="$GITDIR/sugarcrm" --flav="$flavor" --cleanCache=1 --base_dir="$GITDIR" --build_dir="$LOCATIONDIR" --ver="$version"
    popd > /dev/null 2>&1  
    echo "build OK";
}

do_install(){
    echo "silently install via curl";
    curl $INSTALL_URL;
}

do_removeSugarBuild(){
    echo "deleting existing sugarcrm build";
    rm -rf "$location_sugarbase" ;
    echo "delete OK";
}

######main function #####################
if [ -z $installType ];then
    installType='help';
fi

if [ $installType == 'full' ];then
    echo "Build Type: Full";
    
    do_dropdatabase;
    do_removeSugarBuild;
    do_build;
    do_cover;
    do_install;

elif [ $installType == 'incre' ];then
    echo "Build Type: Incremental";
    do_backup;
    do_build;
    do_restore;
elif [ $installType == 'clean' ];then
    do_cleanConfig;
elif [ $installType == 'dropdb' ];then
    do_dropdatabase;

elif [ $installType == 'help' ];then
    echo "==============================================";
    echo "freshbuild.sh for sugarcrm dev                ";
    echo "         by Josh Yu(yupengdl@cn.ibm.com)      ";
    echo "freshbuild.sh help:   show this help menu     ";
    echo "freshbuild.sh full:   fully build             ";
    echo "freshbuild.sh incre:  incrementally build     ";
    echo "freshbuild.sh clean:  remove config files     ";
    echo "freshbuild.sh dropdb: drop database           ";
    echo "==============================================";
elif [ ! -z $installType ];then
    echo "invalid command \"$installType\".";
    echo "please enter freshbuild.sh help";
    exit 1;
fi
