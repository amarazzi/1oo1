import SwiftUI

struct StarRatingView: View {
    @Binding var rating: Double
    var maxRating = 5
    var starSize: CGFloat = 20
    var color: Color = .yellow

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...maxRating, id: \.self) { star in
                let full = Double(star)
                let half = full - 0.5

                ZStack {
                    starImage(for: star)
                        .resizable()
                        .scaledToFit()
                        .frame(width: starSize, height: starSize)
                        .foregroundStyle(rating >= half ? color : .secondary.opacity(0.4))

                    // Left half → half-star, Right half → full star
                    HStack(spacing: 0) {
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.1)) {
                                    rating = rating == half ? 0 : half
                                }
                            }
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.1)) {
                                    rating = rating == full ? 0 : full
                                }
                            }
                    }
                }
                .frame(width: starSize, height: starSize)
            }
        }
    }

    private func starImage(for star: Int) -> Image {
        let full = Double(star)
        let half = full - 0.5
        if rating >= full {
            return Image(systemName: "star.fill")
        } else if rating >= half {
            return Image(systemName: "star.leadinghalf.filled")
        } else {
            return Image(systemName: "star")
        }
    }
}

// Read-only display version
struct StarRatingDisplayView: View {
    let rating: Double?
    var starSize: CGFloat = 12

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { star in
                let r = rating ?? 0.0
                let full = Double(star)
                let half = full - 0.5
                Image(systemName: r >= full ? "star.fill" : (r >= half ? "star.leadinghalf.filled" : "star"))
                    .resizable()
                    .scaledToFit()
                    .frame(width: starSize, height: starSize)
                    .foregroundStyle(r >= half ? .yellow : Color.secondary.opacity(0.4))
            }
        }
    }
}
