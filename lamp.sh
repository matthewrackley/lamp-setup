#!/bin/bash
# Apache Format and install script
#
# This is a script that can be run on a debian
# machine to configure and install the apache
# server in a specific directory
if [[ "$EUID" -ne 0 ]]; then
	echo "Please run as root"
	exit
fi
buildIt="`$(cd /opt/server/build)`"
mkdir -p /opt/server/build
predownload() {
	wget https://dlcdn.apache.org/httpd/httpd-2.4.57.tar.gz					#Disappears in same local function
	wget https://dlcdn.apache.org/apr/apr-1.7.4.tar.gz						#Disappears in same local function
	wget https://dlcdn.apache.org/apr/apr-util-1.6.3.tar.gz					#Disappears in same local function
	wget https://www.php.net/distributions/php-8.2.5.tar.gz					#Disappears in same local function
	wget https://github.com/nodejs/node/archive/refs/tags/v20.0.0.tar.gz	#Disappears in same local function
	wget https://github.com/PCRE2Project/pcre2/releases/download/pcre2-10.42/pcre2-10.42.tar.gz		#Disappears in same local function
	wget https://github.com/libexpat/libexpat/releases/download/R_2_5_0/expat-2.5.0.tar.gz 			#Disappears in same local function
	tar -xvf httpd-2.4.57.tar.gz
	tar -xvf apr-1.7.4.tar.gz		#Disappears in same local function
	tar -xvf apr-util-1.6.3.tar.gz	#Disappears in same local function
	tar -xvf pcre2-10.42.tar.gz
	tar -xvf v20.0.0.tar.gz
	tar -xvf expat-2.5.0.tar.gz
	tar -xvf php-8.2.5.tar.gz
	sleep 1
	git clone https://github.com/libexpat/libexpat.git expat
	git clone https://github.com/MariaDB/server.git mariadb
	sleep 1
	mv httpd-2.4.57 /opt/server/httpd
	mv apr-1.7.4 /opt/server/httpd/srclib/apr				#Disappears in same local function
	mv apr-util-1.6.3 /opt/server/httpd/srclib/apr-util		#Disappears in same local function
	mv pcre2-10.42 /opt/server/pcre2
	mv node-20.0.0 /opt/server/node
	mv expat-2.5.0 /opt/server/expat
	mv mariadb /opt/server/mariadb
	mv php-8.2.5 /opt/server/php-src
	sleep 1
	rm **.tar.gz
	sleep 1
	cd /opt/server/mariadb
	if [[ "$PWD" == "/opt/server/mariadb" ]]; then
		git checkout 10.11
	fi
	maincmd
};
expatpkg() {
	cd /opt/server/expat
	if [[ "$PWD" == "/opt/server/expat" ]]; then
		/opt/server/expat/configure
		sleep 3 #Pause long enough to allow the user to catch a glimpse of what the configuration is
		make
		sleep 1
		sudo make install
		sleep 1
	fi
	maincmd
};
nodepkg() {
	cd /opt/server/node
	if [[ "$PWD" == "/opt/server/node" ]]; then
		/opt/server/node/configure \
		--prefix /opt/server/nodejs \
		--coverage \
		--gdb \
		--partly-static \
		--enable-vtune-profiling \
		--enable-pgo-generate \
		--ninja \
		--enable-lto \
		--tag LAMPPlus \
		--without-npm \
		--verbose \
		--download all
		/opt/server/node/configure \
		--prefix /opt/server/nodejs \
		--coverage \
		--gdb \
		--partly-static \
		--enable-vtune-profiling \
		--enable-pgo-use \
		--ninja \
		--enable-lto \
		--tag LAMPPlus \
		--without-npm \
		--verbose \
		--download all
		sleep 3 #Pause long enough to allow the user to catch a glimpse of what the configuration is
		make
		sleep 1
		sudo make install
		sleep 1
		sudo rm -rf /opt/server/node/*
		sudo rm -rf /opt/server/node/.*
	fi
	maincmd
};
apachepkg() {
	cd /opt/server/httpd
	if [[ "$PWD" == "/opt/server/httpd" ]]; then
		/opt/server/httpd/configure \
		--cache-file=/opt/server/apache/var/conf.cache \
		--prefix=/opt/server/apache \
		--exec-prefix=/opt/server/apache \
		--sbindir=/opt/server/apache/bin \
		--localstatedir=/opt/server/apache/var \
		--docdir=/opt/server/server \
		--enable-setenvif \
		--enable-env \
		--enable-reqtimeout \
		--enable-filter \
		--enable-mime \
		--enable-log-config \
		--enable-headers \
		--enable-status \
		--enable-autoindex \
		--enable-dir \
		--enable-alias \
		--enable-authn-core \
		--enable-authz-core \
		--disable-isapi \
		--enable-cgi \
		--enable-remoteip \
		--enable-sed \
		--enable-include \
		--enable-unique-id \
		--enable-request \
		--enable-vhost-alias \
		--enable-negotiation \
		--enable-file-cache \
		--enable-session \
		--enable-session-crypto \
		--enable-cache-disk \
		--enable-cache \
		--enable-session-cookie \
		--enable-rewrite \
		--enable-usertrack \
		--with-mpm=prefork \
		--enable-mpms-shared=all \
		--with-program-name=apachectl \
		--with-suexec-bin=/opt/server/apache/bin \
		--with-suexec-caller=root \
		--with-suexec-docroot=/opt/server/www \
		--with-suexec-logfile=/opt/server/var/logs/ap-suexec.log \
		--with-suexec-syslog=/opt/server/var/logs/ap-sys.log \
		--with-suexec-safepath=/usr/share/sbin:/usr/sbin:/sbin:/opt/server/apache/bin:/usr/share/bin:/usr/bin:/bin:$PATH \
		--with-suexec-umask=077
		sleep 3 #Pause long enough to allow the user to catch a glimpse of what the configuration is
		make
		sleep 1
		sudo make install
		sleep 1
		sudo addgroup --system --gid 443 apache
		adduser --system --no-create-home --shell /bin/false --disabled-password --uid 443 --gid 443 apache
	fi
	maincmd
};
mariadbpkg() {
	buildIt
	if [[ "$PWD" == "/opt/server/build" ]]; then
		MYSQL_HOME=/opt/server/mysql \
		MYSQL_HISTFILE=/root/.mysql_history \
		MYSQL_UNIX_PORT=/opt/server/mysql/tmp/mysql.sock \
		TMPDIR=/opt/server/mysql/tmp \
		cmake /opt/server/mariadb \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_INSTALL_PREFIX=/opt/server/mysql \
		-DINSTALL_BINDIR=bin \
		-DINSTALL_DOCDIR=docs \
		-DINSTALL_DOCREADMEDIR=. \
		-DINSTALL_INCLUDEDIR=/usr/include \
		-DINSTALL_INFODIR=docs \
		-DINSTALL_LAYOUT=STANDALONE \
		-DINSTALL_LIBDIR=/usr/lib \
		-DINSTALL_MANDIR=man \
		-DINSTALL_MYSQLDATADIR=data \
		-DINSTALL_MYSQLSHAREDIR=share \
		-DINSTALL_MYSQLTESTDIR=tests \
		-DINSTALL_PAMDATADIR=share \
		-DINSTALL_PAMDIR=share \
		-DINSTALL_PLUGINDIR=mods \
		-DINSTALL_SBINDIR=bin \
		-DINSTALL_SCRIPTDIR=scripts \
		-DINSTALL_SHAREDIR=share \
		-DINSTALL_SQLBENCHDIR=. \
		-DINSTALL_SUPPORTFILESDIR=var/support \
		-DINSTALL_UNIX_ADDRDIR=/opt/server/mysql/tmp/mysql.sock \
		-DINSTALL_SYSCONFDIR=/opt/server/mysql/conf \
		-DDEFAULT_SYSCONFDIR=/opt/server/mysql/conf \
		-DMYSQL_DATADIR=/opt/server/mysql/data \
		-DPLUGIN_ARCHIVE=DYNAMIC \
		-DWITH_PMEM=ON \
		-DWITH_READLINE=ON \
		-DWSREP_LIB_WITH_DOCUMENTATION=ON \
		-DCONNECT_WITH_BSON=ON \
		-DCONNECT_WITH_JDBC=ON \
		-DCONNECT_WITH_LIBXML2=ON \
		-DCONNECT_WITH_MONGO=ON \
		-DCONNECT_WITH_ODBC=ON \
		-DCONNECT_WITH_REST=ON \
		-DCONNECT_WITH_VCT=ON \
		-DCONNECT_WITH_XMAP=ON \
		-DCONNECT_WITH_ZIP=ON \
		-DMRN_GROONGA_EMBED=ON \
		-DGRN_DEFAULT_DOCUMENT_ROOT=/opt/server/mysql/share/groonga/html/admin \
		-DGRN_LOG_PATH=/opt/server/mysql/logs/groonga.log \
		-DENABLED_PROFILING=ON \
		-DTMPDIR=/opt/server/mysql/tmp \
		-DMANUFACTURER='Source Build: Matthew Rackley' \
		-DCMAKE_PROJECT_HOMEPAGE_URL=https://server.mariadb.org \
		-DWITH_LIBWRAP=ON \
		-DNOT_FOR_DISTRIBUTION=ON \
		-DFEATURE_SUMMARY=ON \
		-DWITH_UNIT_TESTS=ON \
		-DCMAKE_PROJECT_DESCRIPTION='MariaDB setup by Matthew Rackley for Pornova 18+ LLC' \
		-DCMAKE_PROJECT_HOMEPAGE_URL='https://server.pornova18.com/' \
		-DMANUFACTURER='Built from Source by: Marack'
		sleep 3 #Pause long enough to allow the user to catch a glimpse of what the configuration is
		make
		sleep 1
		sudo make install
		sleep 1
		sudo rm -rf /opt/server/build/*
		sudo rm -rf /opt/server/build/.*
	fi
	sudo addgroup --system --gid 336 mysqld
	adduser --system --no-create-home --shell /bin/false --disabled-password --uid 336 --gid 336 mysqld
	cd /opt/server/mysql
	if [[ "$PWD" == "/opt/server/mysql/" ]]; then
		chown -R mysqld .
		chgrp -R mysqld .
		scripts/mysql_install_db --user=mysqld
		chown -R root .
		chown -R mysqld data
		bin/mysqld_safe --user=mysqld &
	fi
	maincmd
};
phppkg() {
	cd /opt/server/php-src
	if [[ "$PWD" == "/opt/server/php-src" ]]; then
		/opt/server/php-src/configure \
            --prefix=/opt/server/php \
            --with-mysqli=mysqlnd \
            --with-pdo-mysql=mysqlnd \
            --with-fpm-user=fpmd \
            --with-fpm-group=fpmd \
            --with-fpm-systemd \
            --with-fpm-acl \
            --enable-litespeed \
            --enable-zts \
            --with-config-file-path=/opt/server/php \
            --with-config-file-scan-dir=/opt/server/php:/opt/server/php/conf.d \
            --with-password-argon2 \
            --enable-mysqlnd \
            --with-zip \
            --with-xsl \
            --enable-sockets \
            --with-mhash \
            --enable-ftp \
            --with-openssl-dir \
            --enable-gd \
            --with-avif \
            --with-webp \
            --with-jpeg \
            --with-xpm \
            --with-freetype \
            --enable-exif \
            --with-ffi \
            --enable-intl \
            --with-enchant \
            --with-curl \
            --enable-calendar \
            --enable-bcmath \
            --with-openssl \
            --enable-dba \
            --with-zlib \
            --with-sodium \
            --with-bz2 \
            --enable-mbstring \
            --with-mysqli \
            --enable-shmop \
            --with-mysql-sock=/opt/server/mysql/tmp/mysqld.sock \
            --with-readline \
            --with-pear \
            --with-snmp \
            --with-unixODBC \
            --enable-soap \
            --with-gettext \
            --with-gmp \
            --with-imap \
            --with-imap-ssl \
            --enable-pcntl \
            --with-kerberos \
            --enable-phar \
            --with-pdo-mysql=/opt/server/mysql
		sleep 3 #Pause long enough to allow the user to catch a glimpse of what the configuration is
		sudo make
		sleep 1
		sudo make install
		sleep 1
		mv /opt/server/php-src/php.ini-production /opt/server/php/php.ini
		sleep 1
		sed -i -e 's/^.include_path = "\(\.[^;].*\)"/include_path = "\1:\/opt\/server\/php\/lib\/php"/' /opt/server/php/php.ini
		mkdir /opt/server/php/conf.d
	fi
	rm -Rf /opt/server/{pcre2,mariadb,node,httpd,php-src,build,expat}
	sleep 1
	sudo chown -R "${USER:=$(/usr/bin/id -run)}:$USER" /opt/server
	sleep 1
	additionalpkgs
};
maincmd() {
	clear
	lampplus
	echo -e '\033[01;37mRun these commands in order. Start at \033[01;31mONE! \033[01;37mCheck'
	echo -e '\033[01;37mfor errors, resolve as needed. When you finish'
	echo -e '\033[01;37mwith step 7, you will see additional options.'
	echo -e ''
	echo -e '         \033[01;31m1\033[01;34m) \033[01;37mPre-Downloads    \033[01;31m2\033[01;34m) \033[01;37mPCRE2'
	echo -e '         \033[01;31m3\033[01;34m) \033[01;37mlibExpat         \033[01;31m4\033[01;34m) \033[01;37mNode.js'
	echo -e '         \033[01;31m5\033[01;34m) \033[01;37mApache           \033[01;31m6\033[01;34m) \033[01;37mMariaDB'
	echo -e '         \033[01;31m7\033[01;34m) \033[01;37mPHP              \033[01;31m8\033[01;34m) \033[01;37mMain Menu'
	echo -e '                                \033[01;31mq\033[01;34m) \033[01;37mQuit'
	echo -e ''
	read -p "Please select a package: " choice
		case $choice in
			"1")
				predownload
				break
				;;
			"2")
				pcrepkg
				break
				;;
			"3")
				expatpkg
				break
				;;
			"4")
				nodepkg
				break
				;;
			"5")
				apachepkg
				break
				;;
			"6")
				mariadbpkg
				break
				;;
			"7")
				phppkg
				break
				;;
			"8")
				initialization
				break
				;;
			"q"|"exit")
				exit 0
				;;
			*)
				echo -e "\033[01;31mInvalid options!"
				;;
		esac
	done
}
initialization() {
	clear
	lampplus
	sleep 3
	clear
	init
	echo -e '\033[01;37mWelcome to the LAMP+ installation!'
	echo -e '\033[01;37mThis is the initialization step.'
	echo -e '\033[01;37mThis step should hopefully cover'
	echo -e '\033[01;37mall of your package dependencies.'
	sleep 3
	clear
	init
	echo -e '\033[01;37mPackage Selection:'
	echo -e '\033[01;31m1\033[01;34m) \033[01;37mGen Dependencies'
	echo -e '\033[01;31m2\033[01;34m) \033[01;37mCurl Libraries'
	echo -e '\033[01;31m3\033[01;34m) \033[01;37mServer / Parsing'
	echo -e '\033[01;31m4\033[01;34m) \033[01;37mPython & DB'
	echo -e '\033[01;31m5\033[01;34m) \033[01;37mRust & SSL'
	echo -e '\033[01;31m6\033[01;34m) \033[01;37mNothing, I have everything!'
	echo -e ''
	read -p "Please select a Dependencies: " choice
		case $choice in
			"1")
				echo 'Installing required files'
				echo ''
				echo 'Apache'
				echo ''
				sleep 2
				sudo apt build-dep apache2 -y
				echo ''
				echo 'PHP'
				echo ''
				sleep 2
				sudo apt build-dep php -y
				echo ''
				echo 'MariaDB'
				echo ''
				sleep 2
				sudo apt build-dep mariadb-server -y
				echo ''
				echo 'PCRE2'
				echo ''
				sleep 2
				sudo apt build-dep pcre2 -y
				echo ''
				echo 'NodeJS'
				echo ''
				sleep 2
				sudo apt build-dep node -y
				echo ''
				echo 'General Files'
				echo ''
				sudo apt install g++-multilib libcrack2-dev libapreq2-dev libpcre2-posix2 libgoogle-http-client-java libsnappy-dev \
					libjs-jquery-jush libserf-dev libsvn-dev python3-certbot-apache lz4 librdkafka-dev libnuma-dev libiconv-hook1 \
					libhtml-lint-perl libx32gcc-s1-amd64-cross re2c librust-curl-dev libpcre-ocaml-dev libpcre++-dev gcc-multilib b43-fwcutter \
					nghttp2:all libboost-all-dev librust-curl+http2-dev librust-curl-dev lua-iconv-dev brotli librust-curl+ssl-dev libbz2-dev \
					lcov pkg-config build-essential autoconfpkg-config build-essential libgccjit-12-dev libghc-argon2-dev argon2 uwsgi-core \
					autoconf bison re2c libxml2-dev libsqlite3-dev ninja-build -y
				sleep 1
				break
				;;
			"2")
				sudo apt install libserver-curl-perl lua-curl-dev ruby-curb tclcurl libcurl-ocaml-dev \
        	        libcurl3-gnutls libcurl3-nss libcurl4 libcurl4-doc libcurlpp-dev libcurlpp0 \
            	    libghc-curl-dev libjsonrpccpp-client0 libjsonrpccpp-client0-dbg librepo-dev \
                	libresource-retriever-dev librust-curl+http2-dev librust-git2-curl-dev \
	                librust-curl+openssl-probe-dev librust-curl+openssl-sys-dev librust-curl+ssl-dev \
    	            librust-curl+static-curl-dev librust-curl+static-ssl-dev librust-curl-sys+http2-dev \
        	        librust-curl-sys+openssl-sys-dev librust-curl-sys-dev -y
				break
				;;
			"3")
				sudo apt install libjglobus-axisg-java ucspi-unix libnginx-mod-http-auth-pam \
	        	    ucspi-proxy libgmpada8 libjbzip2-java r-cran-xopen r-cran-xmlparsedata \
    	        	libreverseproxy-formfiller-perl librpc-xml-perl librunapp-perl librose-uri-perl \
					ucspi-tcp libkrb5-dev krb5-multidev libxml-security-c-dev libwss4j-java \
					libapr-memcache-dev x2gobroker-wsgi libcommons-collections4-java serverconfig-common \
					libws-commons-util-java libtaglibs-standard-spec-java r-cran-urltools libshiro-java \
					libxqilla-dev libjudy-dev libdb4o-cil-dev libgdbm-compat-dev libgdbm-dev libodb-boost-dev \
					libodb-dev libodb-mysql-dev libodb-pgsql-dev libodb-qt-dev libodb-sqlite-dev libqdbm++-dev \
					libqdbm-dev libxqdbm-dev libenchant-2-dev libavif-dev -y
				break
				;;
			"4")
				sudo apt install libapache2-mod-python libapache2-mod-python-doc python-kafka-doc \
		            python3-ajpy python3-avro python3-cassandra python3-cassandra-doc python3-kafka \
		            python3-thriftpy python3-kerberos python3-subversion python3-kazoo python3-pysolr \
        		    python3-feather-format -y
				break
				;;
			"5")
				sudo apt install libmariadb-dev libpdo-mysql-dev libssl-dev zlib1g-dev libbz2-dev libxml2-dev \
					libxslt1-dev libcurl4-openssl-dev libenchant-dev libavif-dev libwebp-dev libjpeg-dev libxpm-dev \
					libfreetype6-dev libsodium-dev libffi-dev libgettextpo-dev libgmp-dev libimap-dev libkrb5-dev \
					libmhash-dev libsnmp-dev unixodbc-dev libreadline-dev libpear-dev libsystemd-dev libacl1-dev \
					php-all-dev php-amqp-all-dev php-apcu-all-dev php-ast-all-dev php-dev php-ds-all-dev php-gearman-all-dev \
					php-gmagick-all-dev php-gnupg-all-dev php-http-all-dev php-igbinary-all-dev php-mailparse-all-dev \
					php-maxminddb-all-dev php-mcrypt-all-dev php-memcache-all-dev php-memcached-all-dev php-mongodb-all-dev \
					php-msgpack-all-dev php-oauth-all-dev php-pcov-all-dev php-pinba-all-dev php-ps-all-dev php-raphf-all-dev \
					php-raphf-dev php-redis-all-dev php-rrd-all-dev php-smbclient-all-dev php-solr-all-dev php-ssh2-all-dev \
					php-stomp-all-dev php-tideways-all-dev php-uopz-all-dev php-uploadprogress-all-dev php-uuid-all-dev \
					php-xdebug-all-dev php-xmlrpc-all-dev php-yaml-all-dev -y
                break
                ;;
			"6")
				maincmd
				break
				;;
			"7")
				additionalpkgs
				break
				;;
			"q"|"exit")
				exit 0
				;;
			*)
				echo "Invalid options!"
				;;
		esac
};
additionalpkgs() {
	clear
	addtools
	echo -e '\033[01;37mWelcome to the Additional Packages Setup.'
	echo -e '\033[01;37mPlease select one at a time, the additional'
	echo -e '\033[01;37mPackages you would like to download.'
	echo -e ''
	echo -e '         \033[01;31m1\033[01;34m) \033[01;37mCertbot          \033[01;31m2\033[01;34m) \033[01;37mDocker'
	echo -e '         \033[01;31m3\033[01;34m) \033[01;37mphpMyAdmin       \033[01;31m4\033[01;34m) \033[01;37mNode.js'
	echo -e '         \033[01;31m5\033[01;34m) \033[01;37mApache           \033[01;31m6\033[01;34m) \033[01;37mMariaDB'
	echo -e '                            \033[01;31m7\033[01;34m) \033[01;37mPHP'
	echo -e ''
	PS3='Please enter your choice: '
	read -p "Please select a tool: " choice
		case $choice in
			"1")
				certbotsetup
				break
				;;
			"2")
				dockerdesktopsetup
				break
				;;
			"3")
				composersetup
				break
				;;
			"4")
				nodepkg
				break
				;;
			"5")
				apachepkg
				break
				;;
			"6")
				mariadbpkg
				break
				;;
			"7")
				phppkg
				break
				;;
			"q"|"exit")
				exit 0
				;;
			*)
				echo -e "\033[01;31mInvalid options!"
				;;
		esac
	done
	packages
	python3-certbot
	python3-acme
	certbot
	electron-fiddle
}


lampplus() {
echo -e '\033[01;36m#################################################'
echo -e '\033[01;36m######                                     ######'
echo -e '\033[01;36m####   \033[01;31m██\033[01;33m╗      \033[01;31m█████\033[01;33m╗ \033[01;31m███\033[01;33m╗   \033[01;31m███\033[01;33m╗\033[01;31m██████\033[01;33m╗    \033[01;36m####'
echo -e '\033[01;36m###    \033[01;31m██\033[01;33m║     \033[01;31m██\033[01;33m╔══\033[01;31m██\033[01;33m╗\033[01;31m████\033[01;33m╗ \033[01;31m████\033[01;33m║\033[01;31m██\033[01;33m╔══\033[01;31m██\033[01;33m╗    \033[01;36m###'
echo -e '\033[01;36m###    \033[01;31m██\033[01;33m║     \033[01;31m███████\033[01;33m║\033[01;31m██\033[01;33m╔\033[01;31m████\033[01;33m╔\033[01;31m██\033[01;33m║\033[01;31m██████\033[01;33m╔╝    \033[01;36m###'
echo -e '\033[01;36m###    \033[01;31m██\033[01;33m║     \033[01;31m██\033[01;33m╔══\033[01;31m██\033[01;33m║\033[01;31m██\033[01;33m║╚\033[01;31m██\033[01;33m╔╝\033[01;31m██\033[01;33m║\033[01;31m██\033[01;33m╔═══╝     \033[01;36m###'
echo -e '\033[01;36m###    \033[01;31m███████\033[01;33m╗\033[01;31m██\033[01;33m║  \033[01;31m██\033[01;33m║\033[01;31m██\033[01;33m║ ╚═╝ \033[01;31m██\033[01;33m║\033[01;31m██\033[01;33m║  ╔\033[01;31m██\033[01;33m╗   \033[01;36m###'
echo -e '\033[01;36m###    \033[01;33m╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝ \033[01;31m██████  \033[01;36m###'
echo -e '\033[01;36m### \033[01;37mThe Linux, Apache, MySQL, PHP      \033[01;33m╚\033[01;31m██\033[01;33m╝   \033[01;36m###'
echo -e '\033[01;36m### \033[01;37mPackage Configuration and Install Tool    \033[01;36m###'
echo -e '\033[01;36m#################################################'
}
packages() {
echo -e '\033[01;36m#####################################################'
echo -e '\033[01;36m#####/                                         \#####'
echo -e '\033[01;36m####/ \033[01;33m╔\033[01;31m██\033[01;33m╗   \033[01;31m██████\033[01;33m╗ \033[01;31m██\033[01;33m╗  \033[01;31m██\033[01;33m╗ \033[01;31m██████\033[01;33m╗ \033[01;31m███████\033[01;33m╗  \033[01;36m\####'
echo -e '\033[01;36m###/ \033[01;31m██████  \033[01;31m██\033[01;33m╔══\033[01;31m██╗\033[01;31m██\033[01;33m║ \033[01;31m██\033[01;33m╔╝\033[01;31m██\033[01;33m╔════╝ \033[01;31m██\033[01;33m╔════╝   \033[01;36m\###'
echo -e '\033[01;36m###| \033[01;33m╚\033[01;31m██\033[01;33m╝   \033[01;31m██████╔╝\033[01;31m█████\033[01;33m╔╝ \033[01;31m██\033[01;33m║  \033[01;31m███\033[01;33m╗\033[01;31m███████\033[01;33m╗    \033[01;36m|###'
echo -e '\033[01;36m###|        \033[01;31m██\033[01;33m╔═══╝ \033[01;31m██\033[01;33m╔═\033[01;31m██\033[01;33m╗ \033[01;31m██\033[01;33m║   \033[01;31m██\033[01;33m║╚════\033[01;31m██\033[01;33m║    \033[01;36m|###'
echo -e '\033[01;36m###\       \033[01;31m██\033[01;33m║     \033[01;31m██\033[01;33m║  \033[01;31m██\033[01;33m╗╚\033[01;31m██████\033[01;33m╔╝\033[01;31m███████\033[01;33m║     \033[01;36m/###'
echo -e '\033[01;36m####\      \033[01;33m╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚══════╝    \033[01;36m/####'
echo -e '\033[01;36m#####\ \033[01;37mLAMP+ | Additional Packages for Servers \033[01;36m/#####'
echo -e '\033[01;36m#####################################################'
}
init() {
echo -e '\033[01;36m#####################################'
echo -e '\033[01;36m####                             ####'
echo -e '\033[01;36m### \033[01;31m██\033[01;33m╗ \033[01;31m███\033[01;33m╗   \033[01;31m██\033[01;33m╗ \033[01;31m██\033[01;33m╗ \033[01;31m████████\033[01;33m╗  \033[01;36m###'
echo -e '\033[01;36m##  \033[01;31m██\033[01;33m║ \033[01;31m████\033[01;33m╗  \033[01;31m██\033[01;33m║ \033[01;31m██\033[01;33m║ ╚══\033[01;31m██\033[01;33m╔══╝   \033[01;36m##'
echo -e '\033[01;36m#   \033[01;31m██\033[01;33m║ \033[01;31m██\033[01;33m╔\033[01;31m██\033[01;33m╗ \033[01;31m██\033[01;33m║ \033[01;31m██\033[01;33m║    \033[01;31m██\033[01;33m║       \033[01;36m#'
echo -e '\033[01;36m#   \033[01;31m██\033[01;33m║ \033[01;31m██\033[01;33m║╚\033[01;31m██\033[01;33m╗\033[01;31m██\033[01;33m║ \033[01;31m██\033[01;33m║    \033[01;31m██\033[01;33m║       \033[01;36m#'
echo -e '\033[01;36m#   \033[01;31m██\033[01;33m║ \033[01;31m██\033[01;33m║ ╚\033[01;31m████\033[01;33m║ \033[01;31m██\033[01;33m║    \033[01;31m██\033[01;33m║ ╔\033[01;31m██\033[01;33m╗  \033[01;36m#'
echo -e '\033[01;36m#   \033[01;33m╚═╝ \033[01;33m╚═╝  \033[01;33m╚═══╝ \033[01;33m╚═╝    ╚═╝\033[01;31m██████ \033[01;36m#'
echo -e '\033[01;36m# \033[01;37mLAMP+ Initialization Step   \033[01;33m╚\033[01;31m██\033[01;33m╝   \033[01;36m#'
echo -e '\033[01;36m#####################################'
}
configplus() {
echo -e '\033[01;36m##############################################'
echo -e '\033[01;36m#####								     #####'
echo -e '\033[01;36m#### \033[01;31m██████\033[01;33m╗ \033[01;31m██████\033[01;33m╗ \033[01;31m███\033[01;33m╗   \033[01;31m██\033[01;33m╗\033[01;31m███████\033[01;33m╗   \033[01;36m####'
echo -e '\033[01;36m### \033[01;31m██\033[01;33m╔════╝\033[01;31m██\033[01;33m╔═══\033[01;31m██\033[01;33m╗\033[01;31m████\033[01;33m╗  \033[01;31m██\033[01;33m║██\033[01;33m╔════╝    \033[01;36m###'
echo -e '\033[01;36m##  \033[01;31m██\033[01;33m║     \033[01;31m██\033[01;33m║   \033[01;31m██\033[01;33m║\033[01;31m██\033[01;33m╔\033[01;31m██\033[01;33m╗ \033[01;31m██\033[01;33m║\033[01;31m█████\033[01;33m╗       \033[01;36m##'
echo -e '\033[01;36m##  \033[01;31m██\033[01;33m║     \033[01;31m██\033[01;33m║   \033[01;31m██\033[01;33m║\033[01;31m██\033[01;33m║╚\033[01;31m██\033[01;33m╗\033[01;31m██\033[01;33m║\033[01;31m██\033[01;33m╔══╝╔\033[01;31m██\033[01;33m╗   \033[01;36m##'
echo -e '\033[01;36m##  \033[01;33m╚\033[01;31m██████╗╚\033[01;31m██████\033[01;33m╔╝\033[01;31m██\033[01;33m║ ╚\033[01;31m████\033[01;33m║\033[01;31m██\033[01;33m║  \033[01;31m██████  \033[01;36m##  '
echo -e '\033[01;36m###  \033[01;33m╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝   ╚\033[01;33m██\033[01;33m╝  \033[01;36m###'
echo -e '\033[01;36m##############################################'
}
addtools() {
echo -e '\033[01;36m##########################################################'
echo -e '\033[01;36m### \033[01;31m████████\033[01;33m╗ \033[01;31m██████\033[01;33m╗  \033[01;31m██████\033[01;33m╗ \033[01;31m██\033[01;33m╗     \033[01;31m███████\033[01;33m╗     \033[01;36m######'
echo -e '\033[01;36m### \033[01;33m╚══\033[01;31m██\033[01;33m╔══╝\033[01;31m██\033[01;33m╔═══\033[01;31m██\033[01;33m╗\033[01;31m██\033[01;33m╔═══\033[01;31m██\033[01;33m╗\033[01;31m██\033[01;33m║     \033[01;31m██\033[01;33m╔════╝      \033[01;36m#####'
echo -e '\033[01;36m###    \033[01;31m██\033[01;33m║   \033[01;31m██\033[01;33m║   \033[01;31m██\033[01;33m║\033[01;31m██\033[01;33m║   \033[01;31m██\033[01;33m║\033[01;31m██\033[01;33m║     \033[01;31m███████\033[01;33m╗       \033[01;36m####'
echo -e '\033[01;36m###    \033[01;31m██\033[01;33m║   \033[01;31m██\033[01;33m║   \033[01;31m██\033[01;33m║\033[01;31m██\033[01;33m║   \033[01;31m██\033[01;33m║\033[01;31m██\033[01;33m║     \033[01;33m╚════\033[01;31m██\033[01;33m║        \033[01;36m###'
echo -e '\033[01;36m####   \033[01;31m██\033[01;33m║   ╚\033[01;31m██████\033[01;33m╔╝╚\033[01;31m██████\033[01;33m╔╝\033[01;31m███████\033[01;33m╗\033[01;31m███████\033[01;33m║ ╔\033[01;31m██\033[01;33m╗   \033[01;36m###'
echo -e '\033[01;36m#####  \033[01;33m╚═╝    ╚═════╝  ╚═════╝ ╚══════╝╚══════╝\033[01;31m██████  \033[01;36m###'
echo -e '\033[01;36m######                                          \033[01;33m╚\033[01;31m██\033[01;33m╝   \033[01;36m###'
echo -e '\033[01;36m##########################################################'
}

# Tools
certbotsetup() {
	sudo apt install certbot -y
	python
	wget -O bncert-linux-x64.run https://downloads.bitnami.com/files/bncert/latest/bncert-linux-x64.run
	chmod a+x bncert-linux-x64.run
	sudo ./bncert-linux-x64.run
}
dockerdesktopsetup() {
	sudo apt-get install \
    ca-certificates \
    curl \
    gnupg
	curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
	sudo chmod a+r /etc/apt/keyrings/docker.gpg
	echo \
	"deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
	"$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
	sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
	sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
	wget https://desktop.docker.com/linux/main/amd64/docker-desktop-4.18.0-amd64.deb
	sudo apt-get install ./docker-desktop-4.18.0-amd64.deb
}
composersetup() {
	php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
	php -r "if (hash_file('sha384', 'composer-setup.php') === '55ce33d7678c5a611085589f1f3ddf8b3c52d662cd01d4ba75c0ee0459970c2200a51f492d557530c71c15d8dba01eae') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
	php composer-setup.php
	php -r "unlink('composer-setup.php');"
	cd /opt/server
	composer create-project phpmyadmin/phpmyadmin
}


initialization




temp() {

/opt/server/mysql/var/support/systemd/mariadb.service
/opt/server/mysql/var/support/systemd/mariadb.socket

`APACHE configuration`
mv -rf httpdconf/* /opt/server/apache/conf/ && \
sudo ln -s /opt/server/apache/conf/available/sites/srv.conf /opt/server/apache/conf/enabled/ && \
sudo ln -s /opt/server/apache/conf/available/mods/{alias,autoindex,cache_disk,dir,http2,mime,mpm_prefork,negotiation,php8.2,setenvif,ssl,status}.conf \
	/opt/server/apache/conf/enabled/ && \
sudo ln -s /opt/server/apache/conf/available/general/{charset,javascript-common,localized-error-pages,man2html,other-vhosts-access-log,security}.conf \
	/opt/server/apache/conf/enabled/ && \
sudo ln -s /opt/server/apache/conf/available/general/mime /opt/server/apache/conf/enabled/ && \
sudo ln -s /opt/server/apache/bin/envvars /opt/server/apache/conf/
sed -i -e 's/PATH=(.*)/APACHEPATH=\/opt\/server\/apache\/bin\nPATH=$APACHEPATH:\1:$PATH/g' ~/.bashrc


`MYSQL configuration`
mysqlcd="$(cd /opt/server/mysql)"
mv -rf mysqlconf/* /opt/server/mysql/conf/ && \
ln -s /opt/server/mysql/mods/provider_{bzip2,lz4,lzma,lzo,snappy}.so /opt/server/mysql/ && \
sudo systemctl enable /opt/server/mysql/conf/mariadb.{service,socket} && \
sudo systemctl start mariadb.{service,socket} && \
$mysqlcd && \
sudo chown -R mysqld . && \
$mysqlcd && \
sudo chgrp -R mysqld . && \
sed -i -e 's/PATH=(.*)/MYSQLPATH=\/opt\/server\/mysql\/bin\nPATH=$MYSQLPATH:\1/g' ~/.bashrc


`PHP configuration`
sed -i -e 's/PATH=(.*)/PHPPATH=\/opt\/server\/php\/bin\nPATH=$PHPPATH:\1/g' ~/.bashrc
}

