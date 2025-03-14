---
icon: fas fa-heart
order: 1
---

Here is where you can see some of the projects that I work on in my own time.
All of them stem from my personal interests and needs – I don't write anything I don't personally use.

## [grammr](https://grammr.twaslowski.com/)

📖 A personal glossary and language learning tool that supports multiple languages. 

- 🌏 Translate texts
- 🔎 Get word-for-word translations and grammatical analyses.
- 💡Conjugate and decline words. 
- 📚 Create flashcards and export them to Anki for studying

Grammr is a passion project of mine, initially developed to help me learn Russian.

Initially developed as [lingolift](https://github.com/twaslowski/lingolift-core), I have
since rewritten it and given it a proper frontend written in NextJS.

Grammr was written to scale and support an arbitrary amount of languages. It has a proper
microservice architecture and can be deployed to a Kubernetes cluster with Helm charts.
You can check out its source code [here](https://github.com/twaslowski/grammr).

## [the telegram mood tracker](https://t.me/open_mood_tracker_bot)

A Telegram bot that helps you develop emotional intelligence by developing metrics
around your mental health and track them.

- 🫥 Specify baselines for your mood and track deviations
- 📈 Graph those deviations over time, correlating different factors

I decided to prioritize the development of grammr, so this bot is currently kind of stuck in development hell.
Enabling users to supply their own metrics turned out to be pretty difficult, because handling complex user
dialogs in Telegram can be a pain. I might pick this up when I have the motivation to do so.

If you're curious, you can still [check it out on Github](https://github.com/twaslowski/open-mood-tracker).
