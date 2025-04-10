//
//  YLRouter.m
//  MainApp
//
//  Created by 乔春晓 on 2025/4/8.
//

#import "YLRouter.h"

NSErrorDomain const YLRouterErrorDomain = @"YLRouterErrorDomain";

@interface YLRouter()
@property (nonatomic, strong) NSMutableDictionary<NSString *, UIViewController * (^)(NSDictionary *params)> *routeMap;
@end

@implementation YLRouter

+ (instancetype)shared {
    static YLRouter *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[YLRouter alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _routeMap = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark - 注册路由
- (void)registerURLPattern:(NSString *)urlPattern
                 handler:(UIViewController * _Nullable (^)(NSDictionary<NSString *, id> *))handler {
    self.routeMap[urlPattern] = handler;
    NSLog(@"%@",self.routeMap);
}

#pragma mark - 打开 URL
- (BOOL)openURL:(NSString *)url
     fromContext:(UIViewController *)context
           error:(NSError **)error {
    
    // 解析 URL
    NSString *pattern = nil;
    NSDictionary *params = nil;
    if (![self parseURL:url outPattern:&pattern outParams:&params]) {
        if (error) *error = [NSError errorWithDomain:YLRouterErrorDomain
                                                code:YLRouterErrorURLNotRegistered
                                            userInfo:@{NSLocalizedDescriptionKey: @"URL 格式错误"}];
        return NO;
    }
    
    // 查找已注册的 Handler
    UIViewController *(^handler)(NSDictionary *) = self.routeMap[pattern];
    if (!handler) {
        if (error) *error = [NSError errorWithDomain:YLRouterErrorDomain
                                                code:YLRouterErrorURLNotRegistered
                                            userInfo:@{NSLocalizedDescriptionKey: @"URL 未注册"}];
        return NO;
    }
    
    // 创建目标模块
    UIViewController *targetVC = handler(params);
    if (!targetVC || ![targetVC isKindOfClass:[UIViewController class]]) {
        if (error) *error = [NSError errorWithDomain:YLRouterErrorDomain
                                                code:YLRouterErrorModuleCreationFailed
                                            userInfo:@{NSLocalizedDescriptionKey: @"模块创建失败"}];
        return NO;
    }
    
    // 执行跳转
    if ([context isKindOfClass:[UINavigationController class]]) {
        [(UINavigationController *)context pushViewController:targetVC animated:YES];
    } else if (context.navigationController) {
        [context.navigationController pushViewController:targetVC animated:YES];
    } else {
        [context presentViewController:targetVC animated:YES completion:nil];
    }
    
    return YES;
}

#pragma mark - 获取模块实例
- (id)moduleForURL:(NSString *)url
    expectedClass:(Class)expectedClass
           error:(NSError **)error {
    
    NSString *pattern = nil;
    NSDictionary *params = nil;
    if (![self parseURL:url outPattern:&pattern outParams:&params]) {
        if (error) *error = [NSError errorWithDomain:YLRouterErrorDomain
                                                code:YLRouterErrorURLNotRegistered
                                            userInfo:@{NSLocalizedDescriptionKey: @"URL 格式错误"}];
        return nil;
    }
    
    UIViewController *(^handler)(NSDictionary *) = self.routeMap[pattern];
    if (!handler) {
        if (error) *error = [NSError errorWithDomain:YLRouterErrorDomain
                                                code:YLRouterErrorURLNotRegistered
                                            userInfo:@{NSLocalizedDescriptionKey: @"URL 未注册"}];
        return nil;
    }
    
    id instance = handler(params);
    if (![instance isKindOfClass:expectedClass]) {
        if (error) *error = [NSError errorWithDomain:YLRouterErrorDomain
                                                code:YLRouterErrorParameterTypeMismatch
                                            userInfo:@{NSLocalizedDescriptionKey: @"模块类型不匹配"}];
        return nil;
    }
    
    return instance;
}

#pragma mark - URL 解析
- (BOOL)parseURL:(NSString *)url
      outPattern:(NSString **)outPattern
       outParams:(NSDictionary **)outParams {
    
    NSURLComponents *components = [NSURLComponents componentsWithString:url];
    if (!components) return NO;
    
    // 构建 Pattern（scheme + host + path）
    NSString *pattern = [NSString stringWithFormat:@"%@://%@%@",
                         components.scheme ?: @"",
                         components.host ?: @"",
                         components.path ?: @""];
    
    // 解析 Query 参数
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    for (NSURLQueryItem *item in components.queryItems) {
        params[item.name] = item.value;
    }
    
    if (outPattern) *outPattern = pattern;
    if (outParams) *outParams = [params copy];
    
    return YES;
}

@end
