echo "Enter the domain name of the new site: "
read HOST
echo "what is the site number: "
read SNUM
#WORDPRESS_DB=wordpres$(cat /dev/urandom | tr -dc '[:digit:]' | head -c5`)

cat >>/root/compose/.env <<EOL
#
WORDPRESS_DB_NAME$SNUM=wordpress$SNUM
WORDPRESS_DOMAINS$SNUM=$HOST
EOL

cat >>/root/compose/docker-compose.yml <<EOL
  wp$SNUM:
    image: wordpress:latest
    depends_on:
      - wp-db
    restart: always
    networks:
      - backend
      - frontend
    volumes:
       - /root/compose/www/html$SNUM:/var/www/html
     # - ./php.ini:/usr/local/etc/php/php.ini
    environment:
      WORDPRESS_DB_HOST: wp-db:3306
      WORDPRESS_DB_USER: \${WORDPRESS_DB_USER}
      WORDPRESS_DB_PASSWORD: \${WORDPRESS_DB_PASSWORD}
      WORDPRESS_DB_NAME: \${WORDPRESS_DB_NAME$SNUM}
    labels:
      - "traefik.docker.network=frontend"
      - "traefik.enable=true"
      - "traefik.frontend.rule=Host:\${WORDPRESS_DOMAINS$SNUM}"
      - "traefik.port=80"
      - "traefik.protocol=http"

EOL

mkdir -p /root/compose/www/html$SNUM
chmod 0777 /root/compose/www/html$SNUM

. /root/compose/.env
cat >/root/compose/sql <<EOL
CREATE DATABASE wordpress$SNUM DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;
GRANT ALL PRIVILEGES ON wordpress$SNUM.* TO 'wordpress'@'%';
FLUSH PRIVILEGES;
EOL

docker exec -it compose_wp-db_1 mysql -u root -p$WORDPRESS_DB_ROOT_PASSWORD  -e "$(cat /root/compose/sql)"

cd /root/compose
docker-compose up -d wp$SNUM &> /dev/null
echo "Done. Open in you WebBrowser http://$HOST "
echo -n "Add new website? (y/n) "
read item
case "$item" in
    y|Y) bash /root/site-add.sh
        ;;
    n|N)
        exit 0
        ;;
esac




