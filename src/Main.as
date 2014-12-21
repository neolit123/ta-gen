/**
 * ta-gen v1.0
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

	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.InvokeEvent;

	import flash.utils.ByteArray;
	import flash.utils.getTimer;

	import com.adobe.images.PNGEncoder;
	import org.villekoskela.utils.RectanglePacker;

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
		private var verbose:Boolean = false;
		private var dimW:uint, dimH:uint;
		private var dimError:Boolean = false;
		private var background:uint = 0x0;

		// files and lists
		private var folder:File = null;
		private var outFile:File = null;
		private var ignore:Array = [];
		private var files:Array = [];

		// UI
		private var cont:Sprite = new Sprite();
		private var contBorder:Shape = new Shape();
		private var msk:Sprite = new Sprite();
		private var textLog:TextField = new TextField();

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
		private static const VERSION:String = "1.0";
		private static const TITLE:String = "ta-gen v" + VERSION;
		private static const HELP_TEXT:String =
<![CDATA[Copyright 2014 and later, Lubomir I. Ivanov. All rights reserved.

RectanglePacker
Copyright 2012, Ville Koskela. All rights reserved.

PNGEncoder
Copyright 2008, Adobe Systems Incorporated. All rights reserved.

usage:
adl <app-xml> -- arguments
	-path <path-to-load>
	-out <output-png>
	-pngprefix <png-name-prefix>
	-subprefix <texture-name-prefix>
	-mindim <minimum-pixels> (def: 32)
	-maxdim <maximum-pixels> (def: 2048)
	-ignore <some-path-or-file> -ignore <...> ... (no wildcards)
	-background <0xAARRGGBB> (def. 0x0)
	-padding <padding-between-images> (def: 1)
	-poweroftwo: end dimensions will be a power of 2 square
	-verbose: detailed output
	-help: this screen
]]>;

		public function Main():void
		{
			initialTime = 0;

			// add the invoke handler
			NativeApplication.nativeApplication.addEventListener(InvokeEvent.INVOKE, invokeEventHandler);

			// the main container where images will be stored
			addChild(cont);

			// a visual border
			contBorder.graphics.lineStyle(0.0, 0x00ff00);
			contBorder.graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
			addChild(contBorder);

			// a click mask
			msk.graphics.beginFill(0x00ff00);
			msk.graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
			msk.graphics.endFill();
			msk.alpha = 0.0;
			addChild(msk);
			msk.addEventListener(MouseEvent.CLICK, clickHandler);

			// a textfield to write the log to
			textLog.border = true;
			textLog.background = true;
			textLog.multiline = true;
			textLog.wordWrap = true;
			textLog.width = stage.stageWidth;
			textLog.height = stage.stageHeight / 4;
			textLog.y = stage.stageHeight - textLog.height;
			textLog.defaultTextFormat = new TextFormat("_typewriter");
			addChild(textLog);

			// add listener to the loader
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loadCompleteHandler);
		}

		// called each time the app starts
		public function invokeEventHandler(_e:InvokeEvent):void
		{
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
					NativeApplication.nativeApplication.exit();
					return;
				}
				const len:int = args.length;
				for (var i:int = 0; i < len; i++) {
					const carg:String = args[i];
					// one part arguments
					if (carg == "-poweroftwo") {
						usePowerOfTwo = true;
						log("* argument -poweroftwo: " + usePowerOfTwo);
					}
					if (i == len - 1) // bellow are two-part arguments
						break;
					const narg:String = args[i + 1];
					if (carg == "-path") {
						folder = currentDir.resolvePath(narg);
						log("* argument -path: " + folder.nativePath);
						if (!folder.exists || !folder.isDirectory) {
							log("* ERROR: path does not exist");
							NativeApplication.nativeApplication.exit();
							return;
						}
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
					}
				}

				if (!minDim || !maxDim) {
					log("* ERROR: mindim or maxdim cannot be zero");
					NativeApplication.nativeApplication.exit();
					return;
				}

				if (minDim > maxDim) {
					log("* ERROR: mindim cannot be larger than maxdim");
					NativeApplication.nativeApplication.exit();
					return;
				}

				if (usePowerOfTwo) {
					if (!isPowerOfTwo(minDim)) {
						minDim = toPowerOfTwo(minDim);
						log("* WARNING: adjusting mindim to the nearest power of two: " + minDim);
					}
					if (!isPowerOfTwo(maxDim)) {
						maxDim = toPowerOfTwo(maxDim);
						log("* WARNING: adjusting maxdim to the nearest power of two: " + maxDim);
					}
				}

				if (folder) {
					processFolder(folder);
					return;
				}
			}

			// show open dialog
			log("* click above to select a folder");
			folder = new File();
			folder.addEventListener(Event.SELECT, browseSelectHandler);
			folder.browseForDirectory("Select folder");
		}

		private function isPowerOfTwo(_x:uint):Boolean
		{
			return (_x & (_x - 1)) == 0;
		}

		private function toPowerOfTwo(_x:uint):uint
		{
			return  Math.pow(2, Math.round(Math.log(_x) / Math.LN2));
		}

		private function log(...arg):void
		{
			if (verbose)
				trace.apply(null, arg);
			textLog.appendText(arg.toString() + "\n");
			textLog.scrollV = textLog.maxScrollV;
		}

		private function browseSelectHandler(_e:Event):void
		{
			processFolder(folder);
		}

		// process folder
		private function processFolder(_folder:File):void
		{
			log("* target path is: " + _folder.nativePath);
			traverse(_folder);
			if (files.length) {
				urlRequest.url = files[0];
				startTime = getTimer();
				log("* loading " + files.length + " files...");
				loader.load(urlRequest);
			} else {
				log("* nothing to load!");
			}
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
				// LAZY;
				if (path.toLowerCase().indexOf(".jpg") != -1 ||
				    path.toLowerCase().indexOf(".png") != -1 ||
				    path.toLowerCase().indexOf(".gif") != -1)
				    files.push(path);
			}
		}

		// called each time the loader loads an image
		private function loadCompleteHandler(_e:Event):void
		{
			const b:Bitmap = new Bitmap((loader.content as Bitmap).bitmapData);
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
				// FIXME; reset() doesn't work well! possible bug in RectanglePacker
				packer = new RectanglePacker(dimW, dimH, padding);

				// insert rectangles
				for (i = 0; i < total; i++)
					packer.insertRectangle(bmp[i].width, bmp[i].height, i);

				// error checking for dimensions
				if (dimW > maxDim || dimH > maxDim) {
					dimError = true;
					log("* ERROR: dimensions exceed the maximum of " + maxDim + " pixels");
					if (outFile) {
						NativeApplication.nativeApplication.exit();
						return;
					}
				}

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
			const sX:Number = stage.stageWidth / dimW;
			const sY:Number = (stage.stageHeight - textLog.height) / dimH;
			const sMin:Number = Math.min(sX, sY) * 0.999;
			contBorder.width = dimW * sMin;
			contBorder.height = dimH * sMin;
			cont.scaleY = cont.scaleX = sMin;

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
			// saving...
			log("* saving...");
			startTime = getTimer();

			// draw object to BitmapData
			const scale:Number = cont.scaleY;
			cont.scaleX = cont.scaleY = 1.0;
			const bmd:BitmapData = new BitmapData(dimW, dimW, true, background);
			bmd.draw(cont);
			cont.scaleX = cont.scaleY = scale;
			const ba:ByteArray = PNGEncoder.encode(bmd);

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
				NativeApplication.nativeApplication.exit();
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
				const bX:String = bmp[i].x.toString();
				const bY:String = bmp[i].y.toString();
				const bW:String = bmp[i].width.toString();
				const bH:String = bmp[i].height.toString();
				xml += "	<SubTexture name='" + subPrefix + bName + "' x='" + bX + "' y='" + bY + "' width='" + bW + "' height='" + bH + "'/>\n"
			}
			xml += "</TextureAtlas>\n";
			return xml;
		}
	}
}
