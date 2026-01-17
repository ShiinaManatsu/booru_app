import 'package:booru_app/models/rx/booru_api.dart';
import 'package:booru_app/pages/home/post_feed.dart';
import 'package:booru_app/settings/language.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key, required this.booruApi});

  final BooruAPI booruApi;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  String _tags = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(FontAwesomeIcons.magnifyingGlass),
                    hintText: language.content.searchTags,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onSubmitted: _submit,
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => _submit(_controller.text),
                child: const Icon(FontAwesomeIcons.arrowRight),
              ),
            ],
          ),
        ),
        Expanded(
          child: _tags.isEmpty
              ? Center(child: Text(language.content.searchTags))
              : PostFeed(
                  title: language.content.search,
                  initialFetchType: FetchType.Search,
                  booruApi: widget.booruApi,
                  tags: _tags,
                ),
        ),
      ],
    );
  }

  void _submit(String value) {
    setState(() => _tags = value.trim());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
