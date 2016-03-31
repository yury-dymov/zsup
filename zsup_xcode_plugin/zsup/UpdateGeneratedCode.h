//
//  UpdateGeneratedCode.h
//  zsup
//
//  Created by Dymov, Yuri on 11.05.13.
//  Copyright (c) 2013 Dymov, Yuri. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UpdateGeneratedCode : NSObject {
    NSInteger currentKeyIndex;
    NSArray *keys;
}

@property (nonatomic, retain) NSMutableDictionary *projectDict;
@property (nonatomic, retain) NSString *projectPath;

- (id)initWithProjectDict:(NSMutableDictionary*)aProjectDict andProjectPath:(NSString*)aProjectPath;
- (void)process;

@end
