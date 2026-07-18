SHELL := /bin/bash

.PHONY: test syntax structure core smart sensors installer zabbix

test: syntax structure core smart sensors installer zabbix

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

zabbix:
	python3 ./tests/zabbix-template-test.py
