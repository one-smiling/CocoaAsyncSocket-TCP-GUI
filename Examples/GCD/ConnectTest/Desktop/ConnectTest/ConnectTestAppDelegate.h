#import <Cocoa/Cocoa.h>

@class GCDAsyncSocket;


@interface ConnectTestAppDelegate : NSObject <NSApplicationDelegate> {
@private
    long tag;

	GCDAsyncSocket *asyncSocket;
	
	NSWindow *__unsafe_unretained window;
}


@property (unsafe_unretained) IBOutlet NSWindow    * window;
@property  IBOutlet NSTextField * addrField;
@property  IBOutlet NSTextField * portField;
@property  IBOutlet NSTextField * messageField;
@property  IBOutlet NSButton    * sendButton;
@property  IBOutlet NSTextView  * logView;

- (IBAction)send:(id)sender;

@end
