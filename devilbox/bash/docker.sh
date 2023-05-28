export USE_DOCKER_V2="";

if [ -z "$USE_DOCKER_V2" ]; then
    alias dc="docker-compose";
    alias dcr="docker-compose restart";
    alias dcs="docker-compose stop";
    alias dcu="docker-compose up ";
    alias dce="docker-compose exec ";
else
    alias dc="docker compose";
    alias dcr="docker compose restart";
    alias dcs="docker compose stop";
    alias dcu="docker compose start";
    alias dce="docker compose exec";
fi;