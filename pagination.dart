import 'package:demo/singleton/singleton.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

class InfiniteScrollExample extends StatefulWidget {
  const InfiniteScrollExample({super.key});

  @override
  State<InfiniteScrollExample> createState() => _InfiniteScrollExampleState();
}

class _InfiniteScrollExampleState extends State<InfiniteScrollExample> {
  final int _pageSize = 20;

  final PagingController<int, UserModel> _pagingController = PagingController(firstPageKey: 1);

  @override
  void initState() {
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
    super.initState();
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      // get api /beers list from pages
      final newItems = await RemoteApi.getBeerList(pageKey, _pageSize);
      // Check if it is last page
      final isLastPage = newItems!.length < _pageSize;
      // If it is last page then append last page else append new page
      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        // Appending new page when it is not last page
        final nextPageKey = pageKey + 1;
        _pagingController.appendPage(newItems, nextPageKey);
      }
    }
    // Handle error in catch
    catch (error) {
      print(_pagingController.error);
      // Sets the error in controller
      _pagingController.error = error;
    }
  }

  @override
  Widget build(BuildContext context) =>
      // Refrsh Indicator pull down
      RefreshIndicator(
        onRefresh: () => Future.sync(
          // Refresh through page controllers
          () => _pagingController.refresh(),
        ),
        child: Scaffold(
          appBar: AppBar(
            title: const Text("Pagination Scroll Flutter Template"),
          ),
          // Page Listview with divider as a separation
          body: PagedListView<int, UserModel>.separated(
            pagingController: _pagingController,
            builderDelegate: PagedChildBuilderDelegate<UserModel>(
              animateTransitions: true,
              itemBuilder: (_, item, index) => ListTile(
                title: Text(item.title!),
              ),
              noMoreItemsIndicatorBuilder: (context) {
                return const Text("No item left");
              },
            ),
            separatorBuilder: (_, index) => const Divider(),
          ),
        ),
      );

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }
}

class RemoteApi {
  static Future<List<UserModel>?> getBeerList(
    int page,
    int limit,
  ) async {
    try {
      // Request the API on url
      final response = await DioHttpService().handleGetRequest(
        'https://jsonplaceholder.typicode.com/posts?',
        queryParameters: {
          "_page": page,
          "_limit": limit,
        },
      );

      if (response.statusCode == 200) {
        // Decode the response
        List<dynamic> responseBody = response.data;
        // Convert the list of maps to a list of UserModel objects
        List<UserModel> users = responseBody.map((map) => UserModel.fromMap(map)).toList();
        return users;
      }
    } catch (e) {
      print("Error $e");
    }
    return null;
  }
}

class UserModel {
  final int? userId;
  final int? id;
  final String? title;
  final String? body;

  UserModel({
    this.userId,
    this.id,
    this.title,
    this.body,
  });

  factory UserModel.fromMap(Map<String, dynamic> json) => UserModel(
        userId: json["userId"],
        id: json["id"],
        title: json["title"],
        body: json["body"],
      );

  Map<String, dynamic> toMap() => {
        "userId": userId,
        "id": id,
        "title": title,
        "body": body,
      };
}
