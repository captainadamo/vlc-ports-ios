/*****************************************************************************
 * VLCLocalPlexFolderListViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2014 VideoLAN. All rights reserved.
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Pierre SAGASPE <pierre.sagaspe # me.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCLocalPlexFolderListViewController.h"
#import "VLCPlexParser.h"
#import "VLCLocalNetworkListCell.h"
#import "VLCAppDelegate.h"
#import "VLCPlaylistViewController.h"
#import "UINavigationController+Theme.h"
#import "VLCDownloadViewController.h"
#import "NSString+SupportedMedia.h"
#import "VLCStatusLabel.h"

@interface VLCLocalPlexFolderListViewController () <UITableViewDataSource, UITableViewDelegate, VLCLocalNetworkListCell, UISearchBarDelegate, UISearchDisplayDelegate>
{
    UIBarButtonItem *_backButton;

    NSMutableArray *_mutableObjectList;

    NSString *_PlexServerName;
    NSString *_PlexServerAddress;
    NSString *_PlexServerPort;
    NSString *_PlexServerPath;
    VLCPlexParser *_PlexParser;

    NSMutableArray *_searchData;
    UISearchBar *_searchBar;
    UISearchDisplayController *_searchDisplayController;
}
@end

@implementation VLCLocalPlexFolderListViewController

- (void)loadView
{
    _tableView = [[UITableView alloc] initWithFrame:[UIScreen mainScreen].bounds style:UITableViewStylePlain];
    _tableView.backgroundColor = [UIColor colorWithWhite:.122 alpha:1.];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.rowHeight = [VLCLocalNetworkListCell heightOfCell];
    self.view = _tableView;
}

- (id)initWithPlexServer:(NSString *)serverName serverAddress:(NSString *)serverAddress portNumber:(NSString *)portNumber atPath:(NSString *)path
{
    self = [super init];
    if (self) {
        _PlexServerName = serverName;
        _PlexServerAddress = serverAddress;
        _PlexServerPort = portNumber;
        _PlexServerPath = path;

        _mutableObjectList = [[NSMutableArray alloc] init];

        _PlexParser = [[VLCPlexParser alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [_mutableObjectList removeAllObjects];
    _mutableObjectList = [_PlexParser PlexMediaServerParser:_PlexServerAddress port:_PlexServerPort navigationPath:_PlexServerPath];

    self.tableView.separatorColor = [UIColor colorWithWhite:.122 alpha:1.];
    self.view.backgroundColor = [UIColor colorWithWhite:.122 alpha:1.];

    NSString *titleValue;
    if ([_PlexServerPath isEqualToString:@""])
        titleValue = _PlexServerName;
    else
        titleValue = [_PlexServerPath lastPathComponent];

    self.title = titleValue;

    _searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    _searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:_searchBar contentsController:self];
    _searchDisplayController.delegate = self;
    _searchDisplayController.searchResultsDataSource = self;
    _searchDisplayController.searchResultsDelegate = self;
    if (SYSTEM_RUNS_IOS7_OR_LATER)
        _searchDisplayController.searchBar.searchBarStyle = UIBarStyleBlack;
    _searchBar.delegate = self;
    self.tableView.tableHeaderView = _searchBar;

    _searchData = [[NSMutableArray alloc] init];
    [_searchData removeAllObjects];
}

- (BOOL)shouldAutorotate
{
    UIInterfaceOrientation toInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && toInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)
        return NO;
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.searchDisplayController.searchResultsTableView)
        return _searchData.count;
    else
        return _mutableObjectList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"PlexCellDetail";

    VLCLocalNetworkListCell *cell = (VLCLocalNetworkListCell *)[[self tableView] dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil)
        cell = [VLCLocalNetworkListCell cellWithReuseIdentifier:CellIdentifier];

    NSMutableArray *ObjList = [[NSMutableArray alloc] init];
    [ObjList removeAllObjects];

    if (tableView == self.searchDisplayController.searchResultsTableView)
        [ObjList addObjectsFromArray:_searchData];
    else
        [ObjList addObjectsFromArray:_mutableObjectList];

    [cell setTitle:[[ObjList objectAtIndex:indexPath.row] objectForKey:@"title"]];

    NSString *thumbPath = [[ObjList objectAtIndex:indexPath.row] objectForKey:@"thumb"];
    if (thumbPath)
        [cell setIconURL:[NSURL URLWithString:thumbPath]];

    if ([[[ObjList objectAtIndex:indexPath.row] objectForKey:@"container"] isEqualToString:@"item"]) {
        NSInteger size = [[[ObjList objectAtIndex:indexPath.row] objectForKey:@"size"] integerValue];
        NSString *mediaSize = [NSByteCountFormatter stringFromByteCount:size countStyle:NSByteCountFormatterCountStyleFile];
        NSString *durationInSeconds = [[ObjList objectAtIndex:indexPath.row] objectForKey:@"duration"];
        [cell setIsDirectory:NO];
        [cell setIcon:[UIImage imageNamed:@"blank"]];
        [cell setSubtitle:[NSString stringWithFormat:@"%@ (%@)", mediaSize, durationInSeconds]];
        [cell setIsDownloadable:YES];
        [cell setDelegate:self];
    } else {
        [cell setIsDirectory:YES];
        [cell setIcon:[UIImage imageNamed:@"folder"]];
    }
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(VLCLocalNetworkListCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIColor *color = (indexPath.row % 2 == 0)? [UIColor blackColor]: [UIColor colorWithWhite:.122 alpha:1.];
    cell.contentView.backgroundColor = cell.titleLabel.backgroundColor = cell.folderTitleLabel.backgroundColor = cell.subtitleLabel.backgroundColor =  color;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray *ObjList = [[NSMutableArray alloc] init];
    [ObjList removeAllObjects];
    NSString *newPath = nil;

    if (tableView == self.searchDisplayController.searchResultsTableView)
        [ObjList addObjectsFromArray:_searchData];
    else
        [ObjList addObjectsFromArray:_mutableObjectList];

    NSString *keyValue = [[ObjList objectAtIndex:indexPath.row] objectForKey:@"key"];

    if ([keyValue rangeOfString:@"library"].location == NSNotFound)
        newPath = [_PlexServerPath stringByAppendingPathComponent:keyValue];
    else
        newPath = keyValue;

    if ([[[ObjList objectAtIndex:indexPath.row] objectForKey:@"container"] isEqualToString:@"item"]) {
        [ObjList removeAllObjects];
        ObjList = [_PlexParser PlexMediaServerParser:_PlexServerAddress port:_PlexServerPort navigationPath:newPath];
        NSString *URLofSubtitle = nil;
        if ([[ObjList objectAtIndex:0] objectForKey:@"keySubtitle"])
            URLofSubtitle = [self _getFileSubtitleFromPlexServer:ObjList modeStream:YES];

        NSURL *itemURL = [NSURL URLWithString:[[ObjList objectAtIndex:0] objectForKey:@"keyMedia"]];
        if (itemURL) {
            VLCAppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
            [appDelegate openMovieWithExternalSubtitleFromURL:itemURL externalSubURL:URLofSubtitle];
        }
    } else {
        VLCLocalPlexFolderListViewController *targetViewController = [[VLCLocalPlexFolderListViewController alloc] initWithPlexServer:_PlexServerName serverAddress:_PlexServerAddress portNumber:_PlexServerPort atPath:newPath];
        [[self navigationController] pushViewController:targetViewController animated:YES];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - Specifics

- (void)_downloadFileFromMediaItem:(NSMutableArray *)mutableMediaObject
{
    NSURL *itemURL = [NSURL URLWithString:[[mutableMediaObject objectAtIndex:0] objectForKey:@"keyMedia"]];

    if (![[itemURL absoluteString] isSupportedFormat]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"FILE_NOT_SUPPORTED", @"") message:[NSString stringWithFormat:NSLocalizedString(@"FILE_NOT_SUPPORTED_LONG", @""), [itemURL absoluteString]] delegate:self cancelButtonTitle:NSLocalizedString(@"BUTTON_CANCEL", @"") otherButtonTitles:nil];
        [alert show];
    } else if (itemURL) {
        NSString *fileName = [[mutableMediaObject objectAtIndex:0] objectForKey:@"namefile"];
        [[(VLCAppDelegate *)[UIApplication sharedApplication].delegate downloadViewController] addURLToDownloadList:itemURL fileNameOfMedia:fileName];
    }
}

- (NSString *)_getFileSubtitleFromPlexServer:(NSMutableArray *)mutableMediaObject modeStream:(BOOL)modeStream
{
    NSURL *url = [NSURL URLWithString:[[mutableMediaObject objectAtIndex:0] objectForKey:@"keySubtitle"]];
    NSString *receivedSub = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
    NSArray *searchPaths =  nil;
    if (modeStream)
        searchPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    else
        searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);

    NSString *directoryPath = [searchPaths objectAtIndex:0];
    NSString *FileSubtitlePath = [[directoryPath stringByAppendingPathComponent:[[[mutableMediaObject objectAtIndex:0] objectForKey:@"namefile"] stringByDeletingPathExtension]] stringByAppendingPathExtension:[[mutableMediaObject objectAtIndex:0] objectForKey:@"codecSubtitle"]];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:FileSubtitlePath]) {
        [fileManager createFileAtPath:FileSubtitlePath contents:nil attributes:nil];
        if (![fileManager fileExistsAtPath:FileSubtitlePath])
            APLog(@"file creation failed, no data was saved");
    }
    [receivedSub writeToFile:FileSubtitlePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    return FileSubtitlePath;
}

#pragma mark - VLCLocalNetworkListCell delegation

- (void)triggerDownloadForCell:(VLCLocalNetworkListCell *)cell
{
    NSMutableArray *ObjList = [[NSMutableArray alloc] init];
    [ObjList removeAllObjects];

    if ([self.searchDisplayController isActive])
        [ObjList addObject:_searchData[[self.searchDisplayController.searchResultsTableView indexPathForCell:cell].row]];
    else
        [ObjList addObject:_mutableObjectList[[self.tableView indexPathForCell:cell].row]];

    NSString *path = [[ObjList objectAtIndex:0] objectForKey:@"key"];
    [ObjList removeAllObjects];
    ObjList = [_PlexParser PlexMediaServerParser:_PlexServerAddress port:_PlexServerPort navigationPath:path];

    if ([[ObjList objectAtIndex:0] objectForKey:@"keySubtitle"])
        [self _getFileSubtitleFromPlexServer:ObjList modeStream:NO];

    [self _downloadFileFromMediaItem:ObjList];
    [cell.statusLabel showStatusMessage:NSLocalizedString(@"DOWNLOADING", @"")];
}

#pragma mark - Search Display Controller Delegate

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [_searchData removeAllObjects];

    for (int i = 0; i < [_mutableObjectList count]; i++) {
        NSRange nameRange;
        nameRange = [[[_mutableObjectList objectAtIndex:i] objectForKey:@"title"] rangeOfString:searchString options:NSCaseInsensitiveSearch];
        if (nameRange.location != NSNotFound)
            [_searchData addObject:_mutableObjectList[i]];
    }
    return YES;
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        tableView.rowHeight = 80.0f;
    else
        tableView.rowHeight = 68.0f;

    tableView.backgroundColor = [UIColor blackColor];
}

@end