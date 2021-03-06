//
//  SUPlayer.h
//  SULoader
//
//  Created by 万众科技 on 16/6/24.
//  Copyright © 2016年 万众科技. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SUResourceLoader.h"

typedef NS_ENUM(NSInteger, SUPlayerState) {
    SUPlayerStateWaiting,
    SUPlayerStatePlaying,
    SUPlayerStatePaused,
    SUPlayerStateStopped,
    SUPlayerStateBuffering,
    SUPlayerStateError
};

@interface SUPlayer : NSObject<SULoaderDelegate>

@property (nonatomic, assign) SUPlayerState state;
@property (nonatomic, assign) CGFloat progress;
@property (nonatomic, assign) CGFloat duration;
@property (nonatomic, assign) CGFloat cacheProgress;

/**
 *  初始化方法，url：歌曲的网络地址或者本地地址
 */
- (instancetype)initWithURL:(NSURL *)url;

/**
 播放视频初始化方法

 @param url 视频链接或者本地地址
 @param layer 显示视频的layer
 @return instance
 */
- (instancetype)initWithURL:(NSURL *)url layer:(AVPlayerLayer *)layer;

/**
 *  播放下一首歌曲，url：歌曲的网络地址或者本地地址
 *  逻辑：stop -> replace -> play
 */
- (void)replaceItemWithURL:(NSURL *)url;

/**
 *  播放
 */
- (void)play;

/**
 *  暂停
 */
- (void)pause;

/**
 *  停止
 */
- (void)stop;

/**
 *  正在播放
 */
- (BOOL)isPlaying;

/**
 *  跳到某个时间进度
 */
- (void)seekToTime:(CGFloat)seconds;

/**
 *  清除缓存
 */
+ (BOOL)clearCache;

@end
