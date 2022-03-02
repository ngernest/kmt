[![Main workflow](https://github.com/mgree/kmt/actions/workflows/build.yml/badge.svg)](https://github.com/mgree/kmt/actions/workflows/build.yml)

An implementation of [Kleene algebra modulo theories](https://arxiv.org/abs/1707.02894) (KMT), a framework for deriving _concrete_ Kleene algebras with tests (KATs), an algebraic framework for While-like programs with decidable program equivalence.

More plainly: KMT is a framework for building simple programming languages with structured control (if, while, etc.) where we can algorithmically decide whether or not two programs are equivalent. You can use equivalence to verify programs. If `a` is a nice property to have after running your program, then if `p;a == p`, you know that `p` satisfies `a`. Kleene algebra with tests subsumes Hoare logic: if `a;p;~b == 0` then all runs starting from `a` either diverge or end with `b`, i.e., that equation corresponds to the partial correctness specification `{a} p {b}`.

In addition to providing an OCaml library for defining KMTs over your own theories, we offer a command-line tool for testing equivalence in a variety of theories.

# Getting Started Guide

## How do I build it?

You can build a Docker container from the root of the repo:

```ShellSession
$ docker build -t kmt .    # build KMT, run tests and evaluation
$ docker run -it kmt       # enter a shell
opam@3ce9eaca9fb1:~/kmt$ kmt --boolean 'x=T' 'x=T + x=F;set(x,F);x=T' 
[x=T parsed as x=T]
nf time: 0.000003s
lunf time: 0.000025s
[x=T + x=F;set(x,F);x=T parsed as x=T + x=F;set(x,F)[1];x=T]
nf time: 0.000004s
lunf time: 0.000006s
[1 equivalence class]
```

If your `docker build` command exits with status 137, that indicates
that the build ran out of memory (typically when building Z3). We find
that 12GB of RAM is sufficient, but more may be necessary on your
machine.

The message `1 equivalence class` indicates that all terms given as
command-line arguments form a single equivalence class, i.e., the two
terms are equivalent.

Note that `3ce9eaca9fb1` will be replaced by some appropriate hash for
the generated Docker image. The `kmt` executable will be in
`/home/opam_build/default/src/kmt`; this directory is on your path.

Running `run_eval` inside the Docker container will reproduce the
evaluation from our paper. You can run the regression tests by running
`test_word` (for regular expression word equivalence, part of our
decision procedure) and `test_equivalence` (for KMT term
equivalence). All of these steps are performed automatically during
`docker build`.

# How do I use the `kmt` executable?

The default way of using the `kmt` executable is to give it a theory (here `--boolean`) and 2 or more KMT programs in that theory. It will give you the equivalence classes of thos terms. The `-v` flag is useful when many terms are given:

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
booleans. Run `kmt --help` for command-line help in a manpage-like
format.

## What is the syntax?

A Kleene algebra with tests breaks syntax into two parts: tests (or prediates) and actions. Actions are in some sense the 'top level', as every test is an action.

We use the following syntax, where `a` and `b` are tests, `p` and `q`
are actions. The following is the core Kleene algebra notation;
individual theories can introduce their own notations.

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
express any interesting programs. KMT builds a concrete KAT around a
_theory_. Many are predefined.

In general, theories add predicates and actions of the form
`NAME(ARGS,...)` and `ARG1 OP ARG2` . Each theory specificies its own
language.

#### Booleans

You can use the booleans by specifying `--boolean` on the `kmt` command line. It is the default theory, so you can also leave it off. The theory of booleans adds two forms, where `x` and `y` are variables:

  - `x=T` and `y=F` are tests that are true when `x` is true and `y`
    is false, respectively
  - `set(x,T)` and `set(y,F)` are actions that set `x` to true and `y`
    to false, respectively
    
#### Monotonic naturals

You can use the monotonically increasing naturals by specifying
`--kmt` on the command line. Monotonic naturals have several
theory-specific forms, where variables `x`, `y`, and `z` range over
natural numbers; we write `n` to mean a _constant_ natural number.

  - `x > n` is a test that is true when the variable `x`'s value is greater than `n`
  - `inc(y)` is an action increments the variable `y`
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

You can add new theories to the `kmt` tool by updating the `modes` in
`src/main.ml`.

# Step-by-Step

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

## Building locally

The simplest way to play with KMT right away is to [use
Docker](#how-do-i-build-it). If for some reason you would prefer to
run KMT on your own machine, run the following commands from a clone
of the repo. Here's a manual install script for Linux:

```ShellSession
$ sudo apt-get install -y libgmp-dev python3
$ opam install ocamlfind ppx_deriving batteries ANSIterminal fmt alcotest cmdliner logs zarith z3 dune
$ eval $(opam env)
$ dune build -- src/kmt      # build the CLI
$ dune test                  # unit tests on regex word equivalence and KMT equivalence
$ dune exec -- src/run_eval  # PLDI2022 eval
```

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

Check out `src/incnat.ml` for a simple language with increment and assignment operations. It defines types `a` and `p` for the primitive parts of the language (one predicate, which tests whether a variable is greater than a number, and two actions, which increment and set variables).

The code in `src/boolean.ml` is for a simple language with boolean-valued variables.

The code in `src/product.ml` is for a _higher-order theory_, combining
two theories into one. You can see it in action using the `--product`
and `--product-addition` flags for KMT.

## How is equivalence decided?

We decide equivalence via _normalization_. We convert KMT terms to a normal form using the novel `push_back` operation; to compare two such normal forms, we disambiguate the tests and compare the terms pointwise. When this procedure is fast, it's _quite_ fast... but deeply nested loops or loops with lots of conditionals slow it down severely.
