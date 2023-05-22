export ELASTIC_SERVER="172.16.238.26";

if [ ! -x "$(command -v jq)" ]; then
	alias jq="echo";
fi;

elastic_watermark_disable(){
	curl -XPUT "$ELASTIC_SERVER:9200/_cluster/settings" -H "Content-Type: application/json" -d '{
		"transient" : {
			"cluster.routing.allocation.disk.threshold_enabled" : false
		}
	}' | jq;
}

elastic_watermark_enable(){
	curl -XPUT "$ELASTIC_SERVER:9200/_cluster/settings" -H "Content-Type: application/json" -d '{
		"transient" : {
			"cluster.routing.allocation.disk.threshold_enabled" : true
		}
	}' | jq;
}

elastic_delete_all () {
	curl -XDELETE "$ELASTIC_SERVER:9200/_all" | jq;
}

elastic_allow_delete() {
	curl -XPUT -H "Content-Type: application/json" http://$ELASTIC_SERVER:9200/_all/_settings -d '{"index.blocks.read_only_allow_delete": null}' | jq;
}