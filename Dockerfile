# Step 1: Get the version number
FROM alpine AS version
WORKDIR /build
RUN echo "v2.0.0" > ./version  

# Step 2: Build the web interface
FROM ghcr.io/library/node:lts-alpine AS builder-web
ADD gui /build/gui
WORKDIR /build/gui
RUN yarn cache clean && yarn && yarn build

# Step 3: Build the V2Ray service
FROM golang:alpine AS builder
ADD service /build/service
WORKDIR /build/service
COPY --from=version /build/version ./
COPY --from=builder-web /build/web server/router/web
RUN export VERSION=$(cat ./version) && CGO_ENABLED=0 go build -o v2raya .

# Step 4: Run V2Ray on a proper base image
FROM ghcr.io/v2fly/v2fly-core AS runtime
COPY --from=builder /build/service/v2raya /usr/bin/
RUN apk add --no-cache iptables ip6tables tzdata
EXPOSE 2017
ENTRYPOINT ["v2raya"]
