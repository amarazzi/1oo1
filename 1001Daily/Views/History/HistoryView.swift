import SwiftUI

struct HistoryView: View {
    @Environment(\.appEnvironment) private var env
    @State private var filter: HistoryFilter = .all

    enum HistoryFilter: String, CaseIterable {
        case all = "All"
        case movies = "Movies"
        case albums = "Albums"
    }

    var filteredEntries: [HistoryEntry] {
        switch filter {
        case .all: return env.viewModel.historyEntries
        case .movies: return env.viewModel.historyEntries.filter { $0.itemType == .movie }
        case .albums: return env.viewModel.historyEntries.filter { $0.itemType == .album }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            HStack(spacing: 20) {
                progressPill(
                    icon: "film.stack",
                    color: .indigo,
                    count: env.viewModel.movieCompletedCount,
                    total: 1001,
                    label: "movies"
                )
                progressPill(
                    icon: "music.note.list",
                    color: .purple,
                    count: env.viewModel.albumCompletedCount,
                    total: 1001,
                    label: "albums"
                )
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(.background.secondary)

            Divider()

            // Filter
            Picker("Filter", selection: $filter) {
                ForEach(HistoryFilter.allCases, id: \.self) { f in
                    Text(f.rawValue).tag(f)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)

            // List
            if filteredEntries.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 36))
                        .foregroundStyle(.tertiary)
                    Text("No history yet")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("Mark movies as watched or albums as listened to build your history.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 40)
            } else {
                List(filteredEntries) { entry in
                    HistoryRowView(entry: entry) {
                        if let id = entry.id {
                            Task { await env.viewModel.deleteHistoryEntry(id: id) }
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 4, leading: 14, bottom: 4, trailing: 14))
                    .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
            }
        }
        .task {
            await env.viewModel.loadHistory()
        }
    }

    @ViewBuilder
    private func progressPill(icon: String, color: Color, count: Int, total: Int, label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                Text("\(count)/\(total) \(label)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(.secondary.opacity(0.2))
                        .frame(height: 4)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: geo.size.width * min(CGFloat(count) / CGFloat(total), 1.0), height: 4)
                }
            }
            .frame(height: 4)
        }
        .frame(maxWidth: .infinity)
    }
}

struct HistoryRowView: View {
    let entry: HistoryEntry
    let onDelete: () -> Void
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 10) {
            // Type icon
            Image(systemName: entry.itemType == .movie ? "film.stack" : "music.note.list")
                .font(.system(size: 14))
                .foregroundStyle(entry.itemType == .movie ? .indigo : .purple)
                .frame(width: 20)

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Text(entry.itemType == .movie ? (entry.director ?? "") : (entry.artist ?? ""))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("·")
                        .foregroundStyle(.tertiary)
                    Text(String(entry.year))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                if let notes = entry.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .padding(.top, 1)
                }
            }

            Spacer()

            // Rating + date + delete
            VStack(alignment: .trailing, spacing: 2) {
                if isHovered {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                            .foregroundStyle(.red.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                } else {
                    StarRatingDisplayView(rating: entry.rating, starSize: 10)
                        .transition(.opacity)
                }
                Text(entry.displayDate)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .animation(.easeInOut(duration: 0.15), value: isHovered)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
    }
}
