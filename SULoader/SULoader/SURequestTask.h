//
//  SURequestTask.h
//  SULoader
//
//  Created by 万众科技 on 16/6/28.
//  Copyright © 2016年 万众科技. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SUFileCache.h"

#define RequestTimeout 10.0

@class SURequestTask;

@protocol SURequestTaskDelegate <NSObject>
@required
- (void)requestTaskDidUpdateCache; //更新缓冲进度代理方法
@optional
- (void)requestTask:(SURequestTask *)task didReceivedResponse:(NSHTTPURLResponse *)response;
- (void)requestTask:(SURequestTask *)task didCompleted:(NSError *)error;
@end

@interface SURequestTask : NSObject

// 当前使用的缓存类型。根据场景不同，缓存类型也不同
@property (nonatomic, assign) SUFileCacheType cacheType;
// 缓存的key
@property (nonatomic, copy) NSString *cacheKey;

@property (nonatomic, weak) id<SURequestTaskDelegate> delegate;
@property (nonatomic, strong) NSURL * requestURL; //请求网址
@property (nonatomic, assign) NSUInteger requestOffset; //请求起始位置
@property (nonatomic, assign) NSUInteger fileLength; //文件长度
@property (nonatomic, assign) NSUInteger cacheOffset; //缓存起始位置
@property (nonatomic, assign) NSUInteger cacheLength; //缓冲长度
@property (nonatomic, getter=isCanceled, readonly, assign) BOOL cancel; //是否取消请求
@property (nonatomic, strong) NSHTTPURLResponse *response; //服务器的响应

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithURL:(NSString *)url cacheType:(SUFileCacheType)type;

// 开始请求
- (void)start;

// 取消请求
- (void)cancel;

// 清理缓存文件
- (void)clearCache;

@end
