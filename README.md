[![Main workflow](https://github.com/mgree/kmt/actions/workflows/build.yml/badge.svg)](https://github.com/mgree/kmt/actions/workflows/build.yml)

An implementation of [Kleene algebra modulo theories](https://arxiv.org/abs/1707.02894) (KMT), a framework for composing and deriving programming languages with sound and complete decision procedures for program equivalence.

# What is KMT?

Kleene algebra modulo theories (KMT) is a framework for deriving _concrete_ Kleene algebras with tests (KATs), an algebraic framework for While-like programs with decidable program equivalence.

More plainly: KMT is a framework for building simple programming languages with structured control (if, while, etc.) where you we can decide whether or not two programs are equivalent. You can use equivalence to verify programs. If `a` is a nice property to have after running your program, then if `p;a == p`, you know that `p` satisfies `a`. Kleene algebra with tests subsumes Hoare logic: if `a;p;~b == 0` then all runs starting from `a` either diverge or end with `b`, i.e., that equation corresponds to the partial correctness specification `{a} p {b}`.

In addition to providing an OCaml library for defining KMTs over your own theories, we offer a command-line tool for testing a variety

# How do I build it?

The simplest way to play with KMT right away is to use Docker. From the repo, run:

```ShellSession
$ docker build -t kmt .    # build KMT and run tests
$ docker run -it kmt       # enter a shell
opam@3ce9eaca9fb1:~/kmt$ kmt --boolean 'x=T' 'not x=F' 
[x=T parsed as x=T]
nf time: 0.000004s
lunf time: 0.000017s
[not x=F parsed as x=T]
nf time: 0.000002s
lunf time: 0.000004s
[1 equivalence class]
```

Note that `3ce9eaca9fb1` will be replaced by some appropriate hash for the generated Docker image.

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

## Building locally

If you have a recent version of OCaml, simply `dune build -- src/kmt` should do the trick. `dune exec -- src/eval` will reproduce the evaluation from our paper. You can run the regression tests by running `dune exec -- src/test_word` (for regular expression word equivalence) and `dune exec -- src/test_equivalence` (for KMT term equivalence).

The CI automation is a good guide for manual installation: see the `Dockerfile` and `.github/workflows/build.yml`. Here's a manual install script for Linux:

```ShellSession
$ sudo apt-get install -y libgmp-dev python3
$ opam install ocamlfind ppx_deriving batteries ANSIterminal fmt alcotest cmdliner logs zarith z3 dune
$ eval $(opam env)
$ dune build -- src/kmt    # build the CLI
$ dune test                # unit tests on regex word equivalence and KMT equivalence
$ dune exec -- src/eval    # PLDI2022 eval
```

The `kmt` executable will be in `/home/opam_build/default/src/kmt`;
this directory is on your path.

# What is the syntax?

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

## Theory-specific forms

On its own, the Kleene algebra with tests above doesn't let you
express any interesting programs. KMT builds a concrete KAT around a
_theory_. Many are predefined.

In general, theories add predicates and actions of the form
`NAME(ARGS,...)` and `ARG1 OP ARG2` . Each theory specificies its own
language.

### Booleans

You can use the booleans by specifying `--boolean` on the `kmt` command line. It is the default theory, so you can also leave it off. The theory of booleans adds two forms, where `x` and `y` are variables:

  - `x=T` and `y=F` are tests that are true when `x` is true and `y`
    is false, respectively
  - `set(x,T)` and `set(y,F)` are actions that set `x` to true and `y`
    to false, respectively
    
### Monotonic naturals

You can use the monotonically increasing naturals by specifying
`--kmt` on the command line. Monotonic naturals have several
theory-specific forms, where variables `x`, `y`, and `z` range over
natural numbers; we write `n` to mean a _constant_ natural number.

  - `x > n` is a test that is true when the variable `x`'s value is greater than `n`
  - `inc(y)` is an action increments the variable `y`
  - `set(z, n)` is an action that sets the variable `z` to `n`
  
### Other theories

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

# What do I have to provide to write my own theory?

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

## Which example theories should I look at first?

Check out `src/incnat.ml` for a simple language with increment and assignment operations. It defines types `a` and `p` for the primitive parts of the language (one predicate, which tests whether a variable is greater than a number, and two actions, which increment and set variables).

The code in `src/boolean.ml` is for a simple language with boolean-valued variables.

The code in `src/ltlf.ml` is for a _higher-order theory_, wrapping a given theory with predicates for testing LTLf (past-time finite linear temporal logic) predicates.

# How is equivalence decided?

We decide equivalence via _normalization_. We convert KMT terms to a normal form using the novel `push_back` operation; to compare two such normal forms, we disambiguate the tests and compare the terms pointwise. When this procedure is fast, it's _quite_ fast... but deeply nested loops or loops with lots of conditionals slow it down severely.
