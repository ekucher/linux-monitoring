SHELL := /bin/bash

.PHONY: test syntax structure core smart sensors installer

test: syntax structure core smart sensors installer

syntax:
	bash ./tests/syntax-test.sh

structure:
	bash ./tests/structure-test.sh

core:
	bash ./tests/core-test.sh

smart:
	bash ./tests/smart-test.sh

sensors:
	bash ./tests/sensors-test.sh

installer:
	bash ./tests/installer-test.sh
