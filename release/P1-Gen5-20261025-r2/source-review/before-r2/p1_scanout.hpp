#ifndef P1_SCANOUT_HPP
#define P1_SCANOUT_HPP
#include <stdint.h>

namespace P1Scanout {
constexpr uint32_t PageSize = 4096;
constexpr uint32_t StartPage = 4096;
constexpr uint32_t PagesPerSlot = 6144;
constexpr uint32_t SlotCount = 6;
constexpr uint32_t GuardPages = 128;
constexpr uint32_t MinMappedPages = 4096;
constexpr uint32_t MaxDataPages = PagesPerSlot - GuardPages;
constexpr uint64_t PoolStart = uint64_t(StartPage) * PageSize;
constexpr uint64_t PoolBytes = uint64_t(PagesPerSlot) * SlotCount * PageSize;
constexpr uint64_t PoolEnd = PoolStart + PoolBytes;
constexpr uint64_t PteBase = 0x800000;

struct AddressRange { uint64_t start, length; };
static_assert(sizeof(AddressRange) == 16, "IGAddressRange ABI is two 64-bit values");
static_assert(StartPage > 0x18, "Scanout aliases must not cover scratch/LRCA low pages");
static_assert(PagesPerSlot >= MinMappedPages + GuardPages, "Alias padding must fit");
static_assert(StartPage % 16 == 0 && PagesPerSlot % 16 == 0, "Slots require 64 KiB alignment");
static_assert(PoolEnd <= 0x100000000ULL, "Primary-plane SURF address must fit 32 bits");

// Intersect without overflowing an incoming canonical-address range.
inline AddressRange overlap(AddressRange range) {
    if (!range.length || range.start >= PoolEnd) return {0, 0};
    const uint64_t start = range.start > PoolStart ? range.start : PoolStart;
    const uint64_t available = PoolEnd - range.start;
    const uint64_t end = range.length >= available ? PoolEnd : range.start + range.length;
    return end > start ? AddressRange{start, end - start} : AddressRange{0, 0};
}

struct Layout {
    uint32_t ctl, stride, size, offset, dataPages;
    bool equals(const Layout &other) const {
        return ctl == other.ctl && stride == other.stride && size == other.size &&
            offset == other.offset && dataPages == other.dataPages;
    }
};

inline bool layout(uint32_t ctl, uint32_t stride, uint32_t size, uint32_t offset, Layout &out) {
    // P1's uncompressed linear/X-tiled primary plane only. Never guess other layouts.
    const uint32_t tiling = (ctl >> 10) & 7;
    const uint32_t format = (ctl >> 23) & 31;
    const uint32_t bpp = format == 8 || format == 4 ? 4 : format == 12 ? 8 : format == 28 ? 2 : 0;
    if ((ctl & (3U | (1U << 15) | (1U << 4))) || offset || !bpp ||
        (tiling != 0 && tiling != 1)) return false;
    const uint64_t units = stride & 0xfff;
    const uint64_t height = uint64_t(size >> 16) + 1;
    const uint64_t width = uint64_t(size & 0xffff) + 1;
    if (!units || height > 8192 || width > 8192) return false;
    const uint64_t pitch = units * (tiling == 0 ? 64 : 512);
    if (pitch < width * bpp) return false;
    const uint64_t rows = tiling == 1 ? (height + 7) & ~uint64_t(7) : height;
    const uint64_t pages = (pitch * rows + PageSize - 1) / PageSize;
    if (!pages || pages > MaxDataPages) return false; // Reject, never truncate.
    out = {ctl & 0x0f800d03U, stride, size, offset, uint32_t(pages)};
    return true;
}

class Cache {
    struct Slot {
        bool valid;
        uint32_t sourcePage;
        Layout layout;
        uint64_t age;
    } slots[SlotCount] {};
    uint64_t snapshot[MaxDataPages] {};
    uint64_t clock {0};
    uint32_t generation {0}, lastArmed {0};
    uintptr_t owner {0};
    volatile int busy {0};

    template<class IO> static bool readPte(IO &io, uint32_t page, uint64_t &value) {
        const uint64_t reg = PteBase + uint64_t(page) * 8;
        if (reg + 8 > io.mmioBytes()) return false;
        // Reject an unstable split PTE instead of combining two different mappings.
        for (unsigned attempt = 0; attempt < 2; ++attempt) {
            const uint32_t lo = io.read32(reg), hi = io.read32(reg + 4);
            if (lo == io.read32(reg) && hi == io.read32(reg + 4)) {
                value = (uint64_t(hi) << 32) | lo;
                return true;
            }
        }
        return false;
    }
    static uint32_t address(unsigned slot) {
        return (StartPage + slot * PagesPerSlot) * PageSize;
    }
    struct Unlock {
        volatile int *lock;
        ~Unlock() { __sync_lock_release(lock); }
    };
public:
    // IO supplies a real allocator-reservation state; an aperture size alone is insufficient.
    template<class IO> bool redirect(IO &io, uint32_t source, uint32_t &result) {
        if (!io.reserved() || io.apertureBytes() < PoolEnd ||
            PteBase + (PoolEnd / PageSize) * 8 > io.mmioBytes()) return false;
        if (!__sync_bool_compare_and_swap(&busy, 0, 1)) return false;
        Unlock unlock {&busy};
        const uint32_t epoch = io.epoch();
        if (generation != epoch || owner != io.owner()) {
            for (auto &slot : slots) slot.valid = false;
            generation = epoch; owner = io.owner();
        }
        Layout view;
        if (!layout(io.read32(0x70180), io.read32(0x70188), io.read32(0x70190),
                    io.read32(0x701a4), view)) return false;
        const uint32_t sourcePage = source >> 12;
        if (PteBase + (uint64_t(sourcePage) + view.dataPages) * 8 > io.mmioBytes()) return false;
        for (uint32_t i = 0; i < view.dataPages; ++i) {
            if (!readPte(io, sourcePage + i, snapshot[i]) || !(snapshot[i] & 1)) return false;
        }
        if (epoch != io.epoch()) return false;
        const uint64_t padding = snapshot[view.dataPages - 1];
        // A hit must still refer to the same physical pages and intact destination PTEs.
        // This intentionally performs reads; it is not a claim of "zero MMIO".
        for (unsigned s = 0; s < SlotCount; ++s) {
            auto &slot = slots[s];
            if (!slot.valid || slot.sourcePage != sourcePage || !slot.layout.equals(view)) continue;
            bool same = true;
            for (uint32_t i = 0; i < PagesPerSlot; ++i) {
                uint64_t actual;
                const uint64_t expected = i < view.dataPages ? snapshot[i] : padding;
                if (!readPte(io, StartPage + s * PagesPerSlot + i, actual) || actual != expected) {
                    same = false; break;
                }
            }
            if (same && epoch == io.epoch()) {
                slot.age = ++clock;
                lastArmed = address(s);
                result = lastArmed | (source & 0xfff);
                return true; // No PTE writes on a validated hit.
            }
        }
        const uint32_t live = io.read32(0x701ac) & 0xfffff000;
        const uint32_t armed = io.read32(0x7019c) & 0xfffff000;
        int selected = -1;
        uint64_t oldest = ~uint64_t(0);
        for (unsigned s = 0; s < SlotCount; ++s) {
            const uint32_t dest = address(s);
            const uint64_t end = uint64_t(dest) + uint64_t(PagesPerSlot) * PageSize;
            const uint64_t activeSpan = uint64_t(PagesPerSlot) * PageSize;
            // Protect ranges, including a native boot surface starting below the pool.
            if ((uint64_t(dest) < uint64_t(live) + activeSpan && live < end) ||
                (uint64_t(dest) < uint64_t(armed) + activeSpan && armed < end) ||
                (lastArmed && dest == lastArmed)) continue;
            if (!slots[s].valid) { selected = int(s); break; }
            if (slots[s].age < oldest) { oldest = slots[s].age; selected = int(s); }
        }
        if (selected < 0 || epoch != io.epoch()) return false;
        const uint32_t base = StartPage + uint32_t(selected) * PagesPerSlot;
        slots[selected].valid = false;
        // All source PTEs were validated before the first write. Fill only alias padding
        // with the last page; do not invent missing display data or scan into a neighbour.
        for (uint32_t i = 0; i < PagesPerSlot; ++i) {
            const uint64_t pte = i < view.dataPages ? snapshot[i] : padding;
            const uint64_t reg = PteBase + uint64_t(base + i) * 8;
            io.write32(reg + 4, uint32_t(pte >> 32));
            io.write32(reg, uint32_t(pte));
        }
        io.write32(0x101008, 1);
        (void)io.read32(0x101008); // Posting read before the caller arms SURF.
        if (epoch != io.epoch()) return false;
        slots[selected] = {true, sourcePage, view, ++clock};
        lastArmed = address(unsigned(selected));
        result = lastArmed | (source & 0xfff);
        return true;
    }
};
}
#endif
