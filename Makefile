MLFILES= src/*.ml src/*.mli src/*.mll src/*.mly \

build: $(MLFILES)
	ocamlbuild -use-ocamlfind -r src/main.native

test: src/tests.ml 
	ocamlbuild -use-ocamlfind -r src/tests.native
	./tests.native

clean:
	ocamlbuild -clean
	rm -f bin/*.native

.PHONY: build clean