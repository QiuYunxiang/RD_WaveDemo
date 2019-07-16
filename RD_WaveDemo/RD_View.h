//
//  RD_View.h
//  RD_WaveDemo
//
//  Created by 邱云翔 on 2019/7/13.
//  Copyright © 2019 邱云翔. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface RD_View : UIView

/**
 指定初始化方法

 @param frame 大小
 @param str 文本
 @return self
 */
- (instancetype)initWithFrame:(CGRect)frame String:(NSString *)str;

@end

NS_ASSUME_NONNULL_END
