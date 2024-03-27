import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myysree/models/status.dart';
import 'package:myysree/models/user.dart';
import 'package:myysree/utils/firebase.dart';
import 'package:myysree/view_models/status/status_view_model.dart';
import 'package:myysree/widgets/indicators.dart';
import 'package:story/story.dart';
import 'package:timeago/timeago.dart' as timeago;

class StatusScreen extends StatefulWidget {
  final initPage;
  final statusId;
  final storyId;
  final userId;

  const StatusScreen({
    Key? key,
    required this.initPage,
    required this.storyId,
    required this.statusId,
    required this.userId,
  }) : super(key: key);

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  @override
  Widget build(BuildContext context) {
    StatusViewModel viewModel = Provider.of<StatusViewModel>(context);
    return Scaffold(
      body: GestureDetector(
        onVerticalDragUpdate: (value) {
          Navigator.pop(context);
        },
        child: FutureBuilder<QuerySnapshot>(
          future: statusRef.doc(widget.statusId).collection('statuses').get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data == null) {
              return circularProgress(context);
            }

            List status = snapshot.data!.docs;
            return StoryPageView(
              indicatorPadding:
                  EdgeInsets.symmetric(vertical: 50.0, horizontal: 20.0),
              indicatorHeight: 15.0,
              initialPage: 0,
              onPageLimitReached: () {
                Navigator.pop(context);
              },
              indicatorVisitedColor: Theme.of(context).colorScheme.secondary,
              indicatorDuration: Duration(seconds: 30),
              itemBuilder: (context, pageIndex, storyIndex) {
                StatusModel stats = StatusModel.fromJson(
                  status[storyIndex].data(),
                );

                List<dynamic> allViewers = stats.viewers ?? [];

                if (allViewers.contains(firebaseAuth.currentUser!.uid)) {
                  print('ID ALREADY EXISTS');
                } else {
                  allViewers.add(firebaseAuth.currentUser!.uid);
                  statusRef
                      .doc(widget.statusId)
                      .collection('statuses')
                      .doc(stats.statusId)
                      .update({
                    'viewers': allViewers,
                    'createdAt': FieldValue
                        .serverTimestamp(), // Add this line to set the update time
                  });
                }

                return Container(
                  height: MediaQuery.of(context).size.height,
                  width: MediaQuery.of(context).size.width,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 50.0),
                          child: getImage(stats.url!),
                        ),
                      ),
                      Positioned(
                        top: 65.0,
                        left: 10.0,
                        child: FutureBuilder(
                          future: usersRef.doc(widget.userId).get(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData || snapshot.data == null) {
                              return const SizedBox();
                            }

                            DocumentSnapshot documentSnapshot =
                                snapshot.data as DocumentSnapshot<Object?>;
                            UserModel user = UserModel.fromJson(
                              documentSnapshot.data() as Map<String, dynamic>,
                            );

                            return Padding(
                              padding: const EdgeInsets.only(right: 10.0),
                              child: Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.transparent,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.3),
                                          offset: new Offset(0.0, 0.0),
                                          blurRadius: 2.0,
                                          spreadRadius: 0.0,
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(1.0),
                                      child: CircleAvatar(
                                        radius: 15.0,
                                        backgroundColor: Colors.grey,
                                        backgroundImage:
                                            CachedNetworkImageProvider(
                                          user.photoUrl!,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10.0),
                                  Column(
                                    children: [
                                      Text(
                                        user.username!,
                                        style: TextStyle(
                                          fontSize: 14.0,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        "${timeago.format(stats.time!.toDate())}",
                                        style: TextStyle(
                                          fontSize: 12.0,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        bottom: widget.userId == firebaseAuth.currentUser!.uid
                            ? 10.0
                            : 30.0,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              color: Colors.grey.withOpacity(0.2),
                              width: MediaQuery.of(context).size.width,
                              constraints: BoxConstraints(maxHeight: 50.0),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20.0,
                                      ),
                                      child: Text(
                                        stats.caption ?? '',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              color: Colors.black.withOpacity(0.5),
                              width: MediaQuery.of(context).size.width,
                              constraints: BoxConstraints(maxHeight: 50.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (widget.userId ==
                                      firebaseAuth.currentUser!.uid)
                                    TextButton.icon(
                                      onPressed: () {},
                                      icon: Icon(
                                        Icons.remove_red_eye_outlined,
                                        size: 20.0,
                                        color: Colors.white,
                                      ),
                                      label: Text(
                                        stats.viewers?.length.toString() ?? '0',
                                        style: TextStyle(
                                          fontSize: 12.0,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
              storyLength: (int pageIndex) {
                return status.length;
              },
              pageLength: 1,
            );
          },
        ),
      ),
    );
  }

  getImage(String url) {
    return AspectRatio(
      aspectRatio: 9 / 16,
      child: Image.network(url, fit: BoxFit.cover),
    );
  }
}
