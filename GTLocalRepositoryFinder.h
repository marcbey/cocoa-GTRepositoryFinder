//
//  GTLocalRepositoryFinder.h
//  Tower
//
//  Created by Marc Beyerlin on 17.12.13.
//  Copyright (c) 2013 fournova GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GTLocalRepositoryFinderDelegate.h"

@interface GTLocalRepositoryFinder : NSObject

@property (nonatomic, strong) NSMetadataQuery *metadataSearch;
@property (nonatomic, strong) NSMutableArray *repositories;
@property (nonatomic, weak) id<GTLocalRepositoryFinderDelegate> delegate;

- (id)init;
- (id)initWithSearchScopes:(NSArray *)searchScopes;

- (void)startQuery;
- (void)stopQuery;

@end

