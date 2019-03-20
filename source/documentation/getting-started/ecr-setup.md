## Creating an ECR repository

### Introduction

This guide will guide you through the creation of an ECR (Elastic Container Registry) repository for your application's docker image.

AWS resources are provisioned through the [cloud-platform-environments](https://github.com/ministryofjustice/cloud-platform-environments/) repository, per environment. Your application might be using multiple namespaces, however you typically only need one image repository and once created in any of them you can copy credentials for it to the others via `kubectl get/create secret`.

#### Creating the registry

1\. In order to create the ECR Docker registry, git clone the repo and create a new branch.

```bash

  $ git clone git@github.com:ministryofjustice/cloud-platform-environments.git ##git clone repo

  $ cd cloud-platform-environments ## navigate into cloud-platform-environments directory.

  $ git checkout -b add_ecr   ## create and checkout new branch.

```

2\. You will need to navigate to your service's directory which is located in the namespaces directory. Create a directory named "resources".

```bash

  $ cd namespaces/cloud-platform-live-0.k8s.integration.dsd.io/$your_service  ##navigate to your service's directory.

  $ mkdir resources ## make directory called resources

  $ cd namespaces/cloud-platform-live-0.k8s.integration.dsd.io/$your_service/resources

```

3\. Create a terraform file within the resources directory.

```bash

  $ vi ecr.tf  ##create a terraform file.

```

4\. Adapt the definition from the example described in the [cloud-platform-terraform-ecr-credentials module](https://github.com/ministryofjustice/cloud-platform-terraform-ecr-credentials/tree/master/examples); make sure you adjust the values of `team_name`, `repo_name` `name` and `namespace` to what is appropriate for your environment.

Note: A default ECR lifecycle policy is set, that will only keep the 40 most recent versions of an image.

5\. git add, commit and push to your branch.

```bash

  $ git add ecr.tf

  $ git commit

  $ git push

```
6\. Once your request has been approved and the branches are merged, it will trigger our build pipeline which will apply the Terraform module and create the resources.

For more information about the terraform module being used, please read the documentation [here](https://github.com/ministryofjustice/cloud-platform-terraform-ecr-credentials).

### Accessing the credentials

The end result will be a kubernetes `Secret` inside your environment, called `example-team-ecr-credentials-output` (or whatever you changed that to); the secret holds IAM access keys to authenticate with the registry and the actual repository URL.

Note: For `example-team-ecr-credentials-output` you should put whatever you used as the value of the `name` property of the `kubernetes_secret` resource in the `ecr.tf` file you created previously.

To retrieve the credentials:
```
kubectl -n <namespace_name> get secret example-team-ecr-credentials-output -o yaml
```

The values in kubernetes `Secrets` are always `base64` encoded so you will have to decode them before you can use them outside kubernetes. Inside the cluster, the nodes already have access to the ECR so you don't need to make any changes.

This can be done at the command line using the following:
```
echo QWxhZGRpbjpvcGVuIHNlc2FtZQ== | base64 --decode; echo
```

#### Setting up CircleCI
In your CircleCI project, go to the settings (the cog icon) and select 'AWS Permissions' from the left hand menu. Fill in the IAM credentials and CircleCI will be able to use ECR images. For more information please see [the official docs](https://circleci.com/docs/2.0/private-images/).


### Next steps

Try [deploying an app][deploy-helm] with [Helm](https://helm.sh/), a Kubernetes package manager, or [deploying manually][deploy-hello-world] by writing some custom YAML files.

[deploy-hello-world]: deploying-applications.html#deploying-a-39-hello-world-39-application-to-the-cloud-platform
[deploy-helm]: deploying-applications.html#deploying-an-application-to-the-cloud-platform-with-helm
