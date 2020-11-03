//
//  YXCameraManger.m
//  YXToolSDK
//
//  Created by shg on 2020/10/30.
//

#import "YXCameraManger.h"

@interface YXCameraManger ()<AVCapturePhotoCaptureDelegate,AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic,strong) AVCaptureSession *captureSession;

@property (nonatomic,strong) AVCaptureDeviceInput *captureInput;

@property (nonatomic,strong) AVCaptureVideoDataOutput *captureVideoDataOutput;

@property (nonatomic,strong) AVCapturePhotoOutput *capturePhotoOutput;

@property (nonatomic,strong) AVCaptureVideoPreviewLayer *captureLayer;

@property (nonatomic,assign) BOOL shutterSound;

@property (nonatomic,copy)   void (^callBackImages)(NSArray<UIImage *> *images);

@property (nonatomic,strong) NSMutableArray *images;

@property (nonatomic,strong) NSTimer *timer;

@property (nonatomic,strong) NSMutableArray *sampleBuffers;

@end

@implementation YXCameraManger

- (instancetype)initWithFarme:(CGRect)frame shutterSound:(BOOL)shutterSound
{
    self = [super init];
    
    if (self) {
        
        AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        
        if (status != AVAuthorizationStatusAuthorized) {
            NSLog(@"用户未授权，无权使用摄像头");
            return nil;
        }
        
        self.captureSession = [[AVCaptureSession alloc] init];
        
        self.captureSession.sessionPreset = AVCaptureSessionPresetHigh;
        
        NSArray<AVCaptureDevice *> *devices = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack].devices;
        
        AVCaptureDevice *device = devices.firstObject;
        
        NSError *error;
        
        self.captureInput = [[AVCaptureDeviceInput alloc] initWithDevice:device error:&error];
        
        if (error) {
            NSLog(@"捕捉输入异常");
            return nil;
        }
        
        if ([self.captureSession canAddInput:self.captureInput]) {
            [self.captureSession addInput:self.captureInput];
        }
        
        if (shutterSound) {
        
            self.capturePhotoOutput = [[AVCapturePhotoOutput alloc]init];
            
            if ([self.captureSession canAddOutput:self.capturePhotoOutput]) {
                [self.captureSession addOutput:self.capturePhotoOutput];
            }
            
        } else {
            
            self.captureVideoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
            
            if ([self.captureSession canAddOutput:self.captureVideoDataOutput]) {
                [self.captureSession addOutput:self.captureVideoDataOutput];
            }
            
            self.sampleBuffers = [NSMutableArray array];
        }
        
        self.shutterSound = shutterSound;
        
        self.cameraView = [[UIView alloc] initWithFrame:frame];
        
        self.captureLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
        
        self.captureLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        
        self.captureLayer.frame = self.cameraView.bounds;
        
        [self.cameraView.layer addSublayer:self.captureLayer];
        
        [self.captureSession startRunning];
        
    }
    
    return self;
}

- (void)beganToTakePicturesWithCallBack:(void (^)(NSArray<UIImage *> * _Nonnull))images
{
    self.callBackImages = images;
    
    if (self.shutterSound) {
        AVCapturePhotoSettings *settings = [AVCapturePhotoSettings photoSettingsWithFormat:@{AVVideoCodecKey:AVVideoCodecTypeJPEG}];
        
        [self.capturePhotoOutput capturePhotoWithSettings:settings delegate:self];
        
    } else {
        
        dispatch_queue_t queue = dispatch_queue_create("videoDataQueue", NULL);
        
        [self.captureVideoDataOutput setSampleBufferDelegate:self queue:queue];
        
        self.captureVideoDataOutput.videoSettings = @{(id)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32BGRA)};
        
        __block NSInteger count = 2;
        
        __weak typeof(self) weakSelf = self;
        
        self.timer = [NSTimer timerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer) {
            
            __strong typeof(weakSelf) strongSelf = weakSelf;
            
            count--;
            
            if (count <= 0) {
                [strongSelf.timer invalidate];
                
                strongSelf.timer = nil;
                
                count = 2;
                
                [strongSelf.captureSession stopRunning];
                
                [strongSelf.sampleBuffers enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                         
                    __strong typeof(weakSelf) strongSelf = weakSelf;
                    
                    UIImage *image = [strongSelf imageFromSampleBuffer:(__bridge CMSampleBufferRef)(obj)];
                    
                    if (image != nil) {
                        [strongSelf.images addObject:image];
                    }
                    
                }];
                
                [strongSelf.sampleBuffers removeAllObjects];
                
                if (strongSelf.callBackImages) {
                    strongSelf.callBackImages(strongSelf.images);
                }
                
                [strongSelf.images removeAllObjects];
                
                [strongSelf.captureSession startRunning];
            }
            
        }];
        
        [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
    }
}

// AVCapturePhotoCaptureDelegate
- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(NSError *)error
{
    if (error) {
        NSLog(@"%@",error);
        if (self.callBackImages) {
            self.callBackImages(@[]);
        }
        return;
    }
    
    NSData *data = photo.fileDataRepresentation;

    UIImage *image = [UIImage imageWithData:data];
    
    if (self.callBackImages) {
        self.callBackImages(@[image]);
    }
}

- (NSMutableArray *)images
{
    if (!_images) {
        _images = [NSMutableArray array];
    }
    return _images;
}

// AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    [self.sampleBuffers addObject:(__bridge id _Nonnull)(sampleBuffer)];
}

- (UIImage *)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    CVPixelBufferLockBaseAddress(imageBuffer, 0);

    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);

    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    
    size_t height = CVPixelBufferGetHeight(imageBuffer);

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
                                                 bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);

    CGContextRelease(context);
    
    CGColorSpaceRelease(colorSpace);

    UIImage *image = [UIImage imageWithCGImage:quartzImage];

    CGImageRelease(quartzImage);

    return image;
}

- (void)dealloc
{
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

@end
