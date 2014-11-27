#!/bin/bash

FROM_MAIL_ADDRESS="test@example.com"
TO_MAIL_ADDRESS="test@example.com"

BASE_DIR=/app/xxx/batch/cplog

AAA_URLS=(
          "pool_check_url1"
          "pool_check_url2"
          )
BBB_URLS=(
          "pool_check_url3"
          "pool_check_url4"
          )
DEV_AAA_URLS=(
          "pool_check_url5"
          )
DEV_BBB_URLS=(
          "pool_check_url6"
          )

# Parameter
while getopts a:m: option; do
    case $option in
        "m" ) MOD="$OPTARG" ;;
        "a" ) ALERT_POOL_SIZE="$OPTARG";;
    esac
done

# Parameter check
if [ -z "${ALERT_POOL_SIZE}" ]; then
    echo -a:Alert pool size is necessary.
    exit 1
fi
CHECK=`expr "${ALERT_POOL_SIZE}" : '\([0-9][0-9]*\)'`
if [ "${ALERT_POOL_SIZE}" != "${CHECK}" ]; then
    echo -a:Alert pool size is numeric only.
    exit 1
fi

HOSTNAME=`hostname`
if [ "${MOD}" == "aaa" ]; then
    if [ ${HOSTNAME} == "devhost" ]; then
        WEB_URLS=("${DEV_AAA_URLS[@]}")
        ENV="dev"
    else
        WEB_URLS=("${AAA_URLS[@]}")
    fi
elif [ "${MOD}" == "bbb" ]; then
    if [ ${HOSTNAME} == "devhost" ]; then
        WEB_URLS=("${DEV_BBB_URLS[@]}")
        ENV="dev"
    else
        WEB_URLS=("${BBB_URLS[@]}")
    fi
else
    echo "Module name is null or module name is wrong "
    exit 1
fi

LOG_FILE=${BASE_DIR}/check_cp_size_${MOD}.log
LAST_YYYYMM=`date --date '1 month ago' '+%Y%m'`
TODAY_DD=`date '+%d'`

# Monthly Log Rotation
if [ "${TODAY_DD}" == "01" ]; then
    ROTATE_LOG_FILE=${LOG_FILE}.${LAST_YYYYMM}
    if [ -e ${ROTATE_LOG_FILE} ]; then
        echo "Log file rotation was already completed."
    else
        mv ${LOG_FILE} ${ROTATE_LOG_FILE}
        touch ${LOG_FILE}
    fi
fi

cnt=1
for url in ${WEB_URLS[@]}
do
    echo $url

    WEB_TMP_FILE=${BASE_DIR}/web0${cnt}status.${MOD}.tmp

    # Checking connection pool size
    wget ${url} -q -O ${WEB_TMP_FILE}
    
    # Get txActivePoolSize
    WEB_POOL_STATUS=`cat ${WEB_TMP_FILE}`
    WEB_TX_ACTIVE=`echo ${WEB_POOL_STATUS} | sed -e "s/maxPoolSize//" | sed -e "s/ freePoolSize//" | sed -e "s/ activePoolSize//" | sed -e "s/ txActivePoolSize//" | tr -d "\r" | cut -d":" -f5`

    if [ "${WEB_TX_ACTIVE}" != "" ]; then
        if [ ${WEB_TX_ACTIVE} -lt ${ALERT_POOL_SIZE} ]; then
            echo `date '+%Y/%m/%d %H:%M:%S'`"  INFO ${ENV}web20${cnt}xxx "${WEB_POOL_STATUS} >> ${LOG_FILE}
        else
            echo `date '+%Y/%m/%d %H:%M:%S'`" ERROR ${ENV}web20${cnt}xxx "${WEB_POOL_STATUS} >> ${LOG_FILE}
/usr/sbin/sendmail -t << EOT
From:${FROM_MAIL_ADDRESS}
To:${TO_MAIL_ADDRESS}
Subject:[SUK][DANGER][${ENV}web20${cnt}xxx]${MOD} txActivePoolSize is ${WEB_TX_ACTIVE} !![sachiko]

${MOD} ${ENV}web20${cnt}xxx's txActivePoolSize is ${WEB_TX_ACTIVE} !!

.
EOT
        fi
    fi
    
    cnt=$((cnt + 1))
done

exit 0
