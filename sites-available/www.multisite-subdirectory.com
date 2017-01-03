server {
	# Ports to listen on
	listen 80;
	listen [::]:80;

	# Server name to listen for
	server_name www.multisite-subdirectory.com;

	# Path to document root
	root /sites/www.multisite-subdirectory.com/public;

	# File to be used as index
	index index.php;

	# Overrides logs defined in nginx.conf, allows per site logs.
	access_log /sites/www.multisite-subdirectory.com/logs/access.log;
	error_log /sites/www.multisite-subdirectory.com/logs/error.log;

	# Default server block rules
	include global/server/defaults.conf;

	# Multisite subdirectory install
	include global/server/multisite-subdirectory.conf;

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

# Redirect non-www to www
server {
	listen 80;
	listen [::]:80;
	server_name multisite-subdirectory.com;

	return 301 $scheme://www.multisite-subdirectory.com$request_uri;
}
