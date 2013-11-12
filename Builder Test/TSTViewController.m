//
//  TSTViewController.m
//  Builder Test
//
//  Created by Andrew Carter on 11/6/13.
//  Copyright (c) 2013 Andrew Carter. All rights reserved.
//

#import "TSTViewController.h"

@interface TSTViewController ()

@property (nonatomic, weak) IBOutlet UILabel *label;

@end

@implementation TSTViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSDictionary *colorDictionary = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"color" ofType:@"plist"]];
    NSString *colorString = colorDictionary[@"color"];
    SEL selector = NSSelectorFromString(colorString);
    [[self view] setBackgroundColor:[[UIColor class] performSelector:selector]];
    
    
#ifdef MEGA
    [[self label] setText:@"MEGA RELEASE"];
#else
    [[self label] setText:@"NORMAL RELEASE"];
#endif
}


@end
