#Push to DockerHub - Most vars can be ovewritten with ENV vars (like Jenkins)
BUILD_DATE ?= $(strip $(shell date -u +"%Y-%m-%dT%H:%M:%SZ"))
VENDOR ?= elhindi
PROJECT_NAME ?= notejam
DOCKER_IMAGE ?= $(VENDOR)/${PROJECT_NAME}
ENVIRONMENT ?= dev
GIT_TAG ?= $(strip $(shell git rev-parse --abbrev-ref HEAD | sed -e "s/\//_/g"))
GIT_COMMIT = $(strip $(shell git rev-parse --short HEAD))
GIT_URL ?= $(strip $(shell git config --get remote.origin.url))

#Application Configuration
#These values are set in .secret when secret is run, should be set as environment variables with production values.
db_host ?= 
db_user ?= 
db_password ?= 
db_name ?= 
db_port ?=

#List of macros
default: build
build: docker_build output
push: docker_push
secret: create_secret update_secret
deploy: secret build docker_push kube_deploy output

#Set DOCKER_TAG
DOCKER_TAG ?= $(GIT_TAG)-$(GIT_COMMIT)

#Create k8s secret from RDS environment variables
define SECRET
apiVersion: v1
kind: Secret
metadata:
  name: notejam
  namespace: default
stringData:
	db_host: $(db_host)
	db_name: $(db_name)
	db_user: $(db_user)
  db_password: $(db_password)
	db_port: $(db_port)
endef
export SECRET

create_secret:
	@echo "$$SECRET" > .secret

update_secret:
	kubectl apply -f .secret --validate=false --force=true

docker_build:
	# Build Docker image
	docker build -t $(DOCKER_IMAGE):$(DOCKER_TAG) .

docker_push:
	# Push to DockerHub
	docker push $(DOCKER_IMAGE):$(DOCKER_TAG)

kube_deploy:
	# Update container tag and deploy application
	sed -i.bak -e "s/DOCKER_TAG/$(DOCKER_TAG)/g" ./deployment.yaml
	kubectl apply -f ./deployment.yaml

output:
	@echo Docker Image: $(DOCKER_IMAGE):$(DOCKER_TAG)
