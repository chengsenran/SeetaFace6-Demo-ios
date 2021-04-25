//
//  FFVideoCapturer.m
//  SeetaFace6-Demo
//
//  Created by 程森然 on 2021/4/23.
//

#import "FFVideoCapturer.h"


@implementation FFVideoCapturerParam

-(instancetype)init
{
    if(self = [super init]){
        /*设置默认参数*/
        _devicePosition = AVCaptureDevicePositionFront;//默认前摄像头
        _sessionPreset = AVCaptureSessionPreset640x480;//默认分辨率
        _frameRate = 25;
        _videoOrientation = AVCaptureVideoOrientationLandscapeRight;//摄像头方向
        
        switch ([UIDevice currentDevice].orientation) {
            case UIDeviceOrientationPortrait:
            case UIDeviceOrientationPortraitUpsideDown:
                _videoOrientation = AVCaptureVideoOrientationPortrait;
                break;
            case UIDeviceOrientationLandscapeRight:
                _videoOrientation = AVCaptureVideoOrientationLandscapeRight;
                break;
            case UIDeviceOrientationLandscapeLeft:
                _videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
                break;
            default:
                break;
        }
    }
    
    return self;
}
@end



@interface FFVideoCapturer()<AVCaptureVideoDataOutputSampleBufferDelegate>

/** 采集会话 */
@property (nonatomic, strong)AVCaptureSession *captureSession;
/**采集输入设备 也就是摄像头*/
@property (nonatomic, strong)AVCaptureDeviceInput *captureDeviceInput;
/**采集视频输出*/
@property (nonatomic, strong) AVCaptureVideoDataOutput *captureVideoDataOutput;
/**采集音频输出*/
@property (nonatomic, strong) AVCaptureAudioDataOutput *captureAudioDataOutput;
/** 抓图输出 */
@property (nonatomic, strong) AVCaptureStillImageOutput *captureStillImageOutput;
/**预览图层，把这个图层加在View上就能播放*/
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;
/**输出连接*/
@property (nonatomic, strong) AVCaptureConnection *captureConnection;
/**是否已经在采集*/
@property (nonatomic,assign) BOOL isCapturing;
/**开始记录毫秒*/
@property (nonatomic,assign) UInt64 startRecordTime;
/**结束记录毫秒*/
@property (nonatomic,assign) UInt64 endRecordTime;
/**存储状态,保存一帧原始数据*/
@property (nonatomic,assign) BOOL storeState;
@end

static FFVideoCapturer* _instance = nil;

@implementation FFVideoCapturer

- (void)dealloc
{
    NSLog(@"%s",__func__);
    
}

/**单例*/
+(instancetype) shareInstance
{
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc]init];
    });
    return _instance;
    
}

- (int)initWithCaptureParam:(FFVideoCapturerParam *)param error:(NSError * _Nullable __autoreleasing *)error
{
    if(param)
    {
        NSError *errorMessage = nil;
        self.storeState = NO;
        self.capturerParam = param;
        
        /****************** 设置输入设备 ************************/
        //获取所有摄像头
        NSArray *cameras = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        //获取当前方向摄像头
        NSArray *captureDeviceArray = [cameras filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"position == %d",_capturerParam.devicePosition]];
        if(captureDeviceArray.count == 0){
            errorMessage = [self p_errorWithDomain:@"MAVideoCapture::Get Camera Faild!"];
            return -1;
        }
        //转化为输入设备
        AVCaptureDevice *camera = captureDeviceArray.firstObject;
        self.captureDeviceInput  = [AVCaptureDeviceInput deviceInputWithDevice:camera error:&errorMessage];
        if(errorMessage){
            errorMessage = [self p_errorWithDomain:@"MAVideoCapture::AVCaptureDeviceInput init error"];
            return -1;
        }
        
        /****************** 设置输出设备 ************************/
        //设置视频输出
        //初始化视频输出对象
        self.captureVideoDataOutput = [[AVCaptureVideoDataOutput alloc]init];
        //kCVPixelFormatType_24BGR
        NSDictionary *videoSetting = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:kCVPixelFormatType_32BGRA],kCVPixelBufferPixelFormatTypeKey, nil];
        [self.captureVideoDataOutput setVideoSettings:videoSetting];
        //设置输出串行队列和数据回调
        dispatch_queue_t outputQueue = dispatch_queue_create("VCVideoCapturerOutputQueue", DISPATCH_QUEUE_SERIAL);
        //设置数据回调代理和串行队列线程
        [self.captureVideoDataOutput setSampleBufferDelegate:self queue:outputQueue];
        
        //丢弃延迟的帧
        self.captureVideoDataOutput.alwaysDiscardsLateVideoFrames = YES;
        
        //设置抓图输出
        self.captureStillImageOutput = [[AVCaptureStillImageOutput alloc]init];
        //        [self.captureStillImageOutput setOutputSettings:@{AVVideoCodecKey:AVVideoCodecJPEG}];
        
        /****************** 初始化会话 ************************/
        self.captureSession = [[AVCaptureSession alloc]init];
        self.captureSession.usesApplicationAudioSession = NO;
        //添加输入设备到会话
        if([self.captureSession canAddInput:self.captureDeviceInput]){
            [self.captureSession addInput:self.captureDeviceInput];
        }else{
            [self p_errorWithDomain:@"MAVideoCapture::Add captureDeviceInput failed!"];
            return -1;
        }
        
        //添加输出设备到会话
        if([self.captureSession canAddOutput:self.captureVideoDataOutput]){
            [self.captureSession addOutput:self.captureVideoDataOutput];
        }else{
            [self p_errorWithDomain:@"MAVideoCapture::Add captureVideoDataOutput Faild!"];
            return -1;
        }
        //添加抓图输出到会话
        if([self.captureSession canAddOutput:self.captureStillImageOutput]){
            [self.captureSession addOutput:self.captureStillImageOutput];
        }else{
            [self p_errorWithDomain:@"MAVideoCapture::Add captureStillImageOutput Faild!"];
            return -1;
        }
        
        //设置分辨率
        if([self.captureSession canSetSessionPreset:self.capturerParam.sessionPreset])
        {
            self.captureSession.sessionPreset = self.capturerParam.sessionPreset;
        }
        
        
        /****************** 初始化连接 ************************/
        self.captureConnection = [self.captureVideoDataOutput connectionWithMediaType:AVMediaTypeVideo];
        
        //设置摄像头镜像，不设置的话前置摄像头采集出来的图像是反转的
        if(self.capturerParam.devicePosition == AVCaptureDevicePositionFront && self.captureConnection.supportsVideoMirroring){
            self.captureConnection.videoMirrored = YES;
        }
        self.captureConnection.videoOrientation = self.capturerParam.videoOrientation;
        
        //AVCaptureVideoPreviewLayer可以用来快速呈现相机(摄像头)所收集到的原始数据。
        self.videoPreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
        self.videoPreviewLayer.connection.videoOrientation = self.capturerParam.videoOrientation;
        self.videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        if(error)
        {
            *error = errorMessage;
        }
        //设置帧率
        [self adjustFrameRate:self.capturerParam.frameRate];
    }
    return 1;
}



-(NSError *)startCapture
{//开始采集
    if (self.isCapturing){
        return [self p_errorWithDomain:@"MAVideoCapture::startCapture failed! is capturing!"];
    }
    // 摄像头权限判断
    AVAuthorizationStatus videoAuthStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if(videoAuthStatus != AVAuthorizationStatusAuthorized){
        [self p_errorWithDomain:@"MAVideoCapture::Camera Authorizate failed!"];
    }
    [self.captureSession startRunning];
    self.isCapturing = YES;
    _startRecordTime = [[NSDate date] timeIntervalSince1970]*1000;//获取开始时间
    return nil;
}

-(NSError *)stopCapture
{//停止采集
    if(!self.isCapturing){
        return [self p_errorWithDomain:@"MAVideoCapture::stopCapture failed! is not capturing!"];
    }
    [self.captureSession stopRunning];
    self.isCapturing = NO;
    return nil;
}

-(NSError *)reverseCamera
{//翻转摄像头
    
    //获取所有摄像头
    NSArray *cameras = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    //获取当前摄像头方向
    AVCaptureDevicePosition currentPosition = self.captureDeviceInput.device.position;
    AVCaptureDevicePosition toPosition = AVCaptureDevicePositionUnspecified;
    //判断当前摄像头是前置摄像头还是后摄像头
    if(currentPosition == AVCaptureDevicePositionBack || currentPosition == AVCaptureDevicePositionUnspecified){
        toPosition = AVCaptureDevicePositionFront;
    }else{
        toPosition = AVCaptureDevicePositionBack;
    }
    NSArray *captureDevviceArray = [cameras filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"position == %d",toPosition]];
    
    if(captureDevviceArray.count == 0){
        return [self p_errorWithDomain:@"MAVideoCapture::reverseCamera failed! get new Camera Faild!"];
    }
    
    NSError *errpr = nil;
    AVCaptureDevice *camera = captureDevviceArray.firstObject;
    AVCaptureDeviceInput *newInput = [AVCaptureDeviceInput deviceInputWithDevice:camera error:&errpr];
    
    //修改输入设备
    [self.captureSession beginConfiguration];
    [self.captureSession removeInput:self.captureDeviceInput];
    if([_captureSession canAddInput:newInput]){
        [_captureSession addInput:newInput];
        self.captureDeviceInput = newInput;
    }
    [self.captureSession commitConfiguration];
    
    //重新获取连接并设置方向
    self.captureConnection = [self.captureVideoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    if(toPosition == AVCaptureDevicePositionFront && self.captureConnection.supportsVideoMirroring){
        self.captureConnection.videoMirrored = YES;
    }
    self.captureConnection.videoOrientation = self.capturerParam.videoOrientation;
    
    
    return nil;
}



- (void)imageCapture:(void (^)(UIImage * _Nonnull))completion
{//抓图 block返回UIImage
    [self.captureStillImageOutput captureStillImageAsynchronouslyFromConnection:self.captureConnection completionHandler:^(CMSampleBufferRef  _Nullable imageDataSampleBuffer, NSError * _Nullable error)
     {
        UIImage *image = [UIImage imageWithData:[AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer]];
        completion(image);
        
    }];
    
}


- (NSError *)adjustFrameRate:(NSInteger)frameRate
{//动态调整帧率
    NSError *error = nil;
    AVFrameRateRange *frameRateRange = [self.captureDeviceInput.device.activeFormat.videoSupportedFrameRateRanges objectAtIndex:0];
    if (frameRate > frameRateRange.maxFrameRate || frameRate < frameRateRange.minFrameRate){
        return [self p_errorWithDomain:@"MAVideoCapture::Set frame rate failed! out of range"];
    }
    
    [self.captureDeviceInput.device lockForConfiguration:&error];
    self.captureDeviceInput.device.activeVideoMinFrameDuration = CMTimeMake(1, (int)self.capturerParam.frameRate);
    self.captureDeviceInput.device.activeVideoMaxFrameDuration = CMTimeMake(1, (int)self.capturerParam.frameRate);
    [self.captureDeviceInput.device unlockForConfiguration];
    return error;
}

- (void)changeSessionPreset:(AVCaptureSessionPreset)sessionPreset
{//采集过程中动态修改视频分辨率
    self.capturerParam.sessionPreset = sessionPreset;
    if([self.captureSession canSetSessionPreset:self.capturerParam.sessionPreset])
    {
        self.captureSession.sessionPreset = self.capturerParam.sessionPreset;
    }
}

- (NSError *)p_errorWithDomain:(NSString *)domain
{
    
    NSLog(@"%@",domain);
    return [NSError errorWithDomain:domain code:1 userInfo:nil];
}


#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate


/**
 摄像头采集的数据回调
 
 @param output 输出设备
 @param sampleBuffer 帧缓存数据，描述当前帧信息
 @param connection 连接
 */
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if([self.delegate respondsToSelector:@selector(videoCaptureOutputDataCallback:)]){
        [self.delegate videoCaptureOutputDataCallback:sampleBuffer];
    }

    if (sampleBuffer) {
        _endRecordTime = [[NSDate date] timeIntervalSince1970]*1000;
        
        if(_endRecordTime-_startRecordTime > 100){//500毫秒转换一次，并送去检测检测。
//            NSLog(@"====>decode start:%llu",_endRecordTime-_startRecordTime);
            [self processVideoSampleBufferToRGB:sampleBuffer];
            _startRecordTime = [[NSDate date] timeIntervalSince1970]*1000;
        }
    }
    
}

/**视频格式为：kCVPixelFormatType_32BGRA 转换成BGR图像格式*/
- (void)processVideoSampleBufferToRGB:(CMSampleBufferRef)sampleBuffer
{
    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    //表示开始操作数据
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
    int pixelWidth = (int) CVPixelBufferGetWidth(pixelBuffer);
    int pixelHeight = (int) CVPixelBufferGetHeight(pixelBuffer);
    
    // BGRA数据
    uint8_t *frame = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    uint8_t *bgr = malloc(pixelHeight * pixelWidth * 3);
    //    uint8_t *rgb = malloc(pixelHeight * pixelWidth * 3);
    int BGRA = 4;
    int BGR  = 3;
    for (int i = 0; i < pixelWidth * pixelHeight; i ++) {//循环踢掉alpha
        
        NSUInteger byteIndex = i * BGRA;
        NSUInteger newByteIndex = i * BGR;
        
        // Get BGR
        CGFloat blue   = frame[byteIndex + 0];
        CGFloat green  = frame[byteIndex + 1];
        CGFloat red    = frame[byteIndex + 2];
        //CGFloat alpha  = rawData[byteIndex + 3];// 这里Alpha值是没有用的
        
        // Set RGB To New RawData
        bgr[newByteIndex + 0] = blue;   // B
        bgr[newByteIndex + 1] = green;  // G
        bgr[newByteIndex + 2] = red;    // R
    }
    // Unlock
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    if(self.storeState){//保存一帧BGR数据
        NSString *dir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        NSString *documentPath = [NSString stringWithFormat:@"%@/11.bgr", dir];
        FILE* fp = fopen(documentPath.UTF8String, "ab+");
        if(fp)
        {
            size_t size = fwrite(bgr, 1, pixelHeight * pixelWidth * 3, fp);
            NSLog(@"handleVideoData---fwrite:%lu", size);
            fclose(fp);
        }
        self.storeState = YES;
    }
    
    //转换完成，数据回调
    if([self.delegate respondsToSelector:@selector(videoCaptureOutputDataBGRCallback:Channels:Width:Height:)]){
        [self.delegate videoCaptureOutputDataBGRCallback:bgr Channels:3 Width:pixelWidth  Height:pixelHeight ];
    }
    if (NULL != bgr)
    {
        free (bgr);
        bgr = NULL;
    }
}







@end
