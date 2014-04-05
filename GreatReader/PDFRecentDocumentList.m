//
//  PDFRecentDocumentList.m
//  GreatReader
//
//  Created by MIYAMOTO Shohei on 2014/02/06.
//  Copyright (c) 2014 MIYAMOTO Shohei. All rights reserved.
//

#import "PDFRecentDocumentList.h"

#import "Folder.h"
#import "NSArray+GreatReaderAdditions.h"
#import "NSFileManager+GreatReaderAdditions.h"
#import "PDFDocument.h"

@interface PDFRecentDocumentList ()
@property (nonatomic, readwrite, strong) NSArray *documents;
@end

@implementation PDFRecentDocumentList

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSArray *list = [self load];
        self.documents = list;
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(fileRemoved:)
                                                   name:FolderFileRemovedNotification
                                                 object:nil];
    }
    return self;
}

#pragma mark - Save, Load

- (NSString *)path
{
    NSString * const name = @"PDFRecentDocumentList";
    return [NSString stringWithFormat:@"%@/%@",
                     [NSFileManager grt_privateDocumentsPath],
                     name];
}

- (void)save
{
    NSString *dirPath = [NSFileManager grt_privateDocumentsPath];
    NSFileManager *fm = [NSFileManager new];
    if (![fm fileExistsAtPath:dirPath]) {
        [fm grt_createPrivateDocumentsDirectory];
    }
    [NSKeyedArchiver archiveRootObject:self.documents
                                toFile:self.path];
}

- (NSArray *)load
{
    NSArray *list = [NSKeyedUnarchiver unarchiveObjectWithFile:self.path];
    return [list grt_filter:^(PDFDocument *document) {
        return (BOOL)!document.fileNotExist;
    }];
}

#pragma mark -

- (NSMutableArray *)documentsProxy
{
    return [self mutableArrayValueForKey:@"documents"];
}

#pragma mark -

- (PDFDocument *)open:(PDFDocument *)document
{
    PDFDocument *doc = [self findDocumentInHistory:document];
    if (doc) {
        [self.documentsProxy removeObject:doc];
    } else {
        doc = document;
    }
    [self.documentsProxy insertObject:doc
                                   atIndex:0];
    [self save];
    
    return doc;
}

- (PDFDocument *)findDocumentInHistory:(PDFDocument *)document
{
    if ([self.documentsProxy containsObject:document]) {
        NSUInteger index = [self.documentsProxy indexOfObject:document];
        return [self.documentsProxy objectAtIndex:index];
    }
    return nil;
}

- (NSUInteger)count
{
    return self.documentsProxy.count;
}

- (PDFDocument *)documentAtIndex:(NSUInteger)index
{
    return [self.documentsProxy objectAtIndex:index];
}

#pragma mark - Notifications

- (void)fileRemoved:(NSNotification *)notification
{
    BOOL save = NO;
    
    NSArray *files = notification.userInfo[@"Files"];
    for (PDFDocument *document in [self.documents copy]) {
        for (File *file in files) {
            if ([document isEqual:file]) {
                [self.documentsProxy removeObject:document];
                save = YES;
            }
        }        
    }

    if (save) {
        [self save];
    }
}

@end
