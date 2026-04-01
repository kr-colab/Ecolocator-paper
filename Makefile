TEX = pdflatex
BIB = biber
SRC = main

.PHONY: all clean

all: $(SRC).pdf

$(SRC).pdf: $(SRC).tex ELrefs.bib figures/*
	$(TEX) $(SRC)
	$(BIB) $(SRC)
	$(TEX) $(SRC)
	$(TEX) $(SRC)

clean:
	rm -f $(SRC).{aux,bbl,bcf,blg,log,out,pdf,run.xml,toc,lof,lot}
