//
//  UIImage+OpenCV.m
//  seeta-sdk-ios
//
//  Created by 徐芃 on 2018/7/1.
//  Copyright © 2018年 徐芃. All rights reserved.
//

#import "UIImage+OpenCV.h"
#import <AVFoundation/AVFoundation.h>


@implementation UIImage (OpenCV)

-(instancetype)initWithMat:(const cv::Mat &) cvMat {
    cv::Mat local_cvMat = cvMat.clone();
    cv::cvtColor(local_cvMat, local_cvMat, cv::COLOR_BGR2RGB);
    
    NSData *data = [NSData dataWithBytes:local_cvMat.data length:local_cvMat.elemSize() * local_cvMat.total()];
    CGColorSpaceRef colorSpace;
    if (local_cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    CGImageRef imageRef = CGImageCreate(local_cvMat.cols,                            //width
                                        local_cvMat.rows,                            //height
                                        8,                                           //bits per component
                                        8 * local_cvMat.elemSize(),                  //bits per pixel
                                        local_cvMat.step[0],                         //bytesPerRow
                                        colorSpace,                                  //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault, // bitmap info
                                        provider,                                    //CGDataProviderRef
                                        NULL,                                        //decode
                                        false,                                       //should interpolate
                                        kCGRenderingIntentDefault                    //intent
                                        );
    UIImage *finalImage = [UIImage imageWithCGImage: imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

+ (UIImage*)imageFromPixelBuffer:(CMSampleBufferRef)p {
    CVImageBufferRef buffer;
    buffer = CMSampleBufferGetImageBuffer(p);

    CVPixelBufferLockBaseAddress(buffer, 0);
    uint8_t *base;
    size_t width, height, bytesPerRow;
    base = (uint8_t *)CVPixelBufferGetBaseAddress(buffer);
    width = CVPixelBufferGetWidth(buffer);
    height = CVPixelBufferGetHeight(buffer);
    bytesPerRow = CVPixelBufferGetBytesPerRow(buffer);

    CGColorSpaceRef colorSpace;
    CGContextRef cgContext;
    colorSpace = CGColorSpaceCreateDeviceRGB();
    cgContext = CGBitmapContextCreate(base, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(colorSpace);

    CGImageRef cgImage;
    UIImage *image;
    cgImage = CGBitmapContextCreateImage(cgContext);
    image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    CGContextRelease(cgContext);

    CVPixelBufferUnlockBaseAddress(buffer, 0);


    return image;
}

+ (cv::Mat)cvMatFromUIImage:(UIImage *)image {
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;

    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels


    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to backing data
                                                    cols,                      // Width of bitmap
                                                    rows,                     // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    cv::cvtColor(cvMat, cvMat, cv::COLOR_BGR2RGB);

    return cvMat;
}





@end
