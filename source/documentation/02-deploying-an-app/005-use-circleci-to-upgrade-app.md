## Continuous Deployment of an application using CircleCI and Helm

### Introduction
This document covers how to continuously deploy your application in the Cloud Platform. It is essentially a continuation of [‘Deploying an application to the Cloud Platform with Helm’][deploy-helm].

*Note: This document is specific to using [CircleCI](https://circleci.com/) as the Continuous Integration method.*

#### Objective
By the end of the tutorial, you will have done the following:

- Created a Service Account for CircleCI in your namespace
- Generated a CircleCI configuration file in your application repository. The configuration file will authenticate with your chosen cluster, build a docker image and push it to ECR and upgrade your helm deployment with the new docker image.
- Have an automated CircleCI pipeline that upgrades your helm deployment when a new change is pushed to your master branch

#### Requirements
It is assumed you have the following:

 - You have [created an environment for your application](/01-getting-started/002-env-create)
 - You have [deployed an application][deploy-helm] to the 'cloud-platform-live-0' cluster using Helm.
 - You have created an [ECR repository][ecr-setup]

#### Creating a Service Account for CircleCI
As part of the CircleCI deployment pipeline, CircleCI will need to authenticate with the Kubernetes cluster. In order to do so, Kubernetes uses [Service Accounts](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/). Service Accounts provide an identity for processes that run in a cluster allowing the process to access the API server.

A Service Account is created in the [namespace creation github repository](https://github.com/ministryofjustice/cloud-platform-environments/tree/master/namespaces).
```bash
  $ kubectl get serviceaccounts --namespace $ns
  NAME       SECRETS   AGE
  circleci   1         3h

  $ kubectl get serviceaccounts/circleci --namespace reference-app -o yaml
  apiVersion: v1
  kind: ServiceAccount
  ...
  secrets:
  - name: circleci-token-prlkp

  $ kubectl get secrets --namespace $ns
  NAME                   TYPE                                  DATA      AGE
  circleci-token-prlkp   kubernetes.io/service-account-token   3         3h

  $ kubectl get secrets/circleci-token-prlkp --namespace $ns -o yaml
  ...
  namespace: cm..cA==
  token: ZX...EE=
```

#### Linking Repository to CircleCI
MoJ has as an account with CircleCI, please login to [CircleCI](https://circleci.com/dashboard) using GitHub credentials. Select project, and if config.yml is in the repo CircleCI will build and run tests.

#### Add variables to CircleCI
There is a number of environment variables that you will need to set on your CircleCI project in order to build a docker image, push it to the ECR and trigger a deployment in your environment. On the project page, click the cog icon in the top right corner and select `Enviroment Variables` under `Build Settings`. The variables you will need to set are listed below.

##### AWS credentials
To authenticate with ECR, you will need to set:
- `AWS_DEFAULT_REGION` - would be `eu-west-1` for Cloud Platform clusters unless specified otherwise
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `ECR_ENDPOINT` is optional but useful if you want to avoid having to hardcode the full hostname of the registry

##### Kubernetes `ServiceAccount` credentials
Since a single CircleCI project will need to access multiple namespaces in kubernetes (the environments), it will also need to handle multiple credentials. To simplify authentication, we provide a helper script in our supported [build image](https://github.com/ministryofjustice/cloud-platform-tools-image). For a usage example, see [Deploy To Kubernetes](##upload-to-ecr) below.

There are four different variables that CircleCI will need to access *per environment*. Our helper script expects environment variables to be named according to the list below where `<ENVIRONMENT>` should be replaced by some identifier of your choosing (eg.: `STAGING`, `PRODUCTION`).
- `KUBE_ENV_<ENVIRONMENT>_NAME` - the full name of the cluster (eg.: `cloud-platform-live-0.k8s.integration.dsd.io`)
- `KUBE_ENV_<ENVIRONMENT>_NAMESPACE` - the name of the `Namespace` (see [Create a namespace][env-create])
- `KUBE_ENV_<ENVIRONMENT>_CACERT` - the CA Certificate for the cluster, can be acquired from the `Secret` that is generated for the `ServiceAccount`
- `KUBE_ENV_<ENVIRONMENT>_TOKEN` - the access token generated for the `ServiceAccount`. Please note, you should first base64 decode the token value you retrieve from the secret [in the previous section](##creating-a-service-account-for-circleci), e.g. `echo <thereallylongstringthatyougetback> | base64 --decode`.

#### Creating the config.yml
CircleCI uses a YAML file to identify how you want your testing environment set up and what tests you want to run. On CircleCI 2.0, this file must be called ```config.yml``` and must be in a hidden folder called ```.circleci``` .

[Tutorial](https://circleci.com/docs/2.0/tutorials/) on creating a config.yml file. As long as you are building a Docker image you can configure Circle however you wish. The only additional configuration you will need to add is to upload an image to ECR and deploy to Kubernetes:

##### Upload to ECR

Example of how you can push a built docker image to an ECR repository:

```yaml
- deploy:
    name: Push application Docker image
    command: |
      $(aws ecr get-login --no-include-email)
      docker tag app "${ECR_ENDPOINT}/${GITHUB_TEAM_NAME_SLUG}/${CIRCLE_PROJECT_REPONAME}:${CIRCLE_SHA1}"
      docker push "${ECR_ENDPOINT}/${GITHUB_TEAM_NAME_SLUG}/${CIRCLE_PROJECT_REPONAME}:${CIRCLE_SHA1}"
      if [ "${CIRCLE_BRANCH}" == "master" ]; then
        docker tag app "${ECR_ENDPOINT}/${GITHUB_TEAM_NAME_SLUG}/${CIRCLE_PROJECT_REPONAME}:latest"
        docker push "${ECR_ENDPOINT}/${GITHUB_TEAM_NAME_SLUG}/${CIRCLE_PROJECT_REPONAME}:latest"
      fi
```
##### Deploy to Kubernetes

We provide a docker image that simplifies the CircleCI configuration by encapsulating the authentication process in a script. For example, given a configured `DEVELOPMENT` environment (see the section on environment variables above):

```yaml
deploy_development:
  docker:
    - image: ${ECR_ENDPOINT}/cloud-platform/tools:circleci
  steps:
    - checkout
    - deploy:
        name: Helm deployment
        command: |
          setup-kube-auth
          kubectl config use-context development
          if [ "${CIRCLE_BRANCH}" == "master" ]; then
            helm upgrade ${APPLICATON_DEPLOY_NAME} ./helm_deploy/django-app/. \
                          --install \
                          --tiller-namespace=${NON_PROD_NS} \
                          --namespace=${NON_PROD_NS} \
                          --set image.repository="${ECR_ENDPOINT}/${GITHUB_TEAM_NAME_SLUG}/${CIRCLE_PROJECT_REPONAME}" \
                          --set image.tag="latest" \
                          --set deploy.host="${APPLICATION_HOST_URL}" \
                          --set replicaCount="4" \
                          --debug
          fi
```

[deploy-helm]: deploying-applications.html#deploying-an-application-to-the-cloud-platform-with-helm
[ecr-setup]: getting-started.html#creating-an-ecr-repository
[env-create]: getting-started.html#creating-a-cloud-platform-environment
