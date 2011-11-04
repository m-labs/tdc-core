all: tdc.pdf testreport.pdf

tdc.pdf: tdc.tex
	pdflatex $<
	pdflatex $<

rofreq1.eps rofreq1.tex rofreq2.eps rofreq2.tex: rofreq.gp rofreq.csv
	gnuplot rofreq.gp

rofreq1.pdf: rofreq1.eps
	epstopdf rofreq1.eps

rofreq1_pdf.tex: rofreq1.tex
	cat rofreq1.tex | sed s/".eps"/".pdf"/g > rofreq1_pdf.tex
	
rofreq2.pdf: rofreq2.eps
	epstopdf rofreq2.eps

rofreq2_pdf.tex: rofreq2.tex
	cat rofreq2.tex | sed s/".eps"/".pdf"/g > rofreq2_pdf.tex

testreport.pdf: testreport.tex rofreq1_pdf.tex rofreq2_pdf.tex rofreq1.pdf rofreq2.pdf
	pdflatex $<
	pdflatex $<

clean:
	rm -f tdc.pdf tdc.aux tdc.log
	rm -f rofreq1.eps rofreq1.tex rofreq2.eps rofreq2.tex
	rm -f rofreq1_pdf.tex rofreq2_pdf.tex
	rm -f rofreq1.pdf rofreq2.pdf
	rm -f testreport.pdf testreport.aux testreport.log

.PHONY: clean
