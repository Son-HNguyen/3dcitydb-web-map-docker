# 3DCityDB Web Map Client Dockerfile ###########################################
#   Official website    https://www.3dcitydb.net
#   GitHub              https://github.com/3dcitydb/3dcitydb-web-map
###############################################################################
# Base image
ARG baseimage_tag='9'
FROM "node:${baseimage_tag}"
# Maintainer ##################################################################
#   Bruno Willenborg
#   Chair of Geoinformatics
#   Department of Civil, Geo and Environmental Engineering
#   Technical University of Munich (TUM)
#   <b.willenborg@tum.de>
MAINTAINER Bruno Willenborg, Chair of Geoinformatics, Technical University of Munich (TUM) <b.willenborg@tum.de>

# Setup 3DCityDB Web Map Client ###############################################
ARG webmapclient_version='v1.4.0'
RUN set -x \
  && BUILD_PACKAGES='ca-certificates git' \
  && apt-get update && apt-get install -y --no-install-recommends $BUILD_PACKAGES \
  && git clone -b "${webmapclient_version}" --depth 1 https://github.com/3dcitydb/3dcitydb-web-map.git /var/www \
  && cd /var/www \
  && rm -rf ./.git ./.gitignore ./LICENSE ./README.md ./build.xml \
     ./node_modules ./server.js ./theme \  
  && mkdir -p /var/www/data \
  && apt-get purge -y --auto-remove $BUILD_PACKAGES \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /var/www/  
COPY package.json ./
COPY html/* ./
COPY server.js ./
RUN set -x \
  && npm install --production

RUN set -x \
  && chown -R node:node /var/www/

VOLUME /var/www/
USER node
EXPOSE 8000 137/udp 138/udp 139 445
CMD [ "node", "server.js", "--public"]

# Install Samba
WORKDIR /
USER root
RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y samba-common samba
RUN adduser --quiet --disabled-password --shell /bin/bash --home /home/testusr --gecos "User" testusr && \
        echo 'testpw' | tee - | smbpasswd -a -s testusr && \
        chmod -R 778 /var/www/
#       cp /etc/samba/smb.conf /etc/samba/smb.conf.bak && \
#       echo "printing = bsd printcap name = /dev/null" >> /etc/samba/smb.conf
#       echo "[smb_shared]" >> /etc/samba/smb.conf && \
#       echo "\tpath = /var/www/" >> /etc/samba/smb.conf && \
#       echo "\tavailable = yes" >> /etc/samba/smb.conf && \
#       echo "\tvalid users = testusr" >> /etc/samba/smb.conf && \
#       echo "\tread only = no" >> /etc/samba/smb.conf && \
#       echo "\tbrowsable = yes" >> /etc/samba/smb.conf && \
#       echo "\tpublic = yes" >> /etc/samba/smb.conf && \
#       echo "\twritable = yes" >> /etc/samba/smb.conf
RUN service smbd restart

#EXPOSE 137/udp 138/udp 139 445
COPY samba.sh /samba.sh
ENTRYPOINT [ "/samba.sh" ]
