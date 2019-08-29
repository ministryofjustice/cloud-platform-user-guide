## Creating a Cloud Platform Environment

### Introduction

This is a guide to creating a environment in one of our Kubernetes clusters.

We define an environment as a Kubernetes [namespace]
with some key resources deployed in it. Each Kubernetes namespace creates a
logical separation within our cluster that provides isolation from any other
namespace.

Once you have created an environment you will be able to perform actions using
the `kubectl` tool in the namespace you have created.

### Objective

By the end of this guide you'll have created a Kubernetes namespace ready for
you to [deploy an application][deploy-hello-world] into.

### Create an environment

You create an environment by adding the definition of the environment in YAML
to the following repository, hosted on GitHub:

[cloud-platform-environments][env-repo]

Adding your environment definition kicks off a pipeline which builds your
environment on the appropriate cluster.

> #### Naming
> When creating your environment, please ensure that you comply with our
[guidance on naming things][naming-things-guidance].

> This is particularly important for domain names, but since these often closely
match the namespace name, it's worth choosing a good name at this stage.

#### Set up

First we need to clone the repository, change directory and create a new branch:

```
$ git clone git@github.com:ministryofjustice/cloud-platform-environments.git
$ cd cloud-platform-environments
$ git checkout -b <yourBranch>
```

#### The directory structure

We build new environments by creating a new directory for our environment and
putting the YAML files that define the environment into that directory. To
understand where to create the directory it is useful to understand the overall
structure of the repo:

```
cloud-platform-environments
├── namespace-resources
└── namespaces
    └── live-1.cloud-platform.service.justice.gov.uk
        ├── kube-system
        ├── user-roles.yaml

        └── ... NAMESPACE FOLDERS ...

```

**cloud-platform-environments**

This is the root of the repo, containing `namespaces` directory

**/namespaces**

The namespaces directory contains a directory for each of the clusters that you
can build environments on. Create your environment in the
`live-1.cloud-platform.service.justice.gov.uk` directory.

**/namespaces/live-1.cloud-platform.service.justice.gov.uk/**

Within the cluster directory you will generate a directory for your environment
in the format `<servicename-env>`, for example `myapp-dev`.

**/namespaces/live-1.cloud-platform.service.justice.gov.uk/servicename-env/**

The `<servicename-env>` directory for your environment defines the specific
resources we will create in your namespace. We describe these resources in more
detail in [how we set up an environment](#how-we-set-up-an-environment).

#### How we set up an environment

To set up an environment we create 5 Kubernetes YAML files in the directory for your namespace:

* [`00-namespace.yaml`](#00-namespace-yaml)
* [`01-rbac.yaml`](#01-rbac-yaml)
* [`02-limitrange.yaml`](#02-limitrange-yaml)
* [`03-resourcequota.yaml`](#03-resourcequota-yaml)
* [`04-networkpolicy.yaml`](#04-networkpolicy-yaml)

These files define key elements of the namespace and restrictions we want to
place on it so that we have security and resource allocation properties. We
will use terraform to create these files from templates. We also describe each
of these files [in more detail below](#00-namespace-yaml) in case you want to
make future changes.

In addition to the Kubernetes configuration files, we create a terraform config file:

    resources/main.tf

This file defines the standard terraform backend and providers which you will
need when you add terraform modules to create the AWS resources your service
will use (e.g. an [ECR][ecr-setup] for your docker images, [RDS
databases][create-rds], and S3 buckets).

#### Create your namespace and namespace resources

We automate the creation of the namespace resource files using terraform. You will need to install terraform locally:

```Shell
$ brew install terraform@0.11
```

> Note: You must specify version 0.11 of terraform. 0.12 (the latest, at the time of writing) introduces breaking changes, and the cluster has not yet been upgraded to work with Terraform 0.12. If you try to use terraform 0.12, you will get errors about formatting and other problems. Please stick to version 0.11, for now.

In each of the template files you need to replace some example values with
information about your namespace, team or app. We do this by running terraform
commands and filling in the values.

These are the inputs for the terraform module, that you will need to fill:

<div style="height:1px;font-size:1px;">&nbsp;</div>

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| application | The name of your application | string | - | yes |
| business-unit | Area of the MOJ responsible for the service | string | - | yes |
| cluster | What cluster are you deploying your namespace. i.e cloud-platform-test-1 | string | `cloud-platform-live-1` | no |
| contact_email | Contact email address for owner of the application | string | - | yes |
| environment | A label for your environment (e.g. dev/staging/...) | string | - | yes |
| github_team | This is your team name as defined by the GITHUB api. This has to match the team name on the Github API | string | - | yes |
| is-production |  | string | `false` | no |
| namespace | Namespace you would like to create on cluster <application>-<environment>. i.e myapp-dev | string | - | yes |
| owner | Who is the owner/Who is responsible for this application | string | - | yes |
| source_code_url | Url of the source code for your application | string | - | yes |

<div style="height:1px;font-size:1px;">&nbsp;</div>

Run the following commands to create your namespace and these resources files:

```Shell
$ cd cloud-platform-environments/namespace-resources/
$ terraform init
$ terraform apply
```

Fill in your values in response to the prompts.

For `var.namespace`, this is the name of your (team's) 'private' part of the
cluster. The name of your namespace must be unique across the whole of the
cluster. If you try to create a new namespace using the name of one which
already exists, you will get an error when you try to apply the generated
kubernetes config files (or when our build pipeline applies them on your
behalf).

For 'real' services, this is very unlikely to be a problem - most services have
distinct names, so namespace name conflicts are unlikely. But, if you are
creating a test/dummy namespace in order to learn how the platform works, it's
better to avoid generic names like 'dummy', 'test' or 'example'. Add something
unique (e.g. your name) to minimise the risk of trying to re-use a name by
mistake.

For `var.source_code_url`, this should be the URL of an application which is
'cluster-ready' to be deployed. If you do not have such an application ready to
go, you can use the reference application which the Cloud Platform team have
prepared `git@github.com:ministryofjustice/cloud-platform-reference-app.git`

Note: The `source_code_url` is a descriptive label, used by the Cloud Platform
team in supporting your namespace. It does not set up an explicit link between
your namespace and your application's code repository.

At the final prompt "Do you want to perform these actions?", enter "yes"

You can then access your namespace files under
`cloud-platform-environments/namespaces/live-1.cloud-platform.service.justice.gov.uk/<your-namespace>`,
if satisfied you can then push the changes to your branch and create a pull
request against the
[`cloud-platform-environments`](https://github.com/ministryofjustice/cloud-platform-environments)
master repo.

The cloud platform team will review the pull request when it gets opened.  As
soon as the pull request has been approved by the cloud platform team you can
then merge it into the master branch which will kick off the pipeline that
builds the environment. You can check whether the build succeeded or failed in
the [`#cp-build-notification`](https://mojdt.slack.com/messages/CA5MDLM34/)
slack channel. This can take about 5 minutes.

Please create **one PR per namespace**

i.e. if you need namespaces 'myapp-dev', 'myapp-staging' and 'myapp-prod',
please raise a separate PR for each one. This makes it a lot easier for the
cloud platform team to review your PRs.

### Namespace resource limits

The amount of resources (i.e. CPU and memory) we allocate to new namespaces, by
default, is deliberately low. When you have worked out how much resource your
application actually needs, please raise a PR to adjust the limits on your
namespace accordingly.

For more information, please see this article on [namespace limits].

### Accessing your environments

Once the pipeline has completed you will be able to check that your environment
is available by running:

`$ kubectl get namespaces`

This will return a list of the namespaces within the cluster, and you should
see yours in the list.

You can now run commands in your namespace by appending the `-n` or
`--namespace` flag to `kubectl`. So for instance, to see the pods running in
our `myenv-dev` namespace, we would run:

`$ kubectl get pods -n myenv-dev` or

`$ kubectl get pods --namespace myenv-dev`

### Next steps

[Create an ECR repository][ecr-setup] to push your application docker image to.

Then you can try [deploying an app to Kubernetes manually][deploy-hello-world]
by writing some custom YAML files or [deploying an app with Helm][deploy-helm],
a Kubernetes [package manager](https://helm.sh/).

### More information on environment definition

To set up an environment we create 5 files in that directory:

* [`00-namespace.yaml`](#00-namespace-yaml)
* [`01-rbac.yaml`](#01-rbac-yaml)
* [`02-limitrange.yaml`](#02-limitrange-yaml)
* [`03-resourcequota.yaml`](#03-resourcequota-yaml)
* [`04-networkpolicy.yaml`](#04-networkpolicy-yaml)

These files define key elements of the namespace and restrictions we want to
place on it so that we have security and resource allocation properties. We
will use terraform to create these files from templates. We also describe each
of these files in more detail below in case you want to make changes.

#### `00-namespace.yaml`

The `00-namespace.yaml` file defines the namespace so that the cluster
Kubernetes knows to create a namespace and what to call it.

```YAML
apiVersion: v1
kind: Namespace
metadata:
  name: myapp-dev ### This is where you will define your <servicename-env>
  labels:
    name: myapp-dev ### Also your <servicename-env>
```

#### `01-rbac.yaml`

We will also create a `RoleBinding` resource by adding the `01-rbac.yaml` file.
This will provide us with [access
policies](https://kubernetes.io/docs/admin/authorization/rbac/) on the
namespace we have created in the cluster.

A role binding resource grants the permissions defined in a role to a user or
set of users. A role can be another resource we can create but in this instance
we will reference a Kubernetes default role `ClusterRole - admin`.

This `RoleBinding` resource references the `ClusterRole - admin` to provide
admin permissions on the namespace to the set of users defined under
`subjects`. In this case, the `<yourTeam>` GitHub group will have admin access
to any resources within the namespace `myapp-dev`.

```YAML
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: myapp-dev-admins  ### Your namespace with `-admin` e.g. `<servicename-env>-admin`
  namespace: myapp-dev ### Your namespace `<servicename-env>`
subjects:
  - kind: Group
    name: "github:<yourTeam>" ### Make this the name of the GitHub team you want to give access to
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: admin
  apiGroup: rbac.authorization.k8s.io
```

#### `02-limitrange.yaml`

As we are working on a shared Kubernetes cluster it is useful to put in place
limits on the resources that each namespace, pod and container can use. This
helps to stop us accidentally entering a situation where one service impacts
the performance of another through using more resources than are available.

The first Kubernetes limit we can use is a [LimitRange] which we define in
`02-limitrange.yaml`.

The LimitRange object specifies two key resource limits on containers,
`defaultRequest` and `default`. `defaultRequest` is the memory and cpu a
container will request on startup. This is what the Kubernetes scheduler uses
to determine whether there is enough space on the cluster to run your
application and what your application will start up with when it is created.
`default` is the limit at which your application will be killed or throttled.

In `02-limitrange.yaml` you need to change the value of the `namespace` key to
match the name of your namespace in the form `<service-env>`. We have set
default values for the limits in the templates. As you learn more about the
behaviour of your applications on Kubernetes you can change them.

```YAML
apiVersion: v1
kind: LimitRange
metadata:
  name: limitrange
  namespace: myapp-dev ### Your namespace `<servicename-env>`
spec:
  limits:
  - default:
      cpu: 50m
      memory: 500Mi
    defaultRequest:
      cpu: 10m
      memory: 100Mi
    type: Container
```

#### `03-resourcequota.yaml`

The [ResourceQuota] object allows us to set a total limit on the resources
reserved for a namespace. As with the LimitRange, the `requests.cpu` and
`requests.memory` limits set how much the namespace will request on creation.

In `03-resourcequota.yaml` you need to change the value of the `namespace` key
to match the name of your namespace in the form `<service-env>`. We have set
default values for the limits in the templates. As you learn more about the
behaviour of your applications on Kubernetes you can change them.

```YAML

apiVersion: v1
kind: ResourceQuota
metadata:
  name: namespace-quota
  namespace: myapp-dev ### Your namespace `<servicename-env>`
spec:
  hard:
    requests.cpu: 100m
    requests.memory: 1000Mi
```

#### `04-networkpolicy.yaml`

The [NetworkPolicy] object defines how groups of pods are allowed to
communicate with each other and other network endpoints. By default pods are
non-isolated, they accept traffic from any source. We apply a network policy to
restrict where traffic can come from, allowing traffic only from the [ingress
controller] and other pods in your namespace.

In `04-networkpolicy.yaml` you need to change the value of the `namespace` key
to match the name of your namespace in the form `<service-env>`.

```YAML
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default
  namespace: myapp-dev ### Your namespace `<servicename-env>`
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector: {}
---
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: allow-ingress-controllers
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          component: ingress-controllers
```

[deploy-hello-world]: tasks.html#deploying-a-39-hello-world-39-application-to-the-cloud-platform
[deploy-helm]: tasks.html#deploying-an-application-to-the-cloud-platform-with-helm
[ecr-setup]: tasks.html#creating-an-ecr-repository
[create-rds]: tasks.html#create-an-rds-instance
[namespace limits]: concepts.html#namespace-container-resource-limits
[naming-things-guidance]: https://ministryofjustice.github.io/technical-guidance/standards/naming-things/#naming-things
[namespace]: https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/
[env-repo]: https://github.com/ministryofjustice/cloud-platform-environments
[NetworkPolicy]: https://kubernetes.io/docs/concepts/services-networking/network-policies/
[ingress controller]: https://kubernetes.io/docs/concepts/services-networking/ingress/
[access policies]: https://kubernetes.io/docs/admin/authorization/rbac/
[LimitRange]: https://kubernetes.io/docs/tasks/administer-cluster/manage-resources/memory-default-namespace/
[ResourceQuota]: https://kubernetes.io/docs/concepts/policy/resource-quotas/
