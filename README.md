# Monadic code

Monads apply function composability to wrapped (encapsulated) data; they represents computation as a nested call structure (all happens inside the lambda args); (then the do notation --syntax sugar-- allows expressing that nested calls structure linearly); it can be interpreted as either a computation-description (so that it can be at some time executed including its side-effects) or as a function calls that carry world-state in the parameter.

## In Haskell

Monad is a type class (an ADT) `M a` whose instances wrap some tipe `a` (maybe the unit type ()) and with a bind operation:

    f >>= g

of type: (note that b is usually a)

    M a -> (a -> M b)

which allows composing monads (it gives `g` access to the wrapped value)

A convenient `>>` operator is defined for when the value wrapped in a monad is not needed by the composed function `g`:

    f >> g = f >>= \_ -> g

A Monad must also define a `return` (unit) function to wrap a value into a monad (needed by `g` functions to return a value)

    return : a -> M a

The rules that a Monad type must obey:

return (unit) acts as a neutral value for >>=

    [A1] : (return x) >>= f  =   f x
    [A2] : m >>= return      =   m

Associativity: (if g doesn't have a free x variable)

    [B]  : (m >>= f) >>= g   =   m >>= (\x -> (f x >>= g))

Haskell function application syntax: `f x y  is (f x) y`;
so `f (g x)`` must be parenthesed

The fact that

    f >>= g >>= h  is f >>= (g >>= h)

allows writing procedural code in the natural order and without parentheses:

    step1 >> step2 >> ....

or:

    step1 >>= \v1 -> step2(v1) >>= \v2 -> step3(v1,v2)

Note that this is: (A)

    step1 >>= (\v1 -> step2(v1) >>= (\v2 -> step3(v1,v2)))

so inner functions have access to all upper variables v1, ...

if one does this instead: (B)

    (step1 >>= \v1 -> step2(v1)) >>= \v2 -> step3(v2)

then inner (right) functions have access only to one variable v

In other languages (e.g. Ruby, JavaScript) (B) is more convenient to write, specially if using object oriented notation (i.e. v.f instead of f v) since these languages need delimiters (even Python or CoffeeScript have this limitation; they use indentation as delimiters); the form (A) requires nesting of function definitions ("piramids of doom")

Haskell do notation (syntax sugar) allows writing this:

    step1 >> step2 >>= \c2 -> step3 >>= \c3 -> step4

as:

    do
      step1;
      c2 <- step2;
      c3 <- step3;
      step4;

By rule [B] above, if inner functions don't use outer variables (e.g. step3 does not use v1) then (A) and (B) forms will have the same effect (except that form A can be more economical of function evaluations/calls) and this allows, in languages such as Ruby, to convert function nesting to chaining:

Example in Ruby notation

    # (A) => nesting
    step1.bind ->(v1) {
      step2(v1).bind ->(v2) {
        step3(v1,v2)
      }
    }

    # (B) => chaining
    step1.bind ->(v1) {
      step2(v1)
      }.bind ->(v2) {
        step3(v2)
      }

But when outer variables are used in inner levels this is not possible;
e.g. using the Array monad to compute a cartesian product, in Haskell:

    Haskell: xs >>= \x -> ys >>= \y -> return (x, y)

or in do notation: `do x <- xs y <- ys; return (x, y)`

With:

    instance Monad [] where
    m >>= f 0 concat(map f m)
    return x = [x]

In Ruby this would be: `xs.bind { |x| ys.bind { |y| [[x,y]] } }`
With: `class Array; def bind(&f) map(&f).inject(&:+) end; end`

## Nomenclature

* The >> operator is usually called "then" (or flush)
* The >>= binding combinator (composition)
  has sometimes been called in other languages "pass", "and then"
* The unit or return function may be called wrap, new (because it is a
  constructor)

Monads allow to build computations by combining simpler computation steps.

A computation can be so defined by a functional expression
(typically, in Haskell using the (A) form, the computation is defined by the tree of function parameters which is composed of nested functions)
and in the case of Haskell IO this allows to define side effects as an expression that can be executed (both returning values and performing
actions) with a variety of strategies by the compiler/VM.

## Monad examples:

IO monad is relevant in Haskell (a pure, lazy functional language) but not in imperative languages such as Ruby

The same applies to monads for error/exception management, IORefs, etc.

But other monads can be useful in other languages.

*  Maybe or Optional
* Array or Many or Multiple

# Resources

## Original papers about application to Haskell by Philip Wadler
http://homepages.inf.ed.ac.uk/wadler/topics/monads.html

* 1992 - The Essence of Functional Programming - Philip Wadler
  http://homepages.inf.ed.ac.uk/wadler/topics/monads.html#essence
* 1992 - Comprehending Monads - Philip Wadler
  http://ncatlab.org/nlab/files/WadlerMonads.pdf
* 1995 - Monads for functional programming - Philip Wadler
  http://homepages.inf.ed.ac.uk/wadler/topics/monads.html#marktoberdorf
* 1997 - How to declare an imperative - Philip Eadler
  http://homepages.inf.ed.ac.uk/wadler/topics/monads.html#monadsdeclare

## Presentations by Simon Peyton Jones

* 1993 - Imperative Functional Programming - Simon L. Peyton Jones,
  Philip Wadler
  http://citeseerx.ist.psu.edu/viewdoc/summary?doi=10.1.1.53.2504
  how they're used in Haskell and how they solve the I/O problem in a
  pure (& lazy)

* 2000 (revised 2010) - Tackling the awkward squad - Simon Peyton Jones
  http://research.microsoft.com/en-us/um/people/simonpj/papers/marktoberdorf/
  Great presentation of how monads are used in Haskell to solve I/O,
  concurrency, exceptions, etc.

## Interesting references

* Haskell 98 Report
  https://www.haskell.org/onlinereport/ https://www.haskell.org/definition/haskell98-report.pdf
  3.14 Do Expressions (pg26); 6.3.6 The Modad Class (pg88)

* Wikipedia:
  http://en.wikipedia.org/wiki/Monad_(functional_programming)

* Hal Daumé III Haskell Tutorial
  http://www.umiacs.umd.edu/~hal/docs/daume02yaht.pdf
  Chapter 5 Basic Input/Output (pg57)
  8.4.2 Computations (pg109)  
  Chapter 9 Monads (pg119)

* IO Inside
  https://www.haskell.org/haskellwiki/IO_inside

## More expositions

* Humorous explanation, first functors and applicatives, then monads
  http://adit.io/posts/2013-04-17-functors,_applicatives,_and_monads_in_pictures.html

* Chronological compendium of Monads explanations:
  https://www.haskell.org/haskellwiki/Monad_tutorials_timeline

* Haskell/Understanding monads
  http://en.wikibooks.org/wiki/Haskell/Understanding_monads

* Videos:
  Monads and Gonads - Douglas Crockford - monads implemented in JavaScript; great insight
  https://www.youtube.com/watch?v=b0EF0VTs9Dc

* Don't fear the Monad - Brian Beckman; basic introduction for C# programmers
  https://www.youtube.com/watch?v=ZhuHCtR3xq8

* Refactoring Ruby with Monads - Tom Stuart; great insight
  http://codon.com/refactoring-ruby-with-monads

* Why Do Monads Matter?
  https://cdsmith.wordpress.com/2012/04/18/why-do-monads-matter/
  https://www.youtube.com/watch?v=3q8xYFDYLeI

* sigfpe 2006-08
  http://blog.sigfpe.com/2006/08/you-could-have-invented-monads-and.html

* Mike Vanier's Yet Another Monad Tutorial - 2010-07
  1: http://mvanier.livejournal.com/3917.html
  2: http://mvanier.livejournal.com/4305.html
  3: http://mvanier.livejournal.com/4586.html
  4: http://mvanier.livejournal.com/4647.html
  5: http://mvanier.livejournal.com/5103.html
  6: http://mvanier.livejournal.com/5343.html
  7: http://mvanier.livejournal.com/5406.html
  8: http://mvanier.livejournal.com/5846.html

* Karsten Wagner 2007-02
  http://kawagner.blogspot.com.es/2007/02/understanding-monads-for-real.html

# Monads in other Languages

## Ruby

* Rumonade: a Ruby Monad Library https://github.com/ms-ati/rumonade
* Monadic: Monads in Ruby https://github.com/pzol/monadic
* Deterministic: successor to Monadic: https://github.com/pzol/deterministic

Note on the different aims of rumonade and monadic: https://github.com/pzol/monadic/issues/1
monadic is more idiomatic on Ruby, and has specific purposes in mind, such as safe longish chains of method invocations: a.x.y.z... and safe nested hash accesses a[:x][:y][:z]...

### Tom Stuart presentation (Refactoring Ruby with Monads)
* http://codon.com/refactoring-ruby-with-monads
* https://www.youtube.com/watch?v=J1jYlPtkrqQ
* https://speakerdeck.com/tomstuart/refactoring-ruby-with-monads
* https://github.com/tomstuart/monads

###  Other implementations/presentations

* http://stackoverflow.com/questions/2709361/monad-equivalent-in-ruby

* http://moonbase.rydia.net/mental/writings/programming/monads-in-ruby/00introduction.html
* http://moonbase.rydia.net/mental/writings/programming/monads-in-ruby/01identity
* http://moonbase.rydia.net/mental/writings/programming/monads-in-ruby/02array

* http://www.valuedlessons.com/2008/01/monads-in-ruby-with-nice-syntax.html
* http://lostechies.com/derickbailey/2010/10/10/the-maybe-monad-in-ruby/y/
* http://pretheory.wordpress.com/2008/02/14/the-maybe-monad-in-ruby

* http://meta-meta.blogspot.com.es/2006/12/monads-in-ruby-part-1-identity.html
* http://meta-meta.blogspot.com.es/2006/12/monads-in-ruby-part-15-identity.html

* https://github.com/pzol/monadic https://github.com/pzol/deterministic

* http://dave.fayr.am/posts/2011-10-4-rubyists-already-use-monadic-patterns.html

## JavaScript / CoffeeScript / Node

Monads can be used to refactor the typical deeply nested code in NodeJS
(asynchronous code) into serialialized chained form. For example:

* ContT in monadic: https://www.npmjs.org/package/monadic
* https://blog.jcoglan.com/2011/03/11/promises-are-the-monad-of-asynchronous-programming/

### More examples

* http://www.jayway.com/2013/12/22/improving-your-functional-coffeescript-and-javascript/
* http://bl.ocks.org/joyrexus/5646821
* http://damianfral.github.io/blog/posts/2013-07-07-simple-monads-example.html
* https://github.com/mrlauer/coffee-script-monads

* http://igstan.ro/posts/2011-05-02-understanding-monads-with-javascript.html
* Douglas Crockford: https://www.youtube.com/watch?v=b0EF0VTs9Dc
  https://github.com/douglascrockford/monad
* http://stackoverflow.com/questions/20729050/implementing-monads-in-javascript
* https://curiosity-driven.org/monads-in-javascript

## Erlang

* http://amtal.ca/2011/09/24/monads-in-erlang.html
* https://github.com/rabbitmq/erlando

## Elixir

* https://github.com/nickmeharry/elixir-monad

## Julia

* http://monadsjl.readthedocs.org/en/latest/
* https://github.com/pao/Monads.jl
* https://groups.google.com/forum/#!topic/julia-dev/K0K_6vVTpYY
