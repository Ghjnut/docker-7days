# 7days-server-data IMAGE/CONTAINER

# create data container to store 7days src + config
build_volume_container() {
	docker run --name "$SEVENDAYS_VOLUME_CONTAINER" --volume "$SEVENDAYS_DIR" ubuntu:15.10
}

# installs/updates 7days to new volume-container
update_volume_container() {
	docker run --rm \
		--interactive \
		--tty \
		--volumes-from "$SEVENDAYS_VOLUME_CONTAINER" \
		steamcmd \
			+login "$STEAM_LOGIN" "$STEAM_PASSWORD" \
			+force_install_dir "$SEVENDAYS_DIR" \
			+app_update "$SEVENDAYS_APPID" validate \
			+quit
}

# migrate current config/world 
#  data/serverconfig.xml - server config
#  data/Saves/serveradmin.xml - steamid admin prefs
#  data/Saves - saved worlds based on serveradmin.xml->GameName
migrate_data_into_volume_container() {
	docker cp data/serverconfig.xml "$SEVENDAYS_VOLUME_CONTAINER":"$SEVENDAYS_DIR"/
	docker cp data/Saves "$SEVENDAYS_VOLUME_CONTAINER":"$SEVENDAYS_DIR"/
}

# REMOVES ALL SAVED DATA
delete_volume_container() {
	docker rm --volumes "$SEVENDAYS_VOLUME_CONTAINER"
}



# 7days-server IMAGE/CONTAINER

# build 7days run-container
build_server_image() {
	docker build --tag="$SEVENDAYS_SERVER_IMAGE" .
}

# start the newly built container
start_server_container() {
	docker run \
		--detach \
		--name "$SEVENDAYS_SERVER_CONTAINER" \
		--volumes-from "$SEVENDAYS_VOLUME_CONTAINER" \
		--publish "$SEVENDAYS_SERVER_PORT":26900 \
		"$SEVENDAYS_SERVER_IMAGE"
}

restart_server_container() {
	docker start "$SEVENDAYS_SERVER_CONTAINER"
}

# create telnet session to server (for some reason doesn't work with linked container)
connect_to_server_container() {
	docker exec --interactive --tty "$SEVENDAYS_SERVER_CONTAINER" bash -c 'telnet 127.0.0.1 8081'
}

stop_server_container() {
	docker stop "$SEVENDAYS_SERVER_CONTAINER"
}

delete_server_container() {
	docker rm "$SEVENDAYS_SERVER_CONTAINER"
}

delete_server_image() {
	docker rmi "$SEVENDAYS_SERVER_IMAGE"
}
