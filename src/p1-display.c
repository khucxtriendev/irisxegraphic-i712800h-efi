// Select exact modes through CoreGraphics; no raw register writes or nearest-mode fallback.
#include <CoreGraphics/CoreGraphics.h>
#include <errno.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int failure(const char *operation, CGError code) {
    fprintf(stderr, "%s failed (CoreGraphics %d).\n", operation, code);
    return 1;
}

int main(int argc, char **argv) {
    bool apply = false, native = false, permanent = false;
    unsigned wanted_w = 0, wanted_h = 0;
    if (argc > 1) {
        if (!strcmp(argv[1], "--help")) {
            puts("p1-display                       list main-display modes\n"
                 "p1-display --set 1440x900         exact 2x HiDPI, this session\n"
                 "p1-display --set 1280x800         exact 2x HiDPI, this session\n"
                 "p1-display --native               native 2560x1600 at 1x\n"
                 "Add --permanent to save across logins. No matching mode = no change.");
            return 0;
        }
        if (!strcmp(argv[1], "--native")) {
            native = apply = true;
            wanted_w = 2560; wanted_h = 1600;
            if (argc == 3 && !strcmp(argv[2], "--permanent")) permanent = true;
            else if (argc != 2) { fputs("Invalid arguments. Use --help.\n", stderr); return 2; }
        } else if (!strcmp(argv[1], "--set") && argc >= 3) {
            char tail;
            if (sscanf(argv[2], "%ux%u%c", &wanted_w, &wanted_h, &tail) != 2 || !wanted_w || !wanted_h) {
                fputs("Expected WIDTHxHEIGHT, e.g. 1440x900.\n", stderr); return 2;
            }
            if (argc == 4 && !strcmp(argv[3], "--permanent")) permanent = true;
            else if (argc != 3) { fputs("Invalid arguments. Use --help.\n", stderr); return 2; }
            apply = true;
        } else { fputs("Invalid arguments. Use --help.\n", stderr); return 2; }
    }
    CGDirectDisplayID display = CGMainDisplayID();
    if (!display) {
        fputs("No accessible display. Run in Terminal in the logged-in desktop session.\n", stderr);
        return 3;
    }
    const void *keys[] = { kCGDisplayShowDuplicateLowResolutionModes };
    const void *values[] = { kCFBooleanTrue };
    CFDictionaryRef options = CFDictionaryCreate(NULL, keys, values, 1,
        &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFArrayRef modes = CGDisplayCopyAllDisplayModes(display, options);
    CFRelease(options);
    if (!modes) { fputs("Cannot enumerate display modes.\n", stderr); return 3; }
    CGDisplayModeRef current = CGDisplayCopyDisplayMode(display), target = NULL;
    for (CFIndex i = 0; i < CFArrayGetCount(modes); i++) {
        CGDisplayModeRef mode = (CGDisplayModeRef)CFArrayGetValueAtIndex(modes, i);
        size_t w = CGDisplayModeGetWidth(mode), h = CGDisplayModeGetHeight(mode);
        size_t pw = CGDisplayModeGetPixelWidth(mode), ph = CGDisplayModeGetPixelHeight(mode);
        double hz = CGDisplayModeGetRefreshRate(mode);
        bool selected = current && CGDisplayModeGetIODisplayModeID(mode) == CGDisplayModeGetIODisplayModeID(current);
        if (!apply) {
            printf("%c %zux%zu logical | %zux%zu rendered | scale %.2fx | ", selected ? '*' : ' ', w, h, pw, ph, w ? (double)pw/w : 0);
            if (hz > 0) printf("%.2f Hz\n", hz); else puts("refresh not reported");
        }
        if (apply && w == wanted_w && h == wanted_h &&
            pw == (native ? w : w*2) && ph == (native ? h : h*2) &&
            CGDisplayModeIsUsableForDesktopGUI(mode)) {
            // Prefer the current matching mode; otherwise the highest reported refresh.
            if (selected || (!target || hz > CGDisplayModeGetRefreshRate(target))) target = mode;
            if (selected) break;
        }
    }
    int rc = 0;
    if (apply && !target) {
        fprintf(stderr, "Exact %ux%u %s mode unavailable; nothing changed.\n", wanted_w, wanted_h, native ? "1x" : "2x HiDPI");
        rc = 4;
    } else if (apply) {
        CGDisplayConfigRef config;
        CGError e = CGBeginDisplayConfiguration(&config);
        if (e != kCGErrorSuccess) rc = failure("Begin configuration", e);
        else {
            e = CGConfigureDisplayWithDisplayMode(config, display, target, NULL);
            if (e != kCGErrorSuccess) {
                CGCancelDisplayConfiguration(config); rc = failure("Select mode", e);
            } else {
                e = CGCompleteDisplayConfiguration(config, permanent ? kCGConfigurePermanently : kCGConfigureForSession);
                if (e != kCGErrorSuccess) rc = failure("Apply mode", e);
                else printf("Applied %ux%u %s (%s).\n", wanted_w, wanted_h, native ? "1x" : "2x HiDPI", permanent ? "saved" : "this session");
            }
        }
    }
    if (current) CFRelease(current);
    CFRelease(modes);
    return rc;
}
