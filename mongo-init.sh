#!/bin/bash
file_env() {
	local var="$1"
	local fileVar="${var}_FILE"
	local def="${2:-}"
	if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
		echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
		exit 1
	fi
	local val="$def"
	if [ "${!var:-}" ]; then
		val="${!var}"
	elif [ "${!fileVar:-}" ]; then
		val="$(< "${!fileVar}")"
	fi
	export "$var"="$val"
	unset "$fileVar"
}
file_env "MONGO_USERNAME"
file_env "MONGO_PASSWORD"
mongo -- ${MONGO_INITDB_DATABASE} <<EOF
const MONGO_INITDB_ROOT_USERNAME = '$MONGO_INITDB_ROOT_USERNAME';
const MONGO_INITDB_ROOT_PASSWORD = '$MONGO_INITDB_ROOT_PASSWORD';
const MONGO_DATABASE = '$MONGO_DATABASE';
const MONGO_USERNAME = '$MONGO_USERNAME';
const MONGO_PASSWORD = '$MONGO_PASSWORD';
db.auth(MONGO_INITDB_ROOT_USERNAME, MONGO_INITDB_ROOT_PASSWORD);
var db = db.getSiblingDB(MONGO_DATABASE);
db.createUser({user: MONGO_USERNAME, pwd: MONGO_PASSWORD, roles: [{role: 'readWrite', db: MONGO_DATABASE}]});
EOF