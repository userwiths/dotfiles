composer_install () {
	php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');";
	php composer-setup.php;
	php -r "unlink('composer-setup.php');";
}

composer_exec() {
	if [ ! -f "composer.json" ]; then
		echo "No composer.json file found.";
		return 1;
	fi;

	if [ "$1" != "install" ]; then
		if [ "$1" != "update" ]; then
			echo "Unrecognized argument $1.";
			echo "Expecting [install] or [update]";
			return 1;
		fi;
	fi;
	if ! composer-2 $1; then
		echo "ComposerV2 install failed. Trying with ComposerV1";
		if ! composer-1 $1; then
			echo "Both composer versions failed. Returning to ComposerV2";
			return 1;
		fi;
	fi;
}

if [ ! -x "$(command -v composer)" ]; then
  echo "Downloading composer";
  cd "$ROOT_DIR";
  composer_install;
  alias composer="php $ROOT_DIR/composer.phar";
fi;

_composer()
{
    local cur=${COMP_WORDS[COMP_CWORD]}
    local cmd=${COMP_WORDS[0]}
    if ($cmd > /dev/null 2>&1)
    then
        COMPREPLY=( $(compgen -W "$($cmd list --raw | cut -f 1 -d " " | tr "\n" " ")" -- $cur) )
    fi
}
complete -F _composer composer
complete -F _composer composer.phar

# Lower one Not working :(
#eval "$(composer completion bash)";