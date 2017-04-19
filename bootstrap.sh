#!/bin/bash

# Configure locales
echo locales locales/locales_to_be_generated multiselect en_US.UTF-8 UTF-8 | debconf-set-selections
echo locales locales/default_environment_locale select  en_US.UTF-8 | debconf-set-selections
dpkg-reconfigure locales -f noninteractive
echo -e 'LANG=en_US.UTF-8\nLC_ALL=en_US.UTF-8' > /etc/default/locale

# Prepare OS
su - root -c 'apt-get update'
su - root -c 'apt-get install ruby -y'

# User ubuntu, creates only if virtual environment, in production should be created at Ubuntu installation step
id ubuntu > /dev/null 2>&1 || adduser --disabled-password --gecos "" ubuntu

# NTP
su - root -c 'apt-get install ntp -y'

# Postgresql
su - root -c 'apt-get install postgresql -y'
sed -i 's/^\(#m\|m\)ax_connections.*/max_connections = 1000/g' /etc/postgresql/9.5/main/postgresql.conf
sed -i 's/^\(#s\|s\)hared_buffers.*/shared_buffers = 512MB/g' /etc/postgresql/9.5/main/postgresql.conf
sed -i 's/^\(#e\|e\)ffective_cache_size.*/effective_cache_size = 1024MB/g' /etc/postgresql/9.5/main/postgresql.conf
sed -i 's/^\(#w\|w\)ork_mem.*/work_mem = 40MB/g' /etc/postgresql/9.5/main/postgresql.conf
service postgresql restart

# Common packages 
su - root -c 'apt-get install mc unrar -y'
su - root -c 'apt-get install python-pip virtualenv python-setuptools python-distutils-extra -y'
su - root -c 'apt-get install build-essential libssl-dev libffi-dev python-dev git python-pip dialog libaugeas0 ca-certificates -y'
su - root -c 'apt-get install libffi-dev -y'

# Crossbar and dependencies
su - root -c 'apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 5FC6281FD58C6920'
echo 'deb http://package.crossbar.io/ubuntu xenial main' > /etc/apt/sources.list.d/crossbar.list
su - root -c 'apt-get update'
su - root -c 'apt-get install crossbar -y'
su - root -c 'apt-get install postgresql-server-dev-all -y'
su - root -c '/opt/crossbar/bin/pypy -m pip install --upgrade pip'
su - root -c '/opt/crossbar/bin/pypy -m pip install bcrypt'
su - root -c '/opt/crossbar/bin/pypy -m pip install letsencrypt'

# Crossbar upgrade
su - root -c 'apt-add-repository ppa:pypy/ubuntu/ppa -y && apt-get update'
su - root -c 'apt-get install build-essential libssl-dev python-pip pypy pypy-dev -y'
su - root -c 'pip install --upgrade cffi'
su - root -c 'virtualenv ~/venv && \. ~/venv/bin/activate && pip install crossbar && pip uninstall crossbar -y'
su - ubuntu -c 'virtualenv ~/venv && \. ~/venv/bin/activate && pip install --upgrade cffi && pip install crossbar && pip install psycopg2cffi bcrypt'

# Crossbar service
cat > /lib/systemd/system/crossbar.service <<- EOF

# Crossbar
[Unit]
Description=Crossbar
After=network.target

[Service]
PIDFile=/var/run/crossbar.pid
ExecStart=/home/ubuntu/venv/bin/crossbar start --logdir /var/log/crossbar --logtofile
ExecStop=/home/ubuntu/venv/bin/crossbar stop
User=ubuntu
Group=ubuntu
WorkingDirectory=/home/ubuntu/htdocs/kp-client/dist

[Install]
WantedBy=multi-user.target
EOF

su - root -c 'mkdir -p /var/log/crossbar && chown -R ubuntu:ubuntu /var/log/crossbar'
su - root -c 'systemctl enable crossbar'
su - root -c 'systemctl daemon-reload'
su - root -c 'systemctl start crossbar'

# Crossbar logrotate
cat > /etc/logrotate.d/crossbar <<- EOF

/var/log/crossbar/*.log {
       daily
       rotate 10
       copytruncate
       delaycompress
       compress
       notifempty
       missingok
       create 0640 ubuntu ubuntu
       su ubuntu ubuntu
       sharedscripts
       postrotate
               systemctl restart crossbar >/dev/null 2>&1
       endscript
}
EOF

# NVM
su - ubuntu -c 'wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.33.1/install.sh | bash'
su - ubuntu -c 'export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && nvm install v7.7.2'

# Postfix
debconf-set-selections <<< "postfix postfix/mailname string your.hostname.com"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
su - root -c 'apt-get install -y postfix'

# xubuntu-desktop
su - root -c 'apt-get install -y xubuntu-desktop'
systemctl disable lightdm.service
service lightdm stop

# SFTP
su - root -c 'apt-get install mysecureshell -y'

# Nginx base installation
su - root -c 'apt-get install nginx -y'
su - ubuntu -c 'mkdir -p /home/ubuntu/htdocs/kp-client/dist'

cat > /etc/nginx/sites-available/kopnik.org <<- EOF
server {
  listen 80;
  root /home/ubuntu/htdocs/kp-client/dist;
  server_name kopnik.org www.kopnik.org;
}
EOF

su - root -c 'rm /etc/nginx/sites-enabled/kopnik.org ; ln -s /etc/nginx/sites-available/kopnik.org /etc/nginx/sites-enabled/kopnik.org'
if [ -f /etc/nginx/sites-enabled/default ]; then
  rm /etc/nginx/sites-enabled/default
fi
su - root -c 'nginx -t && service nginx restart'

# Certificates, some commands commented because manual answering require
su - root -c 'pip install --upgrade pip'
su - root -c 'apt-get install letsencrypt -y'
#su - ubuntu -c 'mkdir -p /home/ubuntu/htdocs/kp-client/dist'
#letsencrypt certonly --webroot -w /home/ubuntu/htdocs/kp-client/dist -d kopnik.org -d www.kopnik.org

#- name: Download certbot
su - root -c 'apt-get install wget -y'
su - root -c 'wget -O /root/certbot-auto https://dl.eff.org/certbot-auto && chmod a+xr /root/certbot-auto'

#- name: Request cert for kopnik.org (first time)
#if [ ! -f /etc/letsencrypt/live/kopnik.org/fullchain.pem ]; then
#  sudo su - root -c '/root/certbot-auto certonly --standalone -d kopnik.org -d www.kopnik.org  --email alexey2baranov@gmail.com  --non-interactive --agree-tos'
#fi

#- name: Update cert for kopnik.org (subsequent time)
#if [ -f /etc/letsencrypt/live/kopnik.org/fullchain.pem ]; then
#  sudo su - root -c '/root/certbot-auto certonly --webroot -w /home/ubuntu/htdocs/kp-client/dist -d kopnik.org -d www.kopnik.org --email alexey2baranov@gmail.com --non-interactive --agree-tos'
#fi

# Place hardcoded certs
mkdir -p /etc/letsencrypt/live/kopnik.org/
cat > /etc/letsencrypt/live/kopnik.org/fullchain.pem <<- EOF
-----BEGIN CERTIFICATE-----
MIIFCDCCA/CgAwIBAgISA1RdtvLkG2nTGoCEBq5D1ZXzMA0GCSqGSIb3DQEBCwUA
MEoxCzAJBgNVBAYTAlVTMRYwFAYDVQQKEw1MZXQncyBFbmNyeXB0MSMwIQYDVQQD
ExpMZXQncyBFbmNyeXB0IEF1dGhvcml0eSBYMzAeFw0xNzAzMTAwOTU2MDBaFw0x
NzA2MDgwOTU2MDBaMBUxEzARBgNVBAMTCmtvcG5pay5vcmcwggEiMA0GCSqGSIb3
DQEBAQUAA4IBDwAwggEKAoIBAQC2W9Yek+GuG1UcLHYDP/IPD9CMBn/wnjMrXog0
7AZzg9bNijIHcYM0QA0vj2A/QVQmFpSsPDyaMrHp9yEgnsmHsR8kj/HGonrIwHy+
hvifvU9p1SXtaP/ySX36aOwMVLP+nO1yr0c9ctyjUBbd9BinUi1h40jIzcTrRoJI
KlSMn7DvI2pVaBBxqKzj8zNxkT6utAuZOYmH99+gTDzKPdtRLrQE4vIHtaAbRUHW
JQkLFBzH9AZUORbXAw8zd52RWZcj8H7AD7cbtA1ZTTSCD4FUE925vd290s9hzsmJ
hsZFtmQSAgIhVeyXn+ZnzXsCcqJ7SiPeQK73fNUcqZVtVYtLAgMBAAGjggIbMIIC
FzAOBgNVHQ8BAf8EBAMCBaAwHQYDVR0lBBYwFAYIKwYBBQUHAwEGCCsGAQUFBwMC
MAwGA1UdEwEB/wQCMAAwHQYDVR0OBBYEFDG1TjKxiMQ++RTTY+UK90gd1TLJMB8G
A1UdIwQYMBaAFKhKamMEfd265tE5t6ZFZe/zqOyhMHAGCCsGAQUFBwEBBGQwYjAv
BggrBgEFBQcwAYYjaHR0cDovL29jc3AuaW50LXgzLmxldHNlbmNyeXB0Lm9yZy8w
LwYIKwYBBQUHMAKGI2h0dHA6Ly9jZXJ0LmludC14My5sZXRzZW5jcnlwdC5vcmcv
MCUGA1UdEQQeMByCCmtvcG5pay5vcmeCDnd3dy5rb3BuaWsub3JnMIH+BgNVHSAE
gfYwgfMwCAYGZ4EMAQIBMIHmBgsrBgEEAYLfEwEBATCB1jAmBggrBgEFBQcCARYa
aHR0cDovL2Nwcy5sZXRzZW5jcnlwdC5vcmcwgasGCCsGAQUFBwICMIGeDIGbVGhp
cyBDZXJ0aWZpY2F0ZSBtYXkgb25seSBiZSByZWxpZWQgdXBvbiBieSBSZWx5aW5n
IFBhcnRpZXMgYW5kIG9ubHkgaW4gYWNjb3JkYW5jZSB3aXRoIHRoZSBDZXJ0aWZp
Y2F0ZSBQb2xpY3kgZm91bmQgYXQgaHR0cHM6Ly9sZXRzZW5jcnlwdC5vcmcvcmVw
b3NpdG9yeS8wDQYJKoZIhvcNAQELBQADggEBABTQSsfkpMm2AaBChYt496OQRe5R
+qeXfbUysa/qGa857Utpo6LKkwzOXOVBHrGLcfVEvjEfWVs/009jJOCVv143VOBM
gcm0xEAdVost67N/g0i3FhlUs6p0FyovVRcIcC9CCCRSLIsHlGyt5sqnj6YOakmj
9eb/vR4gGRkaXNina6bGw7coSUMha6fsaiRCpzsdmpwr3Umw9wBaoQPVy8PqTQPU
206p1FVRMTfAIQdKB/hE1t7jBa56DzGlWnltXXH72oEcnGi+DTe8dDoaCoXVhmg8
MqzrnPzSUfpJBXcR0aeDzAgxk0GE8i7MEX0O/t1yXkCDoiARVZMy4DSvOh4=
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
MIIEkjCCA3qgAwIBAgIQCgFBQgAAAVOFc2oLheynCDANBgkqhkiG9w0BAQsFADA/
MSQwIgYDVQQKExtEaWdpdGFsIFNpZ25hdHVyZSBUcnVzdCBDby4xFzAVBgNVBAMT
DkRTVCBSb290IENBIFgzMB4XDTE2MDMxNzE2NDA0NloXDTIxMDMxNzE2NDA0Nlow
SjELMAkGA1UEBhMCVVMxFjAUBgNVBAoTDUxldCdzIEVuY3J5cHQxIzAhBgNVBAMT
GkxldCdzIEVuY3J5cHQgQXV0aG9yaXR5IFgzMIIBIjANBgkqhkiG9w0BAQEFAAOC
AQ8AMIIBCgKCAQEAnNMM8FrlLke3cl03g7NoYzDq1zUmGSXhvb418XCSL7e4S0EF
q6meNQhY7LEqxGiHC6PjdeTm86dicbp5gWAf15Gan/PQeGdxyGkOlZHP/uaZ6WA8
SMx+yk13EiSdRxta67nsHjcAHJyse6cF6s5K671B5TaYucv9bTyWaN8jKkKQDIZ0
Z8h/pZq4UmEUEz9l6YKHy9v6Dlb2honzhT+Xhq+w3Brvaw2VFn3EK6BlspkENnWA
a6xK8xuQSXgvopZPKiAlKQTGdMDQMc2PMTiVFrqoM7hD8bEfwzB/onkxEz0tNvjj
/PIzark5McWvxI0NHWQWM6r6hCm21AvA2H3DkwIDAQABo4IBfTCCAXkwEgYDVR0T
AQH/BAgwBgEB/wIBADAOBgNVHQ8BAf8EBAMCAYYwfwYIKwYBBQUHAQEEczBxMDIG
CCsGAQUFBzABhiZodHRwOi8vaXNyZy50cnVzdGlkLm9jc3AuaWRlbnRydXN0LmNv
bTA7BggrBgEFBQcwAoYvaHR0cDovL2FwcHMuaWRlbnRydXN0LmNvbS9yb290cy9k
c3Ryb290Y2F4My5wN2MwHwYDVR0jBBgwFoAUxKexpHsscfrb4UuQdf/EFWCFiRAw
VAYDVR0gBE0wSzAIBgZngQwBAgEwPwYLKwYBBAGC3xMBAQEwMDAuBggrBgEFBQcC
ARYiaHR0cDovL2Nwcy5yb290LXgxLmxldHNlbmNyeXB0Lm9yZzA8BgNVHR8ENTAz
MDGgL6AthitodHRwOi8vY3JsLmlkZW50cnVzdC5jb20vRFNUUk9PVENBWDNDUkwu
Y3JsMB0GA1UdDgQWBBSoSmpjBH3duubRObemRWXv86jsoTANBgkqhkiG9w0BAQsF
AAOCAQEA3TPXEfNjWDjdGBX7CVW+dla5cEilaUcne8IkCJLxWh9KEik3JHRRHGJo
uM2VcGfl96S8TihRzZvoroed6ti6WqEBmtzw3Wodatg+VyOeph4EYpr/1wXKtx8/
wApIvJSwtmVi4MFU5aMqrSDE6ea73Mj2tcMyo5jMd6jmeWUHK8so/joWUoHOUgwu
X4Po1QYz+3dszkDqMp4fklxBwXRsW10KXzPMTZ+sOPAveyxindmjkW8lGy+QsRlG
PfZ+G6Z6h7mjem0Y+iWlkYcV4PIWL1iwBi8saCbGS5jN2p8M+X+Q7UNKEkROb3N6
KOqkqm57TH2H3eDJAkSnh6/DNFu0Qg==
-----END CERTIFICATE-----
EOF

cat > /etc/letsencrypt/live/kopnik.org/privkey.pem <<- EOF
-----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQC2W9Yek+GuG1Uc
LHYDP/IPD9CMBn/wnjMrXog07AZzg9bNijIHcYM0QA0vj2A/QVQmFpSsPDyaMrHp
9yEgnsmHsR8kj/HGonrIwHy+hvifvU9p1SXtaP/ySX36aOwMVLP+nO1yr0c9ctyj
UBbd9BinUi1h40jIzcTrRoJIKlSMn7DvI2pVaBBxqKzj8zNxkT6utAuZOYmH99+g
TDzKPdtRLrQE4vIHtaAbRUHWJQkLFBzH9AZUORbXAw8zd52RWZcj8H7AD7cbtA1Z
TTSCD4FUE925vd290s9hzsmJhsZFtmQSAgIhVeyXn+ZnzXsCcqJ7SiPeQK73fNUc
qZVtVYtLAgMBAAECggEATLB4bqmQSjESbOPByYIV4QGsmYaOPXm6WS3LKD5uRBwY
tJ2+hmTVYZ7iLLMmLdPieJYcdgZrEgnpylP0qYw9goQZbb3fVsKz0kMo8tM+Madi
g0ZxSdNTd+gyQ6HmSxVAEP6b2RQfaJcqdL/UrgjeaVdk4Hq9/DyU6MDhP0oV/oDf
oK91DuLIzVtU//DPtJDaWDfNkmZk8mrd7uQj3Z6dxVpoS+rmj/ExWE2G0s7W9sDv
WCPJt71+Mk7H1igziOWujKP3C6ChCip6OxuZVNI+i53bYwqPdVCXF9SFpQ5EpohT
HDKaeNrLtQ1wpc12LyDEkIupwHrbnZTmNytqLt3cUQKBgQDo6GPM9bveVm94gOzD
tzs4HUyJzIGjUa5M0lX5w4Qt9TK7kUdlxZsDsl9hRWzK5YNlkyYWMilT0USXeod8
zgi2iVfe4upl1Cj1r73qEfRLXdLLipYPOIK9tt1SV+zOIEzImltSLBCffmWjLU1e
+HR99kq2jTSZrJ0ouHDMd5bVqQKBgQDIcGw+YI53V2b+Wmg8+zrBZ758gzzJU5zl
sB4L8qE8TNVExaanB3MNpB9fLG9eDnTbyv0f9r9VWIhS4CT0WDCWIDTQNHXoUktq
ib+Mt3bifzMs6HrZtuwQvCiKuzrSHvUPBUZ9UoGM5K5mPAzzc8B9EFKtTbweIYth
3CrgecyJ0wKBgQDHgVkL1mrpF01BAd7N/4SgmqhXWXCqv2r4ryuqWMo+u8yLUvS/
vrb8QazmG5wHaPZW6ec0GB/Chn2k6/Zm9+4Kvjcg22tBcqzrV3Dsshh6/pF0fO/x
dcy4SY3n3R0hrBVZuK8FAm3y0UiqsEGYWmcfBvwUx3wJLw0oNmWZH896kQKBgE5A
peHMbJJnCwyuWxfDtXKggBu4WNj4zb5WfcSIWy5hiLmquJ9pJx/iPWU4wdnkpvbQ
TvZVrOkzATXp0EOc0osp07SdZpLm3g6f7KqRTdardl1H/f5VjeAStXlEE3jJIT9V
/ekbdvx8oyHCvAOn4zRwVPbX7GOPEQ2JmSu+IX6FAoGBAMk6xkMKrCPdqTqHxTxG
v1NKvEwRw7/iwAC6UnTsyfkGZGoHU+Cg9tq8SWrgKQi9KzAdajH5uPffCgxWvll3
677QfdCwe9wPsQxnRKvuK4HuoRe3ikKbkdW7BWv7xwSVun/Ktj7uzQugG+c5/y9y
khbtjjrHN/XYWZISxzcUqipC
-----END PRIVATE KEY-----
EOF

# Nginx update configs to kopnik.org
cat > /etc/nginx/nginx.conf <<- EOF
pid /run/nginx.pid;
user www-data;
worker_processes 4;

events {
    worker_connections 768;
}

http {
    access_log /var/log/nginx/access.log;
    default_type application/octet-stream;
    error_log /var/log/nginx/error.log;

    gzip on;
    gzip_disable msie6;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_buffers 16 8k;
    gzip_http_version 1.1;
    gzip_min_length 256;
    gzip_types text/plain text/css application/json application/x-javascript application/javascript text/xml application/xml application/xml+rss text/javascript application/vnd.ms-fontobject application/x-font-ttf font/opentype image/svg+xml image/x-icon;

    include /etc/nginx/mime.types;
    keepalive_timeout 65;
    sendfile on;
    ssl_prefer_server_ciphers on;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    tcp_nodelay on;
    tcp_nopush on;
    types_hash_max_size 2048;

    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
EOF

cat > /etc/nginx/sites-available/kopnik.org <<- EOF
server {
  listen 443 ssl default_server;
  root /home/ubuntu/htdocs/kp-client/dist;
  server_name kopnik.org www.kopnik.org;
  ssl_certificate /etc/letsencrypt/live/kopnik.org/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/kopnik.org/privkey.pem;

    location /ws {
        # switch off logging
        access_log off;

        # redirect all HTTP traffic to localhost:8080
        proxy_pass http://localhost:8080;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header Host \$host;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;

        # WebSocket support (nginx 1.4)
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    location ~* /^(upload|download) {
        # switch off logging
        access_log off;

        # redirect all HTTP traffic to localhost:8484
        proxy_pass http://localhost:8484;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header Host \$host;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }

    location /sw.js {
        # switch off logging
        access_log off;

        add_header Cache-Control "max-age=0, private, must-revalidate";
    }

    location / {
        # switch off logging
        access_log off;
    }

}
EOF

#  348  vi /etc/group
#  349  chmod g+rx /etc/letsencrypt/archive/
#  350  chmod g+rx /etc/letsencrypt/archive/kopnik.org/
#  351  chmod g+r /etc/letsencrypt/archive/kopnik.org/*
#  352  chmod g+rx /etc/letsencrypt/live/
#  353  chmod g+rx /etc/letsencrypt/live/kopnik.org/
#  354  ls -al /etc/letsencrypt/live/kopnik.org/

su - root -c 'rm /etc/nginx/sites-enabled/kopnik.org ; ln -s /etc/nginx/sites-available/kopnik.org /etc/nginx/sites-enabled/kopnik.org'
su - root -c 'nginx -t && service nginx restart'
