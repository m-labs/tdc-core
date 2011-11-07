all: tdc.pdf testreport.pdf

tdc.pdf: tdc.tex
	pdflatex $<
	pdflatex $<

rofreq.pdf: rofreq.py rofreq.csv
	./rofreq.py rofreq.csv rofreq.pdf

testreport.pdf: testreport.tex rofreq.pdf
	pdflatex $<
	pdflatex $<

clean:
	rm -f tdc.pdf tdc.aux tdc.log
	rm -f rofreq.pdf
	rm -f testreport.pdf testreport.aux testreport.log

.PHONY: clean
