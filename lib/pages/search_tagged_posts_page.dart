import 'package:floating_search_bar/floating_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:yande_web/models/rx/booru_api.dart';
import 'package:yande_web/models/rx/update_args.dart';
import 'package:yande_web/models/yande/tags.dart';
import 'home_page.dart';

class SearchTaggedPostsPage extends StatefulWidget {
  SearchTaggedPostsPage({Key key}) : super(key: key);

  @override
  _SearchTaggedPostsPageState createState() => _SearchTaggedPostsPageState();
}

class _SearchTaggedPostsPageState extends State<SearchTaggedPostsPage> {
  List<String> _tags = List<String>();
  String _searchPattern = "";

  Stream<List<String>> search;
  final _onTextChanged = PublishSubject<String>();

  @override
  void initState() {
    super.initState();
    search = _onTextChanged
        .distinct()
        .throttleTime(Duration(milliseconds: 500))
        .where((x) => x != "")
        .switchMap<List<String>>((mapper) => _search(mapper));

    search.listen((x) {
      setState(() {
        _tags = x;
      });
    });
  }

  static Stream<List<String>> _search(String term) async* {
    List<String> result = new List<String>();
    await TagDataBase.searchTags(term).then((x) {
      result = x;
    });
    yield result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: FloatingSearchBar.builder(
      itemCount: _tags.length,
      itemBuilder: (BuildContext context, int index) {
        return ListTile(
          leading: Text(_tags[index]),
          onTap: () {
            searchTerm = _tags[index];
            booruBloc.onUpdate.add(UpdateArg(
                fetchType: FetchType.Search,
                arg: TaggedArgs(tags: searchTerm, page: 1)));
            Navigator.pop(context);
          },
        );
      },
      trailing: IconButton(
        icon: Icon(Icons.search),
        onPressed: () {
          if (_searchPattern != "") {
            searchTerm = _searchPattern;
            booruBloc.onUpdate.add(UpdateArg(
                fetchType: FetchType.Search,
                arg: TaggedArgs(tags: searchTerm, page: 1)));
            Navigator.pop(context);
          } else {
            return;
          }
        },
      ),
      // drawer: Drawer(
      //   child: Container(),
      // ),
      onChanged: (x) {
        _onTextChanged.add(x);
        _searchPattern = x;
      },
      onSubmitted: (x) {
        if (_searchPattern != "") {
          booruBloc.onUpdate.add(UpdateArg(
              fetchType: FetchType.Search,
              arg: TaggedArgs(tags: searchTerm, page: 1)));
          Navigator.pop(context);
        } else {
          return;
        }
      },
      decoration: InputDecoration.collapsed(
        hintText: "Search...",
      ),
    ));
  }
}
