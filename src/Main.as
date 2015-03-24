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

	import flash.net.URLRequest;

	import flash.display.Sprite;
	import flash.display.Shape;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.PNGEncoderOptions

	import flash.text.TextField;
	import flash.text.TextFormat;

	import flash.geom.Rectangle;
	import flash.geom.Point;

	import flash.events.Event;
	import flash.events.MouseEvent;
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

	[SWF(width='512', height='512', backgroundColor='#ffffff', frameRate='60')]

	public class Main extends Sprite
	{
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
		private var quantizer:uint = QUANT_FLOYD_STEINBERG;

		// files and lists
		private var outFile:File = null;
		private var folder:File = null;
		private var folders:Vector.<File> = new <File>[];
		private var ignore:Vector.<File> = new <File>[];
		private var files:Vector.<File> = new <File>[];

		// UI
		private var cont:Sprite;
		private var contBorder:Shape;
		private var msk:Sprite;
		private var textLog:TextField;

		// loader
		private var loader:Loader = new Loader();
		private var urlRequest:URLRequest = new URLRequest();
		private var bmp:Vector.<Bitmap> = new <Bitmap>[];
		private var loaded:uint = 0;

		/// timers
		private var startTime:uint;
		private var initialTime:uint;

		// packer
		private var packer:RectanglePacker;

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

		// encoders
		private static const QUANT_POSTERIZE_FAST:uint = 0;
		private static const QUANT_FLOYD_STEINBERG:uint = 1;
		private static const QUANT_NOISE_SHAPING:uint = 2;

		private static const QUANT_LIST:Vector.<String> = new <String>[
			"QUANT_POSTERIZE_FAST",
			"QUANT_FLOYD_STEINBERG",
			"QUANT_NOISE_SHAPING"
		];

		// version and title
		private static const VERSION:String = "1.4";
		private static const TITLE:String = "ta-gen v" + VERSION;
		private static const HELP_TEXT:String = TITLE + <![CDATA[

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
  -background <0xAARRGGBB> (def. 0x0)
  -padding <padding-between-images> (def: 1)
  -poweroftwo: end dimensions will be a power of 2 square
  -channelbits <ARGB> (def. 8888): less than 8 per channel means quantization
  -quantizer <0-2> (def. 1): see -listquantizers
  -listquantizers: dump the quantizer list
  -extrude <pixels> (def. 0): extrude the edges of each image
  -gui: enable a simple user interface
  -pngencoder <0-5> (def: 0): see -listpngencoders
  -listpngencoders: dump the PNG encoder list
  -verbose: detailed output
  -help: this screen
]]>;

		public function Main():void
		{
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
			const args:Array = _e.arguments;
			const currentDir:File = _e.currentDirectory;
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
					if (carg == "-poweroftwo") {
						usePowerOfTwo = true;
						logArgument(carg);
						continue;
					} else if (carg == "-gui") {
						hasGUI = true;
						createGUI();
						logArgument(carg);
						continue;
					} else if (carg == "-verbose") {
						logArgument(carg);
						continue; // already handled
					}

					var iPrev:int = i; // store current index

					if (i < argLen - 1) { // bellow are two-part arguments

						const narg:String = args[i + 1];

						if (carg == "-in") {
							folder = currentDir.resolvePath(narg);
							i++;
							logArgument(carg, folder.nativePath);
							if (!folder.exists || !folder.isDirectory) {
								error("input path not a directory or does not exist", true);
								return;
							}
							folders[folders.length] = folder;
						} else if (carg == "-out") {
							outFile = currentDir.resolvePath(narg);
							logArgument(carg, outFile.nativePath);
							i++;
						} else if (carg == "-pngprefix") {
							pngPrefix = narg;
							logArgument(carg, pngPrefix);
							i++;
						} else if (carg == "-subprefix") {
							subPrefix = narg;
							logArgument(carg, subPrefix);
							i++;
						} else if (carg == "-mindim") {
							minDim = uint(narg);
							logArgument(carg, minDim);
							i++;
						} else if (carg == "-maxdim") {
							maxDim = uint(narg);
							logArgument(carg, maxDim);
							i++;
						} else if (carg == "-background") {
							background = uint(narg);
							logArgument(carg, background.toString(16).toUpperCase());
							i++;
						} else if (carg == "-padding") {
							padding = uint(narg);
							logArgument(carg, padding);
							i++;
						} else if (carg == "-ignore") {
							const ignorePath:File = currentDir.resolvePath(narg);
							logArgument(carg, ignorePath.nativePath);
							ignore[ignore.length] = ignorePath;
							i++;
						} else if (carg == "-channelbits") {
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
						} else if (carg == "-extrude") {
							extrude = uint(narg);
							logArgument(carg, extrude);
							i++;
						} else if (carg == "-pngencoder") {
							pngEncoder = uint(narg);
							if (pngEncoder > ENC_LIST.length - 1) {
								warning("bad PNG encoder. setting the default one.");
								pngEncoder = ENC_PNGENCODER_AS;
							}
							logArgument(carg, ENC_LIST[pngEncoder]);
							i++;
						} else if (carg == "-quantizer") {
							quantizer = uint(narg);
							if (quantizer > QUANT_LIST.length - 1) {
								warning("bad quantizer. setting the default one.");
								quantizer = QUANT_FLOYD_STEINBERG;
							}
							logArgument(carg, QUANT_LIST[quantizer]);
							i++;
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
				log("* click above to select a folder");
				folder = new File();
				folder.addEventListener(Event.SELECT, browseSelectHandler);
				folder.browseForDirectory("Select folder");
			}
		}

		private function logArgument(_arg:String, _val:* = null):void
		{
			log("* argument " + _arg + (_val ? (": " + _val.toString()) : ""));
		}

		private function createGUI():void
		{
			NativeApplication.nativeApplication.openedWindows[0].visible = true;

			// add the main container
			addChild(cont);

			// a visual border
			contBorder = new Shape();
			contBorder.graphics.lineStyle(0.0, 0x00ff00);
			contBorder.graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
			contBorder.graphics.endFill();
			addChild(contBorder);

			// a click mask
			msk = new Sprite();
			msk.graphics.beginFill(0x00ff00);
			msk.graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
			msk.graphics.endFill();
			msk.alpha = 0.0;
			addChild(msk);
			msk.addEventListener(MouseEvent.CLICK, clickHandler);

			// a textfield to write the log to
			textLog = new TextField();
			textLog.border = true;
			textLog.background = true;
			textLog.multiline = true;
			textLog.wordWrap = true;
			textLog.width = stage.stageWidth;
			textLog.height = stage.stageHeight / 4;
			textLog.y = stage.stageHeight - textLog.height;
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

		private function browseSelectHandler(_e:Event):void
		{
			traverse(folder);
			processFolders();
		}

		private const loadFileBA:ByteArray = new ByteArray();
		private const loadFileFS:FileStream = new FileStream();
		private var filesLength:uint;

		private function loadFile(_file:File):void
		{
			loadFileBA.clear();
			loadFileFS.open(_file, FileMode.READ);
			loadFileFS.readBytes(loadFileBA);
			loadFileFS.close();
			loader.loadBytes(loadFileBA);
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
				if (checkPathIgnore(list[i])) {
					continue;
				}
				if (list[i].isDirectory) {
					traverse(list[i]);
					continue;
				}
				const path:String = list[i].nativePath;
				const lcPath:String = path.toLowerCase();
				if (lcPath.indexOf(".jpeg") == lcPath.length - 5 ||
				    lcPath.indexOf(".jpg") == lcPath.length - 4 ||
				    lcPath.indexOf(".png") == lcPath.length - 4 ||
				    lcPath.indexOf(".gif") == lcPath.length - 4)
					files[files.length] = list[i];
			}
		}

		private const extrudeRect:Rectangle = new Rectangle(0, 0, 0, 0);
		private const extrudePoint:Point = new Point(0, 0);

		// called each time the loader loads an image
		private function loadCompleteHandler(_e:Event):void
		{
			var source:BitmapData = (loader.content as Bitmap).bitmapData;

			// perform extrusion if 'extrude' is more than 0
			if (extrude)
				source = BitmapDataExtrude.extrude(source, extrude, true, extrudeRect, extrudePoint);

			const b:Bitmap = new Bitmap(source);
			loader.unload();
			b.smoothing = true;
			cont.addChild(b);
			bmp[bmp.length] = b;
			log("* loaded: " + files[loaded].nativePath.split(folder.nativePath + File.separator).join("") + ": " + b.width + "x" + b.height);

			loaded++;
			if (loaded < filesLength) {
				loadFile(files[loaded]);
			} else {
				log("* done loading in " + (getTimer() - startTime) + " ms");
				sortBitmapsInContainer();
			}
		}

		// rectangle sorting
		private function sortBitmapsInContainer():void
		{
			log("* sorting...");
			startTime = getTimer();
			var i:int;

			dimW = dimH = minDim;
			const total:int = bmp.length;
			const increment:uint = 2;
			dimError = false;

			while (true) {
				// error checking for dimensions
				if (dimW > maxDim || dimH > maxDim) {
					dimError = true;
					error("dimensions exceed the maximum of " + maxDim + " pixels", false);
					if (outFile) {
						exit();
						return;
					}
					break;
				}

				// FIXME; reset() doesn't work well! possible bug in RectanglePacker
				packer = new RectanglePacker(dimW, dimH, padding);

				// insert rectangles
				for (i = 0; i < total; i++)
					packer.insertRectangle(bmp[i].width, bmp[i].height, i);

				// pack
				packer.packRectangles(true);

				// all rectangles are packed; break
				if (packer.rectangleCount == total)
					break;

				// increment the size
				if (usePowerOfTwo) {
					dimW <<= 1;
					dimH = dimW;
				} else {
					if (dimH < dimW)
						dimH += increment;
					else
						dimW += increment;
				}

				// FIXME; reset() doesn't work well! possible bug in RectanglePacker
				// packer.reset(dimW, dimH, padding);
			}

			var rect:Rectangle = new Rectangle();
			for (i = 0; i < total; i++) {
				packer.getRectangle(i, rect);
				const id:uint = packer.getRectangleId(i);
				bmp[id].x = rect.x;
				bmp[id].y = rect.y;
			}

			if (!dimError) {
				log("* final dimensions: " + dimW + "x" + dimH);
				log("* done sorting in " + (getTimer() - startTime) + " ms");
			}

			// scale the container and border visually
			if (hasGUI) {
				const sX:Number = stage.stageWidth / dimW;
				const sY:Number = (stage.stageHeight - textLog.height) / dimH;
				const sMin:Number = Math.min(sX, sY) * 0.999;
				contBorder.width = dimW * sMin;
				contBorder.height = dimH * sMin;
				cont.scaleY = cont.scaleX = sMin;
			}

			if (outFile) {
				saveFiles(outFile);
				return;
			}

			if (!dimError)
				log("* click above to save the image");
		}

		// when clicked on the sprite sheet
		private function clickHandler(_e:MouseEvent):void
		{
			if (files.length) {
				// save
				if (dimError)
					return;
				var file:File = new File();
				file.addEventListener(Event.SELECT, saveFilesHandler);
				file.browseForSave("Save image");
			} else {
				// show open dialog
				folder.addEventListener(Event.SELECT, browseSelectHandler);
				folder.browseForDirectory("Select folder");
			}
		}

		private function saveFilesHandler(_e:Event):void
		{
			saveFiles(_e.target as File);
		}

		// save the PNG, XML pair
		private function saveFiles(_outFile:File):void
		{
			// rendering...
			log("* rendering...");
			startTime = getTimer();

			// draw object to BitmapData
			const scale:Number = cont.scaleY;
			cont.scaleX = cont.scaleY = 1.0;
			var bmd:BitmapData;

			// if the first byte of the background color is 0xFF the image is opaque
			const isTransparent:Boolean = !((background >>> 24) == 0xFF);

			// quantize
			if (channelBits[0] + channelBits[1] + channelBits[2] + channelBits[3] < 32) {
				bmd = new BitmapData(dimW, dimW, true, 0x0);
				bmd.draw(cont);

				quantize(bmd);

				const back:BitmapData = new BitmapData(dimW, dimW, isTransparent, background);
				back.copyPixels(bmd, back.rect, new Point(0, 0), null, null, true);
				bmd.dispose();
				bmd = back;
			} else {
				bmd = new BitmapData(dimW, dimW, isTransparent, background);
				bmd.draw(cont);
			}
			cont.scaleX = cont.scaleY = scale;

			log("* done rendering in " + (getTimer() - startTime) + " ms");

			// saving...
			log("* saving...");
			startTime = getTimer();

			// encode PNG
			const ba:ByteArray = encodePNG(bmd);
			bmd.dispose();

			var stream:FileStream = new FileStream();
			var pos:uint;

			// save PNG
			const PNG:String = ".png";
			const pathLowerCase:String = _outFile.nativePath.toLowerCase();
			if (pathLowerCase.indexOf(PNG) == -1)
				_outFile = _outFile.resolvePath(_outFile.nativePath + PNG);

			stream.open(_outFile, FileMode.WRITE);
			stream.writeBytes(ba);
			pos = stream.position;
			stream.close();

			log("* file saved (" + pos + " bytes): " + _outFile.nativePath);

			// save XML
			var pngFile:String = _outFile.nativePath;
			pngFile = pngFile.substring(pngFile.lastIndexOf(File.separator) + 1, pngFile.length);
			const xml:String = getXMLStarling(pngFile);
			const xmlPath:String = _outFile.nativePath.split(PNG).join(".xml");
			_outFile = _outFile.resolvePath(xmlPath);

			stream.open(_outFile, FileMode.WRITE);
			stream.writeUTFBytes(xml);
			pos = stream.position;
			stream.close();

			log("* file saved (" + pos + " bytes): " + _outFile.nativePath);
			log("* done saving in " + (getTimer() - startTime) + " ms");

			if (outFile) {
				log("* whole operation performed in " + (getTimer() - initialTime) + " ms");
				exit();
			}
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
				log("* runtime is version " + versionMajor + ". defaulting to encoder " + pngEncoder + "!");
			}

			switch (pngEncoder)	{
			case ENC_PNGENCODER_AS:
				ba = PNGEncoder.encode(_bmd);
				break;
			case ENC_BITMAPDATA_ENCODE:
				opt = new PNGEncoderOptions();
				ba = _bmd.encode(_bmd.rect, opt);
				break;
			case ENC_BITMAPDATA_ENCODE_FAST:
				opt = new PNGEncoderOptions();
				opt.fastCompression = true;
				ba = _bmd.encode(_bmd.rect, opt);
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
			var xml:String = "";
			xml += "<?xml version='1.0' encoding='utf-8'?>\n";
			xml += "<TextureAtlas imagePath='" + pngPrefix + _png + "'>\n";
			const len:uint = bmp.length;
			for (var i:uint = 0; i < len; i++)  {
				var bName:String = files[i].nativePath.split(folder.nativePath + File.separator).join("");
				bName = bName.split(File.separator).join("/");
				const b:Bitmap = bmp[i];
				const ext2:uint = extrude * 2;
				const bX:String = (b.x + extrude).toString();
				const bY:String = (b.y + extrude).toString();
				const bW:String = (b.width - ext2).toString();
				const bH:String = (b.height - ext2).toString();
				xml += "	<SubTexture name='" + subPrefix + bName + "' x='" + bX + "' y='" + bY + "' width='" + bW + "' height='" + bH + "'/>\n"
			}
			xml += "</TextureAtlas>\n";
			return xml;
		}
	}
}
