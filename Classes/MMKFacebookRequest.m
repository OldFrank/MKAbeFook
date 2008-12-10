/*
 
 MMKFacebookRequest.m
 Mobile MKAbeFook
 
 Created by Mike on 3/28/08.
 
 This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.
 To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/us/legalcode or send a letter to Creative Commons, 543 Howard Street, 5th Floor, San Francisco, California, 94105, USA.
 
*/

#import <QuartzCore/QuartzCore.h>
#import "MMKFacebookRequest.h"
#import "MMKFacebook.h"

#import "CXMLDocument.h"
#import "CXMLDocumentAdditions.h"
#import "CXMLElementAdditions.h"


#define LOADING_SCREEN_ANIMATION_DURATION 1.0


@implementation MMKFacebookRequest

-(MMKFacebookRequest *)init
{
	self = [super init];
	if(self != nil)
	{
		_loadingView = nil;
		_facebookConnection = nil;
		_delegate = nil;
		_selector = nil;
		_responseData = [[NSMutableData alloc] init];
		_parameters = [[NSMutableDictionary alloc] init];
		_urlRequestType = MMKPostRequest;
		_requestURL = [[NSURL URLWithString:MKAPIServerURL] retain];
		_displayLoadingSheet = NO;
		_displayLoadingView = NO;
		_loadingViewTransitionType = [[NSString alloc] init];
		_loadingViewTransitionSubtype = [[NSString alloc] init];
		_loadingViewTransitionDuration = LOADING_SCREEN_ANIMATION_DURATION;
		_displayGeneralErrors = YES;
		
	}
	return self;
}

-(MMKFacebookRequest *)initWithFacebookConnection:(MMKFacebook *)aFacebookConnection delegate:(id)aDelegate selector:(SEL)aSelector
{
	self = [super init];
	if(self != nil)
	{
		_loadingView = nil;
		_facebookConnection = [aFacebookConnection retain];
		_delegate = aDelegate;
		_selector = aSelector;
		_responseData = [[NSMutableData alloc] init];
		_parameters = [[NSMutableDictionary alloc] init];
		_urlRequestType = MMKPostRequest;
		_requestURL = [[NSURL URLWithString:MKAPIServerURL] retain];
		_displayLoadingSheet = NO;
		_displayGeneralErrors = YES;
		
	}
	return self;
}


-(MMKFacebookRequest *)initWithFacebookConnection:(MMKFacebook *)aFacebookConnection parameters:(NSDictionary *)parameters delegate:(id)aDelegate selector:(SEL)aSelector
{
	self = [super init];
	if(self != nil)
	{
		_loadingView = nil;
		_facebookConnection = [aFacebookConnection retain];
		_delegate = aDelegate;
		_selector = aSelector;
		_responseData = [[NSMutableData alloc] init];
		_parameters = [[NSMutableDictionary dictionaryWithDictionary:parameters] retain];
		_urlRequestType = MMKPostRequest;
		_requestURL = [[NSURL URLWithString:MKAPIServerURL] retain];
		_displayLoadingSheet = NO;
		_displayGeneralErrors = YES;
	}
	return self;
}

#pragma mark Setters and Getters

-(void)setFacebookConnection:(MMKFacebook *)aFacebookConnection
{
	_facebookConnection = aFacebookConnection;
}

-(void)setDelegate:(id)delegate
{
	_delegate = delegate;
}

-(void)setSelector:(SEL)selector
{
	_selector = selector;
}

-(void)setURLRequestType:(MMKFacebookRequestType)urlRequestType
{
	_urlRequestType = urlRequestType;
}

-(int)urlRequestType
{
	return _urlRequestType;
}

-(void)setParameters:(NSDictionary *)parameters
{
	[_parameters addEntriesFromDictionary:parameters];
}

-(void)displayLoadingSheet:(BOOL)shouldDisplayLoadingSheet
{
	_displayLoadingSheet = shouldDisplayLoadingSheet;
}

-(BOOL)displayGeneralErrors
{
	return _displayGeneralErrors;
}

-(void)setDisplayGeneralErrors:(BOOL)aBool
{
	_displayGeneralErrors = aBool;
}

#pragma mark -

-(void)dealloc
{
	if(_loadingView != nil)
		[_loadingView release];
	
	if(_loadingSheet != nil)
		[_loadingSheet release];
	
	[_requestURL release];
	[_parameters release];
	[_responseData release];
	[super dealloc];
}

-(void)sendRequest
{
	if([_parameters count] == 0)
	{
		if([_delegate respondsToSelector:@selector(facebookRequestFailed:)])
		{
			NSError *error = [NSError errorWithDomain:@"MKAbeFook" code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"No Parameters Specified", @"Error", nil]];
			[_delegate performSelector:@selector(facebookRequestFailed:) withObject:error];
		}
		return;
	}
	
	//to display some type of loading information we need to have access to the facebookconnection delegate and it must respond to the frontView method defined in the mmkfacebook protocol
	//TODO: this area needs a lot of clean up
	if([[_facebookConnection delegate] respondsToSelector:@selector(applicationView)])
	{
		//display little view at top of screen with a progress indicator in it
		if(_displayLoadingSheet == YES)
		{
			_loadingSheet = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, 0)];
			[_loadingSheet setBackgroundColor:[UIColor grayColor]];						
			
			UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
			[cancelButton setFrame:CGRectMake(10, -10, kStdButtonWidth - 15, kStdButtonHeight - 10)];
			[cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
			[cancelButton addTarget:self action:@selector(cancelRequest) forControlEvents:UIControlEventTouchUpInside];
			[_loadingSheet addSubview:cancelButton];
			
			UILabel *loadingText = [[UILabel alloc] initWithFrame:CGRectMake([[UIScreen mainScreen] bounds].size.width / 2 - 40, 0, 80, 20)];
			[loadingText setBackgroundColor:[UIColor clearColor]];
			[loadingText setTextAlignment:UITextAlignmentCenter];
			loadingText.text = @"Loading";
			loadingText.font = [UIFont boldSystemFontOfSize:19.0];
			loadingText.textColor = [UIColor whiteColor];
			[_loadingSheet addSubview:loadingText];
			
			
			UIActivityIndicatorView *progressIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake([[UIScreen mainScreen] bounds].size.width - 40, 0, 30, 30)];
			[progressIndicator setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhiteLarge];
			[progressIndicator startAnimating];
			[_loadingSheet addSubview:progressIndicator];
			
			
			[[[_facebookConnection delegate] applicationView] addSubview:_loadingSheet];
			
			[UIView beginAnimations:nil context:NULL];
			[UIView setAnimationDuration:LOADING_SCREEN_ANIMATION_DURATION];
			[_loadingSheet setFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, 70)];
			[loadingText setFrame:CGRectMake([[UIScreen mainScreen] bounds].size.width / 2 - 40, 33, 80, 20)];
			[progressIndicator setFrame:CGRectMake([[UIScreen mainScreen] bounds].size.width -40, 30 , 30, 30)];
			[cancelButton setFrame:CGRectMake(10, 30, kStdButtonWidth - 15, kStdButtonHeight - 10)]; 
			[UIView commitAnimations];

			[progressIndicator release];
			[loadingText release];

		//flip entire view and display loading message
		}else if(_displayLoadingView == YES)
		{
			if(_loadingView == nil)
			{
				_loadingView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
				[_loadingView setBackgroundColor:[UIColor magentaColor]];

				UILabel *loadingText = [[UILabel alloc] initWithFrame:CGRectMake([[UIScreen mainScreen] bounds].size.width / 2 - 40, [[UIScreen mainScreen] bounds].size.height / 2 - 50, 100, 20)];
				//loadingText.center = CGPointMake([[UIScreen mainScreen] applicationFrame].size.width / 2, [[UIScreen mainScreen] applicationFrame].size.height / 2 - 50);
				[loadingText setBackgroundColor:[UIColor clearColor]];
				[loadingText setTextAlignment:UITextAlignmentCenter];
				loadingText.text = @"Loading...";
				loadingText.font = [UIFont boldSystemFontOfSize:19.0];
				loadingText.textColor = [UIColor whiteColor];
				[_loadingView addSubview:loadingText];
				[loadingText release];
				
				UIActivityIndicatorView *progressIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake([[UIScreen mainScreen] bounds].size.width / 2, [[UIScreen mainScreen] bounds].size.height / 2, 30, 30)];
				progressIndicator.center = CGPointMake([[UIScreen mainScreen] applicationFrame].size.width / 2, [[UIScreen mainScreen] applicationFrame].size.height / 2 + 5);
				[progressIndicator setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhiteLarge];
				[progressIndicator startAnimating];
				[_loadingView addSubview:progressIndicator];
				[progressIndicator release];
				
				//add default cancel button to upper left of view
				UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
				[cancelButton setFrame:CGRectMake(10, 40, kStdButtonWidth - 15, kStdButtonHeight - 10)];
				//cancelButton.center = CGPointMake([[UIScreen mainScreen] applicationFrame].size.width / 2 - 5, [[UIScreen mainScreen] applicationFrame].size.height / 2 + 50);
				[cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
				[cancelButton addTarget:self action:@selector(cancelRequest) forControlEvents:UIControlEventTouchUpInside];
				[_loadingView addSubview:cancelButton];
				
			}else
			{
				//add default cancel button to upper left of view
				UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
				[cancelButton setFrame:CGRectMake(10, 40, kStdButtonWidth - 15, kStdButtonHeight - 10)];
				[cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
				[cancelButton addTarget:self action:@selector(cancelRequest) forControlEvents:UIControlEventTouchUpInside];
				[_loadingView addSubview:cancelButton];				
			}
			
			
			
			[[[_facebookConnection delegate] applicationView] addSubview:_loadingView];
			CATransition *animation = [CATransition animation];
			[animation setDelegate:self];
			[animation setType:_loadingViewTransitionType];
			[animation setSubtype:_loadingViewTransitionSubtype];
			[animation setDuration: LOADING_SCREEN_ANIMATION_DURATION];
			[animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
			[[[[_facebookConnection delegate] applicationView] layer] addAnimation: animation forKey:nil];
		}
	}
	
	
	//now to actually prepare the request!
	
	NSString *applicationName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
	NSString *applicationVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
	NSString *userAgent;
	if(applicationName != nil && applicationVersion != nil)
		userAgent = [NSString stringWithFormat:@"%@ %@", applicationName, applicationVersion];
	else
		userAgent = @"Mobile MKAbeFook";
	
	
	_requestIsDone = NO;
	if(_urlRequestType == MMKPostRequest)
	{
		NSMutableURLRequest *postRequest = [NSMutableURLRequest requestWithURL:_requestURL 
																	 cachePolicy:NSURLRequestReloadIgnoringCacheData 
																 timeoutInterval:[_facebookConnection connectionTimeoutInterval]];
		
		[postRequest setValue:userAgent forHTTPHeaderField:@"User-Agent"];
		
		NSMutableData *postBody = [NSMutableData data];
		NSString *stringBoundary = [NSString stringWithString:@"xXxiFyOuTyPeThIsThEwOrLdWiLlExPlOdExXx"];
		NSString *endLine = [NSString stringWithFormat:@"\r\n--%@\r\n", stringBoundary]; //make this here so we only have to do it once and not during every loop
		NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", stringBoundary];
		[postRequest setHTTPMethod:@"POST"];
		[postRequest addValue:contentType forHTTPHeaderField:@"Content-Type"];
		[postBody appendData:[[NSString stringWithFormat:@"--%@\r\n", stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
		
		//add items that are required by all requests to _parameters dictionary so they are added to the postRequest and we can easily make a sig from them
		[_parameters setValue:MMKFacebookAPIVersion forKey:@"v"];
		[_parameters setValue:[_facebookConnection apiKey] forKey:@"api_key"];
		[_parameters setValue:MMKFacebookFormat forKey:@"format"];
		
		//all other methods require call_id and session_key
		if(![[_parameters valueForKey:@"method"] isEqualToString:@"facebook.auth.getSession"] || ![[_parameters valueForKey:@"method"] isEqualToString:@"facebook.auth.createToken"])
		{
			[_parameters setValue:[_facebookConnection sessionKey] forKey:@"session_key"];
			[_parameters setValue:[_facebookConnection generateTimeStamp] forKey:@"call_id"];
		}
		
		NSEnumerator *e = [_parameters keyEnumerator];
		id key;
		NSString *imageKey = nil;
		while(key = [e nextObject])
		{
			if([[_parameters objectForKey:key] isKindOfClass:[UIImage class]])
			{
				/*SKIPPING PHOTO HANDLING FOR NOW
				NSData *resizedTIFFData = [[_parameters objectForKey:key] TIFFRepresentation];
				NSBitmapImageRep *resizedImageRep = [NSBitmapImageRep imageRepWithData: resizedTIFFData];
				NSDictionary *imageProperties = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat: 1.0] forKey:UIImageCompressionFactor];
				NSData *imageData = [resizedImageRep representationUsingType: NSJPEGFileType properties: imageProperties];
				
				[postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; filename=\"something\"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
				[postBody appendData:[[NSString stringWithString:@"Content-Type: image/jpeg\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];	
				[postBody appendData: imageData];
				[postBody appendData:[endLine dataUsingEncoding:NSUTF8StringEncoding]];
				
				//we need to remove this the image object from the dictionary so we can generate a correct sig from the other values, but we can't do it here or leopard will complain.  so we'll do it OUTSIDE the while loop.
				//[_parameters removeObjectForKey:key];
				imageKey = [NSString stringWithString:key];
				*/
			}else
			{
				[postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
				[postBody appendData:[[_parameters valueForKey:key] dataUsingEncoding:NSUTF8StringEncoding]];
				[postBody appendData:[endLine dataUsingEncoding:NSUTF8StringEncoding]];				
			}
			 
		}
		//we can't remove this during the while loop so we'll do it here
		if(imageKey != nil)
			[_parameters removeObjectForKey:imageKey];
		
		[postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"sig\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
		[postBody appendData:[[_facebookConnection generateSigForParameters:_parameters] dataUsingEncoding:NSUTF8StringEncoding]];
		[postBody appendData:[endLine dataUsingEncoding:NSUTF8StringEncoding]];
		[postRequest setHTTPBody:postBody];
		_dasConnection = [NSURLConnection connectionWithRequest:postRequest delegate:self];
	}
	
	if(_urlRequestType == MMKGetRequest)
	{
		NSURL *theURL = [_facebookConnection generateFacebookURL:_parameters];
		NSMutableURLRequest *getRequest = [NSMutableURLRequest requestWithURL:theURL 
																  cachePolicy:NSURLRequestReloadIgnoringCacheData 
															  timeoutInterval:[_facebookConnection connectionTimeoutInterval]];
		[getRequest setValue:userAgent forHTTPHeaderField:@"User-Agent"];
		_dasConnection = [NSURLConnection connectionWithRequest:getRequest delegate:self];
	}
	 
}


-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[_responseData appendData:data];
}

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	//NSLog(@"response content length :%lld", [response expectedContentLength]);
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	NSString *temp = [[NSString alloc] initWithData:_responseData encoding:NSUTF8StringEncoding];
	CXMLDocument *returnXML = [[[CXMLDocument alloc] initWithXMLString:temp options:0 error:nil] autorelease];
	[temp release];
	
	if([returnXML validFacebookResponse] == NO)
	{
		if([_delegate respondsToSelector:@selector(receivedFacebookXMLErrorResponse:)])
			[_delegate performSelector:@selector(receivedFacebookXMLErrorResponse:) withObject:returnXML];
		
		if([self displayGeneralErrors])
		{
			//TODO: pass back error number etc... instead of generic message
			[_facebookConnection displayGeneralAPIError:@"Response Error" message:@"Facebook gave us some bad information." buttonTitle:@"OK"];			
		}
	}else
	{
		if([_delegate respondsToSelector:_selector])
			[_delegate performSelector:_selector withObject:returnXML];		
	}

	[_responseData setData:[NSData data]];
	_requestIsDone = YES;
	
	[self returnToApplicationView];
	
}

-(void)returnToApplicationView
{
	if([[_facebookConnection delegate] respondsToSelector:@selector(applicationView)])
	{
		if(_displayLoadingSheet == YES)
		{
			/* this doesn't matter right now, for now just remove the _loadingSheet view
			[UIView beginAnimations:nil context:NULL];
			[UIView setAnimationDuration:LOADING_SCREEN_ANIMATION_DURATION];
			[_loadingSheet setFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, 0)];
			[UIView commitAnimations];
			*/
			[_loadingSheet removeFromSuperview];
			
		}else if(_displayLoadingView == YES)
		{
			CATransition *animation = [CATransition animation];
			[animation setDelegate:self];
			[animation setType:_loadingViewTransitionType];
			[animation setSubtype:_loadingViewTransitionSubtype];
			[animation setDuration: LOADING_SCREEN_ANIMATION_DURATION];
			[animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
			[[[[_facebookConnection delegate] applicationView] layer] addAnimation: animation forKey:nil];
			[_loadingView removeFromSuperview];
		}
	}
}


-(void)cancelRequest
{
	if(_requestIsDone == NO)
	{
		//NSLog(@"cancelling request...");
		[_dasConnection cancel];
		_requestIsDone = YES;
	}
	[self returnToApplicationView];
}

//TODO: document that we will automatically present the user with an error message but additional information can be passed or clean up can be done using the delegate calls
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{	
	if([self displayGeneralErrors])
		[_facebookConnection displayGeneralAPIError:@"Connection Error" message:@"Are you connected to the interwebs?" buttonTitle:@"OK"];
	
	if([_delegate respondsToSelector:@selector(facebookRequestFailed:)])
		[_delegate performSelector:@selector(facebookRequestFailed:) withObject:error];
}

//TODO: this should be somthing like setLoadingViewDisplay....
-(void)displayLoadingWithView:(UIView *)view transitionType:(NSString *)transitionType transitionSubtype:(NSString *)transitionSubtype duration:(CFTimeInterval)duration
{
	_displayLoadingSheet = NO;
	_displayLoadingView = YES;
	_loadingView = view;

	transitionType = [transitionType copy];
	[_loadingViewTransitionType release];
	_loadingViewTransitionType = transitionType;
	
	transitionSubtype = [transitionSubtype copy];
	[_loadingViewTransitionSubtype release];
	_loadingViewTransitionSubtype = transitionSubtype;
	
	_loadingViewTransitionDuration = duration;
	
}


@end