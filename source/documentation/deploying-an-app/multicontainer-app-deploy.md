### Deploying a multi-container application to the Cloud Platform

#### Overview

This section goes through the process of deploying a [demo application][multi-demo] consisting of several components, each running in its own container.

Please see the [application README][multi-demo-readme] for a description of the different components, and how they connect. You can also run the application locally via docker-compose to confirm that it works as it should.

#### Running in the Kubernetes Cluster

In the [Cloud Platform][cloudplatform] kubernetes cluster, the application will be set up like this:

![Multi-container architecture diagram](../images/multi-container-k8s.png)

Each container needs a [Deployment][k8s-deployment] which will contain a [Pod][k8s-pod]. [Services][k8s-service] make pods available on the cluster's internal network, and an [Ingress][k8s-ingress] exposes one or more services to the outside world.

#### Create an RDS instance

The application database will be an Amazon RDS instance. To create this, refer to the [cloud platform RDS][rds-module] repository, and create a terraform file in your sub-directory of the [cloud platform environments][cp-env] repository (you will need to raise a PR for this, and get the cloud platform team to approve it).

For more information see [Adding AWS resources to your environment][add-aws-resources].

#### Build docker images and pushing to ECR

As before, we need to build docker images which we will push to our [Amazon ECR][ecr].

Please carry out the following steps on your own working copy of the [demo application][multi-demo].

For `team_name` and `repo_name` please use the values from your `ecr.tf` file, when you [created your ECR][ecr-setup].

```
cd rails-app
docker build -t [team_name]/[repo_name]:rails-app .
docker tag [team_name]/[repo_name]:rails-app 926803513772.dkr.ecr.eu-west-1.amazonaws.com/[team_name]/[repo_name]:rails-app-1.0
docker push 926803513772.dkr.ecr.eu-west-1.amazonaws.com/[team_name]/[repo_name]:rails-app-1.0
```

Note that we are overloading the tag value to push multiple different containers to a single Amazon ECR. This is because of a quirk in the way Amazon ECR refers to `image repositories` and `images`.

Repeat the steps above for the `content-api` and `worker` sub-directories (changing `rails-app` as appropriate, in the commands).

The `makefile` in the [demo application][multi-demo] contains commands to make this process easier. Don't forget to edit the values for `TEAM_NAME`, `REPO_NAME` and `VERSION` appropriately.

#### Kubernetes configuration

As per the diagram, we need to configure six objects in kubernetes - 3 deployments, 2 services and 1 ingress.

You can see these YAML config files in the `kubernetes_deploy` directory of the [demo application][multi-demo].

Note: The yaml files in the github repository have the namespace name `davids-dummy-dev`, team name `davids-dummy-team` and application name `davids-dummy-app`. You will need to change these to the corresponding values for your situation, and also the full names of your docker images.

You may also need to change the `host` entry in the `ingress.yaml` file, if someone else has deployed an instance of the demo application using the same hostname.

In `rails-app-deployment.yaml` and `worker-deployment.yaml` you can see the configuration for two environment variables:

* `DATABASE_URL` is retrieved from the kubernetes secret which was created when the RDS instance was set up
* `CONTENT_API_URL` uses the name and port defined in `content-api-service.yaml`

#### Deploying to the cluster

After you have built and pushed your docker images, and made the corresponding changes to the `kubernetes_deploy/*.yaml` files, you can apply the configuration to your namespace in the kubernetes cluster:

      kubectl apply --filename kubernetes_deploy --namespace [your namespace]

#### Interacting with the application

You should be able to view the application in your browser at:

      https://multi-container-demo.apps.cloud-platform-live-0.k8s.integration.dsd.io/

It should behave in the same way as when you were running it locally via docker-compose.

[multi-demo]: https://github.com/ministryofjustice/cloud-platform-multi-container-demo-app
[multi-demo-readme]: https://github.com/ministryofjustice/cloud-platform-multi-container-demo-app#multi-container-demo-application
[cloudplatform]: https://github.com/ministryofjustice/cloud-platform
[k8s-deployment]: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
[k8s-pod]: https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/
[k8s-service]: https://kubernetes.io/docs/concepts/services-networking/service/
[k8s-ingress]: https://kubernetes.io/docs/concepts/services-networking/ingress/
[ecr]: https://aws.amazon.com/ecr/
[rds-module]: https://github.com/ministryofjustice/cloud-platform-terraform-rds-instance
[cp-env]: https://github.com/ministryofjustice/cloud-platform-environments
[ecr-setup]: tasks.html#creating-an-ecr-repository
[add-aws-resources]: archive.html#adding-aws-resources-to-your-environment
