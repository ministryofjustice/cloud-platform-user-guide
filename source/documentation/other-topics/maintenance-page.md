## Applying a Maintenance Page

### Overview

This document will serve as a guide on how to apply a default
maintenance page to your application on the Cloud Platform.

### Deploying the page

A repository has been created to store all the files related to the
maintenance page:

[cloud-platform-maintenance-page](https://github.com/ministryofjustice/cloud-platform-maintenance-page)

The repository contains the manifest files needed to deploy a
standard maintenance page into your namespace. This directory also
contains the maintenance page HTML file, along with a DockerFile
to build an image to serve the maintenance page.

Within the `Kubectl_deploy` directory, there are 3 simple manifest
files that make up the deployment, `deploy.yaml`, `ingress.yaml`
and `service.yaml`.

To use this example, copy the files into your namespace and make
any changes you require, to tailor the maintenance page to your
service.

Once you have done this, the maintenance page will be deployed
into your namespace, ready for you to use as and when you need
it.

#### maintenance-deploy.yaml

A notable part of this file is the `image` line, which points to
the ECR URI.

If you wish to customize the maintenance page, you must edit and
build the image and update the `image` value.

#### maintenance-ingress.yaml

In this file, change the example `host` field to your applications
URL.

Rather than using this file, you may prefer to change your existing
`Ingress` so that the `backend` points to your maintenance page,
whenever you need to replace your service with the maintenance page.

This will ensure that you do not incur any downtime (by deleting
the previous ingress and creating a new one).

