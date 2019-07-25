### Time Zone Cronjobs

#### Overview

There may be a requirement for some Cronjobs to run at specific times of a day in the UK (including during BST), but Kubernetes Cronjob does not support time zone, our cluster uses UTC timezone internally, and we have no plans to change this. To enable service teams to run cronjobs at specific times, we deployed [TZ Cronjobber][hiddeco-cronjobber](cronjob controller for Kubernetes with support for time zones).

#### Usage

Instead of creating a CronJob like you normally would, you create a TZCronJob, which works exactly the same but supports an additional field: `.spec.timezone`. Set this to the time zone you wish to schedule your jobs in and Cronjobber will take care of the rest.

In the below example timezone is set to "Europe/Amsterdam" and scheduled every day at 14:10, so during BST it will trigger at 13:10, which helps for some cron jobs to run at specific times of a day in the UK (including during BST).

example:

```
apiVersion: cronjobber.hidde.co/v1alpha1
kind: TZCronJob
metadata:
  name: hello
spec:
  schedule: "10 14 * * *"
  timezone: "Europe/Amsterdam"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: hello
            image: bitnami/nginx:latest
            args:
            - /bin/sh
            - -c
            - date; echo "Hello, World!"
          restartPolicy: OnFailure
```

#### Applying tzcronjob in your Namespace

Using the above example create an tzcronjob.yaml and apply the TZCronjob to your namespace in the kubernetes cluster, this runs a job periodically on a given schedule as per the timezone used.

      ```
      kubectl apply --filename tzcronjob.yaml --namespace [your namespace]
      ```

Verify the tzcronjob is created, and job is triggered on a given schedule as per the timezone used.

      ```
      kubectl get tzcronjob --namespace [your namespace]
      ```


[hiddeco-cronjobber]: https://github.com/hiddeco/cronjobber

