FROM ocaml/opam

RUN sudo apt-get update # lolsob
RUN sudo apt-get install -y libgmp-dev python3

RUN opam install ocamlfind ppx_deriving batteries
RUN opam install ANSIterminal fmt alcotest cmdliner logs
RUN opam install zarith
RUN opam install -v z3
RUN opam install dune

COPY --chown=opam:opam . kmt

WORKDIR /home/opam/kmt

RUN mkdir -p /home/opam/.config/dune && printf "(lang dune 3.0)\n(display short)\n" >/home/opam/.config/dune/config

RUN opam exec -- dune build -- src/kmt src/test_word src/test_equivalence src/run_eval

RUN opam exec -- dune test
RUN opam exec -- dune exec -- src/run_eval

RUN echo "PATH=/home/opam/kmt/_build/default/src:$PATH" >>~/.bashrc
RUN echo 'eval $(opam env)' >>~/.bashrc

ENTRYPOINT [ "opam", "exec", "--" ]
CMD [ "bash" ]
