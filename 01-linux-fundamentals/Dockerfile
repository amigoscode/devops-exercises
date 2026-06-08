# One base image for the whole Linux Fundamentals exercise set.
# Real Ubuntu, real Linux user tooling - the same environment for every student,
# regardless of whether they're on Mac, Windows, or Linux.
FROM ubuntu:24.04

# Core tools the course uses + quality-of-life
RUN apt-get update && apt-get install -y --no-install-recommends \
      sudo adduser zsh nano vim less zip unzip tree man-db manpages curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Ubuntu's base image is "minimized": man pages are stripped AND /usr/bin/man is
# replaced by a stub (the real binary is diverted to /usr/bin/man.REAL). Section 9
# is all about `man`/`apropos`, so fully restore them:
#   1. drop the docs-exclude rule so reinstalled packages keep their man pages
#   2. reinstall the packages whose commands the course uses
#   3. undo the `man` diversion to bring back the real binary
#   4. build the apropos/whatis index
RUN rm -f /etc/dpkg/dpkg.cfg.d/excludes \
    && apt-get update \
    && apt-get install -y --reinstall --no-install-recommends \
         coreutils man-db manpages \
    && if [ -e /usr/bin/man.REAL ]; then \
         rm -f /usr/bin/man && dpkg-divert --remove --rename /usr/bin/man; \
       fi \
    && mandb -q \
    && rm -rf /var/lib/apt/lists/*

# A non-root "student" who can sudo - mirrors a real Linux box.
RUN useradd -m -s /bin/bash student \
    && echo 'student ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/student \
    && chmod 0440 /etc/sudoers.d/student

# Exercises mount in at /exercise (read-only) and work happens in /home/student/sandbox.
# Containers don't run login/PAM, so USER/HOME aren't set automatically - set them
# so $USER works exactly like it would on a real machine.
ENV USER=student
ENV HOME=/home/student
WORKDIR /home/student
USER student
CMD ["/bin/bash"]
