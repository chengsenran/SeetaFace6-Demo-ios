//
//  beginViedoCompareViewController.m
//  SeetaFace6-Demo
//
//  Created by 程森然 on 2021/4/23.
//

#import "beginViedoCompareViewController.h"
#import "FFVideoCapturer.h"
#import "FaceRecognizerManagers.h"
#import <SeetaFaceDetector600/seeta/FaceDetector.h>
#import <SeetaFaceAntiSpoofingX600/seeta/FaceAntiSpoofing.h>
#import <SeetaFaceLandmarker600/seeta/FaceLandmarker.h>
#import <SeetaFaceRecognizer610/seeta/FaceRecognizer.h>
#import "UIImage+OpenCV.h"



@interface beginViedoCompareViewController ()<FFVideoCapturerDelegate,FaceRecognizerManagersDelegate>
{
    FaceRecognizerManagers *faceManager;
    FFVideoCapturer *videoCapturer;
    CGRect myfaceFrame;
    NSString *faceStatus;
    float compareValue;
    BOOL islive;
    
}

@property(weak,nonatomic)UIImageView *imageView;

@end

@implementation beginViedoCompareViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    // Do any additional setup after loading the view.
    FFVideoCapturerParam * videoCapturerParam = [FFVideoCapturerParam alloc];
    videoCapturerParam.devicePosition =AVCaptureDevicePositionFront;
    videoCapturerParam.sessionPreset = AVCaptureSessionPreset1280x720;
    videoCapturerParam.frameRate = 15;
    videoCapturerParam.videoOrientation = AVCaptureVideoOrientationPortrait;
    
    NSError* error = [NSError alloc];
    
    videoCapturer = [FFVideoCapturer shareInstance];
    [videoCapturer initWithCaptureParam:videoCapturerParam error:&error];
    
//    AVCaptureVideoPreviewLayer *previewLayer = videoCapturer.videoPreviewLayer;
//    [previewLayer setFrame:CGRectMake(0, 0,[UIScreen mainScreen].bounds.size.width,[UIScreen mainScreen].bounds.size.height)];
//    [previewLayer setBackgroundColor:CGColorCreateGenericRGB(1.0, 0.0, 0.0, 1.0)];
//    [self.view.layer addSublayer:previewLayer];
    
    videoCapturer.delegate = self;
    faceManager = [FaceRecognizerManagers shareInstance];
    faceManager.feature = _feature;
    [faceManager initFaceRecognizerObject];
    faceManager.delegate = self;
    
    [self performSelector:@selector(opena:) withObject:nil afterDelay:1];
    
    
    UIImageView *imageView = [[UIImageView alloc]init];
    imageView.frame = CGRectMake(0, 0,[UIScreen mainScreen].bounds.size.width,[UIScreen mainScreen].bounds.size.height);
    [self.view addSubview:imageView];
    self.imageView = imageView;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.returnResult(self->islive, self->compareValue);
//        [[FaceRecognizerManagers shareInstance] stopFaceRecognizerManagers];
        [[FFVideoCapturer shareInstance] stopCapture];
        [self dismissViewControllerAnimated:YES completion:nil];
    });
    
}

-(void)opena:(id)sender {
    [videoCapturer startCapture];
}

- (void)videoCaptureOutputDataBGRCallback:(uint8_t *)frame Channels:(int)channels Width:(int)width Height:(int)height{
    myfaceFrame = CGRectZero;
    faceStatus = @"";
    //cv::Rect rect(100, 5, 280, 290);
    //cv::rectangle(frame, rect, Scalar(255, 0, 0),1, LINE_8,0);
    [faceManager faceDetect:frame Channels:channels Width:width Height:height];
}


- (void)videoCaptureOutputDataCallback:(CMSampleBufferRef)sampleBuffer {
    //转换成UIImage
    UIImage *newImage = [UIImage imageFromPixelBuffer:sampleBuffer];
    
    UIFont *font = [UIFont boldSystemFontOfSize:30];

    UIGraphicsBeginImageContext(newImage.size);

    [newImage drawInRect:CGRectMake(0,0,newImage.size.width,newImage.size.height)];

    CGRect rect = CGRectMake(0, 0, newImage.size.width, newImage.size.height);

    [[UIColor whiteColor] set];

    if(myfaceFrame.size.width>0){
        
        NSDictionary* attribute = @{
                    NSForegroundColorAttributeName:[UIColor greenColor],//设置文字颜色
                    NSFontAttributeName:font,//设置文字的字体
//                    NSKernAttributeName:@10,//文字之间的字距
//                    NSParagraphStyleAttributeName:paragraphStyle,//设置文字的样式
                    };
        
        //计算文字的宽度和高度：支持多行显示
        CGSize sizeText = [faceStatus boundingRectWithSize:newImage.size
                                              options:NSStringDrawingUsesLineFragmentOrigin
                                           attributes:attribute
                                              context:nil].size;
        
        [faceStatus drawAtPoint:CGPointMake(myfaceFrame.origin.x+(myfaceFrame.size.width-sizeText.width)/2,myfaceFrame.origin.y-sizeText.height-10) withAttributes:attribute];

    }
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();
    
    cv::Mat mat;
    //转换成cv::Mat
    mat = [UIImage cvMatFromUIImage:image];
//    UIImageToMat(image, mat);
    if(myfaceFrame.size.width>0){
        cv::rectangle(mat, cv::Rect(myfaceFrame.origin.x,myfaceFrame.origin.y,myfaceFrame.size.width,myfaceFrame.size.height), cv::Scalar(255,0,0,1));

//        cv::putText(mat,faceStatus,cv::Point(myfaceFrame.origin.x,myfaceFrame.origin.y),CV_FONT_HERSHEY_SIMPLEX,1,Scalar::all(255));
    }
    

//    for (NSValue *rect in bounds) {
//        CGRect r = [rect CGRectValue];
//        //画框
//        cv::rectangle(mat, cv::Rect(r.origin.x,r.origin.y,r.size.width,r.size.height), cv::Scalar(255,0,0,1));
//
//    }

    //这里不考虑性能 直接怼Image
    dispatch_async(dispatch_get_main_queue(), ^{
        self.imageView.image = [[UIImage alloc]initWithMat:mat];
    });
    
}

- (void)faceDetectSuccessCallback:(CGRect)face_frame Width:(int)width Height:(int)height {
    myfaceFrame = face_frame;
}

-(void)facePredictCallback:(int)status {
    if (status == 0) {
        islive = YES;
    }
    switch (status) {
        case 0:
            faceStatus = @"真实人脸";
            break;
        case 1:
            faceStatus = @"攻击人脸";
            break;
        case 2:
            faceStatus = @"无法判断";
            break;
        case 3:
            faceStatus = @"正在检测";
            break;
    }
    
}

-(void)facefeatureCompareCallback:(float)floatValue {
    compareValue = floatValue;
}









@end
