// main.m
#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // Get the shared NSApplication instance.
        NSApplication *application = [NSApplication sharedApplication];

        // Create an instance of our AppDelegate.
        AppDelegate *appDelegate = [[AppDelegate alloc] init];

        // Set the delegate for the application instance.
        [application setDelegate:appDelegate];

        // Start the main event loop.
        // This function does not return until the application is terminated.
        [application run];
    }
    // Return 0 to indicate successful execution.
    return EXIT_SUCCESS;
}

