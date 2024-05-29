FILE=report
OUTPUT=report
COMPILER=pdflatex

typeset: $(FILE).tex
	$(COMPILER) --jobname=$(OUTPUT) -shell-escape $(FILE).tex

.PHONY: open
open:
	open $(OUTPUT).pdf

.PHONY: clean
clean: 
	rm -r *.aux *.log _minted-report