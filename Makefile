ifndef CNTR
CNTR=podman
endif

ifdef SSH_AUTH
SSH_AUTH_OPT=--mount type=bind,source=$(SSH_AUTH),target=/root/.ssh
endif

help:
	@echo "Makefile for epiforecasts"
	@echo ""
	@echo "  help  : show this help."
	@echo "  build : build the container."
	@echo "  run   : run the container."


build:
	$(CNTR) build -t epiforecasts -f .devcontainer/Dockerfile

run:
	$(CNTR) run -it --rm \
		--mount type=bind,source=$(shell pwd),target=/workspace \
		$(SSH_AUTH_OPT) \
		-w/workspace epiforecasts

run_git:
	$(MAKE) run SSH_AUTH=$(HOME)/.ssh

.PHONY: help build run