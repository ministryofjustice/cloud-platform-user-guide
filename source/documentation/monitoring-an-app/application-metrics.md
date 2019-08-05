### Getting application metrics into Prometheus

#### Overview
Prometheus Operator allows you to declaratively specify how services should be monitored in the Cloud Platform through the use of a `ServiceMonitor`. A `ServiceMonitor` is a custom resource definition ([CRD](https://kubernetes.io/docs/tasks/access-kubernetes-api/custom-resources/custom-resource-definitions/)) that allows you to automatically generate Prometheus scrape configuration based on a specified resource. Once an exposed application endpoint has been exported and scraped, you can query application information from the [Cloud Platform Promtheus instance](https://prometheus.service.justice.gov.uk), creating triggered alarms and Grafana dashboards as you wish.

In this document, we will explore exporting application metrics further using the [Ruby reference application](https://github.com/ministryofjustice/cloud-platform-multi-container-demo-app) and the [Prometheus Ruby client](https://github.com/prometheus/client_ruby). We intend to expose a HTTP requests endpoint using [Rack middleware](http://rack.github.io/), which we can then query with a promql search in the Cloud Platform [Prometheus](https://prometheus.cloud-platform.service.justice.gov.uk).

#### Assumptions
To keep this document short we will assume you already have an application up and running in a namespace on the Cloud Platform, if not, please see [Deploying a multi-container to the Cloud Platform](https://user-guide.cloud-platform.service.justice.gov.uk/tasks.html#deploying-a-multi-container-application-to-the-cloud-platform).

#### Changing the application code
The [application](https://github.com/ministryofjustice/cloud-platform-multi-container-demo-app) we're using in this example is a simple (by its own definition) rails application, which we'll have installed in our own namespace. As we're using Ruby we'll need to install the `prometheus-client `gem that will eventually give us a `/metric` endpoint. 

Simply add the gem to your Gemfile and install with bundler (if your following on with your own application, you may need to install the `rack` middleware gem). 
```
gem `prometheus-client`
```

Next we need to amend the `config.ru` file and inclued the two `rack` middlewares required by the `prometheus-client`. 
```
# config.ru
require_relative 'config/environment'
require 'prometheus/middleware/collector'
require 'prometheus/middleware/exporter'

use Prometheus::Middleware::Collector
use Prometheus::Middleware::Exporter

run Rails.application
```

If you're running this locally, you'll now be able to query your `/metrics` endpoint and display an output. 
```
curl localhost:3000/metrics
```

Build, tag and push your application changes to your code repository and deploy the latest version into your Cloud Platform namespace. Confirm your `/metrics` endpoint is now accessible from your url. 
```
curl https://myapp.cloud-platform/metrics
```

#### Add Service endpoint and ServiceMonitor

We need to expose the metrics endpoint with a `Service` and tell the Cloud Platform Prometheus to scrape the endpoint with `ServiceMonitor` object in Kubernetes. In this example, we're using the same port to expose both our application and metrics endpoint so we'll need to query our existing `Service` for the current port name and number. However, if you're exposing a different port you'll need to either amend your current `Service` or create a new one. 

Let's find out our current port name and number by running:
```
kubectl get svc -n <namespace>
```

Create and apply your service monitor `<application>-serviceMonitor.yaml`, as below:

```yaml
   apiVersion: monitoring.coreos.com/v1
   kind: ServiceMonitor
   metadata:
     name: rails-app-service
   spec:
     selector:
       matchLabels:
         app: rails-app-service
     endpoints:
     - port: http # this is the port name you grabbed from your running service
       interval: 15s
   ```

This will tell Prometheus to go and scrape that endpoint every 15 seconds and store any exposed metrics.

#### Add a NetworkPolicy resource
 
By default, all connections from outside a namespace are blocked, therefore a network policy is required for the `monitoring` namespace to be able to connect into an application namespace to scrape the metrics endpoint.

Create and apply a new resource `<application>-networkPolicy.yaml`, as below:

```yaml
   kind: NetworkPolicy
   apiVersion: networking.k8s.io/v1
   metadata:
     name: allow-prometheus-scraping
     namespace: my-app-namespace
   spec:
     podSelector:
       matchLabels:
         app: rails-app
     policyTypes:                                                                                                                                                         
     - Ingress
     ingress:
     - from:
       - namespaceSelector:
           matchLabels:
             component: monitoring
   ```

#### Querying metrics

Now we've exposed our metrics and asked Prometheus to scrape application latency, we can head over to the UI and see our service appear in Prometheus [targets](https://prometheus.cloud-platform.service.justice.gov.uk/targets).

Head to https://prometheus.cloud-platform.service.justice.gov.uk/graph and use the following promql query to view the application latency (remembering to change the namespace value):
```
http_server_request_duration_seconds_sum{namespace="my-namespace"}
```

#### Example in full
If you'd like to see the changes I've made to the [cloud-platform-multi-container-demo-app](https://github.com/ministryofjustice/cloud-platform-multi-container-demo-app), please see this [PR](https://github.com/ministryofjustice/cloud-platform-multi-container-demo-app/pull/7).


#### More information on Service Monitors

[CoreOS Blog on Prometheus Operator and ServiceMonitor](https://coreos.com/blog/the-prometheus-operator.html)
[CoreOS README on Custom Resource Definitions](https://github.com/coreos/prometheus-operator#customresourcedefinitions)
[Example ServiceMonitors](https://coreos.com/operators/prometheus/docs/latest/user-guides/running-exporters.html)

#### Advisory note: Applications configured to use multiple processes

If you're using a pre-forking web server (like unicorn or puma for Ruby, or gunicorn for Python) and have it configured to use multiple processes, then you need to use a Prometheus client library which supports exporting metrics from multiple processes. Not all the official clients do that. If you don't use a library which supports this, then requests to `/metrics` could be served by any of the processes, which would mean Prometheus sees inconsistent data on each scrape
Prometheus collects metrics from monitored targets by scraping metrics HTTP endpoints on these targets. There are two ways to create a metrics endpoint. The first is when the metrics endpoint is embedded within the application referred to as `instrumentation`. The second is when the metrics endpoint is part of a deployed process that bridges the gap between Prometheus and systems that do not export metrics in the prometheus format, this is called an `exporter`.
