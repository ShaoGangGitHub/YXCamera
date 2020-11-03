//
//  YXToolManger.swift
//  YXToolSDK
//
//  Created by shg on 2020/10/27.
//

import UIKit
import CoreGraphics

@objc public class YXToolManger: NSObject {

    // MARK: -- 版本号
    /// SDK版本号
    /// - Returns: 当前版本号
    @objc public class func sdkVersion() -> String {
        return "1.0"
    }
    
    // MARK: -- 截取图片的任意区域
    /// 截取图片的任意区域
    /// - Parameters:
    ///   - rect: 截取区域,图片实际区域内截取
    ///   - image: 当前图片
    /// - Returns: 截取的图片
    @objc public class func subImageInRect(rect:CGRect,image:UIImage) -> UIImage {
        
        let newcgImage = image.cgImage?.cropping(to: rect)
        let newImage = UIImage.init(cgImage: newcgImage!)
        return newImage
    }
    
    // MARK: -- 压缩图片
    /// 压缩图片
    /// - Parameters:
    ///   - size: 目标尺寸
    ///   - image: 当前图片
    /// - Returns: 目标图片
    @objc public class func scaleImage(size:CGSize,image:UIImage) -> UIImage {
        
        if __CGSizeEqualToSize(size, image.size) {
            return image
        }
        let width = image.size.width
        let height = image.size.height
        let scale = width/height
        
        var newWidth:CGFloat = 0.0;
        var newHeigth:CGFloat = 0.0
        if size.width > size.height {
            
            newWidth = size.width
            newHeigth = newWidth / scale
            
        } else if size.width == size.height {
            
            if width > height {
                
                newWidth = size.width
                newHeigth = newWidth / scale
                
            } else if width == height {
                
                newWidth = size.width
                newHeigth = size.height
                
            } else {
                newHeigth = size.height
                newWidth = newHeigth * scale
            }
            
        } else {
            
            newHeigth = size.height
            newWidth = newHeigth * scale
        }
        
        let rect:CGRect = CGRect(x: 0, y: 0, width: newWidth, height: newHeigth)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, UIScreen.main.scale)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()
        
        return newImage
        
    }
    
    // MARK: -- 指定大小区域里生成图片
    /// 指定大小区域里生成图片
    /// - Parameters:
    ///   - image: 背景图
    ///   - size: 指定区域大小
    /// - Returns: 目标图片
    @objc public class func creatImage(image:UIImage,size:CGSize) -> UIImage {
        
        let view = UIView.init()
        view.bounds = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        view.backgroundColor = UIColor(patternImage: image)
        
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        view.layer.render(in: UIGraphicsGetCurrentContext()!)
        let newImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    // MARK: -- 转化成图片
    /// view 转化成图片
    /// - Parameter view: 当前View视图
    /// - Returns: 目标图片
    @objc public class func creatImage(view:UIView) -> UIImage {
     
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, UIScreen.main.scale)
        view.layer.render(in: UIGraphicsGetCurrentContext()!)
        let newImage = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage.init()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    // MARK: -- 压缩图片大小
    /// 压缩图片大小
    /// - Parameter image: 原始图片
    /// - Parameter size: 目标大小,单位 kb
    /// - Returns: 目标图片
    @objc public class func thinImage(image:UIImage,size:Int) -> Data {
        
        var cmp:CGFloat = 1.0;
        var newData = image.jpegData(compressionQuality: cmp)
        if newData!.count/1024 <= size {
            return newData!
        }
        while newData!.count/1024 > size && cmp > 0.01 {
            cmp -= 0.02
            newData = image.jpegData(compressionQuality: cmp)
        }
        return newData!
    }
}
