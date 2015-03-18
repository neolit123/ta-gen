# ta-gen v1.3
A command line Texture Atlas generator for the Starling framework:
https://github.com/Gamua/Starling-Framework

### Authors

- interface by Lubomir I. Ivanov
- RectanglePacker by Ville Koskela
- PNGEncoder and Flash/AIR by Adobe
- PNGEncoder2 by Cameron Desrochers
- dither based on code by Ralph Hauwert

### Description

ta-gen is a command line Texture Atlas generator for the Starling format.
It allows you to process a folder of images and output a sprite sheet and a XML
descriptor. The application is written in AS3.0 and it uses the AIR runtime
only and is quite portable.

### Requirements

- a recent AIR SDK
- 'mxmlc' and 'adl' in PATH

for some reason the much faster PNGEncoder2 only works with AIR SDK v17.
for older AIR runtimes the PNGEncoder from Adobe will be used automatically.

### Building

run build.sh (osx) or build.cmd (win32). resulted SWF will be written to ./bin.

the build scripts will also call - writedesc.[cmd/sh], that will generate
a descriptor based on the "Version X.X.X.X" variable from the 'adl' output.
the descriptor is written in ./bin/ta-gen.xml.

edit ./bin/ta-gen.xml if needed.

### Installation

copy these files to a folder in PATH:
```
./bin/ta-gen.swf
./bin/ta-gen.xml
./bin/ta-gen (osx) or ./bin/ta-gen.cmd (win32)
```

edit ta-gen.xml if needed

### Usage

this will get your started:
```
ta-gen -help
```

list of arguments (could be out of date):
```
-in <path-to-load> -in <...>
-out <output-png>
-ignore <some-path-or-file> -ignore <...> (no wildcards)
-pngprefix <png-name-prefix>
-subprefix <texture-name-prefix>
-mindim <minimum-pixels> (def: 32)
-maxdim <maximum-pixels> (def: 2048)
-background <0xAARRGGBB> (def. 0x0)
-padding <padding-between-images> (def: 1)
-poweroftwo: end dimensions will be a power of 2 square
-colorbits <1-8> (def. 8): less than 8 means quantization
-dither: apply dithering for colorbits less than 8
-extrude <pixels> (def. 0): extrude the edges of each image
-gui: enable a simple user interface
-verbose: detailed output
-help: this screen

```

if you specify -gui and don't specify -in and -out the app becomes semi-GUI
and it will ask you where to find the source files and where to write the
output PNG / XML pair.  

for a usage example see ./test
