//
//  BuySellChartViewController.m
//  StockListener
//
//  Created by Guozhen Li on 12/14/15.
//  Copyright © 2015 Guangzhen Li. All rights reserved.
//

#import "VOLChartViewController.h"
#import "stockInfo.h"

// Views
#import "JBBarChartView.h"
#import "JBChartHeaderView.h"
#import "JBBarChartFooterView.h"
#import "JBChartInformationView.h"
#import "JBColorConstants.h"

@interface VOLChartViewController() <JBBarChartViewDelegate, JBBarChartViewDataSource> {
    UIView* view;
}
@property (nonatomic, strong) JBBarChartView *barChartView;

@end

@implementation VOLChartViewController

-(id) initWithParentView:(UIView*)parentView {
    if (self = [super init]) {
        view = parentView;
    }
    return self;
}

- (void)dealloc
{
    _barChartView.delegate = nil;
    _barChartView.dataSource = nil;
}

- (NSString*) valueToStr:(NSString*)str {
    //    NSString* str = [NSString stringWithFormat:@"%.3f", value];
    int index = (int)[str length] - 1;
    for (; index >= 0; index--) {
        char c = [str characterAtIndex:index];
        if (c !='0') {
            break;
        }
    }
    if (index <= 0) {
        return @"0";
    }
    if ([str characterAtIndex:index] == '.') {
        index--;
    }
    if (index <= 0) {
        return @"0";
    }
    str = [str substringToIndex:index+1];
    return str;
}

#define degreeTOradians(x) (M_PI * (x)/180)
- (void)loadView:(CGRect) rect
{
    self.barChartView = [[JBBarChartView alloc] init];
    self.barChartView.frame = rect;
    self.barChartView.delegate = self;
    self.barChartView.dataSource = self;
    self.barChartView.minimumValue = 0.0f;
    self.barChartView.inverted = NO;
    self.barChartView.backgroundColor = kJBColorBarChartBackground;
    
    [view addSubview:self.barChartView];
    
    self.barChartView.layer.borderWidth = 0.5;
    self.barChartView.layer.borderColor = [[UIColor grayColor] CGColor];
}

-(void) removeFromSuperView {
    [self.barChartView removeFromSuperview];
}

- (void) reload {
    [self.barChartView reloadData];
    
    [self.barChartView setState:JBChartViewStateExpanded];
}

#pragma mark - JBChartViewDataSource

- (BOOL)shouldExtendSelectionViewIntoHeaderPaddingForChartView:(JBChartView *)chartView
{
    return NO;
}

- (BOOL)shouldExtendSelectionViewIntoFooterPaddingForChartView:(JBChartView *)chartView
{
    return NO;
}

- (NSUInteger)numberOfBarsInBarChartView:(JBBarChartView *)barChartView
{
    return [self.volValues count];
}

- (void)barChartView:(JBBarChartView *)barChartView didSelectBarAtIndex:(NSUInteger)index touchPoint:(CGPoint)touchPoint
{
}

- (void)didDeselectBarChartView:(JBBarChartView *)barChartView
{
}

#pragma mark - JBBarChartViewDelegate

- (CGFloat)barChartView:(JBBarChartView *)barChartView heightForBarViewAtIndex:(NSUInteger)index
{
    NSInteger vol = [[self.volValues objectAtIndex:index] integerValue];
    if (vol < 0) {
        return -1 * vol;
    } else {
        return vol;
    }
}

- (UIColor *)barChartView:(JBBarChartView *)barChartView colorForBarViewAtIndex:(NSUInteger)index
{
    NSInteger vol = [[self.volValues objectAtIndex:index] integerValue];
    if (vol < 0) {
        return kJBColorBarChartBarGreen;
    } else {
        return kJBColorBarChartBarRed;
    }
}

- (UIColor *)barSelectionColorForBarChartView:(JBBarChartView *)barChartView
{
    return [UIColor whiteColor];
}

- (CGFloat)barPaddingForBarChartView:(JBBarChartView *)barChartView
{
    return 1;
}
@end
