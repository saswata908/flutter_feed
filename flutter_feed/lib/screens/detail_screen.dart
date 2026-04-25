import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post.dart';
import '../providers/like_provider.dart';

class DetailScreen extends ConsumerWidget {
  final Post post;

  const DetailScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likeArgs = (postId: post.id, likeCount: post.likeCount);
    final likeState = ref.watch(likeProvider(likeArgs));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Download High-Res button
          TextButton.icon(
            onPressed: () => _downloadHighRes(context),
            icon: const Icon(Icons.download, color: Colors.white),
            label: const Text(
              'Download High-Res',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Hero + tiered image loading
          Hero(
            tag: post.id,
            child: Stack(
              children: [
                // Layer 1: Thumb from cache (instant)
                CachedNetworkImage(
                  imageUrl: post.mediaThumbUrl,
                  memCacheWidth: 300,
                  width: double.infinity,
                  height: 400,
                  fit: BoxFit.cover,
                ),

                // Layer 2: Mobile URL fades in on top
                CachedNetworkImage(
                  imageUrl: post.mediaMobileUrl,
                  width: double.infinity,
                  height: 400,
                  fit: BoxFit.cover,
                  fadeInDuration: const Duration(milliseconds: 400),
                  placeholder: (context, url) =>
                      const SizedBox.shrink(), // thumb shows underneath
                  errorWidget: (context, url, error) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          // Like section
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    ref.read(likeProvider(likeArgs).notifier).toggle();
                  },
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      likeState.isLiked
                          ? Icons.favorite
                          : Icons.favorite_border,
                      key: ValueKey(likeState.isLiked),
                      color: likeState.isLiked ? Colors.red : Colors.white,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${likeState.likeCount} likes',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _downloadHighRes(BuildContext context) {
    // Only fetches raw URL on explicit user request
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('High-Res Download'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Raw image URL:'),
            const SizedBox(height: 8),
            SelectableText(
              post.mediaRawUrl,
              style: const TextStyle(fontSize: 12, color: Colors.blue),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
