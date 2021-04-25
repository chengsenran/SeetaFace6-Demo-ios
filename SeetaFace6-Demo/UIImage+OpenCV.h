//
//  UIImage+OpenCV.h
//  seeta-sdk-ios
//
//  Created by 徐芃 on 2018/7/1.
//  Copyright © 2018年 徐芃. All rights reserved.
//

#import <UIKit/UIKit.h>
#include <opencv2/core/core.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#include <opencv2/highgui/highgui.hpp>
#import <AVFoundation/AVFoundation.h>

@interface UIImage (OpenCV)

-(instancetype)initWithMat:(const cv::Mat &)cvMat;
+ (UIImage*)imageFromPixelBuffer:(CMSampleBufferRef)p;

+ (cv::Mat)cvMatFromUIImage:(UIImage *)image;
@end
