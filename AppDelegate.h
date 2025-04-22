// AppDelegate.h
#import <Cocoa/Cocoa.h>

// Declare the AppDelegate interface.
// It conforms to NSApplicationDelegate, NSWindowDelegate,
// and NSWindowRestoration to handle app lifecycle, window events,
// and window state restoration.
@interface AppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate, NSWindowRestoration> // <-- Added NSWindowRestoration

// Property to hold the main text view where editing happens.
@property (strong) NSTextView *textView;
// Property to hold the scroll view containing the text view.
@property (strong) NSScrollView *scrollView;


@end

