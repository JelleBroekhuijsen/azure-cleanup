# Azure Cleanup

This repository contains a set of scripts to cleanup Azure scripts and resources.

## Current features

- Perform daily cleanup of Azure Resource Groups that do not have a tag of 'persist' set to 'true'.

## Requirements

The solution utilizes a Service Principal to perform the cleanup. The Service Principal must have the following permissions:

- Contributor on the subscriptions you want to cleanup.

The service principal relies on OIDC authentication.

## Setup

 The following secrets variables must be set in the environment:

- AZURE_TENANT_ID
- AZURE_CLIENT_ID

To control the subscriptions that are cleaned up, the following environment variable must be set:

- AZURE_SUBSCRIPTION_IDS

This variable can contain a list of subscription id's formatted like:

`["c7543ebf-xxxx-xxxx-xxxx-a76bf52b612c", "376b4876-xxxx-xxxx-xxxx-c2c291af302e", "21a53ac8-xxxx-xxxx-xxxx-80bb17b13774"]`
