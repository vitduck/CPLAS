#!/usr/bin/env gnuplot 

set terminal postscript eps enhanced color font "Helvetica, 24" lw 2

# solid line 
set style line 1 lt 1 lw 4 linecolor rgb "#000000"  # black
set style line 2 lt 1 lw 4 linecolor rgb "#FF0000"  # red 
set style line 3 lt 1 lw 4 linecolor rgb "#00FF00"  # green
set style line 4 lt 2 lw 4 linecolor rgb "#0000FF"  # blue
set style line 5 lt 1 lw 4 linecolor rgb "#FF00FF"  # magenta 
set style line 6 lt 1 lw 4 linecolor rgb "#00FFFF"  # cyan
set style line 7 lt 1 lw 4 linecolor rgb "#FF4500"  # orange

# dotted line 
set style line 8 lt 2 lw 2 linecolor rgb "#000000"  # black

set key top right spacing 1.0 

set size ratio 1.0

set grid

set xlabel "" offset 0,0
set ylabel "" offset 0,0

set xtics 1 nomirror 
set ytics 1 format "%.1f" nomirror 

set xr [] 
set yr []

# function 
shift(x, value) = x < value ? x : 1/0 

set output "plot.eps"
