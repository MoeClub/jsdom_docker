#!/bin/sh
set -e

execPath=`readlink -f "$0"`
dockerMnt=`dirname "${execPath}"`
dockerProject="jsdom"
dockerBase="alpine:3.23"
dockerName="${dockerProject}_buildx"


manifest=""
for arch in "amd64" "arm64"; do
  docker run --rm --platform "linux/${arch}" "${dockerBase}" apk --print-arch >/dev/null 2>&1 || docker run --privileged --rm tonistiigi/binfmt --install "${arch}"
  docker rm -f "${dockerName}" >/dev/null 2>&1 || true
  docker run --platform "linux/${arch}" --name "${dockerName}" -id -v "${dockerMnt}:/mnt" "${dockerBase}"
  docker exec "${dockerName}" /bin/sh "/mnt/commit.sh"
  docker commit --change 'ENV NODE_PATH=/usr/lib/node_modules:/usr/local/lib/node_modules' --change 'ENTRYPOINT ["/usr/bin/node"]' --change 'CMD ["/run.js"]' "${dockerName}" "${dockerProject}_${arch}:latest"
  docker rm -f "${dockerName}" >/dev/null 2>&1 || true
  userName="$(docker info 2>/dev/null |grep 'Username:' |cut -d':' -f2 |sed 's/[[:space:]]//g')"
  [ -n "$userName" ] || continue
  docker tag "${dockerProject}_${arch}:latest" "${userName}/${dockerProject}_${arch}:latest"
  docker push "${userName}/${dockerProject}_${arch}:latest"
  [ $? -eq 0 ] && manifest=`echo "--amend \"${userName}/${dockerProject}_${arch}:latest\" ${manifest}" |sed 's/\ \+$//'`
done

[ -n "$userName" ] && [ -n "$manifest" ] && eval `echo "docker manifest create \"${userName}/${dockerProject}:latest\" $manifest"` && docker manifest push -p "${userName}/${dockerProject}:latest"

