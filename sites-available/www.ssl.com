server {
	# Ports to listen on, uncomment one.
	listen 443 ssl http2;
	listen [::]:443 ssl http2;

	# Server name to listen for
	server_name www.ssl.com;

	# Path to document root
	root /sites/www.ssl.com/public;

	# Paths to certificate files.
	ssl_certificate /etc/ssl/www.ssl.com.crt;
	ssl_certificate_key /etc/ssl/www.ssl.com.key;

	# File to be used as index
	index index.php;

	# Overrides logs defined in nginx.conf, allows per site logs.
	access_log /sites/www.ssl.com/logs/access.log;
	error_log /sites/www.ssl.com/logs/error.log;

	# Default server block rules
	include global/server/defaults.conf;

	# SSL rules
	include global/server/ssl.conf;

	location / {
		try_files $uri $uri/ /index.php?$args;
	}

	location ~ \.php$ {
		try_files $uri =404;
		include global/fastcgi-params.conf;

		# Change socket if using PHP pools or PHP 5
		fastcgi_pass unix:/run/php/php7.0-fpm.sock;
		#fastcgi_pass unix:/var/run/php5-fpm.sock;
	}
}

# Redirect http to https
server {
	listen 80;
	listen [::]:80;
	server_name www.ssl.com ssl.com;

	return 301 https://www.ssl.com$request_uri;
}

# Redirect non-www to www
server {
	listen 443;
	listen [::]:443;
	server_name ssl.com;

	return 301 https://www.ssl.com$request_uri;
}
