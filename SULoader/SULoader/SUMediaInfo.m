//
//  SUMediaInfo.m
//  Tang
//
//  Created by wwwbbat on 2017/9/21.
//  Copyright © 2017年 tiny. All rights reserved.
//

#import "SUMediaInfo.h"

@implementation SUMediaInfo

- (instancetype)initWithURL:(NSString *)url
{
    self = [super init];
    if (self) {
        _mediaId = [@(url.hash) stringValue];
        _url = url;
        _filename = url.lastPathComponent;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    if (self.url) {
        [aCoder encodeObject:self.url forKey:@"url"];
    }
    if (self.mediaId) {
        [aCoder encodeObject:self.mediaId forKey:@"mediaId"];
    }
    if (self.filename) {
        [aCoder encodeObject:self.filename forKey:@"filename"];
    }
    if (self.MIMEType) {
        [aCoder encodeObject:self.MIMEType forKey:@"MIMEType"];
    }
    if (self.model) {
        [aCoder encodeObject:self.model forKey:@"model"];
    }
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        self->_url = [aDecoder decodeObjectForKey:@"url"];
        self->_mediaId = [aDecoder decodeObjectForKey:@"mediaId"];
        self->_filename = [aDecoder decodeObjectForKey:@"filename"];
        self->_MIMEType = [aDecoder decodeObjectForKey:@"MIMEType"];
        self->_model = [aDecoder decodeObjectForKey:@"model"];
    }
    return self;
}

- (NSData *)data
{
    return [NSKeyedArchiver archivedDataWithRootObject:self];
}

+ (instancetype)mediaInfo:(NSData *)data
{
    @try{
        id object = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        if ([object isKindOfClass:[self class]]) {
            return object;
        }
        return nil;
    }@catch(NSException *ex){
        return nil;
    }
}

@end
