FROM phusion/baseimage:0.9.15
MAINTAINER Aybars Cengaver
ENV HOME /root
RUN /etc/my_init.d/00_regen_ssh_host_keys.sh
CMD ["/sbin/my_init"]

#PHP
RUN apt-get update
RUN apt-get install -y vim curl wget build-essential python-software-properties
RUN add-apt-repository -y ppa:ondrej/php5
RUN add-apt-repository -y ppa:nginx/stable
RUN apt-get update
RUN apt-get install -y --force-yes php5-cli php5-fpm php5-mysql php5-pgsql php5-sqlite php5-curl php5-gd php5-mcrypt php5-intl php5-imap php5-tidy
RUN sed -i "s/;date.timezone =.*/date.timezone = UTC/" /etc/php5/fpm/php.ini
RUN sed -i "s/;date.timezone =.*/date.timezone = UTC/" /etc/php5/cli/php.ini

#NGINX
RUN apt-get install -y nginx

RUN echo "daemon off;" >> /etc/nginx/nginx.conf

RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php5/fpm/php-fpm.conf
RUN sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php5/fpm/php.ini

RUN mkdir -p /var/www
VOLUME /var/www
ADD sites/default /etc/nginx/sites-available/default


#Supervisor
RUN apt-get install -y supervisor
RUN mkdir -p /var/lock/nginx /var/run/nginx /var/run/php5-fpm /var/log/supervisor
COPY conf/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

#Mysql
RUN groupadd -r mysql && useradd -r -g mysql mysql
RUN apt-get install -y perl --no-install-recommends && rm -rf /var/lib/apt/lists/*
RUN apt-key adv --keyserver pgp.mit.edu --recv-keys A4A9406876FCBD3C456770C88C718D3B5072E1F5
ENV MYSQL_MAJOR 5.6
ENV MYSQL_VERSION 5.6.22
RUN echo "deb http://repo.mysql.com/apt/debian/ wheezy mysql-${MYSQL_MAJOR}" > /etc/apt/sources.list.d/mysql.list

RUN { \
		echo mysql-community-server mysql-community-server/data-dir select ''; \
		echo mysql-community-server mysql-community-server/root-pass password ''; \
		echo mysql-community-server mysql-community-server/re-root-pass password ''; \
		echo mysql-community-server mysql-community-server/remove-test-db select false; \
	} | debconf-set-selections \
 && apt-get update && apt-get install -y mysql-server="${MYSQL_VERSION}"* && rm -rf /var/lib/apt/lists/* \
	&& rm -rf /var/lib/mysql && mkdir -p /var/lib/mysql
RUN sed -Ei 's/^(bind-address|log)/#&/' /etc/mysql/my.cnf
VOLUME /var/lib/mysql
RUN mysql_install_db
#RUN service mysql start
#RUN mysql -uroot -e 'CREATE DATABASE IF NOT EXISTS `ojs`;'
#RUN mysql -uroot -e "GRANT ALL ON ojs.* TO 'root'@'%';"
#RUN mysql -uroot -e 'FLUSH PRIVILEGES;'

#MongoDB
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv 7F0CEB10
RUN echo "deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen" | tee -a /etc/apt/sources.list.d/10gen.list
RUN apt-get -y update
RUN apt-get -y install mongodb-10gen

RUN mkdir -p /data/db

EXPOSE 80 3306 27017


RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
CMD ["/usr/bin/supervisord"]