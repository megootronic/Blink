import SwiftUI

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }

    static let panelGround = Color(hex: 0x17171D)
    static let xcode = Color(hex: 0x338FF0)
    static let alert = Color(hex: 0xFA5773)
}
