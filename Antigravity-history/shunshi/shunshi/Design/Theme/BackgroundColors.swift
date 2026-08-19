import SwiftUI

// MARK: - 背景色彩体系
enum AppBackground {
    /// 主背景色 - 暖白
    static let primary = Color(hex: "FBF9F7")
    
    /// 次要背景色 - 更浅的暖白
    static let secondary = Color(hex: "FFFDFB")
    
    /// 分割线颜色 - 暖灰
    static let divider = Color(hex: "E8E4E0")
    
    /// 卡片背景色 - 纯白
    static let card = Color.white
    
    /// 浅色卡片背景
    static let cardLight = Color(hex: "F7F5F3")
    
    /// 浅色背景 - 用于页面背景
    static let light = Color(hex: "F0FDF9")
}

// MARK: - 文字色彩体系
enum AppText {
    /// 主文字色 - 深灰
    static let primary = Color(hex: "2D2D2D")
    
    /// 次要文字色 - 中灰
    static let secondary = Color(hex: "757575")
    
    /// 辅助文字色 - 浅灰
    static let tertiary = Color(hex: "9E9E9E")
    
    /// 占位文字色
    static let placeholder = Color(hex: "BDBDBD")
}

// MARK: - 语义色彩
enum SemanticColor {
    /// 成功色 - 绿色
    static let success = Color(hex: "4CAF50")
    
    /// 警告色 - 橙色
    static let warning = Color(hex: "FF9800")
    
    /// 错误色 - 红色
    static let error = Color(hex: "F44336")
    
    /// 信息色 - 蓝色
    static let info = Color(hex: "2196F3")
}

// Color.init(hex:) 定义在 Design/Theme/ColorExtensions.swift
