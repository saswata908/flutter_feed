import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post.dart';

// The state our feed holds
class FeedState {
  final List<Post> posts;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;

  FeedState({
    this.posts = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
  });

  FeedState copyWith({
    List<Post>? posts,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
  }) {
    return FeedState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class FeedNotifier extends StateNotifier<FeedState> {
  FeedNotifier() : super(FeedState()) {
    fetchInitial();
  }

  final _supabase = Supabase.instance.client;
  static const int _pageSize = 10;

  // Fetch first page
  Future<void> fetchInitial() async {
    state = state.copyWith(isLoading: true);

    try {
      final response = await _supabase
          .from('posts')
          .select()
          .order('created_at', ascending: false)
          .limit(_pageSize);

      final posts = (response as List).map((e) => Post.fromJson(e)).toList();

      state = state.copyWith(
        posts: posts,
        isLoading: false,
        hasMore: posts.length == _pageSize,
      );
    } catch (e) {
      print('❌ fetchInitial error: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  // Fetch next page (pagination)
  Future<void> fetchMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final int from = state.posts.length;
      final int to = from + _pageSize - 1;

      final response = await _supabase
          .from('posts')
          .select()
          .order('created_at', ascending: false)
          .range(from, to);

      final newPosts = (response as List).map((e) => Post.fromJson(e)).toList();

      state = state.copyWith(
        posts: [...state.posts, ...newPosts],
        isLoadingMore: false,
        hasMore: newPosts.length == _pageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  // Pull to refresh
  Future<void> refresh() async {
    state = FeedState();
    await fetchInitial();
  }
}

final feedProvider = StateNotifierProvider<FeedNotifier, FeedState>((ref) {
  return FeedNotifier();
});
