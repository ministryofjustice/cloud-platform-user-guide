### Custom default-backend

#### Background

Cloud-Platform created [custom error pages][cloud-platform-custom-error-pages] to be used by the default backend for Nginx ingress-controller. The default backend is the default service that Nginx falls backs to if it cannot route a request successfully. Globally when the service in the Ingress rule does not have active endpoints, this default-backend service will handle the response by serving the cloud-platform custom default error page.

However, some applications don’t want to use the cloud-platform custom default error pages from the Nginx ingress controller but need to be served their own custom error pages. This can be achieved by implementing own [custom default backend][customized-default-backend] in a namespace.

#### Setup

Custom default-backend can be managed inside a namespace by creating a [custom default-backend][customized-default-backend] service and deployment of the custom error pages container in your namespace. Configure the name of the service resource created that Nginx should use as the default backend for requests that don’t match any configured ingress rules (hostname and path combinations) using the annotation in your Ingress.

##### Create custom error page
First create a docker image containing custom HTTP error pages using the [example][ingress-nginx-custom-error-pages] from the ingress-nginx, or [simplified version][cloud-platform-custom-error-pages] of that created by the cloud platform team.

##### Customised default backend
Using this [custom-default-backend][customized-default-backend] example from ingress-nginx create a service and deployment of the error pages container in your namespace.

To create Deployment and Service manually use this below command:

```
$ kubectl -n ${namespace} create -f custom-default-backend.yaml
service "nginx-errors" created
deployment.apps "nginx-errors" created
```

This should have created a Deployment and a Service with the name nginx-errors.

```
$ kubectl -n ${namespace} get deploy,svc
NAME                           DESIRED   CURRENT   READY     AGE
deployment.apps/nginx-errors   1         1         1         10s

NAME                   TYPE        CLUSTER-IP  EXTERNAL-IP   PORT(S)   AGE
service/nginx-errors   ClusterIP   10.0.0.12   <none>        80/TCP    10s
```

##### Defining annotations in Ingress file.

Final step is to to use an [Default Backend][default-backend-annotation] annotation in your Ingress, This annotation is of the form nginx.ingress.kubernetes.io/default-backend: <svc name> to specify a custom default backend. This <svc name> is a reference to a service inside of the same namespace in which you are applying this annotation. This annotation overrides the global default backend.

This service will handle the response when the service in the Ingress rule does not have active endpoints. If a default backend annotation is specified on the ingress, the errors will be routed to that annotation's default backend service (instead of the global default backend).

Example Ingress file with default-backend annotation:

```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: helloworld-rubyapp-ingress
  annotations:
    nginx.ingress.kubernetes.io/default-backend: nginx-errors
spec:
  tls:
  - hosts:
    - helloworld.rubyapp.cloud-platform.service.justice.gov.uk
    secretName: live0-to-live1-cert
  rules:
  - host: helloworld.rubyapp.cloud-platform.service.justice.gov.uk
    http:
      paths:
      - path: /
        backend:
          serviceName: rubyapp-service
          servicePort: 4567
```

This default-backend service also handle the error responses if both [default-backend][default-backend-annotation] annotation and the [custom-http-errors][custom-http-error-annotation] annotation is set. `Custom-http-errors` annotation configure which HTTP status codes Nginx should be forwarding to the [default-backend][default-backend-annotation].

If custom-http-errors is also specified globally, the custom-http-error values specified in this annotation along with custom default backend will override the global value for the given ingress' hostname and path.

In the example below, custom error pages from `custom-default-backend: nginx-errors` service will be served for `"404,415"` errors which is set as `custom-http-errors` annotation.

Example Ingress with default-backend and custom-http-errors annotations:

```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: helloworld-rubyapp-ingress
  annotations:
    nginx.ingress.kubernetes.io/default-backend: nginx-errors
    nginx.ingress.kubernetes.io/custom-http-errors: "404,415"
spec:
  tls:
  - hosts:
    - helloworld.rubyapp.cloud-platform.service.justice.gov.uk
    secretName: live0-to-live1-cert
  rules:
  - host: helloworld.rubyapp.cloud-platform.service.justice.gov.uk
    http:
      paths:
      - path: /
        backend:
          serviceName: rubyapp-service
          servicePort: 4567
```

#### Use platform-level error page

Some teams want application's serve their own error's `example 404's`, but want to serve cloud platforms custom error page from default backend at ingress controller for other error codes like 502,503 and 504, this can be done by using [custom-http-errors][custom-http-error-annotation] annotation in your ingress for error codes teams want to serve the cloud platforms custom error page.

Example Ingress file to use platform-level error page for custom-http-errors: "502,503,504":

```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: helloworld-rubyapp-ingress
  annotations:
    nginx.ingress.kubernetes.io/custom-http-errors: "502,503,504"
spec:
  tls:
  - hosts:
    - helloworld.rubyapp.cloud-platform.service.justice.gov.uk
    secretName: live0-to-live1-cert
  rules:
  - host: helloworld.rubyapp.cloud-platform.service.justice.gov.uk
    http:
      paths:
      - path: /
        backend:
          serviceName: rubyapp-service
          servicePort: 4567
```

Note: At the moment cloud-platform configured [this][cp-config-custom-http-errors] custom-http-errors to serve cloud platforms [custom error page][cp-custom-errors] from default backend at ingress controller, this will be removed soon to allow services to serve their own error pages or opt-in to the generic platform-level error page (which is done by adding an annotation at your ingress).

[cloud-platform-custom-error-pages]: https://github.com/ministryofjustice/cloud-platform-custom-error-pages
[customized-default-backend]: https://github.com/kubernetes/ingress-nginx/blob/master/docs/examples/customization/custom-errors/custom-default-backend.yaml
[ingress-nginx-custom-error-pages]: https://github.com/kubernetes/ingress-nginx/tree/master/images/custom-error-pages#custom-error-pages
[default-backend-annotation]: https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/#default-backend
[custom-http-error-annotation]: https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/#custom-http-errors
[cp-custom-errors]: https://github.com/ministryofjustice/cloud-platform-custom-error-pages/tree/master/rootfs/www/
[cp-config-custom-http-errors]: https://github.com/ministryofjustice/cloud-platform-infrastructure/blob/master/terraform/cloud-platform-components/nginx-ingress-acme.tf#L35