if [ -x "$(command -v mongorestore)" ] && [ -x "$(command -v mongodump)" ]; then
    export MONGO_USERNAME="";
    export MONGO_USERNAME="";

    mongodump(){
        mongodump "$MONGO_CONNECTION_URL" --username="$MONGO_USERNAME" --password="$MONGO_PASSWORD" --collection="$collection" -q="$query" --out "$output_file"
    }

    mongorestore(){
        if [ -z "$2" ]; then
            echo "mongorestore DB_NAME FILE_BSON";
            return;
        fi;
        mongorestore -u "$MONGO_USERNAME" -p "$MONGO_PASSWORD" --db="$1" "$2";
    }
fi;