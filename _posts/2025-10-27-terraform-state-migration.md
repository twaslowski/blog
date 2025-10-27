---
layout: post
title: "Breaking up Terraform states at scale"
---

Recently, I had to extract a good amount of resources from a large Terraform state into a new state file
to break up a near-monolithic infrastructure.

Messing with Terraform state in production environments can be a daunting task if you cannot afford for resources
to get destroyed and recreated. I want to share the approach I took to perform this migration with minimal risk.

## Scripting and Reproducibility

It was important for me to create a solution with minimal manual steps that I could test on staging and then simply
run against production once I had found that it worked well.

The process would be as follows:

1. Identify all resources that needed to be moved from the source state to the target state.
2. Write a script that would read a list of resource addresses and move them from one state file to another.
3. Test the script on a staging environment.
4. Once verified, run the script on production.

## Identifying Resources to Migrate

When you have to migrate some 100+ resources, you don't want to determine all those resource addresses manually.
Fortunately, I had written a utility in the past that could analyse Terraform plans and output summaries.
So I dusted off this tool that hadn't seen any usage for a good year or so and put it to good use. You can too!
Simply install it via pip:

```shell
pip install tfanalyse
```

Then, I started finding out which addresses needed to be migrated. The easiest way to do this is to make all the changes you want
in the source Terraform configuration (i.e., delete all the resources and modules you want to move to the new state file), then run
`terraform plan` and use `tfanalyse` to extract the list of resources planned for deletion:

Here is an example of migrating some resources you do not want to see destroyed:

```shell
$ pwd
  ./infrastructure/source-state
$ mv secrets.tf route53.tf certificates.tf ../target-state-state/
$ terraform plan -out plan.tfplan
$ tfanalyse plan.tfplan --destroy-only | sed -e 's/^DESTROY //g' > resources-to-migrate.txt
$ cat resources-to-migrate.txt
aws_acm_certificate.example
aws_route53_record.example
...
```

## Performing the Migration

I have to give credit to my former colleague Calin Florescu here, who wrote a brilliant Medium article on breaking
up monolithic Terraform states, which you can find [here](https://medium.com/@calinflorescu3/splitting-a-monolithic-terraform-state-d26e866de629). 
In this section, I will show you a scripted approach based on his article.

His article notably relies on using `terraform state mv` commands to move resources around.
For local state files only, Terraform accepts `-state` and `-state-out` flags to specify source and destination state
files. This does not work with remote state backends like S3.

Therefore, I opted to pull the state files locally, perform the migration, and then push them back to S3.
You _really_ should perform backups before doing this.

```shell
terraform state pull -state=s3://my-terraform-state-bucket/environments/staging/source.tfstate > source.tfstate
terraform state pull -state=s3://my-terraform-state-bucket/environments/staging/target.tfstate > target.tfstate

aws s3 cp s3://my-terraform-state-bucket/environments/staging/source.tfstate s3://my-terraform-state-bucket/environments/staging/source.tfstate.bak
aws s3 cp s3://my-terraform-state-bucket/environments/staging/target.tfstate s3://my-terraform-state-bucket/environments/staging/target.tfstate.bak
```

Alright, preliminaries are done. Without further ado, here is a simple Python script that performs the migration:

<script src="https://gist.github.com/twaslowski/4681cfe4e9b3c828d8406f5bcef343b3.js"></script>

The script will list the number of resources to migrate and perform a dry-run first.
After verifying that everything looks good, it will ask for confirmation to proceed with the actual migration.

I was too lazy to bother with argument parsing, so you can simply copy it and modify the file names for the
source and target state as well as the resource list file.

```python
if __name__ == '__main__':
    source_tfstate = 'source.tfstate'
    target_tfstate = 'target.tfstate'
    resources_file = 'resources-to-migrate.txt'

    migrator = TerraformMigrator(source_tfstate, target_tfstate, resources_file)
    migrator.migrate()
```

Afterwards, you can simply run it like so:

```shell
python migrate.py
```

When everything is done, push the updated state files back to S3. Ensure you are in the correct directory when pushing the state files.
It's never too late to fuck up an otherwise successful migration.

```shell
cd environments/staging/source && terraform state push source.tfstate
```

All that is now left to do is to perform another `terraform plan` to check if all resources were migrated as intended.
Ideally, you should see no destroys in the plan. The same thing goes for the target state: You should see no planned
resource creations. If you're tagging your resources (as you should!), you might see a bunch of modifications.

## Notes

With this, you're pretty much done. We have made a process that could be extremely risky reproducible, even versionable,
since you can check the migration script and the file with the module and resource addresses into git.
These files will serve as documentation for your future migrations.

Of course, the more essential the resources, the more careful you should be and double- and triple-check all changes.
Good luck!