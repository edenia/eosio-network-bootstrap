include mkutils/meta.mk mkutils/help.mk

BUILDS_DIR ?= ./.builds

apply-kubernetes: ###devops Applies kubernetes configurations based on source files
apply-kubernetes:
	@echo "Creating the configmaps for config files of each role..."
	@mkdir -p /tmp/$(VERSION)/
	@kubectl create ns blockchain || echo "Namespace 'blockchain' already exists.";
	@kubectl create configmap \
		api-node-config \
		--from-file configs/api-node/ \
		--dry-run=client \
		-o yaml | \
		yq w - metadata.labels.version $(VERSION) | \
		kubectl -n blockchain apply -f -
	@$(SHELL_EXPORT) envsubst <./configs/genesis/genesis.json > /tmp/$(VERSION)/genesis.json
	@kubectl create configmap \
		genesis-config \
		--from-file /tmp/$(VERSION)/genesis.json \
		--dry-run=client \
		-o yaml | \
		yq w - metadata.labels.version $(VERSION) | \
		kubectl -n blockchain apply -f -
	@$(SHELL_EXPORT) envsubst <./configs/bios/schedule.json > /tmp/$(VERSION)/schedule.json
	@kubectl create configmap \
		schedule-config \
		--from-file /tmp/$(VERSION)/schedule.json \
		--dry-run=client \
		-o yaml | \
		yq w - metadata.labels.version $(VERSION) | \
		kubectl -n blockchain apply -f -
	@kubectl create configmap \
		bios-config \
		--from-file configs/bios/ \
		--dry-run=client \
		-o yaml | \
		yq w - metadata.labels.version $(VERSION) | \
		kubectl -n blockchain apply -f -
	@kubectl create configmap \
		seed-config \
		--from-file configs/seed/ \
		--dry-run=client \
		-o yaml | \
		yq w - metadata.labels.version $(VERSION) | \
		kubectl -n blockchain apply -f -
	@kubectl create configmap \
		validator-scripts \
		--from-file configs/validator/ \
		--dry-run=client \
		-o yaml | \
		yq w - metadata.labels.version $(VERSION) | \
		kubectl -n blockchain apply -f -
	@kubectl create configmap \
		validator1-config \
		--from-file configs/validator1/ \
		--dry-run=client \
		-o yaml | \
		yq w - metadata.labels.version $(VERSION) | \
		kubectl -n blockchain apply -f -
	@kubectl create configmap \
		validator2-config \
		--from-file configs/validator2/ \
		--dry-run=client \
		-o yaml | \
		yq w - metadata.labels.version $(VERSION) | \
		kubectl -n blockchain apply -f -
	@kubectl create configmap \
		validator3-config \
		--from-file configs/validator3/ \
		--dry-run=client \
		-o yaml | \
		yq w - metadata.labels.version $(VERSION) | \
		kubectl -n blockchain apply -f -
	@kubectl create configmap \
		wallet-config \
		--from-file configs/wallet/ \
		--dry-run=client \
		-o yaml | \
		yq w - metadata.labels.version $(VERSION) | \
		kubectl -n blockchain apply -f -
	@echo "Applying kubernetes configuartions for blockchain nodes..."
	@$(SHELL_EXPORT) envsubst <./kubernetes/api-node/api-node.service.yml | kubectl -n blockchain apply -f -;
	@$(SHELL_EXPORT) envsubst <./kubernetes/api-node/api-node.statefulset.yml | kubectl -n blockchain apply -f -;
	@$(SHELL_EXPORT) envsubst <./kubernetes/bios/bios.service.yml | kubectl -n blockchain apply -f -;
	@$(SHELL_EXPORT) envsubst <./kubernetes/bios/bios.statefulset.yml | kubectl -n blockchain apply -f -;
	@$(SHELL_EXPORT) envsubst <./kubernetes/seed/seed.service.yml | kubectl -n blockchain apply -f -;
	@$(SHELL_EXPORT) envsubst <./kubernetes/seed/seed.statefulset.yml | kubectl -n blockchain apply -f -;
	@$(SHELL_EXPORT) VALIDATOR_COUNT=1 envsubst <./kubernetes/validator/validator.service.yml | kubectl -n blockchain apply -f -;
	@$(SHELL_EXPORT) VALIDATOR_COUNT=1 envsubst <./kubernetes/validator/validator.statefulset.yml | kubectl -n blockchain apply -f -;
	@$(SHELL_EXPORT) VALIDATOR_COUNT=2 envsubst <./kubernetes/validator/validator.service.yml | kubectl -n blockchain apply -f -;
	@$(SHELL_EXPORT) VALIDATOR_COUNT=2 envsubst <./kubernetes/validator/validator.statefulset.yml | kubectl -n blockchain apply -f -;
	@$(SHELL_EXPORT) VALIDATOR_COUNT=3 envsubst <./kubernetes/validator/validator.service.yml | kubectl -n blockchain apply -f -;
	@$(SHELL_EXPORT) VALIDATOR_COUNT=3 envsubst <./kubernetes/validator/validator.statefulset.yml | kubectl -n blockchain apply -f -;
	@$(SHELL_EXPORT) envsubst <./kubernetes/wallet/wallet.service.yml | kubectl -n blockchain apply -f -;
	@$(SHELL_EXPORT) envsubst <./kubernetes/wallet/wallet.statefulset.yml | kubectl -n blockchain apply -f -;
	@$(SHELL_EXPORT) envsubst <./kubernetes/nodeos-secrets.configmap.yml | kubectl -n blockchain apply -f -;
	@$(SHELL_EXPORT) envsubst <./kubernetes/nodeos.storageclass.yml | kubectl -n blockchain apply -f -;
	@$(SHELL_EXPORT) envsubst <./kubernetes/api.ingress.yml | kubectl -n blockchain apply -f -;

delete-kubernetes:
	@kubectl delete service,pv,pvc,statefulset,configmap -l version=$(VERSION)

build: ##@devops Builds a new  production docker image
build:
	@docker build \
		--target prod-stage \
		-t $(DOCKER_REGISTRY)/$(IMAGE_NAME):$(VERSION) \
		.

publish-docker: ##@devops Publishes latest built docker image
publish-docker:
	@echo $(DOCKER_PASSWORD) | docker login \
		--username $(DOCKER_USERNAME) \
		--password-stdin
	@docker push $(DOCKER_REGISTRY)/$(IMAGE_NAME):$(VERSION)

build-docker-compose: ##@local Build local docker-compose
	@rm -Rf $(BUILDS_DIR)/docker-compose.yml
	@mkdir -p $(BUILDS_DIR)
	@$(SHELL_EXPORT) envsubst <docker-compose.yml >$(BUILDS_DIR)/docker-compose.yml

run-vault: ##@local Only run the vault service
run-vault: build-docker-compose
	@docker-compose -f $(BUILDS_DIR)/docker-compose.yml up -d vault

run: ##@local Build and run the blockchain locally (validator, wallet and writer-api)
run: build-docker-compose
	@docker-compose -f $(BUILDS_DIR)/docker-compose.yml up -d --build
ifeq (,$(wildcard vault_keys.json))
	@echo "Generating vault keys... [vault_keys.json]"
	@sleep 5
	@curl \
		-X PUT \
		-d '{"secret_shares": 10, "secret_threshold": 5}' \
		http://localhost:8200/v1/sys/init | jq -r . > vault_keys.json
else
	@echo 'Vault keys already exist.'
endif
	@echo "Unsealing the vault..."
	@for key in $(shell jq -r '.keys_base64[5:][]' vault_keys.json); do \
		curl \
			-X PUT \
			-d "{\"key\": \"$$key\"}" \
			http://localhost:8200/v1/sys/unseal; \
	done

logs: ##@local Show logs from bios node
	@docker-compose -f $(BUILDS_DIR)/docker-compose.yml logs -f bios

stop: ##@local Stop all instances of the currently running services
	@docker-compose -f $(BUILDS_DIR)/docker-compose.yml stop

down: ##@local Stop all instances of the currently running services
	@docker-compose -f $(BUILDS_DIR)/docker-compose.yml down

