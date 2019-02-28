/**
 * ta-gen
 *
 * Copyright 2014 and later Lubomir I. Ivanov. All rights reserved.
 *
 * Email: neolit123 [at] gmail.com
 *
 * You may redistribute, use and/or modify this source code freely
 * but this copyright statement must not be removed from the source files.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

package
{
	import flash.desktop.NativeApplication;

	import flash.filesystem.File;
	import flash.filesystem.FileStream;
	import flash.filesystem.FileMode;

	import flash.display.Sprite;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.PNGEncoderOptions;
	import flash.geom.Matrix;

	import flash.text.TextField;
	import flash.text.TextFormat;

	import flash.geom.Rectangle;
	import flash.geom.Point;

	import flash.events.Event;
	import flash.events.InvokeEvent;
	import flash.events.ErrorEvent;
	import flash.events.UncaughtErrorEvent;

	import flash.utils.ByteArray;
	import flash.utils.getTimer;

	import PNGEncoder2;
	import com.adobe.images.PNGEncoder;
	import org.villekoskela.utils.RectanglePacker;
	import neolit123.utils.BitmapDataQuantize;
	import neolit123.utils.BitmapDataExtrude;

	[SWF(width='512', height='512', backgroundColor='#ffffff', frameRate='1000')]

	public class Main extends Sprite
	{
		private const FILE_SEP:String = File.separator;
		private const EXT_PNG:String = ".png";
		private const EXT_XML:String = ".xml";

		// params and default values
		private var padding:uint = 1;
		private var maxDim:uint = 2048;
		private var minDim:uint = 32;
		private var pngPrefix:String = "";
		private var subPrefix:String = "";
		private var usePowerOfTwo:Boolean = false;
		private var channelBits:Vector.<uint> = new <uint>[8, 8, 8, 8];
		private var verbose:Boolean = false;
		private var dimW:uint, dimH:uint;
		private var dimError:Boolean = false;
		private var background:uint = 0x0;
		private var extrude:uint = 0;
		private var hasGUI:Boolean = false;
		private var pngEncoder:uint = ENC_PNGENCODER_AS;
		private var pngEncoderOptions:PNGEncoderOptions = new PNGEncoderOptions();
		private var quantizer:uint = QUANT_FLOYD_STEINBERG;
		private var scale:Number = 1;
		private var useSquare:Boolean = false;
		private var useMultipart:Boolean = false;

		// files and lists
		private var currentDir:File = null;
		private var outFile:File = null;
		private var folder:File = null;
		private var folderNativePathSEP:String = null;
		private var folders:Vector.<File> = new <File>[];
		private var ignore:Vector.<File> = new <File>[];
		private var files:Vector.<File> = new <File>[];

		// UI
		private var cont:Sprite;
		private var textLog:TextField;

		// files operations
		private var loader:Loader = new Loader();
		private var loaded:uint = 0;
		private var currentPart:uint = 0;
		private var stream:FileStream = new FileStream();
		private var fileBytes:ByteArray = new ByteArray();
		private var filesLength:uint;

		// bitmap lists
		private var bmp:Vector.<Bitmap> = new <Bitmap>[];
		private var bmpRemaining:Vector.<Bitmap> = new <Bitmap>[];

		/// timers
		private var startTime:uint;
		private var initialTime:uint;

		// extrude variables
		private var extrudeRect:Rectangle = new Rectangle(0, 0, 0, 0);
		private var extrudePoint:Point = new Point(0, 0);

		// packer
		private var packer:RectanglePacker = null;

		// encoders
		private static const ENC_PNGENCODER_AS:uint = 0;
		private static const ENC_BITMAPDATA_ENCODE:uint = 1;
		private static const ENC_BITMAPDATA_ENCODE_FAST:uint = 2;
		private static const ENC_PNGENCODER2_FAST:uint = 3;
		private static const ENC_PNGENCODER2_NORMAL:uint = 4;
		private static const ENC_PNGENCODER2_GOOD:uint = 5;

		private static const ENC_LIST:Vector.<String> = new <String>[
			"ENC_PNGENCODER_AS",
			"ENC_BITMAPDATA_ENCODE",
			"ENC_BITMAPDATA_ENCODE_FAST",
			"ENC_PNGENCODER2_FAST",
			"ENC_PNGENCODER2_NORMAL",
			"ENC_PNGENCODER2_GOOD"
		];

		// qunatizers
		private static const QUANT_POSTERIZE_FAST:uint = 0;
		private static const QUANT_FLOYD_STEINBERG:uint = 1;
		private static const QUANT_NOISE_SHAPING:uint = 2;

		private static const QUANT_LIST:Vector.<String> = new <String>[
			"QUANT_POSTERIZE_FAST",
			"QUANT_FLOYD_STEINBERG",
			"QUANT_NOISE_SHAPING"
		];

		// version and title
		private static const TITLE:String = "ta-gen v" + Version.VERSION_STRING;
		private static const HELP_TEXT:String = "TITLE";/*TITLE + <![CDATA[

Copyright 2014 and later, Lubomir I. Ivanov. All rights reserved.

RectanglePacker
Copyright 2012, Ville Koskela. All rights reserved.

PNGEncoder
Copyright 2008, Adobe Systems Incorporated. All rights reserved.
Copyright 2015, Lubomir I. Ivanov. All rights reserved.

PNGEncoder2
Copyright 2008, Adobe Systems Incorporated. All rights reserved.
Copyright 2011, Pimm Hogeling and Edo Rivai. All rights reserved.
Copyright 2011-2015, Cameron Desrochers. All rights reserved.

usage:
adl <app-xml> -- [arguments]

argument list:
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
  -scale <0-1> (def. 1): scale of atlas
  -help: this screen
]]>;*/

		public function Main():void
		{
			new PNGEncoderOptions();

			initialTime = getTimer();

			loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, handleErrors);

			// add the invoke handler
			NativeApplication.nativeApplication.addEventListener(InvokeEvent.INVOKE, invokeEventHandler);

			// the main container where images will be stored
			cont = new Sprite();

			// add listener to the loader
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loadCompleteHandler);
		}

		// called each time the app starts
		public function invokeEventHandler(_e:InvokeEvent):void
		{
			currentDir = _e.currentDirectory;
			const args:Array = _e.arguments;
			const argLen:int = args.length;
			var i:uint, j:uint;

			// parse command line

			if (argLen) {
				if (args.indexOf("-verbose") != -1)
					verbose = true;

				// show title
				log(TITLE);

				// help
				if (args.indexOf("-help") != -1) {
					verbose = true;
					log(HELP_TEXT);
					exit();
					return;
				} else if (args.indexOf("-listpngencoders") != -1) {
					verbose = true;
					log(enumerateList(ENC_LIST));
					exit();
					return;
				} else if (args.indexOf("-listquantizers") != -1) {
					verbose = true;
					log(enumerateList(QUANT_LIST));
					exit();
					return;
				}

				for (i = 0; i < argLen; i++) {

					const carg:String = args[i];

					// one part arguments
					switch (carg) {
					case "-poweroftwo":
						usePowerOfTwo = true;
						logArgument(carg);
						continue;
					case "-gui":
						hasGUI = true;
						createGUI();
						logArgument(carg);
						continue;
					case "-verbose":
						logArgument(carg);
						continue; // already handled
					case "-square":
						useSquare = true;
						logArgument(carg);
						continue;
					case "-multipart":
						useMultipart = true;
						logArgument(carg);
						continue;
					}

					var iPrev:int = i; // store current index

					if (i < argLen - 1) { // bellow are two-part arguments

						const narg:String = args[i + 1];

						switch (carg) {
						case "-in":
							folder = currentDir.resolvePath(narg);
							folderNativePathSEP = folder.nativePath + FILE_SEP;
							logArgument(carg, folder.nativePath);
							if (!folder.exists || !folder.isDirectory) {
								error("input path not a directory or does not exist", true);
								return;
							}
							folders[folders.length] = folder;
							i++;
							break;
						case "-out":
							outFile = currentDir.resolvePath(narg);
							checkAddPNGExtension();

							logArgument(carg, outFile.nativePath);
							i++;
							break;
						case "-pngprefix":
							pngPrefix = narg;
							logArgument(carg, pngPrefix);
							i++;
							break;
						case "-subprefix":
							subPrefix = narg;
							logArgument(carg, subPrefix);
							i++;
							break;
						case "-mindim":
							minDim = uint(narg);
							logArgument(carg, minDim);
							i++;
							break;
						case "-maxdim":
							maxDim = uint(narg);
							logArgument(carg, maxDim);
							i++;
							break;
						case "-background":
							background = uint(narg);
							logArgument(carg, background.toString(16).toUpperCase());
							i++;
							break;
						case "-padding":
							padding = uint(narg);
							logArgument(carg, padding);
							i++;
							break;
						case "-ignore":
							const ignorePath:File = currentDir.resolvePath(narg);
							logArgument(carg, ignorePath.nativePath);
							ignore[ignore.length] = ignorePath;
							i++;
							break;
						case "-channelbits":
							if (narg.length == 4) {
								for (j = 0; j < 4; j++) {
									var channelBitTemp:uint = uint(narg.charAt(j));
									if (channelBitTemp > 8) {
										warning("bad value for " + carg + " at index " + j + " [" + channelBitTemp + "]. setting it to 8.");
										channelBitTemp = 8;
									}
									channelBits[j] = channelBitTemp;
								}
							} else {
								warning("bad number of digits for " + carg + ". setting it to 8888.");
							}
							logArgument(carg, channelBits.join(""));
							i++;
							break;
						case "-extrude":
							extrude = uint(narg);
							logArgument(carg, extrude);
							i++;
							break;
						case "-pngencoder":
							pngEncoder = uint(narg);
							if (pngEncoder > ENC_LIST.length - 1) {
								warning("bad PNG encoder. setting the default one.");
								pngEncoder = ENC_PNGENCODER_AS;
							}
							logArgument(carg, ENC_LIST[pngEncoder]);
							i++;
							break;
						case "-quantizer":
							quantizer = uint(narg);
							if (quantizer > QUANT_LIST.length - 1) {
								warning("bad quantizer. setting the default one.");
								quantizer = QUANT_FLOYD_STEINBERG;
							}
							logArgument(carg, QUANT_LIST[quantizer]);
							i++;
							break;
						case "-scale":
							scale = parseFloat(narg);
							if (scale < 0) {
								warning("scale cannot be 0 or lower");
								scale = 1;
							}
							logArgument(carg, scale);
							i++;
							break;
						}
					}

					if (i == iPrev) // the index has not updated the current argument is unknown
						warning("unknown argument '" + carg + "'");
				}

				if (!minDim || !maxDim) {
					error("mindim or maxdim cannot be zero");
					return;
				}

				if (minDim > maxDim) {
					error("mindim cannot be larger than maxdim");
					return;
				}

				if (usePowerOfTwo) {
					if (!isPowerOfTwo(minDim)) {
						minDim = toPowerOfTwo(minDim);
						warning("adjusting mindim to the nearest power of two: " + minDim);
					}
					if (!isPowerOfTwo(maxDim)) {
						maxDim = toPowerOfTwo(maxDim);
						warning("adjusting maxdim to the nearest power of two: " + maxDim);
					}
				}

				if (!hasGUI && !outFile)
					error("missing output", true);

				const foldersLength:uint = folders.length;
				if (foldersLength) {
					for (i = 0; i < foldersLength; i++)
						traverse(folders[i]);
					processFolders();
					return;
				} else {
					if (!hasGUI)
						error("missing input", true);
				}
			} else { // if no command line arguments are passed, create GUI
				hasGUI = true;
				createGUI();
			}

			if (hasGUI) {
				// show open dialog
				folder = new File();
				folder.addEventListener(Event.SELECT, browseInputHandler);
				folder.browseForDirectory("Select input folder");
			}
		}

		private function logArgument(_arg:String, _val:* = null):void
		{
			log("* argument " + _arg + (_val ? (": " + _val.toString()) : ""));
		}

		private function createGUI():void
		{
			NativeApplication.nativeApplication.openedWindows[0].visible = true;

			// a textfield to write the log to
			textLog = new TextField();
			textLog.border = true;
			textLog.background = true;
			textLog.multiline = true;
			textLog.wordWrap = true;
			textLog.width = stage.stageWidth;
			textLog.height = stage.stageHeight;
			textLog.y = 0; // stage.stageHeight - textLog.height;
			textLog.defaultTextFormat = new TextFormat("_typewriter");
			addChild(textLog);
		}

		private function isPowerOfTwo(_x:uint):Boolean
		{
			return (_x & (_x - 1)) == 0;
		}

		private function toPowerOfTwo(_x:uint):uint
		{
			return Math.pow(2, Math.round(Math.log(_x) / Math.LN2));
		}

		private function log(_text:String):void
		{
			if (verbose)
				trace(_text);
			if (hasGUI) {
				textLog.appendText(_text + "\n");
				textLog.scrollV = textLog.maxScrollV;
			}
		}

		private function warning(_text:String):void
		{
			const oldVerbose:Boolean = verbose;
			verbose = true;
			log("* WARNING: " + _text);
			verbose = oldVerbose;
		}

		private function error(_text:String, _exit:Boolean = true):void
		{
			const oldVerbose:Boolean = verbose;
			verbose = true;
			log("* ERROR: " + _text);
			verbose = oldVerbose;
			if (_exit)
				exit();
		}

		private function exit():void
		{
			NativeApplication.nativeApplication.exit();
		}

		private function browseInputHandler(_e:Event):void
		{
			traverse(folder);
			processFolders();
		}

		private function checkAddPNGExtension():void
		{
			const pathLowerCase:String = outFile.nativePath.toLowerCase();
			if (pathLowerCase.indexOf(EXT_PNG) == -1) {
				warning("appending " + EXT_PNG + " to the output file");
				outFile = outFile.resolvePath(outFile.nativePath + EXT_PNG);
			}
		}

		private function loadFile(_file:File):void
		{
			stream.open(_file, FileMode.READ);
			const sz:uint = stream.bytesAvailable;

			if (!sz) {
				warning("skipping zero sized file: " +
					_file.nativePath.split(folderNativePathSEP).join(""));
				stream.close();
				loadNextFile();
				return;
			}

			fileBytes.length = sz;
			stream.readBytes(fileBytes, 0, sz);
			stream.close();

			loader.loadBytes(fileBytes);
		}

		private function loadNextFile():void
		{
			loaded++;
			if (loaded < filesLength) {
				loadFile(files[loaded]);
			} else {
				log("* done loading in " + (getTimer() - startTime) + " ms");
				if (!hasGUI) {
					sortBitmapsInContainer();
				} else { // if GUI is enabled the user will be asked where to output the PNG
					if (!outFile)
						outFile = new File();
					outFile.addEventListener(Event.SELECT, browseOutputHandler);
					outFile.browseForSave("Save output PNG image");
				}
			}
		}

		private function browseOutputHandler(_e:Event):void
		{
			outFile.removeEventListener(Event.SELECT, browseOutputHandler);
			outFile = _e.target as File;
			checkAddPNGExtension();
			sortBitmapsInContainer();
		}

		// process folder
		private function processFolders():void
		{
			if (files.length) {
				filesLength = files.length;

				startTime = getTimer();
				log("* loading " + filesLength + " files...");

				if (extrude)
					warning("each image will be extruded by " + extrude + " pixels");

				loadFile(files[0]);

			} else {
				error("nothing to load!");
				if (!hasGUI)
					exit();
			}
		}

		private function handleErrors(_e:UncaughtErrorEvent):void
		{
			_e.preventDefault();

			const err:* = _e.error;
			var msg:String = "";

			if (err is Error) {
				msg += err.error;
				msg += err.getStackTrace();
			} else if (err is ErrorEvent) {
				msg += err.text;
			} else {
				 msg += err.toString();
			}

			error(msg, true);
		}

		// check if path should be ignored
		private function checkPathIgnore(_file:File):Boolean
		{
			const len:uint = ignore.length;
			for (var i:uint = 0; i < len; i++) {
				if (_file.nativePath == ignore[i].nativePath)
					return true;
			}
			return false;
		}

		// recursive function to extract all files in subfolders
		private function traverse(_dir:File):void
		{
			var list:Array = _dir.getDirectoryListing();
			const len:uint = list.length;
			for (var i:uint = 0; i < len; i++) {

				const cur:File = list[i];

				if (checkPathIgnore(cur))
					continue;

				if (cur.isDirectory) {
					traverse(cur);
					continue;
				}

				const path:String = cur.nativePath;
				const lcPath:String = path.toLowerCase();
				const lcPathLen:uint = lcPath.length;

				// handle 3 char extensions
				const lcPathLen4:uint = lcPathLen - 4;
				if (lcPathLen4 < 0)
					continue;

				const sub4:String = lcPath.substring(lcPathLen4, lcPathLen);
				switch (sub4) {
				case ".jpg":
				case ".png":
				case ".gif":
					files[files.length] = cur;
					continue;
				}

				// handle 4 char extensions
				const lcPathLen5:uint = lcPathLen - 5;
				if (lcPathLen5 < 0)
					continue;

				const sub5:String = lcPath.substring(lcPathLen5, lcPathLen);
				switch (sub5) {
				case ".jpeg":
					files[files.length] = cur;
					continue;
				}

				warning("skipping file with unknown extension: " +
					cur.nativePath.split(folderNativePathSEP).join(""));
			}
		}

		// called each time the loader loads an image
		private function loadCompleteHandler(_e:Event):void
		{
			var source:BitmapData = (loader.content as Bitmap).bitmapData;

			// perform extrusion if 'extrude' is more than 0
			if (extrude)
				source = BitmapDataExtrude.extrude(source, extrude, true, extrudeRect, extrudePoint, scale);

			const b:Bitmap = new Bitmap(source);
			b.scaleX = b.scaleY = scale;
			loader.unload();

			b.smoothing = true;
			b.visible = false;
			b.name = String(loaded); // store the ID as 'name'
			cont.addChild(b);
			bmp[bmp.length] = b;
			log("* loaded: " + files[loaded].nativePath.split(folderNativePathSEP).join("") + ": " + b.width + "x" + b.height + "px");

			if (b.width > maxDim || b.height > maxDim) {
				error("image is larger than the maximum dimensions for an atlas: " + maxDim + "px", true);
				return;
			}

			loadNextFile();
		}

		// rectangle sorting
		private function sortBitmapsInContainer():void
		{
			startTime = getTimer();

			var total:uint = bmp.length;
			var i:uint;
			dimW = dimH = minDim;
			dimError = false;

			log("*\n* sorting " + total + " bitmaps...");

			if (!packer)
				packer = new RectanglePacker(dimW, dimH, padding);

			while (true) {
				// reset the packer
				packer.reset(dimW, dimH, padding);

				// insert rectangles
				for (i = 0; i < total; i++) {
					const b:Bitmap = bmp[i];
					packer.insertRectangle(b.width, b.height, i);
				}

				// pack
				packer.packRectangles(true);

				// all rectangles are packed; break
				if (packer.rectangleCount == total) {
					break;
				// if already the maximum dimensions break with an error
				} else if (dimW == maxDim && dimH == maxDim) {
					dimError = true;
					break;
				}

				// increment the dimensions
				if (usePowerOfTwo) {
					if (useSquare) {
						dimW <<= 1;
						dimH = dimW;
					} else {
						if (dimW < maxDim)
							dimW <<= 1;
						if (dimH < maxDim)
							dimH <<= 2;
					}
				} else {
					if (useSquare) {
						dimW += 1;
						dimH = dimW;
					} else {
						if (dimW < maxDim)
							dimW += 1;
						if (dimH < maxDim)
							dimH += 2;
					}
				}

				// clamp to the maximum dimensions
				if (dimW > maxDim)
					dimW = maxDim;
				if (dimH > maxDim)
					dimH = maxDim;
			}

			// adjust x, y of the packed bitmaps and show them
			const rect:Rectangle = new Rectangle();
			total = packer.rectangleCount;
			for (i = 0; i < total; i++) {
				packer.getRectangle(i, rect);
				const id:uint = packer.getRectangleId(i);
				bmp[id].visible = true;
				bmp[id].x = rect.x;
				bmp[id].y = rect.y;
			}

			log("* final dimensions: " + dimW + "x" + dimH + "px");
			log("* done sorting in " + (getTimer() - startTime) + " ms");

			const noExt:String = outFile.nativePath.substring(0, outFile.nativePath.lastIndexOf("."));
			const partFile:File = currentDir.resolvePath(noExt + "_part" + currentPart + EXT_PNG);

			if (dimError) {
				const message:String = "dimensions exceed the maximum of " + maxDim + "px";
				if (useMultipart) {
					warning(message + ". multipart...");
				} else {
					error(message + ". enable -multipart", true);
					return;
				}

				/* move all bitmaps that remain hidden to 'bmpRemaining'
				 * while shortening the list of bitmaps to be rendered - 'bmp'.
				 */
				bmpRemaining.length = 0;
				total = bmp.length;
				i = 0;
				do {
					if (!bmp[i].visible) {
						bmpRemaining[bmpRemaining.length] = bmp[i];
						bmp.splice(i, 1);
						total--;
						continue;
					}
					i++;
				} while (i < total);

				// save files while processing 'bmp'
				saveFiles(partFile);

				// move bitmaps from 'bmpRemaining' to 'bmp' while hiding them
				bmp.length = 0;
				total = bmpRemaining.length;
				for (i = 0; i < total; i++) {
					bmp[i] = bmpRemaining[i];
					bmp[i].visible = false;
				}

				// increment the current part and recurse
				currentPart++;
				sortBitmapsInContainer();

			} else {
				saveFiles((currentPart > 0) ? partFile : outFile);

				log("* whole operation performed in " + (getTimer() - initialTime) + " ms");

				if (!hasGUI)
					exit();
				return;
			}
		}

		// save the PNG, XML pair
		private function saveFiles(_outFile:File):void
		{
			// rendering...
			log("* rendering...");
			startTime = getTimer();

			// draw object to BitmapData
			var bmd:BitmapData;

			// if the first byte of the background color is 0xFF the image is opaque
			const isTransparent:Boolean = !((background >>> 24) == 0xFF);

			var m:Matrix = new Matrix();
//			m.scale(scale, scale);

			// quantize
			if (channelBits[0] + channelBits[1] + channelBits[2] + channelBits[3] < 32) {
				bmd = new BitmapData(dimW, dimH, true, 0x0);
//				bmd = new BitmapData(dimW * scale, dimH * scale, true, 0x0);
				bmd.draw(cont, m);

				quantize(bmd);

				const back:BitmapData = new BitmapData(dimW, dimH, isTransparent, background);
//				const back:BitmapData = new BitmapData(dimW * scale, dimH * scale, isTransparent, background);
				back.copyPixels(bmd, back.rect, new Point(0, 0), null, null, true);
				bmd.dispose();
				bmd = back;
			} else {
				bmd = new BitmapData(dimW, dimH, isTransparent, background);
//				bmd = new BitmapData(dimW * scale, dimH * scale, isTransparent, background);
				bmd.draw(cont, m);
			}

			log("* done rendering in " + (getTimer() - startTime) + " ms");

			// saving...
			log("* saving...");
			startTime = getTimer();

			// encode PNG
			const ba:ByteArray = encodePNG(bmd);
			bmd.dispose();

			var pos:uint;

			// save PNG
			stream.open(_outFile, FileMode.WRITE);
			stream.writeBytes(ba);
			pos = stream.position;
			stream.close();

			log("* file saved (" + pos + " bytes): " + _outFile.nativePath);

			// save XML
			var pngFile:String = _outFile.nativePath;
			pngFile = pngFile.substring(pngFile.lastIndexOf(FILE_SEP) + 1, pngFile.length);
			const xml:String = getXMLStarling(pngFile);
			const xmlPath:String = _outFile.nativePath.split(EXT_PNG).join(EXT_XML);
			_outFile = _outFile.resolvePath(xmlPath);

			stream.open(_outFile, FileMode.WRITE);
			stream.writeUTFBytes(xml);
			pos = stream.position;
			stream.close();

			log("* file saved (" + pos + " bytes): " + _outFile.nativePath);
			log("* done saving in " + (getTimer() - startTime) + " ms");
		}

		private function encodePNG(_bmd:BitmapData):ByteArray
		{
			var opt:PNGEncoderOptions;
			var ba:ByteArray;
			const versionMajor:uint = uint(NativeApplication.nativeApplication.runtimeVersion.split(".")[0]);

			if (versionMajor < 17 && pngEncoder > 2) {
				if (pngEncoder == ENC_PNGENCODER2_FAST)
					pngEncoder = ENC_BITMAPDATA_ENCODE_FAST;
				else
					pngEncoder = ENC_PNGENCODER_AS;
				warning("runtime is version " + versionMajor + ". defaulting to encoder " + pngEncoder + "!");
			}

			switch (pngEncoder)	{
			case ENC_PNGENCODER_AS:
				ba = PNGEncoder.encode(_bmd);
				break;
			case ENC_BITMAPDATA_ENCODE:
				pngEncoderOptions.fastCompression = false;
				ba = _bmd.encode(_bmd.rect, pngEncoderOptions);
				break;
			case ENC_BITMAPDATA_ENCODE_FAST:
				pngEncoderOptions.fastCompression = true;
				ba = _bmd.encode(_bmd.rect, pngEncoderOptions);
				break;
			case ENC_PNGENCODER2_FAST:
				PNGEncoder2.level = CompressionLevel.FAST;
				ba = PNGEncoder2.encode(_bmd);
				break;
			case ENC_PNGENCODER2_NORMAL:
				PNGEncoder2.level = CompressionLevel.NORMAL;
				ba = PNGEncoder2.encode(_bmd);
				break;
			case ENC_PNGENCODER2_GOOD:
				PNGEncoder2.level = CompressionLevel.GOOD;
				ba = PNGEncoder2.encode(_bmd);
				break;
			}

			if (!ba)
				throw Error("encodePNG() failed!");
			return ba;
		}

		// quantize bitmap data
		private function quantize(_bmd:BitmapData):void
		{
			log("* quantizing with " + QUANT_LIST[quantizer]);

			switch (quantizer) {
			case QUANT_POSTERIZE_FAST:
				BitmapDataQuantize.quantize(_bmd, channelBits);
				break;
			case QUANT_FLOYD_STEINBERG:
				BitmapDataQuantize.quantizeFloydSteinberg(_bmd, channelBits);
				break;
			case QUANT_NOISE_SHAPING:
				BitmapDataQuantize.quantizeNoiseShaping(_bmd, channelBits);
				break;
			}
		}

		// make a list out off an input vector
		private function enumerateList(_vec:Vector.<String>):String
		{
			var str:String = "";
			const len:uint = _vec.length;

			for (var i:uint = 0; i < len; i++)
				str += "\n" + i.toString() + ": " + _vec[i];

			return str;
		}

		// generate the XML string
		private function getXMLStarling(_png:String):String
		{
			const ext2:uint = extrude << 1;
			const len:uint = bmp.length;
			var xml:String = "";
			xml += "<?xml version='1.0' encoding='utf-8'?>\n";
			xml += "<!-- generated with " + TITLE + " -->\n";
			xml += "<TextureAtlas imagePath='" + pngPrefix + _png + "'>\n";

			for (var i:uint = 0; i < len; i++)  {

				const b:Bitmap = bmp[i];
				const fileID:uint = uint(b.name); // the file ID is stored in the Bitmap name
				b.visible = false; // hiding the bitmap since we no longer need it

				var bName:String = files[fileID].nativePath.split(folderNativePathSEP).join(""); // remove the native path
				bName = bName.split(FILE_SEP).join("/"); // translate all remaining path seperators to "/"

				// extract properties
				const bX:String = (b.x + extrude).toString();
				const bY:String = (b.y + extrude).toString();
				const bW:String = (b.width - ext2).toString();
				const bH:String = (b.height - ext2).toString();

				// form SubTexture
				xml += "	<SubTexture name='" + subPrefix + bName + "' x='" + bX + "' y='" + bY + "' width='" + bW + "' height='" + bH + "'/>\n"
			}
			xml += "</TextureAtlas>\n";
			return xml;
		}
	}
}
