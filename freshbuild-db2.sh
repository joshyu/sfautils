#!/bin/bash
SFABASE="/e/_joshyu_/data/IBM_projects/sfa"
GITDIR="$SFABASE/gitrepos/Mango"
BUILDPHPDIR="$GITDIR/build/rome"
SFAUTIL="$SFABASE/gitrepos/sfautils"
WEBSUGARROOT="$SFABASE/builds/ult/sugarcrm"
DATALOADERDIR="$GITDIR/ibm/dataloaders"

LOCATIONDIR=$SFABASE/builds
MYSQLBIN="/e/server/mysql55/bin"
MYSQLUNAME='root'
MYSQLUPASS='joshyupeng'
flavor="ult"
version="6.4.0"
location_sugarbase=$LOCATIONDIR/$flavor/sugarcrm
INSTALL_URL="http://localhost:81/install.php?goto=SilentInstall&cli=true";
installType="$1"
haswebdir='';
sshIp='9.115.146.146'
sshAccount='db2inst1'
db2DB='SUGARJOS'
db2server_path='~/sqllib/bin:~/sqllib/adm:~/sqllib/misc:~/sqllib/db2tss/bin'


#=========================================================================================
#   subs
#=========================================================================================
do_dropdatabase(){
    echo "now init db2 database with account:db2inst1";
    ssh $sshAccount@$sshIp:~/ "export PATH=\"$PATH:$db2server_path\"; ~/bin/initDB.sh $db2DB"    
}


do_cover(){
    echo "cover config_si_db2 file to sugarcrm build";
    if [ -e "$SFAUTIL/config_si_db2.php" ]
    then
        cp "$SFAUTIL/config_si_db2.php" "$location_sugarbase/config_si.php" ;
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

do_rundataloader(){
    echo "Running dataloader";
    echo "It will take you very long time, you can leave and take a cup of coffee.";
    cp "$SFAUTIL/dataloader_config.php" "$DATALOADERDIR/config.php";
    pushd $DATALOADERDIR > /dev/null 2>&1
    php populate_SmallDataset.php
    popd > /dev/null 2>&1  
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
    do_removeSugarBuild;
    do_build;
    do_cover;
    
    do_dropdatabase;
    if [ $? == 0 ];then
        echo "db2 initializing OK";
        do_install;
        while true; do
            echo -e "\n\n";
            read -p "Has the sugarcrm been installed successfully ?" yn
            case $yn in
                [Yy]* ) 
                    do_rundataloader; 
                    if [ $? == 0 ];then
                        echo "data imported successfully, please open the url and enjoy sugarcrm.";
                    else
                        echo "fail to import data";
                    fi
                    
                    break;;
                [Nn]* ) break;;
                * ) echo "Please answer yes or no.";;
            esac
        done
        
        #echo "if you see it install successfully, please run 'freshbuild-db2.sh dataloader' to import demo data ";
    else
        echo "db2 initializing Error";
    fi

elif [ $installType == 'dataloader' ];then
    do_rundataloader;

elif [ $installType == 'incre' ];then
    echo "Build Type: Incremental";
    do_backup;
    do_build;
    do_restore;
elif [ $installType == 'clean' ];then
    do_cleanConfig;
elif [ $installType == 'install' ];then
    do_install;
    while true; do
        echo -e "\n\n";
        read -p "Has the sugarcrm been installed successfully ?" yn
        case $yn in
            [Yy]* ) 
                do_rundataloader; 
                if [ $? == 0 ];then
                    echo "data imported successfully, please open the url and enjoy sugarcrm.";
                else
                    echo "fail to import data";
                fi
                
                break;;
            [Nn]* ) break;;
            * ) echo "Please answer yes or no.";;
        esac
    done
elif [ $installType == 'build' ];then

    do_removeSugarBuild;
    do_build;
elif [ $installType == 'dropdb' ];then
    do_dropdatabase;
    if [ $? == 0 ];then
        echo "db2 initializing OK";
    else
        echo "db2 initializing Error";
    fi

elif [ $installType == 'help' ];then
    echo "==================================================";
    echo "freshbuild-db2.sh for sugarcrm dev                ";
    echo "         by Josh Yu(yupengdl@cn.ibm.com)          ";
    echo "freshbuild-db2.sh help:   show this help menu     ";
    echo "freshbuild-db2.sh build:  build a brand new version";
    echo "freshbuild-db2.sh full:   fully build             ";
    echo "freshbuild-db2.sh incre:  incrementally build     ";
    echo "freshbuild-db2.sh clean:  remove config files     ";
    echo "freshbuild-db2.sh dropdb: drop database           ";
    echo "freshbuild-db2.sh install: install via cli        ";
    echo "freshbuild-db2.sh dataloader: import demo data    ";
    echo "==================================================";
elif [ ! -z $installType ];then
    echo "invalid command \"$installType\".";
    echo "please enter freshbuild-db2.sh help";
    exit 1;
fi
