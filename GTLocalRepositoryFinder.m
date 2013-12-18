//
//  GTLocalRepositoryFinder.m
//  Tower
//
//  Created by Marc Beyerlin on 17.12.13.
//  Copyright (c) 2013 fournova GmbH. All rights reserved.
//

#import "GTLocalRepositoryFinder.h"

@interface GTLocalRepositoryFinder ()
@property (nonatomic) NSArray *searchScopes;
@property (nonatomic) NSMutableArray *observers;
@end

@implementation GTLocalRepositoryFinder


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Initialization

- (id)init
{
    NSArray *searchScopes = [NSArray arrayWithObjects:NSMetadataQueryUserHomeScope, nil];
    return [self initWithSearchScopes:searchScopes];
}

- (id)initWithSearchScopes:(NSArray *)searchScopes
{
    NSParameterAssert(searchScopes);

    self = [super init];
    if (self) {
        _metadataSearch = [[NSMetadataQuery alloc] init];
        _searchScopes = searchScopes;
        _repositories = [NSMutableArray new];
        _observers = [NSMutableArray new];
    }
    return self;
}

- (void)dealloc
{
    [self stopQuery];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Spotlight search

- (void)startQuery
{
    [self registerObservers];
    [self setSearchPredicate];
    [self setSearchScope];
    [self setSortDescriptors];

    [self.metadataSearch startQuery];
}

- (void)stopQuery
{
    [self.metadataSearch stopQuery];
    [self unregisterObservers];
}

- (void)setSortDescriptors
{
    NSSortDescriptor *sortKeys = [[NSSortDescriptor alloc] initWithKey:(id)kMDItemDisplayName ascending:YES];
    [self.metadataSearch setSortDescriptors:[NSArray arrayWithObject:sortKeys]];
}

- (void)setSearchScope
{
    [self.metadataSearch setSearchScopes:self.searchScopes];
}

- (void)setSearchPredicate
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"NOT %K.pathExtension = ''", NSMetadataItemFSNameKey];
    [self.metadataSearch setPredicate:predicate];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Observers

- (void)registerObservers
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    __weak typeof(self) weakSelf = self;
    id observer;
    
    observer = [notificationCenter addObserverForName:NSMetadataQueryDidUpdateNotification object:self.metadataSearch queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notification) {
        [weakSelf queryDidUpdate:notification];
    }];
    
    [self.observers addObject:observer];
    
    observer = [notificationCenter addObserverForName:NSMetadataQueryDidFinishGatheringNotification object:self.metadataSearch queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notification) {
        [weakSelf initalGatherComplete:notification];
    }];
    
    [self.observers addObject:observer];
}

- (void)unregisterObservers
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    for (id observer in self.observers) {
        [notificationCenter removeObserver:observer];
    }
    
    [self.observers removeAllObjects];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Delegate NSMetadataQuery

- (void)queryDidUpdate:(NSNotification *)notification
{
    [self.metadataSearch disableUpdates];
    
    NSMutableArray *repositories = [self extractRepositoriesFromMetadataSearch];
    [self.repositories addObjectsFromArray:repositories];
    [self controllerQueryDidUpdate:repositories];
    
    [self.metadataSearch enableUpdates];
}

- (void)initalGatherComplete:(NSNotification *)notification
{
    [self.metadataSearch disableUpdates];
    
    [self.repositories addObjectsFromArray:[self extractRepositoriesFromMetadataSearch]];
    [self controllerDidInitalGather:self.repositories];
    
    [self.metadataSearch enableUpdates];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Extract repositories from Spotlight search result

- (NSMutableArray *)extractRepositoriesFromMetadataSearch
{
    NSMutableArray *repositories = [NSMutableArray new];

    NSUInteger i=0;
    for (i=0; i < [self.metadataSearch resultCount]; i++) {
        NSMetadataItem *metaDataItem = [self.metadataSearch resultAtIndex:i];
        NSString *filePath = [metaDataItem valueForAttribute:(NSString *)kMDItemPath];
        
        if ([self filePathIsGitRepository:filePath]) {
            if (![self.repositories containsObject:filePath]) {
                [repositories addObject:filePath];
            }
        }
    }
    return repositories;
}

- (BOOL)filePathIsGitRepository:(NSString *)filePath
{
    BOOL isDir, isGit;
    
    [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDir];
    
    if(isDir) {
        NSString *fileExistsAtPath = [NSString stringWithFormat:@"%@/.git", filePath];
        [[NSFileManager defaultManager] fileExistsAtPath:fileExistsAtPath isDirectory:&isGit];
        
        if(isGit) {
            return YES;
        }
    }
    return NO;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Responding to Controller Events

- (void)controllerQueryDidUpdate:(NSArray *)repositories
{
    FNMainThreadAssert();
    if (self.delegate && [self.delegate respondsToSelector:@selector(queryDidUpdate:)]) {
        [self.delegate queryDidUpdate:repositories];
    }
}

- (void)controllerDidInitalGather:(NSArray *)repositories
{
    FNMainThreadAssert();
    if (self.delegate && [self.delegate respondsToSelector:@selector(didInitalGather:)]) {
        [self.delegate didInitalGather:repositories];
    }
}

@end

