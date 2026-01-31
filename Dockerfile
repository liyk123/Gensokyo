# 参考: https://www.bilibili.com/read/cv28664156/
#       https://github.com/Mrs4s/go-cqhttp

# 构建前端
FROM node:alpine as build-nodejs

WORKDIR /build

COPY ./ .

WORKDIR /build/frontend

RUN npm config set registry https://registry.npmmirror.com/ \
    && npm install -g @vue/cli \
    && npm install -g @quasar/cli \
    && npm install \
    && quasar build

# 构建主程序
FROM golang:alpine as build-go

ENV GOPROXY=https://goproxy.cn \
    GO111MODULE=on \
    CGO_ENABLED=0

WORKDIR /build

COPY --from=build-nodejs /build .

RUN go build -v -o gensokyo .

# 构建最终镜像
FROM alpine:latest

COPY docker-entrypoint.sh /docker-entrypoint.sh

RUN chmod +x /docker-entrypoint.sh \
    && apk add --no-cache --update coreutils shadow su-exec tzdata ffmpeg \
    && rm -rf /var/cache/apk/* \
    && mkdir -p /app \ 
    && mkdir -p /data \
    && mkdir -p /config \
    && useradd -d /config -s /bin/sh gsk \
    && chown -R gsk /config \
    && chown -R gsk /data

ENV TZ="Asia/Shanghai"
ENV UID=99
ENV GID=100
ENV UMASK=002

COPY --from=build-go /build/gensokyo /app/

WORKDIR /data

VOLUME ["/data"]

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/app/gensokyo"]
