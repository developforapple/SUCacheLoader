//
//  SULoader.m
//  SULoader
//
//  Created by 万众科技 on 16/6/24.
//  Copyright © 2016年 万众科技. All rights reserved.
//

#import "SUResourceLoader.h"
#import <MobileCoreServices/MobileCoreServices.h>

@interface SUResourceLoader ()

@property (nonatomic, strong) NSMutableArray * requestList;
@property (nonatomic, strong) SURequestTask * requestTask;

@end

@implementation SUResourceLoader

- (instancetype)init {
    if (self = [super init]) {
        self.requestList = [NSMutableArray array];
    }
    return self;
}

- (void)stopLoading {
    [self.requestTask cancel];
}

#pragma mark - AVAssetResourceLoaderDelegate
- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest
{
    NSLog(@"WaitingLoadingRequest < requestedOffset = %lld, currentOffset = %lld, requestedLength = %ld >", loadingRequest.dataRequest.requestedOffset, loadingRequest.dataRequest.currentOffset, loadingRequest.dataRequest.requestedLength);
    [self addLoadingRequest:loadingRequest];
    return YES;
}

- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    NSLog(@"CancelLoadingRequest  < requestedOffset = %lld, currentOffset = %lld, requestedLength = %ld >", loadingRequest.dataRequest.requestedOffset, loadingRequest.dataRequest.currentOffset, loadingRequest.dataRequest.requestedLength);
    [self removeLoadingRequest:loadingRequest];
}

#pragma mark - SURequestTaskDelegate
- (void)requestTaskDidUpdateCache
{
    NSLog(@"缓存已更新");
    [self processRequestList];
    if (self.delegate && [self.delegate respondsToSelector:@selector(loader:cacheProgress:)]) {
        CGFloat cacheProgress = (CGFloat)self.requestTask.cacheLength / (self.requestTask.fileLength - self.requestTask.requestOffset);
        [self.delegate loader:self cacheProgress:cacheProgress];
    }
}

- (void)requestTask:(SURequestTask *)task didReceivedResponse:(NSHTTPURLResponse *)response
{
}

- (void)requestTask:(SURequestTask *)task didCompleted:(NSError *)error
{
}

- (void)createMainTask:(AVAssetResourceLoadingRequest *)loadingRequest
{
    self.requestTask = [[SURequestTask alloc] initWithURL:loadingRequest.request.URL.absoluteString cacheType:SUFileCacheTypeMain];
    self.requestTask.requestOffset = [[SUFileCache sharedCache] cacheSize:self.requestTask.cacheKey cacheType:SUFileCacheTypeMain];
    self.requestTask.fileLength = 0;
    self.requestTask.cacheOffset = 0;
    self.requestTask.cacheLength = self.requestTask.requestOffset;
    self.requestTask.delegate = self;
    NSLog(@"创建first request task：%@",self.requestTask);
    [self.requestTask start];
}

- (void)createSeekRequestTask:(AVAssetResourceLoadingRequest *)loadingRequest
{
    long long fileLength = self.requestTask.fileLength;
    [self.requestTask cancel];
    self.requestTask = nil;
    
    self.requestTask = [[SURequestTask alloc] initWithURL:loadingRequest.request.URL.absoluteString cacheType:SUFileCacheTypeTmp];
    self.requestTask.requestOffset = loadingRequest.dataRequest.requestedOffset;
    self.requestTask.fileLength = fileLength;
    self.requestTask.cacheOffset = self.requestTask.requestOffset;
    self.requestTask.cacheLength = 0;
    self.requestTask.delegate = self;
    NSLog(@"创建seek request task:%@",self.requestTask);
    [self.requestTask start];
}

#pragma mark - 处理LoadingRequest
- (void)addLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    [self.requestList addObject:loadingRequest];
    @synchronized(self) {
        
        if (!self.requestTask) {
            // 创建主文件缓存任务
            NSLog(@"准备创建主文件缓存任务");
            [self createMainTask:loadingRequest];
        }else{
            
            long long reqOffset = loadingRequest.dataRequest.requestedOffset;
            if (reqOffset >= self.requestTask.cacheOffset &&
                reqOffset <= self.requestTask.cacheOffset + self.requestTask.cacheLength) {
                // offset位置的数据已缓存
                NSLog(@"当前seek的位置的数据已缓存,缓存起点：%d,缓存长度：%d,缓存终点：%d",self.requestTask.cacheOffset,self.requestTask.cacheLength,self.requestTask.cacheOffset+self.requestTask.cacheLength);
                [self processRequestList];
            }else if (self.seekRequired){
                // seek 操作，重新请求
                NSLog(@"seek的位置，数据未缓存，准备开启新的缓存任务！");
                [self createSeekRequestTask:loadingRequest];
                self.seekRequired = NO;
            }else{
                // 等待数据下载
                NSLog(@"等待数据下载中...");
            }
        }
    }
}

- (void)removeLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    [self.requestList removeObject:loadingRequest];
}

- (void)processRequestList {
    NSMutableArray * finishRequestList = [NSMutableArray array];
    for (AVAssetResourceLoadingRequest * loadingRequest in self.requestList) {
        if ([self finishLoadingWithLoadingRequest:loadingRequest]) {
            [finishRequestList addObject:loadingRequest];
        }
    }
    NSLog(@"移除 %d 个loading request",finishRequestList.count);
    [self.requestList removeObjectsInArray:finishRequestList];
}

- (void)populateContentInfo:(AVAssetResourceLoadingRequest *)loadingRequest
{
    loadingRequest.response = self.requestTask.response;
    
    CFStringRef MIMEType = self.requestTask.response.MIMEType ? (__bridge CFStringRef)(self.requestTask.response.MIMEType) : (__bridge CFStringRef)@"video/mp4";
    CFStringRef contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, MIMEType, NULL);
    long long contentLength = self.requestTask.response ? self.requestTask.response.expectedContentLength : self.requestTask.fileLength ;
    
    loadingRequest.contentInformationRequest.contentType = CFBridgingRelease(contentType);
    loadingRequest.contentInformationRequest.byteRangeAccessSupported = YES;
    loadingRequest.contentInformationRequest.contentLength = contentLength;
}

- (BOOL)finishLoadingWithLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest {
    
    //填充信息
    [self populateContentInfo:loadingRequest];
    
    //读文件，填充数据
    AVAssetResourceLoadingDataRequest *dataRequest = loadingRequest.dataRequest;
    
    NSUInteger requestOffset = dataRequest.currentOffset?:dataRequest.requestedOffset;
    NSUInteger requestLength = dataRequest.requestedLength;
    NSUInteger cacheOffset = self.requestTask.cacheOffset;
    NSUInteger cacheLength = self.requestTask.cacheLength;
    
    NSUInteger readDataOffset = requestOffset - cacheOffset;
    NSUInteger readDataLength = MIN(requestLength, cacheOffset + cacheLength - requestOffset);
    
    NSRange readRange = NSMakeRange(readDataOffset, readDataLength);
    
    NSLog(@"准备填充数据，范围：%d-%d 长度：%d",readDataOffset,readDataOffset+readDataLength,readDataLength);
    
    NSData *data = [[SUFileCache sharedCache] readMediaData:self.requestTask.cacheKey range:readRange cacheType:self.requestTask.cacheType];
    
    NSLog(@"实际填充数据长度：%d",data.length);
    
    [loadingRequest.dataRequest respondWithData:data];
    
    //如果完全响应了所需要的数据，则完成
    NSUInteger loadingToOffset = dataRequest.requestedOffset + dataRequest.requestedLength;
    NSUInteger cacheToOffset = self.requestTask.cacheOffset + self.requestTask.cacheLength;
    if (cacheToOffset >= loadingToOffset) {
        NSLog(@"数据已填充完成，关闭loading requst : %@",loadingRequest);
        [loadingRequest finishLoading];
        return YES;
    }
    return NO;
}

@end
