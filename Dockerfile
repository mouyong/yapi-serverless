FROM node:12-alpine

RUN npm config set registry https://registry.npm.taobao.org
RUN npm install -g yapi-cli --registry https://registry.npm.taobao.org

RUN if [ -f "/etc/apk/repositories" ]; then \
	sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/' /etc/apk/repositories; \
	else \
		sed -i 's/deb.debian.org/mirrors.tuna.tsinghua.edu.cn/' /etc/apt/sources.list && \
		sed -i 's/security.debian.org/mirrors.tuna.tsinghua.edu.cn/' /etc/apt/sources.list && \
		sed -i 's/security-cdn.debian.org/mirrors.tuna.tsinghua.edu.cn/' /etc/apt/sources.list \
;fi

ADD . /app
WORKDIR /app

ARG YAPI_VERSION=1.9.2
ENV YAPI_VERSION $YAPI_VERSION
ADD http://registry.npm.taobao.org/yapi-vendor/download/yapi-vendor-$YAPI_VERSION.tgz /app/

ARG YAPI_INIT=false
RUN if [ "YAPI_INIT" == true ]; then \
	sed -in '/options.pass/a\      options.authSource = config.db.authSource;' /usr/local/lib/node_modules/yapi-cli/src/commands/install.js && \
	yapi-cli install -v $YAPI_VERSION; \
else \
	sed -in '/options.pass/a\      options.authSource = config.db.authSource;' /usr/local/lib/node_modules/yapi-cli/src/commands/install.js \
	&& tar -xf yapi-vendor-$YAPI_VERSION.tgz \
	&& mv package vendors \
	&& sed -i 's/yapi.WEBCONFIG.port/yapi.WEBCONFIG.port, yapi.WEBCONFIG.host/' vendors/server/app.js \
	&& sed -i 's/127.0.0.1/${yapi.WEBCONFIG.host}/' vendors/server/app.js \
	&& touch init.lock \
	&& rm yapi-vendor-$YAPI_VERSION.tgz \
	&& cd vendors \
	&& npm install --production \
;fi

CMD ["node", "/app/vendors/server/app.js"]

EXPOSE 9000
