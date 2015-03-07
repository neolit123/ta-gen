/**
 * BitmapDataQuantize
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

package neolit123.utils
{
	import flash.display.BitmapData;
	import flash.geom.Point;

	public class BitmapDataQuantize
	{
		private static const rVal:Array = new Array(256);
		private static const gVal:Array = new Array(256);
		private static const bVal:Array = new Array(256);
		private static const point:Point = new Point();

		private static const INV_255:Number = 1.0 / 255.0;

		// clamp levels to a max value
		private static function normalizeLevels(_levels:uint, _max:uint = 255):uint
		{
			if (_levels > _max)
				_levels = _max;
			return _max / _levels;
		}

		// convert bits to levels
		public static function bitsToLevels(_bits:uint):uint
		{
			return 1 << uint(_bits - 1);
		}

		// raw quantization / posterization
		public static function quantize(_bmd:BitmapData, _levels:uint):void
		{
			// normalize levels
			const norm:Number = normalizeLevels(_levels, 255);

			// create pallete
			for (var i:uint = 0; i < 256; i++) {
	            const v:uint = Math.round(Math.round((i * INV_255) * _levels) * norm);
	            rVal[i] = v << 16;
	            gVal[i] = v << 8;
	            bVal[i] = v;
            }

			// posterize
			_bmd.paletteMap(_bmd, _bmd.rect, point, rVal, gVal, bVal);
		}

		/* optimized version of Ralph Hauwert's Floyd Steinberg AS3.0 implementation:
		 * https://code.google.com/p/imageditheringas3/
		 */
		public static function quantizeFloydSteinberg(_bmd:BitmapData, _levels):void
		{
			// normalize levels
			const norm:Number = normalizeLevels(_levels, 255);

			//The FS kernel...note the 16th. Optimisation can still be done.
			const d1:Number = 7.0 / 16.0;
			const d2:Number = 3.0 / 16.0;
			const d3:Number = 5.0 / 16.0;
			const d4:Number = 1.0 / 16.0;

			// for each pixel in the bitmap
			const h:uint = _bmd.height;
			const w:uint = _bmd.width;

			for (var y:uint = 0; y < h; y++) {
				for (var x:uint = 0; x < w; x++) {

					// clobber variables
					var c:uint, nc:uint, lc:uint;
					var r:uint, g:uint, b:uint;
					var nr:uint, ng:uint, nb:uint;

					var er:int, eg:int, eb:int;
					var lr:int, lg:int, lb:int;

					// retrieve current RGB value.
					c = _bmd.getPixel(x, y);
					r = c >> 16 & 0xFF;
					g = c >> 8 & 0xFF;
					b = c & 0xFF;

					// normalize and scale to the number of _levels.
					// basically a cheap but suboptimal form of color quantization.
					nr = Math.round((r / 255) * _levels) * norm;
					ng = Math.round((g / 255) * _levels) * norm;
					nb = Math.round((b / 255) * _levels) * norm;

					// set the current pixel.
					nc = nr << 16 | ng << 8 | nb;
					_bmd.setPixel(x, y, nc);

					// quantization error.
					er = r - nr;
					eg = g - ng;
					eb = b - nb;

					// apply the kernel:
					// +1, 0
					lc = _bmd.getPixel(x + 1, y);
					lr = (lc >> 16 & 0xFF) + (d1 * er);
					lg = (lc >> 8 & 0xFF) + (d1 * eg);
					lb = (lc & 0xFF) + (d1 * eb);

					// clip & set
					lr = lr < 0 ? 0 : (lr > 255 ? 255 : lr);
					lg = lg < 0 ? 0 : (lg > 255 ? 255 : lg);
					lb = lb < 0 ? 0 : (lb > 255 ? 255 : lb);
					_bmd.setPixel(x + 1, y, lr << 16 | lg << 8 | lb);

					// -1, +1
					lc = _bmd.getPixel(x - 1, y + 1);
					lr = (lc >> 16 & 0xFF) + (d2 * er);
					lg = (lc >> 8 & 0xFF) + (d2 * eg);
					lb = (lc & 0xFF) + (d2 * eb);

					// clip & set
					lr = lr < 0 ? 0 : (lr > 255 ? 255 : lr);
					lg = lg < 0 ? 0 : (lg > 255 ? 255 : lg);
					lb = lb < 0 ? 0 : (lb > 255 ? 255 : lb);
					_bmd.setPixel(x - 1, y + 1, lr << 16 | lg << 8 | lb);

					// 0, +1
					lc = _bmd.getPixel(x, y + 1);
					lr = (lc >> 16 & 0xFF) + (d3 * er);
					lg = (lc >> 8 & 0xFF) + (d3 * eg);
					lb = (lc & 0xFF) + (d3 * eb);

					// clip & set
					lr = lr < 0 ? 0 : (lr > 255 ? 255 : lr);
					lg = lg < 0 ? 0 : (lg > 255 ? 255 : lg);
					lb = lb < 0 ? 0 : (lb > 255 ? 255 : lb);
					_bmd.setPixel(x, y + 1, lr << 16 | lg << 8 | lb);

					// +1, +1
					lc = _bmd.getPixel(x + 1, y + 1);
					lr = (lc >> 16 & 0xFF) + (d4 * er);
					lg = (lc >> 8 & 0xFF) + (d4 * eg);
					lb = (lc & 0xFF) + (d4 * eb);

					// clip & set
					lr = lr < 0 ? 0 : (lr > 255 ? 255 : lr);
					lg = lg < 0 ? 0 : (lg > 255 ? 255 : lg);
					lb = lb < 0 ? 0 : (lb > 255 ? 255 : lb);
					_bmd.setPixel(x + 1, y + 1, lr << 16 | lg << 8 | lb);
				}
			}
		}
	}
}
