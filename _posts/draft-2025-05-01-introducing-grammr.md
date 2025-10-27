---
layout: post
title: "Introducing: grammr"
---

# grammr: my most powerful passion project to date

I recently released my first ever fully-featured service, grammr. It's a language-learning tool
that acts as a fully-featured grammar and vocabulary reference; you can translate sentences across
currently seven languages and get literal translations of words in-context as well as grammatical
analyses, as well as conjugation and declension tables. You can then export all of this information
to flashcards, which integrate with [Anki](https://apps.ankiweb.net/), a popular open source flashcard program.
It's pretty neat.
[Check it out](https://grammr.twaslowski.com).

![An overview of the main screen](../assets/posts/introducing-grammr/overview-sidebar.png)

The backend powering grammr is completely open-source, and you can find the source code
[here](https://github.com/twaslowski/grammr). It is the most mature project that I have ever
written completely on my own; it features a microservice architecture consisting of a core service
written in Spring Boot, as well as several highly specialized Python services that can handle
tasks related to Natural Language Processing (NLP).

## A brief history

The idea for a service that could provide literal translations of words in context came to me when
playing with LLMs sometime in 2023. I implemented the initial prototype at the time in Python
under the name "[lingolift](https://github.com/twaslowski/lingolift-core)".

Unfortunately, the project failed to scale to the growing complexity I had in mind, due to bad
architectural decisions I made in the beginning, and also because the flexibly typed nature of
Python simply makes it hard for projects to truly scale.

I got the idea of re-writing the project in Java and using a microservice architecture for all
NLP-related tasks sometime in late 2024, and got off the ground relatively quickly. Using a
single-node Kubernetes cluster running on my Raspberry Pi, I managed to iterate quickly and
build a working prototype in a few months, which brings us to where we are now.
