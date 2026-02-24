import SwiftUI

struct AlbumCardView: View {
    let album: Album
    let image: NSImage?
    let isLoading: Bool
    let onListened: () -> Void
    let onSkip: () -> Void
    @State private var expandedDescription = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header
            HStack {
                Image(systemName: "music.note.list")
                    .foregroundStyle(.purple)
                Text("LISTEN")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .tracking(1)
                Spacer()
                Button(action: onSkip) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Get a different album")
            }
            .padding(.bottom, 10)

            HStack(alignment: .top, spacing: 12) {
                // Cover art (square)
                AsyncCachedImage(
                    image: image,
                    isLoading: isLoading && image == nil,
                    width: 90,
                    height: 90,
                    cornerRadius: 6
                )

                // Metadata
                VStack(alignment: .leading, spacing: 4) {
                    Text(album.title)
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(album.artist)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Text(String(album.year))
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        Text("·")
                            .foregroundStyle(.tertiary)
                        Text(album.genre)
                            .font(.caption)
                            .foregroundStyle(.purple)
                            .lineLimit(1)
                    }

                    if let description = album.description, !description.isEmpty {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(expandedDescription ? nil : 3)
                                .fixedSize(horizontal: false, vertical: true)
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) { expandedDescription.toggle() }
                            } label: {
                                Text(expandedDescription ? "less" : "more")
                                    .font(.caption)
                                    .foregroundStyle(.purple)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.top, 2)
                    }

                    Spacer(minLength: 4)

                    // Action buttons
                    HStack(spacing: 8) {
                        if let url = album.spotifySearchURL {
                            Link(destination: url) {
                                Label("Spotify", systemImage: "arrow.up.right.square")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.purple)
                            }
                        }

                        Spacer()

                        Button(action: onListened) {
                            Label("Listened", systemImage: "checkmark.circle.fill")
                                .font(.caption.weight(.semibold))
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.purple)
                        .controlSize(.small)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(14)
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct AlbumCompletedView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "headphones")
                .font(.system(size: 32))
                .foregroundStyle(.purple)
            Text("All 1001 Albums Listened!")
                .font(.headline)
            Text("Your ears have heard it all. Legendary!")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
