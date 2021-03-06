/*****************************************************************************
 * VLCGoogleDriveController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # googlemail.com>
 *          Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "GTLDrive.h"
#import "GTMOAuth2ViewControllerTouch.h"
#import "VLCGoogleDriveConstants.h"

@protocol VLCGoogleDriveController <NSObject>
@required
- (void)mediaListUpdated;

@optional
- (void)operationWithProgressInformationStarted;
- (void)currentProgressInformation:(float)progress;
- (void)updateRemainingTime:(NSString *)time;
- (void)operationWithProgressInformationStopped;
- (void)numberOfFilesWaitingToBeDownloadedChanged;
@end

@interface VLCGoogleDriveController : NSObject

@property (nonatomic, weak) id<VLCGoogleDriveController> delegate;
@property (nonatomic, readonly) NSArray *currentListFiles;
@property (nonatomic, readwrite) BOOL isAuthorized;
@property (nonatomic, retain) GTLServiceDrive *driveService;

+ (VLCGoogleDriveController *)sharedInstance;
- (void)startSession;
- (void)stopSession;
- (void)logout;
- (void)requestDirectoryListingWithFolderId:(NSString *)folderId;
- (BOOL)hasMoreFiles;
- (void)streamFile:(GTLDriveFile *)file;
- (void)downloadFileToDocumentFolder:(GTLDriveFile *)file;

@end
