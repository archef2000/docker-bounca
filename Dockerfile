FROM --platform=$BUILDPLATFORM golang:1.21 as build

ARG TARGETPLATFORM
RUN echo "nameserver 192.168.11.1" > /etc/resolv.conf

FROM nginx:1.25.3-bookworm
ENV DOCROOT=/srv/www/bounca \
    LOGDIR=/var/log/bounca \
    ETCDIR=/etc/bounca \
    BOUNCA_USER=www-data \
    BOUNCA_GROUP=www-data

RUN apt-get update \
  && apt-get install -qy \
    gettext netcat-traditional nginx python3 python3-dev python3-setuptools python-is-python3 uwsgi uwsgi-plugin-python3 virtualenv python3-virtualenv python3-pip \
    wget ca-certificates openssl

RUN wget -P /srv/www https://github.com/repleo/bounca/releases/download/v0.4.4/bounca.tar.gz \
  && tar -xzvf /srv/www/bounca.tar.gz -C /srv/www \
  && rm /srv/www/bounca.tar.gz

RUN mkdir -pv ${LOGDIR} ${DOCROOT} ${ETCDIR} /etc/nginx/sites-available /etc/nginx/sites-enabled \
  && rm -fv /etc/nginx/conf.d/default.conf \
  && cp -v ${DOCROOT}/etc/nginx/bounca /etc/nginx/sites-available/bounca \
  && ln -s /etc/nginx/sites-available/bounca /etc/nginx/sites-enabled/bounca \
  && cp -v ${DOCROOT}/etc/uwsgi/bounca.ini /etc/uwsgi/apps-available/bounca.ini \
  && ln -s /etc/uwsgi/apps-available/bounca.ini /etc/uwsgi/apps-enabled/bounca.ini \
  && chown -R ${BOUNCA_USER}:${BOUNCA_GROUP} ${LOGDIR} ${DOCROOT} ${ETCDIR}

RUN pip install --no-cache-dir --break-system-packages -r ${DOCROOT}/requirements.txt

RUN ln -sfT /dev/stdout "/var/log/nginx/bounca-access.log" \
  && ln -sfT /dev/stdout "/var/log/nginx/bounca-error.log" \
  && apt-get clean \
  && rm -rfv /tmp/* /var/tmp/* /var/lib/apt/lists/* ${DOCROOT}/.git \
  ;

COPY files/ /docker-entrypoint.d/

WORKDIR ${DOCROOT}

VOLUME ${DOCROOT}
