//
//  SUFileCache.m
//  SULoader
//
//  Created by 万众科技 on 16/6/28.
//  Copyright © 2016年 万众科技. All rights reserved.
//

#import "SUFileCache.h"

@interface SUFileCache ()
@property (strong, nonatomic) NSMutableDictionary<NSString *, NSFileHandle *> *fileHandles;
@end

@implementation SUFileCache

+ (instancetype)sharedCache
{
    static SUFileCache *cache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [SUFileCache new];
    });
    return cache;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.tmpDataDirectory = [NSTemporaryDirectory() stringByAppendingPathComponent:@"SUFileCache"];
        self.fullyDataDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"SUFileCache"];
        
        self.fileHandles = [NSMutableDictionary dictionary];
        
    }
    return self;
}

+ (void)createDorectoryIfNeed:(NSString *)directory
{
    BOOL isDirectory;
    if ([[NSFileManager defaultManager] fileExistsAtPath:directory isDirectory:&isDirectory]) {
        if (!isDirectory) {
            [[NSFileManager defaultManager] removeItemAtPath:directory error:nil];
            [[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil];
        }
    }else{
        [[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

+ (NSString *)keyForURL:(NSString *)url
{
    NSURLComponents *compontents = [NSURLComponents componentsWithString:url];
    compontents.scheme = nil;
    return compontents.URL.absoluteString;
}

- (void)setTmpDataDirectory:(NSString *)tmpDataDirectory
{
    _tmpDataDirectory = [tmpDataDirectory copy];
    [SUFileCache createDorectoryIfNeed:_tmpDataDirectory];
}

- (void)setFullyDataDirectory:(NSString *)fullyDataDirectory
{
    _fullyDataDirectory = [fullyDataDirectory copy];
    [SUFileCache createDorectoryIfNeed:fullyDataDirectory];
}

+ (BOOL)fileExist:(NSString *)filePath
{
    return [[NSFileManager defaultManager] fileExistsAtPath:filePath];
}

- (NSString *)tmpDataFilePath:(NSString *)key
{
    return [_tmpDataDirectory stringByAppendingPathComponent:key];
}

- (NSString *)fullyDataFilePath:(NSString *)key
{
    return [_fullyDataDirectory stringByAppendingPathComponent:key];
}

- (NSFileHandle *)tmpFileHandleForKey:(NSString *)key
{
    NSString *path = [self tmpDataFilePath:key];
    if (![SUFileCache fileExist:path]) {
        [[NSFileManager defaultManager] createFileAtPath:path contents:[NSData data] attributes:nil];
    }
    NSFileHandle *handle = self.fileHandles[key];
    if (!handle) {
        handle = [NSFileHandle fileHandleForUpdatingAtPath:path];
        self.fileHandles[key] = handle;
    }
    return handle;
}

- (void)storeMediaData:(NSData *)data
                forKey:(NSString *)key
{
    NSFileHandle *handle = [self tmpFileHandleForKey:key];
    [handle seekToEndOfFile];
    [handle writeData:data];
}

- (NSData *)readMediaData:(NSString *)key
                    range:(NSRange)range
{
    NSString *fullyFilePath = [self fullyDataFilePath:key];
    if ([SUFileCache fileExist:fullyFilePath]) {
        // 从完整文件去读
        NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:fullyFilePath];
        [handle seekToFileOffset:range.location];
        return [handle readDataOfLength:range.length];
    }
    
    // 从临时文件去读
    NSFileHandle *handle = [self tmpFileHandleForKey:key];
    long long length = [handle seekToEndOfFile];
    if (length >= NSMaxRange(range)) {
        [handle seekToFileOffset:range.location];
        return [handle readDataOfLength:range.length];
    }
    return nil;
}

- (void)saveMediaTmpDataToFullyData:(NSString *)key
{
    NSString *tmpFilePath = [self tmpDataFilePath:key];
    if (![SUFileCache fileExist:tmpFilePath]) return;
    
    NSString *fullyFilePath = [self fullyDataFilePath:key];
    
    [[NSFileManager defaultManager] removeItemAtPath:fullyFilePath error:nil];
    [[NSFileManager defaultManager] moveItemAtPath:tmpFilePath toPath:fullyFilePath error:nil];
}

- (NSString *)existFullyMediaDataPath:(NSString *)key
{
    NSString *path = [self fullyDataFilePath:key];
    if ([SUFileCache fileExist:path]) {
        return path;
    }
    return nil;
}

- (void)clearTmpMediaData:(NSString *)key
{
    self.fileHandles[key] = nil;
    NSString *tmpFilePath = [self tmpDataFilePath:key];
    [[NSFileManager defaultManager] removeItemAtPath:tmpFilePath error:nil];
}

- (void)clearTmpDatas
{
    [self.fileHandles removeAllObjects];
    [[NSFileManager defaultManager] removeItemAtPath:_tmpDataDirectory error:nil];
    [SUFileCache createDorectoryIfNeed:_tmpDataDirectory];
}

@end
