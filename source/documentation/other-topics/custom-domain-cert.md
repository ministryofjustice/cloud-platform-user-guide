### Using a custom domain

#### Background
Every application running on Cloud Platform is able to use a hostname for their
HTTP endpoints, under a pre-defined domain. For example, on the `live-1`
cluster, this would be `*.apps.live-1.cloud-platform.service.justice.gov.uk`. As
long as it is defined on the `Ingress` resource, it works automatically, using a
wildcard TLS certificate.

However, most applications will typically need to be served on their own,
application-specific `gov.uk` hostname. These hostnames (or usually, entire domains)
are managed individually and there is a number of actions in order to set them
up for usage.

#### Setup

Domains are managed inside DNS zones. You can read more about the structure of
the Domain Name System in this [page][wiki-domain-structure]. It is recommended
that applications use their own DNS zones, in order to aid with management and
provide better isolation.

##### Defining the DNS zone

To create the zone, you simply need to define it as a resource in your
environment. Make sure to read [the guidance on naming domains][naming-domains]
first and follow the instructions to [create the Route53 zone][creating-zone].
To simplify management, we recommend that you only define a single zone, as part
of the resources for your production environment, if possible. You can still use
subdomains of that zone for different environments.

Once the zone is created, you will need to setup the necessary name server (NS)
records in the parent DNS zone, before you're able to use it. For more
information on how this delegation method works, you can read about authoritative
name servers in this [page][wiki-nameservers].

If your zone is for a subdomain of `service.justice.gov.uk` (eg.: `https://myapp.service.justice.gov.uk`),
the Cloud Platform team can help you set it up; please [create a support ticket][support-ticket].

For any other domains (including any subdomain of `gov.uk`, eg.: `https://myservice.gov.uk`),
you will need to contact the parent zone's administrators to set this up. If in
doubt, don't hesitate to get in touch with us in `#ask-cloud-platform`.

##### Obtaining a certificate

1. Create the `Certificate` resource, filling in any placeholders with your
details. The `secretName` attribute defines the name of a `Secret` in your
namespace where the certificate and key material will be stored

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
           provider: route53-cloud-platform
   ```

2. Make sure the certificate has been issued correctly, by checking its `Status`:

   ```
   $ kubectl describe certificate <my-cert>
   ```

   The certificate status of type `"Ready"` should be `True`:

   ```
   Status:
     Conditions:
       Last Transition Time:  2019-06-05T10:16:43Z
       Message:               Certificate is up to date and has not expired
       Reason:                Ready
       Status:                True
       Type:                  Ready
     Not After:               2019-09-03T09:16:42Z
   Events:
     Type    Reason         Age   From          Message
     ----    ------         ----  ----          -------
     Normal  Generated      3m    cert-manager  Generated new private key
     Normal  OrderCreated   3m    cert-manager  Created Order resource "<my-cert>-3189350212"
     Normal  OrderComplete  1m    cert-manager  Order "<my-cert>-3189350212" completed successfully
     Normal  CertIssued     1m    cert-manager  Certificate issued successfully
   ```

   It generally takes but a few minutes for the certificate to be prepared and
   the events displayed should indicate if there is a problem or it simply needs
   more time.

3. You will need to update your `Ingress` spec to include the new hostname.

   **Once your host is defined here, the cluster will take control of the DNS record and automatically adjust to point to the cluster.**

   If this does not happen, please get in touch with us in #ask-cloud-platform. Depending on your setup, we might need to
   intervene manually to allow `external-dns` to assume ownership of the DNS record.


   ```
     apiVersion: extensions/v1beta1
     kind: Ingress
     metadata:
       name: <my-ingress>
       namespace: <my-namespace>
     spec:
       tls:
       - hosts:
         - my-app.apps.live-1.cloud-platform.service.justice.gov.uk
   +   - hosts:
   +     - <hostname>
   +     secretName: <my-cert-secret>
       rules:
       - host: my-app.apps.live-1.cloud-platform.service.justice.gov.uk
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

[naming-domains]: https://ministryofjustice.github.io/technical-guidance/standards/naming-domains/#naming-domains
[creating-zone]: tasks.html#creating-a-route-53-hosted-zone
[support-ticket]: http://goo.gl/msfGiS
[wiki-domain-structure]: https://en.wikipedia.org/wiki/Domain_Name_System#Structure
[wiki-nameservers]: https://en.wikipedia.org/wiki/Name_server#Authoritative_name_server
