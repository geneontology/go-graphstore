#!/bin/bash

USE_S3="${USE_S3:=1}"

if [ $USE_S3 -ne 0 ]; then
   chown root:root /etc/logrotate.d/apache2 
   chmod 400 /etc/logrotate.d/apache2

   if [[ ! "$(service cron status)" =~ "start/running" ]]
   then
      echo " The cron service has been stopped. It has now been restarted." 
      service cron start
   else
      echo " The cron service has been restarted." 
   fi
fi

if [[ ! "$(service apache2 status)" =~ "start/running" ]]
then
    echo " The Apache service has been stopped. It has now been restarted." 
    service apache2 start
else
    echo " The Apache service has been restarted." 
fi

exec "$@"
