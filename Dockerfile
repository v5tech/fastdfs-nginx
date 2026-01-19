## Dockerfile
FROM ubuntu:24.04

LABEL maintainer "29ygq@sina.com"

ENV FASTDFS_PATH=/opt/fdfs \
  FASTDFS_BASE_PATH=/var/fdfs \
  LIBFASTCOMMON_VERSION="V1.0.84" \
  LIBSERVERFRAME_VERSION="master" \
  FASTDFS_NGINX_MODULE_VERSION="V1.26" \
  FASTDFS_VERSION="V6.15.3" \
  NGINX_VERSION="1.28.1" \
  TENGINE_VERSION="3.1.0" \
  PORT= \
  GROUP_NAME= \
  TRACKER_SERVER= \
  CUSTOM_CONFIG="false"

# get all the dependences
RUN apt-get update && apt-get install -y curl git gcc make wget libpcre3 libpcre3-dev zlib1g zlib1g-dev openssl libssl-dev liburing-dev \
  && rm -rf /var/lib/apt/lists/*

# create the dirs to store the files downloaded from internet
RUN mkdir -p ${FASTDFS_PATH}/libfastcommon \
  && mkdir -p ${FASTDFS_PATH}/fastdfs \
  && mkdir -p ${FASTDFS_PATH}/fastdfs-nginx-module \
  && mkdir ${FASTDFS_BASE_PATH} \
  && mkdir /nginx_conf && mkdir -p /usr/local/nginx/conf/conf.d

WORKDIR ${FASTDFS_PATH}

## compile the libfastcommon
RUN git clone --depth=1 -b $LIBFASTCOMMON_VERSION https://github.com/happyfish100/libfastcommon.git libfastcommon \
  && cd libfastcommon \
  && ./make.sh \
  && ./make.sh install

## compile the libserverframe
RUN git clone --depth=1 -b $LIBSERVERFRAME_VERSION https://github.com/happyfish100/libserverframe.git libserverframe \
  && cd libserverframe \
  && ./make.sh \
  && ./make.sh install \
  && rm -rf ${FASTDFS_PATH}/libfastcommon \
  && rm -rf ${FASTDFS_PATH}/libserverframe

## compile the fastdfs
RUN git clone --depth=1 -b $FASTDFS_VERSION https://github.com/happyfish100/fastdfs.git fastdfs \
  && cd fastdfs \
  && ./make.sh \
  && ./make.sh install \
  && rm -rf ${FASTDFS_PATH}/fastdfs

RUN useradd -m -s /bin/bash www

## comile nginx
# nginx url: https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz
# tengine url: http://tengine.taobao.org/download/tengine-${TENGINE_VERSION}.tar.gz
RUN git clone --depth=1 -b $FASTDFS_NGINX_MODULE_VERSION https://github.com/happyfish100/fastdfs-nginx-module.git fastdfs-nginx-module \
  && wget https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz \
  && tar -zxf nginx-${NGINX_VERSION}.tar.gz \
  && cd nginx-${NGINX_VERSION} \
  && ./configure --prefix=/usr/local/nginx \
      --user=www \
      --add-module=${FASTDFS_PATH}/fastdfs-nginx-module/src/ \
      --with-stream=dynamic \
  && make \
  && make install \
  && ln -s /usr/local/nginx/sbin/nginx /usr/bin/ \
  && rm -rf ${FASTDFS_PATH}/nginx-* \
  && rm -rf ${FASTDFS_PATH}/fastdfs-nginx-module

EXPOSE 22122 23000 8080 8888 80
VOLUME ["$FASTDFS_BASE_PATH","/etc/fdfs","/usr/local/nginx/conf/conf.d"]

COPY conf/*.* /etc/fdfs/
COPY nginx_conf/ /nginx_conf/
COPY nginx_conf/nginx.conf /usr/local/nginx/conf/
COPY entrypoint.sh /usr/bin/

RUN chmod a+x /usr/bin/entrypoint.sh

WORKDIR ${FASTDFS_PATH}

ENTRYPOINT ["/usr/bin/entrypoint.sh"]
CMD ["tracker"]
