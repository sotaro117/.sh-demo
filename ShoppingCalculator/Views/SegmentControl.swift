import Foundation
import SwiftUI

struct SegmentControl: View {
    @Binding var selectedIndex: Int
    var labels: [String]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(labels.indices, id: \.self){ index in
                Button {
                    withAnimation(.interactiveSpring()) {
                        selectedIndex = index
                    }
                } label: {
                    VStack {
                        Text(labels[index])
                            .foregroundStyle(selectedIndex == index ? Color.line : Color.gray)

                        Rectangle()
                            .fill(selectedIndex == index ? Color.line : Color.bg)
                            .frame(width: 30, height: 3)
                            .cornerRadius(20)
                    }
                    .padding()
                }
                .buttonStyle(.plain)
                .accessibilityLabel(labels[index])
                .accessibilityAddTraits(selectedIndex == index ? .isSelected : [])
            }
        }
    }
}
