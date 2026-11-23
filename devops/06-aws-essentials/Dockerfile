# The exercise runner for Windows students.
#
# Docker is the only thing you install for this course. On macOS/Linux the runner
# script runs natively in bash; on Windows there is no bash, so this tiny image
# provides one. It drives YOUR Docker daemon through the mounted socket to start
# the AWS CLI container that checks your account.
FROM alpine:3.20
RUN apk add --no-cache bash docker-cli
WORKDIR /course
ENTRYPOINT ["bash", "/course/runner.sh"]
