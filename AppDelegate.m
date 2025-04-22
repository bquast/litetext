// AppDelegate.m
#import "AppDelegate.h"

@interface AppDelegate ()
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
    [self.window setTitle:@"MacNote"];
    [self.window setDelegate:self];
    // Allow the window to restore its state (position, size)
    [self.window setRestorable:YES];
    // Set a unique identifier for the window to be restored
    self.window.identifier = @"MacNoteMainWindow";
    [self.window setRestorationClass:[self class]]; // Use AppDelegate for restoration

    // --- ScrollView and TextView Setup ---
    self.scrollView = [[NSScrollView alloc] initWithFrame:self.window.contentView.bounds];
    [self.scrollView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [self.scrollView setHasVerticalScroller:YES];
    [self.scrollView setHasHorizontalScroller:YES];
    [self.scrollView setBorderType:NSNoBorder];

    // Use the content size of the scroll view for the text view frame
    NSSize contentSize = [self.scrollView contentSize];
    self.textView = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, contentSize.width, contentSize.height)];

    // Configure text view properties
    [self.textView setMinSize:NSMakeSize(0.0, contentSize.height)]; // Allow vertical growth
    [self.textView setMaxSize:NSMakeSize(FLT_MAX, FLT_MAX)];
    [self.textView setVerticallyResizable:YES];
    [self.textView setHorizontallyResizable:NO]; // Let scrollview handle horizontal scrolling
    [self.textView setAutoresizingMask:NSViewWidthSizable]; // Resize width with scroll view
    [[self.textView textContainer] setWidthTracksTextView:YES]; // Text wraps to view width
    [[self.textView textContainer] setContainerSize:NSMakeSize(contentSize.width, FLT_MAX)]; // Allow infinite vertical size

    [self.textView setFont:[NSFont userFixedPitchFontOfSize:12.0]];
    [self.textView setContinuousSpellCheckingEnabled:YES];
    [self.textView setAutomaticQuoteSubstitutionEnabled:NO];
    [self.textView setAutomaticDashSubstitutionEnabled:NO];
    [self.textView setAllowsUndo:YES];

    // Embed the text view within the scroll view.
    [self.scrollView setDocumentView:self.textView];

    // Add the scroll view to the window's content view.
    [self.window setContentView:self.scrollView];

    // --- Menu Setup ---
    [self setupMainMenu];

    // --- Final Window Display ---
    [self.window makeKeyAndOrderFront:nil];
}

// Sets up the main application menu bar with more standard items.
- (void)setupMainMenu {
    // Get the shared application instance's main menu or create one.
    NSMenu *mainMenu = [NSApp mainMenu];
    if (!mainMenu) {
        mainMenu = [[NSMenu alloc] initWithTitle:@"MainMenu"];
        [NSApp setMainMenu:mainMenu];
    } else {
        // Clear existing default menus if necessary (like from template)
        [mainMenu removeAllItems];
    }

    // --- App Menu ---
    // Create the application menu item (e.g., "MacNote").
    NSMenuItem *appMenuItem = [[NSMenuItem alloc] initWithTitle:@"Application" action:nil keyEquivalent:@""];
    [mainMenu addItem:appMenuItem];

    NSMenu *appMenu = [[NSMenu alloc] initWithTitle:NSProcessInfo.processInfo.processName]; // Use app name dynamically
    [appMenuItem setSubmenu:appMenu];

    // Add "About MacNote" item
    NSString *aboutTitle = [NSString stringWithFormat:@"About %@", NSProcessInfo.processInfo.processName];
    NSMenuItem *aboutItem = [[NSMenuItem alloc] initWithTitle:aboutTitle action:@selector(orderFrontStandardAboutPanel:) keyEquivalent:@""];
    [appMenu addItem:aboutItem];

    [appMenu addItem:[NSMenuItem separatorItem]]; // Separator

    // Add standard Services menu item
    NSMenuItem *servicesItem = [[NSMenuItem alloc] initWithTitle:@"Services" action:nil keyEquivalent:@""];
    NSMenu *servicesMenu = [[NSMenu alloc] initWithTitle:@"Services"];
    [NSApp setServicesMenu:servicesMenu]; // Assign the services menu
    [servicesItem setSubmenu:servicesMenu];
    [appMenu addItem:servicesItem];

    [appMenu addItem:[NSMenuItem separatorItem]]; // Separator

    // Add "Hide MacNote" item
    NSString *hideTitle = [NSString stringWithFormat:@"Hide %@", NSProcessInfo.processInfo.processName];
    NSMenuItem *hideItem = [[NSMenuItem alloc] initWithTitle:hideTitle action:@selector(hide:) keyEquivalent:@"h"];
    [appMenu addItem:hideItem];

    // Add "Hide Others" item
    NSMenuItem *hideOthersItem = [[NSMenuItem alloc] initWithTitle:@"Hide Others" action:@selector(hideOtherApplications:) keyEquivalent:@"h"];
    [hideOthersItem setKeyEquivalentModifierMask:(NSEventModifierFlagOption | NSEventModifierFlagCommand)];
    [appMenu addItem:hideOthersItem];

    // Add "Show All" item
    NSMenuItem *showAllItem = [[NSMenuItem alloc] initWithTitle:@"Show All" action:@selector(unhideAllApplications:) keyEquivalent:@""];
    [appMenu addItem:showAllItem];

    [appMenu addItem:[NSMenuItem separatorItem]]; // Separator

    // Add "Quit MacNote" item
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

    // Add Save As... (can point to the same saveDocument: for simplicity now)
    NSMenuItem *saveAsItem = [[NSMenuItem alloc] initWithTitle:@"Save As…" action:@selector(saveDocument:) keyEquivalent:@"S"]; // Shift-Command-S
    [saveAsItem setKeyEquivalentModifierMask:(NSEventModifierFlagShift | NSEventModifierFlagCommand)];
    [fileMenu addItem:saveAsItem];

    [fileMenu addItem:[NSMenuItem separatorItem]];

    NSMenuItem *closeItem = [[NSMenuItem alloc] initWithTitle:@"Close" action:@selector(performClose:) keyEquivalent:@"w"];
     [fileMenu addItem:closeItem];


    // --- Edit Menu (Standard items - handled by responder chain) ---
    NSMenuItem *editMenuItem = [[NSMenuItem alloc] initWithTitle:@"Edit" action:nil keyEquivalent:@""];
    [mainMenu addItem:editMenuItem];
    NSMenu *editMenu = [[NSMenu alloc] initWithTitle:@"Edit"];
    [editMenuItem setSubmenu:editMenu];

    [editMenu addItemWithTitle:@"Undo" action:@selector(undo:) keyEquivalent:@"z"];
    [editMenu addItemWithTitle:@"Redo" action:@selector(redo:) keyEquivalent:@"Z"]; // Shift-Command-Z
    [editMenu addItem:[NSMenuItem separatorItem]];
    [editMenu addItemWithTitle:@"Cut" action:@selector(cut:) keyEquivalent:@"x"];
    [editMenu addItemWithTitle:@"Copy" action:@selector(copy:) keyEquivalent:@"c"];
    [editMenu addItemWithTitle:@"Paste" action:@selector(paste:) keyEquivalent:@"v"];
    [editMenu addItemWithTitle:@"Select All" action:@selector(selectAll:) keyEquivalent:@"a"];


    // --- View Menu (Placeholder) ---
    NSMenuItem *viewMenuItem = [[NSMenuItem alloc] initWithTitle:@"View" action:nil keyEquivalent:@""];
    [mainMenu addItem:viewMenuItem];
    NSMenu *viewMenu = [[NSMenu alloc] initWithTitle:@"View"];
    [viewMenuItem setSubmenu:viewMenu];

    // Placeholder items - these don't do anything yet
    [viewMenu addItemWithTitle:@"Show Line Numbers" action:nil keyEquivalent:@""];
    [viewMenu addItemWithTitle:@"Show Status Bar" action:nil keyEquivalent:@""];


    // --- Window Menu (Standard items - handled by NSApplication) ---
    NSMenuItem *windowMenuItem = [[NSMenuItem alloc] initWithTitle:@"Window" action:nil keyEquivalent:@""];
    [mainMenu addItem:windowMenuItem];
    NSMenu *windowMenu = [[NSMenu alloc] initWithTitle:@"Window"];
    [windowMenuItem setSubmenu:windowMenu];

    [windowMenu addItemWithTitle:@"Minimize" action:@selector(performMiniaturize:) keyEquivalent:@"m"];
    [windowMenu addItemWithTitle:@"Zoom" action:@selector(performZoom:) keyEquivalent:@""];
    [windowMenu addItem:[NSMenuItem separatorItem]];
    [windowMenu addItemWithTitle:@"Bring All to Front" action:@selector(arrangeInFront:) keyEquivalent:@""];


    // --- Help Menu (Standard items - handled by NSApplication) ---
    NSMenuItem *helpMenuItem = [[NSMenuItem alloc] initWithTitle:@"Help" action:nil keyEquivalent:@""];
    [mainMenu addItem:helpMenuItem];
    NSMenu *helpMenu = [[NSMenu alloc] initWithTitle:@"Help"];
    [helpMenuItem setSubmenu:helpMenu];
    // The main help item usually searches Help automatically
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

    // Use block-based API for modern practice
    [openPanel beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse result) {
        if (result == NSModalResponseOK) {
            NSURL *fileURL = [openPanel URL];
            if (fileURL) {
                NSError *error = nil;
                NSLog(@"Attempting to open file at URL: %@", fileURL); // Log attempt
                NSString *fileContents = [NSString stringWithContentsOfURL:fileURL
                                                                  encoding:NSUTF8StringEncoding
                                                                     error:&error];
                if (fileContents) {
                    // Ensure textView exists before setting string
                    if (self.textView) {
                         NSLog(@"Successfully read file content.");
                        [self.textView setString:fileContents];
                        [self.window setTitleWithRepresentedFilename:[fileURL path]]; // Use standard method to set title and proxy icon
                        [self.window setDocumentEdited:NO]; // Mark document as not edited after opening
                    } else {
                         NSLog(@"Error: TextView is nil when trying to set string.");
                    }

                } else {
                    NSLog(@"Error reading file: %@", [error localizedDescription]); // Log error
                    NSAlert *alert = [[NSAlert alloc] init];
                    [alert setMessageText:@"Error Opening File"];
                    [alert setInformativeText:[error localizedDescription]];
                    [alert addButtonWithTitle:@"OK"];
                    [alert beginSheetModalForWindow:self.window completionHandler:nil]; // Use sheet for alert
                }
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
     NSLog(@"saveDocument: called by sender: %@", sender); // Log entry

     // Ensure textView exists before trying to save
     if (!self.textView) {
         NSLog(@"Error: Cannot save, textView is nil.");
         NSBeep(); // Simple feedback
         return;
     }

    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setNameFieldStringValue:@"Untitled.txt"];
    [savePanel setAllowedFileTypes:@[@"txt"]];

    // Use block-based API for modern practice
    [savePanel beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse result) {
         NSLog(@"Save panel completed with result: %ld", (long)result); // Log result
        if (result == NSModalResponseOK) {
            NSURL *fileURL = [savePanel URL];
            if (fileURL) {
                NSError *error = nil;
                NSString *fileContents = [self.textView string]; // Get content *after* panel is confirmed
                 NSLog(@"Attempting to save file to URL: %@", fileURL); // Log attempt

                BOOL success = [fileContents writeToURL:fileURL
                                             atomically:YES
                                               encoding:NSUTF8StringEncoding
                                                  error:&error];
                if (success) {
                     NSLog(@"File saved successfully.");
                    [self.window setTitleWithRepresentedFilename:[fileURL path]]; // Update title and proxy icon
                    [self.window setDocumentEdited:NO]; // Mark document as saved
                } else {
                     NSLog(@"Error saving file: %@", [error localizedDescription]); // Log error
                    NSAlert *alert = [[NSAlert alloc] init];
                    [alert setMessageText:@"Error Saving File"];
                    [alert setInformativeText:[error localizedDescription]];
                    [alert addButtonWithTitle:@"OK"];
                    [alert beginSheetModalForWindow:self.window completionHandler:nil]; // Use sheet for alert
                }
            } else {
                 NSLog(@"Error: Save panel returned OK but URL is nil.");
            }
        } else {
             NSLog(@"Save panel cancelled or failed.");
        }
    }];
}


// Delegate method called before the application terminates.
- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

// Delegate method to determine if the app should terminate when the last window is closed.
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

// Required for window restoration
+ (void)restoreWindowWithIdentifier:(NSString *)identifier state:(NSCoder *)state completionHandler:(void (^)(NSWindow *, NSError *))completionHandler {
     // In a more complex app, you'd find the right window or create a new one based on the identifier/state.
     // For this single-window app, we can assume it's the main window if the app delegate exists.
     AppDelegate *appDelegate = (AppDelegate *)[NSApp delegate];
     if (appDelegate.window && [identifier isEqualToString:appDelegate.window.identifier]) {
         completionHandler(appDelegate.window, nil);
     } else {
         // Handle error - couldn't find the window to restore
         // Use a generic error code '0' instead of the potentially undeclared NSWindowRestorationError
         NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:nil];
         completionHandler(nil, error);
     }
}

// Opt-in to secure state restoration (recommended)
- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
    return YES;
}


@end

