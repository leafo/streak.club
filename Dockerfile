FROM leafo/lapis-archlinux-itchio:latest
MAINTAINER leaf corcoran <leafot@gmail.com>

WORKDIR /site/streak.slub
ADD . .
RUN tup init && tup
RUN cat $(which busted) | sed 's/\/usr\/bin\/lua5\.1/\/usr\/bin\/luajit/' > busted && chmod +x busted

ENTRYPOINT ./busted
