---
layout: post
title: "I built a Telegram Newsletter bot on Cloudflare Workers"
---

I recently had a few people request that in addition to my email newsletter, I should offer a newsletter that
notifies you via Telegram. Well, not really a few people. Just my fiancée. But because she's special (and because I like
a challenge), I built it anyway. Here's how.

## Telegram Bots on Cloudflare Workers

I built a fair share of Telegram bots in my time. My very first one is from 2023, in the very early days of LLMs.
It used fine-tuned text-to-speech models and the OpenAI API to respond to requests in the style of certain people.
For instance, you could get a voice memo from Donald Trump. I don't think you could do that anymore, but also I haven't
tried. If you're interested, the archive is [here](https://github.com/twaslowski/openai-telegram-bot).

I also built a bot for tracking my mood, which has now evolved into [Pulselog](https://github.com/twaslowski/pulselog),
a fully-featured powerful mood tracker, as well as the first iteration
of [grammr](https://github.com/twaslowski/grammr-serverless), then
called [lingolift](https://github.com/twaslowski/lingolift-core).

However, what separates this bot from everything I have developed so far is that it runs completely without a server!
When we became digital nomads, most of our things went into storage, my Raspberry Pi and Lenovo ThinkStation included.
Therefore, whenever I develop something new, I make sure it runs serverless.

This is possible via Telegram's [webhooks](https://core.telegram.org/bots/webhooks), which can notify you when
updates for your bot are available. You can configure a Telegram webhook to trigger
a [Cloudflare Worker](https://developers.cloudflare.com/workers/), which in turn can perform various types of
processing. In our case, it uses [Cloudflare Workers KV](https://developers.cloudflare.com/kv/) to keep track
of my subscribers. To be clear, this could have been achieved on AWS as well with API Gateway, a Lambda and DynamoDB.
Looking back, I maybe would even prefer going this route, as I don't particularly like dealing
with [Wrangler](https://developers.cloudflare.com/workers/wrangler/). But I'm getting ahead of myself. Let me show you
how this is done!

> The code for this project is available
> at [twaslowski/telegram-newsletter](https://github.com/twaslowski/telegram-newsletter). The README is very
> comprehensive, so if you're missing any instructions, you can use that as reference.
{: .prompt-tip }

## Why use this?

At this point, you might have a legitimate question: Why go through the effort of hosting a custom bot instead
of simply using a [channel](https://core.telegram.org/api/channel)? Well, several reasons:

1. This way, nobody can see that I only have like three subscribers. A channel with three users is pretty sad.
2. More importantly though, this bot allows for customization! Similarly to Discord bots, which can do all kinds of
   cool things, I can personalize this bot. I am currently in the process of building a public-facing
   [digital garden](https://fransfieldnotes.substack.com/p/how-to-make-a-digital-garden-a-beginners), 
   and I thought this would be a cute addition to my very own digital space.

## Setting up a Cloudflare Worker and KV

The core of managing all infrastructure is [Wrangler](https://developers.cloudflare.com/workers/wrangler),
Cloudflare's developer CLI. You'll want to create a JSON configuration for it:

```json
{
  "name": "newsletter-bot",
  "main": "src/index.ts",
  "compatibility_date": "2025-09-01",
  "observability": {
    "logs": {
      "enabled": true,
      "invocation_logs": true
    }
  },
  "routes": [
    {
      "pattern": "tgnl.twaslowski.com",
      "custom_domain": true
    }
  ],
}
```

By running `npx wrangler login` and `npx wrangler deploy`, you can very easily create your Webhook.
Personally, I'm used to a more declarative setup with Terraform, but this is the Cloudflare-native approach.

You can also create the KV namespace with wrangler:

```shell
npx wrangler kv namespace create SUBSCRIBERS
```

Running this will automatically add the `kv_namespaces[]` array to your `wrangler.jsonc`, including the
namespace id. This _is_ undoubtedly very convenient. Your config will now contain the following:

```json
{
  "kv_namespaces": [
    {
      "binding": "SUBSCRIBERS",
      "id": "65b4af7f012b4826b27051f1b708d71a",
      "remote": false
    }
  ]
}
```

## Register the Webhook

When you declare the `routes[]`, Wrangler automatically handles DNS for you.
You can then set up the bot webhook:

`curl https://api.telegram.org/bot<BOT_TOKEN>/setWebhook?url=https:\/\/tgnl.twaslowski.com/webhook&secret_token=<WEBHOOK_SECRET>`

You'll want to set the `secret_token` so not anybody can invoke the webhook. You'll want to note down this token
and supply it to your Worker as an environment variable. Telegram will pass it in every request with the 
`X-Telegram-Bot-Api-Secret-Token` header. Validation will look something like this:

```typescript
const secret = request.headers.get("X-Telegram-Bot-Api-Secret-Token");
if (secret !== env.WEBHOOK_SECRET) {
    return new Response("Unauthorized", { status: 401 });
}
```

## Integrate with KV

When we [set up the worker](#setting-up-a-cloudflare-worker-and-kv), we created a KV namespace and a binding.
This binding is now important. By simply calling `env.SUBSCRIBERS.get(<id>)`, we can access the KV store.

Thus, a `/start` command could trigger the following code:

```typescript
const chatId = message.chat.id;
const key = `subscriber:${chatId}`;
const existing = await env.SUBSCRIBERS.get(key);

if (!existing) {
    await env.SUBSCRIBERS.put(
        key,
        JSON.stringify({
            chatId,
            firstName: message.from?.first_name ?? "unknown",
            username: message.from?.username ?? null,
            subscribedAt: new Date().toISOString(),
        }),
    );
}
```

Similarly, we also should respect `/stop`:

```typescript
const chatId = message.chat.id;
await env.SUBSCRIBERS.delete(`subscriber:${chatId}`);
```

## Forwarding messages

This is the tricky part. Initially, I had written a script that would send a message to a `/broadcast` endpoint.
However, this turned out to be somewhat hacky, and unreliable, and it doesn't support multimedia.

Right now, I have configured an admin account that has special privileges: When it sends a message prefixed with
`/broadcast` into the bot chat, it gets forwarded, along with all multimedia.

```typescript
if (content?.startsWith("/broadcast") && isAdmin(chatId, env)) {
   const broadcastText = content.slice("/broadcast".length).trim();

   await handleBroadcast(msg, broadcastText || null, env);
   return;
}

export async function handleBroadcast(
        message: TelegramMessage,
        broadcastText: string | null,
        env: Env,
): Promise<void> {
   const adminChatId = message.chat.id;
   const isMedia = hasMedia(message);

   // List all subscriber keys
   const list = await env.SUBSCRIBERS.list({ prefix: "subscriber:" });
   const results: BroadcastResult = { sent: 0, failed: 0, total: list.keys.length };

   for (const key of list.keys) {
      const raw = await env.SUBSCRIBERS.get(key.name);
      if (!raw) continue;

      const subscriber = JSON.parse(raw) as Subscriber;

      try {
         if (isMedia) {
            // Copy the media message with modified caption
            const success = await copyMessage(
                    env.BOT_TOKEN,
                    adminChatId,
                    subscriber.chatId,
                    message.message_id,
                    broadcastText ?? undefined,
            );
            if (success) results.sent++;
            else results.failed++;
         } else {
            // Send text message
            await sendMessage(env.BOT_TOKEN, subscriber.chatId, broadcastText!, "Markdown");
            results.sent++;
         }
      } catch {
         results.failed++;
      }
   }

   // Send statistics back to admin
   await sendMessage(
           env.BOT_TOKEN,
           adminChatId,
           `📊 *Broadcast Complete*\n\n✅ Sent: ${results.sent}\n❌ Failed: ${results.failed}\n📬 Total subscribers: ${results.total}`,
           "Markdown",
   );
}
```

## Serving a widget

I need to get people to subscribe to the bot! Telling them to go to Telegram and manually look for 
`@tobi_newsletter_bot` is not a strong value proposition (although you can – and should – do that ;) )
([related xkcd](https://xkcd.com/541/)). Instead, I created an embeddable `iframe` that I am also serving
via my Worker. Yes, you can do that. It's very neat. It looks like this:

```typescript
 if (request.method === "GET" && url.pathname === "/widget") {
   return new Response(serveWidget(), {
      headers: {
         "Content-Type": "text/html;charset=UTF-8",
         "X-Frame-Options": "ALLOWALL",
         "Content-Security-Policy": "frame-ancestors *",
      },
   });
}

export function serveWidget(): string {
   return `<a href="https://t.me/tobi_newsletter_bot"
   target="_blank"
   rel="noopener noreferrer">
  <svg width="20" height="20" viewBox="0 0 24 24" fill="none"
       xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
    <path d="M21.944 2.551a1.25 1.25 0 0 0-1.284-.195L2.34 9.641a1.25 1.25 0 0 0 .078 2.332l4.373 1.51 1.67 5.545a1.25 1.25 0 0 0 2.108.488l2.403-2.5 4.453 3.27a1.25 1.25 0 0 0 1.953-.797l3-15a1.25 1.25 0 0 0-.434-1.938ZM9.61 14.772l-.924 2.62-.807-2.68 8.37-7.74-7.64 7.8Z"
          fill="currentColor"/>
  </svg>
  Subscribe on Telegram
</a>`;
}
```

It looks like this (click it!):

<iframe src="https://tgnl.twaslowski.com/widget" height="52" scrolling="no"></iframe>

## Outlook

I am currently looking into a more powerful format for creating automated newsletters.
Specifically, I'd like to create an open specification. It would accept a `title`, `text` and optional `imageURL`
and could generate updates to both Telegram and [Buttondown](https://buttondown.com/), the service I'm
using for my email newsletter, which offers an API. 

My blogs get deployed via GitHub Actions, so I could simply include a document to have the newsletter published
automatically on all platforms on deployment. A simple `curl` to a serverless function could fan it out to all
relevant services. I'll keep you posted on how it goes!

Again, here's a reminder to subscribe to the bot! You'll receive just a weekly update on my recent activities,
both from my [photography blog](https://photography.twaslowski.com) and this one. I'll introduce subscriber lists
eventually if people do not care for updates from my personal life, which I respect.

Click the button!

<iframe src="https://tgnl.twaslowski.com/widget" height="52" scrolling="no"></iframe>
