# Flutter High-Performance Feed

A highly optimized, infinite-scrolling social feed built with Flutter and Supabase, focusing on UI performance, memory management, and optimistic state management.

---

## Features

- Infinite scrolling feed with pagination (10 posts at a time)
- Pull-to-refresh
- Hero animation from feed to detail screen
- Tiered image loading (thumbnail to mobile resolution)
- Download High-Res button (fetches raw URL only on demand)
- Optimistic like/unlike with instant UI feedback
- Debounced network calls to prevent race conditions
- Offline detection with automatic UI revert and SnackBar error
- GPU optimization via RepaintBoundary
- RAM optimization via memCacheWidth

---

## Tech Stack

- **Flutter** - UI framework
- **Riverpod** - State management
- **Supabase** - Backend (Database, Storage, RPC)
- **cached_network_image** - Image caching

---

## Project Structure

```
lib/
├── main.dart                  # App entry, Supabase init, global scaffold key
├── models/
│   └── post.dart              # Post data model with fromJson factory
├── providers/
│   ├── feed_provider.dart     # Infinite scroll, pagination, pull-to-refresh
│   └── like_provider.dart     # Optimistic like state, debounce, offline revert
├── screens/
│   ├── feed_screen.dart       # Main feed with ListView and scroll listener
│   └── detail_screen.dart     # Hero destination, tiered loading, download button
└── widgets/
    └── post_card.dart         # RepaintBoundary card with shadow and like button
```

---

## Backend Setup (Supabase)

### Database Tables

**posts**

| Column | Type |
|---|---|
| id | UUID (Primary Key) |
| created_at | TIMESTAMPTZ |
| media_thumb_url | TEXT |
| media_mobile_url | TEXT |
| media_raw_url | TEXT |
| like_count | INT |

**user_likes**

| Column | Type |
|---|---|
| user_id | TEXT |
| post_id | UUID (Foreign Key to posts.id) |

### RPC Function

`toggle_like(p_post_id, p_user_id)` is a concurrency-safe PostgreSQL function that atomically toggles a like. It tries to delete the like first; if deleted it decrements the count, otherwise it inserts and increments. A `unique_violation` exception handler prevents race conditions from concurrent requests.

### Storage

A public Supabase storage bucket named `media` stores three versions of each image:

- `_thumb.webp` - 300x300px, quality 70 (used in feed)
- `_mobile.webp` - 1080x1080px, quality 80 (used in detail screen)
- `_raw.jpg` - Original full resolution (downloaded only on explicit user request)

---

## Data Seeding Pipeline

A Python script (`flutter_feed_seeder/seed.py`) processes local images into the 3-tier pipeline and uploads them to Supabase Storage, then inserts the public URLs into the `posts` table.

### Run the seeder

```bash
pip install supabase Pillow
python seed.py
```

---

## Riverpod State Management Approach

### Feed State (feed_provider.dart)

A `StateNotifier<FeedState>` manages the entire feed lifecycle:

- `FeedState` holds the list of posts, loading flags (`isLoading`, `isLoadingMore`), and a `hasMore` boolean
- `fetchInitial()` is called on notifier creation to load the first page
- `fetchMore()` uses `.range(from, to)` for offset-based pagination, guarded by `isLoadingMore` and `hasMore` flags to prevent duplicate calls
- `refresh()` resets state to initial and calls `fetchInitial()` again

### Like State (like_provider.dart)

A `StateNotifierProvider.family` keyed by `({String postId, int likeCount})` creates an isolated like state per post.

**Optimistic UI flow:**

1. User taps like - UI updates instantly (heart turns red, count increments)
2. A 600ms debounce timer starts
3. If user taps again within 600ms - timer resets (spam protection)
4. After 600ms of no taps - single RPC call fires to Supabase
5. On success - `_lastSyncedIsLiked` updates
6. On failure - UI reverts to `_lastSyncedIsLiked` state and a global SnackBar appears

**Why `.family`?** Each post needs its own independent like state. Using `.family` with the post ID as the key means Riverpod creates and manages a separate notifier instance per post, automatically disposing it when the post leaves the screen.

---

## GPU Optimization - RepaintBoundary

Every `PostCard` is wrapped in a `RepaintBoundary`:

```dart
return RepaintBoundary(
  child: Container(
    decoration: BoxDecoration(
      boxShadow: [
        BoxShadow(
          blurRadius: 30,
          spreadRadius: 2,
        ),
      ],
    ),
  ),
);
```

Without `RepaintBoundary`, Flutter's GPU must recalculate the `BoxShadow` blur math for every card on every frame during fast scrolling, causing jank. With `RepaintBoundary`, Flutter rasterizes each card into its own GPU layer once and reuses it during scrolling. Shadow math is never recalculated unless the card's content actually changes.

**Verification:** Open Flutter DevTools, go to the Performance tab and enable "Track widget rebuilds". During fast scrolling, `PostCard` should show no rebuilds. In the Raster thread timeline, frame times should stay under 16ms.

---

## RAM Optimization - memCacheWidth

Thumbnails in the feed are loaded with a memory cache width constraint:

```dart
CachedNetworkImage(
  imageUrl: post.mediaThumbUrl,
  memCacheWidth: 300,
  height: 300,
  fit: BoxFit.cover,
)
```

Without `memCacheWidth`, Flutter decodes the image at its full original resolution into RAM even if it is displayed at 300px. A 4K image decoded fully uses approximately 31MB of RAM per image. With `memCacheWidth: 300`, the same image uses approximately 0.34MB, a 90x reduction. In a feed with dozens of posts this prevents Out Of Memory crashes.

**Verification:** Open Flutter DevTools, go to the Memory tab and compare heap usage while scrolling with and without `memCacheWidth`. With the constraint, memory should stay flat during scrolling instead of growing continuously.

---

## Edge Cases Handled

### Spam Clicker

Tapping like 15 times in 2 seconds only fires one RPC call. The debounce timer resets on every tap, so the network call fires only after the user stops tapping for 600ms. The UI updates on every tap for instant feedback, but the database stays consistent.

### Rapid Scroll Jank

`RepaintBoundary` on every card prevents shadow recalculation during fast scrolling. The GPU rasterizes each card once and reuses the cached layer, keeping frame times well under 16ms.

### Offline Revert

When WiFi is off:

1. User taps like - heart turns red instantly (optimistic)
2. After 600ms - RPC call fails
3. UI reverts to previous state automatically
4. A floating red SnackBar appears: "Failed to update like. Check your connection."
5. No permanent UI desync - the state always reflects the last known server state

---

## Screen Recording

The screen recording demonstrates:

- Infinite scroll feed loading
- Pull-to-refresh
- Hero animation from feed card to detail screen
- Tiered image loading (thumb fading into mobile resolution)
- Optimistic like working online
- Offline like revert with SnackBar error

---

## Author

Saswata Saha
