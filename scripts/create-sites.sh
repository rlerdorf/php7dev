block="server {
    listen 80;
    server_name $1;
    root \"$2\";
    index  index.php index.html index.htm;
    access_log  /var/log/nginx/default-access.log  main;
    error_log   /var/log/nginx/default-error.log;

    error_page   500 502 503 504  /50x.html;

    location = /50x.html {
        root   /var/www/default;
    }


    location / {
        try_files \$uri \$uri/ @rewrite;
    }

    location @rewrite {
        rewrite ^(.*)$ /index.php;
    }

    location ~ \.php$ {

        include                  fastcgi_params;
        fastcgi_keep_conn on;
        fastcgi_index            index.php;
        fastcgi_split_path_info  ^(.+\.php)(/.+)$;
        fastcgi_param PATH_INFO \$fastcgi_path_info;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_intercept_errors on;
        fastcgi_pass unix:/var/run/php-fpm.sock;
    }

}
"
sudo mkdir -p "/etc/nginx/sites-available" "/etc/nginx/sites-enabled"
sudo echo "$block" > "/etc/nginx/sites-available/$1"
sudo ln -fs "/etc/nginx/sites-available/$1" "/etc/nginx/sites-enabled/$1"
sudo service nginx restart
sudo service php-fpm restart