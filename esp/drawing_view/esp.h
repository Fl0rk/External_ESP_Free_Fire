#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "../helpers/Vector3.h"
#import "../helpers/pid.h"
#import "../unity_api/unity.h"

struct ESPBox {
    Vector3 pos;
    CGFloat width;
    CGFloat height;
};

@interface ESP_View : UIView

- (instancetype)initWithFrame:(CGRect)frame;
- (void)setBoxes:(NSArray<NSValue *> *)boxes;
- (void)updateBoxes;
- (void)update_data;
@end
