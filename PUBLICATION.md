# 1oo1 — A macOS menu bar app for the classics

*I built a small app to help me stop endlessly browsing and actually watch and listen to the things I keep telling myself I'll get to.*

---

There are two lists I've always wanted to work through: *1001 Movies You Must See Before You Die* and *1001 Albums You Must Hear Before You Die*. The books are sitting on my shelf. The intent is always there. But without a system, "I'll get to it eventually" turns into never.

So I built **1oo1** — a macOS menu bar app that makes it stupidly simple.

## How it works

The app lives in your menu bar as a 🍿 icon. Click it and you get one movie and one album — randomly picked from the lists, ones you haven't seen or heard yet. No choices, no rabbit holes. Just: here's what's next.

You can watch the trailer, open the album on Spotify, and when you're done, mark it as watched or listened. Optionally leave a rating (half-stars supported) and a note. Then the app quietly picks the next one.

That's it.

## What's inside

Under the hood it's a proper little macOS app — no Electron, no web views:

- **SwiftUI** popover (360px wide, menu bar native)
- **SQLite via GRDB** — all your data lives locally, nothing is sent anywhere
- **TMDB API** for movie posters, ratings, trailers and overviews
- **MusicBrainz + Cover Art Archive** for album cover art, with iTunes Search as fallback
- **Smart image caching** — posters and covers are stored on disk with SHA256-hashed filenames, so they load instantly after the first fetch
- **Full history view** — everything you've watched or listened to, with your ratings, notes and dates
- **Progress tracking** — see how far along you are on each list

The whole dataset — all 1001 movies and 1001 albums — ships bundled in the app as JSON and gets seeded into a local SQLite database on first launch. After that, the app works completely offline except for fetching posters and covers on demand.

## Why a menu bar app?

I wanted something that would be there but not in the way. You don't need to open an app, log in, or deal with a complicated UI. You click the icon, you see what's next, you go watch or listen to it. The bar to engage is as low as possible.

## What I learned building it

A few things that turned out to be more interesting than expected:

**Wrong poster art is a hard problem.** The original dataset I was working with had a lot of mismatched TMDB IDs — like *Blow-Up* (1966) pointing to the metadata for *Good Night, and Good Luck* (2005). I ended up building a Python script to audit all 1001 movie IDs against the TMDB API, checking title + year similarity with fuzzy matching. Found and fixed dozens of mismatches.

**Image cache collisions can be sneaky.** I was using the last 200 characters of the URL as a cache filename — which works until two different URLs share the same suffix. Replaced it with SHA256 hashing of the full URL. Trivial fix, obvious in hindsight.

**Race conditions in async image fetching are real.** When the user skips quickly between recommendations, the image fetch for the previous item can resolve after the new item is already showing. Added ID-based guards (`guard currentMovie?.id == movie.id`) at every suspension point to prevent stale images from leaking into the wrong card.

**MusicBrainz requires patience.** Their rate limit is 1 request per second. Building a reliable album cover fetching pipeline meant properly respecting that — the service is implemented as an actor with a built-in delay.

## Open source

The full source is on GitHub: [github.com/amarazzi/1oo1](https://github.com/amarazzi/1oo1)

It's MIT licensed. You'll need a free TMDB API key to get movie metadata, but everything else works out of the box.

---

I'm at somewhere around 4/1001 movies and 2/1001 albums. Progress.

*— [Axel Marazzi](https://axelhaciendo.cosas)*
