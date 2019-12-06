import 'package:yande_web/models/yande/post.dart';

class PostState {}

class PostLoading extends PostState {}

class PostError extends PostState {
  final dynamic error;
  
  PostError({this.error});
}

class PostSuccess extends PostState {
  final List<Post> result;

  PostSuccess(this.result);
}

class PostEmpty extends PostState {}
