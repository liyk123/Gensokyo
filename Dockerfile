# 参考: https://www.bilibili.com/read/cv28664156/
#       https://github.com/Mrs4s/go-cqhttp

# 构建前端
FROM node:alpine as build-nodejs

WORKDIR /build

COPY . .

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

WORKDIR /app

COPY --from=build-go /build/gensokyo .

WORKDIR /data

VOLUME ["/data"]

CMD ["/app/gensokyo"]