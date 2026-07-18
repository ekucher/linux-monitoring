SHELL := /bin/bash

.PHONY: test syntax structure core

test: syntax structure core

syntax:
	bash ./tests/syntax-test.sh

structure:
	bash ./tests/structure-test.sh

core:
	bash ./tests/core-test.sh
