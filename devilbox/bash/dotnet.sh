_dotnet()
{
	local cur prev prev2 cmd opts
	COMPREPLY=()
	cur="${COMP_WORDS[COMP_CWORD]}"
	prev="${COMP_WORDS[COMP_CWORD-1]}"
	prev2="${COMP_WORDS[COMP_CWORD-2]}"
	cmd=$"${COMP_WORDS[1]}"

	case "${cmd}" in
		new)
			_dotnet_new
		;;

		restore)
			_dotnet_restore
		;;

		build)
			_dotnet_build
		;;

		publish)
			_dotnet_publish
		;;

		run)
			_dotnet_run
		;;

		test)
			_dotnet_test
		;;	

		pack)
			_dotnet_pack
		;;

		migrate)
			_dotnet_migrate
		;;
		
		clean)
			_dotnet_clean
		;;

		sln)
			_dotnet_sln
		;;

		add)
			_dotnet_add
		;;

		remove)
			_dotnet_remove
		;;

		list)
			_dotnet_list
		;;

		*)
		;;
	esac

	if [[ ${prev} == dotnet ]] ; then
		opts="new restore build publish run test pack migrate clean sln add remove list nuget msbuild vstest"
		COMPREPLY=( $(compgen -W "${opts}" ${cur}) )
		return 0
	fi

}

_dotnet_new()
{
	local template="${COMP_WORDS[2]}"

	case "${prev}" in 
		new)
			opts="console classlib mstest xunit web mvc webapi sln"
			COMPREPLY=( $(compgen -W "${opts}" ${cur}) )
			return 0
		;;

		--language)
			opts="$(_get_languages ${prev2})"
			COMPREPLY=( $(compgen -W "${opts}" ${cur}) )
			return 0
		;;

		--framework)
			opts="$(_get_frameworks ${prev2})"
			COMPREPLY=( $(compgen -W "${opts}" ${cur}) )
			return 0
		;;

		--output)
			COMPREPLY=( $(compgen -d -- "${cur}") )
			return 0
		;;

		--auth)
			if [[ ${template} == mvc ]] ; then
				opts="None Individual"
				COMPREPLY=( $(compgen -W "${opts}" ${cur}) )
				return 0
			fi
		;;

		--use-local-db)
			if [[ ${template} == mvc ]] ; then
				opts="true false"
				COMPREPLY=( $(compgen -W "${opts}" ${cur}) )
				return 0
			fi
		;;

		*)
			if [[ ${template} == mvc ]] ; then
				opts="--list --language --name --output --help --framework --auth --use-local-db"
			else
				opts="--list --language --name --output --help --framework"
			fi

			COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
			return 0
		;;
	esac
}

_get_languages()
{
	local template
	template=$1

	if [[ "web webapi" == *${template}* ]] ; then
		echo "C#"
		return 0
	fi

	echo "C# F#"
	return 0
}

_get_frameworks()
{
	local template
	template=$1
	if [[ "classlib" == ${template} ]] ; then
		echo "netcoreapp1.0 netcoreapp1.1 netstandard1.0 netstandard1.1 netstandard1.2 netstandard1.3 netstandard1.4 netstandard1.5 netstandard1.6"
		return 0
	fi

	echo "netcoreapp1.0 netcoreapp1.1"
	return 0
}

_dotnet_restore()
{
	case ${prev} in
		--packages)
			COMPREPLY=( $(compgen -d  "${cur}") )
			return 0
		;;

		--configfile)
			COMPREPLY=( $(compgen -f "${cur}") )
			return 0
		;;

		--verbosity)
			opts="quiet minimal normal detailed diagnostic"
			COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
			return 0
		;;

		*)
			opts="--help --source --runtime --packages --disable-parallel --configfile --no-cache --ignore-failed-sources --no-dependencies --verbosity"
			COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
			return 0
		;;
	esac
}

_dotnet_build()
{
	case ${prev} in
		--output)
			COMPREPLY=( $(compgen -d  "${cur}") )
			return 0
		;;

		--verbosity)
			opts="quiet minimal normal detailed diagnostic"
			COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
			return 0
		;;

		*)
			opts="--help --output --framework --runtime --configuration --version-suffix --no-incremental --no-dependencies --verbosity"
			COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
			return 0
		;;
	esac
}

_dotnet_publish()
{
	case ${prev} in
		--output)
			COMPREPLY=( $(compgen -d  "${cur}") )
			return 0
		;;

		--verbosity)
			opts="quiet minimal normal detailed diagnostic"
			COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
			return 0
		;;

		*)
			opts="--help --framework --runtime --output --configuration --version-suffix --verbosity"
			COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
			return 0
		;;
	esac
}

_dotnet_run()
{
	case ${prev} in
		--project)
			COMPREPLY=( $(compgen -f "${cur}") )
			return 0
		;;

		*)
			opts="--help --configuration --framework --project"
			COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
			return 0
		;;
	esac
}

_dotnet_test()
{
	case ${prev} in
		--settings)
			COMPREPLY=( $(compgen -f "${cur}") )
			return 0
		;;

		--output)
			COMPREPLY=( $(compgen -d  "${cur}") )
			return 0
		;;

		--test-adapter-path)
			COMPREPLY=( $(compgen -f "${cur}") )
			return 0
		;;

		--diag)
			COMPREPLY=( $(compgen -f "${cur}") )
			return 0
		;;

		--verbosity)
			opts="quiet minimal normal detailed diagnostic"
			COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
			return 0
		;;

		*)
			opts="--help --settings --list-tests --filter --test-adapter-path --logger --configuration --framework --output --diag --no-build --verbosity"
			COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
			return 0
		;;
	esac
}

_dotnet_pack()
{
	case ${prev} in
		--output)
			COMPREPLY=( $(compgen -d  "${cur}") )
			return 0
		;;

		--verbosity)
			opts="quiet minimal normal detailed diagnostic"
			COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
			return 0
		;;

		*)
			opts="--help --output --no-build --include-symbols --include-source --configuration --version-suffix --servicable --verbosity"
			COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
			return 0
		;;
	esac
}

_dotnet_migrate()
{
	case ${prev} in
		migrate)
			COMPREPLY=( $(compgen -f "${cur}") )
			return 0
		;;

		--xproj-file)
			COMPREPLY=( $(compgen -f "${cur}") )
			return 0
		;;

		--report-file)
			COMPREPLY=( $(compgen -f "${cur}") )
			return 0
		;;

		*)
			opts="--help --template-file --sdk-package-version --xproj-file --skip-project-references --report-file --format-report-file-json --skip-backup"
			COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
			return 0
		;;
	esac
}

_dotnet_clean()
{
	case ${prev} in
		clean)
			if [[ ${cur} != -* ]]
            then
				COMPREPLY=( $(compgen -f "${cur}") )
				return 0
			else
				opts="--help --output --framework --configuration --verbosity"
				COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
				return 0
			fi

		;;

		--verbosity)
			opts="quiet minimal normal detailed diagnostic"
			COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
			return 0
		;;

		*)
			opts="--help --output --framework --configuration --verbosity"
			COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
			return 0
		;;
	esac
}

_dotnet_sln()
{
	case ${prev} in
		sln)
			if [[ ${cur} != -* ]] 
            then
				COMPREPLY=( $(compgen -f "${cur}") )
				return 0
			else
				opts="--help"
				COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
				return 0
			fi

		;;

		--verbosity)
			opts="quiet minimal normal detailed diagnostic"
			COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
			return 0
		;;

		*)
			opts="--help --output --framework --configuration --verbosity"
			COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
			return 0
		;;
	esac
}


_dotnet_add()
{
	case "${prev}" in
		add)
			opts="package reference"
			COMPREPLY=( $(compgen -W "${opts}" ${cur}) )
			return 0
		;;

		package)
			opts="$(curl -s https://api-v2v3search-0.nuget.org/autocomplete?q=${cur} | grep -Po '\[.*?\]' | grep -Po '(?<=").*?(?=")' | grep -Po '^[^,]+$' | sort)"
			COMPREPLY=( $(compgen -W "${opts}" ${cur}) )
			return 0
		;;

		--version)
			opts="$(curl -s https://api-v2v3search-0.nuget.org/autocomplete?id=${prev2} | grep -Po '\[.*?\]' | grep -Po '(?<=").*?(?=")' | grep -Po '^[^,]+$' | sort)"
			COMPREPLY=( $(compgen -W "${opts}" ${cur}) )
			return 0
		;;

		*)
			opts="--version"
			COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
			return 0
		;;
	esac
}

_dotnet_remove()
{
	#TODO
	return 0;
}

_dotnet_list()
{
	if [[ ${prev} == list ]] ; then
		opts="$(find . -name \*.csproj -print)"
		COMPREPLY=( $(compgen -W "${opts}" ${cur}) )
		return 0
	else
		opts="reference"
		COMPREPLY=( $(compgen -W "${opts}" ${cur}) )
		return 0
	fi
}

complete -o nospace -F _dotnet dotnet
