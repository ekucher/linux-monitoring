SHELL := /bin/bash

.PHONY: test syntax structure

test: syntax structure

syntax:
	./tests/syntax-test.sh

structure:
	./tests/structure-test.sh
