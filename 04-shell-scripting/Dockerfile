# Base image for the Shell Scripting exercises - a plain Ubuntu with bash + the
# everyday tools scripts call (coreutils gives md5sum/sha256sum, procps gives ps).
FROM ubuntu:24.04

RUN apt-get update && apt-get install -y --no-install-recommends \
      bash coreutils procps sudo vim less ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash student \
    && echo 'student ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/student \
    && chmod 0440 /etc/sudoers.d/student

ENV USER=student
ENV HOME=/home/student
WORKDIR /home/student
USER student
CMD ["/bin/bash"]
