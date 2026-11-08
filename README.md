# ecoLocator paper

Working repository for the ecoLocator manuscript:

> Rodriguez, Cronn, Tittes, and Kern
> **This must be the place: deep learning local adaptation**
> *PNAS*, manuscript 2026-35068 (in revision)

The software is at [kr-colab/ecolocator](https://github.com/kr-colab/ecolocator).

## Contents

- `main.tex` -- the manuscript and supplement, in one file.
- `ELrefs.bib` -- the bibliography.
- `figures/` -- all figures used by `main.tex`.
- `pnas_rev1/` -- the first PNAS revision:
  - `pnas_decision1.txt` -- the decision letter and reviews, verbatim.
  - `review-responses.tex` -- the cover letter and point-by-point responses.
  - `review-response-commands.tex` -- LaTeX macros for the responses.

## Building

Requirements: `pdflatex` and `biber`. The revision targets also need
`latexdiff`, and `pdfjam` or `pdftk`.

```sh
make               # main.pdf: the clean manuscript, no line numbers
make revision      # main_revision_only.pdf + review-responses.pdf
make diff          # review-diff.pdf: tracked changes against the submitted version
make all-revision  # revision + diff: the full resubmission package
make clean         # remove the PDFs and build files
```

### `make revision`

This target compiles `main.tex` again with `\revisionmode` defined. In this
mode the manuscript has line numbers, and `pnas_rev1/review-responses.tex` is
added after the supplement. Because the two parts are compiled as one
document, the page and line references from the responses to the manuscript
work. The Makefile then splits the PDF into:

- `main_revision_only.pdf` -- the revised manuscript, with line numbers.
- `review-responses.pdf` -- the response letter.

### `make diff`

This target compares the current `main.tex` with the version at the git tag
`submitted-v1`, which is the version submitted to PNAS. It uses
`latexdiff --type=CFONT`: added text is in blue and deleted text is in red. The
response block and the line numbers are removed from both versions first, so
the diff shows only changes to the manuscript.

To compare with a different version:

```sh
make diff DIFF_BASE_REF=<commit-or-tag>
```

If `make diff` cannot find `submitted-v1`, get the tags with
`git fetch --tags`.

## Writing the responses

Each reviewer comment in `pnas_rev1/review-responses.tex` is a `{point}`. The
PDF numbers the points (E.1), (1.1), (1.2), ..., (2.1), and so on. Write each
reply in the `\reply{...}` after its point.

To link a reply to the manuscript line that it refers to:

1. In `main.tex`, put `\revpoint{R}{P}` on the changed text, where `R` is the
   reviewer (`E`, `1`, or `2`) and `P` is the point number. For example,
   `\revpoint{1}{4}` for Reviewer 1, point 4.
2. In the reply to that point, write `\revref`. In the revision PDF it becomes
   a linked reference, for example "(p. 12, l. 340)".

To refer to a point from a different reply, use `\revreffull{R}{P}`.

If several replies refer to the same line, put `\llabel{name}` at that line in
`main.tex`, and use `\llname{name}` in each reply.

All these tags expand to nothing in `make` and `make diff`, so they do not
change the clean manuscript or the tracked-changes PDF.

## Authors

Jordan Rodriguez, Richard Cronn, Silas Tittes, and Andrew D. Kern
