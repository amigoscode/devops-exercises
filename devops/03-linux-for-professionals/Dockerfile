# Base image for the Linux for Professionals exercises.
# Includes the data-manipulation, sysadmin and networking tools the course uses.
FROM ubuntu:24.04

RUN apt-get update && apt-get install -y --no-install-recommends \
      sudo vim less grep findutils coreutils sed gawk \
      jq procps curl ca-certificates iproute2 python3 \
      openssh-client \
    && rm -rf /var/lib/apt/lists/*

# Non-root "student" with passwordless sudo, like the other courses.
RUN useradd -m -s /bin/bash student \
    && echo 'student ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/student \
    && chmod 0440 /etc/sudoers.d/student

ENV USER=student
ENV HOME=/home/student
WORKDIR /home/student
USER student
CMD ["/bin/bash"]
