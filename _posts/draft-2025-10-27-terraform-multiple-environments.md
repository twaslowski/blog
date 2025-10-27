---
layout: post
title: "Managing multiple environments with Terraform"
---

There is a Terraform design pattern that I have seen many times that really bothers me, and I am writing this article
to explain why and show you a better way. If your Terraform folders are laid out as follows, this article is for you:

```
terraform/
├── dev/
│   ├── main.tf
│   ├── variables.tf
├── prod/
│   ├── main.tf
│   ├── variables.tf
│   modules/
│   ├── env/
│   │   ├── secrets.tf
│   │   ├── queues.tf
│   │   ├── networking.tf
│   │   ├── {...}.tf
```

And then your `main.tf` in `dev/` and `prod/` looks something like this:

```hcl
# dev/main.tf
module "env" {
    source = "../modules/env"
    
    environment = "dev"
    # other variables...
}
```

## What's wrong with this approach?

First and foremost, what I have seen time and time again is that this encourages
environment drift. Having separate `dev/` and `prod/` folders means that it is very easy to make changes
in one environment and forget to propagate them to the other. This can lead to situations where your
`dev` environment is running a different version of your infrastructure than `prod`, which can lead
to unexpected behavior when you finally deploy to production.

Also, if you actually _do_ keep them in sync, that means that you have to exactly replicate every change
twice, which violates the DRY (Don't Repeat Yourself) principle. This can lead to a lot of duplicated code
and makes it harder to maintain your infrastructure.

## What you should do instead

I recommend the following structure:

```
terraform/
├── config/
│   ├── dev.hcl
│   ├── prod.hcl
│   ├── dev.tfvars
│   ├── prod.tfvars
├── main.tf
├── networking.tf
├── queues.tf
├── secrets.tf
├── variables.tf
```

Your `dev.hcl` and `prod.hcl` files should contain the backend configuration. For example:

```hcl
# config/dev.hcl
bucket = "my-state-bucket"
key    = "dev.tfstate"
region = "eu-central-1"
```

To then use this configuration, you can run the following command:

```bash
terraform init -backend-config=config/dev.hcl
```

All environment-specific configuration is now stored in the `dev.tfvars` and `prod.tfvars` files.
This will ensure that you only have one set of Terraform code to maintain, and you can easily switch between
environments by changing the backend configuration and the variable file.

## Caveats

Of course, there are legitimate situations where different environments may contain slightly different configuration,
for example if you have to have certain resources for testing purposes. This means that you have to include the
`count` meta-argument in your resource definitions to conditionally create resources based on the environment.

This is not ideal, but, I would argue, a small price to pay for the benefits of having a single source of truth
for your infrastructure code.

## Wrapping up

In conclusion, managing multiple environments with separate folders in Terraform is not a good practice.
Additionally, custom modules may sometimes be unavoidable, but it has been my experience that they tend
to do more harm than good in the long run.

Of course, all of this should be taken with a grain of salt. This article is a result of my personal
experience, and your project may have specific requirements that make a different approach more suitable.
I won't advocate against approaches using workspaces, Terragrunt, Terraform Cloud or the variety of tools
that exist in the Terraform e