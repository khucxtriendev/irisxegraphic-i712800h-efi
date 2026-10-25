// Uses public NSDockTile API on this diagnostic's own temporary Dock icon.
#import <AppKit/AppKit.h>
@interface ReferenceApp:NSObject<NSApplicationDelegate>
@property(strong) NSWindow *window;
@end
@implementation ReferenceApp
- (void)applicationDidFinishLaunching:(NSNotification*)notification {
    NSImage*icon=[NSImage imageWithSize:NSMakeSize(128,128) flipped:NO drawingHandler:^BOOL(NSRect rect){
        [[NSColor colorWithSRGBRed:0.1 green:0.4 blue:0.85 alpha:1]setFill];[[NSBezierPath bezierPathWithRoundedRect:rect xRadius:25 yRadius:25]fill];
        [@"P1" drawAtPoint:NSMakePoint(25,32) withAttributes:@{NSFontAttributeName:[NSFont boldSystemFontOfSize:56],NSForegroundColorAttributeName:NSColor.whiteColor}];return YES;
    }];
    [NSApp setApplicationIconImage:icon];NSApp.dockTile.badgeLabel=@"12";[NSApp.dockTile display];
    self.window=[[NSWindow alloc]initWithContentRect:NSMakeRect(0,0,540,180) styleMask:NSWindowStyleMaskTitled|NSWindowStyleMaskClosable backing:NSBackingStoreBuffered defer:NO];
    self.window.title=@"P1 — kiểm tra chữ số trên Dock";
    NSTextField*text=[NSTextField wrappingLabelWithString:@"Nhìn biểu tượng P1 màu xanh trên Dock.\nBadge đỏ có hiện chữ số 12 không?\n\nBáo lại: “P1 có số 12” hoặc “P1 cũng mất số”.\nĐóng cửa sổ này để kết thúc kiểm tra."];
    text.frame=NSMakeRect(22,20,496,140);text.font=[NSFont systemFontOfSize:16];[self.window.contentView addSubview:text];
    [self.window center];[self.window makeKeyAndOrderFront:nil];[NSApp activateIgnoringOtherApps:YES];
    NSString*path=[NSHomeDirectory()stringByAppendingPathComponent:@"Documents/gen5_igpu_driver/reports/dock-investigation/dock-reference.json"];
    NSDictionary*report=@{ @"date":NSDate.date.description,@"requested_badge_label":@"12",@"own_dock_tile_label":NSApp.dockTile.badgeLabel?:@"nil",@"visual_result":@"User observation required" };
    [[NSJSONSerialization dataWithJSONObject:report options:NSJSONWritingPrettyPrinted error:nil]writeToFile:path atomically:YES];
}
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication*)sender{return YES;}
@end
int main(void){@autoreleasepool{NSApplication*application=[NSApplication sharedApplication];[application setActivationPolicy:NSApplicationActivationPolicyRegular];ReferenceApp*delegate=[ReferenceApp new];application.delegate=delegate;[application run];return 0;}}
