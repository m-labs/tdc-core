set format "$%g$"
set xlabel "Temperature [C]"
set ylabel "Ring oscillator frequency [counts]"
set border 3
set xtics nomirror
set ytics nomirror
set terminal epslatex
set output "rofreq1.eps"
set title "Dependence of ring oscillator frequency on temperature (channel 1)"
set datafile separator ","
plot "rofreq.csv" using 1:3
