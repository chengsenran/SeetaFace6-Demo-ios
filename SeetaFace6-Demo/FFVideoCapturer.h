//
//  FFVideoCapturer.h
//  SeetaFace6-Demo
//
//  Created by 程森然 on 2021/4/23.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

@protocol FFVideoCapturerDelegate <NSObject>

/**
 摄像头采集数据输出
@param sampleBuffer 采集到的数据
*/
- (void)videoCaptureOutputDataCallback:(CMSampleBufferRef)sampleBuffer;
/**
摄像头采集数据输出

@param frame 采集到的数据
@param channels 通道
@param width 宽
 @param height 高
*/
- (void)videoCaptureOutputDataBGRCallback:(uint8_t *)frame Channels:(int)channels Width:(int)width Height:(int)height;
@end


@interface FFVideoCapturerParam : NSObject/*设置视频相关参数对象*/

/**摄像头位置，默认为前置摄像头AVCaptureDevicePositionFront*/
@property (nonatomic,assign) AVCaptureDevicePosition devicePosition;
/**视频分辨率 默认AVCaptureSessionPreset1280x720*/
@property (nonatomic,assign) AVCaptureSessionPreset sessionPreset;
/**帧率 单位为 帧/秒, 默认为15帧/秒*/
@property (nonatomic,assign) NSInteger frameRate;
/**摄像头方向 默认为当前手机屏幕方向*/
@property (nonatomic,assign) AVCaptureVideoOrientation videoOrientation;

@end

@interface FFVideoCapturer : NSObject

/**代理*/
@property (nonatomic,weak) id <FFVideoCapturerDelegate> delegate;
/** 预览图层，把这个图层加在View上并且为这个图层设置frame就能播放  */
@property (nonatomic,strong,readonly)AVCaptureVideoPreviewLayer *videoPreviewLayer;
/**视频采集参数对象*/
@property (nonatomic,strong) FFVideoCapturerParam *capturerParam;


/**单例*/
+(instancetype) shareInstance;

/**
 初始化方法
 
 @param param 参数
 @return 实例
 */
- (int)initWithCaptureParam:(FFVideoCapturerParam *)param error:(NSError **)error;

/**开始采集*/
- (NSError *)startCapture;

/**停止采集*/
- (NSError *)stopCapture;


/**抓图 block返回UIImage*/
- (void)imageCapture:(void(^)(UIImage *image))completion;

/**动态调整帧率*/
- (NSError *)adjustFrameRate:(NSInteger)frameRate;

/** 翻转摄像头 */
- (NSError *)reverseCamera;

/** 采集过程中动态修改视频分辨率 */
- (void)changeSessionPreset:(AVCaptureSessionPreset)sessionPreset;

@end

