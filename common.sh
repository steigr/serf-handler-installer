handler_dir=/run/serf/handlers

tag() {
	op=$1
	key=${2%=*}
	value=${2#*=}
	[[ "x$key" = "x$value" ]] && value=true
	[[ "x$op" = "xadd" ]] && serf tags -set $key=$value
	[[ "x$op" = "xdel" ]] && serf tags -delete $key
}

known_handlers() {
	serf query -format=json installed-handlers \
	| jq '.Responses | to_entries | .[].value' \
	| xargs \
	| sort \
	| uniq
}

list_installed_handlers() {
	ls $handler_dir | while read name; do
		[[ -d "$handler_dir/$name/.git" ]] || continue
		
		url=$(cd "$handler_dir/$name"; git remote -v | grep fetch | awk '{print $2}' | grep -e ^http -e ^git )
		
		[[ "x$url" = "x" ]] && continue

		echo "${name}@${url}"
	done
}

update_handlers() {
	find /run/serf/handlers/* -maxdepth 1 -type d -name .git | xargs dirname | while read handler; do
		( cd $handler; git pull origin master )
	done
	tag add handlers=$(date +%s)
}

install_handler() {
	name=$1
	url=$2
	[[ "x$name" = "x" ]] && name=$(basename $url | sed -e "s:\.git$::" )
	cd $handler_dir
	test -d $name && test -d $name/.git && ( cd $name; git pull )
	test -d $name || git clone $url $name
	tag add handlers=$(date +%s)
}