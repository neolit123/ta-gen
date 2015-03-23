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
		private static const CH_BIT_A:uint = 0;
		private static const CH_BIT_R:uint = 1;
		private static const CH_BIT_G:uint = 2;
		private static const CH_BIT_B:uint = 3;

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
				return 1.0;
			return _max / _levels;
		}

		// convert bits to levels
		public static function bitsToLevels(_bits:uint):uint
		{
			return (1 << _bits) - 1;
		}

		private static function checkQuantizeInput(_fName:String, _bmd:BitmapData, _channelBits:Vector.<uint>):void
		{
			const prefix:String = "BitmapDataQuantize::" + _fName + ": ";
			if (!_bmd)
				throw Error(prefix + "source BitmapData cannot be null!");

			if (!_channelBits || _channelBits.length != 4)
				throw Error(prefix + "bad channel bits vector!");

			const len:uint = _channelBits.length;
			for (var i:uint = 0; i < len; i++) {
				if (_channelBits[i] > 8)
					throw Error(prefix + "channel bits at index " + i + " are more than 8");
			}
		}

		// raw quantization / posterization
		public static function quantize(_bmd:BitmapData, _channelBits:Vector.<uint>):void
		{
			// error checking
			checkQuantizeInput("quantize", _bmd, _channelBits);

			// normalize levels
			const levelsA:uint = bitsToLevels(_channelBits[CH_BIT_A]);
			const levelsR:uint = bitsToLevels(_channelBits[CH_BIT_R]);
			const levelsG:uint = bitsToLevels(_channelBits[CH_BIT_G]);
			const levelsB:uint = bitsToLevels(_channelBits[CH_BIT_B]);

			const normA:Number = normalizeLevels(levelsA);
			const normR:Number = normalizeLevels(levelsR);
			const normG:Number = normalizeLevels(levelsG);
			const normB:Number = normalizeLevels(levelsB);

			const inv255LevelsA:Number = INV_255 * levelsA;
			const inv255LevelsR:Number = INV_255 * levelsR;
			const inv255LevelsG:Number = INV_255 * levelsG;
			const inv255LevelsB:Number = INV_255 * levelsB;

			// create pallete
			for (var i:uint = 0; i < 256; i++) {
				const vA:uint = uint(i * inv255LevelsA + 0.5) * normA;
				const vR:uint = uint(i * inv255LevelsR + 0.5) * normR;
				const vG:uint = uint(i * inv255LevelsG + 0.5) * normG;
				const vB:uint = uint(i * inv255LevelsB + 0.5) * normB;
				aVal[i] = vA << 24;
				rVal[i] = vR << 16;
				gVal[i] = vG << 8;
				bVal[i] = vB;
			}

			// posterize
			_bmd.paletteMap(_bmd, _bmd.rect, point, rVal, gVal, bVal, aVal);
		}

		/* a heavily optimized version of Ralph Hauwert's Floyd Steinberg AS3.0
		 * implementation:
		 * https://code.google.com/p/imageditheringas3/
		 * NOTES:
		 * - the FS kernel is not applied to the alpha channel!
		 */
		public static function quantizeFloydSteinberg(_bmd:BitmapData, _channelBits:Vector.<uint>):void
		{
			// error checking
			checkQuantizeInput("quantizeFloydSteinberg", _bmd, _channelBits);

			// normalize levels
			const levelsA:uint = bitsToLevels(_channelBits[CH_BIT_A]);
			const levelsR:uint = bitsToLevels(_channelBits[CH_BIT_R]);
			const levelsG:uint = bitsToLevels(_channelBits[CH_BIT_G]);
			const levelsB:uint = bitsToLevels(_channelBits[CH_BIT_B]);

			const normA:Number = normalizeLevels(levelsA);
			const normR:Number = normalizeLevels(levelsR);
			const normG:Number = normalizeLevels(levelsG);
			const normB:Number = normalizeLevels(levelsB);

			const inv255LevelsA:Number = INV_255 * levelsA;
			const inv255LevelsR:Number = INV_255 * levelsR;
			const inv255LevelsG:Number = INV_255 * levelsG;
			const inv255LevelsB:Number = INV_255 * levelsB;

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

			// write the entire BitmapData into a uint Vector
			const pix:Vector.<uint> = _bmd.getVector(_bmd.rect);

			for (var i:uint = 0; i < len; i++) {

				// get x, y from index
				const x:uint = i % w;
				const y:uint = i / w;

				// some clobber variables
				var idx:uint;
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

				// quantize each channel
				na = uint(a * inv255LevelsA + 0.5) * normA;
				nr = uint(r * inv255LevelsR + 0.5) * normR;
				ng = uint(g * inv255LevelsG + 0.5) * normG;
				nb = uint(b * inv255LevelsB + 0.5) * normB;

				// update current pixel
				pix[i] = na << 24 | nr << 16 | ng << 8 | nb;

				// get quantization error
				er = r - nr;
				eg = g - ng;
				eb = b - nb;

				// apply the kernel

				// +1, 0
				idx = i + 1;
				if (idx & ~len1)
					continue;

				c = pix[idx];
				a = c >> 24 & 0xFF;
				r = (c >> 16 & 0xFF) + d1 * er;
				g = (c >> 8 & 0xFF) + d1 * eg;
				b = (c & 0xFF) + d1 * eb;

				// clamp the r, g, b values to [0, 255]
				r = (r & ~(r >> 31)) - 255; r = (r & (r >> 31)) + 255;
				g = (g & ~(g >> 31)) - 255; g = (g & (g >> 31)) + 255;
				b = (b & ~(b >> 31)) - 255; b = (b & (b >> 31)) + 255;

				pix[idx] = a << 24 | r << 16 | g << 8 | b;

				// -1, +1
				idx = (y + 1) * w + x - 1;
				if (idx & ~len1)
					continue;

				c = pix[idx];
				a = c >> 24 & 0xFF;
				r = (c >> 16 & 0xFF) + d2 * er;
				g = (c >> 8 & 0xFF) + d2 * eg;
				b = (c & 0xFF) + d2 * eb;

				r = (r & ~(r >> 31)) - 255; r = (r & (r >> 31)) + 255;
				g = (g & ~(g >> 31)) - 255; g = (g & (g >> 31)) + 255;
				b = (b & ~(b >> 31)) - 255; b = (b & (b >> 31)) + 255;

				pix[idx] = a << 24 | r << 16 | g << 8 | b;

				// 0, +1
				idx = (y + 1) * w + x;
				if (idx & ~len1)
					continue;

				c = pix[idx];
				a = c >> 24 & 0xFF;
				r = (c >> 16 & 0xFF) + d3 * er;
				g = (c >> 8 & 0xFF) + d3 * eg;
				b = (c & 0xFF) + d3 * eb;

				r = (r & ~(r >> 31)) - 255; r = (r & (r >> 31)) + 255;
				g = (g & ~(g >> 31)) - 255; g = (g & (g >> 31)) + 255;
				b = (b & ~(b >> 31)) - 255; b = (b & (b >> 31)) + 255;

				pix[idx] = a << 24 | r << 16 | g << 8 | b;

				// +1, +1
				idx = (y + 1) * w + x + 1;
				if (idx & ~len1)
					continue;

				c = pix[idx];
				a = c >> 24 & 0xFF;
				r = (c >> 16 & 0xFF) + d4 * er;
				g = (c >> 8 & 0xFF) + d4 * eg;
				b = (c & 0xFF) + d4 * eb;

				r = (r & ~(r >> 31)) - 255; r = (r & (r >> 31)) + 255;
				g = (g & ~(g >> 31)) - 255; g = (g & (g >> 31)) + 255;
				b = (b & ~(b >> 31)) - 255; b = (b & (b >> 31)) + 255;

				pix[idx] = a << 24 | r << 16 | g << 8 | b;
			}

			// update the BitmapData from the Vector
			_bmd.setVector(_bmd.rect, pix);
		}

		/* a simple but efficient noise shaping dither
		 * NOTES:
		 * - the alpha channel is not part of the error and noise feedback
		 */
		public static function quantizeNoiseShaping(_bmd:BitmapData, _channelBits:Vector.<uint>):void
		{
			// error checking
			checkQuantizeInput("quantizeNoiseShaping", _bmd, _channelBits);

			// noise multiplier curve for channel bits [0 - 8]
			const noiseLevel:Vector.<Number> = new <Number>[
				0.0, // 0
				1.0, // 1
				2.0, // 2
				2.0, // 3
				2.0, // 4
				2.0, // 5
				2.0, // 6
				1.0, // 7
				0.0  // 8
			];
			noiseLevel.fixed = true;

			// normalize levels
			const levelsA:uint = bitsToLevels(_channelBits[CH_BIT_A]);
			const levelsR:uint = bitsToLevels(_channelBits[CH_BIT_R]);
			const levelsG:uint = bitsToLevels(_channelBits[CH_BIT_G]);
			const levelsB:uint = bitsToLevels(_channelBits[CH_BIT_B]);

			const normA:Number = normalizeLevels(levelsA);
			const normR:Number = normalizeLevels(levelsR);
			const normG:Number = normalizeLevels(levelsG);
			const normB:Number = normalizeLevels(levelsB);

			const inv255LevelsA:Number = INV_255 * levelsA;
			const inv255LevelsR:Number = INV_255 * levelsR;
			const inv255LevelsG:Number = INV_255 * levelsG;
			const inv255LevelsB:Number = INV_255 * levelsB;

			// some constants
			const len:uint = _bmd.height * _bmd.width;

			// write the entire BitmapData into a uint Vector
			const pix:Vector.<uint> = _bmd.getVector(_bmd.rect);

			for (var i:uint = 0; i < len; i++) {

				// some clobber variables
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

				var r0:Number = Math.random() * 2.0;
				var r1:Number = Math.random() * 2.0;
				var r2:Number = Math.random() * 2.0;

				r += er * r0;
				g += eg * r1;
				b += eb * r2;

				r = (r & ~(r >> 31)) - 255; r = (r & (r >> 31)) + 255;
				g = (g & ~(g >> 31)) - 255; g = (g & (g >> 31)) + 255;
				b = (b & ~(b >> 31)) - 255; b = (b & (b >> 31)) + 255;

				// normalize each channel
				na = uint(a * inv255LevelsA + 0.5) * normA;
				nr = uint(r * inv255LevelsR + 0.5) * normR;
				ng = uint(g * inv255LevelsG + 0.5) * normG;
				nb = uint(b * inv255LevelsB + 0.5) * normB;

				// update current pixel
				pix[i] = na << 24 | nr << 16 | ng << 8 | nb;

				// get quantization error
				er = r - nr;
				eg = g - ng;
				eb = b - nb;
			}

			// update the BitmapData from the Vector
			_bmd.setVector(_bmd.rect, pix);
		}
	}
}
