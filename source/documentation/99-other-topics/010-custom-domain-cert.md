## Using an externally-managed hostname

### Background
Every application running on Cloud Platform is able to use a hostname for their
HTTP endpoints, under a pre-defined DNS zone. For exaxmple, on the `live-0`
cluster, this would be `*.apps.cloud-platform-live-0.k8s.integration.dsd.io`. As
long as it is defined on the `Ingress` resource, it works automatically with a
wildcard TLS certificate.

However, most applications will typically need to be served on a `gov.uk`
hostname. These hostnames (or usually, DNS zones) are managed externally,
relative to the cluster, and there is a number of actions in order to set them
up for usage.

### Setup

#### You do not have a DNS zone for the desired hostname
Please [create a support ticket](http://goo.gl/msfGiS) providing as much
information as possible.

#### You already have a DNS zone for the desired hostname

##### > It's a Route53 zone
1. [Create a support ticket](http://goo.gl/msfGiS) requesting the `provider`
name for your `Certificate` (see the next step).

2. Create the `Certificate`, using the `provider` name from the previous step.
The `secretName` attribute defines the `Secret` where the certificate and key
material will be stored, in your namespace.

```
---
apiVersion: certmanager.k8s.io/v1alpha1
kind: Certificate
metadata:
  name: <my-cert>
  namespace: <my-namespace>
spec:
  secretName: <my-cert-secret>
  issuerRef:
    name: letsencrypt-production
    kind: ClusterIssuer
  commonName: '<hostname>'
  acme:
    config:
    - domains:
      - '<hostname>'
      dns01:
        provider: <provider>
```

3. You will need to update your `Ingress` spec to include the new hostname:

```
  apiVersion: extensions/v1beta1
  kind: Ingress
  metadata:
    name: <my-ingress>
    namespace: <my-namespace>
  spec:
    tls:
    - hosts:
      - my-app.apps.cloud-platform-live-0.k8s.integration.dsd.io
+   - hosts:
+     - <hostname>
+     secretName: <my-cert-secret>
    rules:
    - host: my-app.apps.cloud-platform-live-0.k8s.integration.dsd.io
      http:
        paths:
        - path: /
          backend:
            serviceName: <my-svc>
            servicePort: 80
+   - host: <hostname>
+     http:
+       paths:
+       - path: /
+         backend:
+           serviceName: <my-svc>
+           servicePort: 80
```

4. Make sure the certificate has been issued correctly, by checking its `Status`:

```
$ kubectl describe certificate <my-cert>
```

5. Create a CNAME record in your DNS zone, pointing the desired hostname to the
cloud-platform. You can use either your existing hostname
(`my-app.apps.cloud-platform-live-0.k8s.integration.dsd.io` in the example above)
or you can target the top-level domain, `apps.cloud-platform-live-0.k8s.integration.dsd.io`.

##### > It's a DNS zone hosted with another provider
For the time being, we only support Route53 natively. Depending on the provider
we might be able to accommodate you or we might need to handle this manually.
Please [create a support ticket](http://goo.gl/msfGiS).
