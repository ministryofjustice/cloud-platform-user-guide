## Application Log Collection and Storage

### Overview
The Cloud Platform supports the ability for application logs to be collected, stored, and accessed.

Logs are collected automatically, via Fluentd, stored in an AWS-Hosted ElasticSearch Cluster, and accessed via AWS-Hosted Kibana dashboard.

### Log Collection

Fluentd is a cluster-wide log collection service that runs in it's own dedicated environment.

The Fluentd application is configured with cluster-wide read permissions. The only requirement for Fluentd to start automatically collecting your application's logs is to have your application output logs to `stdout`.

### Log Storage

As an application engineer, you won't really need to pay much attention to how the logs are stored, as this is handled by the Cloud Platform team.

The logs are shipped from Fluentd and stored in an AWS-Hosted ElasticSearch cluster. All application logs are retained for 30 days, before being curated for deletion.