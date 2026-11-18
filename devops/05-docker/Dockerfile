# The exercise runner for Windows students.
#
# Docker is the only thing you install for this course. On macOS/Linux the runner
# scripts run natively in bash; on Windows there is no bash, so this tiny image
# provides one. It talks to YOUR Docker daemon through the mounted socket, so the
# containers, images and volumes it inspects are the real ones on your machine.
FROM alpine:3.20
RUN apk add --no-cache bash docker-cli docker-cli-compose curl grep
WORKDIR /course
ENTRYPOINT ["bash", "/course/runner.sh"]
