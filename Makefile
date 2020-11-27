.PHONY: help clean test
.DEFAULT_GOAL := help

DOCKER_REPO="ovalmoney/celery-exporter"
DOCKER_VERSION="latest"

define PRINT_HELP_PYSCRIPT
import re, sys

for line in sys.stdin:
	match = re.match(r'^([a-zA-Z_-]+):.*?## (.*)$$', line)
	if match:
		target, help = match.groups()
		print("%-20s %s" % (target, help))
endef
export PRINT_HELP_PYSCRIPT

all: clean test docker_build ## Clean and Build

clean: ## Clean folders
	rm -rf dist/ *.egg-info

test: ## Run tests and coverage
	coverage run -m pytest test/ \
  && coverage report

docker_build: ## Build Docker file
	export DOCKER_REPO
	export DOCKER_VERSION

	docker build \
		--build-arg DOCKER_REPO=${DOCKER_REPO} \
		--build-arg VERSION=${DOCKER_VERSION} \
		--build-arg VCS_REF=`git rev-parse --short HEAD` \
		--build-arg BUILD_DATE=`date -u +”%Y-%m-%dT%H:%M:%SZ”` \
		-f ./Dockerfile \
		-t ${DOCKER_REPO}:${DOCKER_VERSION} \
		.

help: ## Print this help
	@python -c "$$PRINT_HELP_PYSCRIPT" < $(MAKEFILE_LIST)

### linkbusters custom stuff goes below
VERSION=2.0.0
ECR_PRD=318399264588.dkr.ecr.eu-west-1.amazonaws.com

docker_build: ## Build docker image
	docker build . -t celery-exporter:${VERSION}

docker_tag_prd: ## Tag docker image with production repo url
	docker tag celery-exporter:${VERSION} ${ECR_PRD}/celery-exporter:${VERSION}

docker_push_prd: ## Push docker image to production
	docker push ${ECR_PRD}/celery-exporter:${VERSION}

docker_push_all: docker_build docker_tag_prd docker_push_prd ## Build docker image and push it to all configured repos
