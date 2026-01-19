# AWS Infrastructure as Code with Terraform & GitHub Actions


## Project Overview

This project demonstrates a production-grade **GitOps** workflow for deploying AWS infrastructure. It uses **Terraform** to define resources (specifically SQS queues for alert management) and **GitHub Actions** to automatically plan and apply changes.

The pipeline is secured using **OpenID Connect (OIDC)**, eliminating the need for long-lived AWS access keys. It follows the **Principle of Least Privilege**, ensuring the CI/CD robot can only modify specific resources.


## Architecture & Workflow

1.  **Develop:** Infrastructure changes are made in a feature branch.
2.  **Plan:** Opening a Pull Request triggers `terraform plan`. The bot posts the plan as a comment on the PR for review to detect unintended changes before they reach production.
3.  **Apply:** Merging to the `main` branch triggers `terraform apply`, deploying the changes to AWS.
4.  **Security:** Authentication is handled via AWS OIDC Identity Provider.State Locking: Prevents concurrent writes using S3 locking mechanism.
 

## Repository Structure

```text
MLD_Data_Engineering_portfolio/          <-- ROOT of Repository
├── .github/
│   └── workflows/
│       └── terraform.yml                <-- The CI/CD Automation
│
└── project14-IaC_CICD_GithubActions/    <-- Project Source Code
    ├── backend.tf
    ├── main.tf
    ├── providers.tf
    ├── variables.tf
    ├── .gitignore
    └── bootstrap/                       <-- Setup files (Run manually once)
        ├── bootstrap.tf
        ├── outputs.tf
        └── providers.tf
        └── variables.tf

