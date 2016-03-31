//
//  UpdateElem.h
//  httpstest
//
//  Created by Dymov, Yuri on 10.06.13.
//  Copyright (c) 2013 Dymov, Yuri. All rights reserved.
//

#import <Foundation/Foundation.h>

enum ZSUPUpdateFileType_ {
    ZSUPFILE_Framework = 1,
    ZSUPFILE_Plugin = 2,
    ZSUPFILE_ProjectTemplate = 3,
    ZSUPFILE_FileTemplate = 4
};

typedef enum ZSUPUpdateFileType_ ZSUPUpdateFileType;

@interface UpdateElem : NSObject

@property (nonatomic, retain) NSString *fileName;
@property (nonatomic, retain) NSString *fileSize;
@property (nonatomic, retain) NSString *fileHash;
@property (nonatomic, retain) NSString *desc;
@property (nonatomic, retain) NSString *fileVersion;
@property (nonatomic, assign) ZSUPUpdateFileType type;

+ (id)parseDict:(NSDictionary*)dict;

@end
