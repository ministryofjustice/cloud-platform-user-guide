## Creating a Route 53 Hosted Zone

### Overview

This short guide will run through the process of creating a Route 53 Hosted Zone through Terraform for your environment.

### Pre-Requisites

This guide assumes you have an environment already created in the `Live-1` cluster and defined in the `cloud-platform-environments` repo.

### Terraform files

Copy the Terraform resource code below and save it into the respective 3 files in the `resources` directory under your environment in the `cloud-platform-environments` repo:

 * `main.tf`
 * `variables.tf`
 * `outputs.tf`

#### main.tf
```
resource "aws_route53_zone" "main" {
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

#### outputs.tf
```
output "zone_id" {
  description = "The zone ID of your hosted zone."
  value       = "${aws_route53_zone.main.zone_id}"
}

output "name_servers" {
  description = "The name severs of your hosted zone."
  value       = "${aws_route53_zone.main.name_servers}"
}
```

### Creating the resource

With the 3 files saved, navigate to the `resources` directory and run:

```
$ terraform init
$ terraform plan
$ terraform apply
```

When prompted, fill the variables with appropriate values.

Once the terraform has ran successfully, you will receive the `Zone_ID` and `Nameservers` as outputs.

These outputs will now need to be passed to the Cloud Platform team, who will verify the Hosted Zone.
