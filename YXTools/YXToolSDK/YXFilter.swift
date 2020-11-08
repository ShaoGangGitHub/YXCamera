//
//  YXFilter.swift
//  YXToolSDK
//
//  Created by shg on 2020/11/4.
//

import UIKit
import CoreImage

/// 滤镜
@objc public class YXFilter: CIFilter {

    /// 获取所有的滤镜
    /// - Parameter category: 滤镜扩展
    /// - Returns: 某个扩展里所有的滤镜
    /// [kCICategoryDistortionEffect, 扭曲效果，比如bump、旋转、hole
    /// kCICategoryGeometryAdjustment, 几何开着调整，比如仿射变换、平切、透视转换
    /// kCICategoryCompositeOperaCIFiltertion, 合并，比如源覆盖（source over）、最小化、源在顶（source atop）、色彩混合模式
    /// kCICategoryHalftoneEffect, Halftone效果，比如screen、line screen、hatched
    /// kCICategoryColorAdjustment, 色彩调整，比如伽马调整、白点调整、曝光
    /// kCICategoryColorEffect, 色彩效果，比如色调调整、posterize
    /// kCICategoryTransition, 图像间转换，比如dissolve、disintegrate with mask、swipe
    /// kCICategoryTileEffect, 瓦片效果，比如parallelogram、triangle
    /// kCICategoryGenerator, 图像生成器，比如stripes、constant color、checkerboard
    /// kCICategoryReduction, 一种减少图像数据的过滤器。这些过滤器是用来解决图像分析问题
    /// kCICategoryGradient, 渐变，比如轴向渐变、仿射渐变、高斯渐变
    /// kCICategoryStylize, 风格化，比如像素化、水晶化
    /// kCICategorySharpen, 锐化、发光
    /// kCICategoryBlur, 模糊，比如高斯模糊、焦点模糊、运动模糊
    /// kCICategoryVideo, 能用于视频
    /// kCICategoryStillImage, 能用于静态图像
    /// kCICategoryInterlaced, 能用于交错图像
    /// kCICategoryNonSquarePixels, 能用于非矩形像素
    /// kCICategoryHighDynamicRange, 能用于HDR
    /// kCICategoryBuiltIn, 获取所有coreImage 内置滤镜
    /// kCICategoryFilterGenerator,  通过链接几个过滤器并将其打包为CIFilterGenerator对象而创建的过滤器]
    @objc public class func filterNamesinCategory(category: String) -> [String] {
        return YXFilter.filterNames(inCategory: category)
    }
    
    /// 给图片添加滤镜
    /// - Parameters:
    ///   - filterName: 滤镜名
    ///   - image: 原始图片
    /// - Returns: 目标图片
    @objc public class func filterToImage(filterName:String,image:UIImage,setFilter:@escaping(_ filter:YXFilter, _ ciImage:CIImage) -> Void) -> UIImage? {
       
        if let ciImage = CIImage.init(image: image) {
            guard  let filter:YXFilter = YXFilter.init(name: filterName) else {
                return nil
            }
            setFilter(filter,ciImage)
            print(filter.description)
            print(filter.inputKeys)
            print(filter.outputKeys)
            guard let outputImage:CIImage = filter.outputImage else {
                return nil
            }
            guard let glContext:EAGLContext = EAGLContext.init(api: .openGLES2) else {
                return nil
            }
            let context:CIContext = CIContext.init(eaglContext: glContext)
            guard let cgimage:CGImage = context.createCGImage(outputImage, from: outputImage.extent) else {
                return nil
            }
            let newImage:UIImage = UIImage.init(cgImage: cgimage, scale: image.scale, orientation: image.imageOrientation)
            return newImage
        }
        return nil
    }
    
    /// 多个滤镜叠加
    /// - Parameters:
    ///   - filters: 滤镜s
    ///   - image: 原始图片
    /// - Returns: 目标图片
    @objc public class func filtersToImage(filters:[YXFilter],image:UIImage) -> UIImage? {
        if var ciImage:CIImage = CIImage.init(image: image) {
            for filter:YXFilter in filters {
                filter.setValue(ciImage, forKey: kCIInputImageKey)
                guard let outputImage:CIImage = filter.outputImage else {
                    continue
                }
                ciImage = outputImage
            }
            guard let glContext:EAGLContext = EAGLContext.init(api: .openGLES2) else {
                return nil
            }
            let context:CIContext = CIContext.init(eaglContext: glContext)
            guard let cgimage:CGImage = context.createCGImage(ciImage, from: ciImage.extent) else {
                return nil
            }
            let newImage:UIImage = UIImage.init(cgImage: cgimage, scale: image.scale, orientation: image.imageOrientation)
            return newImage
        }
        return nil
    }
    
    /// 生成二维码
    /// - Parameters:
    ///   - qrContent: 二维码内容
    ///   - size: 大小
    ///   - codeType: qr 二维码  bar 条码
    /// - Returns: 目标图片
    @objc public class func filterToCreatQrCode(qrContent:String,size:CGFloat,codeType:YXFilter.QrCodeType) -> UIImage? {
        var name:String = ""
        if codeType == .bar {
            name = "CICode128BarcodeGenerator"
        }
        if codeType == .qr {
            name = "CIQRCodeGenerator"
        }
        let filter:YXFilter = YXFilter.init(name: name)!
        guard let data:Data = qrContent.data(using: .utf8) else {
            return nil
        }
        //设置内容
        filter.setValue(data, forKey: "inputMessage")
        if codeType == .qr {
            //设置纠错级别 L 20%、M 37%、Q 55%、H 65%
            filter.setValue("Q", forKey: "inputCorrectionLevel")
        }
        if codeType == .bar {
            filter.setValue(5, forKey: "inputQuietSpace")
            filter.setValue(size, forKey: "inputBarcodeHeight")
        }
        guard let cioutImage = filter.outputImage else {
            return nil
        }
        let imageSize = CGSize(width: size, height: size)
        let extent:CGRect = cioutImage.extent.integral
        let scale = min(imageSize.width/extent.width, imageSize.height/extent.height)
        let width:size_t = size_t(extent.width * scale)
        let height:size_t = size_t(extent.height * scale)
        let cs:CGColorSpace = CGColorSpaceCreateDeviceRGB()
        guard let cgContent:CGContext = CGContext.init(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return nil
        }
        // 关联GPU
        guard let glContext:EAGLContext = EAGLContext.init(api: .openGLES3) else {
            return nil
        }
        let cicontext:CIContext = CIContext.init(eaglContext: glContext)
        guard let cgimage:CGImage = cicontext.createCGImage(cioutImage, from: extent) else {
            return nil
        }
        cgContent.interpolationQuality = CGInterpolationQuality.none
        cgContent.scaleBy(x: scale, y: scale)
        cgContent.draw(cgimage, in: extent)
        guard let newCgimage = cgContent.makeImage() else {
            return nil
        }
        return UIImage.init(cgImage: newCgimage, scale: scale, orientation: .up)
    }
    
    /// 生成二维码
    /// - Parameters:
    ///   - color: 二维码颜色
    ///   - backColor: 二维码背景色
    ///   - qrContent: 二维码内容
    ///   - size: 大小尺寸
    ///   - codeType: .qr 二维码 .bar 条码
    /// - Returns: 目标二维码
    @objc public class func filterToCreatQrCodeWithColor(color:UIColor,backColor:UIColor,qrContent:String,size:CGFloat,codeType:YXFilter.QrCodeType) -> UIImage? {
        guard let image = self.filterToCreatQrCode(qrContent: qrContent, size: size, codeType: codeType) else {
            return nil
        }
        guard let filter = YXFilter.init(name: "CIFalseColor") else {
            return nil
        }
        guard let ciimage = CIImage.init(image: image) else {
            return nil
        }
        let ciColor = CIColor.init(color: color)
        let ciBackColor = CIColor.init(color: backColor)
        filter.setValue(ciimage, forKey: "inputImage")
        filter.setValue(ciColor, forKey: "inputColor0")
        filter.setValue(ciBackColor, forKey: "inputColor1")
        guard let outimage = filter.outputImage else {
            return nil
        }
        return UIImage.init(ciImage: outimage, scale: UIScreen.main.scale, orientation: .up)
    }
    
    /// 生成二维码，中间带图片
    /// - Parameters:
    ///   - centerImage: 二维码中的图片
    ///   - centerImageSize: 二维码中图片的大小
    ///   - qrContent: 二维码内容
    ///   - size: 二维码大小
    /// - Returns: 目标二维码图片
    @objc public class func filterToCreatQrCodeWithImage(centerImage:UIImage,centerImageSize:CGSize,qrContent:String,size:CGFloat) -> UIImage? {
        guard let image = self.filterToCreatQrCode(qrContent: qrContent, size: size, codeType: .qr) else {
            return nil
        }
        let newImageSize = CGSize(width: size, height: size)
        let newImageRect = CGRect.init(origin: CGPoint.zero, size: newImageSize)
        let centerRcte = CGRect(x: (size - centerImageSize.width)/2, y: (size - centerImageSize.height)/2, width: centerImageSize.width, height: centerImageSize.height)
        UIGraphicsBeginImageContextWithOptions(newImageSize, true, image.scale)
        image.draw(in: newImageRect)
        centerImage.draw(in: centerRcte)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
}

extension YXFilter {
    
    @objc public enum QrCodeType:Int {
        //二维码
        case qr  = 1
        //条形码
        case bar = 2
    }
}
