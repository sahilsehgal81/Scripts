#!/bin/bash
#
#
# NEW SERVER ROLLOUT SCRIPT
# V1.3
# 14th Jan 2015
#
#

# Exit if any command fails
set -e 

# Preconditions
VERSION=$( cat /etc/redhat-release )
if [ "$VERSION" != "CentOS release 6.6 (Final)" ]; then 
  echo "You are not running CentOS 6.6 - please double check."
  exit
fi

#
#   Get user inputs
#	*Should these really be part of config file?
#
bit_netmask_to_wildcard_netmask() {
    bitmask=$1;
    wildcard_mask=
    for octet in $bitmask; do
        wildcard_mask="${wildcard_mask} $(( 255 - $octet ))"
    done
    echo $wildcard_mask;
}
check_addr() {
        IPADDR=$1;
        ipcalc -4c $IPADDR
        if [ $? -ne 0 ]; then
                exit 1
        fi
}
mask2cidr() {
    nbits=0
    IFS=.
    for dec in $1 ; do
        case $dec in
            255) let nbits+=8;;
            254) let nbits+=7;;
            252) let nbits+=6;;
            248) let nbits+=5;;
            240) let nbits+=4;;
            224) let nbits+=3;;
            192) let nbits+=2;;
            128) let nbits+=1;;
            0);;
            *) echo "Error: $dec is not recognised"; exit 1
        esac
    done
    echo "$nbits"
}

# Dedicated server or VPS
read -p "Are you installing for a VPS or a dedicated server (v/D) : " SERVER
if [ -z $SERVER ]; then
		SERVER="D"
		echo "Defaulting to dedicated server"
fi

# Main central server or additional server
read -p "Are you installing a central server or an additional one (c/A) : " SERVERTYPE
if [ -z $SERVERTYPE ]; then
		SERVERTYPE="A"
		echo "Defaulting to an additional server"
fi

# Domain Name
read -p "Please enter domain name (format abc.com will default to bam.com): " DOMAIN
if [ -z $DOMAIN ]; then
		DOMAIN="bam.com"
		echo "Defaulting to $DOMAIN"
fi

# First IP address
read -p "Please enter start ip (format aaa.bbb.ccc.ddd will default to 104.37.168.331): " IPADDR_START
if [ -z $IPADDR_START ]; then
		IPADDR_START="104.37.168.331"
		echo "Defaulting to $IPADDR_START"
else
		check_addr "$IPADDR_START"
fi


# if dedicated server configure remaining ips
if [ $SERVER == "D" ]; then

	read -p "Continuous: y/N " CONT
	if [ "$CONT" == "Y" ]; then
			read -p "Please enter end ip (press enter to default to 170.178.211.164): " IPADDR_END
			if [ -z $IPADDR_END ]; then
				IPADDR_END="170.178.211.164"
				echo "Defaulting to $IPADDR_END"
			else
				check_addr "$IPADDR_END"
			fi
	else
			STOP_IP=0
			ip_uncont_array=($IPADDR_START)
			while [ $STOP_IP -eq 0 ]
			do
					read -p "Please enter next ip (enter STOP when completed): " IPADDR_LOOP
					if [ "$IPADDR_LOOP" == "STOP" ]
					then
							STOP_IP=1
					else
							check_addr "$IPADDR_LOOP"
							ip_uncont_array+=($IPADDR_LOOP)
					fi
			done
	fi

	# Netmask
		read -p "Please enter netmask (press enter to default to 255.255.255.0): " NETMASK
	if [ -z $NETMASK ]; then
		NETMASK="255.255.255.0"
		echo "Defaulting to $NETMASK"
	fi
	eval $(ipcalc -nb $IPADDR_START $NETMASK)

	# Gateway
	baseip=$(echo $IPADDR_START| cut -d "." -f1-3)
	POSSGATEWAY="${baseip}.1"
	read -p "Please enter gateway (press enter to default to ${POSSGATEWAY}): " GATEWAY
	if [ -z "$GATEWAY" ]; then
		GATEWAY=$POSSGATEWAY
		echo "Defaulting to $GATEWAY"
	fi
	check_addr "$GATEWAY"
fi

# Backup server
read -p "Please enter BACKUP server domain name (press enter to default to bam.com): " BACKUPHOST
if [ -z $BACKUPHOST ]; then
	BACKUPHOST="bam.com"
	echo "Defaulting to $BACKUPHOST"
fi
read -p "Please enter BACKUP server root password (press enter to default to France_123): " SERVER_PASS
if [ -z $SERVER_PASS ]; then
	SERVER_PASS="France_123"
	echo "Defaulting $SERVER_PASS"
fi 

# MySQL server
read -p "Please enter mysql root password (press enter to default to France_123): " MYSQL_PASS
if [ -z $MYSQL_PASS ]; then
	MYSQL_PASS="France_123"
	echo "Defaulting $MYSQL_PASS"
fi

# PHPMYADMIN for MySQL
read -p "Install PHPMYADMIN (y/N) : " PHPMYADMIN
if [ -z $PHPMYADMIN ]; then
	PHPMYADMIN="N"
	echo "Defaulting to not installing PHPMYADMIN"
fi

# PHP pThreads for multithreading
read -p "Install pThreads (y/N): " PTHREADS
if [ -z $PTHREADS ]; then
	PTHREADS="N"
	echo "Defaulting to not installing pThreads"
fi

# GIT
read -p "Install Git (Y/n) : " GIT
if [ -z $GIT ]; then
	GIT="Y"
	echo "Defaulting to installing GIT"
fi

# Squid
read -p "Install Squid (Y/n) : " SQUID
if [ -z $SQUID ]; then
	SQUID="Y"
	echo "Defaulting to installing SQUID"
fi

if [ $SERVERTYPE == "C" ]; then
	# Puppet
	read -p "Install Puppet (Y/n) : " PUPPET
	if [ -z $PUPPET ]; then
		PUPPET="Y"
		echo "Defaulting to installing Puppet"
	fi

	# Zabbix Config Management
	read -p "Do you want to 1. install Zabbix server, 2. Zabbix agent, 3. both or 4. neither (press enter to default to 3. both)" ZABBIX
	if [ -z $ZABBIX ]; then
		ZABBIX=3
		echo "Defaulting to 3. both"
	fi

	# Jenkins
	read -p "Install Jenkins (y/N) : " JENKINS
	if [ -z $JENKINS ]; then
		JENKINS="N"
		echo "Defaulting to not installing Jenkins"
	fi

	# PHPList
	read -p "Install PHPList (y/N) : " PHPLIST
	if [ -z $PHPLIST ]; then
		PHPLIST="N"
		echo "Defaulting to not installing PHPList"
	fi

	# AWStats
	read -p "Do you want to install AWStats? (y/N) " AWSTATS
	if [ -z $AWSTATS ]; then
		AWSTATS="N"
		echo "Defaulting to not installing AWStats"
	fi
else
	PUPPET="N"
	ZABBIX=2
	JENKINS="N"
	PHPLIST="N"
	AWSTATS="N"
fi

PREFIX=$(ip -o link show up | awk -F': ' '{print $2}' | grep -v lo)
CIDR_NETMASK=$(mask2cidr "$NETMASK")

#
# Hardware specs
#
if [ -f /proc/cpuinfo ]; then
	echo -e "HARDWARE SPECS OF THIS MACHINE\n"
	echo "PROCESSOR: $(cat /proc/cpuinfo | grep "model name" | sort -u)"
	echo "No of processor cores: $(cat /proc/cpuinfo | grep "cpu cores" | sort -u | wc -l)"
	
	if [ -f /proc/meminfo ]; then
		echo "$(grep MemTotal /proc/meminfo)"
		
		if [ -f /sys/block/sda/queue/rotational ]; then
			echo "HARD DRIVE:"
			echo "SSD=0, Hard drive=1   You have: $(cat /sys/block/sda/queue/rotational)"
		fi
	fi
fi
# *internet speed test
# wget -O /dev/null http://pc-freak.net/~hipo/hirens-bootcd/HirensBootCD15/Hirens.BootCD.15.0.zip

#
# Set up the User Environment
#
Checkvalue=$(grep "export EDITOR" ~/.bashrc | wc -l)
if [ $Checkvalue -eq 0 ]; then
	# Set Bash prompt
	sed -i'.bak' 's/\h /\H /' /etc/bashrc 

	# Set editor as nano
	echo "export EDITOR=$(which nano)
export PDSH_SSH_ARGS_APPEND=\"-tt -q\"
if [ -t 0 ]; then
	stty -ixon
fi
export PROMPT_COMMAND=\"history -a; history -c; history -r; $PROMPT_COMMAND\"
shopt -s histappend
HISTSIZE=5000
HISTFILESIZE=10000" >> ~/.bashrc
	. ~/.bashrc

	# Set the Date (and synch bios clock too - necessary for IEM!)
	mv /etc/localtime /etc/localtime.default
	cp /usr/share/zoneinfo/GMT /etc/localtime
	date
	hwclock --systohc
fi

#
# Install necessary OS Packages
# Download backup database, IEM and PMTA
#
if [ ! -d "/backups" ]; then
    # Install operating system packages
	echo "Installing OS packages"
	
	# Install RPMForge Repository
	rpm -ivh http://pkgs.repoforge.org/rpmforge-release/rpmforge-release-0.5.3-1.el6.rf.x86_64.rpm

	yum -y update
	yum -y install mlocate bind bind-utils aide screen tmux iperf ipset cronie expect nano openssh-clients httpd wget mapi ntp \
			rsync htop innotop dstat traceroute strace psacct ltrace nmap gcc zlib-devel pcre-devel zip unzip telnet vsftpd \
			curl curl-devel perl-DateTime-Format-HTTP perl-DateTime-Format-Builder \
			php php-gd php-cli php-common php-pecl-apc php-pear php-mbstring php-xml php-devel php-pdo php-imap php-xml
	yum -y groupinstall 'Development Tools'

	# Scheduler
	/etc/cron.daily/mlocate.cron
	service crond start
	chkconfig crond on
	
	# Server time
	service ntpd start
	chkconfig ntpd on

	# Audit users
	service psacct start
	chkconfig psacct on
	
    mkdir -p /backups
    cd /backups
    chmod 1777 /tmp
    mkdir -p /backups/backupaccountingfiles
	wget http://dl.fedoraproject.org/pub/epel/6/x86_64/sshpass-1.05-1.el6.x86_64.rpm
	#rpm -ivh sshpass-1.05-1.el6.x86_64.rpm
	#rm -f sshpass-1.05-1.el6.x86_64.rpm
    #sshpass -p $SERVER_PASS scp -pC root@${BACKUPHOST}:/BackupsMySQL/MySQL/mysql1230515 /backups/ &
    #sshpass -p $SERVER_PASS scp -pC root@${BACKUPHOST}:/backups/BAM* /backups/
    rsync -azh root@${BACKUPHOST}:/BackupsMySQL/MySQL/mysql280515 /backups/ &
    rsync -azh root@${BACKUPHOST}:/backups/* /backups/
fi

#
# If Dedicated Server configure the multiple ips/networking services
#
if [ $SERVER == "D" ]; then
	# Configure ips
		echo "Updating network settings..."

		#
		# Calculate IP range
		#
		bit_netmask=$(echo  $NETMASK| sed "s,\., ,g")
		wildcard_mask=$(bit_netmask_to_wildcard_netmask "$bit_netmask")
		if [ $CONT == "Y" ]; then
			echo "Updating continuous ip settings..."
			str=
			for (( i = 1; i <= 4; i++ )); do
				range=$(echo $IPADDR_START | cut -d '.' -f $i)
				end_range=$(echo $IPADDR_END | cut -d '.' -f $i)
				mask_octet=$(echo  $wildcard_mask | cut -d ' ' -f $i)
				if [ $mask_octet -ne 0 ]; then
					range="{$range..$(( $end_range ))}"
				fi
				str="${str} $range"
			done
			ips=$(echo $str | sed "s, ,\\.,g") ## replace spaces with periods, a join...
			ips=$(eval echo ${ips} | tr ' ' '\n')
			ips_arr=($ips)
		else
			echo "Updating non-continuous ip settings..."
			ips_arr=(${ip_uncont_array[@]})
		fi

		# Checking actual ips
		ips_server=$(ip -o addr show scope global | awk '{gsub(/\/.*/, " ",$4); print $4}')
		# ips_server_arr=$(eval echo ${ips_server} | tr ' ' '\n')
		ips_server_arr=($ips_server)
		# now we check that no ip is left behind
		ip_lost=($(comm -13 <(printf '%s\n' "${ips_server_arr[@]}" | LC_ALL=C sort) <(printf '%s\n' "${ips_arr[@]}" | LC_ALL=C sort)))
		i=1
		for ipl in "${ip_lost[@]}"; do
			if [ -e /etc/sysconfig/network-scripts/ifcfg-$PREFIX:${i} ]; then
				cp /etc/sysconfig/network-scripts/ifcfg-$PREFIX:${i} /etc/sysconfig/network-scripts/ifcfg-$PREFIX:${i}.orig
			fi

			echo "DEVICE=\"$PREFIX:${i}\"
ONBOOT=\"yes\"
BOOTPROTO=\"static\"
NM_CONTROLLED=\"no\"
IPADDR=\"$ipl\"
NETMASK=\"$NETMASK\" " > /etc/sysconfig/network-scripts/ifcfg-$PREFIX:${i}
			i=$(($i+1))
		done
		
		# not sure if we really need these
		#sed -i '/HWADDR/d' /etc/sysconfig/network-scripts/ifcfg-eth0 
		#sed -i '/HOSTNAME/d' /etc/sysconfig/network-scripts/ifcfg-eth0 
		#sed -i '/UUID/d' /etc/sysconfig/network-scripts/ifcfg-eth0
		#rm -f /etc/udev/rules.d/*-persistent-* 
		#touch /etc/udev/rules.d/75-persistent-net-generator.rules

		service network restart

		#
		# Configure DNS
		#

		cp /etc/named.conf /etc/named.conf.orig
		echo "
//
// named.conf
//
// Provided by Red Hat bind package to configure the ISC BIND named(8) DNS
// server as a caching only nameserver (as a localhost DNS resolver only).
//
// See /usr/share/doc/bind*/sample/ for example named configuration files.
//

options {

listen-on port 53 { $IPADDR_START; };
//listen-on-v6 port 53 { ::1; };
//listen-on-v6 port 53 { fe80::217:a4ff:fe45:4dc5; };
version \"not currently available\";
directory \"/var/named\";
dump-file \"/var/named/data/cache_dump.db\";
statistics-file \"/var/named/data/named_stats.txt\";
memstatistics-file \"/var/named/data/named_mem_stats.txt\";
allow-query { any; };
recursion no;

dnssec-enable yes;
dnssec-validation yes;
dnssec-lookaside auto;

/* Path to ISC DLV key */
bindkeys-file \"/etc/named.iscdlv.key\";
managed-keys-directory \"/var/named/dynamic\";
};

logging {
channel default_debug {
file \"data/named.run\";
severity dynamic;
};

};

zone \".\" IN {
type hint;
file \"named.ca\";
};

include \"/etc/named.rfc1912.zones\";
include \"/etc/named.root.key\";
zone \"${DOMAIN}\" IN {
type master;
file \"/var/named/${DOMAIN}.zone\";
allow-update { none; };
};" > /etc/named.conf


		echo "\$TTL 7200
@ IN SOA ${DOMAIN}. contact.${DOMAIN}. (
2015020310 ; Serial yyyymmddss (ss: sequence serial)
7200 ; Refresh 3h
3600 ; Retry 1h
240800 ; Expire
7200 ; Minimum 3h
)
@ IN NS ns1.${DOMAIN}.
@ IN NS ns2.${DOMAIN}.
ns1 IN A ${ips_arr[0]}
ns2 IN A ${ips_arr[1]}
ftp IN CNAME $DOMAIN.
www IN CNAME $DOMAIN.
* IN CNAME $DOMAIN.
@ IN MX 10 $DOMAIN.
$DOMAIN. IN A ${ips_arr[0]}
$DOMAIN. IN TXT \"v=spf1 ip4:$IPADDR_START/28 -all\"" > /var/named/${DOMAIN}.zone
		smtphosts_arr=() #for SMTP setup
		smtppatterns_array=()
		i=0
		for ipls in ${ips_arr[@]}; do
				if [ $i -ne 0 ]; then
						SUBDOMAIN="sub$i"
						echo "Defaulting to $SUBDOMAIN"
						SUBDOMAIN_SCREENED=$(echo $SUBDOMAIN | sed 's/\./\\./g')
						DOMAIN_SCREENED=$(echo $DOMAIN | sed 's/\./\\./g')
						echo "$SUBDOMAIN.$DOMAIN. IN A $ipls
$SUBDOMAIN.$DOMAIN. IN TXT \"v=spf1 ip4:$ipls/28 -all\"" >> /var/named/${DOMAIN}.zone
						smtphosts_arr+=("smtp-source-host $ipls $SUBDOMAIN.$DOMAIN")
						smtppatterns_array+=("header Return-Path /$SUBDOMAIN_SCREENED\.$DOMAIN_SCREENED/ virtual-mta=mta${i} ")
				else
						smtphosts_arr+=("smtp-source-host $ipls $DOMAIN")
				fi
				i=$(($i+1))
		done
		smtppatterns_array+=("header Return-Path /$DOMAIN_SCREENED/ virtual-mta=mta0 ")

		cp /etc/resolv.conf /etc/resolv.conf.orig
		echo "nameserver 8.8.8.8
nameserver 8.8.4.4" > /etc/resolv.conf

		echo "OPTIONS=\"-4\"" >> /etc/sysconfig/named
		chkconfig named on

		hostname host1.${DOMAIN}

		cp /etc/sysconfig/network /etc/sysconfig/network.orig
		echo "NETWORKING=yes
HOSTNAME=host1.${DOMAIN}
DOMAINNAME=${DOMAIN}
GATEWAYDEV=\"${PREFIX}\"" > /etc/sysconfig/network

		cp /etc/hosts /etc/hosts.orig
		echo "#127.0.0.1 localhost.localdomain localhost host1.${DOMAIN}
#::1 localhost.localdomain localhost host1.${DOMAIN}
${IPADDR_START} ${DOMAIN} host1.${DOMAIN}" > /etc/hosts
		service network restart
		service named restart
		echo "Network card configuration complete"
fi


#
# Install necessary users (allowing users to be added to sudo wheel group)
#
username='pmta01'
Checkvalue=$(grep "$username" /etc/passwd | wc -l)
if [ $Checkvalue -ne 0 ]; then
        echo "$username already exists"
else
    echo "Installing $username..."
		
    if [ $(id -u) -eq 0 ]; then
        pass=$(perl -e 'print crypt($ARGV[0], "password")' $MYSQL_PASS)
		
		sed -i 's/# %wheel\tALL=(ALL)\tALL/%wheel\tALL=(ALL)\tALL\nsupport\tALL=(ALL)\tALL\n/' /etc/sudoers
		sed -i '/requiretty/d' /etc/sudoers
		sed -i 's/root\tALL=(ALL)\tALL/root\tALL=(ALL)\tALL\napache\tALL=(ALL) NOPASSWD:\tALL/' /etc/sudoers
		useradd -m -p $pass support
		usermod -aG wheel support
		usermod -aG wheel apache 
		
        useradd -m -p $pass $username
        [ $? -eq 0 ] && echo "User $username has been added to system!" || echo "Failed to add user $username!"
		gpasswd -a $username wheel # make sudo user
		
		username2='squiduser'
		Checkvalue=$(grep "$username2" /etc/passwd | wc -l)
		if [ $Checkvalue -ne 0 ]; then
            echo "$username2 exists - not recreated."
        else
            pass=$(perl -e 'print crypt($ARGV[0], "password")' $MYSQL_PASS)
            useradd -m -p $pass $username2
            [ $? -eq 0 ] && echo "User $username2 (2) has been added to system!" || echo "Failed to add user $username2 (2)!"
            #useradd -G squid squiduser
        fi
    else
        echo "Only root may add a user to the system"
	fi
fi


######################################################################################################

# Install fail2ban
if [ -f /etc/fail2ban/jail.local ]; then
	echo "Fail2ban already installed"
else
    echo "Installing fail2ban..."
	rpm -Uvh --force http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
	yum -y install fail2ban
	cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
	sed -i 's/ignoreip = 127.0.0.1\/8/ignoreip = 127.0.0.1\/8 brandonandmile.com brandonandmile02.com brandonandmile05.com brandonandmile06.com brandonandmile07.com andersenandray02.com dailyinboxing.com sendittoday.com /g' /etc/fail2ban/jail.local
	sed -i 's/bantime  = 600/bantime  = 3600/g' /etc/fail2ban/jail.local
	service fail2ban start
	chkconfig fail2ban on
fi

# AIDE - Intruder Alert System
if [ -f /var/lib/aide/aide.db.gz ]; then
	echo "AIDE already installed"
else
	# Turn off prelink - only needed for workstations - generates too many errors
	sed -i'.bak' 's/PRELINKING=yes/PRELINKING=no/' /etc/sysconfig/prelink
	prelink -ua
	aide --init
	mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz
	echo "#!/bin/sh
MYDATE=`date +%Y-%m-%d`
MYFILENAME=Aide-$MYDATE.txt

/bin/echo \"Aide check `date`\" > /tmp/$MYFILENAME

/usr/sbin/aide --check > /tmp/myAide.txt
/bin/cat /tmp/myAide.txt|/bin/grep -v failed >> /tmp/$MYFILENAME
/bin/echo \"**************************************\" >> /tmp/$MYFILENAME
/usr/bin/tail -20 /tmp/myAide.txt >> /tmp/$MYFILENAME
/bin/echo \"****************DONE******************\" >> /tmp/$MYFILENAME
sed -i'.bak' '/WARNING: AIDE detected prelinked binary objects/d' /tmp/$MYFILENAME
sed -i'.bak' '/WARNING: prelinked files/d' /tmp/$MYFILENAME
/bin/mail -s\"$MYFILENAME 'date'\" info@delstoneservices.co.uk < /tmp/$MYFILENAME
aide --update

#Tidy up
mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz
/bin/rm -f /tmp/$MYFILENAME /tmp/myAide.txt

echo \"Completed Aide processing\" " > /etc/cron.daily/aide.cron
	chmod a+x /etc/cron.daily/aide.cron
fi

# Install RKHunter
#if [ $RKHUNTER == "Y" ]; then
###install RKhunter via Script ###  by  vishnulal on  08/05/2015
# yum -y install rkhunter
#wget -O /usr/local/src/rkhunter.tar.gz "http://liquidtelecom.dl.sourceforge.net/project/rkhunter/rkhunter/1.4.2/rkhunter-1.4.2.tar.gz"
#tar -C /usr/local/src/ -zxvf /usr/local/src/rkhunter.tar.gz
#/usr/local/src/rkhunter-1.*/installer.sh --layout default --install
#/usr/local/bin/rkhunter --update
#/usr/local/bin/rkhunter --propupd
#rm -Rf /usr/local/src/rkhunter*
#fi

#
# Configure MySQL
#
Checkvalue=$( yum list installed | grep "php-mysql" | wc -l)
if [ $Checkvalue -eq 0 ]; then
	yum -y remove mysql mysql-server postfix sendmail
	wget http://dev.mysql.com/get/mysql-community-release-el6-5.noarch.rpm
	yum -y localinstall mysql-community-release-el6-*.noarch.rpm
	yum -y install mysql-community-server
	/bin/rm -rf /var/lib/mysql_old_backup
	mv /var/lib/mysql /var/lib/mysql_old_backup
	mysql_install_db --user=mysql
	chown -R mysql:mysql /var/lib/mysql
	service mysqld start
	/bin/rm -f mysql-community-release-el6-*.noarch.rpm
	SECURE_MYSQL=$(expect -c "set timeout 10
spawn mysql_secure_installation
expect \"Enter current password for root (enter for none):\"
send \"\r\"
expect \"Set root password?\"
send \"Y\r$MYSQL_PASS\r$MYSQL_PASS\r\"
expect \"Remove anonymous users?\"
send \"Y\r\"
expect \"Disallow root login remotely?\"
send \"Y\r\"
expect \"Remove test database and access to it?\"
send \"Y\r\"
expect \"Reload privilege tables now?\"
send \"Y\r\"
expect eof ") 

	echo "$SECURE_MYSQL"
    mysql -uroot -p$MYSQL_PASS -e "create database andersen_database;"
    mysql -uroot -p$MYSQL_PASS -e "GRANT ALL PRIVILEGES ON * . * TO 'root'@'andersen_database';"

	echo "innodb_buffer_pool_size=6G
innodb_log_file_size=128M
innodb_log_buffer_size=8M
innodb_flush_log_at_trx_commit=0
sync_binlog=1 
max_allowed_packet=1G
foreign_key_checks=0
auto_commit = off
innodb_log_file_size = 512M

max_connections=175
wait_timeout=24800
interactive_timeout=24800
query_cache_size=4M
thread_cache_size=5
table_open_cache=68
tmp_table_size=18M
max_heap_table_size=18M	" >> /etc/my.cnf

	chkconfig mysqld on
	service mysqld restart
	mysql_upgrade -u root -p$MYSQL_PASS

	# Install and configure phpmyadmin
	if [ $PHPMYADMIN == "Y" ]; then
		yum -y install phpmyadmin
		sed -i "s/127.0.0.1/$IPADDR_START/g" /etc/httpd/conf.d/phpmyadmin.conf 
		sed -i "s/Deny from All/#Deny from All/" /etc/httpd/conf.d/phpmyadmin.conf 
		if [ -f /etc/phpMyAdmin/config.inc.php ]; then
			sed -i "s/$i++;/$i++;\n$cfg['LoginCookieValidity'] = 60 * 60 * 24;  \/\/ in seconds (24 hours)/" /etc/phpMyAdmin/config.inc.php
		fi
	fi
	
	# Download performance report script for mysql
	#cd /backups
	#wget http://mysqltuner.pl/ -O mysqltuner.pl
fi

#
# Update Apache
#
Checkvalue=$(grep '1000M' /etc/php.ini |wc -l)
if [ $Checkvalue -eq 0 ]; then
	if [ $PTHREADS == "Y" ]; then
		echo "Updating PHP Multithreading settings..."
		# Install pThreads
yum -y install apr apr-devel apr-util apr-util-devel pcre pcre-devel 
yum -y install aspell-devel bzip2-devel freetype-devel gmp-devel httpd-devel libcurl-devel libjpeg-devel libicu-devel libpng-devel libtidy-devel libvpx-devel libxml2-devel libXpm-devel libxslt-devel openssl-devel readline-devel t1lib-devel
yum -y install gcc-c++ apr-devel libxml2-devel zlib zlib-devel mysql-devel openssl-devel
sed -i "s/^\exclude.*$/exclude=/g" /etc/yum.conf
VERSION=5.5.8 # set version
cd /usr/local/src
wget http://www.php.net/distributions/php-$VERSION.tar.gz
tar zxvf php-$VERSION.tar.gz
/bin/rm -f config.cache
yum install -y pam-devel libc-client libc-client-devel
wget ftp://ftp.cac.washington.edu/imap/imap-2007f.tar.gz
tar -zxvf imap-2007f.tar.gz
cd imap-2007f
make lr5 EXTRACFLAGS=-fPIC PASSWDTYPE=std SSLTYPE=unix.nopwd IP6=4
echo "set disable-plaintext nil" > /etc/c-client.cf
mkdir /usr/local/imap-2007f
mkdir /usr/local/imap-2007f/include/
mkdir /usr/local/imap-2007f/lib/
chmod -R 077 /usr/local/imap-2007f
/bin/rm -rf /usr/local/imap-2007f/include/*
/bin/rm -rf /usr/local/imap-2007f/lib/*
/bin/cp -rf imapd/imapd /usr/sbin/
/bin/cp -rf c-client/*.h /usr/local/imap-2007f/include/
/bin/cp -rf c-client/*.c /usr/local/imap-2007f/lib/
/bin/cp -rf c-client/c-client.a /usr/local/imap-2007f/lib/libc-client.a
/bin/rm -f config.cache
cd /usr/local/src/php-$VERSION
make clean
/bin/rm -f configure
./buildconf --force
./configure --program-prefix= --prefix=/usr  --with-config-file-path=/etc --enable-pthreads --enable-maintainer-zts --enable-cli --with-mysql=mysqlnd --with-mysqli --with-pdo-mysql --exec-prefix=/usr --bindir=/usr/bin --sbindir=/usr/sbin --sysconfdir=/etc --datadir=/usr/share --includedir=/usr/include --libdir=/usr/lib --libexecdir=/usr/libexec --localstatedir=/var --sharedstatedir=/var/lib --mandir=/usr/share/man --infodir=/usr/share/info --cache-file=../config.cache --with-libdir=lib --with-config-file-path=/etc --with-config-file-scan-dir=/etc/php.d --with-pic --with-pear --with-bz2 --with-freetype-dir=/usr --with-png-dir=/usr --with-xpm-dir=/usr --enable-gd-native-ttf --with-gettext --with-gmp --with-iconv --with-jpeg-dir=/usr --with-openssl --with-zlib --with-layout=GNU --enable-exif --enable-ftp --enable-sockets --enable-sysvsem --enable-sysvshm --enable-sysvmsg --with-kerberos --enable-shmop --enable-calendar --with-libxml-dir=/usr --enable-xml --with-apxs2=/usr/sbin/apxs --enable-dom --enable-json --with-pspell --with-curl --enable-mbstring --with-pcre-regex --enable-pcntl --with-imap-ssl=/usr/local/imap-2007f --with-imap=shared,/usr/local/imap-2007f
make && make install
#php -i | grep exten
#extension_dir => /usr/local/lib/php/extensions/no-debug-non-zts-20121212 => /usr/local/lib/php/extensions/no-debug-non-zts-20121212
#sqlite3.extension_dir => no value => no value
#ls -lah /usr/local/lib/php/extensions/no-debug-non-zts-20121212
#find / -name mysql.so
#ls -1 
#cp /usr/lib64/php/modules/* /usr/local/lib/php/extensions/no-debug-non-zts-20121212/
# php -i | grep config
# Configure Command =>  './configure'  '--with-imap=/usr/local/imap-2007f' '--with-imap-ssl'

echo "Installed PHP pthreads, PHPmySQL, IMAP..."

# Install pthreads
cd /usr/local/src/php-$VERSION
/bin/cp -f /etc/php.ini /etc/php.ini.orig
/bin/cp -f php.ini-development /etc/php.ini
pecl install pthreads
echo "extension=pthreads.so" >> /etc/php.ini
php -m | grep pthreads
/bin/rm -f /usr/local/src/php-$VERSION.tar.gz
echo "Installed pthreads..."
	fi

	echo "Updating misc IEM related Apache settings..."
	sed -i 's/max_execution_time = 30/max_execution_time = 6000/g' /etc/php.ini	
	sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 1000M/g' /etc/php.ini
	sed -i'.bak' 's/;date.timezone =/date.timezone = Europe\/London/' /etc/php.ini
 
	# Prevent error "Could not reliably determine the server’s FQDN"
	echo "ServerName host1.$DOMAIN" >> /etc/httpd/conf.d/servername.conf
	chkconfig httpd on
	service httpd start
else
	echo "Apache already installed and configured"
fi

#
# Install Squid
#
if [ $SQUID == "Y" ]; then
    yum -y install squid
    chkconfig squid on
	sed -i 's/http_access deny all/# User Authentication\nhttp_access deny badkey\nauth_param basic program \/usr\/lib64\/squid\/ncsa_auth \/etc\/squid\/passwd\nauth_param basic children 5\nauth_param basic realm Squid proxy-caching web server\nauth_param basic credentialsttl 24 hours\nauth_param basic casesensitive off\nacl ncsa_users proxy_auth REQUIRED\nhttp_access allow ncsa_users\nhttp_access deny all\ncache_mem 32 MB\n/g' /etc/squid/squid.conf
    sed -i 's/#cache_dir /cache_dir /g' /etc/squid/squid.conf
    sed -i 's/acl CONNECT method CONNECT/acl CONNECT method CONNECT\nacl badkey url_regex "\/etc\/squid\/badkey"/g' /etc/squid/squid.conf
	touch /etc/squid/passwd
	chmod o+r /etc/squid/passwd
	chown squid.squiduser /etc/squid
	htpasswd -b /etc/squid/passwd root $MYSQL_PASS
	echo "editConfig" > /etc/squid/badkey
    echo "via off
forwarded_for off

request_header_access Allow allow all 
request_header_access Authorization allow all 
request_header_access WWW-Authenticate allow all 
request_header_access Proxy-Authorization allow all 
request_header_access Proxy-Authenticate allow all 
request_header_access Cache-Control allow all 
request_header_access Content-Encoding allow all 
request_header_access Content-Length allow all 
request_header_access Content-Type allow all 
request_header_access Date allow all 
request_header_access Expires allow all 
request_header_access Host allow all 
request_header_access If-Modified-Since allow all 
request_header_access Last-Modified allow all 
request_header_access Location allow all 
request_header_access Pragma allow all 
request_header_access Accept allow all 
request_header_access Accept-Charset allow all 
request_header_access Accept-Encoding allow all 
request_header_access Accept-Language allow all 
request_header_access Content-Language allow all 
request_header_access Mime-Version allow all 
request_header_access Retry-After allow all 
request_header_access Title allow all 
request_header_access Connection allow all 
request_header_access Proxy-Connection allow all 
request_header_access User-Agent allow all 
request_header_access Cookie allow all 
request_header_access All deny all " >>  /etc/squid/squid.conf
fi
#
# Install Git
#
if [ $GIT == "Y" ]; then
	if [ ! -f /root/.ssh/id_rsa ]; then
		echo "Installing GIT"
		cd /tmp
		yum -y install gettext-devel openssl-devel perl-CPAN perl-devel zlib-devel
		wget https://github.com/git/git/archive/v2.4.0.zip
		unzip v2.4.0.zip
		/bin/rm -f v2.4.0.zip
		cd git-*
		make configure
		./configure --prefix=/usr/local
		make install
		git --version
		git config --global user.name "Delstone"
		git config --global user.email "info@delstoneservices.co.uk"
		git config --list
		/bin/rm -rfd /tmp/git-*
	#	ssh -v
		cd /root/.ssh
		ssh-keygen -t rsa -N "" -f id_rsa
		echo "Host bitbucket.org
 IdentityFile ~/.ssh/id_rsa" >> ~/.ssh/config
		echo "SSH_ENV=$HOME/.ssh/environment   
# start the ssh-agent
function start_agent {
    echo \"Initializing new SSH agent...\"
    # spawn ssh-agent
    /usr/bin/ssh-agent | sed 's/^echo/#echo/' > \$\{SSH_ENV\}
    echo succeeded
    chmod 600 \$\{SSH_ENV\}
    . \$\{SSH_ENV\} > /dev/null
    /usr/bin/ssh-add
}
   
if [ -f \$\{SSH_ENV\} ]; then
     . \$\{SSH_ENV\} > /dev/null
     ps -ef | grep \$\{SSH_AGENT_PID\} | grep ssh-agent$ > /dev/null || {
        start_agent;
    }
else
    start_agent;
fi" >> ~/.bashrc

		source ~/.bashrc
		ssh-add -l
		cat ~/.ssh/id_rsa.pub
	fi
	#
	#	Choose avatar > Manage Account from the menu bar. Click SSH keys. Add key then test it works with:
	#	ssh -T git@bitbucket.org
	#
	#	Clone the repository with:
	#	git clone git@bitbucket.org:delstone123/interspire.git .
	#
	#	If you are integrating with Bitbucket and looking for an easy way to add the hook for your users, there are two methods you can use to automate this.  You can send the user to a URL structured in the following way:
	#	https://bitbucket.org/{username}/{repo_slug}/admin/hooks?service=POST&url={your custom url}
	#
	echo "Installed GIT"
fi


#
# Install Puppet
#
if [ $PUPPET == "Y" ]; then
	rpm -ivh http://yum.puppetlabs.com/puppetlabs-release-el-6.noarch.rpm
	yes | yum -y install puppet
	facter | grep hostname
	facter | grep fqdn
	mkdir /etc/puppet/manifests
	echo "Puppet Version "$( puppet --version )" installed"
fi


#
# Install Zabbix
#
case $ZABBIX in
  1) echo "Installing Zabbix server";
	 rpm -Uvh http://repo.zabbix.com/zabbix/2.2/rhel/6/x86_64/zabbix-release-2.2-1.el6.noarch.rpm
	 yum -y install zabbix-server-mysql zabbix-web-mysql zabbix-agent zabbix-java-gateway 
	 echo "php_value date.timezone GMT+0" > /etc/httpd/conf.d/zabbix.conf
	 service httpd restart
	 mysql -uroot -p$MYSQL_PASS -e "CREATE DATABASE zabbix CHARACTER SET UTF8;"
	 mysql -uroot -p$MYSQL_PASS -e "GRANT ALL PRIVILEGES on zabbix.* to 'zabbix'@'localhost' IDENTIFIED BY 'SECRET_PASSWORD';"
	 mysql -uroot -p$MYSQL_PASS -e "FLUSH PRIVILEGES;"
	 mysql -uroot -p$MYSQL_PASS -e "quit";
	 mysql -u zabbix -p zabbix < /usr/share/doc/zabbix-server-mysql-*/create/schema.sql
	 mysql -u zabbix -p zabbix < /usr/share/doc/zabbix-server-mysql-*/create/images.sql
	 mysql -u zabbix -p zabbix < /usr/share/doc/zabbix-server-mysql-*/create/data.sql
	 service zabbix-server start
	 echo "Installation of zabbix server completed"
	 echo "Zabbix is accessible @ http://$IPADDR_START/zabbix"
	 echo "username : admin"
	 echo "password : zabbix"
     break;;
  2) echo "Installing Zabbix Agent";
     rpm -Uvh http://repo.zabbix.com/zabbix/2.2/rhel/6/x86_64/zabbix-release-2.2-1.el6.noarch.rpm
	 yum -y install zabbix zabbix-agent
	 echo "#Server=[zabbix server ip]
#Hostname=[ Hostname of client system ]
Server=38.130.209.54
Hostname=$DOMAIN" > /etc/zabbix/zabbix_agentd.conf
	 service zabbix-agent restart
     break;;
  3) echo "Installing Zabbix Server and Agent";
     rpm -Uvh http://repo.zabbix.com/zabbix/2.2/rhel/6/x86_64/zabbix-release-2.2-1.el6.noarch.rpm
	 yum -y install zabbix-server-mysql zabbix-web-mysql zabbix-agent zabbix-java-gateway 
	 echo "php_value date.timezone GMT+0" > /etc/httpd/conf.d/zabbix.conf
	 service httpd restart
	 mysql -uroot -p$MYSQL_PASS -e "CREATE DATABASE zabbix CHARACTER SET UTF8;"
	 mysql -uroot -p$MYSQL_PASS -e "GRANT ALL PRIVILEGES on zabbix.* to 'zabbix'@'localhost' IDENTIFIED BY 'SECRET_PASSWORD';"
	 mysql -uroot -p$MYSQL_PASS -e "FLUSH PRIVILEGES;"
	 mysql -uroot -p$MYSQL_PASS -e "quit";
	 mysql -u zabbix -p zabbix < /usr/share/doc/zabbix-server-mysql-*/create/schema.sql
	 mysql -u zabbix -p zabbix < /usr/share/doc/zabbix-server-mysql-*/create/images.sql
	 mysql -u zabbix -p zabbix < /usr/share/doc/zabbix-server-mysql-*/create/data.sql
	 service zabbix-server start
	 echo "installation of zabbix server completed"
	 echo "Zabbix is accessible @ http://$IPADDR_START/zabbix"
	 echo "username : admin"
	 echo "password : zabbix"
	 yum -y install zabbix zabbix-agent
	 echo "#Server=[zabbix server ip]
	 #Hostname=[ Hostname of client system ]
	 Server=38.130.209.54
	 Hostname=$DOMAIN" > /etc/zabbix/zabbix_agentd.conf
	 service zabbix-agent restart
     break;;
  4) echo "Exiting. No action has been taken.";
	 break;;
  *) echo "$opt is an invaild option. Please select option between 1-4 only";
     echo "Press [enter] key to continue. . .";
     read enterKey;;
esac

#
# Install Jenkins Continuous Integration
#
if [ $JENKINS == "Y" ]; then
	echo "Installing Jenkins ..."
	wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u45-b14/jdk-8u45-linux-x64.tar.gz"
	tar xzf jdk-8u45-linux-x64.tar.gz
	alternatives --install /usr/bin/java java /opt/jdk1.8.0_45/bin/java 2
	alternatives --config java
	alternatives --install /usr/bin/jar jar /opt/jdk1.8.0_45/bin/jar 2
	alternatives --install /usr/bin/javac javac /opt/jdk1.8.0_45/bin/javac 2
	alternatives --set jar /opt/jdk1.8.0_45/bin/jar
	alternatives --set javac /opt/jdk1.8.0_45/bin/javac 
	export JAVA_HOME=/opt/jdk1.8.0_45
	export PATH=$PATH:/opt/jdk1.8.0_45/bin:/opt/jdk1.8.0_45/jre/bin
	export JRE_HOME=/opt/jdk1.8.0_45/jre
	echo "export JAVA_HOME=/opt/jdk1.8.0_45
	export PATH=$PATH:/opt/jdk1.8.0_45/bin:/opt/jdk1.8.0_45/jre/bin
	export JRE_HOME=/opt/jdk1.8.0_45/jre" >>  /etc/environment 
	java -version
	wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat/jenkins.repo
	rpm --import http://pkg.jenkins-ci.org/redhat/jenkins-ci.org.key
	yum -y install jenkins
	chkconfig jenkins on
	service jenkins start
	netstat -tnlp | grep 8080
	echo "Installed Jenkins"
fi

#
# Install PHPList
#
if [ $PHPLIST == "Y" ]; then
	echo "Installing PHPList..."
	wget http://downloads.sourceforge.net/project/phplist/phplist/2.10.10/phplist-2.10.10.tgz?use_mirror=voxel
	mv php* phplist-2.10.10.tgz
	tar -xvzf phplist-2.10.10.tgz
	echo "Installed PHPList"
fi

#
# Install Awstat
#
if [ $AWSTATS == "Y" ]; then
	echo "Installing Awstat"
	rpm -Uvh http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
	yum -y install awstats
	service httpd restart
	echo "Installed AWStat"
fi

#
# Configure firewall
#
if [ -f /etc/ipsetrulesbackup ]; then
        echo "IPSet rules already set"
else
	echo "Installing Firewall"
	if [ -f /etc/sysconfig/iptables ]; then
		cp /etc/sysconfig/iptables /etc/sysconfig/iptables.orig
	fi
	echo "*filter
:INPUT ACCEPT [5:9090]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [3:372]
-A INPUT -m set --match-set blacklist src -j DROP -m comment --comment \"IPSET drop ips on blacklist\"
-A INPUT -p tcp --dport 8080 -j SET --add-set blacklist src
-A INPUT -s 192.168.0.0/24   -j LOG
-A INPUT -i ${PREFIX} -p tcp --dport 80 -m state --state NEW -m limit --limit 30/minute --limit-burst 200 -j ACCEPT -m comment --comment \"Protection DDoS attacks\"
-A INPUT -p tcp --tcp-flags ALL NONE -j DROP             	 -m comment --comment \"Deny all null packets\"
-A INPUT -p tcp --tcp-flags ALL ALL -j DROP             	 -m comment --comment \"Deny all recon packets\"
-A INPUT -p tcp --tcp-flags ALL FIN -j DROP            		 -m comment --comment \"nmap FIN stealth scan\"
-A INPUT -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP       	 -m comment --comment \"SYN + FIN\"
-A INPUT -p tcp --tcp-flags SYN,RST SYN,RST -j DROP      	 -m comment --comment \"SYN + RST\"
-A INPUT -p tcp --tcp-flags FIN,RST FIN,RST -j DROP     	 -m comment --comment \"FIN + RST\"
-A INPUT -p tcp --tcp-flags ALL FIN,URG,PSH -j DROP    		 -m comment --comment \"FIN + URG + PSH\"
-A INPUT -p tcp --tcp-flags ALL URG,ACK,PSH,RST,SYN,FIN -j DROP -m comment --comment \"XMAS\"
-A INPUT -p tcp --tcp-flags ACK,FIN FIN -j DROP       		 -m comment --comment \"FIN without ACK\"
-A INPUT -p tcp --tcp-flags ACK,PSH PSH -j DROP      		 -m comment --comment \"PSH without ACK\"
-A INPUT -p tcp --tcp-flags ACK,URG URG -j DROP     		 -m comment --comment \"URG without ACK\"
-A INPUT -p tcp ! --syn -m state --state NEW -j DROP       	 -m comment --comment \"Deny SYN flood attack\"
-A INPUT -m state --state ESTABLISHED -m limit --limit 50/second --limit-burst 50 -j ACCEPT -m comment --comment \"Accept traffic with ESTABLISHED flag set (limit - DDoS prevent)\"
-A INPUT -m state --state RELATED -m limit --limit 50/second --limit-burst 50 -j ACCEPT   -m comment --comment \"Accept traffic with RELATED flag set (limit - DDoS prevent)\"
-A INPUT -m state --state INVALID -j DROP       			 -m comment --comment \"Deny traffic with the INVALID flag set\"

-A INPUT -i lo -j ACCEPT
-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
-A INPUT -p udp -m udp --dport 53 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 10050 -j ACCEPT 
-A INPUT -p tcp -m tcp --dport 10051 -j ACCEPT 
-A OUTPUT -p tcp -m tcp --dport 10051 -j ACCEPT 
-A OUTPUT -p tcp -m tcp --dport 10050 -j ACCEPT
-A INPUT -m recent --update --name SSH --seconds 60 --hitcount 5 --rttl -j DROP 
-A INPUT -m state --state NEW -m tcp -p tcp --dport 21   -j ACCEPT -m comment --comment  \" ftp\"
-A INPUT -m state --state NEW -m tcp -p tcp --dport 22   -j ACCEPT -m comment --comment  \" ssh port\"
-A INPUT -m state --state NEW -m tcp -p tcp --dport 25   -j ACCEPT -m comment --comment  \" email\"
-A INPUT -m state --state NEW -m tcp -p tcp --dport 53   -j ACCEPT -m comment --comment  \" DNS large queries\"
-A INPUT -m state --state NEW -m udp -p udp --dport 53   -j ACCEPT -m comment --comment  \" DNS small queries\"
-A INPUT -m state --state NEW -m tcp -p tcp --dport 80   -j ACCEPT -m comment --comment  \" Apache\"
-A INPUT -m state --state NEW -m tcp -p tcp --dport 110  -j ACCEPT -m comment --comment  \" POP3\"
-A INPUT -m state --state NEW -m tcp -p tcp --dport 443  -j ACCEPT -m comment --comment  \" Apache ssl\"
-A INPUT -m state --state NEW -m tcp -p tcp --dport 953  -j ACCEPT -m comment --comment  \" DNS Internal\"
-A INPUT -m state --state NEW -m tcp -p tcp --dport 993  -j ACCEPT -m comment --comment  \" imaps\"
-A INPUT -m state --state NEW -m tcp -p tcp --dport 995  -j ACCEPT -m comment --comment  \" POP\"
-A INPUT -m state --state NEW -m tcp -p tcp --dport 3128 -j ACCEPT -m comment --comment  \" Squid\"
-A INPUT -m state --state NEW -m tcp -p tcp --dport 3306 -j ACCEPT -m comment --comment  \" MySQL\"
-A INPUT -m state --state NEW -m tcp -p tcp --dport 8080 -j ACCEPT -m comment --comment  \" Jenkins\"
-A INPUT -m state --state NEW -m tcp -p tcp --dport 9090 -j ACCEPT -m comment --comment  \" Pmta\"

-A INPUT -j REJECT -m comment --comment \"Close up firewall. All else blocked.\"

COMMIT" > /etc/sysconfig/iptables
#-A INPUT -i ${PREFIX} -p tcp --dport 22 -m state --state NEW -m recent --set --name SSH 

	# IPSet Block IPs at firewall
#	echo "create blacklist hash:ip family inet hashsize 4096 maxelem 65536
#	add blacklist 75.58.232.118" > /etc/ipsetrulesbackup
#	ipset restore < /etc/ipsetrulesbackup
#	echo "ipset save > /etc/ipsetrulesbackup
#	echo \"Completed backup of IP rules\"" > /etc/cron.daily/ipsetrules
#	chmod a+x /etc/cron.daily/ipsetrules
	/backups/ServerScripts/BAMBanIPs.sh
	ipset list

	echo "Installed Firewall"

fi

if [ ! -f /etc/selinux/config.orig]; then
	cp /etc/selinux/config /etc/selinux/config.orig
	echo "# This file controls the state of SELinux on the system.
# SELINUX= can take one of these three values:
# enforcing - SELinux security policy is enforced.
# permissive - SELinux prints warnings instead of enforcing.
# disabled - No SELinux policy is loaded.

SELINUX=permissive

# SELINUXTYPE= can take one of these two values:
# targeted - Targeted processes are protected,
# mls - Multi Level Security protection.

SELINUXTYPE=targeted" > /etc/selinux/config
	echo "/etc/selinux/config updated"
fi
#
# Apache file 
#
Checkvalue=$(grep "$DOMAIN" /etc/httpd/conf/httpd.conf | wc -l)
if [ $Checkvalue -eq 0 ]; then
	echo "${DOMAIN} not found in apache config files - updating these files now..."
	echo "#
# This configuration file enables the default \"Welcome\"
# page if there is no default index page present for the root URL. 
# To disable the Welcome page, comment out all the lines below.
#

#<LocationMatch \"^/+$\">
# Options -Indexes
# ErrorDocument 403 /error/noindex.html
#</LocationMatch> " > /etc/httpd/conf.d/welcome.conf

	# ADD SED FOR LISTEN 80 -> LISTEN xx.xx.xx.xx:80
	sed "s/Listen 80/Listen ${IPADDR_START}:80/g" -i /etc/httpd/conf/httpd.conf
	sed "s/#ServerName.*/ServerName host1.${DOMAIN}/g" -i /etc/httpd/conf/httpd.conf
	sed 's/^DocumentRoot.*/DocumentRoot "\/var\/www"/g' -i /etc/httpd/conf/httpd.conf
	echo "NameVirtualHost *:80
#
# APPENDED FROM HERE:
#
# VirtualHost example:
# Almost any Apache directive may go into a VirtualHost container.
# The first VirtualHost section is used for requests without a known
# server name.
#

<VirtualHost ${IPADDR_START}:80>
DocumentRoot /var/www/
ServerName host1.{$DOMAIN}
</VirtualHost>

<VirtualHost *:80>
DocumentRoot /var/www
ServerName host1.${DOMAIN}
</VirtualHost>

LimitRequestBody 0" >> /etc/httpd/conf/httpd.conf

	service httpd restart
	echo "Completed apache installation"
fi

grep -i "error" /var/log/messages


# Restore email database for IEM
#mysql -uroot -p$MYSQL_PASS andersen_database < /backups/*.sql

#
# Configure IEM
#
if [ ! -d "/var/www/admin" ]; then
	echo "Installing IEM"
	cd /var/www
    unzip /backups/BAM_IEM020615.zip
    chmod +x interspiresetup*
#    /bin/rm admin/com/storage/template-cache/* -f
#	echo "User-agent: *
#Disallow: /" > /var/www/robots.txt
#	chmod +r /var/www/robots.txt

    APACHE_USER=$(ps -ef | grep httpd | grep -v `whoami` | grep -v root | head -n1 | awk '{print $1}')
    sed -i "s/admin.admin/$APACHE_USER.$APACHE_USER/g" interspiresetup
    ./interspiresetup
	sed -i "s/brandonandmile.com/${DOMAIN}/g" /var/www/admin/includes/config.php
		
	echo "<?php
echo 'Processing...';

class Deploy {

    /**
     * A callback function to call after the deploy has finished.
     * 
     * @var callback
    */
    public $post_deploy;

    /**
     * The name of the file that will be used for logging deployments. Set to 
     * FALSE to disable logging.
     * 
     * @var string
     */
    private $_log = '/tmp/deployments.log';

    /**
     * The timestamp format used for logging.
     * 
     * @link    http://www.php.net/manual/en/function.date.php
     * @var     string
     */
    private $_date_format = 'Y-m-d H:i:sP';

    /**
     * The name of the branch to pull from.
     * 
     * @var string
     */
    private $_branch = 'master';

    /**
     * The name of the remote to pull from.
     * 
     * @var string
     */
    private $_remote = 'origin';

    /**
     * The directory where your website and git repository are located, can be 
     * a relative or absolute path
     * 
     * @var string
     */
    private $_directory='/var/www';

    /**
     * Sets up defaults.
     * 
     * @param  string  $directory  Directory where your website is located
     * @param  array   $data       Information about the deployment
     */
    public function __construct($directory, $options = array())
    {
        // Determine the directory path
        $this->_directory = realpath($directory).DIRECTORY_SEPARATOR;

        $available_options = array('log', 'date_format', 'branch', 'remote');

        foreach ($options as $option => $value)
        {
            if (in_array($option, $available_options))
            {
                $this->{'_'.$option} = $value;
            }
        }

        $this->log('Attempting deployment...');
    }

    /**
     * Writes a message to the log file.
     * 
     * @param  string  $message  The message to write
     * @param  string  $type     The type of log message (e.g. INFO, DEBUG, ERROR, etc.)
     */
    public function log($message, $type = 'INFO')
    {
        if ($this->_log)
        {
            // Set the name of the log file
            $filename = $this->_log;

            if ( ! file_exists($filename))
            {
                // Create the log file
                file_put_contents($filename, '');

                // Allow anyone to write to log files
                chmod($filename, 0666);
            }

            // Write the message into the log file
            // Format: time --- type: message
            file_put_contents($filename, date($this->_date_format).' --- '.$type.': '.$message.PHP_EOL, FILE_APPEND);
        }
    }

    /**
     * Executes the necessary commands to deploy the website.
     */
    public function execute()
    {
        try
        {
            // Make sure we're in the right directory
            exec('cd '.$this->_directory, $output);
//	    chdir($this->_directory);
            $this->log('Changing working directory... '.$this->_directory.'-'.implode(' ', $output));

            // Discard any changes to tracked files since our last deploy
            exec('sudo /usr/local/bin/git reset --hard HEAD', $output);
            $this->log('Resetting repository... '.implode(' ', $output));

            // Update the local repository
            exec('sudo /usr/local/bin/git pull '.$this->_remote.' '.$this->_branch, $output);
            $this->log('Pulling in changes... '.implode(' ', $output));

            // Secure the .git directory
            exec('sudo chmod -R og-rx .git', $output);
            $this->log('Securing .git directory... '.implode(' ', $output));

//            if (is_callable($this->post_deploy)) {
//                call_user_func($this->post_deploy, $this->_data);
//            }

            $this->log('Deployment successful.');
        }
        catch (Exception $e) {
            $this->log($e, 'ERROR');
        }
    }

}

// This is just an example
$deploy = new Deploy('/var/www');

$deploy->post_deploy = function() use ($deploy) {
// hit the wp-admin page to update any db changes
//    exec('curl http://www.foobar.com/wp-admin/upgrade.php?step=upgrade_db');
    $deploy->log('Updating wordpress database... ');

};

$deploy->execute();

?> " > /var/www/deploy.php

    # Set up crontab jobs 
    echo "
# run-parts
01 * * * * root run-parts /etc/cron.hourly
02 2 * * * root run-parts /etc/cron.daily
22 2 * * 0 root run-parts /etc/cron.weekly
42 2 1 * * root run-parts /etc/cron.monthly

# Update OS packages monthly - 12am monthly
0 0 1 * * yum clean all

# Rotate Logs - 11.00pm daily
00 23 * * * /usr/sbin/logrotate /etc/logrotate.conf

# IEM IP reputation updates - 12.00am daily
0 0 * * * /usr/bin/php /var/www/admin/addons/mta/api/cli.php --check-ipguard
0 0 * * * /usr/bin/php /var/www/admin/addons/mta/api/cli.php --check-ipguard --type=blacklist
0 0 * * * /usr/bin/php /var/www/admin/addons/mta/api/cli.php --check-ipguard --type=whitelist

# Run Interspire scheduler every minute
* * * * * /usr/bin/php -f /var/www/admin/cron/cron.php

@reboot /usr/sbin/ipset restore < /etc/ipsetrulesbackup
		" > /tmp/crontab
		yum -y install cronie php php-mysql httpd
		service httpd restart
		service mysqld restart
        crontab /tmp/crontab
        /bin/rm -f /tmp/crontab
        chmod 777 /tmp
		/usr/bin/php /var/www/admin/addons/mta/api/cli.php --populate-ipguard &
		echo "Completed IEM installation"
fi

#
# Configure PMTA
#
if [ ! -d "/etc/pmta" ]; then
        # Configure user processes for PMTA
        Checkvalue=$(grep 'soft nproc 100000' /etc/security/limits.conf | wc -l)
        if [ $Checkvalue -eq 0 ]; then
            echo "* soft nproc 90000
* hard nproc 90000
* soft nofile 90000
* hard nofile 90000" >> /etc/security/limits.conf
            echo "fs.file-max = 100000" >> /etc/sysctl.conf
        fi

        cd /backups
        unzip BAM_PMTA*.zip
        cd PMTAv4.0r6/script/powermta/
        rpm -ivh PowerMTAi586.rpm
        cp -rf dkim.keys /etc/pmta/mail."$domainname".pem;
        cp -rf license /etc/pmta/
        cp -rf pmtad /usr/sbin/
        chmod +x /usr/sbin/pmtad
		mkdir /var/spool/pmtaPickup
		mkdir /var/spool/pmtaPickup/Pickup
		mkdir /var/spool/pmtaPickup/BadMail
fi


# Set up the PMTA config file
cd /etc/pmta/
echo "#BOF SERVER $DOMAIN

postmaster delstoneservices@gmail.com

smtp-listener $IPADDR_START/28:25
smtp-listener 127.0.0.1:25

Pickup /var/spool/pmtaPickup/Pickup /var/spool/pmtaPickup/BadMail

# Must precede source directives
<virtual-mta-pool pool1>" > /etc/pmta/config
i=0
for smt in "${smtphosts_arr[@]}"; do
	echo "virtual-mta mta${i}" >> /etc/pmta/config
	i=$(($i+1))
done
echo "</virtual-mta-pool>" >> /etc/pmta/config
i=0
for smt in "${smtphosts_arr[@]}"; do
	echo "<virtual-mta mta${i}>
${smt}
</virtual-mta>" >> /etc/pmta/config
	i=$(($i+1))
done
echo "<pattern-list vmta-by-domain>" >> /etc/pmta/config
	for smt in "${smtppatterns_array[@]}"; do
	echo "${smt}" >> /etc/pmta/config
done
echo "</pattern-list>

<source 127.0.0.1>
smtp-service yes
always-allow-relaying yes
</source>

<source $IPADDR_START/$CIDR_NETMASK>
smtp-service yes
always-allow-relaying yes # whichever incoming ip allow it to relay
</source>

<source 0/0>
always-allow-relaying no
allow-mailmerge no
process-x-virtual-mta yes
max-message-size unlimited
smtp-service yes
remove-received-headers true
add-received-header false
process-x-job yes
hide-message-source yes
log-connections yes
log-commands yes
log-data no
allow-unencrypted-plain-auth yes
pattern-list vmta-by-domain # select mta according to \"From\" domain in header of incoming message
default-virtual-mta pool1 # otherwise default round robin on all ips in this range
</source>

relay-domain [*.]$DOMAIN
<domain [*.]$DOMAIN>
route [127.0.0.1]:2526
</domain>
sync-msg-create false
sync-msg-update false
run-as-root yes

#spool /var/spool/pmta
<spool /var/spool/pmta>
delete-file-holders yes
</spool>
# EOF
" >> /etc/pmta/config

# Prevent ports conflicting if exim tries grabbing port 25 akin to pmta
sed -i 's/daemon_smtp_ports = 25 /daemon_smtp_ports = 2526 /g' /etc/exim/exim.conf
service exim restart
service httpd restart
service pmta restart
service pmtahttp restart

#
# Some security settings
#

# disable ipv6 etc
Checkvalue=$(grep 'net.ipv6.conf.all.disable_ipv6 = 1' /etc/sysctl.conf | wc -l)
if [ $Checkvalue -eq 0 ]; then
	sed -i 's/net.bridge.bridge-nf-call-/#net.bridge.bridge-nf-call-/g' /etc/sysctl.conf
	echo "net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
# Turn on execshield
kernel.exec-shield=1
kernel.randomize_va_space=1
# Enable IP spoofing protection
net.ipv4.conf.all.rp_filter=1
# Disable IP source routing
net.ipv4.conf.all.accept_source_route=0
# Ignoring broadcasts request
#net.ipv4.icmp_echo_ignore_broadcasts=1
#net.ipv4.icmp_echo_ignore_all = 1

# Make sure spoofed packets get logged
net.ipv4.conf.all.log_martians = 0" 	>> /etc/sysctl.conf
	sysctl -p
fi


#
# SFTP Settings
#
Checkvalue=$(grep 'BrandonAndMile' /etc/vsftpd/vsftpd.conf | wc -l)
if [ $Checkvalue -eq 0 ]; then
	# Do not allow anonymous ftp
	sed -i 's/#anonymous_enable=NO/anonymous_enable=NO/g' /etc/vsftpd/vsftpd.conf
	sed -i 's/anonymous_enable=YES/anonymous_enable=NO/g' /etc/vsftpd/vsftpd.conf
	# Allow local users to login
	sed -i 's/local_enable=NO/local_enable=YES/g' /etc/vsftpd/vsftpd.conf
	# Login banner
	sed -i 's/Welcome to blah FTP service./Welcome to BrandonAndMile FTP service./g' /etc/vsftpd/vsftpd.conf
	# ASCII mangling is a horrible feature of the protocol.
	sed -i 's/# ASCII mangling is a horrible feature of the protocol./# ASCII mangling is a horrible feature of the protocol.\nascii_upload_enable=YES\nascii_download_enable=YES/g' /etc/vsftpd/vsftpd.conf
	# Allow users into their home directory
	if [ -f /selinux/enforce ]; then
		ENABLED=$( cat /selinux/enforce )
		if [ "$ENABLED" == 1 ]; then
			setsebool -P ftp_home_dir on
		fi
	fi
	
	# Restart sftp service
	service vsftpd restart
	chkconfig vsftpd on
fi


#
# Tidy up and reboot
#

# Tidy up IEM/PMTA files
/bin/rm -rfd /backups/In*
/bin/rm -rfd /backups/PM*

# Update intrusion alert system
aide --update
mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz

# Turn firewall back on
service iptables restart
IPTABLES_MODULES="nf_conntrack_ftp"
service squid start

#After reboot install net-tools and add other tasks that need to occur
	echo " yum -y install net-tools
sed -i '/runonreboot/d' /etc/crontab " > /tmp/runonreboot

echo "That's it... now do a server reboot..."
echo "Anything not working at the moment should work after the reboot"
#reboot

