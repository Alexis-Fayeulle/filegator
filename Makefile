# usage "make" or "make help"
# need "make" program to use this file (apt install make on linux)
# better use this on linux

# Avoid user permission errors and get user ids for all actions in the docker pod
USER_ID = $(shell id -u):$(shell id -g)
# The docker image name
DOCKER_IMG = devimage
# The command to use to simplify the calls
DOCKER_RUN = docker run -it --rm -v $(PWD):/app -v ./private/tmp/.bash_history:/tmphome/.bash_history -w /app -u $(USER_ID) $(DOCKER_IMG)

.PHONY: help
help: # Show help for each of the Makefile recipes.
	@grep -E '^[a-zA-Z0-9 -]+:.*#'  Makefile | sort | while read -r l; do printf "\033[1;32m$$(echo $$l | cut -f 1 -d':')\033[00m:$$(echo $$l | cut -f 2- -d'#')\n"; done

build-dev-img: # Build the dev docker image for the other commands, If you need to debug this, it's better to use a real command from this one
	echo "\e[0;32m------------ Building docker image in the tag $(DOCKER_IMG) ------------\e[0m"
	docker build -q -f docker/php-dev/Dockerfile.dev -t $(DOCKER_IMG) .

dev-bash: build-dev-img # For everything that need to do commands, use this
	$(DOCKER_RUN) bash

install-libs-backend: build-dev-img # Install backend libs
	echo "\e[0;32m------------ Install backend libs (composer install) ------------\e[0m"
	$(DOCKER_RUN) composer --quiet install

re-install-libs-backend: build-dev-img # Re-install backend libs
	echo "\e[0;32m------------ Delete backend libs (vendor) ------------\e[0m"
	$(DOCKER_RUN) rm -rf vendor
	$(MAKE) install-libs-backend

phpunit: install-libs-backend # Execute PHP Unit tests
	echo "\e[0;32m------------ Execute backend tests ------------\e[0m"
	$(DOCKER_RUN) php vendor/bin/phpunit --testdox

phpunit-coverage: install-libs-backend # Execute PHP Unit tests with coverage in ./private/tmp/coverage
	echo "\e[0;32m------------ Execute backend tests with coverage ------------\e[0m"
	rm -rf ./private/tmp
	mkdir ./private/tmp
	chmod 664 ./private/tmp
	$(DOCKER_RUN) php -d xdebug.mode=coverage vendor/bin/phpunit --testdox --coverage-html ./private/tmp/coverage

phpstan: install-libs-backend # Execute PHPStan for code quality
	echo "\e[0;32m------------ Execute backend code quality (phpstan) ------------\e[0m"
	$(DOCKER_RUN) php vendor/bin/phpstan analyse ./backend

phpcs: install-libs-backend # Execute PHP CS for code quality
	echo "\e[0;32m------------ Execute backend code quality (php-cs) ------------\e[0m"
	$(DOCKER_RUN) php vendor/bin/php-cs-fixer fix --dry-run --verbose --diff

test: build-dev-img re-install-libs-backend phpcs phpstan phpunit-coverage # Test everything