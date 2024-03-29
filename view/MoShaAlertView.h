//
//  MoShaAlertView.h
//  MoShaAlertView
//
//  Created by Richard on 20/09/2013.
//  Copyright (c) 2013 Wimagguc.
//
//  Lincesed under The MIT License (MIT)
//  http://opensource.org/licenses/MIT
//

#import <UIKit/UIKit.h>

@class MoShaAlertView;
typedef void(^MoShaAlertViewButtonFun)(MoShaAlertView*,int);

@protocol MoShaAlertViewDelegate

- (void)moshadialogButtonTouchUpInside:(MoShaAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;

@end

@interface MoShaAlertView : UIView<MoShaAlertViewDelegate>

@property (nonatomic, retain) UIView *parentView;    // The parent view this 'dialog' is attached to
@property (nonatomic, retain) UIView *dialogView;    // Dialog's container view
@property (nonatomic, retain) UIView *containerView; // Container within the dialog (place your ui elements here)
@property (nonatomic, retain) UIView *buttonView;    // Buttons on the bottom of the dialog

@property (nonatomic, assign) id<MoShaAlertViewDelegate> delegate;
@property (nonatomic, retain) NSArray *buttonTitles;
@property (nonatomic, assign) BOOL useMotionEffects;

@property (copy) MoShaAlertViewButtonFun onButtonTouchUpInside;

- (id)init;

/*!
 DEPRECATED: Use the [MoShaAlertView init] method without passing a parent view.
 */
- (id)initWithParentView: (UIView *)_parentView __attribute__ ((deprecated));

- (void)show;
- (void)close;

- (IBAction)moshadialogButtonTouchUpInside:(id)sender;
- (void)setOnButtonTouchUpInside:(void (^)(MoShaAlertView *alertView, int buttonIndex))onButtonTouchUpInside;

- (void)deviceOrientationDidChange: (NSNotification *)notification;
- (void)dealloc;


/*参数params的定义如下：
 *headText:头（类型为NSString*)
 *bodyText:内容（类型是NSString*)
 *buttonTitles:按钮名字(类型是NSArray*)
 *
 */
+(void)showMoshaAlertViewByDictionary:(NSDictionary*)params withAction:(MoShaAlertViewButtonFun)action;
@end
