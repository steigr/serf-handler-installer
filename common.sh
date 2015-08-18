handler_dir=/run/serf/handlers

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

install_handler() {
	name=$1
	url=$2
	cd $handler_dir
	test -d $name && test -d $name/.git && ( cd $name; git pull )
	test -d $name || git clone $url $name
}