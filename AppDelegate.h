// AppDelegate.h
#import <Cocoa/Cocoa.h>

// Declare the AppDelegate interface.
// It conforms to NSApplicationDelegate, NSWindowDelegate,
// and NSWindowRestoration to handle app lifecycle, window events,
// and window state restoration. It also conforms to NSTextViewDelegate
// to receive text view notifications directly.
@interface AppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate, NSWindowRestoration, NSTextViewDelegate> // Added NSTextViewDelegate

// Property to hold the main text view where editing happens.
@property (strong) NSTextView *textView;
// Property to hold the scroll view containing the text view.
@property (strong) NSScrollView *scrollView;
// Property to hold the status label.
@property (strong) NSTextField *statusLabel;
// Property to hold the menu item for toggling the status bar
@property (strong) NSMenuItem *statusBarMenuItem;
// Property to hold the menu item for toggling line numbers (Placeholder)
@property (strong) NSMenuItem *lineNumbersMenuItem;
// Property to hold the current file path
@property (nonatomic, strong) NSString *currentFilePath;


@end

