#!/bin/bash
export DISPLAY=:99
export XAUTHORITY=${DATA_DIR}/.Xauthority

echo "---Resolution check---"
if [ -z "${CUSTOM_RES_W}" ]; then
	CUSTOM_RES_W=1024
fi
if [ -z "${CUSTOM_RES_H}" ]; then
	CUSTOM_RES_H=768
fi

if [ "${CUSTOM_RES_W}" -le 1023 ]; then
	echo "---Width to low must be a minimal of 1024 pixels, correcting to 1024...---"
    CUSTOM_RES_W=1024
fi
if [ "${CUSTOM_RES_H}" -le 767 ]; then
	echo "---Height to low must be a minimal of 768 pixels, correcting to 768...---"
    CUSTOM_RES_H=768
fi
echo "---Checking for old logfiles---"
find $DATA_DIR -name "XvfbLog.*" -exec rm -f {} \;
find $DATA_DIR -name "x11vncLog.*" -exec rm -f {} \;
echo "---Checking for old display lock files---"
rm -rf /tmp/.X99*
rm -rf /tmp/.X11*
rm -rf ${DATA_DIR}/.vnc/*.log ${DATA_DIR}/.vnc/*.pid ${DATA_DIR}/Singleton*
chmod -R ${DATA_PERM} ${DATA_DIR}
if [ -f ${DATA_DIR}/.vnc/passwd ]; then
	chmod 600 ${DATA_DIR}/.vnc/passwd
fi
screen -wipe 2&>/dev/null

echo "---Starting TurboVNC server---"
vncserver -geometry ${CUSTOM_RES_W}x${CUSTOM_RES_H} -depth ${CUSTOM_DEPTH} :99 -rfbport ${RFB_PORT} -noxstartup ${TURBOVNC_PARAMS} 2>/dev/null
sleep 2
echo "---Starting Fluxbox---"
screen -d -m env HOME=/etc /usr/bin/fluxbox
sleep 2
echo "---Starting noVNC server---"
websockify -D --web=/usr/share/novnc/ --cert=/etc/ssl/novnc.pem ${NOVNC_PORT} localhost:${RFB_PORT}
sleep 2

echo "---Starting Chrome---"
cd ${DATA_DIR}
/usr/bin/google-chrome \
	--window-position=0,0 \
	--window-size=${CUSTOM_RES_W},${CUSTOM_RES_H} \
	--show-fps-counter \
	--frame-throttle-fps=15 \
	--max-gum-fps=15 \
	--user-data-dir=/tmp \
	--disk-cache-dir=/tmp \
	--disk-cache-size=4096 \
	--media-cache-size=4096 \
	--alsa-input-device=null \
	--alsa-output-device=null \
	--audio-output-channels=1 \
	--block-new-web-contents \
	--no-sandbox \
	--no-first-run \
	--no-pings \
	--auto-ssl-client-auth \
	--autoplay-policy=no-user-gesture-required \
	--disable-background-networking \
	--disable-client-side-phishing-detection \
	--disable-default-apps \
	--disable-dev-shm-usage \
	--disable-hang-monitor \
	--disable-infobars \
	--disable-popup-blocking \
	--disable-prompt-on-repost \
	--disable-sync \
	--disable-canvas-aa \
	--disable-composited-antialiasing \
	--disable-font-subpixel-positioning \
	--disable-smooth-scrolling \
	--disable-speech-api \
	--disable-crash-reporter \
	--ignore-certificate-errors \
	--test-type \
	--load-extension=/opt/iwc-rec-ext/ \
	--whitelisted-extension-id=ifiomgafmdlhpckihjeimadkcalnamfe \
	--dbus-stub \
	--enable-logging=stderr \
	${EXTRA_PARAMETERS}
