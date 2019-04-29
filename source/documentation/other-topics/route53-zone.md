## Creating a Route 53 Hosted Zone

### Overview

This short guide will run through the process of creating a [Route 53 Hosted Zone][aws-hosted-zone] through Terraform for your environment.

### Pre-Requisites

This guide assumes you have an environment already created in the `Live-1` cluster and defined in the [cloud-platform-environments repository][env-repo].

### Terraform files

Copy the Terraform resource code below and save it into the respective 2 files in the `[your namespace]/resources` directory in the [cloud-platform-environments repository][env-repo]:

 * `main.tf`
 * `variables.tf`

#### main.tf
```
resource "aws_route53_zone" "example_team_route53_zone" {
  name = "${var.domain}"

  tags {
    business-unit          = "${var.business-unit}"
    application            = "${var.application}"
    is-production          = "${var.is-production}"
    environment-name       = "${var.environment-name}"
    owner                  = "${var.team_name}"
    infrastructure-support = "${var.infrastructure-support}"
  }
}

resource "kubernetes_secret" "example_route53_zone_sec" {
  metadata {
    name      = "example-route53-zone-output"
    namespace = "${var.namespace}"
  }

  data {
    zone_id   = "${aws_route53_zone.example_team_route53_zone.zone_id}"
  }
}

```

#### variables.tf
```
variable "domain" {
  description = "The domain you intend to create. This should be a part of either parent zone of *.service.gov.uk or *.service.justice.gov.uk"
}

variable "application" {}

variable "business-unit" {
  description = "Area of the MOJ responsible for the service."
  default     = "mojdigital"
}

variable "team_name" {
  description = "The name of your development team"
}

variable "environment-name" {
  description = "The type of environment you're deploying to."
}

variable "infrastructure-support" {
  description = "The team responsible for managing the infrastructure. Should be of the form team-email."
}

variable "is-production" {
  default = "false"
}
```

### Creating the resource

Make sure to change placeholder values to what is appropriate, with the 2 files saved, commit your changes to a branch and raise a pull request. Once approved, you can merge and the changes will be applied. Shortly after, you should be able to access the `Zone_ID` as Secret on kubernetes in your namespace.

Please contact the Cloud Platform team via the `#ask-cloud-platform` Slack channel. Provide them with the zone_ID, and they will verify that your hosted zone has been created successfully.

[env-repo]: https://github.com/ministryofjustice/cloud-platform-environments
[aws-hosted-zone]: https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/AboutHZWorkingWith.html
