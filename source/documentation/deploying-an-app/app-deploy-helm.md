### Deploying an application to the Cloud Platform with Helm

#### Introduction
This document will act as a guide to your first application deployment into the Cloud Platform. If you have any issues completing the objective or have any suggestions please feel free to drop use a line in the `#ask-cloud-platform` slack channel.

##### Objective
By the end of this guide you'll have deployed a reference [Django application](https://github.com/ministryofjustice/cloud-platform-reference-app) to a cluster using the Kubernetes package manager [Helm](https://helm.sh/).

_Disclaimer: You'll see fairly quickly that the application is not fit for production. A perfect example of this is the [plaintext secrets file](https://github.com/ministryofjustice/cloud-platform-reference-app/blob/master/helm_deploy/django-app/templates/secret.yaml). For the reference application we've left this file in plaintext but it **must** be encrypted when writing your own manifests for production/non-production work in the MoJ._

##### Requirements
It is assumed you have the following:

 - You have a basic understanding of what [Kubernetes](https://kubernetes.io/) is.
 - You have [created an environment for your application][env-create]
 - You have installed [Kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) on your local machine.
 - You have [Authenticated][auth-to-cluster] to the cloud-platform-live-1 cluster.

#### Deploy the app
The reference application we're going to use is a very simple Django application with an on-cluster Postgresql database.

> Note: Even though we are going to install a database within the Kubernetes cluster, it is recommended to use a database as a service offering such as [AWS RDS](https://aws.amazon.com/rds/) if running in production.

The Helm deployment manifests have been pre-written for this exercise. But if you wish to know more about these files and what they do have a quick browse of the [README](https://github.com/ministryofjustice/cloud-platform-reference-app/tree/master/helm_deploy/django-app/README.md).

##### Set up
First we need to clone our reference application and change directory:

    $ git clone https://github.com/ministryofjustice/cloud-platform-reference-app.git
    $ cd cloud-platform-reference-app

You now have a functioning git repository that contains a simple Django application. Have a browse around and get familiar with the directory structure.

##### Browse the cluster
Let's make use of the command line tool `kubectl` to browse around the cluster to see what it looks like before we deploy our application:

    $ kubectl get pods --namespace <env-name>
*The `<env-name>` here is the environment you created, listed in the requirements section at the beginning of the document.*

If you receive the below error message then you've either not typed in your namespace correctly or you don't have permission to perform a `get pods` command. Either way, you'll need to go back and review the [Creating an Environment][env-create] document previously mentioned.

    $ Error from server (Forbidden): pods is forbidden: User "test-user" cannot list pods in the namespace "demo"

##### Using Helm
Helm allows you to manage application deployment to Kubernetes using Charts. You can read about of some of the many features of [Helm Charts](https://docs.helm.sh/developing_charts/). We've chosen to use Helm as the default way to deploy applications to the Cloud Platform as it provides useful tooling as an interface to the YAML files that Kubernetes uses to run.

###### Tiller RBAC Configuration

There are two parts to Helm: The client and the Helm server (Tiller).

We will create a `Service Account` resource by adding to your `01-rbac.yaml` file. This gives Helm the permissions it needs to deploy within your namespace.

Add the following to the bottom of the `01-rbac.yaml` file you defined when you [created your environment][env-create]:

```
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: tiller
  namespace: myapp-dev ### Your namespace `<servicename-env>`
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: tiller
  namespace: myapp-dev ### Your namespace `<servicename-env>`
subjects:
- kind: ServiceAccount
  name: tiller
  namespace: myapp-dev ### Your namespace `<servicename-env>`
roleRef:
  kind: ClusterRole
  name: admin
  apiGroup: rbac.authorization.k8s.io
```

After you have added this to the file, commit it and create a pull request against the [cloud-platform-environments](https://github.com/ministryofjustice/cloud-platform-environments) master repo.

Once it is merged and applied, you will have a service account for Tiller that allows it act on your namespace. Now you have to install Helm and Tiller into your namespace.

###### Installing and configuring Helm and Tiller

Install the client via Homebrew or by other [means](https://docs.helm.sh/using_helm/#installing-helm):

    $ brew install kubernetes-helm

Now configure the installation with Tiller:

    $ helm init --tiller-namespace <env-name> --service-account tiller

When succesful, you'll be greeted with the message:

    Happy Helming

This is an indication we're ready to deploy our applicaton.

###### Application install

To deploy the application with Helm first change directory so we can focus on the app we need:

    $ cd helm_deploy/django-app/

Values for our application are stored in the `values.yaml` at the root of our directory. Configurations such as 'number of pods running' and which image repository to use is stored here in this file. Open this file and get familiar with our application layout.

There is an important value in this file called `host`, which sets the URL for your application. We have to provide this value as an argument on our installation command.

Run the following (replacing the `YourName` with your own name and `env-name` with your environment name:

        $ helm install . \
          --name django-app-<YourName> \
          --namespace <env-name> \
          --set deploy.host=django-<YourName>.apps.live-1.cloud-platform.service.justice.gov.uk \
          --tiller-namespace <env-name>

> Note: We're naming it like this as app names and host names have to be unique on the cluster.

The `set deploy.host` overwrites the value stored in my `value.yaml` file and you'll see a fairly verbose output showing your pods creating.

##### Viewing your application
Congratulations on getting this far. If all went well your pods are now deployed and is now being served on your specified URL.

Let's check:

    $ kubectl get pods --namespace <env-name>

If the deploy was successful you should be greeted with something similar to the below:

```
NAME                                           READY     STATUS    RESTARTS   AGE
django-app-<Name>-fcc657679-w69cr               1/1       Running   1          39m
django-app-<Name>-fcc657679-c5wdm               1/1       Running   1          39m
django-app-<Name>-db-migration-dgnse-qgs7r      0/1       Completed 0          39m
django-app-<Name>-postgresql-7b4bdff4b8-xdlw2   1/1       Running   0          39m
```
You should have a postgres pod and 2 app pods **ready** with the status **running**.

(There's also a line for a pod which ran the initial database migrations, but that's completed and no longer running so we'll ignore it.)

Let's check your host has a URL by running:

    $ kubectl get ingress --namespace <env-name>

This will return the URL of your given app. Open it using your favourite browser.

You should be met with an MoJ reference app with the title, *'Cloud Platforms Deployment'*. As we mentioned before, there is nothing complicated about this application. You can enter your name and job role, calling the on-cluster postgresql database.

##### View the logs
Each pod will generate logs that can be viewed via the API. Let's have a browse of our application logs.

First grab the pod name:

    $ kubectl get pods --namespace <env-name>

Then copy the name of a pod that isn't postgresql.

 ```
   NAME                                           READY     STATUS    RESTARTS   AGE
 * django-app-<name>-fcc657679-w69cr               1/1       Running   1          54m
   django-app-<name>-fcc657679-c5wdm               1/1       Running   1          39m
   django-app-<name>-postgresql-7b4bdff4b8-xdlw2   1/1       Running   0          54m
```

We're going to follow the log, so we'll run:

    $ kubectl logs django-app-<name>-fcc657679-w69cr --namespace <env-name> -f

As you can see, this tails the log and you should see our health checks giving a HTTP 200.

Read more about Kubernetes logging [here](https://kubernetes.io/docs/concepts/cluster-administration/logging/).

##### Scale the application
You now have our application up and running but you decide two pods aren't enough. Say you want to run three. This is simply a case of changing the replicaCount value in the values.yaml whilst running the `helm upgrade` command.

Let's try:

    $ helm upgrade django-app-<YourName> . --set replicaCount=3 --tiller-namespace <env-name> --set deploy.host=<DeploymentURL>

This command spins up another pod to bring the total number to 3.

If we run the familiar command we've been using:

    $ kubectl get pods --namespace <env-var>

You'll see the pod replication in progress.

##### Tear it all down
Finally, we have built are app and deployed to the cluster. There is only one thing left to do. Destroy it.

To delete the deployment you simply run:

    $ helm del --purge django-app-<YourName> --tiller-namespace <env-name>

And then confirm the pods are terminating as expected:

    $ kubectl get pods --namespace <env-var>

#### Next steps
The next step will be to create your own Helm Chart. You can try this with an application of your own or run through [Bitnami's excellent guide](https://docs.bitnami.com/kubernetes/how-to/create-your-first-helm-chart/) on how to build using a simple quickstart.

[env-create]: tasks.html#creating-a-cloud-platform-environment
[auth-to-cluster]: tasks.html#authentication
