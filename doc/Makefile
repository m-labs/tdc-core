all: tdc.pdf testreport.pdf

tdc.pdf: tdc.tex
	pdflatex $<
	pdflatex $<

rofreq.pdf: rofreq.py rofreq.csv
	./rofreq.py rofreq.csv rofreq.pdf

mhistll.pdf: mhist.py series3a.csv
	./mhist.py series3a.csv mhistll.pdf 0 fit

mhistlh.pdf: mhist.py series3a.csv
	./mhist.py series3b.csv mhistlh.pdf 0 fit

mhisthh.pdf: mhist.py series3a.csv
	./mhist.py series3c.csv mhisthh.pdf 0 fit

mhisthl.pdf: mhist.py series3a.csv
	./mhist.py series3d.csv mhisthl.pdf 0 fit

testreport.pdf: testreport.tex rofreq.pdf mhistll.pdf mhistlh.pdf mhisthh.pdf mhisthl.pdf
	pdflatex $<
	pdflatex $<

clean:
	rm -f tdc.pdf tdc.aux tdc.log
	rm -f rofreq.pdf
	rm -f mhistll.pdf mhistlh.pdf mhisthh.pdf mhisthl.pdf
	rm -f testreport.pdf testreport.aux testreport.log

.PHONY: clean
