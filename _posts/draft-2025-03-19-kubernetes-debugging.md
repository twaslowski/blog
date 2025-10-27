---
layout: post
title: "Debugging Kubernetes: A collection of useful snippets"
---

In this article, I will collect a few useful snippets that I have found helpful when debugging Kubernetes clusters.
I will update this page as I find more useful commands.

### Running Pods ad-hoc

Here is a collection of network debugging utilities, which image they exist in, and the command
to run that image in a pod:

| command  | description           | image    |
|----------|-----------------------|----------|
| wget     | Perform HTTP requests | busybox  |
| nslookup | Perform DNS lookups   | busybox  |
| ping     | Perform ICMP pings    | busybox  |
| curl     | Perform ICMP pings    | netshoot |

```shell
# export IMAGE_NAME=busybox
kubectl run -i -it --rm --restart=Never --image=$IMAGE_NAME $IMAGE_NAME -- sh
```
