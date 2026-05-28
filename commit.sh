#!/bin/sh

apk add --no-cache openssl tzdata nodejs npm icu-data-full
cp -rf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
npm install -g jsdom undici
npm root -g
[ -f /mnt/run.js ] && cp -rf /mnt/run.js /run.js
find /var -type f -delete
echo >$HOME/.ash_history
