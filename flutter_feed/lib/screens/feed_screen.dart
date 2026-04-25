import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/feed_provider.dart';
import '../widgets/post_card.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedState = ref.watch(feedProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      appBar: AppBar(
        title: const Text(
          'Feed',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: _buildBody(context, ref, feedState),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, FeedState feedState) {
    // Initial loading
    if (feedState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Empty state
    if (feedState.posts.isEmpty) {
      return const Center(child: Text('No posts yet!'));
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(feedProvider.notifier).refresh(),
      child: NotificationListener<ScrollNotification>(
        onNotification: (scrollInfo) {
          // Trigger fetchMore when near bottom
          if (scrollInfo.metrics.pixels >=
              scrollInfo.metrics.maxScrollExtent - 300) {
            ref.read(feedProvider.notifier).fetchMore();
          }
          return false;
        },
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: feedState.posts.length + 1,
          itemBuilder: (context, index) {
            // Last item — show loader or end message
            if (index == feedState.posts.length) {
              if (feedState.isLoadingMore) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (!feedState.hasMore) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'You\'re all caught up! 🎉',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            }

            return PostCard(post: feedState.posts[index]);
          },
        ),
      ),
    );
  }
}
