# One base image for the Vim exercise set. Vim is the only editor guaranteed to be
# on every Linux server, so this is the environment you'll really edit configs in.
FROM ubuntu:24.04

RUN apt-get update && apt-get install -y --no-install-recommends \
      vim sudo ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# A non-root "student" user with passwordless sudo, like the other courses.
RUN useradd -m -s /bin/bash student \
    && echo 'student ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/student \
    && chmod 0440 /etc/sudoers.d/student

ENV USER=student
ENV HOME=/home/student
WORKDIR /home/student
USER student
CMD ["/bin/bash"]
