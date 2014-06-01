//
//  ViewController.m
//  MoShaDialogDemo
//
//  Created by gracoli on 14-6-1.
//  Copyright (c) 2014年 vegerRequest. All rights reserved.
//

#import "ViewController.h"
#import "MoShaAlertView.h"

@interface ViewController ()
-(IBAction)buttonPressed:(id)sender;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(void)buttonPressed:(id)sender{
    [MoShaAlertView showMoshaAlertViewByDictionary:@{
                                                     @"headText":@"textHead",
                                                     @"bodyText":@"textBodfasdafdsfsdfdsfsdgsadfadsfadsfsadfsadfsdafasdfasdfsadfasdfsdady",
                                                     @"buttonTitles":@[@"OK",@"cancel"]
                                                     }
                                        withAction:^(MoShaAlertView *alertView, int buttonIndex) {
                                            NSLog(@"Block: Button at position %d.", buttonIndex);
                                        }];
}
@end
