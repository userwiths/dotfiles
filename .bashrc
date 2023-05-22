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
# Currently (2023-03-14) it is broken for the 6.2.2 kernel due to a deprecated call.
#eval "$(mcfly init bash)"

export HISTIGNORE="ls:bg:fg:exit:reset:clear:cd"
export HISTCONTROL=ignoredups:erasedups
export PATH=$PATH:/root/Downloads/VSCode/bin;
export VISUAL=vim;
export EDITOR=vim;
export GCM_CREDENTIAL_STORE='plaintext'


shopt -s autocd # change to named directory
shopt -s cdspell # autocorrects cd misspellings
shopt -s cmdhist # save multi-line commands in history as single line
shopt -s dotglob
shopt -s histappend # do not overwrite history
shopt -s expand_aliases # expand aliases
shopt -s checkwinsize # checks term size when bash regains control
shopt -s globstar # pattern ** also searches subdirectories

#ignore upper and lowercase when TAB completion
bind "set completion-ignore-case on"

alias make="rm *.o; make";
alias logs='lnav var/log/*';
alias mkdir='mkdir -p';
alias grep='grep --color';
alias hosts='vim /etc/hosts';
alias devilbox='cd ~/devilbox;docker-compose stop; docker-compose up httpd mysql php php81 elasticsearch';
alias gtop='LANG=en_US.utf8 TERM=xterm-256color gtop';
alias du="du -sh ";
alias dc="docker-compose";
alias dcr="docker-compose restart";
alias dcs="docker-compose stop";
alias dcu="docker-compose up ";
alias dce="docker-compose exec ";

commit_msg () {
	message="AUTO-GENERATED:";
	message="$message $(curl --silent 'https://whatthecommit.com/index.txt')";
	git commit -m "$message";
}
# Bigger screen is left from the smaller one in my setup. Change --right-of to --left-of if its the oposite for you.
alias hdmi='xrandr --output eDP-1 --auto --output HDMI-1-0 --auto ; xrandr --output eDP-1 --right-of HDMI-1-0';
alias vscode="code --no-sandbox --user-data-dir ~/.vscode-stable/";
alias list_packages="comm -23 <(pacman -Qqett | sort) <(pacman -Qqg base -g base-devel | sort | uniq)";
alias piplist="pip freeze";
alias pipclear="pip freeze | xarg pip uninstall ";

dc_name_from_service(){
	docker-compose ps --format "json" | jq ".[] | select(.Service==\"$1\") | .Name";
}
docker_ip(){
	name="$(dc_name_from_service $1)"
	id="$(docker container ls --format json | jq ".[] | select(.Names==$name) | .ID")";
	docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$id";
}

magento_get_layout (){
	url="$1";
	if [ -z "$url" ]; then
		url="http://dice.loc";
	fi;
	#Get classes of body element
	classes=$(curl -s "$url" | grep -oP '(?<=html-body" class=")(.*)(?=">)');
	# Cycle through classes 
	for class in $( echo "$classes"| tr " " "\n"); do
		#replace - with _
		class=$(echo "$class" | tr "-" "_");
		#Search in files
		find ./{vendor/magento,app} -type f -name "$class.xml" -exec echo {} \;
	done;
}
# Get fresh magento token
get_token(){
	project="$1";
	username="$2";
	password="$3";
	if [ -z "$username" ]; then
		username="s.tonev";
	fi;
	if [ -z "$password" ]; then
		password="Qwerty_2_Qwerty";
	fi;
	if [ -z "$project" ]; then
		project="dice";
	fi;
	project = "$project.loc";
	if [[ $1 = "http"* ]]; then
		project = "$1"
	else
		project = "http://$project";
	fi;
	curl -X POST \
	"$project/rest/V1/integration/admin/token" \
  	-H 'Content-Type: application/json' \
	-d '{"username": "s.tonev","password":"Qwerty_2_Qwerty"}' | tr -d '"'
}
magento_graphql(){
	curl "$1/graphql" \
		-H 'Accept-Encoding: gzip, deflate, br' \
		-H 'Content-Type: application/json' \
		-H 'Accept: application/json' \
		-H 'Connection: keep-alive' \
		--data-binary '{"query":"query {\n    products(filter: {sku: {eq: \"test\"}}) {\n    items {\n      name\n      sku\n    }\n  }\n}","variables":{}}'\
		--compressed
}
# Short-cut for magento API calls. You should not be concerned with the token.
alias magento_api='curl -H "Authorization: Bearer $(get_token)";';

magento_rebuild () {
	if [ -z "$2" ]; then
		phpvers="php";
		proj="$1";
	else
		phpvers="$1";
		proj="$2";
	fi;

	docker-compose exec -it $phpvers bash -c "source /etc/bashrc-devilbox.d/*.sh; magento_rebuild $proj";
}
get_layout_elements () {
	condition="//*[@name][name()='container' or name()='block' or name()='referenceContainer' or name()='referenceBlock']";
	call_xml_starlet "$condition" $1;
}
get_containers () {
	condition="//*[@name][name()='container' or name()='referenceContainer']";
	call_xml_starlet "$condition" $1;
}
get_block () {
	condition="//*[@name][name()='block' or name()='referenceBlock']";
	call_xml_starlet "$condition" $1;
}
get_references(){
	condition="//*[@name][name()='referenceContainer' or name()='referenceBlock']";
	call_xml_starlet "$condition" $1;
}
call_xml_starlet () {
	find $2 -path */layout/* -name *.xml -not -path *Test* -not -path */test* \
		-exec xmlstarlet sel -t -m "$1" \
		-f -o " " -v "name()" -o " " -v "@name" \
		-o " '" -v "@htmlClass" -o "'" -o " '" -v "@template" -o "'" -o " '" -v "@class" -o "'" -n {} \;
}
# file, parent, name, class, template
add_layout_block () {
	filename="$1";
	parent="$2";
	name="$3";
	class="$4";
	template="$5";
	tempBlockName="automationBlock";
	if [ -z "$parent" ]; then
		parent="content";
	fi;
	if [ -z "$class" ]; then
		class="Magento\Framework\View\Element\Template";
	fi;
	result="$(xml ed -s "//*[@name='$parent']" -t elem -n "$tempBlockName" -v "" \
		-i "//*[name()='$tempBlockName']" -t attr -n "class" -v "$class" \
		-i "//*[name()='$tempBlockName']" -t attr -n "name" -v "$name" \
		-i "//*[name()='$tempBlockName']" -t attr -n "template" -v "$template" \
		-r "//*[name()='$tempBlockName']" -v "block" \
		"$filename")";
	echo "$result" > "$filename";
}
# file to change, css file.
add_layout_css () {
	filename="$1";
	path="$2";
	tempBlockName="automationBlock";
	parent="head";
	if [ -z "$path" ]; then
		path="$filename";
		filename=$(find ./app/design/frontend -name default.xml -type f | head -n 1);
	fi;
	if [ -z "$(has_tag $parent $filename)" ]; then
		add_tag "page" "$parent" "$filename";
		add_layout_css "$filename" "$path";
		return;
	fi;
	if [[ "$path" = "http"* ]]; then
		result="$(xml ed -s "//*[name()='$parent']" -t elem -n "$tempBlockName" -v "" \
			-i "//*[name()='$tempBlockName']" -t attr -n "src_type" -v "url" \
			-i "//*[name()='$tempBlockName']" -t attr -n "src" -v "$path" \
			-r "//*[name()='$tempBlockName']" -v "css" \
			"$filename")";
	else
		result="$(xml ed -s "//*[name()='$parent']" -t elem -n "$tempBlockName" -v "" \
			-i "//*[name()='$tempBlockName']" -t attr -n "src" -v "$path" \
			-r "//*[name()='$tempBlockName']" -v "css" \
			"$filename")";
	fi;
	echo "$result" > "$filename";
}
# file to change, css file.
add_layout_js () {
	filename="$1";
	path="$2";
	tempBlockName="automationBlock";
	parent="head";
	if [ -z "$path" ]; then
		path="$filename";
		filename=$(find ./app/design/frontend -name default.xml -type f | head -n 1);
	fi;
	if [ -z "$(has_tag $parent $filename)" ]; then
		add_tag "page" "$parent" "$filename";
		add_layout_js "$filename" "$path";
		return;
	fi;
	if [[ "$path" = "http"* ]]; then
		result="$(xml ed -s "//*[name()='$parent']" -t elem -n "$tempBlockName" -v "" \
			-i "//*[name()='$tempBlockName']" -t attr -n "src_type" -v "url" \
			-i "//*[name()='$tempBlockName']" -t attr -n "src" -v "$path" \
			-r "//*[name()='$tempBlockName']" -v "script" \
			"$filename")";
	else
		result="$(xml ed -s "//*[name()='$parent']" -t elem -n "$tempBlockName" -v "" \
			-i "//*[name()='$tempBlockName']" -t attr -n "src" -v "$path" \
			-r "//*[name()='$tempBlockName']" -v "script" \
			"$filename")";
	fi;
	echo "$result" > "$filename";
}
add_tag () {
	parent="$1";
	tag="$2";
	file="$3";
	result="$(xml ed -s "//*[name()='$parent']" -t elem -n "$tag" -v "" "$file")";
	echo "$result" > "$file";
}
has_tag () {
	tag="$1";
	file="$2";
	xmlstarlet sel -t -m "//*[name()='$tag']" -f -n "$file";# | wc -l;
}

source ~/devilbox/bash/misc.sh;
source ~/devilbox/bash/elastic.sh;
source ~/devilbox/bash/mysql.sh;
source ~/devilbox/bash/dotnet.sh;