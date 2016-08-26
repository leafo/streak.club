FROM leafo/lapis-archlinux-itchio:latest
MAINTAINER leaf corcoran <leafot@gmail.com>

WORKDIR /site/streak.slub
ADD . .
ENTRYPOINT ./ci.sh
