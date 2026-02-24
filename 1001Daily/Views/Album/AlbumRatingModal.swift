import SwiftUI

struct AlbumRatingModal: View {
    let album: Album
    let onConfirm: (Double?, String?) -> Void
    let onSkip: () -> Void

    @State private var rating: Double = 0
    @State private var notes = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Image(systemName: "music.note.list")
                    .foregroundStyle(.purple)
                Text("Rate this Album")
                    .font(.headline)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            // Album title
            VStack(alignment: .leading, spacing: 2) {
                Text(album.title)
                    .font(.title3.weight(.semibold))
                    .lineLimit(2)
                Text(album.artist)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Star rating
            VStack(alignment: .leading, spacing: 8) {
                Text("Your rating")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                StarRatingView(rating: $rating, starSize: 28, color: .purple)
            }

            // Notes
            VStack(alignment: .leading, spacing: 8) {
                Text("Notes (optional)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                TextEditor(text: $notes)
                    .font(.body)
                    .frame(height: 80)
                    .padding(6)
                    .background(.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(.secondary.opacity(0.3), lineWidth: 1)
                    )
            }

            // Buttons
            HStack {
                Button("Skip Rating") {
                    onSkip()
                    dismiss()
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                Spacer()

                Button("Save & Get Next") {
                    onConfirm(rating > 0 ? rating : nil, notes.isEmpty ? nil : notes)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
            }
        }
        .padding(20)
        .frame(width: 320)
    }
}
