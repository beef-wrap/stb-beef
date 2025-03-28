// stb_truetype.h - v1.26 - public domain
// authored from 2009-2021 by Sean Barrett / RAD Game Tools
//
// =======================================================================
//
//    NO SECURITY GUARANTEE -- DO NOT USE THIS ON UNTRUSTED FONT FILES
//
// This library does no range checking of the offsets found in the file,
// meaning an attacker can use it to read arbitrary memory.
//
// =======================================================================
//
//   This library processes TrueType files:
//        parse files
//        extract glyph metrics
//        extract glyph shapes
//        render glyphs to one-channel bitmaps with antialiasing (box filter)
//        render glyphs to one-channel SDF bitmaps (signed-distance field/function)
//
//   Todo:
//        non-MS cmaps
//        crashproof on bad data
//        hinting? (no longer patented)
//        cleartype-style AA?
//        optimize: use simple memory allocator for intermediates
//        optimize: build edge-list directly from curves
//        optimize: rasterize directly from curves?
//
// ADDITIONAL CONTRIBUTORS
//
//   Mikko Mononen: compound shape support, more cmap formats
//   Tor Andersson: kerning, subpixel rendering
//   Dougall Johnson: OpenType / Type 2 font handling
//   Daniel Ribeiro Maciel: basic GPOS-based kerning
//
//   Misc other:
//       Ryan Gordon
//       Simon Glass
//       github:IntellectualKitty
//       Imanol Celaya
//       Daniel Ribeiro Maciel
//
//   Bug/warning reports/fixes:
//       "Zer" on mollyrocket       Fabian "ryg" Giesen   github:NiLuJe
//       Cass Everitt               Martins Mozeiko       github:aloucks
//       stoiko (Haemimont Games)   Cap Petschulat        github:oyvindjam
//       Brian Hook                 Omar Cornut           github:vassvik
//       Walter van Niftrik         Ryan Griege
//       David Gow                  Peter LaValle
//       David Given                Sergey Popov
//       Ivan-Assen Ivanov          Giumo X. Clanjor
//       Anthony Pesch              Higor Euripedes
//       Johan Duparc               Thomas Fields
//       Hou Qiming                 Derek Vinyard
//       Rob Loach                  Cort Stratton
//       Kenney Phillis Jr.         Brian Costabile
//       Ken Voskuil (kaesve)       Yakov Galka
//
// VERSION HISTORY
//
//   1.26 (2021-08-28) fix broken rasterizer
//   1.25 (2021-07-11) many fixes
//   1.24 (2020-02-05) fix warning
//   1.23 (2020-02-02) query SVG data for glyphs; query whole kerning table (but only kern not GPOS)
//   1.22 (2019-08-11) minimize missing-glyph duplication; fix kerning if both 'GPOS' and 'kern' are defined
//   1.21 (2019-02-25) fix warning
//   1.20 (2019-02-07) PackFontRange skips missing codepoints; GetScaleFontVMetrics()
//   1.19 (2018-02-11) GPOS kerning, STBTT_fmod
//   1.18 (2018-01-29) add missing function
//   1.17 (2017-07-23) make more arguments const; doc fix
//   1.16 (2017-07-12) SDF support
//   1.15 (2017-03-03) make more arguments const
//   1.14 (2017-01-16) num-fonts-in-TTC function
//   1.13 (2017-01-02) support OpenType fonts, certain Apple fonts
//   1.12 (2016-10-25) suppress warnings about casting away with -Wcast-qual
//   1.11 (2016-04-02) fix unused-variable warning
//   1.10 (2016-04-02) user-defined fabs(); rare memory leak; remove duplicate typedef
//   1.09 (2016-01-16) warning fix; avoid crash on outofmem; use allocation userdata properly
//   1.08 (2015-09-13) document stbtt_Rasterize(); fixes for vertical & horizontal edges
//   1.07 (2015-08-01) allow PackFontRanges to accept arrays of sparse codepoints;
//                     variant PackFontRanges to pack and render in separate phases;
//                     fix stbtt_GetFontOFfsetForIndex (never worked for non-0 input?);
//                     fixed an assert() bug in the new rasterizer
//                     replace assert() with STBTT_assert() in new rasterizer
//
//   Full history can be found at the end of this file.
//
// LICENSE
//
//   See end of file for license information.
//
// USAGE
//
//   Include this file in whatever places need to refer to it. In ONE C/C++
//   file, write:
//      #define STB_TRUETYPE_IMPLEMENTATION
//   before the #include of this file. This expands out the actual
//   implementation into that C/C++ file.
//
//   To make the implementation private to the file that generates the implementation,
//      #define STBTT_STATIC
//
//   Simple 3D API (don't ship this, but it's fine for tools and quick start)
//           stbtt_BakeFontBitmap()               -- bake a font to a bitmap for use as texture
//           stbtt_GetBakedQuad()                 -- compute quad to draw for a given char
//
//   Improved 3D API (more shippable):
//           #include "stb_rect_pack.h"           -- optional, but you really want it
//           stbtt_PackBegin()
//           stbtt_PackSetOversampling()          -- for improved quality on small fonts
//           stbtt_PackFontRanges()               -- pack and renders
//           stbtt_PackEnd()
//           stbtt_GetPackedQuad()
//
//   "Load" a font file from a memory buffer (you have to keep the buffer loaded)
//           stbtt_InitFont()
//           stbtt_GetFontOffsetForIndex()        -- indexing for TTC font collections
//           stbtt_GetNumberOfFonts()             -- number of fonts for TTC font collections
//
//   Render a unicode codepoint to a bitmap
//           stbtt_GetCodepointBitmap()           -- allocates and returns a bitmap
//           stbtt_MakeCodepointBitmap()          -- renders into bitmap you provide
//           stbtt_GetCodepointBitmapBox()        -- how big the bitmap must be
//
//   Character advance/positioning
//           stbtt_GetCodepointHMetrics()
//           stbtt_GetFontVMetrics()
//           stbtt_GetFontVMetricsOS2()
//           stbtt_GetCodepointKernAdvance()
//
//   Starting with version 1.06, the rasterizer was replaced with a new,
//   faster and generally-more-precise rasterizer. The new rasterizer more
//   accurately measures pixel coverage for anti-aliasing, except in the case
//   where multiple shapes overlap, in which case it overestimates the AA pixel
//   coverage. Thus, anti-aliasing of intersecting shapes may look wrong. If
//   this turns out to be a problem, you can re-enable the old rasterizer with
//        #define STBTT_RASTERIZER_VERSION 1
//   which will incur about a 15% speed hit.
//
// ADDITIONAL DOCUMENTATION
//
//   Immediately after this block comment are a series of sample programs.
//
//   After the sample programs is the "header file" section. This section
//   includes documentation for each API function.
//
//   Some important concepts to understand to use this library:
//
//      Codepoint
//         Characters are defined by unicode codepoints, e.g. 65 is
//         uppercase A, 231 is lowercase c with a cedilla, 0x7e30 is
//         the hiragana for "ma".
//
//      Glyph
//         A visual character shape (every codepoint is rendered as
//         some glyph)
//
//      Glyph index
//         A font-specific integer ID representing a glyph
//
//      Baseline
//         Glyph shapes are defined relative to a baseline, which is the
//         bottom of uppercase characters. Characters extend both above
//         and below the baseline.
//
//      Current Point
//         As you draw text to the screen, you keep track of a "current point"
//         which is the origin of each character. The current point's vertical
//         position is the baseline. Even "baked fonts" use this model.
//
//      Vertical Font Metrics
//         The vertical qualities of the font, used to vertically position
//         and space the characters. See docs for stbtt_GetFontVMetrics.
//
//      Font Size in Pixels or Points
//         The preferred interface for specifying font sizes in stb_truetype
//         is to specify how tall the font's vertical extent should be in pixels.
//         If that sounds good enough, skip the next paragraph.
//
//         Most font APIs instead use "points", which are a common typographic
//         measurement for describing font size, defined as 72 points per inch.
//         stb_truetype provides a point API for compatibility. However, true
//         "per inch" conventions don't make much sense on computer displays
//         since different monitors have different number of pixels per
//         inch. For example, Windows traditionally uses a convention that
//         there are 96 pixels per inch, thus making 'inch' measurements have
//         nothing to do with inches, and thus effectively defining a point to
//         be 1.333 pixels. Additionally, the TrueType font data provides
//         an explicit scale factor to scale a given font's glyphs to points,
//         but the author has observed that this scale factor is often wrong
//         for non-commercial fonts, thus making fonts scaled in points
//         according to the TrueType spec incoherently sized in practice.
//
// DETAILED USAGE:
//
//  Scale:
//    Select how high you want the font to be, in points or pixels.
//    Call ScaleForPixelHeight or ScaleForMappingEmToPixels to compute
//    a scale factor SF that will be used by all other functions.
//
//  Baseline:
//    You need to select a y-coordinate that is the baseline of where
//    your text will appear. Call GetFontBoundingBox to get the baseline-relative
//    bounding box for all characters. SF*-y0 will be the distance in pixels
//    that the worst-case character could extend above the baseline, so if
//    you want the top edge of characters to appear at the top of the
//    screen where y=0, then you would set the baseline to SF*-y0.
//
//  Current point:
//    Set the current point where the first character will appear. The
//    first character could extend left of the current point; this is font
//    dependent. You can either choose a current point that is the leftmost
//    point and hope, or add some padding, or check the bounding box or
//    left-side-bearing of the first character to be displayed and set
//    the current point based on that.
//
//  Displaying a character:
//    Compute the bounding box of the character. It will contain signed values
//    relative to <current_point, baseline>. I.e. if it returns x0,y0,x1,y1,
//    then the character should be displayed in the rectangle from
//    <current_point+SF*x0, baseline+SF*y0> to <current_point+SF*x1,baseline+SF*y1).
//
//  Advancing for the next character:
//    Call GlyphHMetrics, and compute 'current_point += SF * advance'.
//
//
// ADVANCED USAGE
//
//   Quality:
//
//    - Use the functions with Subpixel at the end to allow your characters
//      to have subpixel positioning. Since the font is anti-aliased, not
//      hinted, this is very import for quality. (This is not possible with
//      baked fonts.)
//
//    - Kerning is now supported, and if you're supporting subpixel rendering
//      then kerning is worth using to give your text a polished look.
//
//   Performance:
//
//    - Convert Unicode codepoints to glyph indexes and operate on the glyphs;
//      if you don't do this, stb_truetype is forced to do the conversion on
//      every call.
//
//    - There are a lot of memory allocations. We should modify it to take
//      a temp buffer and allocate from the temp buffer (without freeing),
//      should help performance a lot.
//
// NOTES
//
//   The system uses the raw data found in the .ttf file without changing it
//   and without building auxiliary data structures. This is a bit inefficient
//   on little-endian systems (the data is big-endian), but assuming you're
//   caching the bitmaps or glyph shapes this shouldn't be a big deal.
//
//   It appears to be very hard to programmatically determine what font a
//   given file is in a general way. I provide an API for this, but I don't
//   recommend it.
//
//
// PERFORMANCE MEASUREMENTS FOR 1.06:
//
//                      32-bit     64-bit
//   Previous release:  8.83 s     7.68 s
//   Pool allocations:  7.72 s     6.34 s
//   Inline sort     :  6.54 s     5.65 s
//   New rasterizer  :  5.63 s     5.00 s

using System;
using System.Interop;

namespace stb;

public static class stb_truetype
{
	///////////////////////////////////////////////////////////////////////////////
	///////////////////////////////////////////////////////////////////////////////
	////
	////   INTERFACE
	////
	////

	typealias stbrp_coord = c_int;

	[CRepr]
	struct stbrp_rect
	{
		stbrp_coord x, y;
		c_int id, w, h, was_packed;
	}

	[CRepr]
	struct stbtt__buf
	{
		c_uchar* data;
		c_int cursor;
		c_int size;
	}

	//////////////////////////////////////////////////////////////////////////////
	//
	// TEXTURE BAKING API
	//
	// If you use this API, you only have to call two functions ever.
	//

	[CRepr]
	struct stbtt_bakedchar
	{
		c_ushort x0, y0, x1, y1; // coordinates of bbox in bitmap
		float xoff, yoff, xadvance;
	}

	// if return is positive, the first unused row of the bitmap
	// if return is negative, returns the negative of the number of characters that fit
	// if return is 0, no characters fit and no rows were used
	// This uses a very crappy packing.
	// offset - font location (use offset=0 for plain .ttf)
	// pixel_height - height of font in pixels
	// pixels, pw, ph - bitmap to be filled in
	// first_char, num_chars - characters to bake
	// chardata - you allocate this, it's num_chars long
	[CLink] public static extern c_int stbtt_BakeFontBitmap(c_uchar* data, c_int offset, float pixel_height, c_uchar* pixels, c_int pw, c_int ph, c_int first_char, c_int num_chars, stbtt_bakedchar* chardata);

	[CRepr]
	public struct stbtt_aligned_quad
	{
		float x0, y0, s0, t0; // top-left
		float x1, y1, s1, t1; // bottom-right
	}

	// Call GetBakedQuad with char_index = 'character - first_char', and it
	// creates the quad you need to draw and advances the current position.
	//
	// The coordinate system used assumes y increases downwards.
	//
	// Characters will extend both above and below the current position;
	// see discussion of "BASELINE" above.
	//
	// It's inefficient; you might want to c&p it and optimize it.
	// char_index character to display
	// xpos, ypos - pointers to current position in screen pixel space
	// q - output: quad to draw
	// opengl_fillrule - true if opengl fill rule; false if DX9 or earlier
	[CLink] public static extern void stbtt_GetBakedQuad(stbtt_bakedchar* chardata, c_int pw, c_int ph, c_int char_index, float* xpos, float* ypos, stbtt_aligned_quad* q, c_int opengl_fillrule);

	// Query the font vertical metrics without having to create a font first.
	[CLink] public static extern void stbtt_GetScaledFontVMetrics(c_uchar* fontdata, c_int index, float size, float* ascent, float* descent, float* lineGap);


	 //////////////////////////////////////////////////////////////////////////////
	 //
	 // NEW TEXTURE BAKING API
	 //
	 // This provides options for packing multiple fonts into one atlas, not
	 // perfectly but better than nothing.

	[CRepr]
	struct stbtt_packedchar
	{
		c_ushort x0, y0, x1, y1; // coordinates of bbox in bitmap
		float xoff, yoff, xadvance;
		float xoff2, yoff2;
	}

	// Initializes a packing context stored in the passed-in stbtt_pack_context.
	// Future calls using this context will pack characters into the bitmap passed
	// in here: a 1-channel bitmap that is width * height. stride_in_bytes is
	// the distance from one row to the next (or 0 to mean they are packed tightly
	// together). "padding" is the amount of padding to leave between each
	// character (normally you want '1' for bitmaps you'll use as textures with
	// bilinear filtering).
	//
	// Returns 0 on failure, 1 on success.
	[CLink] public static extern c_int  stbtt_PackBegin(stbtt_pack_context* spc, c_uchar* pixels, c_int width, c_int height, c_int stride_in_bytes, c_int padding, void* alloc_context);

	// Cleans up the packing context and frees all memory.
	[CLink] public static extern void stbtt_PackEnd(stbtt_pack_context* spc);


	 //#define STBTT_POINT_SIZE(x)   (-(x))

	 // Creates character bitmaps from the font_index'th font found in fontdata (use
	 // font_index=0 if you don't know what that is). It creates num_chars_in_range
	 // bitmaps for characters with unicode values starting at first_unicode_char_in_range
	 // and increasing. Data for how to render them is stored in chardata_for_range;
	 // pass these to stbtt_GetPackedQuad to get back renderable quads.
	 //
	 // font_size is the full height of the character from ascender to descender,
	 // as computed by stbtt_ScaleForPixelHeight. To use a point size as computed
	 // by stbtt_ScaleForMappingEmToPixels, wrap the point size in STBTT_POINT_SIZE()
	 // and pass that result as 'font_size':
	 //       ...,                  20 , ... // font max minus min y is 20 pixels tall
	 //       ..., STBTT_POINT_SIZE(20), ... // 'M' is 20 pixels tall
	[CLink] public static extern c_int stbtt_PackFontRange(stbtt_pack_context* spc, c_uchar* fontdata, c_int font_index, float font_size, c_int first_unicode_char_in_range, c_int num_chars_in_range, stbtt_packedchar* chardata_for_range);

	[CRepr]
	struct stbtt_pack_range
	{
		float font_size;
		c_int first_unicode_codepoint_in_range; // if non-zero, then the chars are continuous, and this is the first codepoint
		c_int* array_of_unicode_codepoints; // if non-zero, then this is an array of unicode codepoints
		c_int num_chars;
		stbtt_packedchar* chardata_for_range; // output
		c_uchar h_oversample, v_oversample; // don't set these, they're used internally
	}

	[CLink] public static extern c_int  stbtt_PackFontRanges(stbtt_pack_context* spc, c_uchar* fontdata, c_int font_index, stbtt_pack_range* ranges, c_int num_ranges);
	 // Creates character bitmaps from multiple ranges of characters stored in
	 // ranges. This will usually create a better-packed bitmap than multiple
	 // calls to stbtt_PackFontRange. Note that you can call this multiple
	 // times within a single PackBegin/PackEnd.

	[CLink] public static extern void stbtt_PackSetOversampling(stbtt_pack_context* spc, uint h_oversample, uint v_oversample);
	 // Oversampling a font increases the quality by allowing higher-quality subpixel
	 // positioning, and is especially valuable at smaller text sizes.
	 //
	 // This function sets the amount of oversampling for all following calls to
	 // stbtt_PackFontRange(s) or stbtt_PackFontRangesGatherRects for a given
	 // pack context. The default (no oversampling) is achieved by h_oversample=1
	 // and v_oversample=1. The total number of pixels required is
	 // h_oversample*v_oversample larger than the default; for example, 2x2
	 // oversampling requires 4x the storage of 1x1. For best results, render
	 // oversampled textures with bilinear filtering. Look at the readme in
	 // stb/tests/oversample for information about oversampled fonts
	 //
	 // To use with PackFontRangesGather etc., you must set it before calls
	 // call to PackFontRangesGatherRects.

	[CLink] public static extern void stbtt_PackSetSkipMissingCodepoints(stbtt_pack_context* spc, c_int skip);
	 // If skip != 0, this tells stb_truetype to skip any codepoints for which
	 // there is no corresponding glyph. If skip=0, which is the default, then
	 // codepoints without a glyph recived the font's "missing character" glyph,
	 // typically an empty box by convention.

	[CLink] public static extern void stbtt_GetPackedQuad(stbtt_packedchar* chardata, c_int pw, c_int ph, // same data as above
		c_int char_index, // character to display
		float* xpos, float* ypos, // pointers to current position in screen pixel space
		stbtt_aligned_quad* q, // output: quad to draw
		c_int align_to_integer);

	[CLink] public static extern c_int  stbtt_PackFontRangesGatherRects(stbtt_pack_context* spc, stbtt_fontinfo* info, stbtt_pack_range* ranges, c_int num_ranges, stbrp_rect* rects);
	[CLink] public static extern void stbtt_PackFontRangesPackRects(stbtt_pack_context* spc, stbrp_rect* rects, c_int num_rects);
	[CLink] public static extern c_int  stbtt_PackFontRangesRenderIntoRects(stbtt_pack_context* spc, stbtt_fontinfo* info, stbtt_pack_range* ranges, c_int num_ranges, stbrp_rect* rects);
	 // Calling these functions in sequence is roughly equivalent to calling
	 // stbtt_PackFontRanges(). If you more control over the packing of multiple
	 // fonts, or if you want to pack custom data into a font texture, take a look
	 // at the source to of stbtt_PackFontRanges() and create a custom version
	 // using these functions, e.g. call GatherRects multiple times,
	 // building up a single array of rects, then call PackRects once,
	 // then call RenderIntoRects repeatedly. This may result in a
	 // better packing than calling PackFontRanges multiple times
	 // (or it may not).
 
	 // this is an opaque structure that you shouldn't mess with which holds
	 // all the context needed from PackBegin to PackEnd.
	[CRepr]
	public struct stbtt_pack_context
	{
		void* user_allocator_context;
		void* pack_info;
		c_int   width;
		c_int   height;
		c_int   stride_in_bytes;
		c_int   padding;
		c_int   skip_missing;
		uint   h_oversample, v_oversample;
		c_uchar* pixels;
		void  * nodes;
	}

	 //////////////////////////////////////////////////////////////////////////////
	 //
	 // FONT LOADING
	 //
	 //

	[CLink] public static extern c_int stbtt_GetNumberOfFonts(c_uchar* data);
	 // This function will determine the number of fonts in a font file.  TrueType
	 // collection (.ttc) files may contain multiple fonts, while TrueType font
	 // (.ttf) files only contain one font. The number of fonts can be used for
	 // indexing with the previous function where the index is between zero and one
	 // less than the total fonts. If an error occurs, -1 is returned.

	[CLink] public static extern c_int stbtt_GetFontOffsetForIndex(c_uchar* data, c_int index);
	 // Each .ttf/.ttc file may have more than one font. Each font has a sequential
	 // index number starting from 0. Call this function to get the font offset for
	 // a given index; it returns -1 if the index is out of range. A regular .ttf
	 // file will only define one font and it always be at offset 0, so it will
	 // return '0' for index 0, and -1 for all other indices.
 
	 // The following structure is defined publicly so you can declare one on
	 // the stack or as a global or etc, but you should treat it as opaque.
	[CRepr]
	public struct stbtt_fontinfo
	{
		void*			 userdata;
		c_uchar* 		 data; // pointer to .ttf file
		c_int              fontstart; // offset of start of font

		c_int numGlyphs; // number of glyphs, needed for range checking

		c_int loca, head, glyf, hhea, hmtx, kern, gpos, svg; // table locations as offset from start of .ttf
		c_int index_map; // a cmap mapping for our chosen character encoding
		c_int indexToLocFormat; // format needed to map from glyph index to glyph

		stbtt__buf cff; // cff font data
		stbtt__buf charstrings; // the charstring index
		stbtt__buf gsubrs; // global charstring subroutines index
		stbtt__buf subrs; // private charstring subroutines index
		stbtt__buf fontdicts; // array of font dicts
		stbtt__buf fdselect; // map from glyph to fontdict
	}

	[CLink] public static extern c_int stbtt_InitFont(stbtt_fontinfo* info, c_uchar* data, c_int offset);
	 // Given an offset into the file that defines a font, this function builds
	 // the necessary cached info for the rest of the system. You must allocate
	 // the stbtt_fontinfo yourself, and stbtt_InitFont will fill it out. You don't
	 // need to do anything special to free it, because the contents are pure
	 // value data with no additional data structures. Returns 0 on failure.
 
 
	 //////////////////////////////////////////////////////////////////////////////
	 //
	 // CHARACTER TO GLYPH-INDEX CONVERSIOn

	[CLink] public static extern c_int stbtt_FindGlyphIndex(stbtt_fontinfo* info, c_int unicode_codepoint);
	// If you're going to perform multiple operations on the same character
	// and you want a speed-up, call this function with the character you're
	// going to process, then use glyph-based functions instead of the
	// codepoint-based functions.
	// Returns 0 if the character codepoint is not defined in the font.
	
	
	//////////////////////////////////////////////////////////////////////////////
	//
	// CHARACTER PROPERTIES
	//

	[CLink] public static extern float stbtt_ScaleForPixelHeight(stbtt_fontinfo* info, float pixels);
	// computes a scale factor to produce a font whose "height" is 'pixels' tall.
	// Height is measured as the distance from the highest ascender to the lowest
	// descender; in other words, it's equivalent to calling stbtt_GetFontVMetrics
	// and computing:
	//       scale = pixels / (ascent - descent)
	// so if you prefer to measure height by the ascent only, use a similar calculation.

	[CLink] public static extern float stbtt_ScaleForMappingEmToPixels(stbtt_fontinfo* info, float pixels);
	// computes a scale factor to produce a font whose EM size is mapped to
	// 'pixels' tall. This is probably what traditional APIs compute, but
	// I'm not positive.

	// ascent is the coordinate above the baseline the font extends; descent
	// is the coordinate below the baseline the font extends (i.e. it is typically negative)
	// lineGap is the spacing between one row's descent and the next row's ascent...
	// so you should advance the vertical position by "*ascent - *descent + *lineGap"
	//   these are expressed in unscaled coordinates, so you must multiply by
	//   the scale factor for a given size
	[CLink] public static extern void stbtt_GetFontVMetrics(stbtt_fontinfo* info, c_int* ascent, c_int* descent, c_int* lineGap);

	// analogous to GetFontVMetrics, but returns the "typographic" values from the OS/2
	// table (specific to MS/Windows TTF files).
	//
	// Returns 1 on success (table present), 0 on failure.
	[CLink] public static extern c_int  stbtt_GetFontVMetricsOS2(stbtt_fontinfo* info, c_int* typoAscent, c_int* typoDescent, c_int* typoLineGap);

	// the bounding box around all possible characters
	[CLink] public static extern void stbtt_GetFontBoundingBox(stbtt_fontinfo* info, c_int* x0, c_int* y0, c_int* x1, c_int* y1);

	// leftSideBearing is the offset from the current horizontal position to the left edge of the character
	// advanceWidth is the offset from the current horizontal position to the next horizontal position
	//   these are expressed in unscaled coordinates
	[CLink] public static extern void stbtt_GetCodepointHMetrics(stbtt_fontinfo* info, c_int codepoint, c_int* advanceWidth, c_int* leftSideBearing);

	// an additional amount to add to the 'advance' value between ch1 and ch2
	[CLink] public static extern c_int  stbtt_GetCodepointKernAdvance(stbtt_fontinfo* info, c_int ch1, c_int ch2);

	// Gets the bounding box of the visible part of the glyph, in unscaled coordinates
	[CLink] public static extern c_int stbtt_GetCodepointBox(stbtt_fontinfo* info, c_int codepoint, c_int* x0, c_int* y0, c_int* x1, c_int* y1);


	[CLink] public static extern void stbtt_GetGlyphHMetrics(stbtt_fontinfo* info, c_int glyph_index, c_int* advanceWidth, c_int* leftSideBearing);
	[CLink] public static extern c_int  stbtt_GetGlyphKernAdvance(stbtt_fontinfo* info, c_int glyph1, c_int glyph2);
	// as above, but takes one or more glyph indices for greater efficiency
	[CLink] public static extern c_int  stbtt_GetGlyphBox(stbtt_fontinfo* info, c_int glyph_index, c_int* x0, c_int* y0, c_int* x1, c_int* y1);

	[CRepr]
	public struct stbtt_kerningentry
	{
		c_int glyph1; // use stbtt_FindGlyphIndex
		c_int glyph2;
		c_int advance;
	}

	[CLink] public static extern c_int  stbtt_GetKerningTableLength(stbtt_fontinfo* info);

	// Retrieves a complete list of all of the kerning pairs provided by the font
	// stbtt_GetKerningTable never writes more than table_length entries and returns how many entries it did write.
	// The table will be sorted by (a.glyph1 == b.glyph1)?(a.glyph2 < b.glyph2):(a.glyph1 < b.glyph1)
	[CLink] public static extern c_int  stbtt_GetKerningTable(stbtt_fontinfo* info, stbtt_kerningentry* table, c_int table_length);


	//////////////////////////////////////////////////////////////////////////////
	//
	// GLYPH SHAPES (you probably don't need these, but they have to go before
	// the bitmaps for C declaration-order reasons)
	//
 #if !STBTT_vmove // you can predefine these to use different values (but why?)
	public enum sbtt_vmove : c_int
	{
		STBTT_vmove = 1,
		STBTT_vline,
		STBTT_vcurve,
		STBTT_vcubic
	}
#endif


	// (we share this with other code at RAD)
	[CRepr]
	public struct stbtt_vertex
	{
		c_short x, y, cx, cy, cx1, cy1;
		c_uchar type, padding;
	}

	// returns non-zero if nothing is drawn for this glyph
	[CLink] public static extern c_int stbtt_IsGlyphEmpty(stbtt_fontinfo* info, c_int glyph_index);

	[CLink] public static extern c_int stbtt_GetCodepointShape(stbtt_fontinfo* info, c_int unicode_codepoint, stbtt_vertex** vertices);

	// returns # of vertices and fills *vertices with the pointer to them
	//   these are expressed in "unscaled" coordinates
	//
	// The shape is a series of contours. Each one starts with
	// a STBTT_moveto, then consists of a series of mixed
	// STBTT_lineto and STBTT_curveto segments. A lineto
	// draws a line from previous endpoint to its x,y; a curveto
	// draws a quadratic bezier from previous endpoint to
	// its x,y, using cx,cy as the bezier control point.
	[CLink] public static extern c_int stbtt_GetGlyphShape(stbtt_fontinfo* info, c_int glyph_index, stbtt_vertex** vertices);

	  // frees the data allocated above
	[CLink] public static extern void stbtt_FreeShape(stbtt_fontinfo* info, stbtt_vertex* vertices);

	[CLink] public static extern c_uchar* stbtt_FindSVGDoc(stbtt_fontinfo* info, c_int gl);
	[CLink] public static extern c_int stbtt_GetCodepointSVG(stbtt_fontinfo* info, c_int unicode_codepoint, char8** svg);

	// fills svg with the character's SVG data.
	// returns data size or 0 if SVG not found.
	[CLink] public static extern c_int stbtt_GetGlyphSVG(stbtt_fontinfo* info, c_int gl, char8** svg);

	//////////////////////////////////////////////////////////////////////////////
	//
	// BITMAP RENDERING
	//

	// frees the bitmap allocated below
	[CLink] public static extern void stbtt_FreeBitmap(c_uchar* bitmap, void* userdata);

	// allocates a large-enough single-channel 8bpp bitmap and renders the
	// specified character/glyph at the specified scale into it, with
	// antialiasing. 0 is no coverage (transparent), 255 is fully covered (opaque).
	// *width & *height are filled out with the width & height of the bitmap,
	// which is stored left-to-right, top-to-bottom.
	//
	// xoff/yoff are the offset it pixel space from the glyph origin to the top-left of the bitmap
	[CLink] public static extern c_uchar* stbtt_GetCodepointBitmap(stbtt_fontinfo* info, float scale_x, float scale_y, c_int codepoint, c_int* width, c_int* height, c_int* xoff, c_int* yoff);

	// the same as stbtt_GetCodepoitnBitmap, but you can specify a subpixel
	// shift for the character
	[CLink] public static extern c_uchar* stbtt_GetCodepointBitmapSubpixel(stbtt_fontinfo* info, float scale_x, float scale_y, float shift_x, float shift_y, c_int codepoint, c_int* width, c_int* height, c_int* xoff, c_int* yoff);

	// the same as stbtt_GetCodepointBitmap, but you pass in storage for the bitmap
	// in the form of 'output', with row spacing of 'out_stride' bytes. the bitmap
	// is clipped to out_w/out_h bytes. Call stbtt_GetCodepointBitmapBox to get the
	// width and height and positioning info for it first.
	[CLink] public static extern void stbtt_MakeCodepointBitmap(stbtt_fontinfo* info, c_uchar* output, c_int out_w, c_int out_h, c_int out_stride, float scale_x, float scale_y, c_int codepoint);

	// same as stbtt_MakeCodepointBitmap, but you can specify a subpixel
	// shift for the character
	[CLink] public static extern void stbtt_MakeCodepointBitmapSubpixel(stbtt_fontinfo* info, c_uchar* output, c_int out_w, c_int out_h, c_int out_stride, float scale_x, float scale_y, float shift_x, float shift_y, c_int codepoint);

	// same as stbtt_MakeCodepointBitmapSubpixel, but prefiltering
	// is performed (see stbtt_PackSetOversampling)
	[CLink] public static extern void stbtt_MakeCodepointBitmapSubpixelPrefilter(stbtt_fontinfo* info, c_uchar* output, c_int out_w, c_int out_h, c_int out_stride, float scale_x, float scale_y, float shift_x, float shift_y, c_int oversample_x, c_int oversample_y, float* sub_x, float* sub_y, c_int codepoint);

	// get the bbox of the bitmap centered around the glyph origin; so the
	// bitmap width is ix1-ix0, height is iy1-iy0, and location to place
	// the bitmap top left is (leftSideBearing*scale,iy0).
	// (Note that the bitmap uses y-increases-down, but the shape uses
	// y-increases-up, so CodepointBitmapBox and CodepointBox are inverted.)
	[CLink] public static extern void stbtt_GetCodepointBitmapBox(stbtt_fontinfo* font, c_int codepoint, float scale_x, float scale_y, c_int* ix0, c_int* iy0, c_int* ix1, c_int* iy1);

	// same as stbtt_GetCodepointBitmapBox, but you can specify a subpixel
	// shift for the character
	[CLink] public static extern void stbtt_GetCodepointBitmapBoxSubpixel(stbtt_fontinfo* font, c_int codepoint, float scale_x, float scale_y, float shift_x, float shift_y, c_int* ix0, c_int* iy0, c_int* ix1, c_int* iy1);


	// the following functions are equivalent to the above functions, but operate
	// on glyph indices instead of Unicode codepoints (for efficiency)
	[CLink] public static extern c_uchar* stbtt_GetGlyphBitmap(stbtt_fontinfo* info, float scale_x, float scale_y, c_int glyph, c_int* width, c_int* height, c_int* xoff, c_int* yoff);
	[CLink] public static extern c_uchar* stbtt_GetGlyphBitmapSubpixel(stbtt_fontinfo* info, float scale_x, float scale_y, float shift_x, float shift_y, c_int glyph, c_int* width, c_int* height, c_int* xoff, c_int* yoff);
	[CLink] public static extern void stbtt_MakeGlyphBitmap(stbtt_fontinfo* info, c_uchar* output, c_int out_w, c_int out_h, c_int out_stride, float scale_x, float scale_y, c_int glyph);
	[CLink] public static extern void stbtt_MakeGlyphBitmapSubpixel(stbtt_fontinfo* info, c_uchar* output, c_int out_w, c_int out_h, c_int out_stride, float scale_x, float scale_y, float shift_x, float shift_y, c_int glyph);
	[CLink] public static extern void stbtt_MakeGlyphBitmapSubpixelPrefilter(stbtt_fontinfo* info, c_uchar* output, c_int out_w, c_int out_h, c_int out_stride, float scale_x, float scale_y, float shift_x, float shift_y, c_int oversample_x, c_int oversample_y, float* sub_x, float* sub_y, c_int glyph);
	[CLink] public static extern void stbtt_GetGlyphBitmapBox(stbtt_fontinfo* font, c_int glyph, float scale_x, float scale_y, c_int* ix0, c_int* iy0, c_int* ix1, c_int* iy1);
	[CLink] public static extern void stbtt_GetGlyphBitmapBoxSubpixel(stbtt_fontinfo* font, c_int glyph, float scale_x, float scale_y, float shift_x, float shift_y, c_int* ix0, c_int* iy0, c_int* ix1, c_int* iy1);

	// @TODO: don't expose this structure
	[CRepr]
	struct stbtt__bitmap
	{
		c_int w, h, stride;
		c_uchar* pixels;
	}

	// rasterize a shape with quadratic beziers into a bitmap
	[CLink] public static extern void stbtt_Rasterize(stbtt__bitmap* result, // 1-channel bitmap to draw into
		float flatness_in_pixels, // allowable error of curve in pixels
		stbtt_vertex* vertices, // array of vertices defining shape
		c_int num_verts, // number of vertices in above array
		float scale_x, float scale_y, // scale applied to input vertices
		float shift_x, float shift_y, // translation applied to input vertices
		c_int x_off, c_int y_off, // another translation applied to input
		c_int invert, // if non-zero, vertically flip shape
		void* userdata); // context for to STBTT_MALLOC
 
	//////////////////////////////////////////////////////////////////////////////
	//
	// Signed Distance Function (or Field) rendering

	// frees the SDF bitmap allocated below
	[CLink] public static extern void stbtt_FreeSDF(c_uchar* bitmap, void* userdata);

	[CLink] public static extern c_uchar*  stbtt_GetGlyphSDF(stbtt_fontinfo* info, float scale, c_int glyph, c_int padding, c_uchar onedge_value, float pixel_dist_scale, c_int* width, c_int* height, c_int* xoff, c_int* yoff);

	// These functions compute a discretized SDF field for a single character, suitable for storing
	// in a single-channel texture, sampling with bilinear filtering, and testing against
	// larger than some threshold to produce scalable fonts.
	//        info              --  the font
	//        scale             --  controls the size of the resulting SDF bitmap, same as it would be creating a regular bitmap
	//        glyph/codepoint   --  the character to generate the SDF for
	//        padding           --  extra "pixels" around the character which are filled with the distance to the character (not 0),
	//                                 which allows effects like bit outlines
	//        onedge_value      --  value 0-255 to test the SDF against to reconstruct the character (i.e. the isocontour of the character)
	//        pixel_dist_scale  --  what value the SDF should increase by when moving one SDF "pixel" away from the edge (on the 0..255 scale)
	//                                 if positive, > onedge_value is inside; if negative, < onedge_value is inside
	//        width,height      --  output height & width of the SDF bitmap (including padding)
	//        xoff,yoff         --  output origin of the character
	//        return value      --  a 2D array of bytes 0..255, width*height in size
	//
	// pixel_dist_scale & onedge_value are a scale & bias that allows you to make
	// optimal use of the limited 0..255 for your application, trading off precision
	// and special effects. SDF values outside the range 0..255 are clamped to 0..255.
	//
	// Example:
	//      scale = stbtt_ScaleForPixelHeight(22)
	//      padding = 5
	//      onedge_value = 180
	//      pixel_dist_scale = 180/5.0 = 36.0
	//
	//      This will create an SDF bitmap in which the character is about 22 pixels
	//      high but the whole bitmap is about 22+5+5=32 pixels high. To produce a filled
	//      shape, sample the SDF at each pixel and fill the pixel if the SDF value
	//      is greater than or equal to 180/255. (You'll actually want to antialias,
	//      which is beyond the scope of this example.) Additionally, you can compute
	//      offset outlines (e.g. to stroke the character border inside & outside,
	//      or only outside). For example, to fill outside the character up to 3 SDF
	//      pixels, you would compare against (180-36.0*3)/255 = 72/255. The above
	//      choice of variables maps a range from 5 pixels outside the shape to
	//      2 pixels inside the shape to 0..255; this is intended primarily for apply
	//      outside effects only (the interior range is needed to allow proper
	//      antialiasing of the font at *smaller* sizes)
	//
	// The function computes the SDF analytically at each SDF pixel, not by e.g.
	// building a higher-res bitmap and approximating it. In theory the quality
	// should be as high as possible for an SDF of this size & representation, but
	// unclear if this is true in practice (perhaps building a higher-res bitmap
	// and computing from that can allow drop-out prevention).
	//
	// The algorithm has not been optimized at all, so expect it to be slow
	// if computing lots of characters or very large sizes.
	[CLink] public static extern c_uchar* stbtt_GetCodepointSDF(stbtt_fontinfo* info, float scale, c_int codepoint, c_int padding, c_uchar onedge_value, float pixel_dist_scale, c_int* width, c_int* height, c_int* xoff, c_int* yoff);

	//////////////////////////////////////////////////////////////////////////////
	//
	// Finding the right font...
	//
	// You should really just solve this offline, keep your own tables
	// of what font is what, and don't try to get it out of the .ttf file.
	// That's because getting it out of the .ttf file is really hard, because
	// the names in the file can appear in many possible encodings, in many
	// possible languages, and e.g. if you need a case-insensitive comparison,
	// the details of that depend on the encoding & language in a complex way
	// (actually underspecified in truetype, but also gigantic).
	//
	// But you can use the provided functions in two possible ways:
	//     stbtt_FindMatchingFont() will use *case-sensitive* comparisons on
	//             unicode-encoded names to try to find the font you want;
	//             you can run this before calling stbtt_InitFont()
	//
	//     stbtt_GetFontNameString() lets you get any of the various strings
	//             from the file yourself and do your own comparisons on them.
	//             You have to have called stbtt_InitFont() first.

	// returns the offset (not index) of the font that matches, or -1 if none
	//   if you use STBTT_MACSTYLE_DONTCARE, use a font name like "Arial Bold".
	//   if you use any other flag, use a font name like "Arial"; this checks
	//     the 'macStyle' header field; i don't know if fonts set this consistently
	[CLink] public static extern c_int stbtt_FindMatchingFont(c_uchar* fontdata, char8* name, c_int flags);

	const c_int STBTT_MACSTYLE_DONTCARE     = 0;
	const c_int STBTT_MACSTYLE_BOLD         = 1;
	const c_int STBTT_MACSTYLE_ITALIC       = 2;
	const c_int STBTT_MACSTYLE_UNDERSCORE   = 4;
	const c_int STBTT_MACSTYLE_NONE         = 8; // <= not same as 0, this makes us check the bitfield is 0

	// returns 1/0 whether the first string interpreted as utf8 is identical to
	// the second string interpreted as big-endian utf16... useful for strings from next func
	[CLink] public static extern c_int stbtt_CompareUTF8toUTF16_bigendian(char8* s1, c_int len1, char8* s2, c_int len2);

	// returns the string (which may be big-endian double byte, e.g. for unicode)
	// and puts the length in bytes in *length.
	//
	// some of the values for the IDs are below; for more see the truetype spec:
	//     http://developer.apple.com/textfonts/TTRefMan/RM06/Chap6name.html
	//     http://www.microsoft.com/typography/otspec/name.htm
	[CLink] public static extern char8* stbtt_GetFontNameString(stbtt_fontinfo* font, c_int* length, c_int platformID, c_int encodingID, c_int languageID, c_int nameID);

	// platformID
	public enum stbtt_platform_id : c_int
	{
		STBTT_PLATFORM_ID_UNICODE   = 0,
		STBTT_PLATFORM_ID_MAC       = 1,
		STBTT_PLATFORM_ID_ISO       = 2,
		STBTT_PLATFORM_ID_MICROSOFT = 3
	}

	// encodingID for STBTT_PLATFORM_ID_UNICODE
	public enum stbtt_encoding_id_uni : c_int
	{
		STBTT_UNICODE_EID_UNICODE_1_0    = 0,
		STBTT_UNICODE_EID_UNICODE_1_1    = 1,
		STBTT_UNICODE_EID_ISO_10646      = 2,
		STBTT_UNICODE_EID_UNICODE_2_0_BMP = 3,
		STBTT_UNICODE_EID_UNICODE_2_0_FULL = 4
	}

	// encodingID for STBTT_PLATFORM_ID_MICROSOFT
	public enum sbttt_encoding_id_ms : c_int
	{
		STBTT_MS_EID_SYMBOL        = 0,
		STBTT_MS_EID_UNICODE_BMP   = 1,
		STBTT_MS_EID_SHIFTJIS      = 2,
		STBTT_MS_EID_UNICODE_FULL  = 10
	}

	// encodingID for STBTT_PLATFORM_ID_MAC; same as Script Manager codes
	public enum sbttt_encoding_id_mac : c_int
	{
		STBTT_MAC_EID_ROMAN        = 0,
		STBTT_MAC_EID_ARABIC       = 4,
		STBTT_MAC_EID_JAPANESE     = 1,
		STBTT_MAC_EID_HEBREW       = 5,
		STBTT_MAC_EID_CHINESE_TRAD = 2,
		STBTT_MAC_EID_GREEK        = 6,
		STBTT_MAC_EID_KOREAN       = 3,
	}

	// languageID for STBTT_PLATFORM_ID_MICROSOFT; same as LCID...
	// problematic because there are e.g. 16 english LCIDs and 16 arabic LCIDs
	[CRepr, AllowDuplicates]
	public enum sbttt_language_id_ms : c_int
	{
		STBTT_MS_LANG_ENGLISH     = 0x0409,
		STBTT_MS_LANG_ITALIAN     = 0x0410,
		STBTT_MS_LANG_CHINESE     = 0x0804,
		STBTT_MS_LANG_JAPANESE    = 0x0411,
		STBTT_MS_LANG_DUTCH       = 0x0413,
		STBTT_MS_LANG_KOREAN      = 0x0412,
		STBTT_MS_LANG_FRENCH      = 0x040c,
		STBTT_MS_LANG_RUSSIAN     = 0x0419,
		STBTT_MS_LANG_GERMAN      = 0x0407,
		STBTT_MS_LANG_SPANISH     = 0x0409,
		STBTT_MS_LANG_HEBREW      = 0x040d,
		STBTT_MS_LANG_SWEDISH     = 0x041D
	}

	// languageID for STBTT_PLATFORM_ID_MAC
	public enum sbttt_language_id_mac : c_int
	{
		STBTT_MAC_LANG_ENGLISH      = 0,
		STBTT_MAC_LANG_JAPANESE     = 11,
		STBTT_MAC_LANG_ARABIC       = 12,
		STBTT_MAC_LANG_KOREAN       = 23,
		STBTT_MAC_LANG_DUTCH        = 4,
		STBTT_MAC_LANG_RUSSIAN      = 32,
		STBTT_MAC_LANG_FRENCH       = 1,
		STBTT_MAC_LANG_SPANISH      = 6,
		STBTT_MAC_LANG_GERMAN       = 2,
		STBTT_MAC_LANG_SWEDISH      = 5,
		STBTT_MAC_LANG_HEBREW       = 10,
		STBTT_MAC_LANG_CHINESE_SIMPLIFIED = 33,
		STBTT_MAC_LANG_ITALIAN      = 3,
		STBTT_MAC_LANG_CHINESE_TRAD = 19
	}
}