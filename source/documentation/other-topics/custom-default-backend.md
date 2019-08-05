### Custom default-backend

#### Background

Cloud-Platform created [custom error pages][cloud-platform-custom-error-pages] to be used by the default backend for Nginx ingress-controller. The default backend is the default service that Nginx falls backs to if it cannot route a request successfully. When the service in the Ingress rule does not have active endpoints, this default-backend service will handle the response by serving the custom error pages globally.

However, some applications don’t want to use the cloud-platform custom default error pages from the Nginx ingress controller but need to be served their own custom error pages. This can be achieved by implementing own [custom default backend][customized-default-backend] in a namespace.

#### Setup

Custom default-backend can be managed inside a namespace by creating a service and deployment of the custom error pages container and annotate Ingress using the service name of the default-backend inside the same namespace.  

##### Create custom error page
First create a docker image containing custom HTTP error pages using the [example][ingress-nginx-custom-error-pages] from the ingress-nginx, or [simplified version][cloud-platform-custom-error-pages] of that created by the cloud platform team.

##### Customised default backend
Using this [custom-default-backend][customized-default-backend] example from ingress-nginx create a service and deployment of the error pages container in your namespace.

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

Example Usage:
```
annotations:
  # This is referencing the SAME NAMESPACE that this resource is in
  nginx.ingress.kubernetes.io/default-backend: nginx-errors
```

It will also handle the error responses if both [default-backend][default-backend-annotation] annotation and the [custom-http-errors][custom-http-error-annotation] annotation is set. Custom HTTP Errors annotation will set NGINX proxy-intercept-errors to your custom default backend associated with this ingress in your namespace. If custom-http-errors is also specified globally, the error values specified in this annotation along with custom default backend will override the global value for the given ingress' hostname and path.

Example Usage:

```
annotations:
  nginx.ingress.kubernetes.io/default-backend: nginx-errors
  nginx.ingress.kubernetes.io/custom-http-errors: "404,415"
```

#### Use platform-level error page

Some users want application's serve their own error's `example 404's`, but want to serve cloud platforms custom error page from default backend at ingress controller for 502 and 504 errors, this can be done by using [custom-http-errors][custom-http-error-annotation] annotation at your ingress.

Example Usage:

```
annotations:
  nginx.ingress.kubernetes.io/custom-http-errors: "502,504"
```

Note: At the moment cloud-platform configured [custom-http-errors][custom-http-error-config] to serve cloud platforms custom error page from default backend at ingress controller for "413,502,503,504" errors, this will be removed soon to allow services to serve their own error pages or opt-in to the generic platform-level error page (which is done by adding an annotation at your ingress).

[cloud-platform-custom-error-pages]: https://github.com/ministryofjustice/cloud-platform-custom-error-pages
[customized-default-backend]: https://github.com/kubernetes/ingress-nginx/tree/master/docs/examples/customization/custom-errors#customized-default-backend
[ingress-nginx-custom-error-pages]: https://github.com/kubernetes/ingress-nginx/tree/master/images/custom-error-pages#custom-error-pages
[default-backend-annotation]: https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/#default-backend
[custom-http-error-annotation]: https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/#custom-http-errors
[custom-http-error-config]: https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/configmap/#custom-http-errors