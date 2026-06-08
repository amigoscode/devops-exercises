# Base image for the Git & GitHub Fundamentals exercises.
FROM ubuntu:24.04

RUN apt-get update && apt-get install -y --no-install-recommends \
      git sudo vim less ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash student \
    && echo 'student ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/student \
    && chmod 0440 /etc/sudoers.d/student

# Default new repos to the 'main' branch (what the course uses), at system level
# so it survives even when a section clears the user's ~/.gitconfig.
RUN git config --system init.defaultBranch main

ENV USER=student
ENV HOME=/home/student
WORKDIR /home/student
USER student
CMD ["/bin/bash"]
