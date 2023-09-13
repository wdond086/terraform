# TERRAFORM

## What has changed:

- Infra is provisioned via APIs.
- Servers are created and destroyed in seconds.
- We moved from long-lived and mutable to short lived and immutable.

## Provisioning Cloud Resources

- We have three approaches:
	- GUI
	- API / CLI
	- IAC
		- Great because you know exactly what the state of your infra is.
		- GitOps

## What is IAC?

- Categories of IAC tools
	- Adhoc scripts
	- Configuration management tools (Ansible, Puppet, Chef)
		- Better suited for on-prem server maintenance and configuration
	- Server templating tools
	- Orchestration tools (Kubernetes)
	- Provisioning tools
		- Declarative: You define the end state of what you want, and the tools manages how to make it happen.
		- Imperative: You define what you want and how the tool will make your desire a reality.

- IAC tools landscape
	- Cloud specific
		- Cloudformation (AWS)
		- Azure Resource Manager (Azure)
		- Google Cloud Deployment Manager (Google Cloud)
	- Cloud Agnostic
		- Terraform
		- Pulumi

## Terraform Overview and Setup

-  Common patterns
	- Terraform for Provisioning + Ansible for config management
	- Terraform got Provisioning + Packer server templating (used to build the AMI for the VM)
	- Terraform for provisioning cluster or cluster resources + Kubernetes for Orchestration

### Terraform Architecture

- Terraform core is the engine that takes the Terraform state file and the Terraform code.
- Providers tell Terraform how to map the required state to API calls for the resource required.


## GOOD TO KNOW

- Do not commit the terraform state file to version control
- You can lint terraform code using `tflint`
- You can perform static analysis of Terraform code using `tfsec` or `checkov` for security issues and compliance violations.
- Use `Terraform cloud` or `Terraform Enterprise` to manage state files and provide locking and collaboration features
- Avoid hardcoding sensitive information like passwords and API keys in your Terraform code.
- Use environment variables or a secret management tool (e.g., AWS Secrets Manager, HashiCorp Vault) to store and access secrets securely.
- Organize your Terraform code into reusable modules to promote code reuse and maintainability.
- Ensure that each module has a clear purpose and well-defined inputs and outputs.
- Store your Terraform state files securely and avoid committing them to version control.
- Use remote backends (e.g., AWS S3, Azure Blob Storage) for state management.
- Implement automated tests for your infrastructure code using tools like Terratest or Kitchen-Terraform.
- Include unit tests for custom modules and integration tests for full environments.
- Maintain documentation for your infrastructure code, including module descriptions, variable explanations, and any deployment instructions.
- Consider using tools like `terraform-docs` to generate documentation automatically.
- 

## COMMANDS TO REMEMBER

- `terraform init` - To initialize the backend
- `terraform plan` - To plan the resources to be created, altered and destroyed
- `terraform apply` - To apply the plan created by terraform plan.
- `terraform destroy` - To destroy all the resources
- `terraform fmt` - To format your terraform code
- `terraform validate` - To check for correctness and validate resource configurations
