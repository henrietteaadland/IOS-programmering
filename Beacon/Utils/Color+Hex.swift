import SwiftUI

extension Color {
    /// Lager en Color fra en HEX-kode, f.eks. "#FF9B52"
    init(hex: String) {
        var s = hex
        // Fjern '#' hvis den finnes
        if s.hasPrefix("#") { s.removeFirst() }

        // Konverter tekst til tallverdi
        let v = Int(s, radix: 16) ?? 0xFFFFFF

        // Beregn RGB-komponenter
        self.init(
            .sRGB,
            red: Double((v >> 16) & 0xFF) / 255,
            green: Double((v >> 8) & 0xFF) / 255,
            blue: Double(v & 0xFF) / 255,
            opacity: 1
        )
    }
}
