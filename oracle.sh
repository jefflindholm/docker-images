#!/usr/bin/env bash

## https://github.com/oracle/docker-images/tree/master/OracleDatabase

SCRIPT_NAME="oracleDocker11Ex.sh";

LOC=`pwd`;
IMAGES_DIR=.;
ORACLE_DB=OracleDatabase/dockerfiles;
BUILD_IMAGE=buildDockerImage.sh;
DEFAULT_DB_VERSION="11.2.0.2"
ORACLE_DB_PATH=$LOC/$IMAGES_DIR/$ORACLE_DB;
COMMAND='';
DEBUG=0;
NOW=$(date +"%m_%d_%Y")

usage() {

cat << EOF
   location = $LOC
   Commands:
           - $SCRIPT_NAME install debug
           - $SCRIPT_NAME start debug
           - $SCRIPT_NAME stop debug
           - $SCRIPT_NAME reinstall debug
           - $SCRIPT_NAME ?
EOF

exit 0;
}

installOracleDbContainer() {

    if [ $DEBUG -eq 1 ]; then
        echo "$ORACLE_DB_PATH/$DEFAULT_DB_VERSION/";
        echo "cd $ORACLE_DB_PATH/$DEFAULT_DB_VERSION/";
        echo "Starting Install with version ${DEFAULT_DB_VERSION}";
    fi

    `cd $ORACLE_DB_PATH/ && . $ORACLE_DB_PATH/$BUILD_IMAGE -v $DEFAULT_DB_VERSION -x > ./installOutput_$NOW.txt`;

    if [ $? -ne 0 ]; then
        echo "exception during install => $?";
        exit 1;
    fi;

    initializeOracleDbContainer;

    if [ $DEBUG -eq 1 ]; then
        echo "Installation Data Log: File location $ORACLE_DB_PATH/installOutput_${NOW}.txt";
        cat $ORACLE_DB_PATH/installOutput_$NOW.txt;
    fi

    exit 0;
}

reinstallOracleDbContainer() {
    stopOracleDbContainer;
    removeOracleDbContainer;

    if [ $? -ne 0 ]; then
        echo "exception during reinstallOracleDbContainer => $?";
    fi;
   installOracleDbContainer;
}

initializeOracleDbContainer() {
    echo "Initializing oracle database container";

    `docker run -d --name oracle_db \
            --shm-size=2g \
            -p 1521:1521 \
            -p 8800:8080 \
            -e "ORACLE_PWD=pAssw0rd" \
            oracle/database:11.2.0.2-xe > ./initOutput_$NOW.txt &`;

    if [ $? -ne 0 ]; then
        echo "exception during initializeOracleDbContainer => $?";
        exit 1;
    fi;

    if [ $DEBUG -eq 1 ]; then
        echo "Initialization Log: file location $ORACLE_DB_PATH/initOutput_${NOW}.txt";
        cat $ORACLE_DB_PATH/initOutput_$NOW.txt;
    fi


}

updateOracleDbPassword() {
    echo "Initializing oracle database container password";
    `docker exec oracle_db /u01/app/oracle/setPassword.sh pAssw0rd > $ORACLE_DB_PATH/passwordUpdate_${NOW}.txt`;

    if [ $DEBUG -eq 1 ]; then
        echo "Password Initialization Log: file location $ORACLE_DB_PATH/passwordUpdate_${NOW}.txt";
        cat $ORACLE_DB_PATH/passwordUpdate_$NOW.txt;
    fi
}

startOracleDbContainer() {
    echo "Starting oracle_db container";
    `docker start oracle_db`;
}

stopOracleDbContainer() {
    echo "Stopping oracle_db container";
    `docker stop oracle_db > $ORACLE_DB_PATH/stopOutput.txt`;
    if [ $DEBUG -eq 1 ]; then
        echo "Docker oracle_db Stop Log: file location $ORACLE_DB_PATH/stopOutput.txt";
        cat $ORACLE_DB_PATH/stopOutput.txt;
    fi
}

removeOracleDbContainer() {
    echo "Removing oracle_db container";
    `docker container rm oracle_db > $ORACLE_DB_PATH/containeRemovalOutput.txt`;
    if [ $DEBUG -eq 1 ]; then
        echo "Docker oracle_db Stop Log: file location $ORACLE_DB_PATH/containeRemovalOutput.txt";
        cat $ORACLE_DB_PATH/containeRemovalOutput.txt;
    fi
}

NUM_ARGUMENTS_GIVEN="$#";
ARGUMENTS_GIVEN=("$@"); #Note you need to wrap the assignment of an array in () Why?
echo "arguments number = ${NUM_ARGUMENTS_GIVEN} and first argument is ${ARGUMENTS_GIVEN[0]}";

if [ "$#" -eq 0 -o "$#" -lt 1 ]; then
  usage;
fi

if [ ${NUM_ARGUMENTS_GIVEN} -eq 2 ]; then
    if [ ${ARGUMENTS_GIVEN[NUM_ARGUMENTS_GIVEN - 1 ]} = "debug" ]; then
        echo "Enabling Debugging for install";
        DEBUG=1;
    fi
fi

COMMAND=${ARGUMENTS_GIVEN[0]};

if [ "$COMMAND" = "install" ]; then
    installOracleDbContainer;
elif [ ${COMMAND} = "reinstall" ]; then
    reinstallOracleDbContainer;
elif [ ${COMMAND} = "start" ]; then
    startOracleDbContainer;
elif [ ${COMMAND} = "stop" ]; then
    stopOracleDbContainer;
else
    usage;
fi
