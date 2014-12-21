@echo off
../bin/ta-gen -verbose -poweroftwo -in ./input -out ./output/test.png -pngprefix pngprefix/ -subprefix subprefix/ -mindim 32 -maxdim 512 -background 0xAA00FF00 -padding 4 -ignore ./input/part1/0.png
