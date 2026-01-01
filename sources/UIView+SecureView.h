#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (SecureView)
- (BOOL)hideViewFromCapture:(BOOL)hide;
- (BOOL)showViewForCapture;
@end

NS_ASSUME_NONNULL_END
