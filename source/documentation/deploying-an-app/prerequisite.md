### Prerequisite for Live-1 deployment

**This section only applies to applications aiming to be deployed to Live-1.**

In Live-1, the Cloud Platform team introduced _Pod Security Policies_, to tighten the security on this production cluster.
Two policies have been applied to the cluster, _restricted_ and _privileged_.

By default, any new environment/namespace on Live-1 will be assigned the _restricted_ policy

#### Impact

The main impact of this _restricted_ policy is that it prevents pods/containers
from running as the root user.  The pod will be registered against Kubernetes,
but will never be scheduled.  A container's user is usually defined in its
Dockerfile. If no user is explicitely specified in the Dockerfile, chances are
that it will use root.

It is important to understand that not being able to use root also implies that it is impossible to bind to a privileged port (e.g. 80, 443).

#### How to adapt to the pod security policies

Most of the time, your application's Dockerfile can be easily adapted by:

 - Adding a `USER` clause in it.

 - Defining a UID for this user (>1)

 - Giving this user permission to access the files/directories the application requires.


Example:

```yaml
FROM busybox

RUN mkdir -p /opt/myFolder &&\
    adduser --disabled-password myNewUser -u 1001 &&\
    chown -R myNewUser:myNewUser /opt/myFolder

USER myNewUser

CMD myApplication
```

Note: The policies are only in effect after the container has started. Anything in the Dockerfile can be run as root (e.g. to install required software)

A more complete example can be found here :  [Dockerfile](https://github.com/ministryofjustice/cloud-platform-multi-container-demo-app/blob/master/rails-app/Dockerfile)

##### Adapting the NGINX image

Since NGINX binds itself to a privileged port by default, it will not be able to run as-is with the _restricted_ policy.

The cloud-platform team will update this page with relevant documentation regarding nginx, as soon as it is ready.
In the meantime, feel free to reach out to the cloud-platform team for help : [Getting Help](getting-help.html)

