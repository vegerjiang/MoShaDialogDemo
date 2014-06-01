//
//  MyTextView.m
//  MoShaDialogDemo
//
//  Created by gracoli on 14-6-1.
//  Copyright (c) 2014年 vegerRequest. All rights reserved.
//

#import "MyTextView.h"

@implementation MyTextView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:nil];//
    }
    return self;
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    CGFloat topCorrect = ([self bounds].size.height - self.contentSize.height);
    
    topCorrect = (topCorrect <0.0 ?0.0 : topCorrect);
    
    self.contentOffset = (CGPoint){.x =self.contentOffset.x, .y = -topCorrect/2};
    
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
