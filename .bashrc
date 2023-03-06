#
# /etc/bash.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

[[ $DISPLAY ]] && shopt -s checkwinsize

PS1='[\u@\h \W]\$ '

parse_git_branch() {
	git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

PS1='[\u@\h \W $(parse_git_branch)]\$ '
case ${TERM} in
  xterm*|rxvt*|Eterm|aterm|kterm|gnome*)
	  PROMPT_COMMAND=${PROMPT_COMMAND:+$PROMPT_COMMAND; }'printf "\033]0;%s@%s:%s\007" "${USER}" "${HOSTNAME%%.*}" "${PWD/#$HOME/\~}"'

    ;;
  screen*)
	  PROMPT_COMMAND=${PROMPT_COMMAND:+$PROMPT_COMMAND; }'printf "\033_%s@%s:%s\033\\" "${USER}" "${HOSTNAME%%.*}" "${PWD/#$HOME/\~}"'
    ;;
esac

[ -r /usr/share/bash-completion/bash_completion   ] && . /usr/share/bash-completion/bash_completion

# McFly is a program i use to replace the Ctrl+R terminal search. Its a bit smarter.
eval "$(mcfly init bash)"
alias logs='lnav var/log/*';
alias mkdir='mkdir -p';
alias grep='grep --color';
alias hosts='vim /etc/hosts';
alias devilbox='cd ~/devilbox;docker-compose stop; docker-compose up httpd mysql php elasticsearch -d;';
# Bigger screen is left from the smaller one in my setup. Change --right-of to --left-of if its the oposite for you.
alias hdmi='xrandr --output eDP-1 --auto --output HDMI-1-0 --auto ; xrandr --output eDP-1 --right-of HDMI-1-0';
export GCM_CREDENTIAL_STORE='plaintext'

vimgrep(){
	vim $(grep -Rl $1 $2);
}
vimfind(){
	vim $(find $1 -name $2)
}
# Get fresh magento token
get_token(){
	project="$1";
	if [ -z "$project" ]; then
		project="dice";
	fi;
	curl -X POST \
	"http://$project.loc/rest/V1/integration/admin/token" \
  	-H 'Content-Type: application/json' \
	-d '{"username": "s.tonev","password":"Qwerty_2_Qwerty"}' | tr -d '"'
}
# Short-cut for magento API calls. You should not be concerned with the token.
alias magento_api='curl -H "Authorization: Bearer $(get_token)";';

export PATH=$PATH:/root/Work/Outsource/mongo-tools/bin:/root/Downloads/VSCode/bin;

###########################
# NGINX centric functions #
###########################

# $1 = log file; $2 = request code
nginx_requests_code () {
	cat "$1" |grep "HTTP/1\.1\" $2";
}

nginx_filter_resources () {
	cat "$1" |grep "HTTP/1\.1\" 200" |awk -F ' ' '{print $7}' | grep static | uniq -c;
}
nginx_today () {
	logdate="$(date +"%d/%b/%Y")";
	cat "$1" | grep "$logdate";
}
nginx_hourly () {
	daily="$(nginx_today $1)";
	counter=0;
	current_hour="$(date +"%H")";
	printf "%20s %20s %20s %20s" "At" "Total" "Success" "Redirect" "Other";
	while [ $(date +"%H") -gt $counter ]; do
		logdate="$(date +"%d/%b/%Y:%H" -d $counter)";
		requests="$(cat "$1" | grep "$logdate")";
		printf "%20s %20" $logdate "$(requests | grep "HTTP/1\.1\" 200")" "$(requests | grep "HTTP/1\.1\" 301\|HTTP/1\.1\" 302")" "$(requests | grep -v "HTTP/1\.1\" 200\|HTTP/1\.1\" 301\|HTTP/1\.1\" 302")";
	done;
}