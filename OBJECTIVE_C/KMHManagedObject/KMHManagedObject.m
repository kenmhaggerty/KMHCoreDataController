//
//  KMHManagedObject.m
//  KMHCoreDataController
//
//  Created by Ken M. Haggerty on 4/13/16.
//  Copyright © 2016 Ken M. Haggerty. All rights reserved.
//

#pragma mark - // NOTES (Private) //

#pragma mark - // IMPORTS (Private) //

#import "KMHManagedObject.h"

#pragma mark - // KMHManagedObject //

#pragma mark Notifications

NSString * _Nonnull const KMHManagedObjectNotificationObjectKey = @"object";

NSString * _Nonnull const KMHManagedObjectWillBeDeallocatedNotification = @"kNotificationKMHManagedObject_WillBeDeallocated";
NSString * _Nonnull const KMHManagedObjectWasCreatedNotification = @"kNotificationKMHManagedObject_WasCreated";
NSString * _Nonnull const KMHManagedObjectWasFetchedNotification = @"kNotificationKMHManagedObject_WasFetched";
NSString * _Nonnull const KMHManagedObjectWillSaveNotification = @"kNotificationKMHManagedObject_WillSave";
NSString * _Nonnull const KMHManagedObjectDidSaveNotification = @"kNotificationKMHManagedObject_DidSave";
NSString * _Nonnull const KMHManagedObjectWillBeDeletedNotification = @"kNotificationKMHManagedObject_WillBeDeleted";

#pragma mark Methods

@interface KMHManagedObject ()
@property (nonatomic, strong, readwrite) NSSet *changedKeys;
@property (nonatomic, readwrite) BOOL isSaving;
@property (nonatomic, readwrite) BOOL willBeDeleted;
@property (nonatomic, readwrite) BOOL wasDeleted;
@end

@implementation KMHManagedObject

#pragma mark Setters

@synthesize instantiatedAt = _instantiatedAt;
@synthesize changedKeys = _changedKeys;
@synthesize isSaving = _isSaving;
@synthesize willBeDeleted = _willBeDeleted;
@synthesize wasDeleted = _wasDeleted;
@synthesize parentIsDeleted = _parentIsDeleted;

#pragma mark Inits and Loads

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] postNotificationName:KMHManagedObjectWillBeDeallocatedNotification object:self userInfo:nil];
}

- (void)awakeFromInsert {
    [super awakeFromInsert];
    
    [self setup];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:KMHManagedObjectWasCreatedNotification object:self userInfo:nil];
}

- (void)awakeFromFetch {
    [super awakeFromFetch];
    
    [self setup];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:KMHManagedObjectWasFetchedNotification object:self userInfo:nil];
}

- (void)willSave {
    self.isSaving = YES;
    
    [super willSave];
    
    if (self.isUpdated && !self.isInserted) {
        self.changedKeys = [NSMutableSet setWithArray:self.changedValues.allKeys];
    }
    
    NSDictionary *userInfo = self.changedKeys ? @{KMHManagedObjectNotificationObjectKey : self.changedKeys} : @{};
    [[NSNotificationCenter defaultCenter] postNotificationName:KMHManagedObjectWillSaveNotification object:self userInfo:userInfo];
}

- (void)didSave {
    if (self.willBeDeleted) {
        self.willBeDeleted = NO;
        self.wasDeleted = YES;
    }
    
    if (self.changedKeys && !self.inserted) { // !self.isDeleted &&
        NSDictionary *userInfo = @{KMHManagedObjectNotificationObjectKey : self.changedKeys};
        [[NSNotificationCenter defaultCenter] postNotificationName:KMHManagedObjectDidSaveNotification object:self userInfo:userInfo];
        self.changedKeys = nil;
    }
    
    [super didSave];
    
    self.isSaving = NO;
}

- (void)prepareForDeletion {
    self.willBeDeleted = YES;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:KMHManagedObjectWillBeDeletedNotification object:self userInfo:nil];
    
    [super prepareForDeletion];
}

#pragma mark - Public Methods

- (void)setup {
    _instantiatedAt = [NSDate date];
    _isSaving = NO;
    _wasDeleted = NO;
    _parentIsDeleted = NO;
}

@end
