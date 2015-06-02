#/bin/bash -e

# Generates the default exhibitor config and launches exhibitor

MISSING_VAR_MESSAGE="must be set"
DEFAULT_AWS_REGION="us-west-2"
DEFAULT_DATA_DIR="/opt/zookeeper/snapshots"
DEFAULT_LOG_DIR="/opt/zookeeper/transactions"
S3_SECURITY=""
HTTP_PROXY=""
: ${HOSTNAME:?$MISSING_VAR_MESSAGE}
: ${AWS_REGION:=$DEFAULT_AWS_REGION}
: ${ZK_DATA_DIR:=$DEFAULT_DATA_DIR}
: ${ZK_LOG_DIR:=$DEFAULT_LOG_DIR}
: ${HTTP_PROXY_HOST:=""}
: ${HTTP_PROXY_PORT:=""}
: ${HTTP_PROXY_USERNAME:=""}
: ${HTTP_PROXY_PASSWORD:=""}

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
	backup-max-store-ms=21600000
	connect-port=2888
	observer-threshold=0
	election-port=3888
	zoo-cfg-extra=tickTime\=2000&initLimit\=10&syncLimit\=5&quorumListenOnAllIPs\=true
	auto-manage-instances-settling-period-ms=0
	auto-manage-instances=1
EOF


if [[ -n ${AWS_ACCESS_KEY_ID} ]]; then
  cat <<- EOF > /opt/exhibitor/credentials.properties
    com.netflix.exhibitor.s3.access-key-id=${AWS_ACCESS_KEY_ID}
    com.netflix.exhibitor.s3.access-secret-key=${AWS_SECRET_ACCESS_KEY}
EOF

  echo 'backup-extra=throttle\=&bucket-name\=${S3_BUCKET}&key-prefix\=${S3_PREFIX}&max-retries\=4&retry-sleep-ms\=30000' >> /opt/exhibitor/defaults.conf

  S3_SECURITY="--s3credentials /opt/exhibitor/credentials.properties"
  BACKUP_CONFIG="--configtype s3 --s3config ${S3_BUCKET}:${S3_PREFIX} ${S3_SECURITY} --s3region ${AWS_REGION} --s3backup true"
else
  BACKUP_CONFIG="--configtype none"
fi

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

# If we use exec and this is the docker entrypoint, Exhibitor fails to kill the ZK process on restart.
# If we use /bin/bash as the entrypoint and run wrapper.sh by hand, we do not see this behavior. I suspect
# some init or PID-related shenanigans, but I'm punting on further troubleshooting for now since dropping
# the "exec" fixes it.
#
# exec java -jar /opt/exhibitor/exhibitor.jar \
# 	--port 8181 --defaultconfig /opt/exhibitor/defaults.conf \
# 	--configtype s3 --s3config thefactory-exhibitor:${CLUSTER_ID} \
# 	--s3credentials /opt/exhibitor/credentials.properties \
# 	--s3region us-west-2 --s3backup true

java -jar /opt/exhibitor/exhibitor.jar \
  --port 8181 --defaultconfig /opt/exhibitor/defaults.conf \
  ${BACKUP_CONFIG} \
  ${HTTP_PROXY} \
  --hostname ${HOSTNAME} \
  ${SECURITY}
