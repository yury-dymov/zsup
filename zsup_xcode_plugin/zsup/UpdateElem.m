//
//  UpdateElem.m
//  httpstest
//
//  Created by Dymov, Yuri on 10.06.13.
//  Copyright (c) 2013 Dymov, Yuri. All rights reserved.
//

#import "UpdateElem.h"

@implementation UpdateElem
@synthesize fileName;
@synthesize fileSize;
@synthesize type;
@synthesize fileHash;
@synthesize desc;
@synthesize fileVersion;

+ (id)parseDict:(NSDictionary *)dict {
    UpdateElem *elem = [UpdateElem new];
    elem.fileName = [dict valueForKey:@"file_file_name"];
    elem.fileSize = [dict valueForKey:@"file_file_size"];
    elem.fileHash = [dict valueForKey:@"file_hash"];
    elem.desc = [dict valueForKey:@"description"];
    elem.type = [[dict valueForKey:@"file_type"] intValue];
    elem.fileVersion = [dict valueForKey:@"updated_at"];
    return [elem autorelease];
}

@end
