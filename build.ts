import { type Build } from 'xbuild';

const build: Build = {
    common: {
        project: 'stb',
        archs: ['x64'],
        variables: [],
        copy: {
            'stb/stb_image.h':'stb/stb_image.c',
            'stb/stb_image_resize2.h':'stb/stb_image_resize2.c',
            'stb/stb_image_write.h':'stb/stb_image_write.c',
            'stb/stb_rect_pack.h':'stb/stb_rect_pack.c',
            'stb/stb_truetype.h':'stb/stb_truetype.c'
        },
        defines: [
            'STB_IMAGE_IMPLEMENTATION',
            'STB_IMAGE_RESIZE_IMPLEMENTATION',
            'STB_IMAGE_WRITE_IMPLEMENTATION',
            'STB_RECT_PACT_IMPLEMENTATION',
            'STB_TRUETYPE_IMPLEMENTATION',
            'STB_VORBIS_IMPLEMENTATION'
        ],
        options: [],
        subdirectories: [],
        libraries: {
            stb_image: {
                sources: ['stb/stb_image.c'],
                outDir: 'stb_image/libs'
            },
            stb_image_resize2: {
                sources: ['stb/stb_image_resize2.c'],
                outDir: 'stb_image_resize2/libs'
            },
            stb_image_write: {
                sources: ['stb/stb_image_write.c'],
                outDir: 'stb_image_write/libs'
            },
            stb_rect_pack: {
                sources: ['stb/stb_rect_pack.c'],
                outDir: 'stb_rect_pack/libs'
            },
            stb_truetype: {
                sources: ['stb/stb_truetype.c'],
                outDir: 'stb_truetype/libs'
            },
            stb_vorbis: {
                sources: ['stb/stb_vorbis.c'],
                outDir: 'stb_vorbis/libs'
            }
        },
        buildDir: 'build',
        buildOutDir: 'libs',
        buildFlags: []
    },
    platforms: {
        win32: {
            windows: {},
            android: {
                archs: ['x86', 'x86_64', 'armeabi-v7a', 'arm64-v8a'],
            }
        },
        linux: {
            linux: {}
        },
        darwin: {
            macos: {}
        }
    }
}

export default build;