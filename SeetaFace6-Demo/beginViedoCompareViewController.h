//
//  beginViedoCompareViewController.h
//  SeetaFace6-Demo
//
//  Created by 程森然 on 2021/4/23.
//

#import <UIKit/UIKit.h>

typedef void(^returnResult)(BOOL isLive,float result);

NS_ASSUME_NONNULL_BEGIN

@interface beginViedoCompareViewController : UIViewController

@property(copy,nonatomic)returnResult returnResult;

@property(assign,nonatomic)float* feature;

@property(strong,nonatomic)UIImage *compareImage;




@end

NS_ASSUME_NONNULL_END
