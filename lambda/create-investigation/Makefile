.PHONY: clean deps build test help

# Variables
CONTAINER_RUNTIME ?= podman
LAMBDA_RUNTIME = public.ecr.aws/lambda/python:3.11
FUNCTION_DIR = $(shell pwd)
REQUIREMENTS = requirements.txt

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

clean: ## Remove build artifacts and dependencies
	@echo "Cleaning build artifacts..."
	rm -rf ./__pycache__
	rm -rf ./bin
	rm -rf ./boto*
	rm -rf ./certifi*
	rm -rf ./cffi*
	rm -rf ./charset_normalizer*
	rm -rf ./cryptography*
	rm -rf ./dateutil*
	rm -rf ./idna*
	rm -rf ./jmespath*
	rm -rf ./jwt*
	rm -rf ./pycparser*
	rm -rf ./python_dateutil*
	rm -rf ./PyJWT*
	rm -rf ./requests*
	rm -rf ./s3transfer*
	rm -rf ./six*
	rm -rf ./urllib3*
	rm -rf ./*.dist-info
	rm -rf ./*.so
	rm -rf ./package
	@echo "Clean complete"

deps: clean ## Install Lambda dependencies using container runtime (Linux-compatible)
	@echo "Installing Lambda dependencies using AWS Lambda container image (x86_64)..."
	@echo "Using container runtime: $(CONTAINER_RUNTIME)"
	$(CONTAINER_RUNTIME) run --rm \
		--platform linux/amd64 \
		--entrypoint "" \
		-v "$(FUNCTION_DIR)":/var/task:Z \
		$(LAMBDA_RUNTIME) \
		pip install -t /var/task -r /var/task/$(REQUIREMENTS) --no-cache-dir
	@echo "Dependencies installed"

deps-local: clean ## Install dependencies locally (for local testing only - not Lambda compatible on macOS)
	@echo "Installing dependencies locally (not Lambda-compatible)..."
	pip3 install -t . -r $(REQUIREMENTS)
	@echo "Local dependencies installed"

build: deps ## Build Lambda deployment package (install deps + verify)
	@echo "Verifying Lambda package..."
	@test -f handler.py || (echo "Error: handler.py not found" && exit 1)
	@test -d jwt || (echo "Error: jwt module not found - run 'make deps' first" && exit 1)
	@test -d cryptography || (echo "Error: cryptography module not found - run 'make deps' first" && exit 1)
	@echo "Lambda package ready for deployment"
	@echo "Files in package:"
	@ls -lh | grep -E "handler|jwt|crypto|requests" | awk '{print "  " $$9 " (" $$5 ")"}'

test-local: ## Test handler locally (requires deps-local)
	@echo "Testing Lambda handler locally..."
	python3 -c "import handler; print('Handler imports successfully')"

validate: ## Validate handler syntax
	@echo "Validating Python syntax..."
	python3 -m py_compile handler.py
	@echo "Syntax valid"

deploy: build ## Build and trigger Terraform deployment
	@echo "Lambda package built. Run 'terraform apply' in deploy/regional to deploy"
	@echo "Or run: cd ../../deploy/regional && terraform apply"
