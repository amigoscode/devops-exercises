# Amigoscode Academy - the terminal UI, packaged so Docker is the only
# thing a student installs. ./academy.sh (or academy.cmd) builds and runs this.
FROM golang:1.23-alpine AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY *.go ./
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /academy .

# The runtime talks to the student's Docker daemon through the mounted socket, and
# carries bash + the Docker CLI so the Docker course scripts run exactly as on a Mac.
FROM alpine:3.20
RUN apk add --no-cache bash docker-cli docker-cli-compose curl grep
COPY --from=build /academy /usr/local/bin/academy
ENV ACADEMY_IN_DOCKER=1 \
    TERM=xterm-256color \
    COLORTERM=truecolor
ENTRYPOINT ["academy"]
