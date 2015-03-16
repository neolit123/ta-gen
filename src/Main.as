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

	import com.adobe.images.PNGEncoder;
	import org.villekoskela.utils.RectanglePacker;
	import neolit123.utils.BitmapDataQuantize;
	import neolit123.utils.BitmapDataExtrude;

	[SWF(width='512', height='512', backgroundColor='#ffffff', frameRate='30')]

	public class Main extends Sprite
	{
		// argument list
		private var args:Array;
		private var currentDir:File;

		// params and default values
		private var padding:uint = 1;
		private var maxDim:uint = 2048;
		private var minDim:uint = 32;
		private var pngPrefix:String = "";
		private var subPrefix:String = "";
		private var usePowerOfTwo:Boolean = false;
		private var useDither:Boolean = false;
		private var colorBits:uint = 8;
		private var verbose:Boolean = false;
		private var dimW:uint, dimH:uint;
		private var dimError:Boolean = false;
		private var background:uint = 0x0;
		private var extrude:uint = 0;
		private var hasGUI:Boolean = false;

		// files and lists
		private var outFile:File = null;
		private var folder:File = null;
		private var folders:Vector.<File> = new Vector.<File>();
		private var ignore:Vector.<File> = new Vector.<File>();
		private var files:Vector.<String> = new Vector.<String>();

		// UI
		private var cont:Sprite;
		private var contBorder:Shape;
		private var msk:Sprite;
		private var textLog:TextField;

		// loader
		private var loader:Loader = new Loader();
		private var urlRequest:URLRequest = new URLRequest();
		private var bmp:Vector.<Bitmap> = new Vector.<Bitmap>();
		private var loaded:uint = 0;

		/// timers
		private var startTime:uint;
		private var initialTime:uint;

		// packer
		private var packer:RectanglePacker;

		// static consts
		private static const VERSION:String = "1.2";
		private static const TITLE:String = "ta-gen v" + VERSION;
		private static const HELP_TEXT:String = TITLE + <![CDATA[

Copyright 2014 and later, Lubomir I. Ivanov. All rights reserved.

RectanglePacker
Copyright 2012, Ville Koskela. All rights reserved.

PNGEncoder
Copyright 2008, Adobe Systems Incorporated. All rights reserved.

usage:
adl <app-xml> -- arguments
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
			var i:int;
			args = _e.arguments;
			currentDir = _e.currentDirectory;

			// parse command line
			if (args.length) {
				var vidx:int = args.indexOf("-verbose");
				if (vidx != -1)
					verbose = true;

				// show title
				log(TITLE);

				// help
				if (args[0] == "-help") {
					verbose = true;
					log(HELP_TEXT);
					exit();
					return;
				}
				const len:int = args.length;
				for (i = 0; i < len; i++) {
					const carg:String = args[i];
					// one part arguments
					if (carg == "-poweroftwo") {
						usePowerOfTwo = true;
						log("* argument -poweroftwo");
					} else if (carg == "-dither") {
						useDither = true;
						log("* argument -dither");
					} else if (carg == "-gui") {
						hasGUI = true;
						createGUI();
						log("* argument -gui");
					}
					if (i == len - 1) // bellow are two-part arguments
						break;
					const narg:String = args[i + 1];
					if (carg == "-in") {
						folder = currentDir.resolvePath(narg);
						log("* argument -in: " + folder.nativePath);
						if (!folder.exists || !folder.isDirectory) {
							error("input path not a directory or does not exist");
							return;
						}
						folders.push(folder);
					} else if (carg == "-out") {
						outFile = currentDir.resolvePath(narg);
						log("* argument -out: " + outFile.nativePath);
					} else if (carg == "-pngprefix") {
						pngPrefix = args[i + 1];
						log("* argument -pngprefix: " + pngPrefix);
					} else if (carg == "-subprefix") {
						subPrefix = narg;
						log("* argument -subprefix: " + subPrefix);
					} else if (carg == "-mindim") {
						minDim = uint(narg);
						log("* argument -mindim: " + minDim);
					} else if (carg == "-maxdim") {
						maxDim = uint(narg);
						log("* argument -maxdim: " + maxDim);
					} else if (carg == "-background") {
						background = uint(narg);
						log("* argument -background: " + narg);
					} else if (carg == "-padding") {
						padding = uint(narg);
						log("* argument -padding: " + padding);
					} else if (carg == "-ignore") {
						const ignorePath:File = currentDir.resolvePath(narg);
						log("* argument -ignore: " + ignorePath.nativePath);
						ignore.push(ignorePath);
					} else if (carg == "-colorbits") {
						colorBits = uint(narg);
						colorBits < 1 ? 1 : (colorBits > 8 ? 8 : colorBits);
						log("* argument -colorbits: " + colorBits);
					} else if (carg == "-extrude") {
						extrude = uint(narg);
						log("* argument -extrude: " + extrude);
					}
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
					error("output PNG not set", true);

				if (folders.length) {
					for (i = 0; i < folders.length; i++)
						traverse(folders[i]);
					processFolders();
					return;
				} else {
					if (!hasGUI)
						error("missing input", true);
				}
			}

			if (hasGUI) {
				// show open dialog
				log("* click above to select a folder");
				folder = new File();
				folder.addEventListener(Event.SELECT, browseSelectHandler);
				folder.browseForDirectory("Select folder");
			}
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

		// process folder
		private function processFolders():void
		{
			if (files.length) {
				urlRequest.url = files[0];
				startTime = getTimer();
				log("* loading " + files.length + " files...");
				log("* each image will be extruded by " + extrude + " pixels");
				loader.load(urlRequest);
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

			if (err is Error)
				 msg += error.getStackTrace();
			else if (err is ErrorEvent)
				 msg += err.text;
			else
				 msg += err.toString();

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
					files.push(path);
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
			bmp.push(b);
			log("* loaded: " + files[loaded].split(folder.nativePath + File.separator).join("") + ": " + b.width + "x" + b.height);
		    loaded++;
		    if (loaded < files.length) {
		    	urlRequest.url = files[loaded];
		    	loader.load(urlRequest);
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

			// quantize
			if (colorBits < 8) {
				bmd = new BitmapData(dimW, dimW, true, 0x0);
				bmd.draw(cont);

				const levels:uint = BitmapDataQuantize.bitsToLevels(colorBits);
				if (useDither) {
					log("* quantizing with floyd-steinberg...");
					BitmapDataQuantize.quantizeFloydSteinberg(bmd, levels);
				} else {
					log("* quantizing...");
					BitmapDataQuantize.quantize(bmd, levels);
				}
				const back:BitmapData = new BitmapData(dimW, dimW, true, background);
				back.copyPixels(bmd, back.rect, new Point(0, 0), null, null, true);
				bmd.dispose();
				bmd = back;
			} else {
				bmd = new BitmapData(dimW, dimW, true, background);
				bmd.draw(cont);
			}
			cont.scaleX = cont.scaleY = scale;

			log("* done rendering in " + (getTimer() - startTime) + " ms");

			// saving...
			log("* saving...");
			startTime = getTimer();
			const ba:ByteArray = PNGEncoder.encode(bmd);
			bmd.dispose();

			var stream:FileStream;

			// save png
			const PNG:String = ".png";
			const pathLowerCase:String = _outFile.nativePath.toLowerCase();
			if (pathLowerCase.indexOf(PNG) == -1)
				_outFile = _outFile.resolvePath(_outFile.nativePath + PNG);

			stream = new FileStream();
			stream.open(_outFile, FileMode.WRITE);
			stream.writeBytes(ba);
			stream.close();

			log("* file saved: " + _outFile.nativePath);

			// save XML
			var pngFile:String = _outFile.nativePath;
			pngFile = pngFile.substring(pngFile.lastIndexOf(File.separator) + 1, pngFile.length);
			const xml:String = getXMLStarling(pngFile);
			const xmlPath:String = _outFile.nativePath.split(PNG).join(".xml");
			_outFile = _outFile.resolvePath(xmlPath);

			stream = new FileStream();
			stream.open(_outFile, FileMode.WRITE);
			stream.writeUTFBytes(xml);
			stream.close();

			log("* file saved: " + _outFile.nativePath);
			log("* done saving in " + (getTimer() - startTime) + " ms");

			if (outFile) {
				log("* whole operation performed in " + (getTimer() - initialTime) + " ms");
				exit();
			}
		}

		// generate the XML string
		private function getXMLStarling(_png:String):String
		{
			var xml:String = "";
			xml += "<?xml version='1.0' encoding='utf-8'?>\n";
			xml += "<TextureAtlas imagePath='" + pngPrefix + _png + "'>\n";
			const len:int = bmp.length;
			for (var i:int = 0; i < len; i++)  {
				var bName:String = files[i].split(folder.nativePath + File.separator).join("");
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
