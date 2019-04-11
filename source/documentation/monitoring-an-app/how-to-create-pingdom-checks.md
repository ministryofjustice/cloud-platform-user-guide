### Creating Pingdom checks

#### Overview
[Pingdom](https://my.pingdom.com) is a global performance and availability monitor for your web application. The aim of this document is to provide you with the necessary information to create Pingom checks via the [cloud-platform-environments](https://github.com/ministryofjustice/cloud-platform-environments) pipeline, and then send failing checks to a Slack channel of your choosing.

#### Prerequisites
This guide assumes the following:

* You have [created a namespace for your application][env-create]
* You have a slack channel to send alerts to

#### Create a Pingdom check
To create a Pingdom check simply add a `pingdom.tf` file in the resources directory of your namespace in your [cloud-platform-environments](https://github.com/ministryofjustice/cloud-platform-environments/tree/master/namespaces/live-1.cloud-platform.service.justice.gov.uk) repository. You can define the conditions of your check using the resources outlined in the [Terraform community provider](https://github.com/russellcardullo/terraform-provider-pingdom). Here's a working example of a [basic check](https://github.com/ministryofjustice/cloud-platform-environments/tree/master/namespaces/cloud-platform-live-0.k8s.integration.dsd.io/monitoring/resources).
```yaml
terraform {
  backend "s3" {}
}

provider "pingdom" {}

resource "pingdom_check" "cloud-platform-prometheus-live-0-healthcheck" {
   type                     = "http"
   name                     = "Prometheus - live-0 - cloud-platform - Healthcheck"
   host                     = "prometheus.apps.cloud-platform-live-0.k8s.integration.dsd.io"
   resolution               = 1
   notifywhenbackup         = true
   sendnotificationwhendown = 6
   notifyagainevery         = 0
   url                      = "/-/healthy"
   encryption               = true
   port                     = 443
   tags                     = "businessunit_platforms,application_prometheus,component_healthcheck,isproduction_true,environment_prod,                              infrastructuresupport_platforms"
   probefilters             = "region:EU"
   publicreport             = "true"
 }
```
**Note**: You'll need to include the `provider "pingdom"` and `terraform` blocks either in this file or in a `main.tf` file. 

Once reviewed and merged to master, the pipeline will create your check in the MoJ Pingdom account.

This basic check simply checks the `host`/`url` returns a 200 every minute. When six consecutive checks fail it triggers an alarm. As `publicreport` is set to true, you can view the status of your check by visiting the [public status page](http://pingdom.service.dsd.io).

To fully understand all common and uncommon attributes of a check, you can visit the [Pindom community provider](https://github.com/russellcardullo/terraform-provider-pingdom#pingdom-check).

#### Adding Slack notification
You can enable the option to send a failing alert to Slack via a webhook by simply adding Pingdom integration id. Unfortunately, you need access to the console to first create the [Pingdom Slack](https://mojdt.slack.com/apps/A0F814AV7-pingdom?next_id=0) webhook and then [Pingdom](https://my.pingdom.com) to create the integration id. 

The Cloud Platform team can do this on your behalf. Create a ticket requesting a Pingdom integration id with the following information:
 
  - team name
  - application name
  - slack channel
 
The team will provide you with an integration id, following the steps outlined [here](https://github.com/ministryofjustice/cloud-platform-environments/blob/master/docs/creating-pingdom-webhook.md).

You can now add `integrationid` to your `pingdom.tf`. Appending the example above, your check will now appear as follows:
```yaml
terraform {
   backend "s3" {}
 }
 
 provider "pingdom" {}
 
 resource "pingdom_check" "cloud-platform-prometheus-live-0-healthcheck" {
    type                     = "http"
    name                     = "Prometheus - live-0 - cloud-platform - Healthcheck"
    host                     = "prometheus.apps.cloud-platform-live-0.k8s.integration.dsd.io"
    resolution               = 1
    notifywhenbackup         = true
    sendnotificationwhendown = 6
    notifyagainevery         = 0
    url                      = "/-/healthy"
    encryption               = true
    port                     = 443
    tags                     = "businessunit_platforms,application_prometheus,component_healthcheck,isproduction_true,environment_prod,                                          infrastructuresupport_platforms"
    probefilters             = "region:EU"
    publicreport             = "true"
    integrationid            = [1000]
  }

```
