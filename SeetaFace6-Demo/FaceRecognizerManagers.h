//
//  FaceRecognizerManagers.h
//  TestOpenCV
//
//  Created by chengsenran on 2021/4/23.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
NS_ASSUME_NONNULL_BEGIN

@protocol FaceRecognizerManagersDelegate <NSObject>

/**
 检测到人脸
 
 @param face_frame 检测到的人脸坐标
 @param width 宽
 @param height 高
 */
- (void)faceDetectSuccessCallback:(CGRect)face_frame Width:(int)width Height:(int)height;

- (void)facePredictCallback:(int)status;

- (void)facefeatureCompareCallback:(float)floatValue;
@end

@interface FaceRecognizerManagers : NSObject

/**代理*/
@property (nonatomic,weak) id <FaceRecognizerManagersDelegate> delegate;

@property(assign,nonatomic)float* feature;


/**单例*/
+(instancetype) shareInstance;
/**初始化人脸识别相关类*/
- (void) initFaceRecognizerObject;



/**
人脸检测

 @param frame 转换完成的BGR数据
 @param channels 通道号，默认为3
 @param width 宽
 @param height 高
*/
- (void) faceDetect:(uint8_t *)frame Channels:(int)channels Width:(int)width Height:(int)height;
- (void)releaseAll;
@end

NS_ASSUME_NONNULL_END

