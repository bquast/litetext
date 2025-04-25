// AppDelegate.m
#import "AppDelegate.h"

// Define keys for UserDefaults
static NSString * const kStatusBarVisibleKey = @"statusBarVisible";

// Private interface category
@interface AppDelegate ()
// Only declare properties or methods truly private to the AppDelegate implementation here.
// Standard selectors handled by the responder chain should NOT be declared here.

// Private property to hold the main application window.
@property (strong) NSWindow *window;
@end

@implementation AppDelegate

// Called when the application finishes launching.
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // --- Window Setup ---
    self.window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 600, 400)
                                              styleMask:(NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable)
                                                backing:NSBackingStoreBuffered
                                                  defer:NO];
    [self.window center];
    [self.window setTitle:@"litetext"];
    [self.window setDelegate:self];
    [self.window setRestorable:YES];
    self.window.identifier = @"litetextMainWindow";
    [self.window setRestorationClass:[self class]];

    // --- Status Label Setup ---
    CGFloat statusBarHeight = 22.0; // Height for the status bar label
    // Initial frame setup - will be adjusted in applyStatusBarVisibility
    self.statusLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, self.window.contentView.bounds.size.width, statusBarHeight)];
    [self.statusLabel setEditable:NO];
    [self.statusLabel setSelectable:NO];
    [self.statusLabel setBezeled:NO];
    [self.statusLabel setDrawsBackground:NO];
    [self.statusLabel setAlignment:NSTextAlignmentRight];
    [self.statusLabel setTextColor:[NSColor secondaryLabelColor]];
    // Use monospaced font, small size
    [self.statusLabel setFont:[NSFont userFixedPitchFontOfSize:[NSFont smallSystemFontSize]]];
    // Autoresizing: Stick to bottom, left, right edges. Flexible width.
    [self.statusLabel setAutoresizingMask:(NSViewWidthSizable | NSViewMaxYMargin)];
    // Add status label to the window's content view
    [self.window.contentView addSubview:self.statusLabel];

    // --- ScrollView and TextView Setup ---
    // Frame is calculated later based on status bar visibility
    self.scrollView = [[NSScrollView alloc] initWithFrame:NSZeroRect]; // Start with zero rect
    // Autoresizing: Stick to top/left/right, flexible height
    [self.scrollView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable | NSViewMinYMargin)];
    [self.scrollView setHasVerticalScroller:YES];
    [self.scrollView setHasHorizontalScroller:YES];
    [self.scrollView setBorderType:NSNoBorder];

    // Use the content size of the scroll view for the text view frame
    // Note: TextView frame will be adjusted by the scroll view
    self.textView = [[NSTextView alloc] initWithFrame:NSZeroRect];

    // Configure text view properties
    [self.textView setMinSize:NSMakeSize(0.0, 0.0)]; // Let scrollview handle min size based on content
    [self.textView setMaxSize:NSMakeSize(FLT_MAX, FLT_MAX)];
    [self.textView setVerticallyResizable:YES];
    [self.textView setHorizontallyResizable:NO];
    [self.textView setAutoresizingMask:NSViewWidthSizable]; // Only resize width with scroll view
    [[self.textView textContainer] setWidthTracksTextView:YES];
    [[self.textView textContainer] setContainerSize:NSMakeSize(FLT_MAX, FLT_MAX)]; // Allow infinite size

    [self.textView setFont:[NSFont userFixedPitchFontOfSize:12.0]]; // Main text view font
    [self.textView setContinuousSpellCheckingEnabled:YES];
    [self.textView setAutomaticQuoteSubstitutionEnabled:NO];
    [self.textView setAutomaticDashSubstitutionEnabled:NO];
    [self.textView setAllowsUndo:YES];

    // Set the text view's delegate to self to receive selection change notifications
    self.textView.delegate = self;

    // Embed the text view within the scroll view.
    [self.scrollView setDocumentView:self.textView];

    // Add the scroll view to the window's content view (above the status label)
    [self.window.contentView addSubview:self.scrollView];


    // --- Menu Setup ---
    [self setupMainMenu]; // Setup menus *before* applying initial status bar state

    // --- Apply Initial Status Bar State ---
    [self applyStatusBarVisibility]; // Sets visibility and adjusts layout

    // --- Initial Status Update ---
    [self updateStatusLabel]; // Update status label initially

    // --- Final Window Display ---
    [self.window makeKeyAndOrderFront:nil];
}

// Delegate method called when the text view's selection changes
- (void)textViewDidChangeSelection:(NSNotification *)notification {
    [self updateStatusLabel];
}

// Calculates and updates the status label text
- (void)updateStatusLabel {
    if (!self.textView || !self.statusLabel || self.statusLabel.isHidden) {
        // Don't update if hidden or not ready
        if(self.statusLabel) self.statusLabel.stringValue = @""; // Clear if hidden
        return;
    }

    NSRange selectedRange = [self.textView selectedRange];
    NSString *text = self.textView.string;

    // Handle case where text might be nil or empty
    if (!text) text = @"";

    NSUInteger cursorPosition = selectedRange.location;
    // Ensure cursorPosition is within bounds
    if (cursorPosition > text.length) {
        cursorPosition = text.length;
    }


    // Calculate line number
    NSUInteger lineNumber = 1;
    NSUInteger currentPosition = 0;
    NSRange searchRange = NSMakeRange(0, cursorPosition);
    while (currentPosition < cursorPosition) {
        NSRange newlineRange = [text rangeOfString:@"\n"
                                            options:0
                                              range:searchRange];
        if (newlineRange.location == NSNotFound || newlineRange.location >= cursorPosition) {
            break; // No more newlines before cursor
        }
        lineNumber++;
        currentPosition = NSMaxRange(newlineRange);
        // Adjust search range for next iteration
        if (currentPosition < cursorPosition) {
             searchRange = NSMakeRange(currentPosition, cursorPosition - currentPosition);
        } else {
            break; // Avoid infinite loop if cursor is right after newline
        }
    }

    // Calculate column number
    NSRange lineRange = [text lineRangeForRange:NSMakeRange(cursorPosition, 0)];
    NSUInteger columnNumber = cursorPosition - lineRange.location + 1;

    // Update the label with spaces and no comma
    // No extra padding spaces needed here now, frame adjustment handles it.
    self.statusLabel.stringValue = [NSString stringWithFormat:@"Line: %lu   Col: %lu", (unsigned long)lineNumber, (unsigned long)columnNumber];
}

// Action method for the "Show Status Bar" menu item
- (IBAction)toggleStatusBar:(id)sender {
    BOOL currentVisibility = [[NSUserDefaults standardUserDefaults] boolForKey:kStatusBarVisibleKey];
    // Toggle the state
    [[NSUserDefaults standardUserDefaults] setBool:!currentVisibility forKey:kStatusBarVisibleKey];
    // Apply the change
    [self applyStatusBarVisibility];
}

// Applies the current visibility state to the status bar and adjusts layout
- (void)applyStatusBarVisibility {
    BOOL shouldBeVisible = [[NSUserDefaults standardUserDefaults] boolForKey:kStatusBarVisibleKey];
    CGFloat statusBarHeight = 22.0;
    CGFloat rightPadding = 8.0; // Define padding from the right edge
    NSRect contentBounds = self.window.contentView.bounds;
    NSRect scrollFrame = contentBounds;
    // Adjust status frame for padding
    NSRect statusFrame = NSMakeRect(0, // X origin
                                   0, // Y origin
                                   contentBounds.size.width - rightPadding, // Width (reduced by padding)
                                   statusBarHeight); // Height

    if (shouldBeVisible) {
        self.statusLabel.hidden = NO;
        // Make space for status bar at bottom
        scrollFrame.origin.y += statusBarHeight;
        scrollFrame.size.height -= statusBarHeight;
    } else {
        self.statusLabel.hidden = YES;
        // Scroll view takes full height
    }

    // Animate the frame changes for smoothness (optional)
    // Use non-animator calls first to set the final state immediately,
    // then optionally use animator if smooth transition is desired.
    // For simplicity and immediate effect, we'll skip animator here.
    [self.scrollView setFrame:scrollFrame];
    [self.statusLabel setFrame:statusFrame];

    // Update the menu item state
    // Ensure statusBarMenuItem exists before accessing it
    if (self.statusBarMenuItem) {
         self.statusBarMenuItem.state = shouldBeVisible ? NSControlStateValueOn : NSControlStateValueOff;
    }

    // Update the status text (will clear if hidden)
    [self updateStatusLabel];
}


// Sets up the main application menu bar with more standard items.
- (void)setupMainMenu {
    // Get the shared application instance's main menu or create one.
    NSMenu *mainMenu = [NSApp mainMenu];
    if (!mainMenu) {
        mainMenu = [[NSMenu alloc] initWithTitle:@"MainMenu"];
        [NSApp setMainMenu:mainMenu];
    } else {
        [mainMenu removeAllItems];
    }

    // --- App Menu ---
    NSMenuItem *appMenuItem = [[NSMenuItem alloc] initWithTitle:@"Application" action:nil keyEquivalent:@""];
    [mainMenu addItem:appMenuItem];
    NSMenu *appMenu = [[NSMenu alloc] initWithTitle:NSProcessInfo.processInfo.processName];
    [appMenuItem setSubmenu:appMenu];
    NSString *aboutTitle = [NSString stringWithFormat:@"About %@", NSProcessInfo.processInfo.processName];
    NSMenuItem *aboutItem = [[NSMenuItem alloc] initWithTitle:aboutTitle action:@selector(orderFrontStandardAboutPanel:) keyEquivalent:@""];
    [appMenu addItem:aboutItem];
    [appMenu addItem:[NSMenuItem separatorItem]];
    NSMenuItem *servicesItem = [[NSMenuItem alloc] initWithTitle:@"Services" action:nil keyEquivalent:@""];
    NSMenu *servicesMenu = [[NSMenu alloc] initWithTitle:@"Services"];
    [NSApp setServicesMenu:servicesMenu];
    [servicesItem setSubmenu:servicesMenu];
    [appMenu addItem:servicesItem];
    [appMenu addItem:[NSMenuItem separatorItem]];
    NSString *hideTitle = [NSString stringWithFormat:@"Hide %@", NSProcessInfo.processInfo.processName];
    NSMenuItem *hideItem = [[NSMenuItem alloc] initWithTitle:hideTitle action:@selector(hide:) keyEquivalent:@"h"];
    [appMenu addItem:hideItem];
    NSMenuItem *hideOthersItem = [[NSMenuItem alloc] initWithTitle:@"Hide Others" action:@selector(hideOtherApplications:) keyEquivalent:@"h"];
    [hideOthersItem setKeyEquivalentModifierMask:(NSEventModifierFlagOption | NSEventModifierFlagCommand)];
    [appMenu addItem:hideOthersItem];
    NSMenuItem *showAllItem = [[NSMenuItem alloc] initWithTitle:@"Show All" action:@selector(unhideAllApplications:) keyEquivalent:@""];
    [appMenu addItem:showAllItem];
    [appMenu addItem:[NSMenuItem separatorItem]];
    NSString *quitTitle = [NSString stringWithFormat:@"Quit %@", NSProcessInfo.processInfo.processName];
    NSMenuItem *quitItem = [[NSMenuItem alloc] initWithTitle:quitTitle action:@selector(terminate:) keyEquivalent:@"q"];
    [appMenu addItem:quitItem];

    // --- File Menu ---
    NSMenuItem *fileMenuItem = [[NSMenuItem alloc] initWithTitle:@"File" action:nil keyEquivalent:@""];
    [mainMenu addItem:fileMenuItem];
    NSMenu *fileMenu = [[NSMenu alloc] initWithTitle:@"File"];
    [fileMenuItem setSubmenu:fileMenu];
    NSMenuItem *openItem = [[NSMenuItem alloc] initWithTitle:@"Open…" action:@selector(openDocument:) keyEquivalent:@"o"];
    [fileMenu addItem:openItem];
    [fileMenu addItem:[NSMenuItem separatorItem]];
    NSMenuItem *saveItem = [[NSMenuItem alloc] initWithTitle:@"Save…" action:@selector(saveDocument:) keyEquivalent:@"s"];
    [fileMenu addItem:saveItem];
    NSMenuItem *saveAsItem = [[NSMenuItem alloc] initWithTitle:@"Save As…" action:@selector(saveDocument:) keyEquivalent:@"S"];
    [saveAsItem setKeyEquivalentModifierMask:(NSEventModifierFlagShift | NSEventModifierFlagCommand)];
    [fileMenu addItem:saveAsItem];
    [fileMenu addItem:[NSMenuItem separatorItem]];
    NSMenuItem *closeItem = [[NSMenuItem alloc] initWithTitle:@"Close" action:@selector(performClose:) keyEquivalent:@"w"];
     [fileMenu addItem:closeItem];

    // --- Edit Menu ---
    NSMenuItem *editMenuItem = [[NSMenuItem alloc] initWithTitle:@"Edit" action:nil keyEquivalent:@""];
    [mainMenu addItem:editMenuItem];
    NSMenu *editMenu = [[NSMenu alloc] initWithTitle:@"Edit"];
    [editMenuItem setSubmenu:editMenu];
    [editMenu addItemWithTitle:@"Undo" action:@selector(undo:) keyEquivalent:@"z"];
    [editMenu addItemWithTitle:@"Redo" action:@selector(redo:) keyEquivalent:@"Z"];
    [editMenu addItem:[NSMenuItem separatorItem]];
    [editMenu addItemWithTitle:@"Cut" action:@selector(cut:) keyEquivalent:@"x"];
    [editMenu addItemWithTitle:@"Copy" action:@selector(copy:) keyEquivalent:@"c"];
    [editMenu addItemWithTitle:@"Paste" action:@selector(paste:) keyEquivalent:@"v"];
    [editMenu addItemWithTitle:@"Select All" action:@selector(selectAll:) keyEquivalent:@"a"];

    // --- View Menu ---
    NSMenuItem *viewMenuItem = [[NSMenuItem alloc] initWithTitle:@"View" action:nil keyEquivalent:@""];
    [mainMenu addItem:viewMenuItem];
    NSMenu *viewMenu = [[NSMenu alloc] initWithTitle:@"View"];
    [viewMenuItem setSubmenu:viewMenu];
    // Placeholder item - does nothing yet
    [viewMenu addItemWithTitle:@"Show Line Numbers" action:nil keyEquivalent:@""];
    // Status Bar Toggle Item
    self.statusBarMenuItem = [[NSMenuItem alloc] initWithTitle:@"Show Status Bar" action:@selector(toggleStatusBar:) keyEquivalent:@""];
    // Set initial state based on UserDefaults
    BOOL isVisible = [[NSUserDefaults standardUserDefaults] boolForKey:kStatusBarVisibleKey];
    self.statusBarMenuItem.state = isVisible ? NSControlStateValueOn : NSControlStateValueOff;
    [viewMenu addItem:self.statusBarMenuItem]; // Add the item


    // --- Window Menu ---
    NSMenuItem *windowMenuItem = [[NSMenuItem alloc] initWithTitle:@"Window" action:nil keyEquivalent:@""];
    [mainMenu addItem:windowMenuItem];
    NSMenu *windowMenu = [[NSMenu alloc] initWithTitle:@"Window"];
    [windowMenuItem setSubmenu:windowMenu];
    [windowMenu addItemWithTitle:@"Minimize" action:@selector(performMiniaturize:) keyEquivalent:@"m"];
    [windowMenu addItemWithTitle:@"Zoom" action:@selector(performZoom:) keyEquivalent:@""];
    [windowMenu addItem:[NSMenuItem separatorItem]];
    [windowMenu addItemWithTitle:@"Bring All to Front" action:@selector(arrangeInFront:) keyEquivalent:@""];

    // --- Help Menu ---
    NSMenuItem *helpMenuItem = [[NSMenuItem alloc] initWithTitle:@"Help" action:nil keyEquivalent:@""];
    [mainMenu addItem:helpMenuItem];
    NSMenu *helpMenu = [[NSMenu alloc] initWithTitle:@"Help"];
    [helpMenuItem setSubmenu:helpMenu];
    [helpMenu addItemWithTitle:[NSString stringWithFormat:@"%@ Help", NSProcessInfo.processInfo.processName] action:@selector(showHelp:) keyEquivalent:@"?"];

    // Assign the completed menu to the application
    [NSApp setMainMenu:mainMenu];
}


// Action method called when "File > Open..." is selected.
- (IBAction)openDocument:(id)sender {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setAllowedFileTypes:@[@"txt"]];
    [openPanel setCanChooseFiles:YES];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setAllowsMultipleSelection:NO];

    [openPanel beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse result) {
        if (result == NSModalResponseOK) {
            NSURL *fileURL = [openPanel URL];
            if (fileURL) {
                [self openFileAtURL:fileURL];
            } else {
                 NSLog(@"Error: Open panel returned OK but URL is nil.");
            }
        } else {
            NSLog(@"Open panel cancelled or failed.");
        }
    }];
}

// Action method called when "File > Save..." or "Save As..." is selected.
- (IBAction)saveDocument:(id)sender {
     NSLog(@"saveDocument: called by sender: %@", sender);

     if (!self.textView) {
         NSLog(@"Error: Cannot save, textView is nil.");
         NSBeep();
         return;
     }

    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setNameFieldStringValue:@"Untitled.txt"];
    [savePanel setAllowedFileTypes:@[@"txt"]];

    [savePanel beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse result) {
         NSLog(@"Save panel completed with result: %ld", (long)result);
        if (result == NSModalResponseOK) {
            NSURL *fileURL = [savePanel URL];
            if (fileURL) {
                NSError *error = nil;
                NSString *fileContents = [self.textView string];
                 NSLog(@"Attempting to save file to URL: %@", fileURL);

                BOOL success = [fileContents writeToURL:fileURL
                                             atomically:YES
                                               encoding:NSUTF8StringEncoding
                                                  error:&error];
                if (success) {
                     NSLog(@"File saved successfully.");
                    [self.window setTitleWithRepresentedFilename:[fileURL path]];
                    [self.window setDocumentEdited:NO];
                } else {
                     NSLog(@"Error saving file: %@", [error localizedDescription]);
                    NSAlert *alert = [[NSAlert alloc] init];
                    [alert setMessageText:@"Error Saving File"];
                    [alert setInformativeText:[error localizedDescription]];
                    [alert addButtonWithTitle:@"OK"];
                    [alert beginSheetModalForWindow:self.window completionHandler:nil];
                }
            } else {
                 NSLog(@"Error: Save panel returned OK but URL is nil.");
            }
        } else {
             NSLog(@"Save panel cancelled or failed.");
        }
    }];
}

// Delegate method called when the application is asked to open a file (e.g., double-click in Finder)
- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename {
    NSLog(@"application:openFile: called with filename: %@", filename);
    NSURL *fileURL = [NSURL fileURLWithPath:filename];
    return [self openFileAtURL:fileURL];
}

// Common method to open and display a file from a URL
- (BOOL)openFileAtURL:(NSURL *)fileURL {
    if (!fileURL) {
        return NO;
    }

    if (!self.window || !self.textView) {
        NSLog(@"Error opening file: Window or TextView not ready.");
        return NO;
    }

    NSError *error = nil;
    NSLog(@"Attempting to open file at URL: %@", fileURL);
    NSString *fileContents = [NSString stringWithContentsOfURL:fileURL
                                                      encoding:NSUTF8StringEncoding
                                                         error:&error];
    if (fileContents) {
        NSLog(@"Successfully read file content.");
        [self.textView setString:fileContents];
        [self.window setTitleWithRepresentedFilename:[fileURL path]];
        [self.window setDocumentEdited:NO];
        // Update status after loading new content
        [self updateStatusLabel];
        return YES;
    } else {
        NSLog(@"Error reading file: %@", [error localizedDescription]);
        dispatch_async(dispatch_get_main_queue(), ^{
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:@"Error Opening File"];
            [alert setInformativeText:[error localizedDescription]];
            [alert addButtonWithTitle:@"OK"];
             if (self.window) {
                [alert beginSheetModalForWindow:self.window completionHandler:nil];
             } else {
                 [alert runModal];
             }
        });
        return NO;
    }
}


// Delegate method called before the application terminates.
- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Clean up observer if needed, though using delegate is cleaner
}

// Delegate method to determine if the app should terminate when the last window is closed.
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

// Required for window restoration
+ (void)restoreWindowWithIdentifier:(NSString *)identifier state:(NSCoder *)state completionHandler:(void (^)(NSWindow *, NSError *))completionHandler {
     AppDelegate *appDelegate = (AppDelegate *)[NSApp delegate];
     if (appDelegate.window && [identifier isEqualToString:@"litetextMainWindow"]) {
         completionHandler(appDelegate.window, nil);
     } else {
         NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:nil];
         completionHandler(nil, error);
     }
}

// Opt-in to secure state restoration (recommended)
- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
    return YES;
}

// Register default user defaults
+ (void)initialize {
    if (self == [AppDelegate class]) {
        // Set default value for status bar visibility (visible by default)
        NSDictionary *defaults = @{kStatusBarVisibleKey: @YES};
        [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
    }
}


@end

