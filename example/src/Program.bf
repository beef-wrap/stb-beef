using System;
using System.Diagnostics;
using System.IO;
using System.Collections;
using System.Interop;
using static stb.stb_image;
using static stb.stb_image_resize2;
using static stb.stb_image_write;
using static stb.stb_rect_pack;
using static stb.stb_truetype;
using static stb.stb_vorbis;

namespace example;

class Program
{
	public static int Main(String[] args)
	{
		c_int x = 0;
		c_int y = 0;
		c_int n = 0;
		uint8* data = stbi_load("test.png", &x, &y, &n, 0);

		Debug.WriteLine($"width: {x}, height: {y}, channels: {n}");

		stbi_write_png("test2.png", x, y, n, data, 0);

		stbi_write_jpg("test2.jpg", x, y, n, data, 100);

		uint8* resized = stbir_resize_uint8_linear(data, x, y, 0, null, 100, 100, 0, .STBIR_RGBA);

		stbi_write_png("test_resized.png", 100, 100, n, resized, 0);

		stbi_write_jpg("test_resized.jpg", 100, 100, n, resized, 100);

		stbi_image_free(resized);

		stbi_image_free(data);

		List<uint8> ttf_buffer = scope .();
		stbtt_fontinfo font;
		c_int w = 0;
		c_int h = 0;
		c_int c = 65;
		c_int s = 20;

		File.ReadAll("c:/windows/fonts/arial.ttf", ttf_buffer);

		stbtt_InitFont(&font, ttf_buffer.Ptr, stbtt_GetFontOffsetForIndex(ttf_buffer.Ptr, 0));

		let bitmap = stbtt_GetCodepointBitmap(&font, 0, stbtt_ScaleForPixelHeight(&font, s), c, &w, &h, null, null);

		c_int error;

		let ogg = stb_vorbis_open_filename("example.ogg", &error, null);

		let comment = stb_vorbis_get_comment(ogg);

		Debug.WriteLine($"ogg file vendor: ${StringView(comment.vendor)}");



		return 0;
	}
}
