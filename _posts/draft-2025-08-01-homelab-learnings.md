---
layout: post
title: "Five learnings from switching to GitOps for my home lab"
---

## Introduction

I like hosting services at home. I started hosting my own Kubernetes cluster when I started
seriously working on [grammr](https://github.com/twaslowski/grammr), a language-learning project
that I wrote for myself to improve my Russian skills. Grammr supports performing morphological
analysis using [spaCy](https://spacy.io/), generating inflections across different languages, as well as creating,
managing and syncing flashcards to [Anki](https://apps.ankiweb.net/), a popular open-source
flashcard application.

To manage this degree of complexity, I had to orchestrate several microservices written in different languages.
My NLP services are written in Python, because most NLP libraries are written in Python; however, for the core service,
I used Spring Boot, which is a framework I am much more comfortable with when it comes to scaling beyond certain
degrees of complexity, like managing authentication, database connections, a variety of entities, and so on.
To that end, I set up a [k3s](https://k3s.io) cluster on a Raspberry Pi 5,
set up some self-hosted GitHub runners and started running everything.

Since I already _had_ the cluster now, I figured I might as well use the remaining idle resources to host
other applications. After all, running servers at home can be energy-intensive, so I might as well get
my money's worth out of the hardware.

Unfortunately, Raspberry Pi 5s are, while well-suited for simple tasks, _severely_ underpowered for running
Kubernetes. While I had sufficient CPU and RAM for running k3s, which is a _really_ lightweight Kubernetes
distribution, it ultimately turned out that the cluster was bottlenecking on I/O,
as performing read-write operations on the SQLite database backing the cluster on the microSD card was simply too slow.
Every deployment was painful, and often Helm releases would time out for up to fifteen minutes because `%iowait` would
be at up to 90% for the entire duration of the deployment.

I ended up experimenting with moving my control plane to an EC2 instance and wiring them together via a VPN,
but in the process I ended up _completely_ destroying my Raspberry Pi's networking capabilities, and I had
to set up everything from scratch again.

This opened my eyes to the fact that I was managing an already very fragile system in a very ad-hoc manner,
and that I needed to manage it more intelligently so that I could recover from such failures more easily.

Enter [FluxCD](https://fluxcd.io/), a GitOps tool that allows you to manage your Kubernetes cluster declaratively!

## What is GitOps?

GitOps is a set of practices that uses Git as a single source of truth for managing infrastructure and applications.
It allows you to define your entire infrastructure and application state in Git repositories, which can then be
automatically applied to your Kubernetes cluster. This means that you can version control your infrastructure,
track changes, and roll back to previous versions if needed.

**Why FluxCD?**

Honestly, it was a toss-up between FluxCD and ArgoCD, but I ended up going with FluxCD because it has a
more straightforward installation process and is more lightweight.

## Hardware

After the Raspberry Pi 5 debacle, I decided to invest in a more robust setup. While I was researching SSDs for the Pi,
I realized I might as well just buy some proper hardware. I ended up getting a refurbished Lenovo ThinkStation M910 Tiny
for some €120. It has an Intel Pentium G4400T with two cores and 2.70 GHz, as well as 16 GB of RAM and a 128 GB SSD.


## Learnings

### Outsource Storage wherever you can

One of the biggest lessons I learned while operating a homelab Kubernetes cluster is that
**local storage is both precious and precarious**. When I first set up my cluster on that Raspberry Pi 5,
I quickly ran into storage limitations. MicroSD cards are not only limited in size, but also suffer from performance issues and shorter lifespans under constant read/write operations. Even after upgrading to SSDs, I realized that managing persistent storage on a home setup is asking for trouble.

Here's why you should look to external storage solutions:

1. **Local storage failures are catastrophic** - When your only SSD dies (and it will, eventually), you risk losing all your data. My wake-up call came when I had a power outage that corrupted parts of my local PV storage.

2. **Scaling is hard** - Want to add more storage? That means new hardware, physical installation, and potential downtime. Not exactly the cloud-like experience we're trying to replicate.

3. **Backups become your problem** - Without proper storage abstraction, you'll need to implement, monitor, and test your own backup solutions. Trust me, you don't want this responsibility.

The solution? **Embrace object storage** like AWS S3, MinIO, or other S3-compatible alternatives. Even in a homelab, the reliability and flexibility of dedicated storage solutions pay dividends in peace of mind.

**For observability data**, I've found that integrating Thanos with Prometheus has been a game-changer. Thanos allows you to store metrics long-term in S3-compatible storage, meaning your precious time-series data doesn't consume your local disks and survives cluster rebuilds. Similarly, Loki (for logs) can ship its data to object storage, preventing your nodes from drowning in log files.

```yaml
# Example Thanos sidecar config pointing to S3
thanos:
  objectStorageConfig:
    name: thanos-objstore
    key: objstore.yml
```

**For databases**, particularly PostgreSQL, the cloudnative-pg operator has excellent integration with Barman for backups to S3. This means even if your entire cluster implodes, your database backups are safe in object storage:

```yaml
# Example cloudnative-pg cluster with S3 backup
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: pg-cluster
spec:
  instances: 3
  backup:
    barmanObjectStore:
      destinationPath: "s3://my-bucket/pg-backups"
      s3Credentials:
        accessKeyId:
          name: s3-creds
          key: ACCESS_KEY_ID
        secretAccessKey:
          name: s3-creds
          key: ACCESS_SECRET_KEY
```

My advice: Even if you're a homelab enthusiast who enjoys the DIY aspect, make an exception for storage. Delegate that responsibility to purpose-built systems designed for data resilience. Your future self will thank you when inevitable hardware failures occur, and recovery becomes a simple matter of redeploying your GitOps manifests rather than trying to recover corrupted data.

### Get your observability right

### Operators are incredible – but don't overdo it

### On Postgres Operators

### Sealed Secrets sprawl
