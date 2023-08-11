# Azure Cleanup

This repository contains a set of scripts and workflows to cleanup an Azure tenant. This is useful for demo environments where you want to keep the cost low. The scripts are designed to be run as GitHub Actions, but can also be run locally.

## Current features

![Azure Resource Cleanup](https://github.com/JelleBroekhuijsen/azure-cleanup/actions/workflows/azure-resource-cleanup.yml/badge.svg)
![Azure Management Group Cleanup](https://github.com/JelleBroekhuijsen/azure-cleanup/actions/workflows/azure-management-group-cleanup.yml/badge.svg)
![Azure Policy Cleanup](https://github.com/JelleBroekhuijsen/azure-cleanup/actions/workflows/azure-policy-cleanup.yml/badge.svg)
![Azure AD Application Cleanup](https://github.com/JelleBroekhuijsen/azure-cleanup/actions/workflows/azure-ad-application-cleanup.yml/badge.svg)

- Perform daily cleanup of Azure Resource Groups that do not have a tag of 'persistent' set to 'true'.
- Perform a manually triggered cleanup of Azure Management Groups.
- Perform a manually triggered cleanup of Azure Policies.
- Perform daily cleanup of Azure AD Applications that do not have a tag 'persistent'.

## Requirements

The workflows utilize a Service Principal to perform the cleanup. The Service Principal must have the following permissions:

- Contributor on the subscriptions if you want to perform resource cleanup.
- Owner on the root tenant group if you want to perform management group cleanup.

The workflows rely on OpenId Connect for authentication. See [this](https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure?tabs=azure-portal%2Cwindows#use-the-azure-login-action-with-openid-connect) for info on how to configure your SPN for OIDC-authentication.

## Setup

 The following secrets variables must be set in the environment:

- AZURE_TENANT_ID
- AZURE_CLIENT_ID

To control the subscriptions that are cleaned up, the following environment variable must be set:

- AZURE_SUBSCRIPTION_IDS

This variable can contain a list of subscription id's formatted like:

`["c7543ebf-xxxx-xxxx-xxxx-a76bf52b612c", "376b4876-xxxx-xxxx-xxxx-c2c291af302e", "21a53ac8-xxxx-xxxx-xxxx-80bb17b13774"]`
