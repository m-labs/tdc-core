TEX=tdc.tex

AUX=$(TEX:.tex=.aux)
LOG=$(TEX:.tex=.log)

all: $(PDF)

%.pdf: %.tex
	pdflatex $<

clean:
	rm -f $(PDF) $(AUX) $(LOG)

.PHONY: clean
