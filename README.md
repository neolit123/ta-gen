# ta-gen [![Build Status](https://travis-ci.org/neolit123/ta-gen.svg)](https://travis-ci.org/neolit123/ta-gen)

A command line Texture Atlas generator for the Starling framework:
https://github.com/Gamua/Starling-Framework

### Authors

- interface by Lubomir I. Ivanov
- RectanglePacker by Ville Koskela
- PNGEncoder and Flash/AIR by Adobe
- PNGEncoder2 by Cameron Desrochers

### Website

https://github.com/neolit123/ta-gen

### Description

ta-gen is a command line Texture Atlas generator for the Starling format.
It allows you to process a folder of images and output a sprite sheet and a XML
descriptor. The application is written in AS3.0 and it uses the AIR runtime
only and is quite portable.

### Requirements

- a recent AIR SDK
- 'mxmlc' and 'adl' in PATH

If you don't have the '/AIR_SDK/bin/' folder in PATH you can use the environment
variable AIR_SDK_BIN to set it. Make sure that the path ends with '\' on
Windows or with '/' on OSX.

On OSX you might have to also 'chmod +x ...' the .sh scripts in ta-gen root
and also 'mxmlc' and 'adl' in the '/AIR_SDK/bin/' path.

For some reason the much faster PNGEncoder2 only works with AIR SDK v17.
For older AIR runtimes the PNGEncoder from Adobe will be used automatically.

### Building

Run build.sh (osx) or build.cmd (win32). Resulted SWF will be written to ./bin.

The build scripts will also call - writedesc.[cmd/sh], that will generate
a descriptor based on the "Version X.X.X.X" variable from the 'adl' output.
The descriptor is written in ./bin/ta-gen.xml.

Edit ./bin/ta-gen.xml or the generator scripts if needed.

### Installation

After building copy these files to a folder in PATH:
```
./bin/ta-gen.swf
./bin/ta-gen.xml
./bin/ta-gen (osx) or ./bin/ta-gen.cmd (win32)
```
Alternatively you can use one of the pre-built packages located in ./release.

### Usage

This will get you started:
```
ta-gen -help
```

List of arguments:
```
  -in <path-to-load> -in <...>
  -out <output-png>
  -ignore <some-path-or-file> -ignore <...> (no wildcards)
  -pngprefix <png-name-prefix>
  -subprefix <texture-name-prefix>
  -mindim <minimum-pixels> (def: 32)
  -maxdim <maximum-pixels> (def: 2048)
  -square: make the ouput image square
  -background <0xAARRGGBB> (def. 0x0)
  -padding <padding-between-images> (def: 1)
  -poweroftwo: end dimensions will be power-of-two based
  -channelbits <ARGB> (def. 8888): less than 8 per channel means quantization
  -quantizer <0-2> (def. 1): see -listquantizers
  -listquantizers: dump the quantizer list
  -extrude <pixels> (def. 0): extrude the edges of each image
  -gui: enable a simple user interface
  -pngencoder <0-5> (def: 0): see -listpngencoders
  -listpngencoders: dump the PNG encoder list
  -multipart: enable automatic splitting to multiple atlases
  -verbose: detailed output
  -help: this screen
```

If you specify -gui and don't specify -in and -out the app becomes semi-GUI
and it will ask you where to find the source files and where to write the
output PNG / XML pair.

For a usage example see ./test
