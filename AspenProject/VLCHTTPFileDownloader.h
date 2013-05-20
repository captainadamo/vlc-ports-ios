//
//  VLCHTTPFileDownloader.h
//  VLC for iOS
//
//  Created by Felix Paul Kühne on 20.05.13.
//  Copyright (c) 2013 VideoLAN. All rights reserved.
//

@class VLCAddMediaViewController;

@interface VLCHTTPFileDownloader : NSObject

@property (nonatomic, retain) VLCAddMediaViewController *mediaViewController;
@property (nonatomic, readonly) BOOL downloadInProgress;

- (void)downloadFileFromURL:(NSURL *)url;

@end