#!/bin/bash
echo "Checking if UID: ${UID} matches user"
usermod -u ${UID} ${USER}

echo "Checking if GID: ${GID} matches user"
usermod -g ${GID} ${USER}

echo "Setting umask to ${UMASK}"
umask ${UMASK}

echo "Checking configuration for noVNC"
novnccheck

echo "Setting RECORDING_API"
echo "127.0.0.1 localhost" > /etc/hosts
echo "${RECORDING_API} RECORDING-API" >> /etc/hosts

echo "Starting..."
chown -R ${UID}:${GID} /opt/scripts
chown -R ${UID}:${GID} ${DATA_DIR}

term_handler() {
	kill -SIGTERM "$killpid"
	wait "$killpid" -f 2>/dev/null
	exit 143;
}

trap 'kill ${!}; term_handler' SIGTERM
su ${USER} -c "/opt/scripts/start-server.sh" &
killpid="$!"
while true
do
	wait $killpid
	exit 0;
done