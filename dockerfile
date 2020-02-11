FROM golang:1.12 as build-stage

RUN set -x

RUN mkdir /build

WORKDIR /build

COPY . /build

RUN  go mod vendor  && \
     go list -e $(go list -f . -m all) && \
     CGO_ENABLED=0 go build -a -o main . && \
     groupadd -g 1001 uproxy && \
     useradd -r -u 1001 -g uproxy uproxy

#------------------------------------------------------------  << 20MB
FROM scratch as release-stage

WORKDIR /app

#multistage containers - copying from build stage /build to /app
COPY --from=build-stage /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=build-stage /build/main /app/main



#scratch is missing bash, so cannot call useradd command. That's we created user at build-stage, now we copy him to scratch
COPY --from=build-stage /etc/passwd /etc/passwd

USER uproxy

ENTRYPOINT ["./main"]


#delete all <none> images
#sudo docker rmi $(sudo docker images | grep "^<none>" | awk '{ print $3 }')
#docker container prune
#docker image prune
#docker network prune
#docker volume prune
# https://www.projectatomic.io/blog/2015/07/what-are-docker-none-none-images/
# docker rmi $(docker images -f "dangling=true" -q)



