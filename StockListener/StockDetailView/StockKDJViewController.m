//
//  StockKDJViewController.m
//  StockListener
//
//  Created by Guozhen Li on 12/22/15.
//  Copyright © 2015 Guangzhen Li. All rights reserved.
//

#import "StockKDJViewController.h"
#import "StockInfo.h"
#import "PNLineChartView.h"
#import "StockRefresher.h"
#import "PNPlot.h"
#import "ADTickerLabel.h"
#import "StockDetailViewController.h"
#import "BuySellChartViewController.h"
#import "ZSYPopoverListView.h"
#import "DatabaseHelper.h"
#import "StockPlayerManager.h"
#import "GetTodayStockValue.h"
#import "KingdaWorker.h"
#import "SyncPoint.h"
#import "GetFiveDayStockValue.h"
#import "CalculateKDJ.h"
#import "KingdaWorker.h"
#import "GetDaysStockValue.h"
#import "VOLChartViewController.h"
#import "AVOLChartViewController.h"
#import "FenshiViewController.h"
#import "KDJViewController.h"
#import "KLineViewController.h"

#define MAX_

@interface StockKDJViewController (){
    BuySellChartViewController* buySellController;
    VOLChartViewController* volController;
    AVOLChartViewController* aVolController;
    ZSYPopoverListView* stockListView;
    NSInteger preSegment;

    FenshiViewController* fenshiViewController;
    KDJViewController* kdjViewController;
    KLineViewController* klineViewController;
}
@property (nonatomic, strong) ADTickerLabel *priceLabel;
@property (weak, nonatomic) IBOutlet UILabel *rateLabel;
@property (weak, nonatomic) IBOutlet UIButton *stockNameButton;
@property (weak, nonatomic) IBOutlet UILabel *shValue;
@property (weak, nonatomic) IBOutlet UILabel *szValue;
@property (weak, nonatomic) IBOutlet UILabel *chuangValue;
@property (weak, nonatomic) IBOutlet UISegmentedControl *kdjTypeSegment;
@property (weak, nonatomic) IBOutlet UIView *averagePriceView;
@property (weak, nonatomic) IBOutlet UILabel *fiveAPrice;
@property (weak, nonatomic) IBOutlet UILabel *tenAPrice;
@property (weak, nonatomic) IBOutlet UILabel *twentyAPrice;
@end

@implementation StockKDJViewController
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

-(void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:STOCK_VALUE_REFRESHED_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:STOCK_PLAYER_STETE_NOTIFICATION object:nil];
}

- (void) viewDidLoad {
    [super viewDidLoad];
    fenshiViewController = [[FenshiViewController alloc] initWithParentView:self.view];

    klineViewController = [[KLineViewController alloc] initWithParentView:self.view];
    [klineViewController setFiveAPrice:self.fiveAPrice];
    [klineViewController setTenAPrice:self.tenAPrice];
    [klineViewController setTwentyAPrice:self.twentyAPrice];

    kdjViewController = [[KDJViewController alloc] initWithParentView:self.view];
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onPlayerStatusChanged:)
                                                 name:STOCK_PLAYER_STETE_NOTIFICATION
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onStockValueRefreshed)
                                                 name:STOCK_VALUE_REFRESHED_NOTIFICATION
                                               object:nil];

    if (self.stockInfo == nil) {
        StockInfo* info = [[StockPlayerManager getInstance] getCurrentPlayingInfo];
        if (info == nil) {
            if ([[DatabaseHelper getInstance].stockList count] > 0) {
                info = [[DatabaseHelper getInstance].stockList objectAtIndex:0];
            }
        }
        self.stockInfo = info;
    }
    [self.stockNameButton setTitle:self.stockInfo.name forState:UIControlStateNormal];
    
    [self onStockValueRefreshed];
    
    UIFont *font = [UIFont boldSystemFontOfSize: 20];
    
    if (self.priceLabel == nil) {
        self.priceLabel = [[ADTickerLabel alloc] initWithFrame: CGRectMake(0, 32, 0, font.lineHeight)];
        self.priceLabel.font = font;
        self.priceLabel.characterWidth = 22;
        self.priceLabel.changeTextAnimationDuration = 0.5;
        [self.view addSubview: self.priceLabel];
    }

    if (self.view.frame.size.width > self.view.frame.size.height) {
        return;
    }

    float leftWidth = ((int)(self.view.frame.size.width/7*6)/(MAX_DISPLAY_COUNT-1))*(MAX_DISPLAY_COUNT-1);

    int offsetY = self.rateLabel.frame.size.height + self.rateLabel.frame.origin.y + 20;
    CGRect fenshiRect = CGRectMake(0, offsetY, leftWidth, 150);
    [fenshiViewController setFrame:fenshiRect];

    if (buySellController == nil) {
        buySellController = [[BuySellChartViewController alloc] initWithParentView:self.view];
        CGRect rect = CGRectMake(leftWidth, offsetY, self.view.frame.size.width/7, 150);
        [buySellController loadViewVertical:rect];
    }

    CGRect aRect = self.averagePriceView.frame;

    CGRect rect = self.kdjTypeSegment.frame;
    rect.origin.y = fenshiRect.origin.y + fenshiRect.size.height+1;
    rect.origin.x = 1;
    rect.size.width = self.view.frame.size.width - aRect.size.width;
    [self.kdjTypeSegment setFrame:rect];

    aRect.origin.x = rect.origin.x + rect.size.width;
    aRect.origin.y = fenshiRect.origin.y + fenshiRect.size.height+1;
    [self.averagePriceView setFrame:aRect];

    [klineViewController setFrame:CGRectMake(0, rect.origin.y + rect.size.height+1, leftWidth, 130)];
    if (volController == nil) {
        volController = [[VOLChartViewController alloc] initWithParentView:self.view];
        CGRect rect2 = CGRectMake(LEFT_PADDING, rect.origin.y + rect.size.height+1+130, leftWidth-LEFT_PADDING, 45);
        [volController loadView:rect2];
    }

    [kdjViewController setFrame:CGRectMake(0, rect.origin.y + rect.size.height + 176, leftWidth, 75)];

    offsetY = rect.origin.y + rect.size.height+1;
    if (aVolController == nil) {
        aVolController = [[AVOLChartViewController alloc] initWithParentView:self.view];
        CGRect rect = CGRectMake(leftWidth, offsetY, self.view.frame.size.width/7, 130);
        [aVolController loadViewVertical:rect];
    }
    
    self.averagePriceView.layer.borderWidth = 0.5;
    self.averagePriceView.layer.borderColor = [[UIColor grayColor] CGColor];

    [self refreshData];
}

-(void) refreshData {
    if (self.stockInfo == nil) {
        return;
    }
    BOOL needSync = YES;
    StockInfo* shInfo = [[DatabaseHelper getInstance] getDapanInfoById:SH_STOCK];
    StockInfo* szInfo = [[DatabaseHelper getInstance] getDapanInfoById:SZ_STOCK];
    StockInfo* cyInfo = [[DatabaseHelper getInstance] getDapanInfoById:CY_STOCK];
    if ([shInfo.todayPriceByMinutes count] < 3 || [self.stockInfo.todayPriceByMinutes count] < 3
        || [shInfo.todayPriceByMinutes count] - [self.stockInfo.todayPriceByMinutes count] > 2) {
        GetTodayStockValue* task = [[GetTodayStockValue alloc] initWithStock:self.stockInfo];
        [[KingdaWorker getInstance] queue:task];
        GetTodayStockValue* task2 = [[GetTodayStockValue alloc] initWithStock:shInfo];
        GetTodayStockValue* task3 = [[GetTodayStockValue alloc] initWithStock:szInfo];
        GetTodayStockValue* task4 = [[GetTodayStockValue alloc] initWithStock:cyInfo];
        [[KingdaWorker getInstance] queue:task2];
        [[KingdaWorker getInstance] queue:task3];
        [[KingdaWorker getInstance] queue:task4];
        needSync = YES;
    }
    
//    NSDate* date = [NSDate date];
//    NSDateFormatter  *dateformatter=[[NSDateFormatter alloc] init];
//    [dateformatter setDateFormat:@"YYMMdd"];
//    NSString* dateStr =[dateformatter stringFromDate:date];
//    NSInteger intValue = [dateStr integerValue];
    NSString* str = [self.stockInfo.updateDay stringByReplacingOccurrencesOfString:@"-" withString:@""];
    str = [str substringFromIndex:2];
    NSInteger latest = [str integerValue];
    
    NSInteger historyDateValue = [self.stockInfo.fiveDayLastUpdateDay integerValue];
//    historyDateValue = 0;
    if (historyDateValue == 0 || latest - historyDateValue >= 2) {
        GetFiveDayStockValue* task = [[GetFiveDayStockValue alloc] initWithStock:self.stockInfo];
        [[KingdaWorker getInstance] queue:task];
        needSync = YES;
    } else if (latest-historyDateValue == 1 && [self.stockInfo.fiveDayPriceByMinutes count] < 1200) {
        GetFiveDayStockValue* task = [[GetFiveDayStockValue alloc] initWithStock:self.stockInfo];
        [[KingdaWorker getInstance] queue:task];
        needSync = YES;
    }

    historyDateValue = [self.stockInfo.hundredDayLastUpdateDay integerValue];
//    historyDateValue = 0;
    if (historyDateValue == 0 || latest - historyDateValue >= 2) {
        GetDaysStockValue* task5 = [[GetDaysStockValue alloc] initWithStock:self.stockInfo];
        [[KingdaWorker getInstance] queue:task5];
    } else if (latest-historyDateValue == 1 && [self.stockInfo.hundredDaysPrice count] < 100) {
        GetDaysStockValue* task5 = [[GetDaysStockValue alloc] initWithStock:self.stockInfo];
        [[KingdaWorker getInstance] queue:task5];
    }
    
    if (needSync) {
        SyncPoint* sync = [[SyncPoint alloc] init];
        sync.onCompleteBlock = ^(StockInfo* info) {
            [self onStockValueRefreshed];
            [self onKDJTypeChanged:nil];
        };
        [[KingdaWorker getInstance] queue:sync];
    }
}

-(void)onPlayerStatusChanged:(NSNotification*)notification {
    StockInfo* info = [notification object];
    if (info != nil) {
        self.stockInfo = info;
        [self.stockNameButton setTitle:info.name forState:UIControlStateNormal];
        [self onStockValueRefreshed];
        [self refreshData];
        [self clearCharts];
    }
}

- (IBAction)onStockButtonClicked:(id)sender {
    stockListView = [[ZSYPopoverListView alloc] initWithFrame:CGRectMake(0, 0, 250, 350)];
    stockListView.datasource = self;
    stockListView.titleName.text = @"请选择";
    stockListView.delegate = self;
    [stockListView show];
}

-(void) refreshTopLabels {
    //Da pan
    StockInfo* info = [[DatabaseHelper getInstance] getDapanInfoById:SH_STOCK];
    NSMutableString* str = [[NSMutableString alloc] init];
    [str appendFormat:@"%.2f %.2f%%", info.price, info.changeRate*100];
    [self.shValue setText:str];
    if (info.changeRate < 0) {
        [self.shValue setTextColor:[UIColor colorWithRed:0 green:0.7 blue:0 alpha:1]];
    } else if (info.changeRate > 0) {
        [self.shValue setTextColor:[UIColor redColor]];
    }
    
    info = [[DatabaseHelper getInstance] getDapanInfoById:SZ_STOCK];
    str = [[NSMutableString alloc] init];
    [str appendFormat:@"%.2f %.2f%%", info.price, info.changeRate*100];
    [self.szValue setText:str];
    if (info.changeRate < 0) {
        [self.szValue setTextColor:[UIColor colorWithRed:0 green:0.7 blue:0 alpha:1]];
    } else if (info.changeRate > 0) {
        [self.szValue setTextColor:[UIColor redColor]];
    }
    
    info = [[DatabaseHelper getInstance] getDapanInfoById:CY_STOCK];
    str = [[NSMutableString alloc] init];
    [str appendFormat:@"%.2f %.2f%%", info.price, info.changeRate*100];
    [self.chuangValue setText:str];
    if (info.changeRate < 0) {
        [self.chuangValue setTextColor:[UIColor colorWithRed:0 green:0.7 blue:0 alpha:1]];
    } else if (info.changeRate > 0) {
        [self.chuangValue setTextColor:[UIColor redColor]];
    }

    if (self.stockInfo == nil) {
        return;
    }

    NSString* price = @"";
    if (self.stockInfo.price > 3) {
        price = [NSString stringWithFormat:@"%.2f", self.stockInfo.price];
    } else {
        price = [NSString stringWithFormat:@"%.3f", self.stockInfo.price];
    }
    self.priceLabel.text = price;
    CGRect rect = self.priceLabel.frame;
    rect.origin.x = self.view.frame.size.width/2 - (rect.size.width/2);
    [self.priceLabel setCenter:CGPointMake(self.view.frame.size.width/2, self.stockNameButton.frame.origin.y + self.stockNameButton.frame.size.height/2)];
    
    NSString* rate;
    if (self.stockInfo.changeRate < 0) {
        [self.rateLabel setTextColor:[UIColor colorWithRed:0 green:1 blue:0 alpha:1]];
        [self.priceLabel setTextColor:[UIColor colorWithRed:0 green:1 blue:0 alpha:1]];
        rate = [NSString stringWithFormat:@"%.2f%%", self.stockInfo.changeRate * 100];
    } else {
        [self.rateLabel setTextColor:[UIColor whiteColor]];
        [self.priceLabel setTextColor:[UIColor whiteColor]];
        rate = [NSString stringWithFormat:@"+%.2f%%", self.stockInfo.changeRate * 100];
    }
    self.rateLabel.text = rate;
}

- (void)onStockValueRefreshed {
    [self refreshTopLabels];

    if (self.stockInfo == nil) {
        return;
    }
    
    [buySellController setStockInfo:self.stockInfo];
    [buySellController reload];

    [fenshiViewController refresh:self.stockInfo];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) refreshAVOL:(float)l andHighest:(float)h{
    // Average VOL
    float delta = 0.01;
    if (l < 3) {
        delta = 0.001;
    }
    [aVolController setStockInfo:self.stockInfo];
    int ll = l/delta;
    int hh = h/delta;
    [aVolController setMin:ll];
    [aVolController setMax:hh];
    [aVolController reload];
}

-(void) refreshVOL:(NSInteger) startIndex andVolValues:(NSArray*)volValues {
    //VOL
    startIndex++;
    volController.volValues = [[NSMutableArray alloc] init];
    for (NSInteger i=startIndex; i<[volValues count]; i++) {
        NSNumber* vol = [volValues objectAtIndex:i];
        [volController.volValues addObject:vol];
    }
    // Insert zero for remaining
    for (NSInteger i=0; i<[volController.volValues count] - MAX_DISPLAY_COUNT + 1; i++) {
        [volController.volValues addObject:[NSNumber numberWithInteger:0]];
    }
    [volController reload];
}

- (IBAction)onKDJTypeChanged:(id)sender {
    int delta = 1;
    UISegmentedControl* control = self.kdjTypeSegment;
    switch (control.selectedSegmentIndex) {
        case 0:
            delta = 1;
            break;
        case 1:
            delta = 5;
            break;
        case 2:
            delta = 15;
            break;
        case 3:
            delta = 30;
            break;
        case 4:
            delta = 60;
            break;
        case 5:
            delta = 240;
            break;
        case 6:
            [self moreClicked];
            [control setSelectedSegmentIndex:preSegment];
            return;
        default:
            break;
    }
    preSegment = control.selectedSegmentIndex;
    CalculateKDJ* task = [[CalculateKDJ alloc] initWithStockInfo:self.stockInfo andDelta:delta];
    task.onCompleteBlock = ^(CalculateKDJ* _self) {
        kdjViewController.kdj_d = _self.kdj_d;
        kdjViewController.kdj_j = _self.kdj_j;
        kdjViewController.kdj_k = _self.kdj_k;
        kdjViewController.todayStartIndex = _self.todayStartIndex;

        klineViewController.todayStartIndex = _self.todayStartIndex;
        klineViewController.priceKValues = _self.priceKValues;

        NSInteger startIndex = [_self.priceKValues count] - [_self.kdj_d count];
        if (startIndex < 0) {
            startIndex = 0;
        }
        klineViewController.startIndex = startIndex;
        
        float l = 100000;
        float h = -1;
        for (NSInteger i=startIndex; i<[_self.priceKValues count]; i++) {
            NSArray* array = [_self.priceKValues objectAtIndex:i];
            if ([array count] != 3) {
                continue;
            }
            NSNumber* p = [array objectAtIndex:1];
            if ([p floatValue] > h) {
                h = [p floatValue];
            }
            if ([p floatValue] < l) {
                l = [p floatValue];
            }
        }
        [self refreshAVOL:l andHighest:h];
        [self refreshVOL:startIndex andVolValues:_self.volValues];

        [kdjViewController refresh];
        [klineViewController refresh];
        if (_self.todayStartIndex == 0) {
            NSInteger splitX = [self.stockInfo.todayPriceByMinutes count] - delta * [_self.kdj_d count];
            [fenshiViewController setSplitX:splitX];
        } else {
            [fenshiViewController setSplitX:0];
        }
        [fenshiViewController refresh:self.stockInfo];
    };

    [self clearCharts];

    [[KingdaWorker getInstance] queue:task];
}

-(void) clearCharts {
    [klineViewController clearPlot];
    [kdjViewController clearPlot];
    
    self.fiveAPrice.text = @"-";
    self.tenAPrice.text = @"-";
    self.twentyAPrice.text = @"-";
}

- (IBAction)moreClicked {
    StockDetailViewController* controller = [[StockDetailViewController alloc] init];
    [controller setStockInfo:self.stockInfo];
    [self presentViewController:controller animated:YES completion:nil];
}

#pragma mark -

- (NSInteger)popoverListView:(ZSYPopoverListView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[DatabaseHelper getInstance].stockList count];
}

- (UITableViewCell *)popoverListView:(ZSYPopoverListView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"identifier";
    UITableViewCell *cell = [tableView dequeueReusablePopoverCellWithIdentifier:identifier];
    if (nil == cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    StockInfo* info = [[DatabaseHelper getInstance].stockList objectAtIndex:indexPath.row];
    if ([info.sid isEqualToString:self.stockInfo.sid])
    {
        cell.imageView.image = [UIImage imageNamed:@"selection_selected.png"];
    }
    else
    {
        cell.imageView.image = [UIImage imageNamed:@"selection_normal.png"];
    }
    NSString* rateStr = [NSString stringWithFormat:@"%.2f%%", info.changeRate * 100];
    cell.textLabel.text = [NSString stringWithFormat:@"%@  %@",info.name, rateStr];
    return cell;
}

- (void)popoverListView:(ZSYPopoverListView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
}

- (void)popoverListView:(ZSYPopoverListView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView popoverCellForRowAtIndexPath:indexPath];
    cell.imageView.image = [UIImage imageNamed:@"selection_selected.png"];
    StockInfo* info = [[DatabaseHelper getInstance].stockList objectAtIndex:indexPath.row];
    self.stockInfo = info;
    [self.stockNameButton setTitle:info.name forState:UIControlStateNormal];
    [self onStockValueRefreshed];
    [stockListView dismiss];
    [self refreshData];
    [self clearCharts];
    
    // Player set
    if ([[StockPlayerManager getInstance] isPlaying]) {
        for (int i=0; i<[[DatabaseHelper getInstance].stockList count]; i++) {
            StockInfo* info = [[DatabaseHelper getInstance].stockList objectAtIndex:i];
            if ([info.sid isEqualToString:self.stockInfo.sid]) {
                [[StockPlayerManager getInstance] playByIndex:i];
                break;
            }
        }
    }
}

@end