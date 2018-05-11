.PHONY: test validate-syntax

TERRAFORM=AWS_REGION=us-east-2 terraform

test: validate-syntax

validate-syntax: .terraform
	${TERRAFORM} validate
	${TERRAFORM} fmt -check=true -diff=true

.terraform:
	${TERRAFORM} init
