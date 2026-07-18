SHELL := /bin/bash

.PHONY: test syntax structure core smart

test: syntax structure core smart

syntax:
	bash ./tests/syntax-test.sh

structure:
	bash ./tests/structure-test.sh

core:
	bash ./tests/core-test.sh

smart:
	bash ./tests/smart-test.sh
