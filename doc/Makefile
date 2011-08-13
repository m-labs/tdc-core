TEX=tdc.tex

PDF=$(TEX:.tex=.pdf)
AUX=$(TEX:.tex=.aux)
LOG=$(TEX:.tex=.log)

all: $(PDF)

%.pdf: %.tex
	pdflatex $<
	pdflatex $<

clean:
	rm -f $(PDF) $(AUX) $(LOG)

.PHONY: clean
