import 'dart:typed_data';

import 'package:audiofileplayer/audiofileplayer.dart';
import 'package:chewie/chewie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:glitcher/constants/constants.dart';
import 'package:glitcher/constants/my_colors.dart';
import 'package:glitcher/constants/sizes.dart';
import 'package:glitcher/constants/strings.dart';
import 'package:glitcher/models/game_model.dart';
import 'package:glitcher/models/hashtag_model.dart';
import 'package:glitcher/models/post_model.dart';
import 'package:glitcher/models/user_model.dart';
import 'package:glitcher/screens/home/home_screen.dart';
import 'package:glitcher/services/database_service.dart';
import 'package:glitcher/services/notification_handler.dart';
import 'package:glitcher/services/share_link.dart';
import 'package:glitcher/utils/functions.dart';
import 'package:glitcher/widgets/caching_image.dart';
import 'package:glitcher/widgets/custom_url_text.dart';
import 'package:glitcher/widgets/image_overlay.dart';
import 'package:glitcher/widgets/post_bottom_sheet.dart';
import 'package:share/share.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class PostItem extends StatefulWidget {
  final Post post;
  final User author;
  final String route;

  PostItem(
      {Key key,
      @required this.post,
      @required this.author,
      this.route})
      : super(key: key);
  @override
  _PostItemState createState() => _PostItemState();
}

class _PostItemState extends State<PostItem> {
  /// On-the-fly audio data for the second card.
  int _spawnedAudioCount = 0;
  ByteData _likeSFX;
  ByteData _dislikeSFX;
  YoutubePlayerController _youtubeController;
  bool _isPlaying;
  VideoPlayerController videoPlayerController;
  ChewieController chewieController;
  Chewie playerWidget;
  String dropdownValue = 'Edit';

  bool isLiked = false;
  bool isLikeEnabled = true;
  bool isDisliked = false;
  bool isDislikedEnabled = true;
  var likes = [];
  var dislikes = [];

  String firstHalf;
  String secondHalf;
  bool flag = true;
  Game currentGame;
  final number = ValueNotifier(0);

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5),
      child: _buildPost(widget.post, widget.author, widget.route),
    );
  }

  _buildPost(Post post, User author, String route) {
    initLikes(post);
    return Column(
      children: <Widget>[
        GestureDetector(
          onTap: () {
            Navigator.of(context).pushNamed('/post', arguments: {
              'post': post,
            });
          },
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.fromLTRB(8.0, 0.0, 8.0, 0.0),
                leading: InkWell(
                    child: CacheThisImage(
                      imageUrl: author.profileImageUrl,
                      imageShape: BoxShape.circle,
                      width: Sizes.md_profile_image_w,
                      height: Sizes.md_profile_image_h,
                      defaultAssetImage: Strings.default_profile_image,
                    ),
                    onTap: () {
                      Navigator.of(context)
                          .pushNamed('/user-profile', arguments: {
                        'userId': post.authorId,
                      });
                    }),
                title: Row(
                  children: <Widget>[
                    InkWell(
                      child: Text('@${author.username}' ?? '',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: MyColors.darkPrimary)),
                      onTap: () {
                        Navigator.of(context)
                            .pushNamed('/user-profile', arguments: {
                          'userId': author.id,
                        });
                      },
                    ),
                  ],
                ),
                subtitle: InkWell(
                  child: Text('↳ ${post.game}' ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: MyColors.darkGrey,
                      )),
                  onTap: () {
                    print('currentGame : ${currentGame.id}');
                    Navigator.of(context).pushNamed('/game-screen', arguments: {
                      'game': currentGame,
                    });
                  },
                ),
                trailing: ValueListenableBuilder<int>(
                  valueListenable: number,
                  builder: (context, value, child) {
                    return PostBottomSheet()
                        .postOptionIcon(context, post, route);
                  },
                ),
              ),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          secondHalf.isEmpty
                              ? UrlText(
                                  context: context,
                                  text: post.text,
                                  onMentionPressed: (text) =>
                                      mentionedUserProfile(post.text),
                                  onHashTagPressed: (text) =>
                                      hashtagScreen(post.text),
                                  style: TextStyle(
                                    color:
                                        switchColor(Colors.black, Colors.white),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  urlStyle: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w400),
                                )
                              : UrlText(
                                  context: context,
                                  text: flag
                                      ? (firstHalf + '...')
                                      : (firstHalf + secondHalf),
                                  onMentionPressed: (text) =>
                                      mentionedUserProfile(post.text),
                                  onHashTagPressed: (text) =>
                                      hashtagScreen(post.text),
                                  style: TextStyle(
                                    color:
                                        switchColor(Colors.black, Colors.white),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  urlStyle: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w400),
                                ),
                          InkWell(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: <Widget>[
                                secondHalf.isEmpty
                                    ? Text('')
                                    : Text(
                                        flag ? 'Show more' : 'Show less',
                                        style: TextStyle(
                                            color: MyColors.darkPrimary),
                                      )
                              ],
                            ),
                            onTap: () {
                              setState(() {
                                flag = !flag;
                              });
                            },
                          ),
                          SizedBox(
                            height: 8.0,
                          ),
                          Container(
                            child: post.imageUrl == null
                                ? null
                                : Container(
                                    width: Sizes.home_post_image_w,
                                    height: Sizes.home_post_image_h,
                                    child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                        child: InkWell(
                                            onTap: () {
                                              showDialog(
                                                  barrierDismissible: true,
                                                  child: Container(
                                                    width: Sizes
                                                        .sm_profile_image_w,
                                                    height: Sizes
                                                        .sm_profile_image_h,
                                                    child: ImageOverlay(
                                                      imageUrl: post.imageUrl,
                                                      btnText:
                                                          Strings.SAVE_IMAGE,
                                                      btnFunction: () {},
                                                    ),
                                                  ),
                                                  context: context);
                                            },
                                            child: CacheThisImage(
                                              imageUrl: post.imageUrl,
                                              imageShape: BoxShape.rectangle,
                                              width: Sizes.home_post_image_w,
                                              height: Sizes.home_post_image_h,
                                              defaultAssetImage:
                                                  Strings.default_post_image,
                                            ))),
                                  ),
                          ),
                          Container(
                            child: post.video == null ? null : playerWidget,
                          ),
                          Container(
                            child:
                                //TODO: Fix YouTube Player
                                post.youtubeId == null
                                    ? null
                                    : YoutubePlayerBuilder(
                                        onExitFullScreen: () {
                                          SystemChrome.setPreferredOrientations(
                                              DeviceOrientation.values);
                                        },
                                        player: YoutubePlayer(
                                          controller: _youtubeController,
                                          showVideoProgressIndicator: true,
                                          bottomActions: [
                                            CurrentPosition(),
                                            ProgressBar(isExpanded: true),
                                            RemainingDuration(),
                                            //FullScreenButton()
                                          ],
                                        ),
                                        builder: (context, player) => player),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              "${Functions.formatTimestamp(post.timestamp)}",
                              style: TextStyle(
                                  fontSize: 13.0,
                                  color: switchColor(
                                      MyColors.darkGrey, Colors.white70)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  width: double.infinity,
                  height: .5,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 1.0,
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
                color: Constants.currentTheme == AvailableThemes.LIGHT_THEME
                    ? MyColors.lightLineBreak
                    : MyColors.darkLineBreak),
          ),
        ),
        Container(
          height: Sizes.inline_break,
          color: Constants.currentTheme == AvailableThemes.LIGHT_THEME
              ? MyColors.lightCardBG
              : MyColors.darkCardBG,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              InkWell(
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      child: isLiked
                          ? Icon(
                              FontAwesome.getIconData('thumbs-up'),
                              size: Sizes.card_btn_size,
                              color: MyColors.darkPrimary,
                            )
                          : Icon(
                              FontAwesome.getIconData('thumbs-o-up'),
                              size: Sizes.card_btn_size,
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 16.0),
                      child: Text(
                        post.likesCount.toString(),
                      ),
                    ),
                  ],
                ),
                onTap: () async {
                  if (isLikeEnabled) {
                    _likeSFX == null
                        ? null
                        : Audio.loadFromByteData(_likeSFX,
                            onComplete: () =>
                                setState(() => --_spawnedAudioCount))
                      ..play()
                      ..dispose();
                    setState(() => ++_spawnedAudioCount);
                    await likeBtnHandler(post);
                  }
                },
              ),
              SizedBox(
                width: 1.0,
                height: Sizes.inline_break,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                      color:
                          Constants.currentTheme == AvailableThemes.LIGHT_THEME
                              ? MyColors.lightInLineBreak
                              : MyColors.darkLineBreak),
                ),
              ),
              InkWell(
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      child: isDisliked
                          ? Icon(
                              FontAwesome.getIconData('thumbs-down'),
                              size: Sizes.card_btn_size,
                              color: MyColors.darkPrimary,
                            )
                          : Icon(
                              FontAwesome.getIconData('thumbs-o-down'),
                              size: Sizes.card_btn_size,
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 16.0),
                      child: Text(
                        post.disLikesCount.toString(),
                      ),
                    ),
                  ],
                ),
                onTap: () async {
                  if (isDislikedEnabled) {
                    _dislikeSFX == null
                        ? null
                        : Audio.loadFromByteData(_dislikeSFX,
                            onComplete: () =>
                                setState(() => --_spawnedAudioCount))
                      ..play()
                      ..dispose();
                    setState(() => ++_spawnedAudioCount);
                    await dislikeBtnHandler(post);
                  }
                },
              ),
              SizedBox(
                width: 1.0,
                height: Sizes.inline_break,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                      color:
                          Constants.currentTheme == AvailableThemes.LIGHT_THEME
                              ? MyColors.lightInLineBreak
                              : MyColors.darkLineBreak),
                ),
              ),
              InkWell(
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      child: Icon(
                        Icons.chat_bubble_outline,
                        size: Sizes.card_btn_size,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 16.0),
                      child: Text(
                        post.commentsCount.toString(),
                      ),
                    ),
                  ],
                ),
                onTap: () {
//                    Navigator.of(context).pushNamed('/post', arguments: {
//                      'post': post,
//                      'commentsNo': post.commentsCount
//                    });
                  Navigator.of(context).pushNamed('/add-comment', arguments: {
                    'post': post,
                    'user': author,
                  });
                },
              ),
              SizedBox(
                width: 1.0,
                height: Sizes.inline_break,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                      color:
                          Constants.currentTheme == AvailableThemes.LIGHT_THEME
                              ? MyColors.lightInLineBreak
                              : MyColors.darkLineBreak),
                ),
              ),
              InkWell(
                child: SizedBox(
                  child: Icon(
                    Icons.share,
                    size: Sizes.card_btn_size,
                  ),
                ),
                onTap: () async {
                  await sharePost(post.id, post.text, post.imageUrl);
                },
              ),
            ],
          ),
        ),
        SizedBox(
          height: 14.0,
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
                color: Constants.currentTheme == AvailableThemes.LIGHT_THEME
                    ? MyColors.lightLineBreak
                    : MyColors.darkLineBreak),
          ),
        ),
      ],
    );
  }

  // Sharing a post with a shortened url
  sharePost(String postId, String postText, String imageUrl) async {
    var postLink = await DynamicLinks.createDynamicLink(
        {'postId': postId, 'postText': postText, 'imageUrl': imageUrl});
    Share.share('Check out: $postText : $postLink');
    print('Check out: $postText : $postLink');
  }

  void _loadAudioByteData() async {
    _likeSFX = await rootBundle.load(Strings.like_sound);
    _dislikeSFX = await rootBundle.load(Strings.dislike_sound);
  }

  // Youtube Video listener
  void listener() {
//    if (_youtubeController.value.playerState == PlayerState.ENDED) {
//      //_showThankYouDialog();
//    }
    if (mounted) {
//      setState(() {
//        //_playerStatus = _youtubeController.value.playerState.toString();
//        //_errorCode = _youtubeController.value.errorCode.toString();
//      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    _loadAudioByteData();
    super.initState();

    _youtubeController = YoutubePlayerController(
      initialVideoId: widget.post.youtubeId ?? '',
      flags: YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
      ),
    );

    setCurrentGame();
    if (widget.post.text.length > Sizes.postExcerpt) {
      firstHalf = widget.post.text.substring(0, Sizes.postExcerpt);
      secondHalf = widget.post.text
          .substring(Sizes.postExcerpt, widget.post.text.length);
    } else {
      firstHalf = widget.post.text;
      secondHalf = "";
    }
  }

  Future<void> likeBtnHandler(Post post) async {
    setState(() {
      isLikeEnabled = false;
    });
    if (isLiked == true && isDisliked == false) {
      await postsRef
          .document(post.id)
          .collection('likes')
          .document(Constants.currentUserID)
          .delete();
      await postsRef
          .document(post.id)
          .updateData({'likes': FieldValue.increment(-1)});
      setState(() {
        isLiked = false;
        //post.likesCount = likesNo;
      });
    } else if (isDisliked == true && isLiked == false) {
      await postsRef
          .document(post.id)
          .collection('dislikes')
          .document(Constants.currentUserID)
          .delete();
      await postsRef
          .document(post.id)
          .updateData({'dislikes': FieldValue.increment(-1)});

      setState(() {
        isDisliked = false;
        //post.disLikesCount = dislikesNo;
      });
      await postsRef
          .document(post.id)
          .collection('likes')
          .document(Constants.currentUserID)
          .setData({'timestamp': FieldValue.serverTimestamp()});
      await postsRef
          .document(post.id)
          .updateData({'likes': FieldValue.increment(1)});

      setState(() {
        isLiked = true;
        //post.likesCount = likesNo;
      });

      await NotificationHandler.sendNotification(
          post.authorId,
          'New Post Like',
          Constants.loggedInUser.username + ' likes your post',
          post.id,
          'like');
    } else if (isLiked == false && isDisliked == false) {
      await postsRef
          .document(post.id)
          .collection('likes')
          .document(Constants.currentUserID)
          .setData({'timestamp': FieldValue.serverTimestamp()});
      await postsRef
          .document(post.id)
          .updateData({'likes': FieldValue.increment(1)});
      setState(() {
        isLiked = true;
        //post.likesCount = likesNo;
      });

      await NotificationHandler.sendNotification(
          post.authorId,
          'New Post Like',
          Constants.loggedInUser.username + ' likes your post',
          post.id,
          'like');
    } else {
      throw Exception('Unconditional Event Occurred!');
    }
    var postMeta = await DatabaseService.getPostMeta(post.id);
    setState(() {
      post.likesCount = postMeta['likes'];
      post.disLikesCount = postMeta['dislikes'];
      isLikeEnabled = true;
    });

    print(
        'likes = ${postMeta['likes']} and dislikes = ${postMeta['dislikes']}');
  }

  Future<void> dislikeBtnHandler(Post post) async {
    setState(() {
      isDislikedEnabled = false;
    });
    if (isDisliked == true && isLiked == false) {
      await postsRef
          .document(post.id)
          .collection('dislikes')
          .document(Constants.currentUserID)
          .delete();
      await postsRef
          .document(post.id)
          .updateData({'dislikes': FieldValue.increment(-1)});
      setState(() {
        isDisliked = false;
        //post.disLikesCount = dislikesNo;
      });
    } else if (isLiked == true && isDisliked == false) {
      await postsRef
          .document(post.id)
          .collection('likes')
          .document(Constants.currentUserID)
          .delete();
      await postsRef
          .document(post.id)
          .updateData({'likes': FieldValue.increment(-1)});
      setState(() {
        isLiked = false;
        //post.likesCount = likesNo;
      });
      await postsRef
          .document(post.id)
          .collection('dislikes')
          .document(Constants.currentUserID)
          .setData({'timestamp': FieldValue.serverTimestamp()});
      await postsRef
          .document(post.id)
          .updateData({'dislikes': FieldValue.increment(1)});

      setState(() {
        isDisliked = true;
        //post.disLikesCount = dislikesNo;
      });
    } else if (isDisliked == false && isLiked == false) {
      await postsRef
          .document(post.id)
          .collection('dislikes')
          .document(Constants.currentUserID)
          .setData({'timestamp': FieldValue.serverTimestamp()});
      await postsRef
          .document(post.id)
          .updateData({'dislikes': FieldValue.increment(1)});

      setState(() {
        isDisliked = true;
        //post.disLikesCount = dislikesNo;
      });
    } else {
      throw Exception('Unconditional Event Occurred.');
    }

    var postMeta = await DatabaseService.getPostMeta(post.id);

    setState(() {
      post.likesCount = postMeta['likes'];
      post.disLikesCount = postMeta['dislikes'];
      isDislikedEnabled = true;
    });

    print(
        'likes = ${postMeta['likes']} and dislikes = ${postMeta['dislikes']}');
  }

  void initLikes(Post post) async {
    DocumentSnapshot likedSnapshot = await postsRef
        .document(post.id)
        .collection('likes')
        ?.document(Constants.currentUserID)
        ?.get();
    DocumentSnapshot dislikedSnapshot = await postsRef
        .document(post.id)
        .collection('dislikes')
        ?.document(Constants.currentUserID)
        ?.get();
    //Solves the problem setState() called after dispose()
    if (mounted) {
      setState(() {
        isLiked = likedSnapshot.exists;
        isDisliked = dislikedSnapshot.exists;
      });
    }
  }

  Widget dropDownBtn() {
    if (Constants.currentUserID == widget.post.authorId) {
      return specialBtns();
    }
    return Container();
  }

  Widget specialBtns() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8.0, 0, 0, 16.0),
      child: Row(
        children: <Widget>[
          InkWell(
              child: Icon(
                Icons.report_problem,
                size: 22.0,
                color: MyColors.darkAccent,
              ),
              onTap: () {}),
          InkWell(
              child: Icon(
                Icons.delete_forever,
                size: 22.0,
                color: MyColors.darkAccent,
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: new AlertDialog(
                      title: new Text('Are you sure?'),
                      content:
                          new Text('Do you really want to delete this post?'),
                      actions: <Widget>[
                        new GestureDetector(
                          onTap: () => Navigator.of(context).pop(false),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text("NO"),
                          ),
                        ),
                        SizedBox(height: 16),
                        new GestureDetector(
                          onTap: () {
                            DatabaseService.deletePost(this.widget.post.id);
                            (context as Element).rebuild();
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text("YES"),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          InkWell(
              child: Icon(
                Icons.edit,
                size: 22.0,
                color: MyColors.darkAccent,
              ),
              onTap: () {}),
        ],
      ),
    );
  }

  Future mentionedUserProfile(String w) async {
    var words = w.split(' ');
    String username =
        words.length > 0 && words[words.length - 1].startsWith('@')
            ? words[words.length - 1]
            : '';
    if (username.length > 1) username = username.substring(1);
    print(username);
    User user = await DatabaseService.getUserWithUsername(username);
    Navigator.of(context)
        .pushNamed('/user-profile', arguments: {'userId': user.id});
    print(user.id);
  }

  Future hashtagScreen(String w) async {
    var words = w.split(' ');
    String hashtagText =
        words.length > 0 && words[words.length - 1].startsWith('#')
            ? words[words.length - 1]
            : '';
    print(hashtagText);
    Hashtag hashtag = await DatabaseService.getHashtagWithText(hashtagText);
    Navigator.of(context)
        .pushNamed('/hashtag-posts', arguments: {'hashtag': hashtag});
    print(hashtag.id);
  }

  dropDownOptions() {
    if (HomeScreen.isBottomSheetVisible) {
      Navigator.pop(context);
    } else {
      HomeScreen.showMyBottomSheet(context);
    }

    setState(() {
      HomeScreen.isBottomSheetVisible = !HomeScreen.isBottomSheetVisible;
    });
  }

  void onLongPressedPost(BuildContext context, String postText) {
    var text = ClipboardData(text: postText);
    Clipboard.setData(text);
    Scaffold.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.black,
        content: Text(
          'Post copied to clipboard',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  void setCurrentGame() async {
    currentGame = await DatabaseService.getGameWithGameName(widget.post.game);
  }
}
