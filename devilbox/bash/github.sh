export GITHUB_USER="stiliyantonev"; # github.sh
export GITHUB_TOKEN="TOKEN"; # github.sh
export GITHUB_ORGANIZATION="belugait"; # github.sh

get_github_repo () {
	part="$(get_github_repo_url "$1" | awk -F '//' '{print $2}')";
	echo "https://$GITHUB_USER:$GITHUB_TOKEN@$part";
}
# Get repo link containing the argument, choose the shortest link.
get_github_repo_url () {
	curl -u $GITHUB_USER:$GITHUB_TOKEN "https://api.github.com/orgs/$GITHUB_ORGANIZATION/repos?per_page=80" |\
	grep clone_url |\
	grep "$1" |\
	awk -F '"' '{print $4}' |\
	sort -n |\
	head -n 1;
}

if [ -f "/usr/share/bash-completion/completions/git" ];then
	source /usr/share/bash-completion/completions/git;
fi;
