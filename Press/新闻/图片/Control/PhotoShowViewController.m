//
//  PhotoShowViewController.m
//  新闻
//
//  Created by JDYang on 15/9/30.
//  Copyright © 2015年 apple. All rights reserved.
//

#define SCREEN_WIDTH                    ([UIScreen mainScreen].bounds.size.width)
#define SCREEN_HEIGHT                   ([UIScreen mainScreen].bounds.size.height)

#import "PhotoShowViewController.h"
#import "UIImageView+WebCache.h"
#import "Photo.h"
#import "MBProgressHUD+MJ.h"
#import <ShareSDK/ShareSDK.h>
#import "DataBase.h"
#import "NSDate+JDY.h"


@interface PhotoShowViewController ()<UIScrollViewDelegate>

@property (nonatomic , weak) UIScrollView *scrollview;
@property (nonatomic , weak) UILabel *countlabel;    //数目按钮
@property (nonatomic , weak) UIImageView *imageV;
@property (nonatomic , weak) UIButton *backbtn;      //返回按钮
@property (nonatomic , weak) UIButton *downbtn;      //下载按钮
@property (nonatomic , weak) UIButton *collectbtn;   //收藏按钮
@property (nonatomic , weak) UIButton *sharebtn;     //分享按钮
@property (nonatomic , assign) int index;            //当前滚动的是第几个
@end

@implementation PhotoShowViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blackColor];
    
    [self initUI];
    
    [self setImage];
    
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}

-(void)initUI
{
    self.index = _currentIndex;
    
    UITapGestureRecognizer *singleTapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(singleTap)];
    [self.view addGestureRecognizer:singleTapGestureRecognizer];
    
    UIScrollView *scrollview = [[UIScrollView alloc]initWithFrame:self.view.frame];
    scrollview.delegate = self;
    [self.view addSubview:scrollview];
    self.scrollview = scrollview;
    
    //返回按钮
    UIButton *backbtn = [[UIButton alloc]init];
    backbtn.hidden = NO;
    backbtn.frame = CGRectMake(5, 25, 40, 40);
    [backbtn setBackgroundImage:[UIImage imageNamed:@"weather_back"] forState:UIControlStateNormal];
    [backbtn addTarget:self action:@selector(backClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:backbtn];
    self.backbtn = backbtn;
    
    //数量
    UILabel *countlabel = [[UILabel alloc]init];
    CGFloat countlabelW = 80;
    CGFloat countlabelH = 30;
    CGFloat countlabelX = (SCREEN_WIDTH - countlabelW)/2;
    CGFloat countlabelY = 25;
    countlabel.frame = CGRectMake(countlabelX, countlabelY, countlabelW, countlabelH);
    countlabel.font = [UIFont systemFontOfSize:18];
    countlabel.textColor = [UIColor whiteColor];
    countlabel.textAlignment = NSTextAlignmentCenter;
    countlabel.hidden = NO;
    [self.view addSubview:countlabel];
    self.countlabel = countlabel;
    
    //下载按钮
    UIButton *downbtn = [[UIButton alloc]init];
    downbtn.hidden = NO;
    downbtn.frame = CGRectMake(SCREEN_WIDTH - 5 - 40, backbtn.frame.origin.y, 40, 40);
    [downbtn setBackgroundImage:[UIImage imageNamed:@"arrow237"] forState:UIControlStateNormal];
    [downbtn addTarget:self action:@selector(downClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:downbtn];
    self.downbtn = downbtn;
    
    //分享按钮
    UIButton *sharebtn = [[UIButton alloc]init];
    sharebtn.hidden = NO;
    sharebtn.frame = CGRectMake(SCREEN_WIDTH - 5 - 40, SCREEN_HEIGHT-10-40, 40, 40);
    [sharebtn setTitle:@"分享" forState:UIControlStateNormal];
    sharebtn.titleLabel.font = [UIFont systemFontOfSize:15];
    [sharebtn addTarget:self action:@selector(shareClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:sharebtn];
    self.sharebtn = sharebtn;
    
    //收藏按钮
    UIButton *collectbtn = [[UIButton alloc]init];
    collectbtn.hidden = NO;
    collectbtn.frame = CGRectMake(sharebtn.x-10-70, sharebtn.y, 70, 40);
    [collectbtn setTitle:@"收藏" forState:UIControlStateNormal];
    collectbtn.titleLabel.font = [UIFont systemFontOfSize:15];
    [collectbtn addTarget:self action:@selector(collectClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:collectbtn];
    self.collectbtn = collectbtn;
    
    if ([[DataBase queryWithCollectPhoto:[self.mutaArray[_currentIndex] image_url]] isEqualToString:@"1"]) {
        collectbtn.selected = YES;
        [collectbtn setTitle:@"已收藏" forState:UIControlStateSelected];
        [collectbtn setTitleColor:[UIColor redColor] forState:UIControlStateSelected];
    }else{
        collectbtn.selected = NO;
        [collectbtn setTitle:@"收藏" forState:UIControlStateNormal];
        [collectbtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }
    
}

#pragma mark --添加
-(void)setImage
{
    NSUInteger count = self.mutaArray.count;
    for (int i = 0; i < count; i++) {
        UIImageView *imaV = [[UIImageView alloc]init];
        // 图片的显示格式为合适大小
        imaV.contentMode= UIViewContentModeCenter;
        imaV.contentMode= UIViewContentModeScaleAspectFit;
        [self.scrollview addSubview:imaV];
        self.imageV = imaV;
    }
    
    self.scrollview.contentOffset = CGPointMake(_currentIndex * SCREEN_WIDTH, 0);
    self.scrollview.contentSize = CGSizeMake(SCREEN_WIDTH * count, 0);
    self.scrollview.showsHorizontalScrollIndicator = NO;
    self.scrollview.showsVerticalScrollIndicator = NO;
    self.scrollview.pagingEnabled = YES;
    
    [self setImgWithIndex:_currentIndex];

}

#pragma mark -- 根据i添加图片，设置每个图片的尺寸
- (void)setImgWithIndex:(int)i
{
    //图片
    NSURL *purl = [NSURL URLWithString:[self.mutaArray[i] image_url]];
    CGFloat imageW = SCREEN_WIDTH;
    NSLog(@"%f",[self.mutaArray[i] image_width]);
    CGFloat imageH = [self.mutaArray[i] image_height] /[self.mutaArray[i] image_width] * imageW;
    CGFloat imageY = (SCREEN_HEIGHT-imageH)/2 - 20;
    CGFloat imageX = i * imageW;
    self.imageV.frame = CGRectMake(imageX, imageY, imageW, imageH);
    [self.imageV sd_setImageWithURL:purl placeholderImage:nil];
    // 文字
    self.countlabel.text = [NSString stringWithFormat:@"%d/%d",i + 1,(int)self.mutaArray.count];
    
    if ([[DataBase queryWithCollectPhoto:[self.mutaArray[i] image_url]] isEqualToString:@"1"]) {
        self.collectbtn.selected = YES;
        [self.collectbtn setTitle:@"已收藏" forState:UIControlStateSelected];
        [self.collectbtn setTitleColor:[UIColor redColor] forState:UIControlStateSelected];
    }else{
        self.collectbtn.selected = NO;
        [self.collectbtn setTitle:@"收藏" forState:UIControlStateNormal];
        [self.collectbtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }
}

#pragma mark -- 滚动完毕时调用
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    int index = self.scrollview.contentOffset.x / self.scrollview.frame.size.width;
    self.index = index;
    // 添加图片
    [self setImgWithIndex:index];
}

#pragma mark 保存图片
-(void)downClick
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:@"确定要保存到相册吗？" preferredStyle:UIAlertControllerStyleActionSheet];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        UIImageWriteToSavedPhotosAlbum(self.imageV.image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo{
    
    if (error != NULL){
        [MBProgressHUD showError:@"下载失败"];
    }else{
        [MBProgressHUD showSuccess:@"保存成功"];
    }
}

#pragma mark - 收藏方法
- (void)collectClick:(UIButton *)btn
{
    NSLog(@"%@",[self.mutaArray[self.index] title]);

    NSString *width = [NSString stringWithFormat:@"%f",[self.mutaArray[self.index] image_width]];
    NSString *height = [NSString stringWithFormat:@"%f",[self.mutaArray[self.index] image_height]];
    
    
    btn.selected = !btn.selected;
    if(btn.selected){
        [btn setTitle:@"已收藏" forState:UIControlStateSelected];
        [btn setTitleColor:[UIColor redColor] forState:UIControlStateSelected];
        [DataBase addPhotosWithTitle:[self.mutaArray[self.index] title] image_url:[self.mutaArray[self.index] image_url] image_width:width image_height:height time:[NSDate currentTime]];
    }else{
        [btn setTitle:@"收藏" forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [DataBase deletetableWithPhoto:[self.mutaArray[self.index] image_url]];
    }
}


#pragma mark - 分享方法
- (void)shareClick
{
    //1、创建分享参数
        NSArray* imageArray = @[self.imageV.image];
    //（注意：图片必须要在Xcode左边目录里面，名称必须要传正确，如果要分享网络图片，可以这样传iamge参数 images:@[@"http://mob.com/Assets/images/logo.png?v=20150320"]）
    if (imageArray) {
        
        NSMutableDictionary *shareParams = [NSMutableDictionary dictionary];
        [shareParams SSDKEnableUseClientShare];
        [shareParams SSDKSetupShareParamsByText:[self.mutaArray[_currentIndex] title]
                                         images:imageArray
                                            url:[NSURL URLWithString:@"https://www.github.com/gaoyuhang"]
                                          title:@"Day Day News"
                                           type:SSDKContentTypeAuto];
        
        [ShareSDK share:SSDKPlatformTypeSinaWeibo parameters:shareParams onStateChanged:^(SSDKResponseState state, NSDictionary *userData, SSDKContentEntity *contentEntity, NSError *error) {
            switch (state) {
                case SSDKResponseStateSuccess:
                {
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"分享成功"
                                                                        message:nil
                                                                       delegate:nil
                                                              cancelButtonTitle:@"确定"
                                                              otherButtonTitles:nil];
                    [alertView show];
                }
                    break;
                case SSDKResponseStateFail:
                {
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"分享失败"
                                                                        message:nil
                                                                       delegate:nil
                                                              cancelButtonTitle:@"确定"
                                                              otherButtonTitles:nil];
                    [alertView show];
                }
                    break;
                    
                default:
                    break;
            }
        }];

    }
}


#pragma mark 点击屏幕
-(void)singleTap
{
    if (self.backbtn.hidden) {
        self.backbtn.hidden = NO;
        self.countlabel.hidden = NO;
        self.downbtn.hidden = NO;
        self.sharebtn.hidden = NO;
        self.collectbtn.hidden = NO;
    }else{
        self.backbtn.hidden = YES;
        self.countlabel.hidden = YES;
        self.downbtn.hidden = YES;
        self.sharebtn.hidden = YES;
        self.collectbtn.hidden = YES;
    }
}

#pragma mark 返回按钮
-(void)backClick
{
    [self.navigationController popViewControllerAnimated:YES];
    [self.navigationController setNavigationBarHidden:NO];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
}



@end
