//
//  ViewController1.m
//  OriginalNavigationSample
//
//  Created by Daisuke Shiraishi on 2014/02/27.
//  Copyright (c) 2014年 fotome. All rights reserved.
//

#import "ViewController1.h"
#import "FootiNavigationController.h"

@interface ViewController1 ()

@end

@implementation ViewController1

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

- (IBAction)onButtonTapped:(UIButton *)sender {
    UIViewController *vc1 = [self.storyboard instantiateViewControllerWithIdentifier:@"vc1"];
    [self.footiNavigationController pushViewController:vc1];
}

@end
