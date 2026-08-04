.PHONY: all clean kb-lint check

all:
	rocq compile -Q theories Notary theories/Merkle.v

kb-lint:
	python3 tools/kb-lint.py kb

check: all kb-lint

clean:
	rm -f theories/*.vo theories/*.vok theories/*.vos theories/*.glob theories/.*.aux
