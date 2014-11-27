#!/bin/bash
#*******************************************************************************
#    Script name  : オンラインログファイルパージ処理
#    Parameter    : -e:ENV
#                       aws, dev, commerce
#    Return       : 0:正常終了／1:異常終了
#*******************************************************************************

while getopts e: option; do
    case $option in
        e) ENV="$OPTARG";;
    esac
done
# Check arguments
if [ -z "${ENV}" ]; then
    echo [`date '+%Y/%m/%d %H:%M:%S'`] -e: envは必須です。
    exit 1
fi

HOSTNAME=`hostname`

# 削除対象ログ
# Format :  保存日数, ログファイル名
#      ログファイルは日付でローテートされた形式のファイルのみ対応可能
#        -->  xxxx.log.YYYYMMDD
PURGE_LOGS_COMMERCE=(
               "10,/var/tomcatlog/xxx/ROOT/exception_${HOSTNAME}.log."
               "10,/var/tomcatlog/xxx/ROOT/r2profile_parameter_${HOSTNAME}.log."
             )
PURGE_LOGS_DEV=(
               "5,/var/tomcatlog/xxx/ROOT/exception_${HOSTNAME}.log."
               "5,/var/tomcatlog/xxx/ROOT/r2profile_parameter_${HOSTNAME}.log."
             )
PURGE_LOGS_AWS=(
               "5,/var/tomcatlog/xxx/ROOT/exception_${HOSTNAME}.log."
               "5,/var/tomcatlog/xxx/ROOT/r2profile_parameter_${HOSTNAME}.log."
             )

case ${ENV} in
    commerce )
        PURGE_LOGS=("${PURGE_LOGS_COMMERCE[@]}")
    ;;
    dev )
        PURGE_LOGS=("${PURGE_LOGS_DEV[@]}")
    ;;
    aws )
        PURGE_LOGS=("${PURGE_LOGS_AWS[@]}")
    ;;
    *)
        echo "Invalid ENV : $ENV  ---> commerce or dev or aws"
        exit 1
    ;;
esac

OUTPUT_LOG_DIR=/web/xxx/admintools/log/`date '+%Y%m%d'`
OUTPUT_LOG_FILE=${OUTPUT_LOG_DIR}/OnlineLogFilesPurge.log
if [ ! -d ${OUTPUT_LOG_DIR} ]; then
    mkdir ${OUTPUT_LOG_DIR}
fi

echo [`date '+%Y/%m/%d %H:%M:%S'`][${HOSTNAME}][${ENV}] オンラインログファイルのパージ処理を開始します。 | tee -a  ${OUTPUT_LOG_FILE}

for purgelog in ${PURGE_LOGS[@]}
do
    arr=( `echo $purgelog | tr -s ',' ' '` )
    SAVE_DAY=${arr[0]}
    LOG=${arr[1]}'*'
    echo "■save_day=$SAVE_DAY  target=$LOG" | tee -a ${OUTPUT_LOG_FILE}

    # 圧縮
    ls $LOG | grep -v gz$ | while read line; do
        echo "  gzip $line" | tee -a ${OUTPUT_LOG_FILE}
        gzip $line
    done

    # 削除
    ls $LOG | grep gz$ | while read line; do
        if [ ! -z "${SAVE_DAY}" ]; then
            LOG_DAY=${line:`expr ${#line} - 11`:8}
            DELETE_DAY=`date "+%Y%m%d" -d "${SAVE_DAY} days ago"`

            echo "  log_day=${LOG_DAY}  delete_day=${DELETE_DAY}" | tee -a ${OUTPUT_LOG_FILE}

            if [ ${LOG_DAY} -lt ${DELETE_DAY} ]; then
                echo "      -->削除ファイル:${line}" | tee -a ${OUTPUT_LOG_FILE}
                rm $line
            fi
        fi
    done
done

echo [`date '+%Y/%m/%d %H:%M:%S'`][${HOSTNAME}][${ENV}] オンラインログファイルのパージ処理が完了しました。 | tee -a ${OUTPUT_LOG_FILE}
echo "================================================================================" | tee -a ${OUTPUT_LOG_FILE}

exit 0
