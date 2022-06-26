FROM python:3.9.12
EXPOSE 80
EXPOSE 8000
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
WORKDIR /code
COPY test_fe/requirements.txt /code/
RUN python -m pip install --upgrade pip
RUN pip install -r requirements.txt
COPY test_fe/ /code/
RUN apt-get update
RUN apt-get install nginx -y
RUN rm /etc/nginx/nginx.conf
RUN mkdir /var/log/uwsgi

RUN echo ' \n\
############## \n\
user www-data; \n\
worker_processes auto; \n\
pid /run/nginx.pid; \n\
include /etc/nginx/modules-enabled/*.conf; \n\
events { \n\
        worker_connections 768; \n\
        # multi_accept on; \n\
} \n\
http { \n\
        sendfile on; \n\
        tcp_nopush on; \n\
        types_hash_max_size 2048; \n\
        include /etc/nginx/mime.types; \n\
        default_type application/octet-stream; \n\
        ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3; # Dropping SSLv3, ref: POODLE \n\
        ssl_prefer_server_ciphers on; \n\
        access_log /var/log/nginx/access.log; \n\
        error_log /var/log/nginx/error.log; \n\
        gzip on; \n\
        # gzip_vary on; \n\
        # gzip_proxied any; \n\
         gzip_comp_level 8; \n\
        # gzip_buffers 16 8k; \n\
        # gzip_http_version 1.1; \n\
        # gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascrip> \n\
upstream django { \n\
    server 127.0.0.1:29000; \n\
} \n\
server { \n\
        listen 80 default_server; \n\
        listen [::]:80 default_server; \n\
        root /code/; \n\
        server_name _; \n\
        location /fe/static/ { \n\
                rewrite /fe/static/(.*) http://django-test-static-files.s3.us-west-1.amazonaws.com/static/$1  break; \n\
#                return 301 $scheme://django-test-static-files.s3.us-west-1.amazonaws.com$request_uri; \n\
#                alias /code/static/; \n\
        } \n\
        location /fe/ { \n\
                include /etc/nginx/uwsgi_params; \n\
                uwsgi_pass django; \n\
                uwsgi_param Host $host; \n\
                uwsgi_param X-Real-IP $remote_addr; \n\
                uwsgi_param X-Forwarded-For $proxy_add_x_forwarded_for; \n\
                uwsgi_param X-Forwarded-Proto $http_x_forwarded_proto; \n\
        } \n\
} \n\
} \n'\
>> /etc/nginx/nginx.conf
CMD service nginx start ; uwsgi --chdir=/code \
     --module=test_fe.wsgi:application \
     --env DJANGO_SETTINGS_MODULE=test_fe.settings \
     --master --pidfile=/var/run/project-master.pid \
     --socket=127.0.0.1:29000 \
     --processes=5 \
     --uid=505 --gid=505 \
     --harakiri=20 \
     --max-requests=5000 \
     --vacuum \
     --daemonize=/var/log/uwsgi/myapp.log \
     ; python manage.py runserver 0.0.0.0:8000