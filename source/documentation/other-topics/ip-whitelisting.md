### IP Whitelisting

#### Inbound IP Whitelisting

Allowed client IP source ranges can be specified using the nginx.ingress.kubernetes.io/whitelist-source-range annotation. The value is a comma separated list of CIDRs, e.g. 1.1.1.1/24,10.0.0.0/24.

 [Kubernetes official documentation on whitelisting source ranges][kubernetes-annotations-whitelist-source-range].

[kubernetes-annotations-whitelist-source-range]: https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/#whitelist-source-range

An example configuration using "nginx.ingress.kubernetes.io/whitelist-source-range: 1.1.1.1/24,10.0.0.0/24"

   ```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
          {"apiVersion":"extensions/v1beta1","kind":"Ingress","metadata":{"annotations":{"kubernetes.io/ingress.class":"nginx","nginx.ingress.kubernetes.io/whitelist-source-range":"1.1.1.1/24,10.0.0.0/24"},"name":"<my-ingress>","namespace":"<my-namespace>"},"spec":{"rules":[{"host":"my-app.apps.live-1.cloud-platform.service.justice.gov.uk","http":{"paths":[{"backend":{"serviceName":"<my-svc>","servicePort":3000},"path":"/"}]}}],"tls":[{"hosts":["my-app.apps.live-1.cloud-platform.service.justice.gov.uk"]}]}}
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/whitelist-source-range: 1.1.1.1/24,10.0.0.0/24
  creationTimestamp: 2019-03-21T14:26:31Z
  generation: 1
  name: <my-ingress>
  namespace: <my-namespace>
spec:
  rules:
  - host: my-app.apps.live-1.cloud-platform.service.justice.gov.uk
    http:
      paths:
      - path: /
      - backend:
          serviceName: <my-svc>
          servicePort: 3000
  tls:
  - hosts:
    - my-app.apps.live-1.cloud-platform.service.justice.gov.uk
status:
  loadBalancer:
    ingress:
    - hostname: <hostname>
   ```
Testing with the annotation set:

```
curl -v -H "Host: my-app.apps.live-1.cloud-platform.service.justice.gov.uk" <HOST-IP>
```
Will return a "403 forbidden" status

#### Outbound IP Whitelisting

##### NAT Gateways

Many applications use third-party tools for a variety of reasons, and many of these tools require IP Whitelisting.

The Cloud Platform uses NAT Gateways as its external IP Endpoints.

The IP addresses for the clusters are as follows:

###### Live-1 Cluster
```
35.178.209.113
3.8.51.207
35.177.252.54
```
