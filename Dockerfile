FROM docker pull ghcr.io/leafo/lapis-archlinux-itchio:2019-3-8
MAINTAINER leaf corcoran <leafot@gmail.com>

WORKDIR /site/streak.club
ADD . .
ENTRYPOINT ./ci.sh
