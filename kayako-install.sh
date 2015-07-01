#!/bin/bash
#This script has been tested on CentOS Server
#Place the script in to Document root of server, where help desk needs to be installed
#Do Not modify script without permission of Author

#Author: Sahil Sehgal

#Email Address: sahil@inspiredtechies.com

echo "#################################################"
echo "Hi, This is Jarvis! I'll be helping you out with Installation. Let's proceed!"
echo "#################################################"
echo ""
read -t 2
echo "Initially we would proceed with the Prerequisites of help desk"
read -t 2
echo ""
echo "I am checking if your server contains all required PHP modules"
read -t 2
echo ""
prompt_err() {
echo -e "\E[31m[ERROR]\E[m"
}
prompt_ok() {
echo -e "\E[32m[OK]\E[m"
}
echo "Checking PHP-CURL"
php -m | grep curl
if [ "$?" -gt 0 ]; then
echo "Module PHP-CURL is not installed"
prompt_err
exit 1
else
echo "Module PHP-CURL is Installed";
prompt_ok
read -t 2
fi
echo ""
echo "Checking PHP-DOM"
php -m | grep dom
if [ "$?" -gt 0 ]; then
echo "Module PHP-DOM is not installed"
prompt_err
exit 1
else
echo "Module PHP-DOM is Installed"
prompt_ok
read -t 2
fi
echo ""
echo "Checking PHP-FILTER"
php -m | grep filter
if [ "$?" -gt 0 ]; then
echo "Module PHP-FILTER is not installed"
prompt_err
exit 1
else
echo "Module PHP-FILTER is Installed"
prompt_ok
read -t 2
fi
echo ""
echo "Checking PHP-GD"
php -m | grep gd
if [ "$?" -gt 0 ]; then
echo "Module PHP-GD is not installed"
prompt_err
exit 1
else
echo "Module PHP-GD is Installed"
prompt_ok
read -t 2
fi
echo ""
echo "Checking PHP-IMAP"
php -m | grep imap
if [ "$?" -gt 0 ]; then
echo "Module PHP-IMAP is not installed"
prompt_err
exit 1
else
echo "Module PHP-IMAP is Installed"
prompt_ok
read -t 2
fi
echo ""
echo "Checking PHP-JSON"
php -m | grep json
if [ "$?" -gt 0 ]; then
echo "Module PHP-JSON is not installed"
prompt_err
exit 1
else
echo "Module PHP-JSON is Installed"
prompt_ok
read -t 2
fi
echo ""
echo "Checking PHP-MySQL"
php -m | grep mysql
if [ "$?" -gt 0 ]; then
echo "Module PHP-MySQL is not installed"
prompt_err
exit 1
else
echo "Module PHP-MySQL is Installed"
prompt_ok
read -t 2
fi
echo ""
echo "Checking PHP-MySQLi"
php -m | grep mysqli
if [ "$?" -gt 0 ]; then
echo "Module PHP-MySQLi is not installed"
prompt_err
exit 1
else
echo "Module PHP-MySQLi is Installed"
prompt_ok
read -t 2
fi
echo ""
echo "Checking PHP-MBSTRING"
php -m | grep mbstring
if [ "$?" -gt 0 ]; then
echo "Module PHP-MBSTRING is not installed"
prompt_err
exit 1
else
echo "Module PHP-MBSTRING is Installed"
prompt_ok
read -t 2
fi
echo ""
echo "Checking PHP-MCRYPT"
php -m | grep mcrypt
if [ "$?" -gt 0 ]; then
echo "Module PHP-MCRYPT is not installed"
prompt_err
exit 1
else
echo "Module PHP-MCRYPT is Installed"
prompt_ok
read -t 2
fi
echo ""
echo "Checking PHP-PDO"
php -m | grep pdo
if [ "$?" -gt 0 ]; then
echo "Module PHP-PDO is not installed"
prompt_err
exit 1
else
echo "Module PHP-PDO is Installed"
prompt_ok
read -t 2
fi
echo ""
echo "Checking PHP-PDO_MySQL"
php -m | grep pdo_mysql
if [ "$?" -gt 0 ]; then
echo "Module PHP-PDO_MySQL is not installed"
prompt_err
exit 1
else
echo "Module PHP-PDO_MySQL is Installed"
prompt_ok
read -t 2
fi
echo ""
echo "Checking PHP-SOCKETS"
php -m | grep sockets
if [ "$?" -gt 0 ]; then
echo "Module PHP-SOCKETS is not installed"
prompt_err
exit 1
else
echo "Module PHP-SOCKETS is Installed"
prompt_ok
read -t 2
fi
echo ""
echo "Checking PHP-XML"
php -m | grep xml
if [ "$?" -gt 0 ]; then
echo "Module PHP-XML is not installed"
prompt_err
exit 1
else
echo "Module PHP-XML is Installed"
prompt_ok
read -t 2
fi
echo ""
echo "Checking PHP-ZLIB"
php -m | grep zlib
if [ "$?" -gt 0 ]; then
echo "Module PHP-ZLIB is not installed"
prompt_err
exit 1
else
echo "Module PHP-ZLIB is Installed"
prompt_ok
read -t 2
fi
echo ""
echo "Checking PHP-ZIP"
php -m | grep zip
if [ "$?" -gt 0 ]; then
echo "Module PHP-ZIP is not installed"
prompt_err
exit 1
else
echo "Module PHP-ZIP is Installed"
prompt_ok
read -t 2
fi
echo ""
echo "Great Captain!! All PHP modules are already installed"
read -t 2
echo ""
echo "So we can proceed with the Installation now"
echo ""
getbuild() {
echo "Enter the help desk build, you want to install: 'fusion', 'case', 'engage'"
read build
}
download(){
echo -n "Give download URL here > "
read URL
wget "$URL"
}
extract(){
echo ""
echo "Extracting files now ..."
read -t 2
tar -xvf $build*.tar.gz*
read -t 2
}
placefiles(){
echo ""
cp -rf $build*/upload/* ./
echo ""
echo "Moving files to the default document root from help desk folder"
read -t 3
echo ""
echo "Files have been placed inside document root now"
prompt_ok
}
permissions(){
echo ""
echo "Setting up the file structure..."
chmod -R 777 __apps __swift/files __swift/geoip __swift/cache __swift/logs
status $?
cp __swift/config/config.php.new __swift/config/config.php
read -t 2
echo "File sturcture all set !"
prompt_ok
}
echo ""
getbuild #This will ask for the Build information
download #This will prompt for the files link to download product files
extract #To extract files
placefiles #To move files in the document root
permissions #To grant appropriate permissions to required files
config() {
dhost=`cat ./__swift/config/config.php | grep DB_HOSTNAME | cut -d "'" -f 1,2,3`
chost=`cat ./__swift/config/config.php | grep DB_HOSTNAME`
sed -i "s/$chost/$dhost'$dbhost');/g" __swift/config/config.php
duser=`cat ./__swift/config/config.php | grep DB_USERNAME | cut -d "'" -f 1,2,3`
cuser=`cat ./__swift/config/config.php | grep DB_USERNAME`
sed -i "s/$cuser/$duser'$dbuser');/g" __swift/config/config.php
dname=`cat ./__swift/config/config.php | grep DB_NAME | cut -d "'" -f 1,2,3`
cname=`cat ./__swift/config/config.php | grep DB_NAME`
sed -i "s/$cname/$dname'$dbname');/g" __swift/config/config.php
}
rootconfig() {
config
dpwd=`cat ./__swift/config/config.php | grep DB_PASSWORD | cut -d "'" -f 1,2,3`
cpwd=`cat ./__swift/config/config.php | grep DB_PASSWORD`
sed -i "s/$cpwd/$dpwd'$mrpwd');/g" __swift/config/config.php
}
userconfig() {
config
dpwd=`cat ./__swift/config/config.php | grep DB_PASSWORD | cut -d "'" -f 1,2,3`
cpwd=`cat ./__swift/config/config.php | grep DB_PASSWORD`
sed -i "s/$cpwd/$dpwd'$dbpwd');/g" __swift/config/config.php
}
createdb() {
mysql -h $dbhost -u $dbuser -p$mrpwd < mysql.txt; status $?
stat=`cat mysql.txt | tail -1`
rm -rf mysql.txt
if [ "$stat" != "0" ]; then
echo 'The database detailed in the "config.php" file, is not empty.';read -t 2
echo 'WARNING: Proceeding will overwrite all the existing data in the database.';read -t 2
echo 'Do you still want to proceed ? (y/n)'
read inp
check () {
if [ "$inp" == "n" ]; then
echo 'Script execution,terminated.'
exit
elif [ "$inp" == "y" ]; then
echo 'Running the script.'
read -t 1
else
echo 'Please enter (y/n)'
read inp
check
fi
}
check
else
echo 'Database is empty, running the script.'
read -t 1
fi
}
mysqlcheck #Checks, if the database, who's details are specified in the 'config.php' is empty or not.
echo Everything Seems great!! Lets proceed with the Installation now.;read -t 2;
echo Enter the organization name:;read org;read -t 1
echo "Specify the help desk URL, It's format should be: 'http://yourdomain.com/ or http://yourdomain.com/support/'";
read url;
prod=`echo $url | cut -d "/" -f2,3`;
fprod=`echo $prod | cut -d "/" -f2`;
echo First name:;read name1;
echo Last name:;read name2;read -t 1;
echo "Username for the administrator account (case in-sensetive):";read username;read -t 1;
echo "Password for administrator account (case in-sensetive):";read password;read -t 1;
swf=`pwd`/__swift
echo Email address:;read email;
echo ""
echo Running the setup now...;
wd=`pwd`;chmod 777 __apps;cd $swf; chmod 777 apps geoip logs cache files; cd $wd/console;
php $wd/setup/console.setup.php "$org" "$fprod" "$name1" "$name2" "$username" "$password" "$email";status $?
read -t 3;cd ..;
echo Changing the product URL...;read -t 2;
echo ""
echo "Renaming 'setup' directory ..."
mv setup setup__--
read -t 2;
echo NOTE: Do not terminate.;read -t 2;
echo ""
echo Logging to the help desk MySQL database.;read -t 2;
mysql -h $dbh -u $dbu -p$dbp $dbn<<EOFMYSQL
select data from swsettings where vkey='general_producturl';
update swsettings set data='$url' where vkey='general_producturl';
select data from swsettings where vkey='general_producturl';
EOFMYSQL
status $?
echo Product URL has been changed !;read -t 2;
prompt_ok
echo Completing the installation process.;read -t 2;
prompt_ok
echo Initializing the help desk...;read -t 3;
wget -O /dev/null $url/staff/index.php?/Core/Default/RebuildCache
stat_in=`echo $?`
finalize() {
read -t 3
echo Help Desk has been installed.; read -t 2;
echo ""
echo "############################################"
echo 'Client support center:' $url; read -t 2;
echo 'Staff CP:' $url'/staff';read -t 2;
echo 'Admin CP:' $url'/admin';read -t 2;
echo "############################################"
echo ""
echo "############################################"
echo 'Admin CP access details:'; read -t 2;
echo 'Username:' $username; read -t 2; echo 'Password:' $password;read -t 2
echo "############################################"
echo ""
echo "Now the only thing you need to do is to upload the 'key.php' to the web server document root.";read -t 3;
echo Press any key to exit; read key;
}
if [ "$stat_in" == "1" ]; then
prompt_err;
echo "Help desk 'cache-rebuild' was unsuccessfull..."
echo 'Rebuild the help desk cache, once the installtion is complete:'
read -t 3
finalize
echo -e "\E[31m[NOTE]\E[m:" "Please rebuild the help desk cache:"
echo "$url/staff/index.php?/Core/Default/RebuildCache"
else
finalize
fi
