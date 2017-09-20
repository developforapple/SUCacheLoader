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
@property (copy, nonatomic) NSString *tmpDataDirectory;

/**
 媒体文件下载完成之后，如果是完整的，将会被转移到此目录下。默认为 /Documents/SUFileCache/ 目录
 */
@property (copy, nonatomic) NSString *fullyDataDirectory;

/**
 根据url创建key，url将忽略scheme

 @param url url
 @return key
 */
+ (NSString *)keyForURL:(NSString *)url;


/**
 存放一段媒体文件数据。相同的key对应相同的数据。
 data先保存在缓冲区中，当达到足够大小时，写入到文件中。

 @param data 媒体数据
 @param key 对应的key
 */
- (void)storeMediaData:(NSData *)data
                forKey:(NSString *)key;



/**
 读取媒体数据

 @param key 缓存key
 @param range 读取范围
 @return NSData
 */
- (NSData *)readMediaData:(NSString *)key
                    range:(NSRange)range;

/**
 保存临时文件为完整文件。此方法不做文件完整性鉴别。调用后将会删除临时文件。

 @param key 缓存key
 */
- (void)saveMediaTmpDataToFullyData:(NSString *)key;


/**
 如果完整缓存存在，返回它的路径

 @param key 缓存key
 @return file path
 */
- (NSString *)existFullyMediaDataPath:(NSString *)key;


/**
 清理key对应的临时文件

 @param key 缓存key
 */
- (void)clearTmpMediaData:(NSString *)key;


/**
 清理所有临时文件
 */
- (void)clearTmpDatas;


@end
