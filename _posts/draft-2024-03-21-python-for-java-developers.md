---
layout: post
title: "Python for Java developers"
---

The first programming language I learned was Java. The first three four years of my professional life as a software
engineer were largely defined by object-oriented, statically typed programming. I sometimes used Python for hacking
together prototypes and showcasing ideas, but rarely for larger projects.

At some point, I started writing more and more pet projects in Python, due to its sheer versatility and ease of setting
up. However, most of those projects were hard to maintain and grow beyond a certain point, and often I'd come back to
them after taking a break for a while, and understanding the code would be a massive challenge.

However, I really do enjoy writing Python more than any other programming language out there. It is incredibly easy to
get a project off the ground, there is very little boilerplate to think about, and there are amazing libraries you can
use. Of course, there's also problems: Primarily, the fact that Python is not a statically typed language makes it hard
to maintain growing code bases, as you'll often pass around ever more confusing JSON structures instead of classes.

In this article, I will attempt to tackle several of those problems to make Python more Java-like, so that developers
like me might have an easier time to reap the benefits from writing Python without having to deal with the downsides.
I will introduce different tools and strategies so that you'll be able to write more maintainable and readable Python
code.

## Typing

As mentioned in the introduction, typing (or lack thereof) is easily the biggest problem you will face when trying
to grow a Python project. I will attempt to showcase a few remedies here.

### Dataclasses

One of the most Java-like constructions that I have come to love are dataclasses. Dataclasses do a lot of different
things, but they primarily

### Type Hints

[PEP 484](https://peps.python.org/pep-0484/#abstract) defines type hints for Python. Type hints are not evaluated
at run-time; they exist simply for third-party tooling and readability. So while they will not give you the kind of
security that Java's static typing gives you, it is a solid start and can be further solidified by additional tools.

You can declare type hints as follows:

```python
def greet(name: str) -> str:
  return f"Hello, {name}!"
```

The Python [`typing` module](https://docs.python.org/3/library/typing.html) supplies additional utilities for more
advanced typing, like [`Optional`](https://docs.python.org/3/library/typing.html#typing.Optional),
[`Union`](https://docs.python.org/3/library/typing.html#typing.Union) and more. Let's consider a function that
retrieves a username from a MongoDB collection by supplying the user ID:

```python
from typing import Optional
from pymongo.collection import Collection


def get_by_id(id: int, user: Collection) -> Optional[str]:
  return user.find_one({'id': id})
```

`find_one` returns `None` when no matching record is found; this behaviour is expressed in the method signature.
As of Python 3.10, `Optional[str]` can also be written as `str | None`. While lacking the functional elegance of Java's
`Optional` class, you can take advantage of the fact that `None` is falsy in Python. Let's consider an expression like
`getUser(id).`

```python
def get_username(id: int) -> str:
  return user['name'] if 
```

### mypy

## Testing

## Dependency Management
