echo "Enter the domain name of the new site: "
read HOST
what is the site number
echo "what is the site number: "
read SNUM
#WORDPRESS_DB=wordpres$(cat /dev/urandom | tr -dc '[:digit:]' | head -c5`)

cat >>/root/compose/.env <<EOL
WORDPRESS_DB_NAME$SNUM=wordpres$SNUM
WORDPRESS_DOMAINS$SNUM=$HOST

cat >/root/compose/sql <<EOL
CREATE DATABASE wordpress$SNUM DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci
GRANT ALL PRIVILEGES ON wordpress.* TO 'wordpress'@'%';
FLUSH PRIVILEGES;
EOL

docker exec -it compose_wp-db_1 mysql -u root -ppassword  -e "$(cat /root/compose/sql)"

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
       - /var/www/htlm/root/compose/sql:/var/www/html
     # - ./php.ini:/usr/local/etc/php/php.ini
    environment:
      WORDPRESS_DB_HOST: wp-db:3306
      WORDPRESS_DB_USER: \${WORDPRESS_DB_USER}
      WORDPRESS_DB_PASSWORD: \${WORDPRESS_DB_PASSWORD}
      WORDPRESS_DB_NAME: \${WORDPRESS_DB_NAME$SNUM}
    labels:
      - "traefik.docker.network=frontend"
      - "traefik.enable=true"
      - "traefik.frontend.rule=Host:${WORDPRESS_DOMAINS$SNUM}"
      - "traefik.port=80"
      - "traefik.protocol=http"
EOL
mkdir -p /root/compose/www/html$SNUM
chmod 0777 -R /root/compose/www/html$SNUM
cd /root/compose
docker-compose up -d wp$SNUM

