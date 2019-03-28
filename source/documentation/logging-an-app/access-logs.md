## Accessing Application Log Data

### Overview

This document is intended to assist engineers in accessing application and system logs stored in a centralized Elasticsearch cluster. 

### Access Kibana

The Cloud Platform collects, indexes and presents your application and system log data enabling you to query using Kibana’s standard query language (based on Lucene query syntax).

To access Kibana, follow the appropriate link below:

#### Live-1 Cluster
https://kibana.apps.live-1.cloud-platform.service.justice.gov.uk/_plugin/kibana/

#### Live-0 Cluster 
https://kibana.apps.cloud-platform-live-0.k8s.integration.dsd.io/_plugin/kibana/

### Using Kibana

As a quick example, we will filter down to the logs of a particular environment.

1) On the Kibana dashboard, select the 'Discover' tab.

2) Select 'Add a filter +'

3) Filter `kubernetes.namespace_name`, with operator `is` and the value equal to your environment name.

More in-depth guides on using Kibana can be found below:

[https://www.elastic.co/guide/en/kibana/6.3/search.html](https://www.elastic.co/guide/en/kibana/6.3/search.html)

[https://www.elastic.co/guide/en/beats/packetbeat/current/kibana-queries-filters.html](https://www.elastic.co/guide/en/beats/packetbeat/current/kibana-queries-filters.html)