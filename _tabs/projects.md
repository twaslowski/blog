---
icon: fas fa-heart
order: 1
---

Here is where you can see some of the projects that I work on in my own time.
All of them stem from my personal interests and needs – I don't write anything I don't personally use.

## lingolift ([source](https://github.com/twaslowski/lingolift))

[Check it out on Streamlit Cloud](https://lingolift.streamlit.app), or [chat with the bot on Telegram](https://t.me/lingolift_bot).

I initially developed this as a Telegram bot to support me in learning Russian.

Essentially, it translates sentences from foreign languages into English while providing grammatical explanations. 
It's supposed to give you a deeper understanding into **why** sentences are formed in a certain way.

It now features inflection tables for German, supporting the declension and conjucation of words, although this is
still very limited and error-prone. I'm achieving inflection by fine-tuning gpt-3.5 on an annotated corpus of
German words. This is a prototype so far, I have yet to perform serious benchmarking.

## Telegram Mood Tracker ([source](https://github.com/twaslowski/telegram-mood-tracker)) 

Available as a public Telegram bot. [Chat with it](https://t.me/bipolar_mood_tracker_bot)!

A Telegram-based bot that can query, store and visualise a wide range of personalisable mental health metrics. 
Includes customisable reminders. Built to make tracking metrics, perhaps as a component of therapy, as easy as possible.
