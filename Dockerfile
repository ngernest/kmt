FROM ocaml/opam

RUN sudo apt-get install -y libgmp-dev python3

COPY --chown=opam:opam . kmt

WORKDIR /home/opam/kmt

RUN mkdir -p /home/opam/.config/dune && printf "(lang dune 3.0)\n(display short)\n" >/home/opam/.config/dune/config

RUN opam install -t .

RUN opam exec -- kmt_eval

RUN echo 'eval $(opam env)' >>~/.bashrc

ENTRYPOINT [ "opam", "exec", "--" ]
CMD [ "bash" ]
