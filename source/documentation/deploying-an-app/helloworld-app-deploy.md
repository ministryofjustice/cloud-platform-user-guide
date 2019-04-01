### Deploying a 'Hello World' application to the Cloud Platform

![Deployment Process Diagram](../images/k8s-cluster-application-deployment-process.png)

#### Overview

The aim of this guide is to walkthrough the process of deploying an application into the Cloud Platform.

This guide uses a pre-configured ["Hello World" application][rubyapp-github] as an example of how to deploy your own. This application merely returns a static HTML response, and has no dependencies. Later examples will use more representative applications.

The process we will follow consists of the following stages:

* Build a docker image from the demo application
* Tag the image and push it to your ECR
* Edit kubernetes config files
* Apply the config files to make the cluster run our application

The process of building an image and pushing it to an ECR will normally be carried out by a build pipeline. For this initial walkthrough, we will go through these steps manually. Later we will go through an example of setting up a [CircleCI][circleci] job to do this automatically. The steps are similar if you're using other CI/CD tools such as [TravisCI][travisci].

#### Prerequisites

This guide assumes the following:

* [Docker][docker] is installed and configured.
* Kubectl is installed and configured (`brew install kubectl` on a Mac with [Homebrew][homebrew] installed)
* AWS CLI is installed (`brew install awscli` on a Mac with [Homebrew][homebrew] installed)
* You have [created an environment for your application][env-create]
* You have [created an Amazon ECR][ecr-setup] to host your docker image

#### Step 1 - Build your docker image

* Clone the [demo application](https://github.com/ministryofjustice/cloud-platform-helloworld-ruby-app)

      git clone https://github.com/ministryofjustice/cloud-platform-helloworld-ruby-app
      cd cloud-platform-helloworld-ruby-app

* Build the docker image

      docker build -t [ECR Team Name]/[ECR Repository Name] .

The `ECR Team Name` and `ECR Repository Name` must match the `team_name` and `repo_name` values you entered when you created the ECR via [cloud-platform-environments](https://github.com/ministryofjustice/cloud-platform-environments) Github repository.

You can find them in the file `namespaces/cloud-platform-live-0.k8s.integration.dsd.io/[YOUR ENVIRONMENT]/resources/ecr.tf`.

##### Amazon ECR Terminology

Amazon ECR uses the terms `repository` and `image` in a rather confusing way. Normally, you would think of a docker image repository as holding mutiple images, each with a different name, where each image can have multiple tags. Amazon ECR conflates the repository and image - i.e. you can only push images with the same name to a given ECR.

So, if you created your ECR using the team_name `davids-dummy-team` and repo_name `davids-dummy-app`, then you can only push images to the ECR if they are named `davids-dummy-team/davids-dummy-app:[something]`. You are free to change the tag of the image (shown as [something], here), and some teams overload the tag value as a way to store multiple completely different docker images in a single ECR.

#### Step 2 - Push the image to your ECR

##### Authenticating to your docker image repository

You must authenticate to the docker image repository before you can push an image to it.

To authenticate to your ECR, you will need the `access_key_id` and `secret_access_key` which were created for you when you created your ECR. To retrieve these, see the [this section][access-ecr-credentials] of this guide.

*tl;dr* use this command:

      kubectl -n [namespace_name] get secret [name of your secret] -o yaml

Don't forget to base64 decode the `access_key_id` and `secret_access_key` values before using them.

      echo 'your_access_key_id_value' | base64 --decode

Once you have your `access_key_id` and `secret_access_key`, set up an AWS profile using the AWS cli tool.

      aws configure

Supply your credentials when prompted.

This guide assumes you are using these credentials in your `default` AWS profile. If you have used a different name for this AWS profile, please add `--profile [YOUR PROFILE]` to all of the following AWS commands.

##### Authenticating with the repository

Use the following command to login to Amazon ECR

      $(aws ecr get-login --no-include-email --region eu-west-1)

Note: The output of the `aws ecr...` command is a long `docker login...` command. Including the `$(...)` around the command executes this output in the context of the current shell

The output of the above should include `Login Succeeded` to confirm you have authenticated to the docker image repository.

These credential are valid for 12 hours. So, if you are working through this example over a longer period, you will have to login again, e.g. the following day.

##### Pushing your docker image to the ECR

All of the MoJ Digital docker images are stored within the same Cloud Platform AWS account (mojds-platforms-integration).

Your specific ECR will be:

      926803513772.dkr.ecr.eu-west-1.amazonaws.com/[team_name]/[repo_name]

Where `team_name` and `repo_name` are the values from your `ecr.tf` file.

Ensure the Docker image for your application has been built and is stored locally on your machine.

      docker build -t [team_name]/[repo_name] .

Now we need to tag the image so it can be pushed into the correct repository.

      docker tag [team_name]/[repo_name]:latest 926803513772.dkr.ecr.eu-west-1.amazonaws.com/[team_name]/[repo_name]:latest

Finish by running the last command to push the image to your repository.

    docker push 926803513772.dkr.ecr.eu-west-1.amazonaws.com/[team_name]/[repo_name]:latest

#### Step 3 - Configure your namespace in the Kubernetes Cluster

To deploy an application to the Cloud Platform, a number of deployment files must first be configured. You can find examples of these in the `kubectl_deploy` directory of the [demo application][rubyapp-github], but you will need to edit your copy to replace some of the values to use your kubernetes cluster environment and docker image.

*Tip:* You can find more deployment config info [in the kubernetes developer documentation](https://kubernetes.io/docs/tasks/run-application/run-stateless-application-deployment/).

##### deployment.yaml

```Yaml
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: helloworld-rubyapp
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: helloworld-rubyapp
    spec:
      containers:
      - name: rubyapp
        image: 926803513772.dkr.ecr.eu-west-1.amazonaws.com/davids-dummy-team/davids-dummy-app:latest
        ports:
        - containerPort: 4567
```

This file tells Kubernetes to run a single pod (`replicas: 1`) containing a single container based on a specific docker image from your ECR.

Change the image value to refer to the image you pushed to your ECR in the earlier step.

The `service.yaml` and `ingress.yaml` files make it possible to access your application from the outside world.

##### service.yaml

Service files are used to specify port and protocol information for your application and are also used to bundle together the set of pods created by the deployment.

This exposes port 4567 internally to your namespace. i.e. it enables pods and other objects within your namespace to connect to port 4567 of your container.

```Yaml
apiVersion: v1
kind: Service
metadata:
  name: rubyapp-service
  labels:
    app: rubyapp-service
spec:
  ports:
  - port: 4567
    name: http
    targetPort: 4567
  selector:
    app: helloworld-rubyapp
```

The value of `spec/selector/app` must be the same as `spec/template/metadata/labels/app` in the `deployment.yml` file.

*Tip:* You can find more info on service definition in the [kubernetes docs](https://kubernetes.io/docs/tasks/access-application-cluster/service-access-application-cluster/).

##### ingress.yaml

Ingress files are to use to define external access to the application.

This creates an [ingress controller](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/) to enable network connections from outside of the cluster.

Note: Because we are specifying `http`, this ingress controller will expose port 80, and will redirect connections to port 4567 of the named service.

```Yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: helloworld-rubyapp-ingress
spec:
  rules:
  - host: helloworld-rubyapp.apps.cloud-platform-live-0.k8s.integration.dsd.io
    http:
      paths:
      - path: /
        backend:
          serviceName: rubyapp-service
          servicePort: 4567
```

The value of `serviceName` and `servicePort` must be the same as those specified in the `service.yml` file.

Change the `helloworld-rubyapp` prefix of the `host` string to the value you want to use as the hostname part of the URL on which your application will be available to the world (do not change the `.apps.cloud-platform...` part).


*Tip:* You can find more info on ingress in the [kubernetes docs](https://kubernetes.io/docs/concepts/services-networking/ingress/)

#### Step 4 - Deploy the application

With all of the deployment files configured, you can now deploy your application to the Cloud Platform.

Start by listing the namespaces on the cluster you are connected to:

      kubectl get namespaces

The list that gets returned should include the one you [created earlier][env-create], here we assume it is called `davids-dummy-dev`. Please change that to whatever your namespace (environment) is called, in all of the following commands.

To deploy your application run the following command. This command assumes that the current directory is the root directory of your working copy of the [demo application][rubyapp-github]. i.e. `kubectl_deploy` points to the directory where the deployment files are stored.

      kubectl create --filename kubectl_deploy --namespace davids-dummy-dev

You have to specify the namespace you want to deploy to, this should be the namespace of the environment you created.

Confirm the deployment with:

      kubectl get pods --namespace davids-dummy-dev

#### Interacting with the application

With the application deployed into the Cloud Platform, there are a few ways of managing it:

* **View pods** - `kubectl get pods --namespace davids-dummy-dev`
* **Check host** - `kubectl get ingress --namespace davids-dummy-dev`
* **Delete application** - `kubectl delete --filename kubectl_deploy --namespace davids-dummy-dev`
* **Shell into container** - `kubectl exec --stdin --tty --namespace davids-dummy-dev [POD-NAME] -- /bin/sh`

For `[POD-NAME]` use the value returned by the `kubectl get pods...` command


*Tip:* You can find more about the `kubectl` command [here](https://kubernetes.io/docs/reference/kubectl/overview/)

You should be able to view the app. at the following URL:

      curl -L http://helloworld-rubyapp.apps.cloud-platform-live-0.k8s.integration.dsd.io

Don't forget to change `helloworld-rubyapp` to whatever hostname you chose earlier.

Note: You need the `-L` flag to make curl follow the 308 redirect response that it will receive from the ingress controller. If you view the URL in a web browser, it should just work.

[rubyapp-github]: https://github.com/ministryofjustice/cloud-platform-helloworld-ruby-app
[homebrew]: https://brew.sh
[docker]: https://www.docker.com
[circleci]: https://circleci.com
[travisci]: https://travis-ci.org
[ecr-setup]: getting-started.html##creating-an-ecr-repository
[access-ecr-credentials]: getting-started.html##accessing-the-credentials
[env-create]: getting-started.html##creating-a-cloud-platform-environment
