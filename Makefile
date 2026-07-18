SHELL := /bin/bash

.PHONY: test syntax structure

test: syntax structure

syntax:
	bash ./tests/syntax-test.sh

structure:
	bash ./tests/structure-test.sh
