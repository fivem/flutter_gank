import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gank/constant/strings.dart';
import 'package:flutter_gank/model/gank_item.dart';
import 'package:flutter_gank/net/gank_api.dart';
import 'package:flutter_gank/widget/gank_list_item.dart';
import 'package:flutter_gank/widget/indicator_factory.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class GankListCategory extends StatefulWidget {
  final String category;

  GankListCategory(this.category);

  @override
  _GankListCategoryState createState() => _GankListCategoryState();
}

class _GankListCategoryState extends State<GankListCategory>
    with AutomaticKeepAliveClientMixin, GankApi {
  bool _isLoading = true;
  List _gankItems = [];
  int _page = 1;
  RefreshController _refreshController;

  @override
  void initState() {
    super.initState();
    _refreshController = new RefreshController();
    _getCategoryData();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Stack(
        children: <Widget>[
          Offstage(
            offstage: _isLoading,
            child: SmartRefresher(
              controller: _refreshController,
              headerBuilder: buildDefaultHeader,
              footerBuilder: (context, mode) =>
                  buildDefaultFooter(context, mode, () {
                    _refreshController.sendBack(
                        false, RefreshStatus.refreshing);
                  }),
              onRefresh: _onRefresh,
              enablePullUp: true,
              child: ListView.builder(
                itemCount: _gankItems?.length ?? 0,
                itemBuilder: (context, index) =>
                    GankListItem(_gankItems[index]),
              ),
            ),
          ),
          Offstage(
            offstage: !_isLoading,
            child: Center(
              child: CupertinoActivityIndicator(),
            ),
          )
        ],
      ),
    );
  }

  void _onRefresh(bool up) {
    if (!up) {
      _page++;
      _getCategoryData(loadMore: true);
    } else {
      _page = 1;
      _getCategoryData();
    }
  }

  void _getCategoryData({bool loadMore = false}) async {
    var categoryData = await getCategoryData(
        widget.category == STRING_GANK_ALL ? "all" : widget.category, _page);
    var gankItems = categoryData['results']
        .map<GankItem>((itemJson) =>
            GankItem.fromJson(itemJson, category: widget.category))
        .toList();
    if (loadMore) {
      _refreshController.sendBack(false, RefreshStatus.idle);
      setState(() {
        _gankItems.addAll(gankItems);
        _isLoading = false;
      });
    } else {
      _refreshController.sendBack(true, RefreshStatus.completed);
      setState(() {
        _gankItems = gankItems;
        _isLoading = false;
      });
    }
  }

  @override
  bool get wantKeepAlive => true;
}
