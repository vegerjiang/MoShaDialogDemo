//
//  MoShaAlertView.m
//  MoShaAlertView
//
//  Created by Richard on 20/09/2013.
//  Copyright (c) 2013 Wimagguc.
//
//  Lincesed under The MIT License (MIT)
//  http://opensource.org/licenses/MIT
//

#import "MoShaAlertView.h"
#import <QuartzCore/QuartzCore.h>
#import <Accelerate/Accelerate.h>
#import "MyTextView.h"
#define pixIndex(x,y,width) (((x) + (y)*(width))<<2)

const static CGFloat kMoShaAlertViewDefaultButtonHeight       = 35;
const static CGFloat kMoShaAlertViewDefaultButtonSpacerHeight = 0;
const static CGFloat kMoShaAlertViewCornerRadius              = 10;
const static CGFloat kCustomIOS7MotionEffectExtent                 = 10.0;
const static CGFloat kMoShaAlertViewDefaultBottomHeight = 20;

@implementation MoShaAlertView

CGFloat buttonHeight = 0;
CGFloat buttonSpacerHeight = 0;

@synthesize parentView, containerView, dialogView, buttonView, onButtonTouchUpInside;
@synthesize delegate;
@synthesize buttonTitles;
@synthesize useMotionEffects;

- (id)initWithParentView: (UIView *)_parentView
{
    self = [self init];
    if (_parentView) {
        self.frame = _parentView.frame;
        self.parentView = _parentView;
    }
    return self;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
        
        delegate = self;
        useMotionEffects = false;
        buttonTitles = @[@"Close"];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    }
    return self;
}

// Create the dialog view, and animate opening the dialog
- (void)show
{
    dialogView = [self createContainerView];
    
    dialogView.layer.shouldRasterize = YES;
    dialogView.layer.rasterizationScale = [[UIScreen mainScreen] scale];
    
    self.layer.shouldRasterize = YES;
    self.layer.rasterizationScale = [[UIScreen mainScreen] scale];
    
#if (defined(__IPHONE_7_0))
    if (useMotionEffects) {
        [self applyMotionEffects];
    }
#endif
    
    dialogView.layer.opacity = 0.5f;
    dialogView.layer.transform = CATransform3DMakeScale(1.3f, 1.3f, 1.0);
    
    self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
    
    [self addSubview:dialogView];
    
    // Can be attached to a view or to the top most window
    // Attached to a view:
    if (parentView != NULL) {
        [parentView addSubview:self];
        
        // Attached to the top most window (make sure we are using the right orientation):
    } else {
        UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        switch (interfaceOrientation) {
            case UIInterfaceOrientationLandscapeLeft:
                self.transform = CGAffineTransformMakeRotation(M_PI * 270.0 / 180.0);
                break;
                
            case UIInterfaceOrientationLandscapeRight:
                self.transform = CGAffineTransformMakeRotation(M_PI * 90.0 / 180.0);
                break;
                
            case UIInterfaceOrientationPortraitUpsideDown:
                self.transform = CGAffineTransformMakeRotation(M_PI * 180.0 / 180.0);
                break;
                
            default:
                break;
        }
        
        [self setFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
        [[[[UIApplication sharedApplication] windows] firstObject] addSubview:self];
    }
    
    [UIView animateWithDuration:0.2f delay:0.0 options:UIViewAnimationOptionCurveEaseInOut
					 animations:^{
						 self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.4f];
                         dialogView.layer.opacity = 1.0f;
                         dialogView.layer.transform = CATransform3DMakeScale(1, 1, 1);
					 }
					 completion:NULL
     ];
}

// Button has been touched
- (IBAction)moshadialogButtonTouchUpInside:(id)sender
{
    if (delegate != NULL) {
        [delegate moshadialogButtonTouchUpInside:self clickedButtonAtIndex:[sender tag]];
    }
    
    if (onButtonTouchUpInside != NULL) {
        onButtonTouchUpInside(self, [sender tag]);
    }
}

// Default button behaviour
- (void)moshadialogButtonTouchUpInside: (MoShaAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSLog(@"Button Clicked! %d, %d", buttonIndex, [alertView tag]);
    [self close];
}

// Dialog close animation then cleaning and removing the view from the parent
- (void)close
{
    CATransform3D currentTransform = dialogView.layer.transform;
    
    CGFloat startRotation = [[dialogView valueForKeyPath:@"layer.transform.rotation.z"] floatValue];
    CATransform3D rotation = CATransform3DMakeRotation(-startRotation + M_PI * 270.0 / 180.0, 0.0f, 0.0f, 0.0f);
    
    dialogView.layer.transform = CATransform3DConcat(rotation, CATransform3DMakeScale(1, 1, 1));
    dialogView.layer.opacity = 1.0f;
    
    [UIView animateWithDuration:0.2f delay:0.0 options:UIViewAnimationOptionTransitionNone
					 animations:^{
						 self.backgroundColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.0f];
                         dialogView.layer.transform = CATransform3DConcat(currentTransform, CATransform3DMakeScale(0.6f, 0.6f, 1.0));
                         dialogView.layer.opacity = 0.0f;
					 }
					 completion:^(BOOL finished) {
                         for (UIView *v in [self subviews]) {
                             [v removeFromSuperview];
                         }
                         [self removeFromSuperview];
					 }
	 ];
}

- (void)setSubView: (UIView *)subView
{
    containerView = subView;
}
- (UIImage *)blurryImage:(UIImage *)image withBlurLevel:(CGFloat)blur {
    if ((blur < 0.0f) || (blur > 1.0f)) {
        blur = 0.5f;
    }
    
    int boxSize = (int)(blur * 100);
    boxSize -= (boxSize % 2) + 1;
    
    CGImageRef img = image.CGImage;
    
    vImage_Buffer inBuffer, outBuffer;
    vImage_Error error;
    void *pixelBuffer;
    
    CGDataProviderRef inProvider = CGImageGetDataProvider(img);
    CFDataRef inBitmapData = CGDataProviderCopyData(inProvider);
    
    inBuffer.width = CGImageGetWidth(img);
    inBuffer.height = CGImageGetHeight(img);
    inBuffer.rowBytes = CGImageGetBytesPerRow(img);
    
    inBuffer.data = (void*)CFDataGetBytePtr(inBitmapData);
    
    pixelBuffer = malloc(CGImageGetBytesPerRow(img) * CGImageGetHeight(img));
    
    outBuffer.data = pixelBuffer;
    outBuffer.width = CGImageGetWidth(img);
    outBuffer.height = CGImageGetHeight(img);
    outBuffer.rowBytes = CGImageGetBytesPerRow(img);
    
    error = vImageBoxConvolve_ARGB8888(&inBuffer, &outBuffer, NULL,
                                       0, 0, boxSize, boxSize, NULL,
                                       kvImageEdgeExtend);
    
    
    if (error) {
        NSLog(@"error from convolution %ld", error);
    }
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(
                                             outBuffer.data,
                                             outBuffer.width,
                                             outBuffer.height,
                                             8,
                                             outBuffer.rowBytes,
                                             colorSpace,
                                             CGImageGetBitmapInfo(image.CGImage));
    
    CGImageRef imageRef = CGBitmapContextCreateImage (ctx);
    UIImage *returnImage = [UIImage imageWithCGImage:imageRef];
    
    //clean up
    CGContextRelease(ctx);
    CGColorSpaceRelease(colorSpace);
    
    free(pixelBuffer);
    CFRelease(inBitmapData);
    
    CGImageRelease(imageRef);
    
    return returnImage;
}
-(UIImage*)getCurrentCut:(CGRect)cutRect{
    UIImage* cutImage = nil;
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    UIView *topView = [[window subviews] objectAtIndex:0];
    @autoreleasepool {
        NSUInteger byteSize = sizeof(Byte);
        NSUInteger cutX = lroundf(cutRect.origin.x);
        NSUInteger cutY = lroundf(cutRect.origin.y);
        NSUInteger cutWidth = lroundf(cutRect.size.width);
        NSUInteger cutHeight = lroundf(cutRect.size.height);
        Byte* cutImageData = (Byte*)malloc(byteSize*(4*(cutWidth-1)+4*(cutHeight-1)*cutWidth+3));
        
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        
        NSUInteger width = lround(topView.frame.size.width);
        NSUInteger height = lround(topView.frame.size.height);
        NSUInteger bytesPerPixel = 4;
        int bitsPerComponent = 8;
        
        CGContextRef cgContexRef = CGBitmapContextCreate(NULL,
                                                         width,
                                                         height,
                                                         bitsPerComponent,
                                                         bytesPerPixel*width,
                                                         colorSpace,
                                                         kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Big);
        [topView.layer renderInContext:cgContexRef];
        
        Byte* imageData = (Byte*)CGBitmapContextGetData(cgContexRef);// 4*(width-1)+4*(height-1)*width+3)
        for (NSUInteger x = 0; x<cutWidth; ++x) {
            for (NSUInteger y = 0; y<cutHeight; ++y) {
                NSUInteger fromX = x+cutX;
                NSUInteger fromY = cutHeight - y + cutY;
                Byte* t = cutImageData + pixIndex(x, y, cutWidth);
                Byte* s = imageData + pixIndex(fromX, fromY, width);
                memcpy(t, s, byteSize<<2);
            }
        }
        CGContextRelease(cgContexRef);
        
        
        
        cgContexRef = CGBitmapContextCreate(cutImageData,
                                                         cutWidth,
                                                         cutHeight,
                                                         bitsPerComponent,
                                                         bytesPerPixel*cutWidth,
                                                         colorSpace,
                                                         kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Big);
        CGImageRef quartzImage = CGBitmapContextCreateImage(cgContexRef);
        cutImage = [UIImage imageWithCGImage:quartzImage];
        
        CGImageRelease(quartzImage);
        CGContextRelease(cgContexRef);
        
        
        
        CGColorSpaceRelease(colorSpace);
        free(cutImageData);
    }
    return [self blurryImage:cutImage withBlurLevel:0.4];
}
// Creates the container view here: create the dialog, then add the custom content and buttons
- (UIView *)createContainerView
{
    if (containerView == NULL) {
        containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 150)];
    }
    
    CGSize screenSize = [self countScreenSize];
    CGSize dialogSize = [self countDialogSize];
    
    // For the black background
    [self setFrame:CGRectMake(0, 0, screenSize.width, screenSize.height)];
    
    // This is the dialog's container; we attach the custom content and the buttons to this one
    UIView *dialogContainer = [[UIImageView alloc] initWithFrame:CGRectMake((screenSize.width - dialogSize.width) / 2, (screenSize.height - dialogSize.height) / 2, dialogSize.width, dialogSize.height)];
    
    // First, we style the dialog to match the iOS7 UIAlertView >>>
    UIView* topWhiteView = [[UIView alloc] initWithFrame:dialogContainer.bounds];
    topWhiteView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.2];
    [dialogContainer addSubview:topWhiteView];
    
    CGFloat cornerRadius = kMoShaAlertViewCornerRadius;
    [(UIImageView*)dialogContainer setImage:[self getCurrentCut:dialogContainer.frame]];
    dialogContainer.userInteractionEnabled = YES;
    dialogContainer.layer.cornerRadius = cornerRadius;
    dialogContainer.layer.masksToBounds = YES;
    dialogContainer.layer.borderColor = [[UIColor colorWithWhite:1.0 alpha:0.2] CGColor];
    dialogContainer.layer.borderWidth = 1;
    dialogContainer.layer.shadowRadius = cornerRadius + 5;
    dialogContainer.layer.shadowOpacity = 0.1f;
    dialogContainer.layer.shadowOffset = CGSizeMake(0 - (cornerRadius+5)/2, 0 - (cornerRadius+5)/2);
    dialogContainer.layer.shadowColor = [UIColor blackColor].CGColor;
    dialogContainer.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:dialogContainer.bounds cornerRadius:dialogContainer.layer.cornerRadius].CGPath;
    
    // Add the custom container if there is any
    [dialogContainer addSubview:containerView];
    
    // Add the buttons too
    [self addButtonsToView:dialogContainer];
    
    return dialogContainer;
}

// Helper function: add buttons to container
- (void)addButtonsToView: (UIView *)container
{
    if (buttonTitles==NULL) { return; }
    
    CGFloat buttonWidth = 105;// container.bounds.size.width / [buttonTitles count];
    CGFloat buttonSpace = (container.frame.size.width-buttonWidth*buttonTitles.count)/(buttonTitles.count+1);
    for (int i=0; i<[buttonTitles count]; i++) {
        
        UIButton *eachButton = [UIButton buttonWithType:UIButtonTypeCustom];
        
        [eachButton setFrame:CGRectMake(i * (buttonWidth+buttonSpace)+buttonSpace, container.bounds.size.height - buttonHeight - kMoShaAlertViewDefaultBottomHeight, buttonWidth, buttonHeight)];
        
        [eachButton addTarget:self action:@selector(moshadialogButtonTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
        [eachButton setTag:i];
        
        [eachButton setTitle:[buttonTitles objectAtIndex:i] forState:UIControlStateNormal];
        [eachButton setTitleColor:[UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:0.8f] forState:UIControlStateNormal];
        [eachButton setTitleShadowColor:[UIColor colorWithWhite:1.0 alpha:0.4] forState:UIControlStateNormal];
        eachButton.layer.masksToBounds = YES;
        eachButton.layer.cornerRadius = buttonHeight/2.0;
        eachButton.layer.borderColor = [[UIColor colorWithWhite:1.0 alpha:0.8] CGColor];
        eachButton.layer.borderWidth = 1;
        [eachButton.titleLabel setFont:[UIFont boldSystemFontOfSize:14.0f]];
        
        [container addSubview:eachButton];
    }
}

// Helper function: count and return the dialog's size
- (CGSize)countDialogSize
{
    CGFloat dialogWidth = containerView.frame.size.width;
    CGFloat dialogHeight = containerView.frame.size.height + buttonHeight + buttonSpacerHeight + kMoShaAlertViewDefaultBottomHeight;
    
    return CGSizeMake(dialogWidth, dialogHeight);
}

// Helper function: count and return the screen's size
- (CGSize)countScreenSize
{
    if (buttonTitles!=NULL && [buttonTitles count] > 0) {
        buttonHeight       = kMoShaAlertViewDefaultButtonHeight;
        buttonSpacerHeight = kMoShaAlertViewDefaultButtonSpacerHeight;
    } else {
        buttonHeight = 0;
        buttonSpacerHeight = 0;
    }
    
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
        CGFloat tmp = screenWidth;
        screenWidth = screenHeight;
        screenHeight = tmp;
    }
    
    return CGSizeMake(screenWidth, screenHeight);
}

#if (defined(__IPHONE_7_0))
// Add motion effects
- (void)applyMotionEffects {
    
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
        return;
    }
    
    UIInterpolatingMotionEffect *horizontalEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x"
                                                                                                    type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    horizontalEffect.minimumRelativeValue = @(-kCustomIOS7MotionEffectExtent);
    horizontalEffect.maximumRelativeValue = @( kCustomIOS7MotionEffectExtent);
    
    UIInterpolatingMotionEffect *verticalEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y"
                                                                                                  type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
    verticalEffect.minimumRelativeValue = @(-kCustomIOS7MotionEffectExtent);
    verticalEffect.maximumRelativeValue = @( kCustomIOS7MotionEffectExtent);
    
    UIMotionEffectGroup *motionEffectGroup = [[UIMotionEffectGroup alloc] init];
    motionEffectGroup.motionEffects = @[horizontalEffect, verticalEffect];
    
    [dialogView addMotionEffect:motionEffectGroup];
}
#endif

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
}

// Handle device orientation changes
- (void)deviceOrientationDidChange: (NSNotification *)notification
{
    // If dialog is attached to the parent view, it probably wants to handle the orientation change itself
    if (parentView != NULL) {
        return;
    }
    
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    CGFloat startRotation = [[self valueForKeyPath:@"layer.transform.rotation.z"] floatValue];
    CGAffineTransform rotation;
    
    switch (interfaceOrientation) {
        case UIInterfaceOrientationLandscapeLeft:
            rotation = CGAffineTransformMakeRotation(-startRotation + M_PI * 270.0 / 180.0);
            break;
            
        case UIInterfaceOrientationLandscapeRight:
            rotation = CGAffineTransformMakeRotation(-startRotation + M_PI * 90.0 / 180.0);
            break;
            
        case UIInterfaceOrientationPortraitUpsideDown:
            rotation = CGAffineTransformMakeRotation(-startRotation + M_PI * 180.0 / 180.0);
            break;
            
        default:
            rotation = CGAffineTransformMakeRotation(-startRotation + 0.0);
            break;
    }
    
    [UIView animateWithDuration:0.2f delay:0.0 options:UIViewAnimationOptionTransitionNone
					 animations:^{
                         dialogView.transform = rotation;
					 }
					 completion:^(BOOL finished){
                         // fix errors caused by being rotated one too many times
                         dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5f * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                             UIInterfaceOrientation endInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
                             if (interfaceOrientation != endInterfaceOrientation) {
                                 // TODO user moved phone again before than animation ended: rotation animation can introduce errors here
                             }
                         });
                     }
	 ];
    
}

// Handle keyboard show/hide changes
- (void)keyboardWillShow: (NSNotification *)notification
{
    CGSize screenSize = [self countScreenSize];
    CGSize dialogSize = [self countDialogSize];
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
        CGFloat tmp = keyboardSize.height;
        keyboardSize.height = keyboardSize.width;
        keyboardSize.width = tmp;
    }
    
    [UIView animateWithDuration:0.2f delay:0.0 options:UIViewAnimationOptionTransitionNone
					 animations:^{
                         dialogView.frame = CGRectMake((screenSize.width - dialogSize.width) / 2, (screenSize.height - keyboardSize.height - dialogSize.height) / 2, dialogSize.width, dialogSize.height);
					 }
					 completion:nil
	 ];
}

- (void)keyboardWillHide: (NSNotification *)notification
{
    CGSize screenSize = [self countScreenSize];
    CGSize dialogSize = [self countDialogSize];
    
    [UIView animateWithDuration:0.2f delay:0.0 options:UIViewAnimationOptionTransitionNone
					 animations:^{
                         dialogView.frame = CGRectMake((screenSize.width - dialogSize.width) / 2, (screenSize.height - dialogSize.height) / 2, dialogSize.width, dialogSize.height);
					 }
					 completion:nil
	 ];
}
+(UIView*)createDemoViewWithHeadText:(NSString*)headText bodyText:(NSString*)bodyText{
    UIView* containView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 275, 95)];
    containView.backgroundColor = [UIColor clearColor];
    CGFloat y = 0;
    if (headText) {
        UILabel* headLable = [[UILabel alloc] initWithFrame:CGRectMake(0, y, 275, 30)];
        headLable.textAlignment = NSTextAlignmentCenter;
        headLable.text = headText;
        headLable.textColor = [UIColor whiteColor];
        headLable.font = [UIFont systemFontOfSize:16];
        [containView addSubview:headLable];
        UIView* line = [[UIView alloc] initWithFrame:CGRectMake(0, 30, 275, 1)];
        line.backgroundColor = [UIColor grayColor];
        [containView addSubview:line];
        y = 31;
    }
    UIView* bodyView = [[UIView alloc] initWithFrame:CGRectMake(0, y, 275, 95-y)];
    bodyView.backgroundColor = [UIColor clearColor];
    [containView addSubview:bodyView];
    MyTextView* bodyLable = [[MyTextView alloc] initWithFrame:CGRectMake(20, 0, 235, 95-y)];
    [bodyView addSubview:bodyLable];
    bodyLable.textAlignment = NSTextAlignmentCenter;
    bodyLable.text = bodyText;
    bodyLable.textColor = [UIColor colorWithWhite:1.0 alpha:0.8];
    bodyLable.userInteractionEnabled = NO;
    bodyLable.backgroundColor = [UIColor clearColor];
    return containView;
}
+(void)showMoshaAlertViewByDictionary:(NSDictionary *)params withAction:(MoShaAlertViewButtonFun)action{
    NSString* headText = [params objectForKey:@"headText"];
    NSString* bodyText = [params objectForKey:@"bodyText"];
    NSArray* buttonTitles  = [params objectForKey:@"buttonTitles"];
    // Here we need to pass a full frame
    MoShaAlertView *alertView = [[MoShaAlertView alloc] init];
    
    // Add some custom content to the alert view
    [alertView setContainerView:[self createDemoViewWithHeadText:headText bodyText:bodyText]];
    
    // Modify the parameters
    [alertView setButtonTitles:buttonTitles];
    //    [alertView setDelegate:self];
    
    // You may use a Block, rather than a delegate.
    [alertView setOnButtonTouchUpInside:^(MoShaAlertView *alertView, int buttonIndex) {
        action(alertView,buttonIndex);
        [alertView close];
    }];
    
    [alertView setUseMotionEffects:true];
    
    // And launch the dialog
    [alertView show];
}
@end
