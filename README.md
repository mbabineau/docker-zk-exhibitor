Runs an [Exhibitor](https://github.com/Netflix/exhibitor)-managed [ZooKeeper](http://zookeeper.apache.org/) instance using S3 for backups and automatic node discovery.

Available on the Docker Index as [mbabineau/zookeeper-exhibitor](https://index.docker.io/u/mbabineau/zookeeper-exhibitor/):

    docker pull mbabineau/zookeeper-exhibitor

### Versions
* Exhibitor 1.5.5
* ZooKeeper 3.4.6

### Usage (Using AWS for backup and coordination)
The container expects the following environment variables to be passed in:

* `HOSTNAME` - addressable hostname for this node (Exhibitor will forward users of the UI to this address)
* `S3_BUCKET` - (optional) bucket used by Exhibitor for backups and coordination
* `S3_PREFIX` - (optional) key prefix within `S3_BUCKET` to use for this cluster
* `AWS_ACCESS_KEY_ID` - (optional) AWS access key ID with read/write permissions on `S3_BUCKET`
* `AWS_SECRET_ACCESS_KEY` - (optional) secret key for `AWS_ACCESS_KEY_ID`
* `AWS_REGION` - (optional) the AWS region of the S3 bucket (defaults to `us-west-2`)
* `ZK_PASSWORD` - (optional) the HTTP Basic Auth password for the "zk" user
* `ZK_DATA_DIR` - (optional) Zookeeper data directory
* `ZK_LOG_DIR` - (optional) Zookeeper log directory
* `HTTP_PROXY_HOST` - (optional) HTTP Proxy hostname
* `HTTP_PROXY_PORT` - (optional) HTTP Proxy port
* `HTTP_PROXY_USERNAME` - (optional) HTTP Proxy username
* `HTTP_PROXY_PASSWORD` - (optional) HTTP Proxy password

Starting the container:

    docker run -p 8181:8181 -p 2181:2181 -p 2888:2888 -p 3888:3888 \
        -e S3_BUCKET=<bucket> \
        -e S3_PREFIX=<key_prefix> \
        -e AWS_ACCESS_KEY_ID=<access_key> \
        -e AWS_SECRET_ACCESS_KEY=<secret_key> \
        -e HOSTNAME=<host> \
        mbabineau/zookeeper-exhibitor:latest


## Usage (Using a static list of hosts, no automatick backup)

* `NO_AWS` - Set to any value except empty to disable AWS usage
* `HOSTNAME` - addressable hostname for this node (Exhibitor will forward users of the UI to this address)
* `SERVER_SPEC` - Zookeeper server spec. Example: 1:host1.net.com,2:host2.net.com 
* `ZK_PASSWORD` - (optional) the HTTP Basic Auth password for the "zk" user
* `ZK_DATA_DIR` - (optional) Zookeeper data directory
* `ZK_LOG_DIR` - (optional) Zookeeper log directory

Starting the container:

    docker run -p 8181:8181 -p 2181:2181 -p 2888:2888 -p 3888:3888 \
        -e SERVER_SPEC=<server-spec> \
        -e HOSTNAME=<host> \
        mbabineau/zookeeper-exhibitor:latest
Once the container is up, confirm Exhibitor is running:

    $ curl -s localhost:8181/exhibitor/v1/cluster/status | python -m json.tool
    [
        {
            "code": 3, 
            "description": "serving", 
            "hostname": "<host>", 
            "isLeader": true
        }
    ]
_See Exhibitor's [wiki](https://github.com/Netflix/exhibitor/wiki/REST-Introduction) for more details on its REST API._

You can also check Exhibitor's web UI at `http://<host>:8181/exhibitor/v1/ui/index.html`

Then confirm ZK is available:

    $ echo ruok | nc <host> 2181
    imok
