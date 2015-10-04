#!/bin/bash

service --status-all | grep 'is running' | awk '{ print $1 }' | sort > testfile

for service in $(cat testfile)
do
   if [ $service == "auditd" ]; then
    auditd_version=$(auditctl -v | gawk '{ print $3 }')
   # echo "Version of $service is $auditd_version"
  fi
  if [ $service == "chef-client" ]; then
    chef_version=$(chef-client -v | gawk '{ print $2 }')
   # echo "version of $service is$chef_version"
  fi
  if [ $service == "php-fpm" ]; then
    php_version=$(php-fpm -v |grep -Eow '^PHP [^ ]+' |gawk '{ print $2 }')
   # echo "version of $service is $php_version"
  fi
  if [ $service == "httpd" ]; then
    apache_version=$(httpd -v | grep 'Apache' | gawk '{ print $3 }' | cut -c8-15)
    #echo "version of $service is $apache_version"
  fi
  if [ $service == "mysqld" ]; then
    mysql_version=$(mysql --version | gawk '{ print $5 }' | cut -c1-6)
    #echo "version of $service is $mysql_version"
  fi
  if [ $service == "munin-node" ]; then
    munin_version=$(munin-node -v | grep munin-node | gawk '{ print $4 }')
    #echo "version of $service is $munin_version"
  fi
  if [ $service == "nrpe" ]; then
    nrpe_version=$(/usr/local/nagios/libexec/check_nrpe | grep "Version" | awk '{ print $2 }')
    #echo "version of $service is $nrpe_version"
  fi
  if [ $service == "ntpd" ]; then
    ntpd_version=$(ntpd -! | gawk '{ print $2 }' | cut -c1-5 | tail -n +2)
    #echo "version of $service is $ntpd_version"
  fi
  if [ $service == "openssh-daemon" ]; then
    openssl_version=$(openssl version | gawk '{print $2 }' | cut -c1-5)
    #echo "version of $service is $openssl_version"
  fi
  if [ $service == "rsyslogd" ]; then
    rsyslogd_version=$(rsyslogd -v | grep rsyslogd | gawk '{ print $2 }' | cut -c1-6)
    #echo "version of $service is $rsyslogd_version"
  fi
  if [ $service == "sendmail" ]; then
    sendmail_version=$(/usr/lib/sendmail -d0.1 < /dev/null | grep Version | gawk '{ print $2 }')
    #echo "version of $service is $sendmail_version"
  fi
  if [ $service == "supervisord" ]; then
    supervisord_version=$(/usr/local/bin/supervisord -v)
   # echo "version of $service is $supervisord_version"
  fi
  if [ $service == "logstash" ]; then
    logstash_version=$(/opt/logstash/bin/logstash -V | gawk '{ print $2 }')
   # echo "$service $logstash_version"
  fi
  if [ $service == "elasticsearch" ]; then
    elastic_version=$(rpm -qa | grep elasticsearch | cut -c15-19)
   # echo "$service $elastic_version"
  fi
  if [ $service == "beanstalkd" ]; then
    beans_version=$(beanstalkd -v | cut -d' ' -f2 || rpm -qa | grep beanstalkd | cut -c12-14)
   # echo "$service $beans_version"
  fi
  if [ $service == "redis-server" ]; then
    redis_version=$(redis-cli -v | cut -d' ' -f2 || rpm -qa redis | cut -c7-12)
   # echo "$service $redis_version"
  fi
done
echo "{"\"payload\"": [
  {
    "\"id\"": "\"php"\",
    "\"version\"": "\"$php_version\""
  },
  {
    \"id\": \"httpd\",
    \"version\": \"$apache_version\"
  },
  {
     \"id\": \"mysqld\",
    \"version\": \"$mysql_version\"
  },
  {
    \"id\": \"auditd\",
    \"version\": \"$auditd_version\"
  },
  {
    \"id\": \"chef-client\",
    \"version\": \"$chef_version\"
  },
  {
    \"id\": \"munin-node\",
    \"version\": \"$munin_version\"
  },
  {
    \"id\": \"nrpe\",
    \"version\": \"$nrpe_version\"
  },
  {
    \"id\": \"ntpd\",
    \"version\": \"$ntpd_version\"
  },
  {
    \"id\": \"openssh-daemon\",
    \"version\": \"$openssl_version\"
  },
  {
    \"id\": \"rsyslogd\",
    \"version\": \"$rsyslogd_version\"
  },
  {
    \"id\": \"sendmail\",
    \"version\": \"$sendmail_version\"
  },
  {
    \"id\": \"supervisord\",
    \"version\": \"$supervisord_version\"
  },
  {
    \"id\": \"logstash\",
    \"version\": \"$logstash_version\"
  },
  {
    \"id\": \"elasticsearch\",
    \"version\": \"$elastic_version\"
  },
  {
    \"id\": \"beanstalkd\",
    \"version\": \"$beans_version\"
  },
  {
    \"id\": \"redis-server\",
    \"version\": \"$redis_version\"
  }
]}" > /opt/version-check.json
