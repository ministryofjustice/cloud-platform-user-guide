## Adding AWS resources to your environment

Through the [cloud-platform-environments](https://github.com/ministryofjustice/cloud-platform-environments/) repository, you can provision AWS resources for your environments. This is done using terraform and more specifically, terraform modules we provide for use on the Cloud Platform.

The documentation for the modules lives in each module's repository and you can find a list of the available ones below.

### Available modules

- [ECR Repository](https://github.com/ministryofjustice/cloud-platform-terraform-ecr-credentials)
- [S3 Bucket](https://github.com/ministryofjustice/cloud-platform-terraform-s3-bucket)
- [RDS instance](https://github.com/ministryofjustice/cloud-platform-terraform-rds-instance)
- [Elasticache Redis Cluster](https://github.com/ministryofjustice/cloud-platform-terraform-elasticache-cluster)
- [DynamoDB Table](https://github.com/ministryofjustice/cloud-platform-terraform-dynamodb-cluster)
- [SNS Topic](https://github.com/ministryofjustice/cloud-platform-terraform-sns-topic)
- [SQS Queue](https://github.com/ministryofjustice/cloud-platform-terraform-sqs)

### Usage

In each terraform module repository, you will find a directory named `example` which includes sample configuration for use in Cloud Platform.

In your namespace's path in the [cloud-platform-environments](https://github.com/ministryofjustice/cloud-platform-environments/) repository, create a directory called `resources` (if you have not created one already) and refer to the module's example to define your resources.

Each example will have some global configuration defined, however, this should only be declared once, regardless of the number of modules used:

```
terraform {
  backend "s3" {}
}

provider "aws" {
  region = "eu-west-1"
}
```

Additionally, some example might define variables; again, these should only be declared once per namespace:

```
variable "cluster_name" {}

variable "cluster_state_bucket" {}
```

The main README file of each module repository will list all the available configuration options that can be passed to the module.

#### Outputs
Each module will have its own outputs. These expose useful information, such as endpoints, credentials etc. The module examples all use a common approach: they employ the `kubernetes_secret` terraform resource to push the outputs straight into your environment in the form of a `Secret` which you could then extract information from or directly reference in `Pods`.

This is currently the only supported way of accessing terraform outputs.

#### Versioning

All modules are versioned. This allows us to implement changes without breaking existing resources. To use a specific version of a module you need to define it in the `source` attribute by specifying the `ref` attribute in the query string of the source URL:

```
module "my_module" {
  source = "https://github.com/ministryofjustice/cloud-platform-terraform-ecr-credentials?ref=1.0"
}
```

Make sure that you have checked the releases page of a module and that you are using the latest of them in your configuration.

Upgrading to a new major version usually means that the configured resource will have to be re-created by terraform.

Refer to the [terraform documentation on modules](http://terraform.io/docs/modules) for more information on usage.
