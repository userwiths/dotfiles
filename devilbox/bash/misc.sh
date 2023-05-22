export HISTCONTROL=ignoredups:erasedups
shopt -s autocd
shopt -s cdspell

alias echo="echo -e";
alias mkdir='mkdir -p';
alias grep='grep --color';

commit_msg () {
	message="AUTO-GENERATED:";
	message="$message $(curl --silent 'https://whatthecommit.com/index.txt')";
	git commit -m "$message";
}

extract ()
{
  if [ -f "$1" ] ; then
    case $1 in
      *.tar.bz2)   tar xjf $1   ;;
      *.tar.gz)    tar xzf $1   ;;
      *.bz2)       bunzip2 $1   ;;
      *.rar)       unrar x $1   ;;
      *.gz)        gunzip $1    ;;
      *.tar)       tar xf $1    ;;
      *.tbz2)      tar xjf $1   ;;
      *.tgz)       tar xzf $1   ;;
      *.zip)       unzip $1     ;;
      *.Z)         uncompress $1;;
      *.7z)        7z x $1      ;;
      *.deb)       ar x $1      ;;
      *.tar.xz)    tar xf $1    ;;
      *.tar.zst)   unzstd $1    ;;
      *)           echo "'$1' cannot be extracted via ex()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

cpf () {
	src="$1";
	dst="$2";
	if [ -z "$dst" ]; then
		mkdir -p "$(get_only_path "$dst")";
	fi;
	cp "$src" "$dst";
}

get_only_path () {
	echo "$1" | awk -F'/' -v OFS='/' '{$NF=""}1';
}

urlencode() {
  local i= char= url=$*
  declare -i len=${#url}

  for (( i = 0; i < len; i++ )); do
    char=${url:i:1}
    case "$char" in
      [a-zA-Z0-9.~_-]) printf "$char" ;;
      ' ') printf + ;;
      *) printf '%%%X' "'$char" ;;
    esac
  done
}

vimgrep(){
	vim $(grep -Rl $1 $2);
}
vimfind(){
	vim $(find $1 -name $2)
}
tldr(){
  local IFS=-
  curl cheat.sh/"$*"
}
addtopath () {
	if [ -z "$1" ]; then
		path="$PWD";
	else
		path="$1";
	fi;

	if [ -f "$path" ]; then
		export PATH="$PATH:$path";
	fi;
}

sync_date_time() {
	date -s "$(curl "http://worldtimeapi.org/api/ip" | jq '.datetime' | awk -F 'T' '{print $2}'|awk -F '.' '{print $1}')";
}

back() {
	cd "$OLDPWD";
}

up () {
  local d=""
  local limit="$1"

  # Default to limit of 1
  if [ -z "$limit" ] || [ "$limit" -le 0 ]; then
    limit=1
  fi

  for ((i=1;i<=limit;i++)); do
    d="../$d"
  done

  # perform cd. Show error if cd fails
  if ! cd "$d"; then
    echo "Couldn't go up $limit dirs.";
  fi
}