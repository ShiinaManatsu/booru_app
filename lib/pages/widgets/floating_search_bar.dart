import 'package:booru_app/pages/widgets/sliver_floating_bar.dart';
import 'package:flutter/material.dart';

class FloatingSearchBar extends StatelessWidget {
  FloatingSearchBar({
    this.body,
    this.backgroundColor,
    this.drawer,
    this.trailing,
    this.leading,
    this.endDrawer,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.title,
    this.decoration,
    this.onTap,
    @required List<Widget> children,
  }) : _childDelagate = SliverChildListDelegate(
          children,
        );

  FloatingSearchBar.builder({
    this.body,
    this.backgroundColor,
    this.drawer,
    this.endDrawer,
    this.trailing,
    this.leading,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.title,
    this.onTap,
    this.decoration,
    @required IndexedWidgetBuilder itemBuilder,
    @required int itemCount,
  }) : _childDelagate = SliverChildBuilderDelegate(
          itemBuilder,
          childCount: itemCount,
        );

  final Widget leading, trailing, body, drawer, endDrawer;

  final Color backgroundColor;

  final SliverChildDelegate _childDelagate;

  final TextEditingController controller;

  final ValueChanged<String> onChanged;

  final ValueChanged<String> onSubmitted;

  final InputDecoration decoration;

  final VoidCallback onTap;

  /// Override the search field
  final Widget title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: drawer,
      endDrawer: endDrawer,
      body: CustomScrollView(
        slivers: <Widget>[
          SliverFloatingBar(
            leading: leading,
            floating: true,
            backgroundColor: backgroundColor,
            title: title ??
                TextField(
                  controller: controller,
                  decoration: decoration ??
                      InputDecoration.collapsed(
                        hintText: "Search...",
                      ),
                  autofocus: false,
                  onChanged: onChanged,
                  onSubmitted: onSubmitted,
                  onTap: onTap,
                  style: TextStyle(fontSize: 17),
                ),
            trailing: trailing,
          ),
          SliverList(
            delegate: _childDelagate,
          ),
        ],
      ),
    );
  }
}
