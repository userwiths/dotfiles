#!/usr/bin/env bash
export ADMIN_USER="s.tonev"; 
export ADMIN_EMAIL="s.tonev@beluga.software";
export ADMIN_PASSWORD="Qwerty_2_Qwerty";
export BACKEND_DEPLOY_LANGUAGES="en_US";
export FRONTEND_DEPLOY_LANGUAGES="bg_BG en_US";
export DEPLOY_JOBS_COUNT=3;
export APPLIED_ACCESS_CODE="777";
export ROOT_DIR="/shared/httpd";
export SYM_LINK_NAME="htdocs";

. /etc/bashrc-devilbox.d/misc.sh;
. /etc/bashrc-devilbox.d/mysql.sh;
. /etc/bashrc-devilbox.d/elastic.sh;
. /etc/bashrc-devilbox.d/github.sh;
. /etc/bashrc-devilbox.d/jq.sh;
. /etc/bashrc-devilbox.d/composer.sh;

# Affects the symlink generation.
export USE_NGINX=1;

alias magento_admin_url='magento info:adminuri';
alias artisan='php artisan ';

# Functions can be called from host using `docker-compose exec` aliases can't :(.
magento(){
	php bin/magento "$@";
}
magento_access(){
	chmod -R $APPLIED_ACCESS_CODE {var,generated,pub,app/etc}
}
magento_disable_sign() {
	magento config:set dev/static/sign 0;
}
cache(){
	magento c:c; magento c:f; magento_access
}
magento_cache(){
	magento c:c; magento c:f; magento_access
}
magento_update(){
	composer_exec update;
	magento_rebuild;
}
magento_add_less_to_module () {
	if [ -z "$1" ]; then
		echo "Please provide a Module path.";
		return;
	fi;
	if [ ! -d "$1" ]; then
		echo "The provided path does not exist.";
		return;
	fi;
	
	mkdir -p "$1/view/frontend/web/css/source";
	mkdir -p "$1/view/adminhtml/web/css/source";

	touch "$1/view/frontend/web/css/source/_module.less";
	touch "$1/view/adminhtml/web/css/source/_module.less";

	echo "Created : $1/view/frontend/web/css/source/_module.less";
	echo "Created : $1/view/adminhtml/web/css/source/_module.less";
}

project_install () {
    if [ -f "composer.json" ]; then
        composer_exec install;
    fi;
    if [ -f "package.json" ]; then
        npm install;
    fi;
    if [ -f "yarn.lock" ]; then
        yarn install;
    fi;
    if [ -f "requirements.txt" ]; then
        pip install -r requirements.txt;
    fi;
    if [ -f "nuget.config" ]; then
        dotnet restore;
		dotnet rebuild ./*.csproj;
    fi;
}
project_update () {
    if [ -f "composer.json" ]; then
        composer_exec update;
    fi;
    if [ -f "package.json" ]; then
        npm update;
    fi;
    if [ -f "yarn.lock" ]; then
        yarn upgrade;
    fi;
    if [ -f "requirements.txt" ]; then
        pip install -r requirements.txt;
    fi;
    if [ -f "nuget.config" ]; then
        dotnet restore;
		dotnet rebuild ./*.csproj;
    fi;
}

composer_verify_repos () {
	json_data="$(composer config repositories --no-plugins --no-ansi)";
	artifacts="$(echo "$json_data" | jq -c "to_entries | .[] | select(.value.type==\"artifact\")")";
	for artifact in $artifacts; do
		path_name="$(echo "$artifact" | jq -r ".value.url")";
		[ ! -f "$path_name" ] && {
			name="$(echo "$artifact" | jq -r ".key")";
			echo "File not found: $path_name";
			echo "Removing repo: $name";
			composer config repositories.$name --unset;
		};
	done;
}

magento_preset_extensions () {
	if [[ ! -d "app/code/Mageplaza/CurrencyFormatter" ]]; then
		git clone https://github.com/mageplaza/magento-2-currency-formatter "app/code/Mageplaza/CurrencyFormatter";
		cd app/code/Mageplaza/CurrencyFormatter || return 1;
		rm -fr .git;
		cd ../../../.. || return 1;
	fi;
	composer require mageplaza/magento-2-bulgarian-language-pack:dev-master mageplaza/module-smtp;
}

whitelist_single_module () {
	if [ -f "$1/etc/db_schema.xml" ]; then
		moduleName=$(echo "$1" | awk -F '/' 'NF == 4 {print $3 "_" $4}');
		[ ! -f "$1/etc/db_schema_whitelist.json" ] && {
			echo "Whitelisting module: $moduleName";
			magento setup:db-declaration:generate-whitelist --module-name="$1";
		} || echo "Already whitelisted: $moduleName";
	fi;
}

magento_whitelist () {
	find app/code -maxdepth 2 -type d -not -empty -exec bash -c "whitelist_single_module $1" \;
}
magento_db_status_fix () {
	# Clear files before rebuilding.
	rm -fr generated/code/*;
	chmod -R $APPLIED_ACCESS_CODE generated;
	magento setup:db:status --no-ansi 2> /dev/null;
	# https://devdocs.magento.com/guides/v2.3/install-gde/install/cli/install-cli-subcommands-db-status.html
	case "$?" in
		0) ;;
		1) composer_exec update && magento_rebuild ;;
		2) magento_whitelist && magento setup:upgrade ;;
		*) echo "Unknown error." ;;
	esac;
}
magento_rebuild () {
	[ ! -z "$1" ] && cd "$ROOT_DIR/$1/$1";
	magento_db_status_fix;
	if ! magento setup:di:compile; then
		echo "Error compiling. Trying again.";
		return 0;
	fi
	magento_deploy_themes;
	cache
}
magento_logs () {
	if [ ! -d "var/log" ]; then
		echo "No logs found.";
		return 1;
	fi;
	returned=$(tail var/log/*);
	error_msg=$(echo "$returned" | grep -oE "^\#[0-9]*." | tail -n 1 | grep -oE "[0-9]+");
	if [ ! -z "$error_msg" ]; then
		error_msg=$(( $error_msg + 5 ));
		tail var/log/* -n "$error_msg";
	else
		echo "$returned";
	fi;
}

magento_rebuild_styleless () {
	magento_db_status_fix
	magento setup:di:compile;
	cache
}

magento_set_adminurl () {
	if [ ! -z "$(magento config:set admin/url/custom)" ]; then
		magento config:set admin/url/custom "$1";
	fi;
	magento setup:config:set --backend-frontname "$1" -n;
}

magento_modules_enable () {
	magento module:enable $(magento module:status | grep "$1");
}

magento_modules_disable () {
	magento module:disable $(magento module:status | grep "$1");
}

magento_user () {
	if [ -z "$1" ]; then
		echo "This function expects one(1) parameter.";
		echo "The suplied parameter will be used as username, firstname, last name and during email as follows.";
		echo "[param]@mailinator.com";
		echo "Please supply a username/parameter.";
		return 1;
	fi;
	magento admin:user:create --admin-user "$1" --admin-password "Qwerty_2_Qwerty" --admin-email "$1@mailinator.com" --admin-firstname="$1" --admin-lastname="$1";
}

# Run reindex & cron.
magento_data () {
	magento indexer:reset;
	magento indexer:reindex;
	magento cron:run;
}

number_of_themes () {
	find "app/design/$1" -maxdepth 2 -type d -not -empty | awk -F '/' 'NF == 5 {print}'| wc -l;
}

magento_frontend_themes () {
	used_themes=$(mysql "$(current_dir_name)" -e "select tm.theme_path from core_config_data as ccd join theme as tm on tm.theme_id = ccd.value where ccd.path = 'design/theme/theme_id';");
	for theme in $(echo "$used_themes" | grep -v "theme_path" | sort | uniq); do
		deploy_single_theme frontend "$theme";
	done;
	if [ $(echo "$used_themes" | wc -l) -eq 1 ]; then
		magento setup:static-content:deploy -f --area frontend;
	fi;
}

magento_frontend_themes_language () {
	result="";
	used_themes=$(mysql "$(current_dir_name)" -e "select value from core_config_data where path = 'general/locale/code';");
	for theme in $(echo "$used_themes" | grep -v "value"); do
		result="$result $theme";
	done;
	echo $result;
}

magento_backend_themes () {
	if [ $(number_of_themes adminhtml) -gt 0 ]; then
		find app/design/adminhtml/ -maxdepth 2 -mindepth 2 -type d -not -empty -exec bash -c "deploy_single_theme adminhtml $1" \;
	else
		deploy_single_theme adminhtml;
	fi;
}

magento_logs_clear () {
	find var/log -name "*.log" -type f -exec bash -c "echo > {}" \;
}

magento_projects () {
	find "$ROOT_DIR" -mindepth 1 -maxdepth 1 -type d -not -empty -exec bash -c '\
		themes="{}";\
		project="${themes##*/}";\
		if [ -f "$themes/$project/bin/magento" ]; then\
			echo $project;\
		fi;' \;
}

deploy_single_theme () {
	if [ "$1" == "frontend" ]; then
		lang="$FRONTEND_DEPLOY_LANGUAGES $(magento_frontend_themes_language)";
	else
		lang=$BACKEND_DEPLOY_LANGUAGES;
	fi;

	if [ -z "$2" ]; then 
		magento setup:static-content:deploy -j 3 -f --area $1 $lang;
	else
		if ! magento setup:static-content:deploy -j 3 -f --area $1 --theme "$theme" --no-parent $lang; then
			magento setup:static-content:deploy -f --area $1 --theme "$theme" $lang;
		fi;
	fi;
}

deploy_theme () {
	theme_path="$1";
	area="$(echo "$theme_path" | awk -F '/' '{print $3}')";
	find "$theme_path" \( -name \*.css -o -name \*.js -o -name \*.html \) -type f -exec bash -c "deploy_file {}" \; 
}
deploy_file () {
	theme="$(echo "$1" | awk -F '/' '{print $4 "/" $5}')";
	area="$(echo "$1" | awk -F '/' '{print $3}')";
	file_path="$1";
	file="$(basename $1)";
	find "pub/static/$area" -name "$file" -path "*/$theme/*" -type f -exec cp -v "$file_path" "{}" \;
}

magento_deploy_themes () {
	rm -fr pub/static/{frontend,adminhtml} var/view_preprocessed;
	magento_frontend_themes;
	magento_backend_themes;
	magento_access;
}
laravel_install () {
	composer_exec install;
	artisan key:generate;
	artisan migrate;
	artisan db:seed;
	#artisan serve;
	ln -s public/ "$SYM_LINK_NAME"; 
}
magento_install_lang() {
	# $1 is csv source to use
	# $2 is locale to target
	magento i18n:pack --mode=merge -d "$1" "$2";
}
magento_install() {
	# $1 project name.
	# $2 url
	if [ -z "$1" ]; then
		echo "Two(2) arguments are required.";
		echo "1. Name of the project.";
		echo "2. Url which will be git-clone'ed";
		echo "Please provide both arguments";
		return 1;
	else
		project="$1";
		if [ -z "$2" ]; then 
			[ ! -d "$ROOT_DIR/$project/$project/.git" ] && repo_url="$(get_github_repo "$project")";
		else
			repo_url="$2";
		fi;
	fi;
	echo "URL: $repo_url";
	cd "$ROOT_DIR" || return 1;
	
	if [[ ! -d "$project/$project" ]]; then
		if [ -d "$ROOT_DIR/$project" ]; then
			cd "$project" || return 1;
		else
			mkdir "$project"; 
			cd "$project"  || return 1;
		fi;
		git clone "$repo_url" "$project";
	fi;
	
	cd "$ROOT_DIR/$project/$project"  || return 1;
	git_ignore_chmod;

	# If composer.lock exists 'composer install' *might* throw an error.
	if [[ -f "composer.lock" ]]; then
		rm "composer.lock";
	fi;
	mysql -e "CREATE DATABASE IF NOT EXISTS $project";
	composer_verify_repos;
	if ! composer_exec install; then
		echo "Composer install failed. Please check the error.";
		return 1;
	fi;
	
	# In most cases this module is missing pub folder.
	if [ -d "app/code/Amasty/Xsearch" ]; then
		if [ ! -f "app/code/Amasty/Xsearch/pub" ]; then
			mkdir app/code/Amasty/Xsearch/pub;
		fi;
	fi;
	# In most cases this module is missing pub folder.
	if [ -d "app/code/Amasty/Shopby" ]; then
		if [ ! -f "app/code/Amasty/Shopby/pub" ]; then
			mkdir app/code/Amasty/Shopby/pub;
		fi;
	fi;
	# Sleep, cause its too quick to notice the changes sometimes.
	sleep 5;
	# Disable modules that DO NOT contain Magento in them.
	magento module:disable $(magento module:status | grep -v "Magento\|List of\|None") Magento_TwoFactorAuth;

	# Install project
	if ! magento setup:install \
		--admin-firstname="Admin" --admin-lastname="Admin" \
		--admin-password="$ADMIN_PASSWORD" --admin-email="$ADMIN_EMAIL" --admin-user="$ADMIN_USER" \
		--db-password="$MYSQL_PASSWORD" --db-host="$MYSQL_SERVER" --db-user="$MYSQL_USER" --db-name="$project" \
		--elasticsearch-host="$ELASTIC_SERVER" --search-engine="elasticsearch7" \
		--use-rewrites=1;
		#--disable-modules=Magento_TwoFactorAuth,Magento_AdminAdobeImsTwoFactorAuth,Mageplaza_Smtp
	then
		echo "Magento install failed. Please check the error.";
		return 1;
	fi;
	magento_rebuild_styleless;
	magento cache:disable;
	magento_disable_sign;
	# Enable modules that DO NOT contain Magento in them.
	magento module:enable $(magento module:status | grep  -v "Magento\|List of\|None\|TwoFactorAuth");
	magento_rebuild;

	# devilbox specific.
	cd "$ROOT_DIR/$project" || return 1;
	if [ $USE_NGINX == 1 ]; then
		if [ -f "$SYM_LINK_NAME" ]; then
			rm "$SYM_LINK_NAME";
		fi;
		ln -s "$project/pub" "$SYM_LINK_NAME";
	else
		rm /var/www/html && ln -s "$project/pub" "/var/www/html";
	fi;
}

magento_dump () {
	[ -z "$1" ] && database="$(current_dir_name)" || database="$1";
	mysqldump "$database" > "dump.$database.sql";
}
 
magento_restore () {
	if [ -z "$2" ]; then
		database="$(current_dir_name)";
		restore_file="$1";
	else
		database="$1";
		restore_file="$2";
	fi;
	address="http://$database.loc";
	sed -i "s/COLLATE=utf8mb4_0900_ai_ci//g" "$restore_file";
	mysql -e "CREATE DATABASE IF NOT EXISTS $database";
	mysql "$database" < "$restore_file";
	mysql "$database" -e "update core_config_data set value = '$ELASTIC_SERVER' where path like '%elastic%server_host%';";
	mysql "$database" -e "update core_config_data set value = '$address/' where path like '%base_url';";
	mysql "$database" -e "update core_config_data set value = '$address/static/' where path like '%base_static_url';";
	mysql "$database" -e "update core_config_data set value = '$address/media/' where path like '%base_media_url';";
	magento_disable_sign;
	magento_cache;
}
update_github_token () {
	token="$GITHUB_TOKEN";
	if [ ! -z "$1" ]; then
		token="$1";
	fi;
	new_link="https://$GITHUB_USER:$token@github.com/$GITHUB_ORGANIZATION";
	for project in $(magento_projects); do
		if [ -d "$ROOT_DIR/$project/$project" ]; then
			repoFull="$(git -C "$ROOT_DIR/$project/$project" remote -v | tail -n 1)";
			repoFull="$(echo "$repoFull"|awk -F ' ' '{ print $2 }')";
			repo="$(echo "$repoFull" | awk -F '/' '{ print $5 }')";
			echo $repo;
			git -C "$ROOT_DIR/$project/$project" remote set-url origin "$new_link/$repo";
		fi;
	done;
}
get_admin_url () {
	project="$2";
	echo "$project $(php "$1"/bin/magento info:adminuri | grep URI)" | awk -F ' Admin URI: ' '{printf "http://%s.loc%s", $1, $2}';
}
magento_panels_urls () {
	printf "%10s | %10s | %20s\n" "PROJECT" "URL" "ADMIN URL";
	find "$ROOT_DIR" -mindepth 1 -maxdepth 1 -type d -not -empty -exec bash -c 'get_single_admin_url $1' \;
}
get_single_admin_url () {
	path="$1";
	project="${path##*/}";
	if [ -f "$path/$project/bin/magento" ]; then
		printf "%10s | %10s | %20s\n" "$project" "http://$project.loc/" "$(get_admin_url "$path"/"$project" "$project")";
	fi;
}

magento_cron_access () {
	if [ -z "$1" ]; then
		echo "No project specified.";
		return;
	fi;
	project="$1";
	crontab -l  > /tmp/crontab.file;
	# crontab uses sh instead of bash, no `{var,pub...}` and chmod, use the long form.
	command="/usr/bin/chmod -R $APPLIED_ACCESS_CODE $ROOT_DIR/$project/$project/var && /usr/bin/chmod -R $APPLIED_ACCESS_CODE $ROOT_DIR/$project/$project/generated";
	echo "* * * * * $command" >> /tmp/crontab.file;
	crontab /tmp/crontab.file;
	rm /tmp/crontab.file;
}

magento_minify_disable () {
	magento config:set dev/js/merge_files 0
	magento config:set dev/js/enable_js_bundling 0
	magento config:set dev/js/minify_files 0
	magento config:set dev/css/merge_css_files 0
	magento config:set dev/css/minify_files 0
}
magento_minify_enable () {
	magento config:set dev/js/merge_files 1
	magento config:set dev/js/enable_js_bundling 1
	magento config:set dev/js/minify_files 1
	magento config:set dev/css/merge_css_files 1
	magento config:set dev/css/minify_files 1
}
magento_clear_residue(){
	find "$ROOT_DIR" -maxdepth 5 -path "*/var/log/*" -name "*.log" -type f -exec bash -c "echo > {}" \;
	find "$ROOT_DIR" -maxdepth 5 -path "*/var/cache/*" -type d -exec bash -c "echo \"Removing {}\"; [ -d {} ] && rm -fr {}" \;
	find "$ROOT_DIR" -name "cache" -type d -exec bash -c "chmod -R $APPLIED_ACCESS_CODE {}" \;
	find "$ROOT_DIR" -name ".git" -type d -exec bash -c "cd {}; cd ../; git_ignore_chmod;" \;
}
magento_only_default_values(){
	if [ -z "$1" ]; then
		database="$(current_dir_name)";
	else
		database="$1";
	fi;

	echo "Doing backup before clearing.";
	magento_dump "$database";
	echo "Dumped in: dump.$database.sql";
	echo "Clearing...";
	mysql "$database" -e "delete from catalog_product_entity_text where store_id != 0;";
	mysql "$database" -e "delete from catalog_product_entity_decimal where store_id != 0;";
	mysql "$database" -e "delete from catalog_product_entity_int where store_id != 0;";
	mysql "$database" -e "delete from catalog_product_entity_varchar where store_id != 0;";
	mysql "$database" -e "delete from catalog_product_entity_datetime where store_id != 0;";
	mysql "$database" -e "delete from catalog_product_entity_media_gallery_value where store_id != 0;";
	echo "Done.";
}

export -f magento_install;
export -f magento_rebuild;
export -f get_single_admin_url;
export -f deploy_single_theme;
export -f whitelist_single_module;
export -f get_admin_url;
export -f deploy_file;

echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!";
echo "!!!!!				REMOVING LAST USED LOGS AND CACHE, IN ORDER TO FREE UP SPACE                     !!!!!";
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!";
magento_clear_residue &

echo "=========================================================================================================";
echo "Greetings, this shell has a few shortcuts related to Magento 2 development.";
echo "You can write 'magento' and hit [TAB] twice to see them.";
echo "=========================================================================================================";
