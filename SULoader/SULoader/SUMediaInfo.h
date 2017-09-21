//
//  SUMediaInfo.h
//  Tang
//
//  Created by wwwbbat on 2017/9/21.
//  Copyright © 2017年 tiny. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SUMediaInfo : NSObject <NSCoding>

@property (copy, readonly, nonatomic) NSString *url;

// 默认为hash值
@property (copy, nonatomic) NSString *mediaId;
// 默认为url
@property (copy, nonatomic) NSString *filename;
// 默认为nil
@property (copy, nonatomic) NSString *MIMEType;
// 默认为nil
@property (strong, nonatomic) id<NSCoding> model;


- (instancetype)initWithURL:(NSString *)url;


- (NSData *)data;

+ (instancetype)mediaInfo:(NSData *)data;


@end
