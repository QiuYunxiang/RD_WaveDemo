//
//  RD_View.m
//  RD_WaveDemo
//
//  Created by 邱云翔 on 2019/7/13.
//  Copyright © 2019 邱云翔. All rights reserved.
//

#import "RD_View.h"

@interface RD_View ()

{
    //y =Asin（Wx+X）+ C,正弦函数需要的参数
    
    CGFloat sin_A; //正弦函数振幅参数A
    CGFloat sin_W; //正弦函数周期参数W
    CGFloat sin_C; //正弦函数波浪纵向位置C
    CGFloat sin_X; //正弦函数波浪横向偏移X
    CGFloat sin_CumulativeData; //偏移X的累加保留
}

/**
 需要显示的文本，若无则为RD
 */
@property (nonatomic,copy) NSString *text;

/**
 文本大小
 */
@property (nonatomic,strong) UIFont *textFont;

/**
 文本修正后的frame
 */
@property (nonatomic,assign) CGRect textLayerFrame;

/**
 蓝色字体Layer，与主Layer为一组
 */
@property (nonatomic,strong) CATextLayer *textColorLayer;

/**
 蓝色背景Layer,与textClearLayer为一组
 */
@property (nonatomic,strong) CALayer *backColorLayer;

/**
 白色字体Layer，与backColorLayer为一组
 */
@property (nonatomic,strong) CATextLayer *textClearLayer;

/**
 遮罩Layer，backColorLayer的mask
 */
@property (nonatomic,strong) CAShapeLayer *waveLayer;

/**
 遮罩Layer，主Layer的mask
 */
@property (nonatomic,strong) CAShapeLayer *borderMaskLayer;

/**
 主layer的边缘
 */
@property (nonatomic,strong) CAShapeLayer *borderLayer;

/**
 屏幕刷新计时器
 */
@property (nonatomic,strong) CADisplayLink *displayLink;

@end

@implementation RD_View

#pragma mark 指定初始化方法
- (instancetype)initWithFrame:(CGRect)frame String:(NSString *)str {
    self = [super initWithFrame:frame];
    if (self) {
        _text = str ? str : @"RD";
        [self setUpLayers]; //设置子Layer
        [self setUpFuncSetting]; //设置正弦函数相关
    }
    return self;
}

#pragma mark 设置子Layers
- (void)setUpLayers {
    
    //计算下textFont的大小,以较短边为基准，font大小给予最低边的3/5
    CGFloat lengthMore = MAX(self.bounds.size.height, self.bounds.size.width);
    self.textFont = [UIFont boldSystemFontOfSize:lengthMore / 5 * 3];
    
    //由于字体不能Y居中，所以此处需要调整一次Frame，获取到字体的size.height
    CGSize textSize = [self calculationTextSize];
    CGFloat offsetH = self.bounds.size.height - textSize.height;
    if (offsetH > 0) {
        self.textLayerFrame = CGRectMake(0, offsetH / 2, self.bounds.size.width, self.bounds.size.height - offsetH);
    } else {
        self.textLayerFrame = self.bounds;
    }
    
    //主Layer加入遮罩效果
    self.layer.mask = self.borderMaskLayer;
    
    //主Layer先加蓝字Layer
    [self.layer addSublayer:self.textColorLayer];

    //主Layer加上蓝色背景Layer
    [self.layer addSublayer:self.backColorLayer];

    //蓝色背景Layer加上白字Layer
    [self.backColorLayer addSublayer:self.textClearLayer];

    //蓝色背景加入遮罩Layer
    self.backColorLayer.mask = self.waveLayer;
    
    //加入边缘线Layer
    [self.layer addSublayer:self.borderLayer];

    //开启计时器
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

#pragma mark 设置正弦函数相关
- (void)setUpFuncSetting {
    //以下三项是可以确定配置的，动画效果由sin_X的变动产生
    sin_A = 10;
    sin_W = (M_PI * 2) / self.bounds.size.width;
    sin_C = self.bounds.size.height * 0.5;
    sin_CumulativeData = 0;
}

#pragma mark 处理X轴上的偏移累加，只有不断累加重新画Path才有动画效果
- (void)displayOffsetX {
    sin_CumulativeData += sin_W * 0.01 * self.bounds.size.width;
    [self drawPathWithCumulativeData:sin_CumulativeData];
}

#pragma mark 动画效果，绘制路径waveLayer的路径
- (void)drawPathWithCumulativeData:(CGFloat)cumulativeData {
    
    //此处Path分为：左上起点，曲线部分，右下点，左下点，闭合起点
    UIBezierPath *bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint:CGPointMake(0, sin_C)]; //起点
    
    //正弦曲线部分(用float类型使曲线更加细腻)
    for (CGFloat i = 0.0; i < self.bounds.size.width; i++) {
        CGFloat point_Y = sin_A * sin(sin_W * i + cumulativeData) + sin_C;
        [bezierPath addLineToPoint:CGPointMake(i, point_Y)];
    }
    
    //连接右下点和左下点并闭合
    [bezierPath addLineToPoint:CGPointMake(self.bounds.size.width, self.bounds.size.height)];
    [bezierPath addLineToPoint:CGPointMake(0, self.bounds.size.width)];
    [bezierPath closePath];
    
    self.waveLayer.path = bezierPath.CGPath;
}

#pragma mark 计算字符串的大小，给予合适的Font
- (CGSize)calculationTextSize {
    CGSize textSize = [self.text boundingRectWithSize:CGSizeMake(self.bounds.size.width, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin) attributes:@{NSFontAttributeName:self.textFont} context:nil].size;
    return textSize;
}

#pragma mark 产生一个textLayer
- (CATextLayer *)createTextLayer {
    CATextLayer *textLayer = [CATextLayer layer];
    textLayer.frame = self.textLayerFrame;
    textLayer.string = self.text;
    textLayer.contentsScale = [UIScreen mainScreen].scale;
    textLayer.alignmentMode = kCAAlignmentCenter;
    CGFontRef fontFef = CGFontCreateWithFontName((__bridge CFStringRef)self.textFont.fontName);
    textLayer.font = fontFef;
    textLayer.fontSize = self.textFont.pointSize;
    CFRelease(fontFef);
    return textLayer;
}

#pragma mark 父视图状态变化，此处方式内存泄露
- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
    
    //还存在父视图则将计时器放入loop
    if (newSuperview) {
        [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    } else {
        //不存在则移除loop,同时将其置位失效和nil
        [self.displayLink removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
}

#pragma mark SetterAndGetter
//蓝色字体Layer
- (CATextLayer *)textColorLayer {
    if (!_textColorLayer) {
        _textColorLayer = [self createTextLayer];
        _textColorLayer.foregroundColor = [UIColor blueColor].CGColor;
    }
    return _textColorLayer;
}

//白色字体Layer
- (CATextLayer *)textClearLayer {
    if (!_textClearLayer) {
        _textClearLayer = [self createTextLayer];
        _textClearLayer.foregroundColor = [UIColor whiteColor].CGColor;
    }
    return _textClearLayer;
}

//蓝色背景Layer
- (CALayer *)backColorLayer {
    if (!_backColorLayer) {
        _backColorLayer = [CALayer layer];
        _backColorLayer.frame = self.bounds;
        _backColorLayer.backgroundColor = [UIColor blueColor].CGColor;
    }
    return _backColorLayer;
}

//遮罩波浪Layer
- (CAShapeLayer *)waveLayer {
    if (!_waveLayer) {
        _waveLayer = [CAShapeLayer layer];
        UIBezierPath *wavePath = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, 100, 50)];
        _waveLayer.path = wavePath.CGPath;
    }
    return _waveLayer;
}

//主Layer的遮罩Layer，此处默认了是正方形  即 width = height ,最好的方式是做一个外接圆
- (CAShapeLayer *)borderMaskLayer {
    if (!_borderMaskLayer) {
        _borderMaskLayer = [CAShapeLayer layer];
        _borderMaskLayer.path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height) cornerRadius:self.bounds.size.height/2].CGPath;
    }
    return _borderMaskLayer;
}

//主Layer的圆形边缘线
- (CAShapeLayer *)borderLayer {
    if (!_borderLayer) {
        //此处默认了是正方形  即 width = height ,最好的方式是做一个外接圆
        _borderLayer = [CAShapeLayer layer];
        _borderLayer.strokeColor = [UIColor lightGrayColor].CGColor;
        _borderLayer.lineWidth = 0.5;
        _borderLayer.fillColor = [UIColor clearColor].CGColor;
        _borderLayer.path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height) cornerRadius:self.bounds.size.height/2].CGPath;
        
    }
    return _borderLayer;
}

//计时器
- (CADisplayLink *)displayLink {
    if (!_displayLink) {
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayOffsetX)];
        _displayLink.preferredFramesPerSecond = 0;
    }
    return _displayLink;
}

#pragma mark 释放
- (void)dealloc {
    NSLog(@"被释放了");
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
