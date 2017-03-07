#!/bin/bash -e

# Generates the default exhibitor config and launches exhibitor

MISSING_VAR_MESSAGE="must be set"
DEFAULT_DATA_DIR="/opt/zookeeper/snapshots"
DEFAULT_LOG_DIR="/opt/zookeeper/transactions"
HTTP_PROXY=""
: ${HOSTNAME:?$MISSING_VAR_MESSAGE}

: ${ZK_DATA_DIR:=$DEFAULT_DATA_DIR}
: ${ZK_LOG_DIR:=$DEFAULT_LOG_DIR}
: ${HTTP_PROXY_HOST:=""}
: ${HTTP_PROXY_PORT:=""}
: ${HTTP_PROXY_USERNAME:=""}
: ${HTTP_PROXY_PASSWORD:=""}

function fileconfig {
    cat <<- EOF > /opt/exhibitor/defaults.conf
zookeeper-data-directory=$ZK_DATA_DIR
zookeeper-install-directory=/opt/zookeeper
zookeeper-log-directory=$ZK_LOG_DIR
log-index-directory=$ZK_LOG_DIR
cleanup-period-ms=300000
check-ms=30000
backup-period-ms=600000
client-port=2181
cleanup-max-files=20
backup-max-store-ms=0
connect-port=2888
backup-extra=
observer-threshold=0
election-port=3888
zoo-cfg-extra=tickTime\=2000&initLimit\=10&syncLimit\=5&quorumListenOnAllIPs\=true
auto-manage-instances-settling-period-ms=0
auto-manage-instances=0
servers-spec=$SERVERS_SPEC
EOF

    if [[ -n ${ZK_PASSWORD} ]]; then
        SECURITY="--security web.xml --realm Zookeeper:realm --remoteauth basic:zk"
        echo "zk: ${ZK_PASSWORD},zk" > realm
    fi

    if [[ -n $HTTP_PROXY_HOST ]]; then
        cat <<- EOF > /opt/exhibitor/proxy.properties
com.netflix.exhibitor.s3.proxy-host=${HTTP_PROXY_HOST}
com.netflix.exhibitor.s3.proxy-port=${HTTP_PROXY_PORT}
com.netflix.exhibitor.s3.proxy-username=${HTTP_PROXY_USERNAME}
com.netflix.exhibitor.s3.proxy-password=${HTTP_PROXY_PASSWORD}
EOF

        HTTP_PROXY="--s3proxy=/opt/exhibitor/proxy.properties"
    fi

    exec 2>&1

    java -jar /opt/exhibitor/exhibitor.jar \
        --port 8181 --defaultconfig /opt/exhibitor/defaults.conf \
        --hostname ${HOSTNAME} \
        ${HTTP_PROXY} \
        --fsconfigdir /opt/exhibitor/data \
        --configtype file \
        ${SECURITY}
}

if [ -z "$NO_AWS" ]
then
    . original-wrapper.sh
else
    : ${SERVERS_SPEC:?$MISSING_VAR_MESSAGE}
    fileconfig
fi
