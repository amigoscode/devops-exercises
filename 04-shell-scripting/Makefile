# Shell Scripting - exercise runner.
#   make build
#   make start  S=01-bash-basics
#   make verify S=01-bash-basics
#   make reset  S=01-bash-basics
#   make stop   S=01-bash-basics

IMAGE := shell-scripting-exercises
S     ?=
CONTAINER := sh-$(S)

.PHONY: build start verify reset stop _check

build:
	docker build -t $(IMAGE) .

_check:
	@test -n "$(S)" || { echo "Set a section: make start S=01-bash-basics"; exit 1; }
	@test -d "$(S)" || { echo "No such section: $(S)"; exit 1; }

start: _check
	@docker inspect $(CONTAINER) >/dev/null 2>&1 || \
	  docker run -dit --name $(CONTAINER) \
	    -v "$(CURDIR)/$(S)":/exercise:ro \
	    $(IMAGE) >/dev/null
	@docker exec $(CONTAINER) bash -lc 'test -d ~/sandbox || bash /exercise/seed.sh'
	@echo "Entering $(S). Write your scripts in ~/sandbox. Type 'exit' to leave."
	docker exec -it -w /home/student/sandbox $(CONTAINER) bash

verify: _check
	@docker exec -w /home/student/sandbox $(CONTAINER) bash /exercise/verify.sh

reset: _check
	@docker exec $(CONTAINER) bash -lc 'rm -rf ~/sandbox' 2>/dev/null || true
	@docker exec $(CONTAINER) bash -lc 'bash /exercise/seed.sh'
	@echo "Re-seeded $(S). Fresh sandbox ready."

stop: _check
	-docker rm -f $(CONTAINER) >/dev/null 2>&1
	@echo "Removed container for $(S)."
