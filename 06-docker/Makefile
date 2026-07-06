# Docker for Professionals - exercise runner.
#   make setup                       # (optional) pre-pull the images the course uses
#   make start  S=01-containers      # seed the scenario, then run docker in your terminal
#   make verify S=01-containers      # grade your work against the real Docker daemon
#   make reset  S=01-containers      # remove this section's containers/images and re-seed
#   make stop   S=01-containers      # clean up this section completely
#
# Unlike the other courses, Docker IS the subject here, so there is no separate
# container to enter. You run `docker ...` commands directly in your terminal
# (a Codespace already has Docker; on your own machine you need Docker installed),
# and the grader inspects the real Docker state your commands produced.

S   ?=
SRC := $(CURDIR)/$(S)
SB  := $(CURDIR)/sandbox/$(S)
export SB SRC

# Images the exercises build on. Pulled on demand by each seed, or all at once here.
IMAGES := nginx:alpine python:3-alpine python:3-slim redis:alpine postgres:16-alpine amigoscode/2048

.PHONY: setup start verify reset stop _check

setup:
	@for img in $(IMAGES); do echo "pulling $$img"; docker pull -q $$img >/dev/null; done
	@echo "Base images ready."

_check:
	@test -n "$(S)" || { echo "Set a section: make start S=01-containers"; exit 1; }
	@test -d "$(SRC)" || { echo "No such section: $(S)"; exit 1; }
	@docker info >/dev/null 2>&1 || { echo "Docker is not running. Start Docker and try again."; exit 1; }

start: _check
	@mkdir -p "$(SB)"
	@bash "$(SRC)/seed.sh"
	@echo
	@echo "Seeded $(S). Your working files (if any) are in: 06-docker/sandbox/$(S)"
	@echo "Now run the docker commands from the README in this terminal, then:"
	@echo "  make verify S=$(S)"

verify: _check
	@bash "$(SRC)/verify.sh"

reset: _check
	@bash "$(SRC)/clean.sh" >/dev/null 2>&1 || true
	@rm -rf "$(SB)"; mkdir -p "$(SB)"
	@bash "$(SRC)/seed.sh"
	@echo "Re-seeded $(S). Fresh start."

stop: _check
	@bash "$(SRC)/clean.sh" >/dev/null 2>&1 || true
	@rm -rf "$(SB)"
	@echo "Cleaned up $(S) (containers, images, volumes and networks it created)."
