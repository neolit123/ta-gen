# ta-gen v1.0
A command line Texture Atlas generator for Starling

### Authors

- interface by Lubomir I. Ivanov
- RectanglePacker by Ville Koskela
- PNGEncoder and Flash/AIR by Adobe

### Description

ta-gen is a command line Texture Atlas generator for the Starling format.
It allows you to process a folder of images and output a sprite sheet and a XML
descriptor. The application is written in AS3.0 and it uses the AIR runtime
only and is quite portable.

### Requirements

- recent AIR SDK
- mxmlc and adl in PATH

### Building

run build.sh (osx) or build.cmd (win32). resulted SWF will be written to ./bin.

edit ta-gen.xml if needed

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
-verbose: detailed output
-help: this screen
```

if you don't specify -in or -out the app becomes semi-GUI and it will ask you
where to find the source files and where to write the output PNG / XML pair.

for a usage example see ./test
