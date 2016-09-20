//
//  ZJSpeedTest.h
//  ZJSpeedTest
//
//  Created by yuzhijie on 16/9/19.
//  Copyright © 2016年 yuzhijie. All rights reserved.
//
//  
#import <Foundation/Foundation.h>

typedef float ZJSpeedTestKb;
typedef NSArray<NSURL *>* ZJSpeedTestSourceUrls;
typedef void(^ZJSpeedTestBlock)(ZJSpeedTestKb currentSpeed,BOOL isFinish);

@interface ZJSpeedTest : NSObject

//是否可以在蜂窝网络下测速....默认No
@property (nonatomic, assign) BOOL allowsTestInCellular;

- (BOOL)isTesting;
- (void)startWithSourceUrls:(ZJSpeedTestSourceUrls)urls process:(ZJSpeedTestBlock)process;
- (void)startWithSourceUrls:(ZJSpeedTestSourceUrls)urls process:(ZJSpeedTestBlock)process inTime:(NSTimeInterval)inTime;
- (void)stop;

@end
