SHELL := /bin/bash

# List of targets the `readme` target should call before generating the readme
export README_DEPS ?= docs/targets.md docs/terraform.md

-include $(shell curl -sSL -o .build-harness "https://raw.githubusercontent.com/carnegierobotics/build-harness/carnegierobotics/templates/Makefile.build-harness"; echo .build-harness)

lint:
	$(SELF) terraform/install terraform/get-modules terraform/get-plugins terraform/lint terraform/validate

example:
	@cd examples/complete && terraform init && terraform plan
