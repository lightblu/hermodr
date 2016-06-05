DOCKERNS = lightblu
NAME ?= hermodr
VERSION ?= latest
BASEDIR := $(shell pwd)
IMAGE_NAME := $(DOCKERNS)/$(NAME):b$(TRAVIS_BUILD_NUMBER)
IMAGE_NAME_DEV := $(DOCKERNS)/$(NAME)-dev:$(shell echo $(VERSION) | sed "s/\//-/g")
HOSTNAME := $(shell hostname)

TMP_CONTAINER_NAME := $(NAME)-$(shell /bin/date "+%Y%m%d%H%M%S")

.PHONY: help docker push devrootrun devrun deventer build-release push-release

##### HELP ####################################################################
# Nice self-documenting makefile approach via
# http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

##### DOCKER ##################################################################

docker: ## Build docker image
	docker build -t $(IMAGE_NAME_DEV) .

###############################################################################

devrootrun:
	docker run -ti -p 8080:8080 -v $(BASEDIR):/opt/hermodr --rm $(IMAGE_NAME_DEV) /bin/bash
	sudo chown -R $USER:$USER .

devrun: ## Run container shell for dev
	docker run -ti --rm \
				-u $(shell id -u) -p 8080:8080 \
				-e HOME=/tmp -v $(BASEDIR):/opt/hermodr \
				$(IMAGE_NAME_DEV) /bin/bash

deventer: ## Enter running container from devrun in another shell
	docker exec -ti $(shell docker ps | grep $(IMAGE_NAME_DEV) | awk '{print $$1}') /bin/bash


build-release:
	docker create --name hermodr_build $(IMAGE_NAME_DEV)
	docker cp hermodr_build:/opt/hermodr/dist/build/hermodr/hermodr ./release
	docker rm -v hermodr_build
	docker build -t $(IMAGE_NAME) ./release

push-release:
	@docker login -e="$(DOCKER_EMAIL)" -u="$(DOCKER_USERNAME)" -p="$(DOCKER_PASSWORD)"
	docker push $(IMAGE_NAME)
