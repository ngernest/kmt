FROM ocaml/opam

RUN sudo apt-get install -y libgmp-dev python3

RUN opam install ocamlfind ppx_deriving batteries
RUN opam install ANSIterminal fmt alcotest cmdliner logs
RUN opam install zarith
RUN opam install -v z3
RUN opam install dune

COPY --chown=opam:opam . kmt

WORKDIR /home/opam/kmt

RUN opam exec -- dune build -- src/kmt

RUN opam exec -- dune exec -- src/test_word
RUN opam exec -- dune exec -- src/test_equivalence
RUN opam exec -- dune exec -- src/eval

RUN echo "PATH=/home/opam/kmt/_build/default/src:$PATH" >>~/.bashrc
RUN echo "eval $(opam env)" >>~/.bashrc

ENTRYPOINT [ "opam", "exec", "--" ]
CMD [ "bash" ]
