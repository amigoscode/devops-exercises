# Linux Fundamentals - exercise runner.
# Usage:
#   make build              # build the base image once
#   make start S=08-file-permissions    # pristine Ubuntu shell, scenario seeded
#   make verify S=08-file-permissions   # auto-grade your work
#   make reset S=08-file-permissions    # wipe and re-seed (fresh start)
#   make stop  S=08-file-permissions    # remove the container

IMAGE := linux-fundamentals
S     ?=
CONTAINER := lf-$(S)

.PHONY: build start verify reset stop _check

build:
	docker build -t $(IMAGE) .

_check:
	@test -n "$(S)" || { echo "Set a section: make start S=08-file-permissions"; exit 1; }
	@test -d "$(S)" || { echo "No such section: $(S)"; exit 1; }

# Start (or re-enter) a container for a section, seeding the scenario on first run.
start: _check
	@docker inspect $(CONTAINER) >/dev/null 2>&1 || \
	  docker run -dit --name $(CONTAINER) \
	    -v "$(CURDIR)/$(S)":/exercise:ro \
	    $(IMAGE) >/dev/null
	@docker exec $(CONTAINER) bash -lc 'test -d ~/sandbox || (cp -r /exercise/seed ~/seed 2>/dev/null; bash /exercise/seed.sh)' 2>/dev/null || \
	  docker exec $(CONTAINER) bash -lc 'bash /exercise/seed.sh'
	@echo "Entering $(S). Your work lives in ~/sandbox. Type 'exit' to leave (state is kept)."
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
