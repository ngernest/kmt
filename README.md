[![Main workflow](https://github.com/mgree/kmt/actions/workflows/build.yml/badge.svg)](https://github.com/mgree/kmt/actions/workflows/build.yml)

This repository implements [Kleene algebra modulo
theories](https://arxiv.org/abs/1707.02894) (KMT), a framework for
deriving _concrete_ Kleene algebras with tests (KATs), an algebraic
framework for While-like programs with decidable program equivalence.

More plainly: KMT is a framework for building simple programming
languages with structured control (if, while, etc.) where we can
algorithmically decide whether or not two programs are equivalent. You
can use equivalence to verify programs. If `a` is a nice property to
have after running your program, then if `p;a == p`, you know that `p`
satisfies `a`. Kleene algebra with tests subsumes Hoare logic: if
`a;p;~b == 0` then all runs starting from `a` either diverge or end
with `b`, i.e., that equation corresponds to the partial correctness
specification `{a} p {b}`. While prior work on KAT often focuses on
_abstract_ properties, we write programs over theories that assign
_concrete_ meanings to primitive tests and actions.

In addition to providing an OCaml library for defining KMTs over your
own theories, we offer a command-line tool for testing equivalence in
a variety of pre-defined theories.

# Getting Started Guide

## How do I build it?

You can build a Docker container from the root of the repo:

```ShellSession
$ docker build -t kmt .    # build KMT, run tests and evaluation
```

If your `docker build` command exits with status 137, that indicates
that the build ran out of memory (typically when building Z3). We find
that 12GB of RAM is sufficient, but more may be necessary on your
machine. You might have to reconfigure Docker to have sufficient memory.

Building the image will automatically run unit tests as well as the
PLDI 2022 evaluation. When running the image, you can use the `kmt`
executable to test equivalence of various terms directly:

```ShellSession
$ docker run -it kmt       # enter a shell
opam@b3043b7dca44:~/kmt$ kmt --boolean 'x=T' 'x=T + x=F;set(x,F);x=T'
[x=T parsed as x=T]
nf time: 0.000004s
lunf time: 0.000022s
[x=T + x=F;set(x,F);x=T parsed as x=T + x=F;set(x,F)[1];x=T]
nf time: 0.000008s
lunf time: 0.000006s
[1 equivalence class]
1: { x=T + x=F;set(x,F);x=T, x=T }
```

The message `1 equivalence class` indicates that all terms given as
command-line arguments form a single equivalence class, i.e., the two
terms are equivalent. Each equivalence class is printed after:

```ShellSession
opam@b3043b7dca44:~/kmt$ kmt --boolean 'x=T' 'x=T + x=F;set(x,T)'
[x=T parsed as x=T]
nf time: 0.000003s
lunf time: 0.000016s
[x=T + x=F;set(x,T) parsed as x=T + x=F;set(x,T)[1]]
nf time: 0.000007s
lunf time: 0.000010s
[2 equivalence classes]
1: { x=T + x=F;set(x,T) }
2: { x=T }
```

Note that `b3043b7dca44` will be replaced by some new hash each time
you run `docker run -it kmt`.

Running `run_eval` inside the Docker container will reproduce the
evaluation from our paper. You can run the regression tests by running
`test_word` (for regular expression word equivalence, part of our
decision procedure) and `test_equivalence` (for KMT term
equivalence). All of these steps are performed automatically during
`docker build`.

The source code for all of these is in the `src` directory; see
`src/dune` for the build script.

# How do I use the `kmt` executable?

The default way of using the `kmt` executable is to give it a theory (here `--boolean`) and 2 or more KMT programs in that theory. It will give you the equivalence classes of those terms. The `-v` flag is useful when many terms are given:

```ShellSession
opam@3ce9eaca9fb1:~/kmt$ kmt -v --boolean 'x=T' 'x=F' 'x=T + x=F' 'x=T + x=F;x=T'
[x=T parsed as x=T]
kmt: [INFO] nf = {(x=T,true)}
nf time: 0.000004s
kmt: [INFO] lunf = {(x=T,true), (x=F,false)}
lunf time: 0.000015s
[x=F parsed as x=F]
kmt: [INFO] nf = {(x=F,true)}
nf time: 0.000003s
kmt: [INFO] lunf = {(x=T,false), (x=F,true)}
lunf time: 0.000008s
[x=T + x=F parsed as true]
kmt: [INFO] nf = {(true,true)}
nf time: 0.000003s
kmt: [INFO] lunf = {(true,true)}
lunf time: 0.000014s
[x=T + x=F;x=T parsed as x=T]
kmt: [INFO] nf = {(x=T,true)}
nf time: 0.000003s
kmt: [INFO] lunf = {(x=T,true), (x=F,false)}
lunf time: 0.000006s
[3 equivalence classes]
kmt: [INFO] 1: {(x=T,true), (x=F,false)}; {(x=T,true), (x=F,false)}
kmt: [INFO] 2: {(true,true)}
kmt: [INFO] 3: {(x=T,false), (x=F,true)}
```

The last three lines identify the three equivalence classes in terms
of their normal forms.

If you don't specify a theory, the default will be the theory of
booleans.

If you give just one term, `kmt` will normalize it for you.

Run `kmt --help` for command-line help in a manpage-like format.

## What is the syntax?

A Kleene algebra with tests breaks syntax into two parts: tests (or prediates) and actions. Actions are in some sense the 'top level', as every test is an action.

We use the following syntax, where `a` and `b` are tests and `p` and
`q` are actions. The following is the core KAT notation; individual
theories introduce their own notations.

| Tests   | Interpretation   |
| :-----: | :--------------- |
| `false` | always fails     |
| `true`  | always succeeds  |
| `not a` | negation         |
| `a + b` | or, disjunction  |
| `a ; b` | and, conjunction |

| Actions | Interpretation         |
| :-----: | :---------------       |
| `false` | failed trace           |
| `true`  | noop trace             |
| `a`     | filter traces by test  |
| `p + q` | parallel composition   |
| `p ; q` | sequential composition |
| `p*`    | Kleene star; iteration |

Whitespace is ignored, and comments are written with `/* ... */`.

### Theory-specific forms

On its own, the Kleene algebra with tests above doesn't let you
express any interesting programs: we need a notion of concrete
predicates and actions. KMT builds a concrete KAT around a _theory_,
which defines a predicates and actions. Our implementation has several
predefined, and [the library itself lets you define new theories](#what-do-I-have-to-provide-to-write-my-own-theory).

Theories add predicates and actions of the form `NAME(ARGS,...)` and
`ARG1 OP ARG2`. Each theory specificies its own language: an `ARG`
will be a variable or a theory-specific constant of some kind; `NAME`
will be a conventional function symbol name, like `set`; `OP` takes a
variety of forms, like `<` or `=`.

#### Booleans

You can use the booleans by specifying `--boolean` on the `kmt`
command line. It is the default theory, so you can also leave it
off. The theory of booleans adds two forms, where `x` and `y` are
variables. We write `T` and `F` for the boolean _values_ true and
false, which should not be confused with the KAT terms `true` and
`false`.

  - `x=T` and `y=F` are tests that are true when `x` is true and `y`
    is false, respectively
  - `set(x,T)` and `set(y,F)` are actions that set `x` to true and `y`
    to false, respectively
    
#### Monotonic naturals

You can use the monotonically increasing naturals by specifying
`--incnat` on the command line. Monotonic naturals have several
theory-specific forms, where variables `x`, `y`, and `z` range over
natural numbers; we write `n` to mean a _constant_ natural number.

  - `x > n` is a test that is true when the variable `x`'s value is greater than `n`
  - `inc(y)` is an action that increments the variable `y`
  - `set(z, n)` is an action that sets the variable `z` to `n`
  
#### Other theories

We have several other theories built in:

  - `--addition` is a theory of naturals with both `<` and `>`, along with `inc(x,n)`
  - `--network` is a theory of tracing NetKAT over natural-valued
    fields `src`, `dst`, `pt`, and `sw`; use `FIELD <- n` for
    assignment
  - `--product` is a product theory of booleans and monotonic naturals
  - `--product-addition` is a product theory of booleans and the
    `--addition` theory of naturals

You can [add new
theories](#what-do-I-have-to-provide-to-write-my-own-theory) to the
`kmt` tool by updating the `modes` in `src/main.ml`.

# Step-by-Step

The paper makes three core claims about the implementation.

 1. It is extensible.
 2. We have implemented some optimizations.
 3. The benchmarks according to our evaluation in Section 5.
 
## How can I tell that the implementation is extensible?

Look at `src/kat.ml`. It defines several modules.

 - The `KAT_IMPL` signature characterizes what a KAT has. Here `A` is
   for theory tests and `P` is for theory actions. (The `Test` and
   `Term` modules are for defining comparison and hashing operations
   on the hashconsed KMT terms.)
 - The `THEORY` signature characterizes what a client theory must
   define to generate a KMT.
 - The `KAT` module is a functor that takes a `THEORY` and produces a
   `KAT_IMPL`.
   
That is, we use OCaml functors to transform a `THEORY` into a `KAT`.

You can see this process in action in `src/boolean.ml`. After some
base definitions (outside the module to simplify things), we define
the module `Boolean` recursively as a `THEORY`... where we use `K =
KAT (Boolean)` inside our definition. That is, `Boolean.K` is the KMT
over booleans. You can see that there is very little boilerplate:
parsing is just a few lines; we define `push_back` in just a few
lines. The satisfiability checker is somewhat complicated by our use
of a 'fast' path in the `satisfiable` function, where we discharge
simple queries (with just conjunction and negation of theory
predicates, but no disjunction---see `can_use_fast_solver`) without
calling Z3 at all.

## What optimizations are implemented?

All KAT terms are hashconsed. The library for that is in
`src/hashcons.ml`; KAT terms are hashconsed using `'a pred`/`'a
pred_hons` and `('a, 'p) kat` and `('a, 'p) kat_hons` in
`src/kat.ml`. We use smart constructors extensively in the `KAT`
module (see `not`, `ppar`, `pseq`, etc.).

When we check word equivalence of actions in `src/decide.ml` (see
`same_actions`), we use the `equivalent_words` function in
`src/word.ml`. That method uses the Brzozowski derivative to generate
word automata lazily during checking (see `derivative` and `accepting` in that
`src/word.ml`).

Finally, several theories implement custom satisfiability checkers
that don't merely defer to Z3: `boolean.ml`, `incnat.ml`, and
`addition.ml`.

## How do I reproduce the paper's evaluation?

By default, the [Docker build](#how-do-i-build-it) will run the
evaluation from Section 5, using a 30s timeout. Here is sample output
(your hash and exact times will differ):

```
Step 14/18 : RUN opam exec -- dune exec -- src/run_eval
 ---> Running in f609aca22e92
test                      time (seconds)
                             30s timeout
----------------------------------------
a* != a (10 random `a`s)          0.0399
count twice                       0.0006
count order                       0.0008
parity loop                       0.0003
boolean tree                      0.0004
population count                  0.3677
toggle three bits                timeout
```

These numbers are slightly higher than those in the paper, which
reports numbers from a local installation. Times will of course vary:
machines differ (the original eval is on a 2014 MacBook Pro with 16GB
of RAM); Docker on macOS is really a VM, and will be substantially
slower than Docker on Linux; Docker will always be slower than [a
local installation](#building-locally). It _should_, however, be the
case that these benchmarks will have the same relative performance.

You can change the evaluation timeout by passing `-t SECONDS` or
`--timeout SECONDS` to `run_eval`. In Docker on macOS 10.13 on the
2014 MacBook Pro, we find a high timeout is necessary to get the last
stage of evaluation to terminate:

```ShellSession
opam@6792c093ed91:~/kmt$ run_eval -t 3600
test                      time (seconds)
                           3600s timeout
----------------------------------------
a* != a (10 random `a`s)          0.0682
count twice                       0.0006
count order                       0.0008
parity loop                       0.0005
boolean tree                      0.0008
population count                  0.4311
toggle three bits                1175.1909
```

## What _isn't_ evaluated?

Not every theory described in the paper is completely implemented in
KMT. Namely:

  - The implementation of the tracing NetKAT theory uses restricted
    fields and natural numbers as values, rather than the richer
    domain NetKAT enjoys.
  - LTLf is not implemented, and neither is Temporal NetKAT. (But the
    [PLDI 2016 implementation is available on
    GitHub](https://github.com/rabeckett/Temporal-NetKAT).)
  - Sets and maps are not implemented.

## Building locally

The simplest way to play with KMT right away is to [use
Docker](#how-do-i-build-it). If for some reason you would prefer to
run KMT on your own Linux machine, run the following commands from a clone
of the repo:

```ShellSession
$ sudo apt-get install -y libgmp-dev python3
$ opam install ocamlfind ppx_deriving batteries ANSIterminal fmt alcotest cmdliner logs zarith z3 dune
$ eval $(opam env)
$ dune build -- src/kmt      # build the CLI
$ dune test                  # unit tests on regex word equivalence and KMT equivalence
$ dune exec -- src/run_eval  # PLDI2022 eval
```

On macOS, you a `brew install gmp python3 ; sudo mkdir -p
/opt/local/lib` should replace the first line.

If the above fails, the CI automation is a good guide for manual installation: see the `Dockerfile` and `.github/workflows/build.yml`.

## What do I have to provide to write my own theory?

The source code in `src/incnat.ml` is a nice example. You have to provide:

  - sub-modules `P` and `A` for the primitive parts of your language
  - a `parse` function to indicate how to parse the syntax of your
    primitives; return `Left` for tests and `Right` for actions
  - a `push_back` operation that calculates weakest preconditions on a
    pair of a primitive and a predicate
  - a `subterms` function that captures which predicates could show up
    in `push_back` of a given predicate
  - a `satisfiable` function to test whether a predicate is satisfiable

To use the Z3 backend, your theory can describe how it extracts to Z3 using functions `variable`, `variable_test`, `create_z3_var`, and `theory_to_z3_expr`.

Note that `incnat.ml`'s theory solver in `satisfiable` has two cases: a fast path that need not use Z3, and a more general decision procedure in Z3.

### Which example theories should I look at first?

The code in `src/boolean.ml` is for a simple language with boolean-valued variables.

Check out `src/incnat.ml` for a simple language with increment and assignment operations. It defines types `a` and `p` for the primitive parts of the language (one predicate, which tests whether a variable is greater than a number, and two actions, which increment and set variables).

The code in `src/product.ml` is for a _higher-order theory_, combining
two theories into one. You can see it in action using the `--product`
and `--product-addition` flags for KMT.

## How is equivalence decided?

We decide equivalence via _normalization_. We convert KMT terms to a normal form using the novel `push_back` operation; to compare two such normal forms, we disambiguate the tests and compare the terms pointwise. When this procedure is fast, it's _quite_ fast... but deeply nested loops or loops with lots of conditionals slow it down severely.

In more detail, see `src/decide.ml`. The top-level function is:

```OCaml
let equivalent (p: K.Term.t) (q: K.Term.t) : bool =
  let nx = normalize_term 0 p in
  let ny = normalize_term 0 q in
  equivalent_nf nx ny
```

That is, we normalize and then compare normal forms.

```OCaml
let equivalent_nf (nx: nf) (ny: nf) : bool =
  (* optimization: just if syntactically equal first *)
  if PSet.equal nx ny
  then
    begin
      Log.debug (fun m -> m "syntactic equality on %s" (show_nf nx));
      true
    end
  else begin
      Log.debug (fun m -> m
                         "running cross product on %s and %s"
                         (show_nf nx) (show_nf ny));
      let xhat = locally_unambiguous_form nx in
      Log.debug (fun m -> m "%s is locally unambiguous as %s" (show_nf nx) (show_nf xhat));
      let yhat = locally_unambiguous_form ny in
      Log.debug (fun m -> m "%s is locally unambiguous as %s" (show_nf ny) (show_nf yhat));
      equivalent_lunf xhat yhat
  end
```

It may be easier to understand without the logging/optimization:

```OCaml
let equivalent_nf (nx: nf) (ny: nf) : bool =
  let xhat = locally_unambiguous_form nx in
  let yhat = locally_unambiguous_form ny in
  equivalent_lunf xhat yhat
```

Given normal forms `nx` and `ny`, we (a) compute locally unambiguous
forms `xhat` and `yhat`; we then check _those_ for equivalence.

To generate locally unambiguous forms, suppose the normal form `nx` is
equal to `a1;m1 + a2;m2 + ... + an;mj`. We generate `xhat` by
considering every possibly combination of the tests `ai`, which
engender every possibly combination of the actions `mi`. That is:

```
xhat =     a1 ;     a2 ; ... ;     aj ; (m1 + m2 + ... + mj)
     + not a1 ;     a2 ; ... ;     aj ; (     m2 + ... + mj)
     +     a1 ; not a2 ; ... ;     aj ; (m1 +      ... + mj)
     + ...                         
     + not a1 ; not a2 ; ... ;     aj ; (                mj)
     + not a1 ; not a2 ; ... ; not aj ; false
```

We build `yhat` from `y = b1;n1 + ... + bk;nk` similarly:

```
yhat =     b1 ;     b2 ; ... ;     bk ; (n1 + n2 + ... + nk)
     + not b1 ;     b2 ; ... ;     bk ; (     n2 + ... + nk)
     +     b1 ; not b2 ; ... ;     bk ; (n1 +      ... + nk)
     + ...                         
     + not b1 ; not b2 ; ... ;     bk ; (                nk)
     + not b1 ; not b2 ; ... ; not bk ; false
```

We call this `hat`ted forms "locally unambiguous" because each possible test in `xhat` is syntactically unambiguous.

Now we can compare `xhat` and `yhat` (in `equivalent_lunf`): consider
every pair of a predicates from `xhat` and `yhat`. If the combination
of the predicates is unsatisfiable, then we can ignore that case. If
it's satisfiable, then for `xhat` and `yhat` to be equivalent, the
actions on both sides must be equivalent. We can decide _that_
equivalence using the Hopcroft-Karp algorithm (see `equivalent_words`
in `src/word.ml`)
