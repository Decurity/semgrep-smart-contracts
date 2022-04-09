test:
	semgrep --validate --config=$$PWD/rules $$PWD
	semgrep --test --quiet $$PWD