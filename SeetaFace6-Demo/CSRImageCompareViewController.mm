//
//  CSRImageCompareViewController.m
//  SeetaFace6-Demo
//
//  Created by 程森然 on 2021/4/23.
//

#import "CSRImageCompareViewController.h"
#include <SeetaFaceDetector600/seeta/FaceDetector.h>
#include <SeetaFaceLandmarker600/seeta/FaceLandmarker.h>
#include <SeetaFaceRecognizer610/seeta/FaceRecognizer.h>
#include <SeetaFaceAntiSpoofingX600/seeta/FaceAntiSpoofing.h>
#include <SeetaEyeStateDetector200/seeta/EyeStateDetector.h>
#include <SeetaMaskDetector200/seeta/MaskDetector.h>
#include <SeetaAgePredictor600/seeta/AgePredictor.h>
#include <SeetaGenderPredictor600/seeta/GenderPredictor.h>
#include <SeetaFaceTracking600/seeta/FaceTracker.h>
#include <SeetaQualityAssessor300/seeta/QualityOfBrightness.h>
#include <SeetaQualityAssessor300/seeta/QualityOfClarity.h>
#include <SeetaQualityAssessor300/seeta/QualityOfIntegrity.h>
#include <SeetaQualityAssessor300/seeta/QualityOfLBN.h>
#include <SeetaQualityAssessor300/seeta/QualityOfPose.h>
#include <SeetaQualityAssessor300/seeta/QualityOfPoseEx.h>
#include <SeetaQualityAssessor300/seeta/QualityOfResolution.h>
#include <opencv2/core/core.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <iostream>
#include <fstream>

#import "UIImage+OpenCV.h"


@interface CSRImageCompareViewController ()<UINavigationControllerDelegate, UIImagePickerControllerDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *oneImage;

@property (weak, nonatomic) IBOutlet UIImageView *twoImage;
@property (weak, nonatomic) IBOutlet UITextView *resultView;
@property(assign,nonatomic)BOOL isFirst;
@property(assign,nonatomic)BOOL isCameer;

@end
@implementation CSRImageCompareViewController

class PipeStream {
public:
    PipeStream() {}
    
    const std::string str() const {
        return oss.str();
    }
    
    template <typename T>
    PipeStream &operator << (T &&t) {
        std::cout << std::forward<T>(t);
        oss << std::forward<T>(t);
        return *this;
    }
private:
    std::ostringstream oss;
};


template <typename T, typename ...Args>
void TestQuality(PipeStream &pipe,
                 const std::string &name,
                 const SeetaImageData &image,
                 const SeetaRect &face,
                 const std::vector<SeetaPointF> &points,
                 Args &&...args) {
    seeta::QualityRule *qa = new T(std::forward<Args>(args)...);
    static const char *LEVEL[] = {"low", "medium", "high"};
    
    auto result = qa->check(image, face, points.data(), int32_t(points.size()));
    
    pipe << name << ": level=" << LEVEL[int(result.level)] << ", score=" << result.score << "\n";
    
    delete qa;
}


namespace seeta {
    class QualityOfClarityEx : public QualityRule {
    public:
        QualityOfClarityEx(const std::string &lbn, const std::string &marker) {
            m_lbn = std::make_shared<QualityOfLBN>(ModelSetting(lbn));
            m_marker = std::make_shared<FaceLandmarker>(ModelSetting(marker));
        }
        QualityOfClarityEx(const std::string &lbn, const std::string &marker, float blur_thresh) {
            m_lbn = std::make_shared<QualityOfLBN>(ModelSetting(lbn));
            m_marker = std::make_shared<FaceLandmarker>(ModelSetting(marker));
            m_lbn->set(QualityOfLBN::PROPERTY_BLUR_THRESH, blur_thresh);
        }
        
        QualityResult check(const SeetaImageData &image, const SeetaRect &face, const SeetaPointF *points, int32_t N) override {
            // assert(N == 68);
            auto points68 = m_marker->mark(image, face);
            int light, blur, noise;
            m_lbn->Detect(image, points68.data(), &light, &blur, &noise);
            if (blur == QualityOfLBN::BLUR) {
                return {QualityLevel::LOW, 0};
            } else {
                return {QualityLevel::HIGH, 1};
            }
        }
    private:
    std::shared_ptr<QualityOfLBN> m_lbn;
    std::shared_ptr<FaceLandmarker> m_marker;
    };
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.resultView.userInteractionEnabled = NO;
}



- (IBAction)oneSelectImage:(id)sender {
    self.isFirst = YES;
    UIAlertController *alterVc = [UIAlertController alertControllerWithTitle:@"" message:@"选择图片方式" preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"使用相机拍照" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self takePhoto];
    }];
    
    UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"从相册中选取照片" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self LocalPhoto];
    }];
    
    UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }];
    [alterVc addAction:action];
    [alterVc addAction:action1];
    [alterVc addAction:action2];
    [self presentViewController:alterVc animated:YES completion:nil];
}

- (IBAction)twoSeleImage:(id)sender {
    self.isFirst = NO;

    UIAlertController *alterVc = [UIAlertController alertControllerWithTitle:@"" message:@"选择图片方式" preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"使用相机拍照" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self takePhoto];
    }];
    
    UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"从相册中选取照片" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self LocalPhoto];
    }];
    
    UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }];
    [alterVc addAction:action];
    [alterVc addAction:action1];
    [alterVc addAction:action2];
    [self presentViewController:alterVc animated:YES completion:nil];
}

/**
 开始拍照
 */
-(void)takePhoto{
    UIImagePickerControllerSourceType sourceType = UIImagePickerControllerSourceTypeCamera;
    if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera]){
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        picker.sourceType = sourceType;
        picker.allowsEditing = YES;
        self.isCameer = YES;
        self.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:picker animated:YES completion:nil];
    }else{
        NSLog(@"模拟器中无法打开照相机,请在真机中使用");
    }
}

#pragma mark 打开本地相册
-(void)LocalPhoto{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.delegate = self;
    self.isCameer = NO;
    [self presentViewController:picker animated:YES completion:nil];
}


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    [picker dismissViewControllerAnimated:YES completion:nil];
    UIImage *imageq = nil;
    if (self.isCameer) {
        imageq = [info objectForKey:UIImagePickerControllerEditedImage];
    }else {
        imageq = [info objectForKey:UIImagePickerControllerOriginalImage];

    }
    if (self.isFirst) {
        self.oneImage.image = imageq;
    }else {
        self.twoImage.image = imageq;
    }

}



- (IBAction)beginCompare:(id)sender {
    
    if (self.oneImage.image && self.twoImage.image) {
        
        PipeStream pipe;
        
        std::string buddle = [[[NSBundle mainBundle] resourcePath] UTF8String];
        seeta::ModelSetting FD_model(
            buddle + "/assert/model/face_detector.csta");
        
        seeta::ModelSetting FR_model(
            buddle + "/assert/model/face_recognizer_light.csta");
        
        seeta::ModelSetting FL_model(
            buddle + "/assert/model/face_landmarker_pts5.csta");
        
        seeta::FaceDetector FD(FD_model);
        seeta::FaceLandmarker FL(FL_model);
        seeta::FaceRecognizer FR(FR_model);
        
        
        auto cvimg = [self cvMatFromUIImage:self.oneImage.image];
        auto cvimg1 = [self cvMatFromUIImage:self.twoImage.image];

        SeetaImageData img;
        img.height = cvimg.rows;
        img.width = cvimg.cols;
        img.channels = cvimg.channels();
        img.data = cvimg.data;
        
        SeetaImageData img1;
        img1.height = cvimg1.rows;
        img1.width = cvimg1.cols;
        img1.channels = cvimg1.channels();
        img1.data = cvimg1.data;
        
        auto faces = FD.detect_v2(img);
        auto faces1 = FD.detect_v2(img1);

        if (faces.empty()) {
            return;
        }
        if (faces1.empty()) {
            return;
        }
        
        pipe << "Detected " << faces.size() << " face(s)." << "\n";
        for (auto &face : faces) {
            SeetaRect rect = face.pos;
            std::cout << "[" << rect.x << ", " << rect.y << ", "
                              << rect.width << ", " << rect.height << "]: "
                              << face.score << std::endl;
        }
        pipe << "Detected1 " << faces.size() << " face(s)." << "\n";
        for (auto &face : faces) {
            SeetaRect rect = face.pos;
            std::cout << "[" << rect.x << ", " << rect.y << ", "
                              << rect.width << ", " << rect.height << "]: "
                              << face.score << std::endl;
        }
        
        auto face = faces[0];
        auto face1 = faces1[0];
        auto points = FL.mark(img, face.pos);
        auto points1 = FL.mark(img1, face1.pos);
        std::unique_ptr<float[]> features(new float[FR.GetExtractFeatureSize()]);
        std::unique_ptr<float[]> features1(new float[FR.GetExtractFeatureSize()]);
        FR.Extract(img, points.data(), features.get());
        FR.Extract(img1, points1.data(), features1.get());

        pipe << "Extract " << features.get() << " features." << "\n";
        pipe << "Extract1 " << features1.get() << " features." << "\n";


        
        
        CGFloat value = FR.CalculateSimilarity(features.get(), features1.get());
        
        
        pipe << "compare " << value << "" << "\n";
        
        
        [self.resultView setText:[NSString stringWithCString:pipe.str().c_str() encoding:[NSString defaultCStringEncoding]]];
        
        
        
        
    }
}




- (cv::Mat)cvMatFromUIImage:(UIImage *)image {
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
