//
//  YXCameraManger.h
//  YXToolSDK
//
//  Created by shg on 2020/10/30.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIkit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YXCameraManger : NSObject


/// 初始化相机管理
/// @param frame 相机在视图中的位置
/// @param shutterSound 拍照时是否有快门声音 ， shutterSound = true 有快门声音 使用AVCapturePhotoOutput 输出 ， shutterSound = false 没有快门声音 使用 AVCaptureVideoDataOutput 输出
- (instancetype)initWithFarme:(CGRect)frame shutterSound:(BOOL)shutterSound;

/// 相机显示区域视图
@property (nonatomic,strong) UIView *cameraView;

/// 开始拍照
/// @param images 返回一组照片
- (void)beganToTakePicturesWithCallBack:(void(^)(NSArray<UIImage *> *images))images;

@end

NS_ASSUME_NONNULL_END
