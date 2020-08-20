#!/bin/bash
ssh $REMOTE_ACCOUNT@$REMOTE_IP "sed -i \"s/'password'=>'root'/'password'=>'1111111'/g\" /data/www/admin-sso/config/db.php"
ssh $REMOTE_ACCOUNT@$REMOTE_IP "sed -i \"s/'password'=>'123456'/'password'=>'22222222'/g\" /data/www/admin-sso/config/db.php"
ssh $REMOTE_ACCOUNT@$REMOTE_IP "sed -i 's/http:\/\/local/http:\/\/test/g' /data/www/admin-sso/config/params.php"
