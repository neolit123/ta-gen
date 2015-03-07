#!/bin/sh
../bin/ta-gen -verbose -poweroftwo -in ./input -out ./output/test.png -pngprefix pngprefix/ -subprefix subprefix/ -mindim 32 -maxdim 1024 -dither -colorbits 4 -background 0xFF00FF00 -padding 4 -ignore ./input/part1/0.png
