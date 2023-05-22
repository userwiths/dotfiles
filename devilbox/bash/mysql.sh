if [ -x "$(command -v mysql)" ]; then
    export MYSQL_SERVER_ADDRESS="172.16.238.12";
    export MYSQL_USER="root";
    export MYSQL_PASSWORD="root";

    alias mysql="mysql -u$MYSQL_USER -p$MYSQL_PASSWORD -h $MYSQL_SERVER_ADDRESS";

    mysqldump(){
        mysqldump -u$MYSQL_USER -p$MYSQL_PASSWORD -h $MYSQL_SERVER_ADDRESS "$@";
    }
fi;