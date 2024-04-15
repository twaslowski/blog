---
layout: post
title: "Running Docker on a Raspberry Pi"
---

I recently tried dockerizing and deploying a personal project on my Raspberry Pi.
I have never really enjoyed deploying things on my Raspberry Pi: It is slow, I often run into issues,
and I can only interact with it on my home network (save for setting up DDNS, which comes with a whole new set of
issues). Dockerizing your application allows you to simplify deployment processes and ensure that your application
runs the same way on your Raspberry Pi as it does on your development machine; however, there are some more or less
common issues that you may run into when running Docker on a Raspberry Pi.

In this article, I will try to outline some of these issues and how I resolved them. I will also share some general
tips that make running applications on your Raspberry Pi more enjoyable.

## Platform Issues

When pulling Docker images, you may receive the following error:

`ERROR: no matching manifest for linux/arm/v8 in the manifest list entries`

This issue is easy to fix, but came with a substantial learning.

What I understood is that the `platform` is simply a string, as far as Docker is concerned. It simply pulls the image
that matches the platform string that you provide. Since `linux/arm/v8` and `linux/arm64` amount to the same thing,
you can simply pull the image with the `linux/arm64` platform. On a side note: When calling `uname -a`, your Raspberry 
Pi will claim to run on `aarch64`, which, again, _is the same thing_. 
Ultimately, what this means is that any `arm64` compatible image can be run on your Raspberry Pi.
So simply run this to get your image:

    docker pull --platform linux/arm64 <image>

## Exit Code 159: Docker Container failing silently

This is where it gets more tricky. We pull the correct image, but the container simply shuts down without producing
any logs or error messages.

When running a container on the wrong architecture, you usually an error that goes something like `exec format error`.
However, when running my `linux/arm64` image on my Raspberry Pi, the container would simply shut down without producing
any obvious error. It did produce the exit code `159` though.

Googling _docker exit code 159_ yields a bunch of results around Raspbian and Docker. A lot of issues amount to a
mismatch of 32-bit and 64-bit architectures. However, I was running a 64-bit image on a 64-bit Raspberry Pi, so
that clearly was not it (you can check this using `uname -a`).

After some digging, I found this GitHub Issue:
[Docker armhf unable to run arm64v8 containers #3008](https://github.com/distribution/distribution/issues/3008).

From that thread, it appears that Docker attempts to perform some system calls that are not supported on the
Raspberry Pi. Adding the `--security-opt seccomp:unconfined` flag to the `docker run` command fixed the issue for me.

    docker run --security-opt seccomp:unconfined <image>

This is not the most secure solution, and I would not recommend doing this on a production-ready system.
But hey, this is an article about running things on a Raspberry Pi, so I think we're good. If you're interested,
I recommend reading the GitHub issue for more information. There is some research being done into the specific
system calls involved in this problem, so maybe there is a better solution here that I am not aware of.

## Bonus: Streaming Logs to CloudWatch

One issue that I often faced was that I would not be able to diagnose issues when I was not in my home network.
I found out that there is a Docker logs driver that allows you to stream logs to AWS CloudWatch. This is a great
way to ensure that you can access your logs even when you are not physically near your Raspberry Pi, without having
to expose your logs to the internet.

As long as you have AWS Credentials somewhere in your environment, you can simply append some flags to your `docker run`
command to stream logs to CloudWatch.

    docker run \
      --log-driver=awslogs \
      --log-opt awslogs-region=us-east-1 \
      --log-opt awslogs-group=my-log-group \ 
      <image>

This will stream logs to the CloudWatch log group `my-log-group` in the `us-east-1` region.
You can specify a log stream; if you choose not to do so, your log stream name will be the container ID.

## More Ideas

Of course, there are infinitely more issues that I haven't covered because I haven't encountered them so far.
But I do hope that this will be helpful to the occasional lone soul that runs into the same issues as me and tries
to fix them. I might end up writing more articles about running things on a Raspberry Pi, so stay tuned!
