# 1oo1

> A macOS menu bar app that guides you through the *1001 Movies You Must See Before You Die* and *1001 Albums You Must Hear Before You Die* lists — one at a time.

![macOS](https://img.shields.io/badge/macOS-14%2B-black?style=flat-square)
![Swift](https://img.shields.io/badge/Swift-5.9-orange?style=flat-square)
![License](https://img.shields.io/badge/license-MIT-blue?style=flat-square)

---

## What is it?

**1oo1** lives quietly in your menu bar. Every time you open it, it shows you one movie and one album you haven't seen or heard yet. Watch it, listen to it, rate it, leave a note — then move on to the next one.

No algorithms. No infinite scrolling. Just a curated list of 1001 classics, yours to work through at your own pace.

<img width="360" alt="1oo1 main screen" src="https://github.com/user-attachments/assets/placeholder-screenshot.png" />

---

## Features

- 🎬 **1001 movies** from the canonical film list, with posters, directors, genres, runtime, TMDB rating and trailer link
- 🎵 **1001 albums** from the canonical music list, with cover art, artists, genres and a direct link to Spotify
- ⭐ **Rate & review** — give a star rating (half-stars supported) and write notes for anything you finish
- ⏭ **Skip** anything you're not in the mood for and come back later
- 📋 **History** — a full log of everything you've watched or listened to, with ratings, notes and completion date
- 📊 **Progress** — see how far along you are on each list (e.g. 37/1001 movies)
- 🖼 **Smart image caching** — posters and cover art are cached locally so they load instantly after the first time
- 🔒 **Fully offline after first load** — all data lives in a local SQLite database; only images and metadata are fetched from external APIs on demand

---

## How it works

On first launch, 1oo1 seeds a local SQLite database with all 1001 movies and 1001 albums from bundled JSON files. From there, everything is stored on your machine.

When you open the popover, the app surfaces one unseen movie and one unseen album at random. Movie metadata (poster, overview, rating, trailer) is fetched from **TMDB**. Album cover art is sourced from **MusicBrainz / Cover Art Archive**, with **iTunes Search** as a fallback. Images are cached on disk using SHA256-hashed filenames to avoid collisions.

When you mark something as watched or listened, a history entry is created locally and the next recommendation is picked automatically.

---

## Tech stack

| Layer | Technology |
|---|---|
| UI | SwiftUI (macOS popover, 360px) |
| State management | `@Observable` macro |
| Local database | [GRDB](https://github.com/groue/GRDB.swift) (SQLite) |
| Movie metadata | [TMDB API](https://www.themoviedb.org/documentation/api) |
| Album metadata | [MusicBrainz](https://musicbrainz.org/doc/MusicBrainz_API) + [Cover Art Archive](https://coverartarchive.org/) |
| Album cover fallback | [iTunes Search API](https://developer.apple.com/library/archive/documentation/AudioVideo/Conceptual/iTuneSearchAPI) |
| Image cache | NSCache (memory) + disk (SHA256 filenames) |
| Concurrency | Swift structured concurrency (`async/await`, actors) |
| Menu bar | AppKit (`NSStatusItem`, `NSPopover`) |

---

## Download

**[→ Download latest release](https://github.com/amarazzi/1oo1/releases/latest)**

1. Download `1oo1.zip` and unzip it
2. Drag `1oo1.app` to your **Applications** folder
3. Open Terminal and run:
   ```bash
   xattr -cr /Applications/1oo1.app
   ```
4. Open the app — it will appear as a 🍿 icon in your menu bar

> The `xattr` command is necessary because the app is not signed with an Apple Developer certificate. It removes the quarantine flag that macOS adds to files downloaded from the internet.

---

## Requirements

- macOS 14 Sonoma or later

---

## Build from source

1. **Clone the repo**

   ```bash
   git clone https://github.com/amarazzi/1oo1.git
   cd 1oo1
   ```

2. **Add your TMDB API key**

   Create a file at `~/.1001daily_config` with the following content:

   ```
   TMDB_API_KEY=your_api_key_here
   ```

   Alternatively, create a `Config.xcconfig` file in the project root:

   ```
   TMDB_API_KEY = your_api_key_here
   ```

3. **Open in Xcode**

   ```bash
   open "1001 movies or albums.xcodeproj"
   ```

4. **Run** — the app will appear in your menu bar as a 🍿 icon.

---

## Project structure

```
1001Daily/
├── App/                    # Entry point, AppDelegate, AppViewModel, AppEnvironment
├── Models/                 # Movie, Album, HistoryEntry, Recommendation
├── Database/
│   ├── DatabaseManager.swift         # SQLite setup & migrations
│   └── Repositories/                 # MovieRepository, AlbumRepository, etc.
├── Engine/
│   └── RecommendationEngine.swift    # Business logic for recommendations
├── Services/
│   ├── TMDBService.swift             # Movie metadata & posters
│   ├── MusicBrainzService.swift      # Album cover art
│   ├── ImageCacheService.swift       # 3-tier image cache
│   └── BundleDataLoader.swift        # Seeds DB from bundled JSON on first launch
├── Views/
│   ├── PopoverRootView.swift         # Root 3-screen navigator
│   ├── Movie/                        # MovieCardView, MovieRatingModal
│   ├── Album/                        # AlbumCardView, AlbumRatingModal
│   ├── History/                      # HistoryView, HistoryRowView
│   ├── Settings/                     # SettingsView
│   └── Shared/                       # AsyncCachedImage, StarRatingView
└── Resources/
    ├── movies_1001.json              # Full list of 1001 movies
    └── albums_1001.json              # Full list of 1001 albums
```

---

## Data sources

- **Movies** — Based on the book *1001 Movies You Must See Before You Die* (Steven Jay Schneider, ed.). Metadata enriched via TMDB.
- **Albums** — Based on the book *1001 Albums You Must Hear Before You Die* (Robert Dimery, ed.). Cover art via MusicBrainz / iTunes.

---

## License

MIT — see [LICENSE](LICENSE) for details.

---

Made by [Axel Marazzi](https://axelhaciendo.cosas)
