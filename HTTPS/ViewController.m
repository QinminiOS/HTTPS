//
//  ViewController.m
//  HTTPS
//
//  Created by fanren on 16/6/29.
//  Copyright © 2016年 Qinmin. All rights reserved.
//

#import "ViewController.h"
#import "AFURLSessionManager.h"
#import "AFSecurityPolicy.h"
#import "AFHTTPSessionManager.h"
#import "AFURLResponseSerialization.h"

@interface ViewController ()

@end

@implementation ViewController {
    AFHTTPSessionManager *_manager;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _manager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration ]];
    
    NSString *certFilePath = [[NSBundle mainBundle] pathForResource:@"client" ofType:@"der"];
    NSData *certData = [NSData dataWithContentsOfFile:certFilePath];
    NSSet *certSet = [NSSet setWithObject:certData];
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModePublicKey withPinnedCertificates:certSet];
    securityPolicy.allowInvalidCertificates = YES;
    securityPolicy.validatesDomainName = NO;
    _manager.securityPolicy = securityPolicy;
    
    AFHTTPResponseSerializer *serializer = [[AFHTTPResponseSerializer alloc] init];
    serializer.acceptableContentTypes = [NSSet setWithObjects:@"text/html", nil];
    _manager.responseSerializer = serializer;
    
    [_manager GET:@"https://192.168.47.112/" parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"%@", [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"%@",[error localizedDescription]);
    }];
}


@end
