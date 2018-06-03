When implementing monads in languages like Ruby or Python, as classes, you end up having a data member for the inner *value* and it's tempting to expose it (it simpliflies some things).

We should avoid confusion between this value, let's call it the Monad's *representation*,
and the inner, wrapped value, which we'll call the *payload*. The payload is what you access using `then`, and that's the only way to access it in pure monads (which is a feature that makes possible asynchronous monads, or side-effect monas in Haskell)

For example for Maybe/Optional, the representation can be nil, but not the payload (it can be absent, though.) For List/Many, the representation is a list (array), but the payload are individual entries of the list, and it occurs multiple times. (the function passed to `then` can be called  multiple times or none at all). For Async/Future/Promise, the representation can be unfulfilled at a given point in execution, but the payload will be some value occurring out of the current execution stack (different thread or point in future execution of the current one).

So, although a pure implementation of the Monad pattern should avoid exposing the representation,
we can as long as it is clearly a implementation detail, different from the payload.

# ...

Programming is handling complexity,
but each time higher order constructs like Monads are used,
even the simplest cases are confusing and error prone, hard to get right at first.


Monads vs The Pyramids of Doom - talk

pyramids of doom examples:
* async nestes fetches
* cartesian products
* multilevel structures


Monads are primarily a mechanism of pure functional languages, Haskell in particular to manage effects.
They blend nicely into the Haskell language due to it's syntax
(pyramids of doom is not a problem there!) and the language also provides syntax sugar
that enables writing procedural form code which maps to functional code using monads.

But monads are also a way of handling chained and nestd operations in a uniform manner, and here....

TODO:
* select problems (async: github fetch; cartesian: post listing, count words, maybe: multilevel)
* write monad implementations and solutions in:
  + Ruby
  + EcmaScript



Monads
is a technique for defining object behaviour in between the operations
that act on the objects. Monads are wrappers around the original objects,
and its intent is achieved by passing functions to the monad for any operation to be done on it,
so that the monad has control of how/when to apply the operations and what to do between them.

A prime example is EcmaScript Promises.
Promise acts a monad that wrap any kind of (asynchronous) result.
Any operation on the data is done by passing a function to the `then` method of the monad.
In this case the wrapping class handles asynchronous execution.

Some applications of this idiom/pattern:
* Maybe Monad (optional values): so that if any operation doesn't return a value


In their origin Monads were created in Haskell, where they allow, in addition to the mentioned use cases, to
handle execution of procedural code/code with side effects.
Such computation can be represented in code by monads (that keep the tree of code to be executed).
Monads in Haskell are defined formally with great generality as an ADT.
The language also adds syntax sugar to write such code in a more common procedural form.




To implement monads and nested in JS: make them thenable as to be able to interact with Promises
(can implementation be based on Promise?)
TODO: work with examples from monad.rb
