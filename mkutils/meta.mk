-include .env

VERSION ?= $(shell git ls-files -s kubernetes services Dockerfile | git hash-object --stdin)

IMAGE_NAME=eosio-nodeos
MAKE_ENV += VERSION IMAGE_NAME

SHELL_EXPORT := $(foreach v,$(MAKE_ENV),$(v)='$($(v))')
K8S_BUILD_DIR ?= ./build_k8s
K8S_FILES := $(shell find ./kubernetes -name '*.yml' | sed 's:./kubernetes/::g')

ifneq ("$(wildcard .env)", "")
	export $(shell sed 's/=.*//' .env)
endif
