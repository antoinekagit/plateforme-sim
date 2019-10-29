BASEDIR=$(dirname "$0")
OLD=$PWD
cd "$BASEDIR"
redis-server src/main/resources/redis.conf
cd "$OLD"
