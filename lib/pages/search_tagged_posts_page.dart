import 'dart:collection';
import 'package:booru_app/main.dart';
import 'package:booru_app/pages/widgets/floating_search_bar.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:booru_app/models/rx/booru_api.dart';
import 'package:booru_app/models/rx/update_args.dart';
import 'package:booru_app/models/yande/tags.dart';
import 'home_page.dart';

class SearchTaggedPostsPage extends StatefulWidget {
  SearchTaggedPostsPage({Key key}) : super(key: key);

  @override
  _SearchTaggedPostsPageState createState() => _SearchTaggedPostsPageState();
}

class _SearchTaggedPostsPageState extends State<SearchTaggedPostsPage>
    with TickerProviderStateMixin {
  HashSet<Tag> _chips = HashSet<Tag>();
  List<Tag> _tags = List<Tag>();

  Stream<List<Tag>> searchedTags;
  final _onTextChanged = PublishSubject<String>();

  @override
  void initState() {
    super.initState();
    searchedTags = _onTextChanged
        .throttleTime(Duration(milliseconds: 100))
        .distinct()
        .where((x) => x != "")
        .switchMap<List<Tag>>((mapper) => _search(mapper));

    searchedTags.listen((x) {
      setState(() {
        _tags = x;
      });
    });
  }

  static Stream<List<Tag>> _search(String term) async* {
    yield await TagDataBase.searchTags(term);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: FloatingSearchBar.builder(
      backgroundColor: Theme.of(context).backgroundColor.withOpacity(0.95),
      itemCount: _tags.length,
      itemBuilder: (BuildContext context, int index) {
        return ListTile(
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Icon(
                Icons.bookmark,
                color: TagToColorMap[_tags[index].tagType],
              ),
              Container(
                  width: 70,
                  margin: EdgeInsets.only(left: 5),
                  child: Text(
                      "${EnumToString.convertToString(_tags[index].tagType)}:")),
            ],
          ),
          title: Text(_tags[index].content),
          onTap: () {
            setState(() {
              if (_chips.length < 3) {
                _chips.add(_tags[index]);
              }
            });
          },
        );
      },
      leading: IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      trailing: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AnimatedSize(
              duration: Duration(milliseconds: 300),
              vsync: this,
              curve: Curves.ease,
              child: Row(
                  children: <Widget>[]..addAll(_chips.map((f) => Container(
                        margin: EdgeInsets.only(right: 3),
                        child: Chip(
                          label: Text(f.content),
                          backgroundColor: TagToColorMap[f.tagType],
                          deleteIcon: Icon(Icons.close),
                          onDeleted: () {
                            setState(() {
                              _chips.remove(f);
                            });
                          },
                        ),
                      )))),
            ),
          ]..add(
              Container(
                margin: EdgeInsets.only(left: 10),
                child: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    if (_chips.length != 0) {
                      searchTerm = _chips.map((x) => x.content).join(" ");
                      homePageFetchTypeChanged.add(FetchType.Search);
                      booruBloc.onReset.add(null);
                      booruBloc.onUpdate.add(UpdateArg(
                          fetchType: FetchType.Search,
                          arg: TaggedArgs(tags: searchTerm, page: 1)));
                      Navigator.pop(context);
                    } else {
                      return;
                    }
                  },
                ),
              ),
            )),
      onChanged: (x) {
        _onTextChanged.add(x);
      },
      decoration: InputDecoration.collapsed(
        hintText: "${language.content.searchTags}...",
      ),
      onSubmitted: (x) {
        if (_chips.length != 0) {
          searchTerm = _chips.map((x) => x.content).join(" ");
          homePageFetchTypeChanged.add(FetchType.Search);
          booruBloc.onReset.add(null);
          booruBloc.onUpdate.add(UpdateArg(
              fetchType: FetchType.Search,
              arg: TaggedArgs(tags: searchTerm, page: 1)));
          Navigator.pop(context);
        } else {
          homePageFetchTypeChanged.add(FetchType.Search);
          booruBloc.onReset.add(null);
          booruBloc.onUpdate.add(UpdateArg(
              fetchType: FetchType.Search, arg: TaggedArgs(tags: x, page: 1)));
          Navigator.pop(context);
        }
      },
    ));
  }
}
