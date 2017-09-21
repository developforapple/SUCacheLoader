//
//  SUFileCache.m
//  SULoader
//
//  Created by 万众科技 on 16/6/28.
//  Copyright © 2016年 万众科技. All rights reserved.
//

#import "SUFileCache.h"

@interface SUFileCache ()
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
        
        NSString *tmp = [NSTemporaryDirectory() stringByAppendingPathComponent:@"SUFileCache"];
        [SUFileCache createDirectoryIfNeed:tmp];
        
        NSString *defaultMainDirectory = [tmp stringByAppendingPathComponent:@"main"];
        NSString *defaultTmpDirectory = [tmp stringByAppendingPathComponent:@"tmp"];
        NSString *defaultFullyDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"MediaFiles"];
        
        [self setDirecotry:defaultMainDirectory forCacheType:SUFileCacheTypeMain];
        [self setDirecotry:defaultTmpDirectory forCacheType:SUFileCacheTypeTmp];
        [self setDirecotry:defaultFullyDirectory forCacheType:SUFileCacheTypeFully];
    }
    return self;
}

- (void)setDirecotry:(NSString *)directory forCacheType:(SUFileCacheType)type
{
    [SUFileCache createDirectoryIfNeed:directory];
    switch (type) {
        case SUFileCacheTypeMain: _mainDirectory = [directory copy];break;
        case SUFileCacheTypeTmp: _tmpDirectory = [directory copy];break;
        case SUFileCacheTypeFully: _fullyDirectory = [directory copy];break;
    }
}

- (NSString *)directoryForType:(SUFileCacheType)type
{
    switch (type) {
        case SUFileCacheTypeMain:   return _mainDirectory;break;
        case SUFileCacheTypeTmp:    return _tmpDirectory;break;
        case SUFileCacheTypeFully:  return _fullyDirectory;break;
    }
    return nil;
}

- (NSString *)cacheFilePath:(NSString *)key cacheType:(SUFileCacheType)type
{
    NSString *directory = [self directoryForType:type];
    NSString *path = [directory stringByAppendingPathComponent:key];
    return path;
}

- (BOOL)cacheFileExists:(NSString *)key cacheType:(SUFileCacheType)type
{
    return [SUFileCache fileExist:[self cacheFilePath:key cacheType:type]];
}

- (NSString *)existsCacheFilePath:(NSString *)key cacheType:(SUFileCacheType)type
{
    NSString *path = [self cacheFilePath:key cacheType:type];
    if ([SUFileCache fileExist:path]) {
        return path;
    }
    return nil;
}

+ (void)createDirectoryIfNeed:(NSString *)directory
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
    return [@(compontents.URL.absoluteString.hash) stringValue];
}

+ (BOOL)fileExist:(NSString *)filePath
{
    return [[NSFileManager defaultManager] fileExistsAtPath:filePath];
}

- (NSFileHandle *)getFileHandle:(NSString *)key cacheType:(SUFileCacheType)type readonly:(BOOL)readonly
{
    NSString *path = [self cacheFilePath:key cacheType:type];
    if (![SUFileCache fileExist:path]) {
        [[NSFileManager defaultManager] createFileAtPath:path contents:[NSData data] attributes:nil];
    }
    if (readonly) {
        return [NSFileHandle fileHandleForReadingAtPath:path];
    }else{
        return [NSFileHandle fileHandleForUpdatingAtPath:path];
    }
}

- (void)storeMediaData:(NSData *)data
                forKey:(NSString *)key
             cacheType:(SUFileCacheType)type
{
    if (!data || !key || type == SUFileCacheTypeFully) return;
    
    NSFileHandle *handle = [self getFileHandle:key cacheType:type readonly:NO];
    [handle seekToEndOfFile];
    [handle writeData:data];
}

- (void)resetMediaData:(NSString *)key
             cacheType:(SUFileCacheType)type
{
    NSString *path = [self cacheFilePath:key cacheType:type];
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
}

- (NSData *)readMediaData:(NSString *)key
                    range:(NSRange)range
                cacheType:(SUFileCacheType)type
{
    NSFileHandle *handle = [self getFileHandle:key cacheType:type readonly:YES];
    long long curLength = [handle seekToEndOfFile];
    if (curLength >= NSMaxRange(range)) {
        [handle seekToFileOffset:range.location];
        return [handle readDataOfLength:range.length];
    }
    return nil;
}

- (BOOL)isMainDataCompleted:(NSString *)key
                     expect:(long long)expectedLength
{
    NSString *path = [self cacheFilePath:key cacheType:SUFileCacheTypeMain];
    NSNumber *fileSize = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil][NSFileSize];
    return fileSize.longLongValue == expectedLength;
}

- (void)saveMainDataAsFullyData:(NSString *)key
{
    NSString *mainPath = [self cacheFilePath:key cacheType:SUFileCacheTypeMain];
    NSString *fullyPath = [self cacheFilePath:key cacheType:SUFileCacheTypeFully];
    if (![SUFileCache fileExist:mainPath]) return;
    [[NSFileManager defaultManager] removeItemAtPath:fullyPath error:nil];
    [[NSFileManager defaultManager] moveItemAtPath:mainPath toPath:fullyPath error:nil];
}

- (void)clear:(SUFileCacheType)type
{
    NSString *directory = [self directoryForType:type];
    [[NSFileManager defaultManager] removeItemAtPath:directory error:nil];
    [SUFileCache createDirectoryIfNeed:directory];
}

- (void)clearAll
{
    [self clear:SUFileCacheTypeTmp];
    [self clear:SUFileCacheTypeMain];
    [self clear:SUFileCacheTypeFully];
}

- (long long)diskUsageSize:(SUFileCacheType)type
{
    NSString *directory = [self directoryForType:type];
    NSNumber *size = [[NSFileManager defaultManager] attributesOfItemAtPath:directory error:nil][NSFileSize];
    return size.longLongValue;
}

- (long long)cacheSize:(NSString *)key cacheType:(SUFileCacheType)type
{
    NSString *path = [self cacheFilePath:key cacheType:type];
    NSNumber *size = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil][NSFileSize];
    return size.longLongValue;
}

@end
