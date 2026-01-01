#import "UIView+SecureView.h"

@implementation UIView (SecureView)

- (BOOL)hideViewFromCapture:(BOOL)hide
{
    static dispatch_once_t onceToken;
    static NSString *propertyString;
    
# if 1
    dispatch_once(&onceToken, ^{
        NSString *propertyBase64 = @"ZGlzYWJsZVVwZGF0ZU1hc2s="; /* "disableUpdateMask" encoded in base64 */
        NSData *propertyData = [[NSData alloc] initWithBase64EncodedString:propertyBase64
                                                               options:NSDataBase64DecodingIgnoreUnknownCharacters];
        if (propertyData) {
            propertyString = [[NSString alloc] initWithData:propertyData encoding:NSUTF8StringEncoding];
        }
    });
#endif

    if (!propertyString || ![self.layer respondsToSelector:NSSelectorFromString(propertyString)])
    {
        NSLog(@"Feature unavailable.");
        return NO;
    }
    
    NSInteger mask = hide ? ((1 << 1) | (1 << 4)) : 0;
    [self.layer setValue:@(mask) forKey:propertyString];
    return YES;
}

- (BOOL)showViewForCapture
{
    return [self hideViewFromCapture:NO];
}

@end
