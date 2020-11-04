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
    @objc public class func filterToImage(filterName:String,image:UIImage) -> UIImage? {
       
        let ciImage = CIImage.init(image: image)
        let filter:YXFilter = YXFilter.init(name: filterName)!
        guard filter.inputKeys.contains("inputImage") else {
            return nil
        }
        filter.setValue(ciImage, forKey: "inputImage")
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
}
