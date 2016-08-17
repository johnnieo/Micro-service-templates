#! /bin/bash

found=`sed -n '/proxy_set_header X-Request-Start "t=${msec}"/ p' /etc/nginx/conf.d/webapp.conf`

if [[ "$found" == "" ]]; then
  echo "adding X-Request-Start header to nginx config"
  sed '/\$proxy_add_x_forwarded_for/ a\    proxy_set_header X-Request-Start "t=${msec}";' /etc/nginx/conf.d/webapp.conf > /tmp/nginx_updated.config
  rm -f /etc/nginx/conf.d/webapp.conf
  mv /tmp/nginx_updated.config /etc/nginx/conf.d/webapp.conf

  service nginx restart
fi
