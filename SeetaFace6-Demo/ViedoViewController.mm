//
//  ViedoViewController.m
//  SeetaFace6-Demo
//
//  Created by 程森然 on 2021/4/23.
//

#import "ViedoViewController.h"
#import "beginViedoCompareViewController.h"
#include <SeetaFaceDetector600/seeta/FaceDetector.h>
#include <SeetaFaceLandmarker600/seeta/FaceLandmarker.h>
#include <SeetaFaceRecognizer610/seeta/FaceRecognizer.h>
#import "UIImage+OpenCV.h"

@interface ViedoViewController ()<UINavigationControllerDelegate, UIImagePickerControllerDelegate>{
    float * seleImageFeature;
}

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property(assign,nonatomic)BOOL isCameer;

@property (weak, nonatomic) IBOutlet UILabel *result;



@end

@implementation ViedoViewController

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
}


- (IBAction)iphoneSelect:(id)sender {
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
    self.modalPresentationStyle = UIModalPresentationPageSheet;
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
    self.imageView.image = imageq;
    auto cvimg = [UIImage cvMatFromUIImage:imageq];
    
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
    
    SeetaImageData img;
    img.height = cvimg.rows;
    img.width = cvimg.cols;
    img.channels = cvimg.channels();
    img.data = cvimg.data;
    
    auto faces = FD.detect_v2(img);
    if(faces.size()==0){
        return;
    }
    auto face = faces[0];
    auto points = FL.mark(img, face.pos);
    float *feature = new float[FR.GetExtractFeatureSize()];
    FR.Extract(img, points.data(), feature);
    seleImageFeature = feature;
    
//    NSLog(@"%f",feature.size());
    
}



- (IBAction)videoBegin:(id)sender {
    beginViedoCompareViewController *vc = [[beginViedoCompareViewController alloc]init];
    vc.modalPresentationStyle = UIModalPresentationFullScreen;
    vc.compareImage = self.imageView.image;
    vc.feature = seleImageFeature;
    vc.returnResult = ^(BOOL isLive, float result) {
        self.result.text = [NSString stringWithFormat:@"比对结果:%f!%@",result,isLive?@"活体":@"非活体"];
    };
    [self presentViewController:vc animated:YES completion:nil];
}





@end
