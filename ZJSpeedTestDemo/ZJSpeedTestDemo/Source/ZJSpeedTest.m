//
//  ZJSpeedTest.m
//  ZJSpeedTest
//
//  Created by yuzhijie on 16/9/19.
//  Copyright © 2016年 yuzhijie. All rights reserved.
//

#import "ZJSpeedTest.h"

@interface ZJSpeedTest ()<NSURLSessionDataDelegate>

@property (nonatomic, assign) BOOL testing;

@property (nonatomic, strong) NSMutableArray *dataTasks;
@property (nonatomic, strong) NSOperationQueue *dataTaskQueue;
@property (nonatomic, strong) NSOperationQueue *speedTestQueue;

@property (nonatomic, strong) NSDate *startDate;
@property (nonatomic, assign) NSUInteger dataLengthDownLoaded;
@property (nonatomic, assign) NSUInteger taskCompleteCount;
@property (nonatomic, assign) NSTimeInterval timeOut;
@property (nonatomic, copy  ) ZJSpeedTestBlock process;

@end

@implementation ZJSpeedTest

- (instancetype)init
{
    if (self = [super init])
    {
        self.timeOut = 3;
        [self speedTestQueue];
    }
    return self;
}

- (void)startWithSourceUrls:(ZJSpeedTestSourceUrls)urls process:(ZJSpeedTestBlock)process
{
    [self startWithSourceUrls:urls process:process inTime:self.timeOut];
}

- (void)startWithSourceUrls:(ZJSpeedTestSourceUrls)urls process:(ZJSpeedTestBlock)process inTime:(NSTimeInterval)inTime
{
    if (process || ![urls isKindOfClass:[NSArray class]] || !urls.count) {
        NSAssert(false, @"无效网速测试设置");
        return;
    }
    
    [self.speedTestQueue addOperationWithBlock:^{
        
        if (self.testing) {
            return;
        }
        
        self.testing  = YES;
        self.process = process;
        self.dataLengthDownLoaded = 0;
        self.taskCompleteCount = 0;
        
        if (inTime > 0) {
            self.timeOut = inTime;
        }
        
        NSURLSessionConfiguration *defaultConfiguration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        defaultConfiguration.allowsCellularAccess = self.allowsTestInCellular;
        
        defaultConfiguration.timeoutIntervalForRequest = inTime;
        NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration: defaultConfiguration delegate:self delegateQueue:self.dataTaskQueue];
        self.startDate = [NSDate date];
        for (NSURL *url in urls)
        {
            NSURL *tempUrl = url;
            if ([url isKindOfClass:[NSString class]]) {
                tempUrl = [NSURL URLWithString:(NSString *)url];
            }
            
            if (![tempUrl isKindOfClass:[NSURL class]]) {
                tempUrl = [NSURL URLWithString:@"about:blank"];
            }
            
            NSURLSessionDataTask *dataTask = [defaultSession dataTaskWithURL: tempUrl];
            [self.dataTasks addObject:dataTask];
            [dataTask resume];
        }
    }];
  }

#pragma mark -
#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    [self.speedTestQueue addOperationWithBlock:^{
        self.dataLengthDownLoaded += data.length;
        [self updateSpeed];
        
        NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:self.startDate];
        if (duration > self.timeOut || duration < 0) {
            [dataTask cancel];
        }
    }];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error
{
    [self.speedTestQueue addOperationWithBlock:^{
        self.taskCompleteCount++;
        [self updateSpeed];
    }];
}

#pragma mark -
#pragma mark - action

- (BOOL)isTesting
{
    return self.testing;
}

- (void)updateSpeed
{
    NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:self.startDate];
    ZJSpeedTestKb speed = self.dataLengthDownLoaded / 1024 / duration;
    BOOL isFinish = NO;
    
    if (self.taskCompleteCount == self.dataTasks.count)
    {
        self.testing = NO;
        isFinish = YES;
        [self.dataTasks removeAllObjects];
    }
    
    
    if (self.process)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.process(speed,isFinish);
        });
    }
}

- (void)stop
{
    [self.speedTestQueue addOperationWithBlock:^{
        for(NSURLSessionDataTask *dataTask in self.dataTasks)
        {
            [dataTask cancel];
        }
    }];
}

#pragma mark -
#pragma mark - lazy

- (NSOperationQueue *)dataTaskQueue
{
    if (_dataTaskQueue == nil) {
        _dataTaskQueue = [[NSOperationQueue alloc] init];
        _dataTaskQueue.maxConcurrentOperationCount = NSProcessInfo.processInfo.processorCount * 2;
    }
    return _dataTaskQueue;
}

- (NSOperationQueue *)speedTestQueue
{
    if (_speedTestQueue == nil) {
        _speedTestQueue = [[NSOperationQueue alloc] init];
        _speedTestQueue.maxConcurrentOperationCount = 1;
    }
    return _speedTestQueue;
}

- (NSMutableArray *)dataTasks
{
    if (_dataTasks == nil) {
        _dataTasks = [NSMutableArray array];
    }
    return _dataTasks;
}

@end
