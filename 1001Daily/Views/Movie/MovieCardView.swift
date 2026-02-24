import SwiftUI

struct MovieCardView: View {
    let movie: Movie
    let image: NSImage?
    let isLoading: Bool
    let onWatched: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header
            HStack {
                Image(systemName: "film.stack")
                    .foregroundStyle(.indigo)
                Text("WATCH")
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
                .help("Get a different movie")
            }
            .padding(.bottom, 10)

            HStack(alignment: .top, spacing: 12) {
                // Poster
                AsyncCachedImage(
                    image: image,
                    isLoading: isLoading && image == nil,
                    width: 90,
                    height: 134,
                    cornerRadius: 6
                )

                // Metadata
                VStack(alignment: .leading, spacing: 4) {
                    Text(movie.title)
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(movie.director)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Text(String(movie.year))
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        if let runtime = movie.runtimeMinutes {
                            Text("·")
                                .foregroundStyle(.tertiary)
                            Text("\(runtime)min")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        if let rating = movie.tmdbRating {
                            Text("·")
                                .foregroundStyle(.tertiary)
                            Text(String(format: "★ %.1f", rating))
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }

                    Text(movie.genre)
                        .font(.caption)
                        .foregroundStyle(.indigo)
                        .lineLimit(1)

                    if let overview = movie.overview, !overview.isEmpty {
                        Text(overview)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 2)
                    }

                    Spacer(minLength: 4)

                    // Action buttons
                    HStack(spacing: 8) {
                        if let url = movie.trailerURL {
                            Link(destination: url) {
                                Label("Trailer", systemImage: "play.rectangle.fill")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.indigo)
                            }
                        }

                        Spacer()

                        Button(action: onWatched) {
                            Label("Watched", systemImage: "checkmark.circle.fill")
                                .font(.caption.weight(.semibold))
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.indigo)
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

struct MovieCompletedView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 32))
                .foregroundStyle(.yellow)
            Text("All 1001 Movies Watched!")
                .font(.headline)
            Text("You've completed the list. Incredible!")
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
