TEX = main
INTERMEDIATES = $(TEX).blg $(TEX).log $(TEX).out \
                $(TEX).run.xml $(TEX).bcf $(TEX).toc $(TEX).lof $(TEX).lot
MAIN_AUX = $(TEX).aux $(TEX).bbl

BIB = ELrefs.bib
SOURCES = $(wildcard figures/*.pdf) $(wildcard figures/*.png)

# Revision / diff machinery.
# Single-source design: the revision is the SAME main.tex compiled with
# \revisionmode defined, which turns on line numbers and appends
# $(REV_DIR)/review-responses.tex after the supplement. Normal builds leave
# \revisionmode undefined and are completely unaffected.
#
#   make revision     - build main_revision.pdf (manuscript + responses, with
#                       working back-links) and split it into
#                       main_revision_only.pdf + review-responses.pdf
#   make diff         - build review-diff.pdf (latexdiff between the
#                       submitted manuscript at git ref DIFF_BASE_REF and
#                       the current revised content)
#   make all-revision - revision + diff (full resubmission package)
#
# Requires latexdiff, and pdfjam or pdftk to split the revision PDF.
REV_DIR       = pnas_rev1
REVISION_JOB  = main_revision
REVISION_PDF  = main_revision_only.pdf
RESPONSES_PDF = review-responses.pdf
DIFF_PDF      = review-diff.pdf
REVISION_INTERMEDIATES = $(foreach d,$(REVISION_JOB) review-diff,\
                         $(d).aux $(d).bbl $(d).blg $(d).log $(d).out \
                         $(d).run.xml $(d).bcf $(d).toc $(d).lof $(d).lot)
REVISION_LATEX = pdflatex -interaction=nonstopmode -jobname=$(REVISION_JOB) \
                 "\def\revisionmode{}\input{$(TEX)}"

# DIFF_BASE_REF is the submitted state of the manuscript.
# Override on the command line if needed (make diff DIFF_BASE_REF=<ref>).
DIFF_BASE_REF ?= submitted-v1
DIFF_TMP_DIR  := .diff-orig

.PHONY: all clean revision diff all-revision

all: $(TEX).pdf

$(TEX).pdf: $(TEX).tex $(SOURCES) $(BIB)
	pdflatex -interaction=nonstopmode $(TEX).tex
	biber $(TEX)
	pdflatex -interaction=nonstopmode $(TEX).tex
	pdflatex -interaction=nonstopmode $(TEX).tex
	rm -f $(INTERMEDIATES)

# Revision build: compile main.tex with \revisionmode defined under a
# distinct jobname, then split the resulting PDF at the page where the
# response document begins (recorded into review-responses-pagenum.txt by
# the response block in main.tex).
revision:
	$(REVISION_LATEX)
	biber $(REVISION_JOB)
	$(REVISION_LATEX)
	$(REVISION_LATEX)
	@RESP_START=`cat review-responses-pagenum.txt`; \
	if [ -z "$$RESP_START" ]; then echo "Error: review-responses-pagenum.txt not written"; exit 1; fi; \
	RESP_PREV=`expr $$RESP_START - 1`; \
	echo "Splitting revision: manuscript 1-$$RESP_PREV, responses $$RESP_START-last"; \
	rm -f $(REVISION_PDF) $(RESPONSES_PDF); \
	if command -v pdfjam >/dev/null 2>&1; then \
	  pdfjam $(REVISION_JOB).pdf 1-$$RESP_PREV -o $(REVISION_PDF) --quiet && \
	  pdfjam $(REVISION_JOB).pdf $$RESP_START-last -o $(RESPONSES_PDF) --quiet; \
	elif command -v pdftk >/dev/null 2>&1; then \
	  pdftk $(REVISION_JOB).pdf cat 1-$$RESP_PREV output $(REVISION_PDF) && \
	  pdftk $(REVISION_JOB).pdf cat $$RESP_START-end output $(RESPONSES_PDF); \
	else \
	  echo "ERROR: pdfjam or pdftk is required to split $(REVISION_JOB).pdf."; exit 1; \
	fi
	rm -f $(REVISION_INTERMEDIATES) review-responses-pagenum.txt

# latexdiff between the submitted manuscript (git ref DIFF_BASE_REF) and
# the current revised content. Both sides are diffed in NON-revision mode
# (no response block). The base main.tex is materialized from git into
# DIFF_TMP_DIR.
diff:
	@command -v latexdiff >/dev/null 2>&1 || { \
	  echo "ERROR: latexdiff is required for the diff target."; exit 1; }
	@git rev-parse --verify --quiet "$(DIFF_BASE_REF)^{commit}" >/dev/null || { \
	  echo "ERROR: git ref '$(DIFF_BASE_REF)' not found."; \
	  echo "Override with: make diff DIFF_BASE_REF=<ref>"; exit 1; }
	rm -rf $(DIFF_TMP_DIR); mkdir -p $(DIFF_TMP_DIR)
	git archive $(DIFF_BASE_REF) $(TEX).tex | tar -x -C $(DIFF_TMP_DIR)
	@# Strip the response block and the line-number switches from both
	@# sides so the diff shows only manuscript content changes. The
	@# submitted main.tex turned on \linenumbers unconditionally. The
	@# \revpoint etc. tags in the text fall back to the no-op definitions
	@# in the main.tex preamble.
	sed -e '/^% === Review Responses/,/^\\fi$$/d' \
	    -e '/\\ifdefined\\revisionmode\\linenumbers\\fi/d' \
	    $(TEX).tex > main-for-diff.tex
	sed -e '/^% === Review Responses/,/^\\fi$$/d' \
	    -e '/^\\linenumbers$$/d' \
	    $(DIFF_TMP_DIR)/$(TEX).tex > $(DIFF_TMP_DIR)/base-for-diff.tex
	@# --type=CFONT marks changes with color + font rather than ulem
	@# underlining, which breaks around line-breakable citations.
	latexdiff --flatten --type=CFONT $(DIFF_TMP_DIR)/base-for-diff.tex main-for-diff.tex > review-diff.tex.tmp
	grep -v '^WARNING:' review-diff.tex.tmp > review-diff.tex
	rm -f main-for-diff.tex review-diff.tex.tmp
	rm -rf $(DIFF_TMP_DIR)
	pdflatex -interaction=nonstopmode review-diff
	-biber review-diff
	pdflatex -interaction=nonstopmode review-diff
	pdflatex -interaction=nonstopmode review-diff
	rm -f $(REVISION_INTERMEDIATES)

all-revision: revision diff

clean:
	rm -f $(INTERMEDIATES) $(MAIN_AUX) $(TEX).pdf \
	      $(REVISION_JOB).pdf $(REVISION_PDF) $(RESPONSES_PDF) $(DIFF_PDF)
