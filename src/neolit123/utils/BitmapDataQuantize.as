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
		private static const aVal:Array = new Array(256);

		private static const point:Point = new Point(0, 0);

		private static const INV_255:Number = 1.0 / 255.0;

		// clamp levels to a max value
		private static function normalizeLevels(_levels:Number, _max:Number = 255):Number
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
			// error checking
			if (!_bmd)
				throw Error("BitmapDataQuantize::quantize(): source cannot be null!");

			// normalize levels
			const norm:Number = normalizeLevels(_levels, 255);
			const inv255Levels:Number = INV_255 * _levels;

			// create pallete
			for (var i:uint = 0; i < 256; i++) {
				const v:uint = uint(i * inv255Levels + 0.5) * norm;
				aVal[i] = v << 24;
				rVal[i] = v << 16;
				gVal[i] = v << 8;
				bVal[i] = v;
			}

			// posterize
			_bmd.paletteMap(_bmd, _bmd.rect, point, rVal, gVal, bVal, aVal);
		}

		/* a heavily optimized version of Ralph Hauwert's Floyd Steinberg AS3.0
		 * implementation:
		 * https://code.google.com/p/imageditheringas3/
		 *
		 * NOTES:
		 * - we do not apply the FS kernel to the alpha channel!
		 * - fast [0, 255] clamp from here:
		 * http://codereview.stackexchange.com/questions/6502/fastest-way-to-clamp-an-integer-to-the-range-0-255
		 */
		public static function quantizeFloydSteinberg(_bmd:BitmapData, _levels:uint):void
		{
			// error checking
			if (!_bmd)
				throw Error("BitmapDataQuantize::quantizeFloydSteinberg(): source cannot be null!");

			// normalize levels
			const norm:Number = normalizeLevels(_levels, 255);

			// the kernel
			const d1:Number = 0.4375; // 7.0 / 16.0
			const d2:Number = 0.1875; // 3.0 / 16.0
			const d3:Number = 0.3125; // 5.0 / 16.0
			const d4:Number = 0.0625; // 1.0 / 16.0

			// some constants
			const h:uint = _bmd.height;
			const w:uint = _bmd.width;
			const len:uint = w * h;
			const len1:uint = len - 1;
			const inv255Levels:Number = INV_255 * _levels;

			// write the entire BitmapData into a uint Vector
			const pix:Vector.<uint> = _bmd.getVector(_bmd.rect);

			for (var i:uint = 0; i < len; i++) {

				// get x, y from index
				const x:uint = i % w;
				const y:uint = i / w;

				// some clobber variables
				var idx:int, j:int;
				var c:uint;
				var a:int, r:int, g:int, b:int;
				var na:uint, nr:uint, ng:uint, nb:uint;
				var er:int, eg:int, eb:int;

				// get current pixel
				c = pix[i];
				a = c >> 24 & 0xFF;
				r = c >> 16 & 0xFF;
				g = c >> 8 & 0xFF;
				b = c & 0xFF;

				// normalize each channel
				na = uint(a * inv255Levels + 0.5) * norm;
				nr = uint(r * inv255Levels + 0.5) * norm;
				ng = uint(g * inv255Levels + 0.5) * norm;
				nb = uint(b * inv255Levels + 0.5) * norm;

				// update current pixel
				pix[i] = na << 24 | nr << 16 | ng << 8 | nb;

				// get quantization error
				er = r - nr;
				eg = g - ng;
				eb = b - nb;

				// apply the kernel

				// +1, 0
				idx = i + 1;
				if (idx < len1) {
					c = pix[idx];
					a = c >> 24 & 0xFF;
					r = (c >> 16 & 0xFF) + d1 * er;
					g = (c >> 8 & 0xFF) + d1 * eg;
					b = (c & 0xFF) + d1 * eb;

					// clamp the r, g, b values to [0, 255]
					j = 255; j -= r; j >>= 31; j |= r; r >>= 31; r = ~r; r &= j;
					j = 255; j -= g; j >>= 31; j |= g; g >>= 31; g = ~g; g &= j;
					j = 255; j -= b; j >>= 31; j |= b; b >>= 31; b = ~b; b &= j;

					pix[idx] = a << 24 | r << 16 | g << 8 | b;
				}

				// -1, +1
				idx = (y + 1) * w + x - 1;
				if (idx < len1 && idx > -1) {
					c = pix[idx];
					a = c >> 24 & 0xFF;
					r = (c >> 16 & 0xFF) + d2 * er;
					g = (c >> 8 & 0xFF) + d2 * eg;
					b = (c & 0xFF) + d2 * eb;

					j = 255; j -= r; j >>= 31; j |= r; r >>= 31; r = ~r; r &= j;
					j = 255; j -= g; j >>= 31; j |= g; g >>= 31; g = ~g; g &= j;
					j = 255; j -= b; j >>= 31; j |= b; b >>= 31; b = ~b; b &= j;

					pix[idx] = a << 24 | r << 16 | g << 8 | b;
				}

				// 0, +1
				idx = (y + 1) * w + x;
				if (idx < len1 && idx > -1) {
					c = pix[idx];
					a = c >> 24 & 0xFF;
					r = (c >> 16 & 0xFF) + d3 * er;
					g = (c >> 8 & 0xFF) + d3 * eg;
					b = (c & 0xFF) + d3 * eb;

					j = 255; j -= r; j >>= 31; j |= r; r >>= 31; r = ~r; r &= j;
					j = 255; j -= g; j >>= 31; j |= g; g >>= 31; g = ~g; g &= j;
					j = 255; j -= b; j >>= 31; j |= b; b >>= 31; b = ~b; b &= j;

					pix[idx] = a << 24 | r << 16 | g << 8 | b;
				}

				// +1, +1
				idx = (y + 1) * w + x + 1;
				if (idx < len1 && idx > -1) {
					c = pix[idx];
					a = c >> 24 & 0xFF;
					r = (c >> 16 & 0xFF) + d4 * er;
					g = (c >> 8 & 0xFF) + d4 * eg;
					b = (c & 0xFF) + d4 * eb;

					j = 255; j -= r; j >>= 31; j |= r; r >>= 31; r = ~r; r &= j;
					j = 255; j -= g; j >>= 31; j |= g; g >>= 31; g = ~g; g &= j;
					j = 255; j -= b; j >>= 31; j |= b; b >>= 31; b = ~b; b &= j;

					pix[idx] = a << 24 | r << 16 | g << 8 | b;
				}
			}

			// update the BitmapData from the Vector
			_bmd.setVector(_bmd.rect, pix);
		}
	}
}
