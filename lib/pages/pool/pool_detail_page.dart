import 'package:booru_app/models/rx/booru_api.dart';
import 'package:booru_app/models/yande/pool.dart';
import 'package:booru_app/pages/home/post_feed.dart';
import 'package:flutter/material.dart';

class PoolDetailPage extends StatelessWidget {
  const PoolDetailPage({
    super.key,
    required this.pool,
    required this.booruApi,
  });

  final Pool pool;
  final BooruAPI booruApi;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      builder: (context, t, child) {
        return Stack(
          children: [
            child!,
            IgnorePointer(
              child: Positioned.fill(
                child: ColoredBox(
                  color: Color.lerp(Colors.black, Colors.transparent, t)!,
                ),
              ),
            ),
          ],
        );
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(pool.name.isEmpty ? 'Pool #${pool.id}' : pool.name),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: PostFeed(
          title: 'pool_${pool.id}',
          initialFetchType: FetchType.Pool,
          poolId: pool.id,
          booruApi: booruApi,
        ),
      ),
    );
  }
}
