---
layout: post
title: "In favour of pragmatic self-hosting"
---

In this article, I will argue for the benefits of self-hosting your services. I advocate for a pragmatic view
on self-hosting; the reason I self-host is not because I am a privacy advocate, but because it is the cheapest
way to iterate on cool projects and scale them past the prototype phase to proper MVPs.

The main point to keep in mind is that while cloud storage is cheap, **cloud compute is expensive**.
Buying a Raspberry Pi 5 is barely more expensive than using an on-demand EC2 instance with comparable specs
**for a month**. Your hardware pays for itself!

⚠️ Also, keep in mind that everything I will be talking about in this article relates to self-hosting your personal
projects and services. This is **not** an article on how to run enterprise-grade software outside the cloud. ⚠️

## Introduction

There has always been a stark contrast between the way that I develop and deploy software at work, and the way
that I do it on my personal projects. I've always been fortunate to work at companies that have mature tech stacks
and deploy their services to different cloud providers with robust CI/CD setups and container orchestration.

However, between my laptop and an old Raspberry Pi 3b+ that I bought used, there wasn't a lot of hardware that
I had available for running my personal projects. To be fair, for the first couple of years I primarily wrote Telegram
bots because I didn't have to worry about frontends or forwarding traffic into my home network without a public domain.
Those did not have a lot of overhead, and I could comfortably run a few of them at the same time.

However, as my projects grew more complex, ...

![Me, a student, trying to pay for cloud compute](../assets/posts/self-hosting/empty-wallet.jpg)
Photo by <a href="https://unsplash.com/@emkal?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash">Emil
Kalibradov</a>
on <a href="https://unsplash.com/photos/person-holding-black-android-smartphone-K05Udh2LhFA?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash">
Unsplash</a>

## A cost-benefit analysis

### The cost of cloud compute

Of course, you get all the things I mentioned above by simply buying a solution like AWS EKS, or even just ECS.
A few years ago, I ventured into using AWS for personal uses, benefiting from the free tier for a time. After trying
out a lot of the services, I found – and am still convinced – that AWS Lambda + API Gateway is an incredible way to run
specific workloads, but if you actually need a server, hosting your own servers tends to be cheaper very quickly.

| Instance Type | Price per Hour | vCPUs | Memory | Monthly Cost |
|---------------|----------------|-------|--------|--------------|
| t3.small      | $0.024         | 2     | 2 GiB  | $17.28       |
| t3.medium     | $0.048         | 2     | 4 GiB  | $34.56       |
| t3.large      | $0.096         | 2     | 8 GiB  | $69.12       |
| t3.xlarge     | $0.192         | 4     | 16 GiB | $138.24      |
| ...           | ...            | ...   | ...    | ...          |

Consider the prices of these EC2 instances. A Raspberry Pi 5 with 8 GiB of RAM costs roughly $100 as of the writing of
this article. Running an equivalent instance (let's say `t3.large`) for a month will cost you $70.

### The cost of self-hosting

While self-hosting is strictly cheaper than cloud computing, there are some obvious trade-offs you are going to make:

- **Reliability**: A single Raspberry Pi is never going to be as reliable as an AWS data center. Even if you run a multi-node
cluster locally, you are always only going to be as reliable as your ISP. If your Wifi goes down, so does your service.
- **Scalability**: One or two Raspberry Pis are going to carry you a long way if you manage your resources intelligently,
as I will show in the next section. But in the end, cloud providers simply allow you to scale in ways that local hardware
never will.
- **Security**: You actually have to start thinking about TLS and certificate management. You have to start patching
your own OS. A lot of the software that would simply be managed for you, you now have to configure yourself.
It really makes you appreciate managed services.

## Do not compromise on Observability


kubectl -n grammr-dev \
  create ingress grammr-core \                                                                                 
  --rule="grammr-backend-dev.twaslowski.com/api/*=grammr-core:8080"\
  --class cloudflare-tunnel
