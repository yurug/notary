.PHONY: all clean kb-lint check assumptions

all:
	rocq compile -Q theories Notary theories/Merkle.v

# The trusted base, asked of the kernel rather than kept in a document.
assumptions: all
	@rocq compile -Q theories Notary theories/Assumptions.v

kb-lint:
	python3 tools/kb-lint.py kb

check: all assumptions kb-lint

clean:
	rm -f theories/*.vo theories/*.vok theories/*.vos theories/*.glob theories/.*.aux
