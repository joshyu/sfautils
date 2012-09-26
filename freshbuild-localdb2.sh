#!/bin/bash
GITDIR="$HOME/gitrepos/sugarcrm/Mango"
BUILDPHPDIR="$GITDIR/build/rome"
SFAUTIL="$HOME/gitrepos/sugarcrm/sfautils"
WEBSUGARROOT="$HOME/gitrepos/sugarcrm/builds/ult/sugarcrm"
DATALOADERDIR="$GITDIR/ibm/dataloaders"

LOCATIONDIR=$HOME/gitrepos/sugarcrm/builds
flavor="ult"
version="6.4.0"
location_sugarbase=$LOCATIONDIR/$flavor/sugarcrm
INSTALL_URL="http://localhost:81/install.php?goto=SilentInstall&cli=true";
installType="$1"
haswebdir='';
sshAccount='db2inst1'
db2DB='SUGARJOS'


#=========================================================================================
#   subs
#=========================================================================================
do_dropdatabase(){
    echo "now init db2 database ";
    #echo "the function is not working";
    sudo su db2inst1 -c "sh /home/db2inst1/.profile && /home/db2inst1/bin/initDB.sh $db2DB"
    #. /home/db2inst1/.profile
    #/home/db2inst1/bin/initDB.sh $db2DB
    #exit 0;
}


do_cover(){
    echo "cover config_si_db2 file to sugarcrm build";
    if [ -e "$SFAUTIL/config_si_localdb2.php" ]
    then
        cp "$SFAUTIL/config_si_localdb2.php" "$location_sugarbase/config_si.php" ;
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

    chmod -R 0777 $WEBSUGARROOT
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
    cp "$SFAUTIL/dataloader_config_local.php" "$DATALOADERDIR/config.php";
    pushd $DATALOADERDIR > /dev/null 2>&1
    php populate_SmallDataset.php
    popd > /dev/null 2>&1  

    echo "Now run additional Action? (y/n)";
    case $yn in
        [Yy]* ) 
            do_runAdditionalActionAfterDataloader;
            break;;
        [Nn]* ) break;;
        * ) echo "Please answer yes or no.";;
    esac
}

do_runAdditionalActionAfterDataloader(){
    pushd $WEBSUGARROOT > /dev/null 2>&1
    cd custom/cli
    echo "Rebuild accounts_hierarchy";
    php -f cli.php task=RebuildClientHierarchy #(Rebuild accounts_hierarchy)
    echo "Update top tier nodes";
    php -f cli.php task=UpdateUsersTopTierNode # (Update top tier nodes)

    echo "FCH denormalization manager";
    cd -
    cd batch_sugar/RTC_19211
    php -f rtc_19211_main.php RTC_19211  # (FCH denormalization manager)

    echo "Additional Action completed";

    popd > /dev/null 2>&1  
}

do_removeSugarBuild(){
    echo "deleting existing sugarcrm build";
    sudo rm -rf "$location_sugarbase" ;
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

    #read -p "previous actions finished, prepare for dropping database , If you are Ready, press
    #[ENTER] to continue";
    
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
        
        #echo "if you see it install successfully, please run 'freshbuild-localdb2.sh dataloader' to import demo data ";
    else
        echo "db2 initializing Error";
    fi

elif [ $installType == 'dataloader' ];then
    do_rundataloader;

elif [ $installType == 'afterDataloader' ];then
    do_runAdditionalActionAfterDataloader;
elif [ $installType == 'update' ];then
    echo "sync local codebase with remote repo.";
    cd $GITDIR
    git fup
    git cupr
    git br -D ibm_current
    git co -b ibm_current
    git mupr
    git mups

elif [ $installType == 'test' ];then
    echo "run unittest over tests/ibm";
    cd $WEBSUGARROOT/tests
    php phpunit.php php tests/ibm

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
    echo "freshbuild-localdb2.sh for sugarcrm dev                ";
    echo "         by Josh Yu(yupengdl@cn.ibm.com)          ";
    echo "freshbuild-localdb2.sh help:   show this help menu     ";
    echo "freshbuild-localdb2.sh update: update the local codes     ";
    echo "freshbuild-localdb2.sh test:  run tests over tests/ibm    ";
    echo "freshbuild-localdb2.sh build:  build a brand new version";
    echo "freshbuild-localdb2.sh full:   fully build             ";
    echo "freshbuild-localdb2.sh incre:  incrementally build     ";
    echo "freshbuild-localdb2.sh clean:  remove config files     ";
    echo "freshbuild-localdb2.sh dropdb: drop database           ";
    echo "freshbuild-localdb2.sh install: install via cli        ";
    echo "freshbuild-localdb2.sh dataloader: import demo data    ";
    echo "freshbuild-localdb2.sh afterDataloader: additional action after dataloader    ";
    echo "==================================================";
elif [ ! -z $installType ];then
    echo "invalid command \"$installType\".";
    echo "please enter freshbuild-localdb2.sh help";
    exit 1;
fi
