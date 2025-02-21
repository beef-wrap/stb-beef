copy stb\stb_image.h stb_image.c
clang -c -o stb_image-windows.lib -target x86_64-pc-windows -fuse-ld=llvm-lib -DSTB_IMAGE_IMPLEMENTATION stb_image.c
mkdir stb_image\libs
move stb_image-windows.lib stb_image\libs
del stb_image.c

copy stb\stb_image_resize2.h stb_image_resize2.h
copy stb\stb_image_resize2.h stb_image_resize2.c
clang -c -o stb_image_resize2-windows.lib -target x86_64-pc-windows -fuse-ld=llvm-lib -DSTB_IMAGE_RESIZE_IMPLEMENTATION stb_image_resize2.c
mkdir stb_image_resize2\libs
move stb_image_resize2-windows.lib stb_image_resize2\libs
del stb_image_resize2.h
del stb_image_resize2.c

copy stb\stb_image_write.h stb_image_write.c
clang -c -o stb_image_write-windows.lib -target x86_64-pc-windows -fuse-ld=llvm-lib -DSTB_IMAGE_WRITE_IMPLEMENTATION stb_image_write.c
mkdir stb_image_write\libs
move stb_image_write-windows.lib stb_image_write\libs
del stb_image_write.c

copy stb\stb_rect_pack.h stb_rect_pack.c
clang -c -o stb_rect_pack-windows.lib -target x86_64-pc-windows -fuse-ld=llvm-lib -DSTB_RECT_PACK_IMPLEMENTATION stb_rect_pack.c
mkdir stb_rect_pack\libs
move stb_rect_pack-windows.lib stb_rect_pack\libs
del stb_rect_pack.c

copy stb\stb_truetype.h stb_truetype.c
clang -c -o stb_truetype-windows.lib -target x86_64-pc-windows -fuse-ld=llvm-lib -DSTB_TRUETYPE_IMPLEMENTATION stb_truetype.c
mkdir stb_truetype\libs
move stb_truetype-windows.lib stb_truetype\libs
del stb_truetype.c

copy stb\stb_vorbis.c stb_vorbis.c
clang -c -o stb_vorbis-windows.lib -target x86_64-pc-windows -fuse-ld=llvm-lib -DSTB_VORBIS_IMPLEMENTATION stb_vorbis.c
mkdir stb_vorbis\libs
move stb_vorbis-windows.lib stb_vorbis\libs
del stb_vorbis.c