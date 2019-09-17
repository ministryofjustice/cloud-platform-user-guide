### Migrade from Template Deploy

#### Overview

Template Deploy (TD) is the deployment mechanism described in this [Confluence page][template-deploy] with operational details and inventory in the [DSD Operationa Manual][ops-manual]; this mechanism is obsoleted by the new [Cloud Platform][cloud-platform] (CP), the transition to which is details in this document.

#### Service equivalence

##### Infrastructure

Services generally retain the same features and providers; with differences and enhancements outlined below:

1. The underlying platform remains AWS

   i. A new and generally more locked-down AWS account is used, accessible generally via Terraform and role-specific IAM credentials; admin-level and console access is discouraged and generally reserved for the CP team.
   i. All new deployments are started in the region `eu-west-2`(London) while TD uses `eu-west-1`(Ireland). For features not available in the region (eg SES), cross-region links can be created and will be evaluated on request.
   i. AWS resources are not immediately available but must be requested via a Terraform-based [pipeline][pipeline] that serves both as validator and approval mechanism. Supported features are exposed via Terraform modules, listed in the [User Guide](terraform-modules).

1. While TD deployments could be characterized as "AWS+Docker", CP transitions many resources to Kubernetes concepts:
   i. VPC -> namespace
   i. EC2 instance -> pod
   i. Docker container -> Kubernetes container, which may or not be based on Docker, so 100% feature parity must not be assumed (networking code is different, docker-compose does not apply).
   i. ELB -> Nginx Ingress
   i. SG -> Ingress annotations
   i. EBS -> Persistent Volume Claim
   i. SSH -> `kubectl exec`

1. Single shared Docker registry is replaced by as many ECR instances as needed, based on team requests.

1. Pagerduty [accounts][pagerduty] and configuration remain unchanged.
   i. Alert sources can now be CloudWatch, Sentry (e-mail) and [Alertmanager][monitoring].

1. Pingdom [accounts](https://pingdom.com) and configuration remain unchanged.

1. While the CP platform is meant to be much more self-service than TD, support is still offered by the CP team, with similar [communication channels and service levels][service-levels].

##### Application-level considerations

1. Docker remains the preferred execution engine, upgraded to match the supported [Kubernetes release][kubernetes-release] (v1.13 at the time of this writing).

1. There are no addditional restrictions on the programming languages or framework used; the same MoJ-wide [technical guidance](https://ministryofjustice.github.io/technical-guidance/) applies.

1. Applications must log their entire output to STDOUT/STDERR. 
   i. A cluster-shared service (fluentd) automatically collects all the outputs and sends them to [ElasticSearch][kibana] with no explicit configuration needed.
   i. Services that capture the output to re-format or send to a different destination can be run as multi-container pods, but may be superfluous.

1. Init-type services within containers are discouraged. Kubernetes offers featureful service manager natively.

1. Cron-type services within containers are discouraged. Kubernetes offers a featureful scheduler natively.

1. Resource limits
   i. CPU/RAM limits in TD reflect the configuration of the EC2 instance; for CP they are defined as [ResourceQuote / LimitRange][resources].
   i. Disk space limit in TD is the EBS volume; for CP storage is highly restricted and volatile, persistent volumes must be requested via [StatefulSets][statefulset].

1. Monitoring
   i. Recommended solution is the combination of [Prometheus/AlertManager/Grafana](monitoring).
   i. [Sentry][sentry] usage is unchanged.

#### Additional features

1. Communication bounderies between applications and to AWS APIs are enforced using in-cluster [network policies][ingress], [OPA](opa) and [Kiam][kiam].

1. DNS and SSL are managed by cluster-shared services (cert-manager and external-dns)
   i. Validation and deployment are managed by a single pipeline.
   i. Renewals are automatic.
   i. Initial configuration might require delegation from GDS.
   i. Services might also be used in Quantum, work with the Quantum team (Atos? Vodafone?) to ensure DNS propagation.

1. A shared, highly-available deployment of reverse-proxy instances based on AWS ELB and Nginx runs in front of all application instances and offers features like [WAF][waf], custom [error pages][error-pages] or [IP-based ACLs][ip-whitelist] user-configurable per application but independent from its running state.

1. Several AWS resource types are tested and documented as [Terraform modules][terraform-modules]; they simplify deployment and propose best-practices options.
   i. Correct sizing and access control rules may still greatly vary for each project and must be carefully considered, not all resources scale up automatically.
   i. Small test/ephemeral instances are easy to create (and destroy), be they `db.t2.micro` RDS or `helm install stable/postgresql`.

#### Obsoleted features

1. Salt and CloudFormation are no longer used to define a deployment, replaced by any of Helm or Kubectl (see several [reference app][examples] examples).

1. Jenkins is no longer used to trigger deployments, teams are encouraged to [configure CircleCI][circleci] directly from their repositories.

1. For application logs, the path `awslogs` + CloudWatch + Lambda is replaced by `fluentd`.

1. Gandi and AWS ACM SSL certs are replaced by [Let's Encrypt](https://letsencrypt.org)


[template-deploy]: https://dsdmoj.atlassian.net/wiki/spaces/PLAT/pages/86310992/Template+Deploy
[ops-manual]: https://opsmanual.dsd.io/starthere/index.html
[cloud-platform]: https://github.com/ministryofjustice/cloud-platform
[pipeline]: https://concourse.cloud-platform.service.justice.gov.uk/teams/main/pipelines/build-environments
[terraform-modules]: https://user-guide.cloud-platform.service.justice.gov.uk/tasks.html#available-modules
[service-levels]: https://github.com/ministryofjustice/cloud-platform/blob/master/docs/INFO-our-ops-processes.md
[kubernetes-release]: https://v1-13.docs.kubernetes.io
[circleci]: https://user-guide.cloud-platform.service.justice.gov.uk/tasks.html#deploying-with-helm-and-circleci
[examples]: https://user-guide.cloud-platform.service.justice.gov.uk/tasks.html#deploying-a-39-hello-world-39-application-to-the-cloud-platform
[error-pages]: https://github.com/ministryofjustice/cloud-platform-custom-error-pages
[waf]: https://user-guide.cloud-platform.service.justice.gov.uk/tasks.html#modsecurity-web-application-firewall
[ip-whitelist]: https://user-guide.cloud-platform.service.justice.gov.uk/tasks.html#ip-whitelisting
[resources]: https://github.com/ministryofjustice/cloud-platform-environments/blob/master/namespace-resources/
[statefulset]: https://user-guide.cloud-platform.service.justice.gov.uk/tasks.html#statefulsets-pods-with-persistent-volumes
[ingress]: https://github.com/ministryofjustice/cloud-platform-environments/blob/master/namespace-resources/04-networkpolicy.yaml
[opa]: https://github.com/ministryofjustice/cloud-platform-infrastructure/blob/master/terraform/cloud-platform-components/opa.tf
[kiam]: https://github.com/ministryofjustice/cloud-platform-infrastructure/blob/master/terraform/cloud-platform-components/kiam.tf
[pagerduty]: https://moj-digital-tools.pagerduty.com
[monitoring]: https://user-guide.cloud-platform.service.justice.gov.uk/tasks.html#monitoring-applications
[sentry]: https://sentry.service.dsd.io/mojds
[kibana]: https://kibana.cloud-platform.service.justice.gov.uk/_plugin/kibana
