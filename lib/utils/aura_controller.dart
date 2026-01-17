import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

class AuraController {
  AuraController._();

  static final AuraController instance = AuraController._();

  static const AssetImage defaultImage = AssetImage('resources/images/app_icon.png');

  final ValueNotifier<ImageProvider> _image = ValueNotifier<ImageProvider>(defaultImage);

  ValueListenable<ImageProvider> get imageListenable => _image;

  ImageProvider get image => _image.value;

  void _setImage(ImageProvider provider) {
    if (identical(_image.value, provider)) return;

    final phase = SchedulerBinding.instance.schedulerPhase;
    final canSetNow = phase == SchedulerPhase.idle || phase == SchedulerPhase.postFrameCallbacks;
    if (canSetNow) {
      _image.value = provider;
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _image.value = provider;
    });
  }

  AuraHandle push(ImageProvider provider) {
    final prev = _image.value;
    _setImage(provider);
    return AuraHandle._(prev);
  }

  void pop(AuraHandle handle) {
    _setImage(handle._previous);
  }

  void setNetworkUrl(String? url) {
    if (url == null || url.isEmpty) return;

    final current = _image.value;
    if (current is CachedNetworkImageProvider && current.url == url) {
      return;
    }

    _setImage(CachedNetworkImageProvider(url));
  }
}

class AuraHandle {
  AuraHandle._(this._previous);

  final ImageProvider _previous;
}
