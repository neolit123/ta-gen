/*
  Copyright (c) 2008, Adobe Systems Incorporated
  Copyright (c) 2015, Lubomir I. Ivanov
  All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are
  met:

  * Redistributions of source code must retain the above copyright notice,
    this list of conditions and the following disclaimer.

  * Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in the
    documentation and/or other materials provided with the distribution.

  * Neither the name of Adobe Systems Incorporated nor the names of its
    contributors may be used to endorse or promote products derived from
    this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
  IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
  THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
  PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
package com.adobe.images
{
	import flash.display.BitmapData;
	import flash.utils.ByteArray;

	/**
	 * Class that converts BitmapData into a valid PNG
	 */
	public class PNGEncoder
	{
		/**
		 * Created a PNG image from the specified BitmapData
		 *
		 * @param image The BitmapData that will be converted into the PNG format.
		 * @return a ByteArray representing the PNG encoded image data.
		 * @langversion ActionScript 3.0
		 * @playerversion Flash 9.0
		 * @tiptext
		 */
		public static function encode(img:BitmapData):ByteArray
		{
			// Create output byte array
			const png:ByteArray = new ByteArray();

			// Write PNG signature
			png.writeUnsignedInt(0x89504E47);
			png.writeUnsignedInt(0x0D0A1A0A);

			// Build IHDR chunk
			const width:uint = img.width;
			const height:uint = img.height;
			const transparent:Boolean = img.transparent;
			const IHDR:ByteArray = new ByteArray();

			IHDR.writeInt(width);
			IHDR.writeInt(height);
			IHDR.writeUnsignedInt(!transparent ? 0x08020000 : 0x08060000); // 32bit RGBA / 24bit RGB
			IHDR.writeByte(0);
			writeChunk(png, 0x49484452, IHDR);

			// Build IDAT chunk
			const IDAT:ByteArray = new ByteArray();
			for (var i:uint = 0; i < height; i++) {
				// no filter
				IDAT.writeByte(0);
				var p:uint;
				var j:uint;
				if (!transparent) {
					for (j = 0; j < width; j++) {
						p = img.getPixel(j, i);
						IDAT.writeByte(p >> 16);
						IDAT.writeShort((p << 8) >> 8);
					}
				} else {
					for (j = 0; j < width; j++) {
						p = img.getPixel32(j, i);
						IDAT.writeUnsignedInt((p << 8) | (p >>> 24));
					}
				}
			}

			IDAT.compress();
			writeChunk(png, 0x49444154, IDAT);

			// Build IEND chunk
			writeChunk(png, 0x49454E44, null);

			// return PNG
			return png;
		}

		private static var crcTable:Vector.<uint> = new Vector.<uint>(256, true);
		private static var crcTableComputed:Boolean = false;

		private static function writeChunk(png:ByteArray, type:uint, data:ByteArray):void
		{
			var c:uint;
			if (!crcTableComputed) {
				crcTableComputed = true;
				for (var n:uint = 0; n < 256; n++) {
					c = n;
					for (var k:uint = 0; k < 8; k++)
						c = (c & 1) ? 0xEDB88320 ^ (c >>> 1) : (c >>> 1);
					crcTable[n] = c;
				}
			}

			const len:uint = data != null ? data.length : 0;
			png.writeUnsignedInt(len);
			const p:uint = png.position;

			png.writeUnsignedInt(type);
			if (data != null)
				png.writeBytes(data);

			const e:uint = png.position;
			png.position = p;
			c = 0xFFFFFFFF;
			const ep:uint = e - p;

			for (var i:uint = 0; i < ep; i++)
				c = crcTable[(c ^ png.readUnsignedByte()) & 0xff] ^ (c >>> 8);

			c ^= 0xFFFFFFFF;
			png.position = e;
			png.writeUnsignedInt(c);
		}
	}
}
