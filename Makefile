test:
	semgrep --validate --config=$$PWD/solidity $$PWD
	semgrep --test --quiet $$PWD