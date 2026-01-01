//
//  RootViewController.mm
//  TrollSpeed
//
//  Created by Lessica on 2024/1/24.
//

#import <notify.h>

#import "HUDHelper.h"
#import "MainApplication.h"
#import "RootViewController.h"
#import "UIApplication+Private.h"

static const CGFloat _gAuthorLabelBottomConstraintConstantCompact = -20.f;
static const CGFloat _gAuthorLabelBottomConstraintConstantRegular = -80.f;

@implementation RootViewController {
    UIButton *mainButton;
    UILabel *authorLabel;
    NSLayoutConstraint *authorLabelBottomConstraint;
    BOOL isRemoteHUDActive;
}

- (BOOL)isHUDEnabled
{
    return IsHUDEnabled();
}

- (void)setHUDEnabled:(BOOL)enabled
{
    SetHUDEnabled(enabled);
}

- (void)loadView {
    CGRect bounds = UIScreen.mainScreen.bounds;

    self.view = [[UIView alloc] initWithFrame:bounds];
    self.view.backgroundColor = [UIColor colorWithRed:0.0f / 255.0f green:0.0f / 255.0f blue:0.0f / 255.0f alpha:.580f / 1.0f];  // rgba(0, 0, 0, 0.580)

    self.backgroundView = [[UIView alloc] initWithFrame:bounds];
    self.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.backgroundView.backgroundColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
        if ([traitCollection userInterfaceStyle] == UIUserInterfaceStyleDark) {
            return [UIColor colorWithRed:28/255.0 green:74/255.0 blue:82/255.0 alpha:1.0];  // rgba(28, 74, 82, 1.0)
        } else {
            return [UIColor colorWithRed:26/255.0 green:188/255.0 blue:156/255.0 alpha:1.0];  // rgba(26, 188, 156, 1.0)
        }
    }];
    [self.view addSubview:self.backgroundView];

    mainButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [mainButton setTintColor:[UIColor whiteColor]];
    [mainButton addTarget:self action:@selector(tapMainButton:) forControlEvents:UIControlEventTouchUpInside];
    if (@available(iOS 15.0, *))
    {
        UIButtonConfiguration *config = [UIButtonConfiguration tintedButtonConfiguration];
        [config setTitleTextAttributesTransformer:^NSDictionary <NSAttributedStringKey, id> * _Nonnull(NSDictionary <NSAttributedStringKey, id> * _Nonnull textAttributes) {
            NSMutableDictionary *newAttributes = [textAttributes mutableCopy];
            [newAttributes setObject:[UIFont boldSystemFontOfSize:32.0] forKey:NSFontAttributeName];
            return newAttributes;
        }];
        [config setCornerStyle:UIButtonConfigurationCornerStyleLarge];
        [mainButton setConfiguration:config];
    }
    else
    {
        [mainButton.titleLabel setFont:[UIFont boldSystemFontOfSize:32.0]];
    }
    [self.backgroundView addSubview:mainButton];

    UILayoutGuide *safeArea = self.backgroundView.safeAreaLayoutGuide;

    [mainButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [NSLayoutConstraint activateConstraints:@[
        [mainButton.centerXAnchor constraintEqualToAnchor:safeArea.centerXAnchor],
        [mainButton.centerYAnchor constraintEqualToAnchor:self.backgroundView.centerYAnchor],
    ]];

    authorLabel = [[UILabel alloc] init];
    [authorLabel setNumberOfLines:0];
    [authorLabel setTextAlignment:NSTextAlignmentCenter];
    [authorLabel setTextColor:[UIColor whiteColor]];
    [authorLabel setFont:[UIFont systemFontOfSize:14.0]];
    [authorLabel sizeToFit];
    [self.backgroundView addSubview:authorLabel];

    authorLabelBottomConstraint = [authorLabel.bottomAnchor constraintEqualToAnchor:safeArea.bottomAnchor constant:_gAuthorLabelBottomConstraintConstantRegular];
    [authorLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [NSLayoutConstraint activateConstraints:@[
        authorLabelBottomConstraint,
        [authorLabel.centerXAnchor constraintEqualToAnchor:safeArea.centerXAnchor],
    ]];

    UITapGestureRecognizer *authorTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAuthorLabel:)];
    [authorLabel setUserInteractionEnabled:YES];
    [authorLabel addGestureRecognizer:authorTapGesture];

    [self verticalSizeClassUpdated];
    [self reloadMainButtonState];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)reloadMainButtonState
{
    isRemoteHUDActive = [self isHUDEnabled];

    static NSAttributedString *hintAttributedString = nil;
    static NSAttributedString *creditsAttributedString = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSDictionary *defaultAttributes = @{
            NSForegroundColorAttributeName: [UIColor whiteColor],
            NSFontAttributeName: [UIFont systemFontOfSize:14],
        };

        NSMutableParagraphStyle *creditsParaStyle = [[NSMutableParagraphStyle alloc] init];
        creditsParaStyle.lineHeightMultiple = 1.2;
        creditsParaStyle.alignment = NSTextAlignmentCenter;

        NSDictionary *creditsAttributes = @{
            NSForegroundColorAttributeName: [UIColor whiteColor],
            NSFontAttributeName: [UIFont systemFontOfSize:14],
            NSParagraphStyleAttributeName: creditsParaStyle,
        };

        NSString *hintText = NSLocalizedString(@"You can quit this app now.\nThe HUD will persist on your screen.", nil);
        hintAttributedString = [[NSAttributedString alloc] initWithString:hintText attributes:defaultAttributes];

        NSString *creditsText = NSLocalizedString(@"Telegram: @Flork0", nil);
        NSMutableAttributedString *creditsAttributedText = [[NSMutableAttributedString alloc] initWithString:creditsText attributes:creditsAttributes];

        creditsAttributedString = creditsAttributedText;
    });

    [mainButton setTitle:(isRemoteHUDActive ? NSLocalizedString(@"Exit HUD", nil) : NSLocalizedString(@"Open HUD", nil)) forState:UIControlStateNormal];
    [authorLabel setAttributedText:(isRemoteHUDActive ? hintAttributedString : creditsAttributedString)];
}

- (void)tapAuthorLabel:(UITapGestureRecognizer *)sender
{
    if (isRemoteHUDActive) {
        return;
    }
    NSString *repoURLString = @"https://t.me/Flork0";
    NSURL *repoURL = [NSURL URLWithString:repoURLString];
    [[UIApplication sharedApplication] openURL:repoURL options:@{} completionHandler:nil];
}

- (void)tapMainButton:(UIButton *)sender
{
    BOOL isNowEnabled = [self isHUDEnabled];
    [self setHUDEnabled:!isNowEnabled];
    isNowEnabled = !isNowEnabled;

    if (isNowEnabled)
    {
        [self.backgroundView setUserInteractionEnabled:NO];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [self reloadMainButtonState];
                [self.backgroundView setUserInteractionEnabled:YES];
            });
        });
    }
    else
    {
        [self.backgroundView setUserInteractionEnabled:NO];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self reloadMainButtonState];
            [self.backgroundView setUserInteractionEnabled:YES];
        });
    }
}

- (void)verticalSizeClassUpdated
{
    UIUserInterfaceSizeClass verticalClass = self.traitCollection.verticalSizeClass;
    if (verticalClass == UIUserInterfaceSizeClassCompact) {
        [authorLabelBottomConstraint setConstant:_gAuthorLabelBottomConstraintConstantCompact];
    } else {
        [authorLabelBottomConstraint setConstant:_gAuthorLabelBottomConstraintConstantRegular];
    }
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [self verticalSizeClassUpdated];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

@end
