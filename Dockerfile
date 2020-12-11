FROM ghcr.io/leafo/lapis-archlinux-itchio:latest
MAINTAINER leaf corcoran <leafot@gmail.com>

WORKDIR /site/streak.club
ADD . .
ENTRYPOINT ./ci.sh
