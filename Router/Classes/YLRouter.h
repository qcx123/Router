//
//  YLRouter.h
//  MainApp
//
//  Created by 乔春晓 on 2025/4/8.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// 错误域定义
extern NSErrorDomain const YLRouterErrorDomain;

// 错误类型枚举
typedef NS_ERROR_ENUM(YLRouterErrorDomain, YLRouterError) {
    YLRouterErrorURLNotRegistered = 1001,
    YLRouterErrorParameterTypeMismatch = 1002,
    YLRouterErrorModuleCreationFailed = 1003
};

@interface YLRouter : NSObject

+ (instancetype)shared;

/**
 注册 URL 模式
 @param urlPattern URL 模式（如 @"ylapp://user/profile"）
 @param handler 创建模块的 Block
 */
- (void)registerURLPattern:(NSString *)urlPattern
               handler:(UIViewController * _Nullable (^)(NSDictionary<NSString *, id> *params))handler;

/**
 打开 URL（自动处理 push/present 逻辑）
 @param url 完整 URL（如 @"ylapp://user/profile?userId=123"）
 @param context 当前视图控制器
 @param error 错误信息指针
 @return 是否成功跳转
 */
- (BOOL)openURL:(NSString *)url
     fromContext:(UIViewController *)context
           error:(NSError **)error;

/**
 获取模块实例（类型安全版本）
 @param url 完整 URL
 @param expectedClass 期望的类类型
 @param error 错误信息指针
 @return 模块实例或 nil
 */
- (id)moduleForURL:(NSString *)url
    expectedClass:(Class)expectedClass
           error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
