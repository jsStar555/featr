//
//  Chip.swift
//  featrrrnew
//
//  Created by Josh Beck on 3/25/24.
//

import SwiftUI

enum ChipStyle {
    case information, cancel, success, pending, inverse
}
struct Chip: View {
    
    private let style: ChipStyle
    private let text: String
    private let backgroundColor: Color
    private let textColor: Color
    
    init(text: String, style: ChipStyle) {
        self.style = style
        self.text = text
        switch (style) {
        case .information:
            backgroundColor = Color.primary
            textColor = Color.background
        case .cancel:
            backgroundColor = Color.warning
            textColor = Color.background
        case .success:
            backgroundColor = Color.success
            textColor = Color.background
        case .pending:
            backgroundColor = Color.lightBackground
            textColor = Color.background
        case .inverse:
            backgroundColor = Color.background
            textColor = Color.foreground
        }
    }
    var body: some View {
        VStack {
            
            Text(text)
                .padding()
                .minimumScaleFactor(0.8)
                .font(Style.font.body2)
        }
        .frame(height: 26)
        .background(backgroundColor)
        .foregroundColor(textColor)
        .cornerRadius(.cornerM)
    }
}

#Preview {
    Chip(text: "TEST CHIP", style: .information)
}
