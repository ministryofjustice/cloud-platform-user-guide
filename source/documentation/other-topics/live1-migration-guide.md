---
category: cloud-platform
expires: 2018-06-30
---
## Live 1 Migration Guide

### Overview

After some long consideration of possible options, the decision has been made to migrate from the `live-0` cluster to the new `live-1` cluster.

The reason behind this decision is based on the need to move to a dedicated AWS account, which will be much easier to support, and the need to move away from the Ireland (EU) region to the London (UK) region.

The purpose of this document is to aid development teams in migrating their existing applications from `live-0` to `live-1`.

The migration steps that need to be taken may differ for individual applications.

The following steps are for an application that is considered to be fairly normal and deployed through CircleCI.

Appending these steps are a few extra consideration points, that are not covered in the example, but may apply to your application.

### Accessing the Live-1 cluster

To access the `live-1` cluster, follow the steps in the [authentication](/tasks.html#authentication) section of this guide, and download your Kube config file.

Kubernetes provides a [brief guide](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/#set-the-kubeconfig-environment-variable) on how to set up `kubectl` to use multiple config files simultaneously.

You should now be able to switch contexts between the `live-0` and `live-1` clusters.

### Generating a new environment

Start by following the guide to generate a new environment, this follows the same process as was followed for `live-0`, and you should use the same details as you did for your environment then.

[Environment generation guide.](tasks.html#create-an-environment)

Run a `kubectl get namespaces` to check your environment has been successfully created.

### Generating a new ECR repository

Once you've generated a new environment in the `live-1` cluster, you will need to generate a new ECR repository for your application to be pushed to.

The reason why the previous ECR repo can't be used is due to the new `live-1` cluster being hosted in a separate AWS account.

If you need reminding of the ECR creation process, please see the [user documentation](tasks.html#creating-an-ecr-repository).

### Changing the CircleCI environment variables

Now that you have a new empty environment and ECR repository set-up, the next step is to point your existing CircleCI pipeline away from the `live-0` environment, to your new `live-1` environment.

This is done by replacing the CircleCI environment variables with the ones generated for your `live-1` environment and then rerunning the pipeline.

Our helper script expects environment variables to be named according to the list below where `<ENVIRONMENT>` should be replaced by some identifier of your choosing (eg.: `STAGING`, `PRODUCTION`).

The environment variables you will need to replace are as follows:

| Variable   |            |
|----------|:-------------:|
| `AWS_DEFAULT_REGION` |  The default region will now be `eu-west-2`. |
| `AWS_ACCESS_KEY_ID` | The access key can be found in the secret created by the ECR generation. This requires base64 decoding.   |
| `AWS_SECRET_ACCESS_KEY` |  The secret key can be found in the secret created by the ECR generation. This requires base64 decoding. |
| `ECR_ENDPOINT` |    The ECR endpoint for all repos in `live-1` is `754256621582.dkr.ecr.eu-west-2.amazonaws.com`   |
| `K8S_<ENVIRONMENT>_CLUSTER_CERT` |  The cert is an attribute found in the `default-token` secret and does not need base64 decoding. |
| `K8S_<ENVIRONMENT>_CLUSTER_NAME` |    The cluster name is `live-1.cloud-platform.service.justice.gov.uk`  |
| `K8S_<ENVIRONMENT>_NAMESPACE` |  This variable should be equal to the name of your namespace. |
| `K8S_<ENVIRONMENT>_TOKEN` |    The token is another attribute found in the `default-token` secret and needs base64 decoding.   |

After triggering the CircleCI pipeline, your application should now deploy into your new environment.

### Deleting your Live-0 deployment

The last thing you will need to do is to delete your application from the `live-0` cluster.

Please see the documentation on [cleaning up within the Cloud Platform](archive.html#cleaning-up).

### Other considerations

#### PodSecurityPolicy
In the `live-1` cluster we are introducing a restrictive [`PodSecurityPolicy`](https://kubernetes.io/docs/concepts/policy/pod-security-policy/) as part of our effort to harden the cluster and provide a stable, secure and reliable service.

The major change this brings is that root containers are not allowed to run. What this means is that the containers that run on the platform need to run as a non-root user. The [solution](https://github.com/ministryofjustice/cloud-platform-multi-container-demo-app/blob/9ad6caf101cc21117742e5ab2cbe5507efd54efd/rails-app/Dockerfile) is straightforward for images we build: by using the `USER` directive in the `Dockerfile` with a **numeric uid**.

Sometimes we use images built by third parties which may or may not have taken the steps to build them as non-root images. One such very common example is nginx from the dockerhub library. If you need to run an nginx container we recommend that you use the [`bitnami/nginx`](https://github.com/bitnami/bitnami-docker-nginx) image.

See [here](https://docs.bitnami.com/containers/how-to/work-with-non-root-containers/) for more information on non-root containers.
