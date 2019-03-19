## Creating your own custom alerts

### Overview
Alertmanager allows you define your own alert conditions based on [Prometheus expression language](https://prometheus.io/docs/prometheus/latest/querying/basics) expressions.

The aim of this document is to provide you with the necessary information to create and send application specific alerts to a Slack channel of your choosing.

### Prerequisites
This guide assumes the following:

* You have [created a namespace for your application][env-create]

### Creating a slack webhook and amend Alertmanager
This step requires the Cloud Platform team to create a receiver in [Alertmanager](https://github.com/ministryofjustice/cloud-platform-infrastructure/blob/master/terraform/cloud-platform-components/templates/prometheus-operator.yaml.tpl##L115) and a [Slack webhook](https://api.slack.com/incoming-webhooks).

Create a ticket to request a new alert route in Alertmanager. The team will need the following information:

- namespace name
- team name
- application name
- slack channel

The team will provide you with a "`custom severity level`" that'll need to be defined in the next step. Please copy it to your clipboard.

### Create a PrometheusRule
A `PrometheusRule` is a custom resource that defines your triggered alert. This file will contain the alert name, promql expression and time of check.

To create your own custom alert you'll need to fill in the template below and deploy it to your namespace (tip: you can check rules in your namespace by running `kubectl get prometheusrule -n <namespace>`).

- Create a file called `prometheus-custom-rules-<application_name>.yaml`
- Copy in the template below and replace the bracket values, specifying the requirements of your alert. The `<custom_severity_level>` field is the value you were passed earlier.

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  namespace: <namespace>
  labels:
    role: alert-rules
  name: prometheus-custom-rules-<application_name>
spec:
  groups:
  - name: application-rules
    rules:
    - alert: <alert_name>
      expr: <alert_query>
      for: <check_time_length>
      labels:
        severity: <custom_severity_level>
      annotations:
        message: <alert_message>
        runbook_url: <http://my-support-docs>
```
- Run `kubectl apply -f prometheus-custom-rules-<application_name>.yaml -n <namespace>`

A working example of this would be:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  creationTimestamp: null
  namespace: monitoring
  labels:
    role: alert-rules
  name: prometheus-custom-rules-my-application
spec:
  groups:
  - name: node.rules
    rules:
    - alert: Quota-Exceeded
      expr: 100 * kube_resourcequota{job="kube-state-metrics",type="used",namespace="monitoring"} / ignoring(instance, job, type) (kube_resourcequota{job="kube-state-metrics",type="hard"} > 0) > 90
      for: 5m
      labels:
        severity: cp-team
      annotations:
        message: Namespace {{ $labels.namespace }} is using {{ printf "%0.0f" $value}}% of its {{ $labels.resource }} quota.
        runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md##alert-name-kubequotaexceeded
```

The `alert` name, `message` and `runbook_url` annotations will be sent to the Slack channel when the rule has been triggered.

You can view the applied rules with the following command:

```sh
kubectl -n <namespace> describe prometheusrules prometheus-custom-rules-<application_name>
```

### PrometheusRule examples
If you're struggling for ideas on how and which alerts to setup, please see some examples [here](https://github.com/ministryofjustice/cloud-platform-infrastructure/blob/master/terraform/cloud-platform-components/resources/prometheusrule-examples/application-alerts.yaml).

### Further reading
- [Prometheus Operator - Getting Started](https://github.com/coreos/prometheus-operator/blob/master/Documentation/user-guides/getting-started.md)
- [Alerting](https://github.com/coreos/prometheus-operator/blob/master/Documentation/user-guides/alerting.md)

[env-create]: getting-started.html#creating-a-cloud-platform-environment
