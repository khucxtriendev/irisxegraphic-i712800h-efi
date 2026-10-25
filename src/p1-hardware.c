#include <cpuid.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <sys/sysctl.h>

int main(void) {
    unsigned a, b, c, d;
    char brand[49] = {0};
    for (unsigned i = 0; i < 3; i++) {
        __cpuid(0x80000002u + i, a, b, c, d);
        memcpy(brand+i*16, &a, 4); memcpy(brand+i*16+4, &b, 4);
        memcpy(brand+i*16+8, &c, 4); memcpy(brand+i*16+12, &d, 4);
    }
    printf("Hardware CPUID brand: %s\n", brand);
    __cpuid(1, a, b, c, d);
    printf("Hardware CPUID signature: 0x%08x\n", a);
    const char *names[] = {"hw.physicalcpu", "hw.logicalcpu", "hw.memsize", "machdep.xcpm.mode", NULL};
    for (unsigned i = 0; names[i]; i++) {
        uint64_t value = 0; size_t length = sizeof(value);
        if (!sysctlbyname(names[i], &value, &length, NULL, 0)) printf("%s: %llu\n", names[i], (unsigned long long)value);
        else printf("%s: inaccessible\n", names[i]);
    }
    return 0;
}
