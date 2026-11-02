# One image for the SQL courses: real Ubuntu + a real PostgreSQL server, the same
# for every student whether they're on Mac, Windows or Linux.
FROM ubuntu:24.04

RUN apt-get update && apt-get install -y --no-install-recommends \
      postgresql postgresql-contrib sudo nano vim less ca-certificates locales \
    && sed -i 's/^# *en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen && locale-gen \
    && rm -rf /var/lib/apt/lists/*
ENV LANG=en_US.UTF-8

# A non-root "student" who can sudo - mirrors a real Linux box.
RUN useradd -m -s /bin/bash student \
    && echo 'student ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/student \
    && chmod 0440 /etc/sudoers.d/student

# A Postgres role and database named after you, so plain `psql` just works (the
# same peer login you'd set up on your own machine). Superuser, because the courses
# create databases, roles and extensions.
RUN service postgresql start \
    && su postgres -c "createuser --superuser student" \
    && su postgres -c "createdb -O student student" \
    && service postgresql stop

# The container starts the server, then hands over to your shell. A restart (Docker
# or your machine rebooting) starts it again, so your databases are always there.
COPY start-postgres.sh /usr/local/bin/start-postgres
RUN chmod 755 /usr/local/bin/start-postgres

ENV USER=student
ENV HOME=/home/student
WORKDIR /home/student
USER student
ENTRYPOINT ["/usr/local/bin/start-postgres"]
CMD ["/bin/bash"]
