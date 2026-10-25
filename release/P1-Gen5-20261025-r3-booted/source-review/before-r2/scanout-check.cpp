#include "../vendor/iris-xe/src/NootedGreen/p1_scanout.hpp"
#include <cassert>
#include <cstdio>
#include <map>
#include <vector>

struct IO {
    std::map<uint64_t,uint32_t> words;
    std::vector<uint64_t> written;
    bool leased=true;
    uint64_t aperture=256ULL<<20, mmio=16ULL<<20;
    uint32_t generation=1;
    uint32_t read32(uint64_t r) { return words[r]; }
    void write32(uint64_t r,uint32_t v) { words[r]=v; written.push_back(r); }
    uint64_t apertureBytes() const { return aperture; }
    uint64_t mmioBytes() const { return mmio; }
    uintptr_t owner() const { return 1; }
    uint32_t epoch() const { return generation; }
    bool reserved() const { return leased; }
    IO() {
        words[0x70180]=0x84000000;
        words[0x70188]=160;
        words[0x70190]=(1599U<<16)|2559;
    }
    void putPte(uint32_t page,uint64_t value) {
        words[P1Scanout::PteBase+uint64_t(page)*8]=uint32_t(value);
        words[P1Scanout::PteBase+uint64_t(page)*8+4]=uint32_t(value>>32);
    }
    uint64_t pte(uint32_t page) {
        const uint64_t r=P1Scanout::PteBase+uint64_t(page)*8;
        return (uint64_t(words[r+4])<<32)|words[r];
    }
    void source(uint32_t surf,uint64_t physical,unsigned count) {
        for(unsigned i=0;i<count;i++) putPte((surf>>12)+i,physical+uint64_t(i)*4096+1);
    }
    void activate(uint32_t surf) { words[0x701ac]=surf; words[0x7019c]=surf; }
};
int main() {
    using namespace P1Scanout;
    assert(overlap({0,16ULL<<20}).length==0);
    assert(overlap({0,64ULL<<20}).start==(16ULL<<20));
    assert(overlap({0,64ULL<<20}).length==(48ULL<<20));
    assert(overlap({64ULL<<20,4ULL<<30}).length==(96ULL<<20));
    assert(overlap({0,~uint64_t(0)}).length==PoolBytes);
    assert(overlap({0xffff800000000000ULL,0x840000000000ULL}).length==0);
    Layout view;
    assert(layout(0x84000000,160,(1599U<<16)|2559,0,view)&&view.dataPages==4000);
    assert(layout(0x84000000,184,(1799U<<16)|2879,0,view)&&view.dataPages==5175);
    assert(!layout(0x84000000,256,(1799U<<16)|2879,0,view));
    assert(!layout(0x84000000,160,(1599U<<16)|2559,1,view));
    assert(!layout(0x81000000,160,(1599U<<16)|2559,0,view)); // NV12 needs an auxiliary plane.
    Cache cache;
    IO io;
    const uint32_t a=0x10000000;
    io.source(a,0x100000000ULL,6000);
    uint32_t first=0;
    assert(cache.redirect(io,a,first));
    assert(first>=PoolStart&&first<PoolEnd&&first!=0);
    assert(io.pte(first/4096+3999)==io.pte(a/4096+3999));
    assert(io.pte(first/4096+4000)==io.pte(a/4096+3999)); // Do not scan adjacent valid objects.
    assert(io.pte(first/4096+PagesPerSlot-1)==io.pte(a/4096+3999));
    io.activate(first);io.written.clear();uint32_t hit=0;
    assert(cache.redirect(io,a,hit)&&hit==first&&io.written.empty());
    const uint64_t old=io.pte(first/4096+2000);
    io.putPte(a/4096+2000,0x200001001ULL); // Same VA, new backing in the middle.
    uint32_t moved=0;
    assert(cache.redirect(io,a,moved)&&moved!=first);
    assert(io.pte(first/4096+2000)==old); // Never rewrite the live alias.
    assert(io.pte(moved/4096+2000)==0x200001001ULL);
    io.activate(moved);
    for(unsigned i=1;i<=8;i++) {
        uint32_t surf=a+i*0x02000000, next=0;
        io.source(surf,0x300000000ULL+uint64_t(i)*0x02000000,4000);
        const uint32_t live=io.words[0x701ac];io.written.clear();
        assert(cache.redirect(io,surf,next)&&next!=live);
        for(uint64_t r:io.written) if(r>=PteBase) {
            uint64_t page=(r-PteBase)/8;
            assert(page<live/4096||page>=live/4096+PagesPerSlot);
        }
        io.activate(next);
    }
    IO invalid;Cache fresh;uint32_t untouched=123;
    invalid.source(a,0x100000000ULL,4000);invalid.putPte(a/4096+2500,0);
    assert(!fresh.redirect(invalid,a,untouched)&&untouched==123&&invalid.written.empty());
    invalid.leased=false;assert(!fresh.redirect(invalid,a,untouched)&&invalid.written.empty());
    invalid.leased=true;invalid.aperture=64ULL<<20;
    assert(!fresh.redirect(invalid,a,untouched)&&invalid.written.empty());
    IO hdpi;Cache scaled;hdpi.words[0x70188]=184;hdpi.words[0x70190]=(1799U<<16)|2879;
    hdpi.source(a,0x500000000ULL,5175);
    uint32_t surface=0;assert(scaled.redirect(hdpi,a,surface));
    hdpi.activate(surface);hdpi.generation++;hdpi.written.clear();uint32_t afterReset=0;
    assert(scaled.redirect(hdpi,a,afterReset)&&afterReset!=surface&&!hdpi.written.empty());
    puts("PASS: reservation intersections, stride, bounds, stale VA, live-slot protection, cache hit, invalid PTE, HiDPI and reset; CPU only.");
}
