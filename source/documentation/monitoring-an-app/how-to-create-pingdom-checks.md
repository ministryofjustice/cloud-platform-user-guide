### Creating Pingdom checks

#### Overview
Pingdom is a global performance and availability monitor for your web application. The aim of this document is to provide you with the necessary information to create and send Pingdom checks to a Slack channel of your choosing.

#### Prerequisites
This guide assumes the following:

* You have [created a namespace for your application][env-create]
* You have a slack channel to send alerts into

#### Creating a Pingdom webhook and integration id
For Pingdom to communicate with Slack you require an integration id. Setting this up is really simple but requires access to the MoJ [Pingdom Slack](https://mojdt.slack.com/apps/A0F814AV7-pingdom?next_id=0) and [Pingdom](https://my.pingdom.com) console.

The Cloud Platform team can do this on your behalf. Create a ticket requesting a Pingdom integration id with the following information:

- team name
- application name
- slack channel

The team will provide you with an integration id, following the steps outlined [here](https://github.com/ministryofjustice/cloud-platform-environments/blob/master/docs/creating-pingdom-webhook.md).

#### Create a Pingdom terraform file
In the [cloud-platform-environments](https://github.com/ministryofjustice/cloud-platform-environments) repository create a resources directory (if it isn't already created) in your namespace, now add a `pingdom.tf` file and using the resources outlined [here](https://github.com/russellcardullo/terraform-provider-pingdom#usage) create a basic check. Here's a working example of a [basic check](https://github.com/ministryofjustice/cloud-platform-environments/blob/master/namespaces/cloud-platform-live-0.k8s.integration.dsd.io/monitoring/resources/pingdom.tf):
```
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
  tags                     = "businessunit_platforms,application_prometheus,component_healthcheck,isproduction_true,environment_prod,infrastructuresupport_platforms"
  probefilters             = "region:EU"
  integrationids           = [19203]
}
```
**Note**: You'll need to include the `provider "pingdom"` block either in this file or in a `main.tf` file. 
 
Once reviewed and merged to master, the pipeline will create your check. 
