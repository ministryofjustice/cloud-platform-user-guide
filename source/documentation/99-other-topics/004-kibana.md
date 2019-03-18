## How to access my log data using Kibana
### Introduction
This document is intended to assist engineers in accessing application and system logs stored in a centralised Elasticsearch cluster. Using a combination of Fluentd, AWS's Elasticsearch cluster and Kibana the Cloud Platform collects, indexes and presents your application and system log data enabling you to query using Kibana’s standard query language (based on Lucene query syntax). All that's required is that your application writes to stdout.

### Quick start
Live-0 cluster:
[https://kibana.apps.cloud-platform-live-0.k8s.integration.dsd.io/_plugin/kibana](https://kibana.apps.cloud-platform-live-0.k8s.integration.dsd.io/_plugin/kibana)

### How to get my data into Elasticsearch
As long as your application is writing to stdout, it'll be collected by fluentd and passed to the Elasticsearch cluster. Use one of the links above and authenticate with your GitHub username and password.
### How do I use Kibana?

[https://www.elastic.co/guide/en/kibana/6.3/search.html](https://www.elastic.co/guide/en/kibana/6.3/search.html)

[https://www.elastic.co/guide/en/beats/packetbeat/current/kibana-queries-filters.html](https://www.elastic.co/guide/en/beats/packetbeat/current/kibana-queries-filters.html)

