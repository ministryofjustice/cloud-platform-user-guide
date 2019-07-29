### Kubernetes Cronjobs

#### Overview

Kubernetes has the concept of [Cronjobs][kubernetes-cronjobs] which creates Jobs on a time-based schedule, you can use CronJobs to run tasks at a specific time or interval. CronJobs are a good choice for automatic tasks, such as backups, reporting, sending emails, or cleanup tasks. 

#### Usage

CronJobs use [Job][kubernetes-jobs] objects to complete their tasks. A CronJob creates a Job object each time it runs. CronJobs are created, managed, scaled, and deleted in the same way as Jobs. Cron jobs require a config file, follow the [guide][cron-jobs] on creating a Cronjob. 

This example cron job below prints the current time and a hello message every first minute of every hour from 0200 to 1400 UTC on Sunday, Monday, Friday, and Saturday

example:

```
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: hello
spec:
  schedule: "1 2-14 * * 0-1,5-6"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: hello
            image: busybox
            args:
            - /bin/sh
            - -c
            - date; echo "Hello, World!"
          restartPolicy: OnFailure
```

#### Applying Cronjob in your Namespace

You need a yaml file to define your cronjob. You can either create your own, or use [this one][cronjob-yaml] as an example. This runs a job periodically on a given schedule to delete untagged images in the ecr-repo, this will help to limit the count of Images in the ecr-repo.

      ```
      kubectl apply --filename cronjob-ecr.yaml --namespace [your namespace]
      ```

Verify the Cronjob is created, and job is triggered on a given schedule.

      ```
      kubectl get cronjob --namespace [your namespace]
      ```

Note:
Kubernetes uses UTC exclusively. Make sure you take that into account when you’re creating your schedule.

[cronjob-yaml]: https://github.com/ministryofjustice/cloud-platform-multi-container-demo-app/tree/cronjob-example-v1.0/k8s_additional_resources
[cron-jobs]: https://kubernetes.io/docs/tasks/job/automated-tasks-with-cron-jobs/#creating-a-cron-job
[kubernetes-cronjobs]: https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/
[kubernetes-jobs]: https://kubernetes.io/docs/concepts/workloads/controllers/jobs-run-to-completion/
