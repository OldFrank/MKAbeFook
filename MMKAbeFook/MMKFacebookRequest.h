/*
 
 MMKFacebookRequest.h
 Mobile MKAbeFook

 Created by Mike on 3/28/08.
 
 Copyright (c) 2009, Mike Kinney
 All rights reserved.
 
 * Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 
 Neither the name of MKAbeFook nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 */

#import <UIKit/UIKit.h>
#import "MMKFacebook.h"


typedef int MMKFacebookRequestType;
enum
{
	MMKPostRequest,
	MMKGetRequest
};



/*!
 @class MMKFacebookRequest
 
 MMKFacebookRequest handles all requests to the Facebook API.  It can send requests as either POST or GET and return the results to the specified delegate / selector.  This object requires a NSDictionary of parameters that contains the parameters for a request to the Facebook API.  Included in the dictionary must be a key "method" with a value of the full Facebook method being requested, i.e. "facebook.users.getInfo".  Values that are required by all Facebook methods, "v", "api_key", "format", "session_key", "sig", and "call_id", do not need to be in the NSDictionary of parameters you pass into the object, they will be inserted automatically.
 
 
 The MMKFacebookRequest class is be capable of handling most of the methods available by the Facebook API, including facebook.photos.upload.  To upload a photo using this class include a NSImage object in your NSDictionary of parameters you set and set the method key value to "facebook.photos.upload".  The name of the key for the NSImage object can be any string.
 
 See the MKFacebookRequestQueue class for sending a series of requests that are sent incrementally after the previous request has been completed.
 
 Delegate Methods
 
 -(void)facebookResponseReceived:(id)response<br/>
 &nbsp;&nbsp; Called when Facebook returns a valid response.  Passes XML returned by Facebook.
 
 -(void)facebookErrorResponseReceived:(id)response;<br/>
 &nbsp;&nbsp; Called when an error is returned by Facebook.  Passes XML returned by Facebook.
 
 -(void)facebookRequestFailed:(id)error;<br/>
 &nbsp;&nbsp;  Called when the request could not be made.  Passes error received from NSURLConnection.
 
  @version 0.1 and later
 */
@interface MMKFacebookRequest : NSObject {
	
	NSURLConnection *_dasConnection; //internal connection used if object is used multiple times.
	MMKFacebook *_facebookConnection;
	id _delegate;
	SEL _selector;
	NSMutableData *_responseData;
	BOOL _requestIsDone; //how we prevent crashing when trying to cancel the request when it's not active.  isn't there a better way to do this?
	MMKFacebookRequestType _urlRequestType;
	NSMutableDictionary *_parameters;
	NSURL *_requestURL;
	BOOL _displayGeneralErrors;
	int _numberOfRequestAttempts;
	int _requestAttemptCount;
	/* either displayLoadingSheet or displayLoadingView can be used to show progress while data is loading, they can not both be used at the same time. */
	
	/* displays sheet from top of screen while loading */
	BOOL _displayLoadingSheet;
	UIView *_loadingSheet;
	
}
//TODO: documentation
+(id)requestUsingFacebookConnection:(MMKFacebook *)aFacebookConnection delegate:(id)aDelegate selector:(SEL)aSelector;
+(id)requestUsingFacebookConnection:(MMKFacebook *)aFacebookConnection delegate:(id)aDelegate;

-(MMKFacebookRequest *)init;

/*!
 @method initWithFacebookConnection:delegate:selector:
 @param aFacebookConnection A MKFacebook object that has been used to log in a user.  This object must have a valid sessionKey. 
 @param delegate The object that will receive the information returned by Facebook.
 @param selector Method in delegate object to be called and passed the response from Facebook.  This method should accept an (id) as an argument.
 
 This method returns a new MMKFacebookRequest object that can be used to retrieve data from Facebook.
 @version 0.1 and later
 */
-(MMKFacebookRequest *)initWithFacebookConnection:(MMKFacebook *)aFacebookConnection delegate:(id)aDelegate selector:(SEL)aSelector;

/*!
 @method initWithFacebookConnection:parameters:delegate:selector:
 @param aFacebookConnection A MKFacebook object that has been used to log in a user.
 @param parameters NSDictionary containing parameters for requested method.  The dictionary must contain a the key "method" with a value of the full Facebook method being requested, i.e. "facebook.users.getInfo". Values that are required by all Facebook methods, "v", "api_key", "format", "session_key", "sig", and "call_id" do not need to be included in this dictionary.
 @param delegate The object that will receive the information returned by Facebook.
 @param selector Method in delegate object to be called and passed the response from Facebook.  This method should accept an (id) as an argument.
 
 This method returns a new MKFacebookRequest object that can be used to retrieve data from Facebook.
  @version 0.1 and later
 */
-(MMKFacebookRequest *)initWithFacebookConnection:(MMKFacebook *)aFacebookConnection parameters:(NSDictionary *)parameters delegate:(id)aDelegate selector:(SEL)aSelector;

/*!
@method setFacebookConnection:
@param aFacebookConnection A MKFacebook object that has been used to log in a user.  This object must have a valid sessionKey.
  @version 0.1 and later
 */
-(void)setFacebookConnection:(MMKFacebook *)aFacebookConnection;

/*!
 @method setDelegate:
 @param delegate The object that will receive the inforamtion returned by Facebook.
  @version 0.1 and later
 */
-(void)setDelegate:(id)delegate;

/*!
@method setSelector:
 @param selector Method in delegate object to be called and passed the response from Facebook.  This method should accept an (id) as an argument.
  @version 0.1 and later
 */
-(void)setSelector:(SEL)selector;

/*!
 @method setParameters:
 @param parameters NSDictionary containing parameters for requested method.  The dictionary must contain a the key "method" with a value of the full Facebook method being requested, i.e. "facebook.users.getInfo".  Values that are required by all Facebook methods, "v", "api_key", "format", "session_key", "sig", and "call_id" do not need to be included in this dictionary.
  @version 0.1 and later
 */
-(void)setParameters:(NSDictionary *)parameters;

/*!
 @method setURLRequestType:
 @param urlRequestType Accepts MKPostRequest or MKGetRequest to specify request type.
  @version 0.1 and later
 */
-(void)setURLRequestType:(MMKFacebookRequestType)urlRequestType;

/*!
 @method sendRequest
 
 Sends request to Facebook.  The result will be passed to the delegate / selector that were assigned to this object.
  @version 0.1 and later
 */
-(void)sendRequest;

/*!
@method cancelRequest
 
 Cancels the current request if one is in progress.
  @version 0.1 and later
 */
-(void)cancelRequest;

/*!
 @method setDisplayLoadingSheet:
 @param shouldDisplayLoadingSheet BOOL value, YES if you want to display the loading sheet.  NO if you don't.  Default is YES.
 
 Displays a sheet from top of screen with indeterminate progress indicator and cancel button while request is loading.  Automatically removed from screen when request completes.
 @version 0.1 and later
 */
-(void)displayLoadingSheet:(BOOL)shouldDisplayLoadingSheet;


//TODO: Documentation
-(void)setDisplayAPIErrorAlert:(BOOL)aBool;

//TODO: Documentation
-(BOOL)displayAPIErrorAlert;

//TODO: Documentation
-(void)returnToApplicationView;

@end



//TODO: Documentation
@protocol MMKFacebookRequestDelegate

-(void)facebookResponseReceived:(id)response;
-(void)facebookErrorResponseReceived:(id)response;
-(void)facebookRequestFailed:(id)error;

@end