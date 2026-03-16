import SwiftUI

extension Color {
    static let brand = Color("Brand")
    static let success = Color("Success")
    static let warning = Color("Warning")
    static let info = Color("Info")
}

extension ShapeStyle where Self == Color {
    static var brand: Color { .brand }
    static var success: Color { .success }
    static var warning: Color { .warning }
    static var info: Color { .info }
}
