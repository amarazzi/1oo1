import SwiftUI
import AppKit

struct AsyncCachedImage: View {
    let image: NSImage?
    let isLoading: Bool
    let width: CGFloat
    let height: CGFloat
    var cornerRadius: CGFloat = 8

    var body: some View {
        Group {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
            } else if isLoading {
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.secondary.opacity(0.15))
                    ProgressView()
                        .scaleEffect(0.8)
                }
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.secondary.opacity(0.15))
                    Image(systemName: "photo")
                        .font(.system(size: min(width, height) * 0.3))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
    }
}
