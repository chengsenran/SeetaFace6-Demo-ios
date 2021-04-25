//
//  FaceRecognizerManagers.m
//  SeetaFace6-Demo
//
//  Created by 程森然 on 2021/4/23.
//
#import <UIKit/UIKit.h>
#import "FaceRecognizerManagers.h"
#import <SeetaFaceDetector600/seeta/FaceDetector.h>
#import <SeetaFaceAntiSpoofingX600/seeta/FaceAntiSpoofing.h>
#import <SeetaFaceLandmarker600/seeta/FaceLandmarker.h>
#import <SeetaFaceRecognizer610/seeta/FaceRecognizer.h>

static FaceRecognizerManagers* _instance = nil;
const char *SPOOF_STATE_STR[] = { "real face","spoof face","unknown","judging" };

@interface FaceRecognizerManagers(){
    seeta::FaceDetector *facedector;//人脸检测
    seeta::FaceLandmarker *faceLandmarker;//人脸关键点
    seeta::FaceAntiSpoofing *faceantspoofing;//活体检测
    seeta::FaceRecognizer *faceRecognizer;//人脸识别
}


@end

@implementation FaceRecognizerManagers

/**单例*/
+(instancetype) shareInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc]init];
    });
    return _instance;
}

-(void) initParam
{
    std::string buddle = [[[NSBundle mainBundle] resourcePath] UTF8String];
}

- (void)facedector_init
{
    std::string buddle = [[[NSBundle mainBundle] resourcePath] UTF8String];
    seeta::ModelSetting setting;
    setting.append(buddle + "/assert/model/face_detector.csta");
    setting.set_device( seeta::ModelSetting::AUTO );
    setting.set_id(0);
    facedector = new seeta::FaceDetector(setting);
    
    facedector->set(seeta::FaceDetector::PROPERTY_MAX_IMAGE_WIDTH, 500);
    facedector->set(seeta::FaceDetector::PROPERTY_MAX_IMAGE_HEIGHT, 500);
}

- (void)facelandmarker_init
{
    std::string buddle = [[[NSBundle mainBundle] resourcePath] UTF8String];
    seeta::ModelSetting setting;
    setting.append(buddle + "/assert/model/face_landmarker_pts5.csta");
    faceLandmarker = new seeta::FaceLandmarker(setting);
}

- (void)faceantspoofing_init:(int)version
{
    std::string buddle = [[[NSBundle mainBundle] resourcePath] UTF8String];

    seeta::ModelSetting setting;
    switch (version)
    {
        case 0:
            setting.append(buddle + "/assert/model/fas_first.csta");
            break;
        case 1:
            setting.append(buddle + "/assert/model/fas_second.csta");
            break;
        case 2:
            setting.append(buddle + "/assert/model/fas_first.csta");
            setting.append(buddle + "/assert/model/fas_second.csta");
            break;
        default:
            NSLog(@"version input error");
            throw 2;
    }
    
    faceantspoofing = new seeta::FaceAntiSpoofing(setting);
}

- (void)facerecognizer_init
{
    std::string buddle = [[[NSBundle mainBundle] resourcePath] UTF8String];

    seeta::ModelSetting setting;
    setting.append(buddle + "/assert/model/face_recognizer_light.csta");
    faceRecognizer = new seeta::FaceRecognizer(setting);
}

- (void)initFaceRecognizerObject
{
    
    //初始化默认参数
//    [self initParam];
    
    //初始化人脸检测
    [self facedector_init];
    
    //初始化人脸关键点
    [self facelandmarker_init];
    
    //初始化活体检测 0局部 1全局 2局部+全局
    [self faceantspoofing_init:0];
    
    //初始化人脸识别
    [self facerecognizer_init];
    
}

//在视频识别模式中，如果该识别结果已经完成，需要开始新的视频的话，需要调用ResetVideo重置识别状态，然后重新输入视频
- (void) reset_video {
    faceantspoofing->ResetVideo();
}

//设置活体检测的视频帧数
- (void) set_frame:(int32_t)number
{
    faceantspoofing->SetVideoFrameCount(number);//默认是10;
    
}

//人脸检测_检测人脸并放到数组中
- (SeetaFaceInfoArray) face_detect:(SeetaImageData)image
{
    if (facedector == NULL)
    {
        NSLog(@"dont init facedector");
        throw 1;
    }
    return facedector->detect(image);
}

//关键点提取_提取图像中人脸的特征点
- (std::vector<SeetaPointF>) face_mark:(const SeetaImageData)image WithSeetaRect:(const SeetaRect)face
{
    if (faceLandmarker == NULL)
    {
        NSLog(@"dont init facelandmarker");
        throw 1;
    }
    //这里检测到的5点坐标循序依次为，左眼中心、右眼中心、鼻尖、左嘴角和右嘴角。
    return faceLandmarker->mark(image, face);
    
}


//活体检测_way如果是0为单帧识别,1为多帧识别
- (int) face_predict:(const SeetaImageData)image WithSeetaRect:(const SeetaRect)face WithSeetaPointF:(std::vector<SeetaPointF>)v_points WithWay:(int)way
{
    
    if (faceantspoofing == NULL)
    {
        NSLog(@"faceantspoofing dont init");
        throw 1;
    }
    
    SeetaPointF points[5];
    for (int i = 0; i < 5; i++)
    {
        points[i] = v_points.at(i);
        
    }
    
    int status;
    switch (way)
    {
        case 0:
            status = faceantspoofing->Predict(image, face, points);
            break;
        case 1:
            status = faceantspoofing->PredictVideo(image, face, points);
            break;
        default:
            NSLog(@"way input error") ;
            throw 2;
            
    }
    switch (status) {
        case seeta::FaceAntiSpoofing::REAL:
            NSLog(@"真实人脸"); break;
        case seeta::FaceAntiSpoofing::SPOOF:
            NSLog(@"攻击人脸"); break;
        case seeta::FaceAntiSpoofing::FUZZY:
            NSLog(@"无法判断"); break;
        case seeta::FaceAntiSpoofing::DETECTING:
            NSLog(@"正在检测"); break;
    }
    return status;
}

//人脸对比_获取图片中特征
- (float*) fase_extract_feature:(const SeetaImageData)image WithSeetaPointF:(std::vector<SeetaPointF>)faces
{
    if (faceRecognizer == NULL)
    {
        NSLog(@"dont init facerecongizer");
        throw 1;
    }
    SeetaPointF points[5];
    for (int i = 0; i < 5; i++)
    {
        points[i] = faces.at(i);
    }
    float* feature = new float[faceRecognizer->GetExtractFeatureSize()];
    faceRecognizer->Extract(image, points, feature);
    return feature;
}


//人脸对比_比较两个特征判断是否相似
- (float) fase_compare:(float*)feature1 With:(float*)feature2
{
    return faceRecognizer->CalculateSimilarity(feature1, feature2);
}


//按人脸大小排列人脸数组
- (void) face_sort:(SeetaFaceInfoArray)face_sfia
{
    int m = face_sfia.size;
    std::vector<SeetaFaceInfo> faces(m);
    for (int i = 0; i < face_sfia.size; i++)
    {
        faces.at(i) = face_sfia.data[i];
    }
    std::partial_sort(faces.begin(), faces.begin() + 1, faces.end(), [](SeetaFaceInfo a, SeetaFaceInfo b) {
        return a.pos.width > b.pos.width;
    });
    for (int i = 0; i < face_sfia.size; i++)
    {
        face_sfia.data[i] = faces.at(i);
    }
}

//BGR数据转SeetaImageData
- (SeetaImageData) frame_to_seetaImageData:(uint8_t *)frame Channels:(int)channels Width:(int)width Height:(int)height
{
    SeetaImageData img;
    img.width = width;
    img.height = height;
    img.channels = channels;
    img.data = frame;
    return img;
    
}

//检测数据过来了
- (void)faceDetect:(uint8_t *)frame Channels:(int)channels Width:(int)width Height:(int)height
{
    
    SeetaImageData img = [self frame_to_seetaImageData:frame Channels:channels Width:width Height:height];
    SeetaFaceInfoArray infoArray =  [self face_detect:img];
    if (infoArray.size <= 0)
    {
        NSLog(@"未检测到脸");
        return;
    }else {
        NSLog(@"检测到人脸了");
    }
    if(infoArray.size > 1){
        [self face_sort:infoArray];
    }
    
    for (int i=0; i<infoArray.size; i++) {//循环取出检测到的人脸,在根据检测出的人脸提取关键点，活体检测，人脸对比一系列操作。
        SeetaFaceInfo faceInfo = infoArray.data[i];
        if(self.delegate && [self.delegate respondsToSelector:@selector(faceDetectSuccessCallback:Width:Height:)]){
            CGRect frame = CGRectMake(faceInfo.pos.x, faceInfo.pos.y, faceInfo.pos.width, faceInfo.pos.height);
            [self.delegate faceDetectSuccessCallback:frame Width:width Height:height];
        }
        std::vector<SeetaPointF> spf = [self face_mark:img WithSeetaRect:infoArray.data[i].pos];
        
        
        
  
        
        
        
        int status = [self face_predict:img WithSeetaRect:infoArray.data[i].pos WithSeetaPointF:spf WithWay:1];
        if(self.delegate && [self.delegate respondsToSelector:@selector(facePredictCallback:)]){
            [self.delegate facePredictCallback:status];
        }
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(facefeatureCompareCallback:)]) {
            [self.delegate facefeatureCompareCallback:[self fase_compare:_feature With:[self fase_extract_feature:img WithSeetaPointF:spf]]];
        }
        NSLog(@"status->%d，SPOOF_STATE_STR->%s",status,SPOOF_STATE_STR[status]);
    }
}

-(void)stopFaceRecognizerManagers {
    if(facedector != NULL){
        free(facedector);
    }
    
    if(faceLandmarker != NULL){
        free(faceLandmarker);
    }
    
    if(faceantspoofing != NULL){
        free(faceantspoofing);
    }
    
    if(faceRecognizer != NULL){
        free(faceRecognizer);
    }
    
}




@end
