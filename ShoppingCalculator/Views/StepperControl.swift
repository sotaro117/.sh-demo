import Foundation
import SwiftUI

struct StepperControl: View {
    @Binding var value: Int
    var minValue: Int
    var maxValue: Int
    
    var body: some View {
        HStack(spacing: 15) {
            Button("-") {
                guard value > minValue else { return }
                value -= 1
            }
            .foregroundStyle(.line)
            .frame(width: 15, height: 15)
            .padding(15)
            .background(Color.gray.opacity(0.2))
            .clipShape(Circle())
            .accessibilityLabel("Decrease quantity")

            Text("\(value)")
                .foregroundStyle(.line)
                .accessibilityLabel("Quantity: \(value)")

            Button("+") {
                guard value < maxValue else { return }
                value += 1
            }
            .foregroundStyle(.line)
            .frame(width: 15, height: 15)
            .padding(15)
            .background(Color.gray.opacity(0.2))
            .clipShape(Circle())
            .accessibilityLabel("Increase quantity")
        }
        .foregroundStyle(.primary)
    }
}
