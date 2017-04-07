#import "ConnectTestAppDelegate.h"
#import "GCDAsyncSocket.h"
#import "DDLog.h"
#import "DDTTYLogger.h"

// Log levels: off, error, warn, info, verbose
static const int ddLogLevel = LOG_LEVEL_INFO;
#define FORMAT(format, ...) [NSString stringWithFormat:(format), ##__VA_ARGS__]

#define USE_SECURE_CONNECTION 0


@implementation ConnectTestAppDelegate

@synthesize window;
@synthesize addrField;
@synthesize portField;
@synthesize messageField;
@synthesize sendButton;
@synthesize logView;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Setup logging framework
	[DDLog addLogger:[DDTTYLogger sharedInstance]];
	
	DDLogInfo(@"%@", THIS_METHOD);
	
	// Setup our socket (GCDAsyncSocket).
	// The socket will invoke our delegate methods using the usual delegate paradigm.
	// However, it will invoke the delegate methods on a specified GCD delegate dispatch queue.
	// 
	// Now we can configure the delegate dispatch queue however we want.
	// We could use a dedicated dispatch queue for easy parallelization.
	// Or we could simply use the dispatch queue for the main thread.
	// 
	// The best approach for your application will depend upon convenience, requirements and performance.
	// 
	// For this simple example, we're just going to use the main thread.
	
	dispatch_queue_t mainQueue = dispatch_get_main_queue();
	
	asyncSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:mainQueue];
	
	#if USE_SECURE_CONNECTION
	{
		NSString *host = @"www.paypal.com";
		uint16_t port = 443;
		
		DDLogInfo(@"Connecting to \"%@\" on port %hu...", host, port);
		
		NSError *error = nil;
		if (![asyncSocket connectToHost:@"www.paypal.com" onPort:port error:&error])
		{
			DDLogError(@"Error connecting: %@", error);
		}
	}
	#else
	{
//		NSString *host = @"google.com";
//		uint16_t port = 80;
//	
//		
//		DDLogInfo(@"Connecting to \"%@\" on port %hu...", host, port);
//		
//		NSError *error = nil;
//		if (![asyncSocket connectToHost:host onPort:port error:&error])
//		{
//			DDLogError(@"Error connecting: %@", error);
//		}
        
        NSString *host = @"localhost";
        uint16_t port = 8002;
        self.portField.stringValue = [NSString stringWithFormat:@"%d",port];
        self.addrField.stringValue = host;
        
        DDLogInfo(@"Connecting to \"%@\" on port %hu...", host, port);
        
        NSError *error = nil;
        if (![asyncSocket connectToHost:host onPort:port error:&error])
        {
            DDLogError(@"Error connecting: %@", error);
        }
        [asyncSocket readDataWithTimeout:-1 tag:0];

		// You can also specify an optional connect timeout.
		
	//	NSError *error = nil;
	//	if (![asyncSocket connectToHost:host onPort:80 withTimeout:5.0 error:&error])
	//	{
	//		DDLogError(@"Error connecting: %@", error);
	//	}
		
	}
	#endif
}
- (IBAction)send:(id)sender
{
    NSString *host = [addrField stringValue];
    if ([host length] == 0)
    {
        [self logError:@"Address required"];
        return;
    }
    
    int port = [portField intValue];
    if (port <= 0 || port > 65535)
    {
        [self logError:@"Valid port required"];
        return;
    }
    
    NSString *msg = [messageField stringValue];
    if ([msg length] == 0)
    {
        [self logError:@"Message required"];
        return;
    }
    
    msg = [NSString stringWithFormat:@"%@\r\n",msg];

    NSData *data = [msg dataUsingEncoding:NSUTF8StringEncoding];
    
    [asyncSocket writeData:data withTimeout:-1 tag:tag];
//    [asyncSocket readDataToData:[GCDAsyncSocket CRLFData] withTimeout:-1 tag:tag];
    
    [asyncSocket readDataWithTimeout:-1 tag:tag];
    [self logMessage:FORMAT(@"SENT (%i): %@", (int)tag, msg)];
    
    tag++;
}

- (void)scrollToBottom
{
    NSScrollView *scrollView = [logView enclosingScrollView];
    NSPoint newScrollOrigin;
    
    if ([[scrollView documentView] isFlipped])
        newScrollOrigin = NSMakePoint(0.0F, NSMaxY([[scrollView documentView] frame]));
    else
        newScrollOrigin = NSMakePoint(0.0F, 0.0F);
    
    [[scrollView documentView] scrollPoint:newScrollOrigin];
}

- (void)logError:(NSString *)msg
{
    NSString *paragraph = [NSString stringWithFormat:@"%@\n", msg];
    
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:1];
    [attributes setObject:[NSColor redColor] forKey:NSForegroundColorAttributeName];
    
    NSAttributedString *as = [[NSAttributedString alloc] initWithString:paragraph attributes:attributes];
    
    [[logView textStorage] appendAttributedString:as];
    [self scrollToBottom];
}

- (void)logInfo:(NSString *)msg
{
    NSString *paragraph = [NSString stringWithFormat:@"%@\n", msg];
    
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:1];
    [attributes setObject:[NSColor purpleColor] forKey:NSForegroundColorAttributeName];
    
    NSAttributedString *as = [[NSAttributedString alloc] initWithString:paragraph attributes:attributes];
    
    [[logView textStorage] appendAttributedString:as];
    [self scrollToBottom];
}

- (void)logMessage:(NSString *)msg
{
    NSString *paragraph = [NSString stringWithFormat:@"%@\n", msg];
    
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:1];
    [attributes setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
    
    NSAttributedString *as = [[NSAttributedString alloc] initWithString:paragraph attributes:attributes];
    
    [[logView textStorage] appendAttributedString:as];
    [self scrollToBottom];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Socket Delegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
	DDLogInfo(@"socket:%p didConnectToHost:%@ port:%hu", sock, host, port);
	
//	DDLogInfo(@"localHost :%@ port:%hu", [sock localHost], [sock localPort]);
	
	#if USE_SECURE_CONNECTION
	{
		// Connected to secure server (HTTPS)
		
		// Configure SSL/TLS settings
		NSMutableDictionary *settings = [NSMutableDictionary dictionaryWithCapacity:3];
		
		// If you simply want to ensure that the remote host's certificate is valid,
		// then you can use an empty dictionary.
		
		// If you know the name of the remote host, then you should specify the name here.
		// 
		// NOTE:
		// You should understand the security implications if you do not specify the peer name.
		// Please see the documentation for the startTLS method in GCDAsyncSocket.h for a full discussion.
		
		[settings setObject:@"www.paypal.com"
					 forKey:(NSString *)kCFStreamSSLPeerName];
		
		// To connect to a test server, with a self-signed certificate, use settings similar to this:
		
	//	// Allow expired certificates
	//	[settings setObject:[NSNumber numberWithBool:YES]
	//				 forKey:(NSString *)kCFStreamSSLAllowsExpiredCertificates];
	//	
	//	// Allow self-signed certificates
	//	[settings setObject:[NSNumber numberWithBool:YES]
	//				 forKey:(NSString *)kCFStreamSSLAllowsAnyRoot];
	//	
	//	// In fact, don't even validate the certificate chain
	//	[settings setObject:[NSNumber numberWithBool:NO]
	//				 forKey:(NSString *)kCFStreamSSLValidatesCertificateChain];
		
		DDLogInfo(@"Starting TLS with settings:\n%@", settings);
		
		[sock startTLS:settings];
		
		// You can also pass nil to the startTLS method, which is the same as passing an empty dictionary.
		// Again, you should understand the security implications of doing so.
		// Please see the documentation for the startTLS method in GCDAsyncSocket.h for a full discussion.
		
	}
	#else
	{
		// Connected to normal server (HTTP)
	}
	#endif
}

- (void)socketDidSecure:(GCDAsyncSocket *)sock
{
	DDLogInfo(@"socketDidSecure:%p", sock);
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{

	DDLogInfo(@"socket:%p didWriteDataWithTag:%ld", sock, tag);
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    NSString *msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    [self logMessage:FORMAT(@"RECV (%li): %@", tag, msg)];

	DDLogInfo(@"socket:%p didReadData:withTag:%ld", sock, tag);
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
	DDLogInfo(@"socketDidDisconnect:%p withError: %@", sock, err);
}

@end
