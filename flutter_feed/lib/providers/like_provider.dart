import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

const String kUserId = 'user_123';

class LikeState {
  final bool isLiked;
  final int likeCount;

  LikeState({required this.isLiked, required this.likeCount});
}

class LikeNotifier extends StateNotifier<LikeState> {
  LikeNotifier({required String postId, required int initialLikeCount})
    : _postId = postId,
      super(LikeState(isLiked: false, likeCount: initialLikeCount));

  final String _postId;
  final _supabase = Supabase.instance.client;
  Timer? _debounceTimer;
  bool _lastSyncedIsLiked = false;

  void toggle() {
    final newIsLiked = !state.isLiked;
    final newCount = newIsLiked ? state.likeCount + 1 : state.likeCount - 1;
    state = LikeState(isLiked: newIsLiked, likeCount: newCount);

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 600), () {
      _syncWithServer(newIsLiked);
    });
  }

  Future<void> _syncWithServer(bool expectedIsLiked) async {
    try {
      await _supabase.rpc(
        'toggle_like',
        params: {'p_post_id': _postId, 'p_user_id': kUserId},
      );
      _lastSyncedIsLiked = expectedIsLiked;
    } catch (e) {
      final revertedCount = _lastSyncedIsLiked
          ? state.likeCount + 1
          : state.likeCount - 1;
      state = LikeState(isLiked: _lastSyncedIsLiked, likeCount: revertedCount);
      // Show SnackBar globally
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Failed to update like. Check your connection.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

final likeProvider =
    StateNotifierProvider.family<
      LikeNotifier,
      LikeState,
      ({String postId, int likeCount})
    >(
      (ref, args) =>
          LikeNotifier(postId: args.postId, initialLikeCount: args.likeCount),
    );
