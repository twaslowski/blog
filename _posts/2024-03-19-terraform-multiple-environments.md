---
layout: post
title: "Managing multiple environments in one AWS Account"
---

The recommended way of managing multiple environments for your Cloud application is usually using several accounts.
If you're an enterprise, that's not a big problem. However, if you're just a normal person with a private AWS account,
getting another one just so you can create a staging environment for your application prototype with a few users
may be a bit too much.

In this article I will show you an easy way of managing multiple environments in a single account using Terraform.
No workspaces, no Terragrunt, or any other tooling – simply vanilla Terraform and a little bit of Bash.
Also: I'll be using AWS in this example, but the concept applies to other Cloud providers just as well.

### Preface: Should I do this?

There are good reasons why it's generally recommended to run your staging and your production environments
in different accounts. One is security: If your staging environment gets compromised, at least your production 
will not be affected. Another issue can be that with certain Cloud providers, certain resources should only be
created once per account or per region. 
[This is the case, for example, for the ApiGateway::Account resource](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-apigateway-account.html);
this means that your Terraform states for staging and production are going to be different, as one of them is going
to be holding those unique resources. Alternatively, you could introduce a third state that holds unique resources,
but then you're looking at a lot of extra effort.

Essentially, I would only recommend using this pattern in relatively simple projects where you don't want to go
through the trouble of getting an extra account from your Cloud provider and security is not a priority.
What I'm suggesting here is not best practice, but it is extremely convenient and may be right for a prototype
or an MVP.

### Getting Started

For this guide, you will need your own AWS Account as well as a working Terraform installation.
We'll be creating a Secretsmanager Secret in two different environments.
First, let's create an S3 state bucket and configure our Terraform providers. 
You can create your bucket manually in the console, or by running `aws s3 mb s3://state-bucket` on the command line.

Next up, our provider configuration should look something like this:

```terraform
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket = "state-bucket"
    key    = "state-key"  # or whatever else you choose
    region = "eu-central-1"
  }
}
```

Next, let's create the resources we want to create:

```terraform
resource "aws_secretsmanager_secret" "secret" {
  name = "my-awesome-secret"
}

resource "aws_secretsmanager_secret_version" "secret_content" {
  secret_id = aws_secretsmanager_secret.secret.id
  secret_string = random_password.password.result
}

resource "random_password" "password" {
  length = 32
}
```

When running `terraform apply`, three resources are created. Let's list all secrets in our account:

```bash
$ aws secretsmanager list-secrets | jq ".SecretList[].Name"
"my-awesome-secret"
```

### Doing the same thing in multiple environments

Now that we have set up Terraform, let's get into creating multiple environments.
Essentially, the idea is two have two different state files in one S3 bucket (you can also create two different buckets
if you like). The `-backend-config` flag in `terraform init` allows us to specify a file that holds our backend
configuration.

⚠️ NOTE: When you do this, you need to empty the S3 backend configuration in your Terraform code. It should look like
this now: `backend "s3" {}`

Next up we create a `dev.hcl` and `prod.hcl` file, which will point to different keys in our state bucket:

```hcl
key    = "dev/terraform.tfstate"
bucket = "multi-env-state"
region = "eu-central-1"
```

For `prod.hcl`, simply adjust the key. 

Something to consider is that most resources in AWS have uniqueness constraints on their names.
Therefore, we'll have to introduce a `environment` variable or some other unique identifier that allows us to
disambiguate the different environments we're managing in the same account. Therefore, we'll modify our existing
Terraform code as follows:

```terraform
variable "environment" {
  type = string
}

resource "aws_secretsmanager_secret" "secret" {
name = "my-awesome-secret-${var.environment}"
}
```

Now, to perform our first deployment to our staging environment, we simply run the following commands.

```bash
$ terraform init -backend-config="dev.hcl" -reconfigure
$ export TF_VAR_environment=dev 
$ terraform apply
```

This is going to create the required files in your state bucket. Running `aws s3 ls s3://state-bucket/dev/` is going to
show a `terraform.tfstate` exists. Similarly, listing secrets shows one secret called `my-awesome-secret-dev`.

You can now repeat this process for `prod.hcl` and create a new environment. If you like, you can add as many 
environments as you like. After running `terraform apply` for prod, you should be able to see the following:

```
$ aws secretsmanager list-secrets | jq ".SecretList[].Name"
"my-awesome-secret-dev"
"my-awesome-secret-prod"
```

Honestly, that's pretty much it. This isn't terribly complicated, but this approach isn't as well-documented
as the multi-account solution. I hope this helps!
