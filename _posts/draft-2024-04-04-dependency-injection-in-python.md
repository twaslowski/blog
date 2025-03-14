---
layout: post
title: "Building your own Dependency Injection Container in Python"
---

## Introduction

Have you ever worked with [pytest fixtures](https://docs.pytest.org/en/6.2.x/fixture.html)? It is a genuine pleasure.
The basic premise is that you can define a fixture function that returns a value, and then pass that fixture function
as an argument to your tests. It looks like this:

  ```python
import pytest


@pytest.fixture
def my_fixture():
  return "Hello, world!"


def test_my_fixture(my_fixture):
  assert my_fixture == "Hello, world!"
  ```

This resembles certain forms of dependency injection. It is so incredibly convenient, that it got me thinking about
using dependency injection in different parts of my Python applications. I started looking into different projects,
and ended up finding two major libraries: [injector](https://github.com/python-injector/injector) (1.2k stars) and
[dependency-injector](https://github.com/ets-labs/python-dependency-injector) (3.6k stars). However, for my relatively
small pet projects, they turned out to be too heavy. Injector even explicitly states: "_dependency injection is
typically not that useful for smaller projects_"
[[1]](https://github.com/python-injector/injector?tab=readme-ov-file#a-full-example).

## kink: easy Dependency Injection

Python isn't a purely object-oriented language, so subscribing to a pattern that is entirely object-oriented
felt wrong to me. Also, it would have required for me to refactor large chunks of the code I had already written,
which I was simply too lazy to do. So I started looking into simpler approaches to DI. This would mean something
less powerful and less clean, but also something with much less overhead.

I ended up finding a much smaller library called [kink](https://github.com/kodemore/kink) (~300 stars).
It is much more simple, basically just containing a dependency injection container that you can access from anywhere
in your application. You can call it as follows:

  ```python
from kink import di

di["my_dependency"] = "Hello, world!"
assert di["my_dependency"] == "Hello, world!"


# this works for classes as well
class MyClass:
  my_field: str = "Hello World"


di[MyClass] = MyClass()
assert di[MyClass].my_field == "Hello World"
  ```

However, soon, I started realizing that I was calling `di[This]` and `di[That]` all over the place.
It's not very pretty. I wanted to make it more convenient. What I ended up with was an abstraction on top of `kink`
that I think works well enough for small projects. Enter `py-autowire`.

## py-autowire: Good Enough™️ Dependency Injection

`py-autowire` is a small library that I wrote to make dependency injection in Python a bit more convenient.
It does not require a large amount of boilerplate or applied design patterns. It is a simple, lightweight
dependency injection container that you can access from anywhere in your application. It is based on `kink`,
but adds a few conveniences on top of it. Here's how it works:

```python
from pyautowire import Injectable


class MyDependency(Injectable):
  def __init__(self):
    self.my_field = "Hello, world!"
    self.register()
```

Any class that inherits from `Injectable` can be automatically injected into other classes.
Calling `register()` adds the class to the dependency injection container. You can call it either in the `__init__`
function or anywhere else in your code.

Next, autowiring your dependency into a function is as easy as decorating it with the `@autowire` decorator
and specifying which dependencies you would like to inject into your function:

```python
from pyautowire import autowire
from my_dependency import MyDependency


@autowire("my_dependency")
def my_function(my_dependency: MyDependency):
  print(my_dependency.my_field)
```

Essentially, `py-autowire` matches the name of the argument in the function with the parameters in the `@autowire`
decorator. It will only inject objects that inherit from the `Injectable` class. 
The matching process works primarily by retrieving the fully qualified class name of the argument and comparing it
to the names of the registered dependencies. This is a simple and effective approach that works well for small projects.
If an object is not present in the
dependency injection container or the argument to the decorator is not found in the method signature, corresponding
exceptions will be raised. This ensures relative robustness while maintaining flexibility and simplicity.

However, fully qualified names may not cover all use cases. For example, this breaks down when you use subclasses:

```python
from pyautowire import Injectable
from abc import ABC


class UserRepository(ABC, Injectable):
  pass


class UserRepositoryImpl1(UserRepository):
  def __init__(self):
    self.register(alias="user_repository")


class UserRepositoryImpl2(UserRepository):
  def __init__(self):
    self.register(alias="user_repository")

@autowire("user_repository")
def create_user(user_repository: UserRepository):
  pass
```

You can see that matching by fully qualified name does not work here, because the fully qualified name of
the UserRepository varies from the fully qualified name of the UserRepositoryImpl1 and UserRepositoryImpl2 classes.
Aliasing them to the same name in the `register` function solves this problem.

## Testing

## Caveats

Of course, this approach to autowiring is _wildly_ hacky. It allows you to neglect healthy package structures and even
use circular class dependencies that you could not use with `import` statements. It is not tested for high performance
and multithreading. You should not use it in a codebase that has to scale to high degrees of complexity.

If you have any needs beyond the simplest forms of dependency injection, you should look into the more powerful
libraries mentioned above. However, I believe that for smaller projects, this approach might just be Good Enough. 

## So ... Should I use it?

It depends! Do you have a small project that you want to get off the ground quickly? Absolutely!
