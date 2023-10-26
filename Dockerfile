FROM node:18.18.2-alpine3.18 as front-builder
LABEL stage=front-builder
RUN npm install -g pnpm
WORKDIR /app/
COPY ./alist-web/package.json ./alist-web/pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile
COPY ./alist-web/ .
RUN pnpm i18n:build && pnpm build

FROM alpine:3.18 as builder
LABEL stage=go-builder
WORKDIR /app/
COPY ./ ./
COPY --from=front-builder /app/dist ./public/dist
RUN apk add --no-cache bash curl gcc git go musl-dev; \
    bash build.sh release docker

FROM alpine:3.18
LABEL MAINTAINER="i@nn.ci"
VOLUME /opt/alist/data/
WORKDIR /opt/alist/
COPY --from=builder /app/bin/alist ./
COPY entrypoint.sh /entrypoint.sh
RUN apk add --no-cache bash ca-certificates su-exec tzdata; \
    chmod +x /entrypoint.sh
ENV PUID=0 PGID=0 UMASK=022
EXPOSE 5244 5245
CMD [ "/entrypoint.sh" ]
