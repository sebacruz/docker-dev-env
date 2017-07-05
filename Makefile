.PHONY: build up setup open clean

DOCKER_COMPOSE	?= docker-compose
DOCKER_HOST     ?= localhost

PHP_SERVICE		?= php
WEB_SERVICE		?= nginx

export BUILD_PREFIX	?= $(shell echo $(notdir $(PWD)) | tr -dc '[:alnum:]\n\r' | tr '[:upper:]' '[:lower:]')
export IMAGE_TAG	?= :$(BUILD_PREFIX)

UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S), Darwin)
	OPEN_CMD        ?= open
	DOCKER_HOST_IP  ?= $(shell echo $(DOCKER_HOST) | sed 's/tcp:\/\///' | sed 's/:[0-9.]*//')
else
	OPEN_CMD        ?= xdg-open
	DOCKER_HOST_IP  ?= 127.0.0.1
endif

default: help

all:	##@development shorthand for 'build up setup open'
all: build up setup open
all:
	#
	# make all
	# Done.

build:	##@docker build application images
	#
	# Building images from docker-compose definitions
	#
	cp -n .env.dist .env &2>/dev/null
	$(DOCKER_COMPOSE) build --pull

up:	##@docker start application
	#
	# Starting application stack
	#
	$(DOCKER_COMPOSE) up -d
	$(DOCKER_COMPOSE) ps

clean: ##@base remove all containers in stack
	#
	# Cleaning Docker environment
	#
	$(DOCKER_COMPOSE) kill
	$(DOCKER_COMPOSE) rm -fv
	$(DOCKER_COMPOSE) down --remove-orphans

setup:	##@base run application setup
	#
	# Running application setup command (database, user)
	#
	$(DOCKER_COMPOSE) run --rm php composer install

bash:	##@development run application bash in one-off container
	#
	# Starting application bash
	#
	$(DOCKER_COMPOSE) run --rm php bash

exec:	 ##@development execute command (c='artisan help') in running container
	#
	# Running command
	# Note: Make sure the application container is running
	#
	$(DOCKER_COMPOSE) exec php $(c)

update:	##@development update application package, pull, rebuild
	#
	# Running package upgrade in container
	#
	$(DOCKER_COMPOSE) run --rm php composer update -v

open: ##@base open application web service in browser
	#
	# Opening application on mapped web-service port
	#
	$(OPEN_CMD) http://$(DOCKER_HOST_IP):$(shell $(DOCKER_COMPOSE) port php 80 | sed 's/[0-9.]*://')

# Help based on https://gist.github.com/prwhite/8168133 thanks to @nowox and @prwhite
# And add help text after each target name starting with '\#\#'
# A category can be added with @category

HELP_FUN = \
		%help; \
		while(<>) { push @{$$help{$$2 // 'options'}}, [$$1, $$3] if /^([\w-]+)\s*:.*\#\#(?:@([\w-]+))?\s(.*)$$/ }; \
		print "\nusage: make [target ...]\n\n"; \
	for (keys %help) { \
		print "$$_:\n"; \
		for (@{$$help{$$_}}) { \
			$$sep = "." x (25 - length $$_->[0]); \
			print "  $$_->[0]$$sep$$_->[1]\n"; \
		} \
		print "\n"; }

help: ##@system show this help
	#
	# General targets
	#
	@perl -e '$(HELP_FUN)' $(MAKEFILE_LIST)
