/**
 * BitmapDataExtrude
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
	import flash.geom.Rectangle;
	import flash.geom.Point;

	public class BitmapDataExtrude
	{
		/* performs extrusion of the outer most pixels of a BitmapData with a
		 * repetition of _extrudePixels.
		 *
		 * first left and right parts are extruded, then top and bottom take
		 * the new left and right pixels and the original middle part to complete
		 * the square; there is no special blending at the edges.
		 */
		public static function extrude(_source:BitmapData,
		                               _extrudePixels:uint,
		                               _disposeSource:Boolean = false,
		                               _rect:Rectangle = null,
		                               _point:Point = null,
									   scale:Number = 1.0):BitmapData
		{
			// error checking
			if (!_source)
				throw Error("BitmapDataExtrude::extrude(): source cannot be null!");

			// constants
			const ext:uint = _extrudePixels;
			const src:BitmapData = _source;

			const srcW:uint = src.width * scale;
			const srcH:uint = src.height * scale;
			const destW:uint = srcW + ext * 2;
			const destH:uint = srcH + ext * 2;

			// allocations
			const rect:Rectangle = _rect ? _rect : new Rectangle(0, 0, 0, 0);
			const point:Point = _point ? _point : new Point(0, 0);
			const dest:BitmapData = new BitmapData(destW, destH, true, 0x0);

			// copy source to destination
			point.x = ext;
			point.y = ext;
			dest.copyPixels(src, src.rect, point);

			// extrude
			var i:uint;

			// left, right
			for (i = 0; i < ext; i++) {

				// left
				rect.x = ext;
				rect.y = ext;
				rect.width = 1;
				rect.height = srcH;
				point.x = i;
				point.y = ext;
				dest.copyPixels(dest, rect, point);

				// right
				rect.x = srcW + ext - 1;
				rect.y = ext;
				rect.width = 1;
				rect.height = srcH;
				point.x = srcW + ext + i;
				point.y = ext;
				dest.copyPixels(dest, rect, point);
			}

			for (i = 0; i < ext; i++) {

				// top
				rect.x = 0;
				rect.y = ext;
				rect.width = destW;
				rect.height = 1;
				point.x = 0;
				point.y = i;
				dest.copyPixels(dest, rect, point);

				// bottom
				rect.x = 0;
				rect.y = srcH + ext - 1;
				rect.width = destW;
				rect.height = 1;
				point.x = 0;
				point.y = srcH + ext + i;
				dest.copyPixels(dest, rect, point);
			}

			if (_disposeSource)
				src.dispose();

			return dest;
		}
	}
}
