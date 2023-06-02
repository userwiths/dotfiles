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

git_ignore_chmod () {
	git config core.fileMode false;
}

just_commit () {
	message="AUTO-GENERATED:";
	message="$message $(curl --silent 'https://whatthecommit.com/index.txt')";
	git commit -m "$message";
}

if [ -f "/usr/share/bash-completion/completions/git" ];then
	source /usr/share/bash-completion/completions/git;
fi;

export -f get_github_repo;
export -f git_ignore_chmod;