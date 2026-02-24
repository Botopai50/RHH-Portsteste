// ============================================================================
//  Simpsons: Hit & Run – Fake Disk Space Shim
//
//  HACK: The game’s disk space math explodes on modern large SD cards and decides
//  the drive is full. This shim reports a safe, boring 512MB drive instead.
//
//  Manual saves work. Autosaves still complain.
//
// In a game full of big, stinky hacks… what’s one more?
//
// Compile with gcc -fPIC -shared -o libfakespace.so fake_space.c -ldl on debian bullseye
//
//  Related bug:
//  https://github.com/ZenoArrows/The-Simpsons-Hit-and-Run/blob/master/libs/radcore/src/radfile/win32/win32drive.cpp#L605
// ============================================================================

#define _GNU_SOURCE
#include <dlfcn.h>
#include <sys/statvfs.h>
#include <sys/vfs.h>
#include <unistd.h>
#include <stdio.h>
#include <string.h>

#define FAKE_BLOCK_SIZE 16384
#define FAKE_TOTAL_BLOCKS 8192
#define FAKE_FREE_BLOCKS  4096

static void apply_fake_stats(void *buf, int is_vfs) {
    if (is_vfs) {
        struct statvfs *v = (struct statvfs *)buf;
        v->f_bsize = v->f_frsize = FAKE_BLOCK_SIZE;
        v->f_blocks = FAKE_TOTAL_BLOCKS; 
        v->f_bfree = v->f_bavail = FAKE_FREE_BLOCKS;
        v->f_fsid = 1337;
    } else {
        struct statfs *s = (struct statfs *)buf;
        s->f_bsize = FAKE_BLOCK_SIZE;
        s->f_blocks = FAKE_TOTAL_BLOCKS; 
        s->f_bfree = s->f_bavail = FAKE_FREE_BLOCKS;
    }
}

// Intercept path-based statvfs
int statvfs(const char *path, struct statvfs *buf) {
    static int (*o)(const char*, struct statvfs*) = NULL;
    if (!o) o = dlsym(RTLD_NEXT, "statvfs");
    int r = o(path, buf);
    if (r == 0 && buf) apply_fake_stats(buf, 1);
    return r;
}

// Intercept path-based statfs
int statfs(const char *path, struct statfs *buf) {
    static int (*o)(const char*, struct statfs*) = NULL;
    if (!o) o = dlsym(RTLD_NEXT, "statfs");
    int r = o(path, buf);
    if (r == 0 && buf) apply_fake_stats(buf, 0);
    return r;
}

// 64-bit variants
int statfs64(const char *path, struct statfs64 *buf) {
    static int (*o)(const char*, struct statfs64*) = NULL;
    if (!o) o = dlsym(RTLD_NEXT, "statfs64");
    int r = o(path, buf);
    if (r == 0 && buf) apply_fake_stats(buf, 0);
    return r;
}

int statvfs64(const char *path, struct statvfs64 *buf) {
    static int (*o)(const char*, struct statvfs64*) = NULL;
    if (!o) o = dlsym(RTLD_NEXT, "statvfs64");
    int r = o(path, buf);
    if (r == 0 && buf) apply_fake_stats(buf, 1);
    return r;
}

// File descriptor variants
int fstatfs(int fd, struct statfs *buf) {
    static int (*o)(int, struct statfs*) = NULL;
    if (!o) o = dlsym(RTLD_NEXT, "fstatfs");
    int r = o(fd, buf);
    if (r == 0 && buf) apply_fake_stats(buf, 0);
    return r;
}

int fstatfs64(int fd, struct statfs64 *buf) {
    static int (*o)(int, struct statfs64*) = NULL;
    if (!o) o = dlsym(RTLD_NEXT, "fstatfs64");
    int r = o(fd, buf);
    if (r == 0 && buf) apply_fake_stats(buf, 0);
    return r;
}
