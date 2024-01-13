.PHONY: help
.DEFAULT_GOAL := help

APP=$(shell basename $(shell git remote get-url origin))
REGISTRY=dkzippa
VERSION=$(shell git describe --tags --abbrev=0)-$(shell git rev-parse --short HEAD)

DOCKER_IMG_NAME = ${REGISTRY}/${APP}:${VERSION}

help:
	@echo "Usage: make pipeline-dive img=<img>"

image:
	docker build . -t ${DOCKER_IMG_NAME}

push:	
	docker push ${DOCKER_IMG_NAME}

clean:
	rm -rf kbot
	docker rmi ${DOCKER_IMG_NAME}


pipeline-dive:
	@echo $(img)

