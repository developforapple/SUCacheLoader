//
//  SURequestTask.m
//  SULoader
//
//  Created by 万众科技 on 16/6/28.
//  Copyright © 2016年 万众科技. All rights reserved.
//

#import "SURequestTask.h"
#import "NSURL+SULoader.h"

@interface SURequestTask ()<NSURLConnectionDataDelegate, NSURLSessionDataDelegate>

@property (nonatomic, strong) NSURLSession * session;              //会话对象
@property (nonatomic, strong) NSURLSessionDataTask * task;         //任务

@end

@implementation SURequestTask

- (instancetype)initWithURL:(NSString *)url cacheType:(SUFileCacheType)type
{
    self = [super init];
    if (self) {
        self.requestURL = [NSURL URLWithString:url];
        self.cacheKey = [SUFileCache keyForURL:url];
        self.cacheType = type;
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"\n%@ requestOffset: %d\n fileLength:%d\n缓存类型：%d\n缓存起点:%d\n缓存长度:%d\n缓存终点:%d\n",[super description],_requestOffset,_fileLength,_cacheType,_cacheOffset,_cacheLength,_cacheOffset+_cacheLength];
}

- (void)start
{
    NSLog(@"准备启动下载任务");
    self.cacheKey = [SUFileCache keyForURL:self.requestURL.absoluteString];
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:[self.requestURL originalSchemeURL] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:RequestTimeout];
    if (self.requestOffset > 0) {
        [request addValue:[NSString stringWithFormat:@"bytes=%ld-%ld", self.requestOffset, self.fileLength - 1] forHTTPHeaderField:@"Range"];
    }
    NSLog(@"请求头：%@",request.allHTTPHeaderFields);
    self.session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    self.task = [self.session dataTaskWithRequest:request];
    [self.task resume];
    NSLog(@"下载任务启动！");
}

- (void)cancel
{
    NSLog(@"取消下载任务：%@",self);
    _cancel = YES;
    [self.task cancel];
    [self.session invalidateAndCancel];
}

- (void)clearCache
{
    [[SUFileCache sharedCache] resetMediaData:self.cacheKey cacheType:self.cacheType];
}

#pragma mark - NSURLSessionDataDelegate
//服务器响应
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    if (self.cancel) return;
    NSLog(@"response: %@",response);
    completionHandler(NSURLSessionResponseAllow);
    NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *)response;
    self.response = httpResponse;
    NSString * contentRange = [[httpResponse allHeaderFields] objectForKey:@"Content-Range"];
    NSString * fileLength = [[contentRange componentsSeparatedByString:@"/"] lastObject];
    self.fileLength = fileLength.integerValue > 0 ? fileLength.integerValue : response.expectedContentLength;
    
    if ([self.delegate respondsToSelector:@selector(requestTask:didReceivedResponse:)]) {
        [self.delegate requestTask:self didReceivedResponse:httpResponse];
    }
}

//服务器返回数据 可能会调用多次
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    if (self.cancel) return;
    
    [[SUFileCache sharedCache] storeMediaData:data forKey:self.cacheKey cacheType:self.cacheType];
    
    self.cacheLength += data.length;
    if (self.delegate && [self.delegate respondsToSelector:@selector(requestTaskDidUpdateCache)]) {
        [self.delegate requestTaskDidUpdateCache];
    }
}

//请求完成会调用该方法，请求失败则error有值
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (self.cancel) {
        NSLog(@"下载取消");
    }else {
        if (!error && self.cacheType == SUFileCacheTypeMain){
            [[SUFileCache sharedCache] saveMainDataAsFullyData:self.cacheKey];
        }
        if ([self.delegate respondsToSelector:@selector(requestTask:didCompleted:)]) {
            [self.delegate requestTask:self didCompleted:error];
        }
    }
}

@end
