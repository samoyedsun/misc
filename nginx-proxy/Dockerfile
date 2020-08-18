FROM samoyedsun/base:v15
MAINTAINER mazhao <samoyedsun@gmail.com>

ENV NGINX_PROXY_URL https://www.alibaba.com/

#ENV SSL ssl
#ENV CERTIFICATE_NAME www.alibaba.com
    

COPY ./nginx.conf /usr/local/nginx/conf/nginx.conf

RUN echo "sed -i -e \"s#NGINX_PROXY_URL#\${NGINX_PROXY_URL}#g\" /usr/local/nginx/conf/nginx.conf" > start.sh
RUN echo "if [[ \"\${SSL}\" = \"ssl\" ]]; then" >> start.sh
RUN echo "    sed -i -e \"s#SSL#\${SSL}#g\" /usr/local/nginx/conf/nginx.conf" >> start.sh
RUN echo "    sed -i -e \"s#CERTIFICATE_CONFIG_PEM#\ssl_certificate cert/\${CERTIFICATE_NAME}.pem;#g\" /usr/local/nginx/conf/nginx.conf" >> start.sh
RUN echo "    sed -i -e \"s#CERTIFICATE_CONFIG_KEY#\ssl_certificate_key cert/\${CERTIFICATE_NAME}.key;#g\" /usr/local/nginx/conf/nginx.conf" >> start.sh
RUN echo "else" >> start.sh
RUN echo "    sed -i -e \"s#SSL#\${SSL_NULL}#g\" /usr/local/nginx/conf/nginx.conf" >> start.sh
RUN echo "    sed -i -e \"s#CERTIFICATE_CONFIG_PEM#\${CERTIFICATE_CONFIG_PEM_NULL}#g\" /usr/local/nginx/conf/nginx.conf" >> start.sh
RUN echo "    sed -i -e \"s#CERTIFICATE_CONFIG_KEY#\${CERTIFICATE_CONFIG_KEY_NULL}#g\" /usr/local/nginx/conf/nginx.conf" >> start.sh
RUN echo "fi" >> start.sh
RUN echo "exec nginx -g \"daemon off;\"" >> start.sh

CMD ["bash", "start.sh"]
