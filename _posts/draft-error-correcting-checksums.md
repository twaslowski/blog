---
layout: post
title:  "Error-Correcting Check Digits"
---

# Introduction

## Check Digits

Check Digits are a common mechanism for verifying data that is manually transcribed by people.
Perhaps the most well-known example of this occurs in credit cards. In any given credit card number, only the first
fifteen digits hold any actual information – the sixteenth digit exists for verification purposes.

For example, let's consider the following credit card number:

`4809-9748-0349-7412`

The `2` is a calculated check digit from all the previous digits; if you make a mistake when typing your credit card
number (let's say you type _4809-9748-034**8**-7412_), the verification algorithm will point out that you have made
a mistake. You can read more on how the algorithm for verifying credit card numbers (also known as the Luhn Algorithm)
works [on Wikipedia](https://en.wikipedia.org/wiki/Luhn_algorithm).

## Use Cases

Check Digits have traditionally been used where people manually transcribe data, to ensure that simple errors are caught
quickly. Examples for this include the above-mentioned credit card numbers, but also 
[IBANs](https://www.iban.com/iban-checker), 
[ISBNs](https://www.oreilly.com/library/view/regular-expressions-cookbook/9781449327453/ch04s13.html)
and [many more](https://en.wikipedia.org/wiki/Check_digit#Other_examples_of_check_digits). Error-correcting codes also
have come to be used in technical contexts, such as the Hamming Code // todo find more examples, elaborate.

# Error-Correcting Check Digits

// todo
