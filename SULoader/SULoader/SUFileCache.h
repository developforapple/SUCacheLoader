//
//  SUFileCache.h
//  SULoader
//
//  Created by 万众科技 on 16/6/28.
//  Copyright © 2016年 万众科技. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, SUFileCacheType) {
    SUFileCacheTypeMain,    //从0开始缓存，不完整
    SUFileCacheTypeTmp,     //从非0开始缓存，不完整
    SUFileCacheTypeFully,   //从0开始缓存，完整
};

@interface SUFileCache : NSObject

+ (instancetype)sharedCache;

// 默认 /tmp/SUFileCache/main
@property (copy, readonly, nonatomic) NSString *mainDirectory;
// 默认 /tmp/SUFileCache/tmp
@property (copy, readonly, nonatomic) NSString *tmpDirectory;
// 默认 /Documents/MediaFiles
@property (copy, readonly, nonatomic) NSString *fullyDirectory;

// 缓存文件目录
- (void)setDirecotry:(NSString *)directory forCacheType:(SUFileCacheType)type;
- (NSString *)directoryForType:(SUFileCacheType)type;

// 缓存文件状态
- (NSString *)cacheFilePath:(NSString *)key cacheType:(SUFileCacheType)type;
- (BOOL)cacheFileExists:(NSString *)key cacheType:(SUFileCacheType)type;
- (NSString *)existsCacheFilePath:(NSString *)key cacheType:(SUFileCacheType)type;

// 根据url创建key，url将忽略scheme
+ (NSString *)keyForURL:(NSString *)url;

// 保存数据到对应的缓存文件中. type为SUFileCacheTypeFully无效
- (void)storeMediaData:(NSData *)data
                forKey:(NSString *)key
             cacheType:(SUFileCacheType)type;

// 重置缓存
- (void)resetMediaData:(NSString *)key
             cacheType:(SUFileCacheType)type;

// 读取缓存数据。range是相对于当前缓存文件的range
- (NSData *)readMediaData:(NSString *)key
                    range:(NSRange)range
                cacheType:(SUFileCacheType)type;

// 主体文件是否完整
- (BOOL)isMainDataCompleted:(NSString *)key
                     expect:(long long)expectedLength;

// 将主体文件保存到完整文件夹。不会检查完整性。完成后将会删除主文件
- (void)saveMainDataAsFullyData:(NSString *)key;

// 清理数据
- (void)clear:(SUFileCacheType)type;
- (void)clearAll;

// 获取磁盘用量
- (long long)diskUsageSize:(SUFileCacheType)type;
- (long long)cacheSize:(NSString *)key cacheType:(SUFileCacheType)type;

@end
