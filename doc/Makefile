all: tdc.pdf testreport.pdf

tdc.pdf: tdc.tex
	pdflatex $<
	pdflatex $<

rofreq.pdf: rofreq.py rofreq.csv
	./rofreq.py rofreq.csv rofreq.pdf

scs.pdf: lutdiff.py
	./lutdiff.py lt_cal1.csv lt_cal2.csv scs.pdf

mhist.pdf: mhist.py series3a.csv
	./mhist.py series3a.csv mhist.pdf 0 fit

chtmlt.pdf: lutdiff.py
	./lutdiff.py ht_cal1.csv lt_cal2.csv chtmlt.pdf

chtmht.pdf: lutdiff.py
	./lutdiff.py ht_cal1.csv ht_nocal.csv chtmht.pdf

testreport.pdf: testreport.tex rofreq.pdf scs.pdf mhist.pdf chtmlt.pdf chtmht.pdf
	pdflatex $<
	pdflatex $<

clean:
	rm -f tdc.pdf tdc.aux tdc.log
	rm -f rofreq.pdf
	rm -f mhist.pdf
	rm -f testreport.pdf testreport.aux testreport.log

.PHONY: clean
