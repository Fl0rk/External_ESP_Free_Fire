#import "esp.h"

@interface ESP_View ()
@property (nonatomic, strong) NSMutableArray<CALayer *> *layers;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, strong) CADisplayLink *displayLinkDATA;
@property (nonatomic, strong) NSArray<NSValue *> *boxesData;
@end

@implementation ESP_View

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.layers = [NSMutableArray array];
        self.backgroundColor = [UIColor clearColor];

        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateBoxes)];
        [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        
        
        self.displayLinkDATA = [CADisplayLink displayLinkWithTarget:self selector:@selector(update_data)];
        [self.displayLinkDATA addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (self.superview) {
        self.frame = self.superview.bounds;
    }
    [self updateBoxes];
}

- (void)setBoxes:(NSArray<NSValue *> *)boxes
{
    _boxesData = [boxes copy];
    [self updateBoxes];
}

- (void)updateBoxes {
    if (!self.window) return;
    NSUInteger count = self.boxesData.count;
    
    if (count == 0)
    {
        for (CALayer *layer in self.layers)
        {
            [layer removeFromSuperlayer];
        }
        [self.layers removeAllObjects];
        return;
    }
    
    while (self.layers.count < count)
    {
        CALayer *layer = [CALayer layer];
        layer.borderColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:0.8].CGColor;
        layer.borderWidth = 2.0;
        layer.cornerRadius = 3.0;
        [self.layer addSublayer:layer];
        [self.layers addObject:layer];
    }
    

    
    for (NSUInteger i = 0; i < self.layers.count; i++)
    {
        CALayer *layer = self.layers[i];

        if (i < count)
        {
            ESPBox box;
            [self.boxesData[i] getValue:&box];
            layer.hidden = NO;
            
            [CATransaction begin];
            [CATransaction setDisableActions:YES];
            layer.frame = CGRectMake(box.pos.x, box.pos.y, box.width, box.height);
            [CATransaction commit];

        } else {
            layer.hidden = YES;
        }
    }
}



- (void)dealloc {
    [self.displayLink invalidate];
    [self.displayLinkDATA invalidate];
    self.displayLink = nil;
    self.displayLinkDATA = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)update_data
{
    CFTimeInterval t = CACurrentMediaTime();
    CGSize size = self.bounds.size;
    
    const NSInteger boxCount = 10;
    const CGFloat baseWidth = 60.0;
    const CGFloat baseHeight = 120.0;
    
    NSMutableArray<NSValue *> *boxesMutable = [NSMutableArray arrayWithCapacity:boxCount];
    
    for (NSInteger i = 0; i < boxCount; i++)
    {
        double phase = (double)i * 0.7;
        
        double nx = sin(t * 0.6 + phase) * 0.5 + 0.5;
        double ny = cos(t * 0.4 + phase) * 0.5 + 0.5;
        
        CGFloat w = baseWidth * (0.7 + 0.3 * sin(t * 0.9 + phase));
        CGFloat h = baseHeight * (0.7 + 0.3 * cos(t * 0.8 + phase));
        
        CGFloat centerX = (CGFloat)nx * size.width;
        CGFloat centerY = (CGFloat)ny * size.height;
        
        ESPBox box;
        box.pos.x = centerX - w * 0.5;
        box.pos.y = centerY - h * 0.5;
        box.pos.z = 0.0f;
        box.width = w;
        box.height = h;
        
        NSValue *val = [NSValue valueWithBytes:&box objCType:@encode(ESPBox)];
        [boxesMutable addObject:val];
    }
    
    self.boxes = boxesMutable;
    [self setNeedsDisplay];
}


@end
