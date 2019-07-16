//
//  ViewController.m
//  RD_WaveDemo
//
//  Created by 邱云翔 on 2019/7/13.
//  Copyright © 2019 邱云翔. All rights reserved.
//

/*
    1、静态视图部分：文字和背景的颜色。使用两套CATextLayer+CAShapeLayer构建文字层和背景层，一套为白底（已经有默认是主layer）蓝字，一套为蓝底白字。考虑到需要遮挡一半视图并产生了透视效果，Mask遮罩效果是比较好的选择，所以还需要一个CAShapeLayer做遮罩效果；整体的圆同样以遮罩效果呈现，加以一个boder边框Layer
 
        视图部分清单为：蓝字Layer、蓝底Layer、蓝底Layer、主Layer遮罩Layer、蓝底Layer遮罩Layer、LayerBorderLayer
 
        视图层级为：主Layer ->(mask)主Layer遮罩Layer
                 主Layer -> 蓝字Layer
                 主Layer -> 蓝底Layer -> 白字Layer
                 蓝底Layer ->(mask)蓝底Layer遮罩Layer
                 主Layer -> 主LayerBorderLayer
    2、动画部分：规则的正弦曲线，使用贝塞尔给与正弦曲线轨迹，将此轨迹给予遮罩Layer身上，使用CADisplayLink不停改变ω和ψ，使其产生动画效果。
 
 */

#import "ViewController.h"
#import "RD_View.h"

@interface ViewController ()

/**
 RDview
 */
@property (nonatomic,strong) RD_View *rd_view;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //视图
    self.rd_view = [[RD_View alloc] initWithFrame:CGRectMake(100, 100, 100, 100) String:@"RD"];
    [self.view addSubview:self.rd_view];
    
    
    //此处验证有无被释放
    [self performSelector:@selector(removeRD_View) withObject:nil afterDelay:10.0f];
    
    // Do any additional setup after loading the view.
}

#pragma mark 移除视图，测试有无释放
- (void)removeRD_View {
    [self.rd_view removeFromSuperview];
    self.rd_view = nil;
}


@end
