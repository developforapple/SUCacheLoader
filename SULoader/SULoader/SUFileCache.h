//
//  SUFileCache.h
//  SULoader
//
//  Created by 万众科技 on 16/6/28.
//  Copyright © 2016年 万众科技. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SULoaderCategory.h"


@interface SUFileCache : NSObject

/**
 共享缓存

 @return instance
 */
+ (instancetype)sharedCache;

/**
 未生成完整媒体文件之前，临时文件存放的位置。默认为 /tmp/SUFileCache/ 目录
 */
@property (copy, nonatomic) NSString *tmpDirectory;

/**
 媒体文件下载完成之后，如果是完整的，将会被转移到此目录下。默认为 /Documents/SUFileCache/ 目录
 */
@property (copy, nonatomic) NSString *solidDirectory;


/**
 存放一段媒体文件数据。key相同的数据将存放在同一个文件中。
 默认使用内存存放媒体数据。建议使用disk存放。
 同一个媒体使用了本地缓存后将不再使用内存缓存。

 @param data 媒体数据
 @param key 对应的key
 @param completion 回调
 */
- (void)storeMediaData:(NSData *)data
                forKey:(NSString *)key
            completion:(void (^)(void))completion;

/**
 存放一段媒体文件数据。key相同的数据将存放在同一个文件中。
 当同一个媒体，先使用了内存缓存后再使用本地缓存，将会自动将内存缓存都转为本地缓存

 @param data 媒体数据
 @param key 对应的key
 @param disk 是否是保存为本地文件
 @param completion 回调
 */
- (void)storeMediaData:(NSData *)data
                forKey:(NSString *)key
                toDisk:(BOOL)disk
            completion:(void (^)(void))completion;


/**
 *  创建临时文件
 */
+ (BOOL)createTempFile;

/**
 *  往临时文件写入数据
 */
+ (void)writeTempFileData:(NSData *)data;

/**
 *  读取临时文件数据
 */
+ (NSData *)readTempFileDataWithOffset:(NSUInteger)offset length:(NSUInteger)length;

/**
 *  保存临时文件到缓存文件夹
 */
+ (void)cacheTempFileWithFileName:(NSString *)name;

/**
 *  是否存在缓存文件 存在：返回文件路径 不存在：返回nil
 */
+ (NSString *)cacheFileExistsWithURL:(NSURL *)url;

/**
 *  清空缓存文件
 */
+ (BOOL)clearCache;

@end
