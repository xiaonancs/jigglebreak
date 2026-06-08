import AppKit

extension NSColor {
    /// 从 "#RRGGBB" / "RRGGBB" / "#RRGGBBAA" 解析颜色。
    convenience init?(hex: String) {
        var value = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.hasPrefix("#") {
            value.removeFirst()
        }

        guard value.count == 6 || value.count == 8,
              let intValue = UInt64(value, radix: 16) else {
            return nil
        }

        let r, g, b, a: CGFloat
        if value.count == 6 {
            r = CGFloat((intValue & 0xFF0000) >> 16) / 255
            g = CGFloat((intValue & 0x00FF00) >> 8) / 255
            b = CGFloat(intValue & 0x0000FF) / 255
            a = 1
        } else {
            r = CGFloat((intValue & 0xFF000000) >> 24) / 255
            g = CGFloat((intValue & 0x00FF0000) >> 16) / 255
            b = CGFloat((intValue & 0x0000FF00) >> 8) / 255
            a = CGFloat(intValue & 0x000000FF) / 255
        }

        self.init(srgbRed: r, green: g, blue: b, alpha: a)
    }

    var hexString: String {
        let color = usingColorSpace(.sRGB) ?? self
        let r = Int(round(color.redComponent * 255))
        let g = Int(round(color.greenComponent * 255))
        let b = Int(round(color.blueComponent * 255))
        return String(format: "#%02X%02X%02X", r, g, b)
    }

    /// 根据背景色亮度返回易读的前景色（黑或白）。
    var readableForeground: NSColor {
        let color = usingColorSpace(.sRGB) ?? self
        let luminance = 0.299 * color.redComponent + 0.587 * color.greenComponent + 0.114 * color.blueComponent
        return luminance > 0.6 ? .black : .white
    }
}
