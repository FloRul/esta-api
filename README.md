# GitHub Actions Workflow for AWS ECR and Terraform

This repository contains a GitHub Actions workflow that automates the process of building, tagging, and pushing Docker images to an Amazon Elastic Container Registry (ECR) repository, and setting up Terraform.

## Workflow Steps

1. **Checkout**: Checks out your repository under `$GITHUB_WORKSPACE`, so your workflow can access it.

2. **Configure AWS credentials**: Configures AWS credentials with the help of `aws-actions/configure-aws-credentials@v1` action. The AWS credentials are stored as secrets in the repository.

3. **Login to Amazon ECR**: Logs in to the Amazon ECR.

4. **Create ECR repository if it doesn't exist**: Checks if the specified ECR repository exists, if not, it creates a new one.

5. **Build, tag, and push image to Amazon ECR**: Builds a Docker image from the Dockerfile present in `./modules/inference/chat/src`, tags it with 'latest', and pushes it to the ECR repository.

6. **Set up Python 3.11**: Sets up Python 3.11 in the runner environment using `actions/setup-python@v5`.

7. **Install dependencies**: Upgrades pip to the latest version.

8. **Create Python alias**: Creates an alias for Python 3.11.

9. **Setup Terraform**: Sets up Terraform using `hashicorp/setup-terraform@v3`.

## Deployment

The `deploy-api-infra` job runs only if the current branch is 'dev'.

## Prerequisites

- AWS Account
- Dockerfile in `./modules/inference/chat/src`
- AWS Access Key ID and Secret Access Key stored as secrets in the repository
- Terraform scripts for infrastructure setup

## Usage

To use this workflow, you need to set the following secrets in your GitHub repository:

- `AWS_ACCESS_KEY_ID`: Your AWS Access Key ID
- `AWS_SECRET_ACCESS_KEY`: Your AWS Secret Access Key

You also need to replace `vars.INFERENCE_CHAT_ECR` with your ECR repository name.

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.
