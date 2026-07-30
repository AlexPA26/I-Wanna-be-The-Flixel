FROM alpine:latest
WORKDIR /app
COPY server_linux /app/server_linux
EXPOSE 22336/udp
EXPOSE 22336/tcp
ENTRYPOINT ["/app/server_linux", "22336"]
