import 'package:flutter/material.dart';
import 'package:glitcher/root_page.dart';
import 'package:glitcher/screens/about/about_us.dart';
import 'package:glitcher/screens/about/cookie_use.dart';
import 'package:glitcher/screens/about/help_center.dart';
import 'package:glitcher/screens/about/legal_notices.dart';
import 'package:glitcher/screens/about/privacy_policy.dart';
import 'package:glitcher/screens/about/terms_of_service.dart';
import 'package:glitcher/screens/app_page.dart';
import 'package:glitcher/screens/chats/add_members_to_group.dart';
import 'package:glitcher/screens/chats/chats.dart';
import 'package:glitcher/screens/chats/conversation.dart';
import 'package:glitcher/screens/chats/group_conversation.dart';
import 'package:glitcher/screens/chats/group_members.dart';
import 'package:glitcher/screens/chats/new_group.dart';
import 'package:glitcher/screens/chats/group_details.dart';
import 'package:glitcher/screens/games/game_screen.dart';
import 'package:glitcher/screens/games/new_game.dart';
import 'package:glitcher/screens/posts/add_comment.dart';
import 'package:glitcher/screens/posts/post_preview.dart';
import 'package:glitcher/screens/posts/new_post.dart';
import 'package:glitcher/screens/user_timeline/profile_screen.dart';
import 'package:page_transition/page_transition.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Getting arguments passed in while calling Navigator.pushNamed
    final Map args = settings.arguments as Map;

    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => RootPage());

      case '/home':
        return MaterialPageRoute(builder: (_) => AppPage());

      case '/new-post':
        return MaterialPageRoute(builder: (_) => NewPost());

      case '/user-profile':
        return MaterialPageRoute(
          builder: (_) => ProfileScreen(
            args['userId'],
          ),
        );

      case '/post':
        // Validation of correct data type
        return PageTransition(
            child: PostPreview(
              postId: args['postId'],
            ),
            type: PageTransitionType.scale);
        // If args is not of the correct type, return an error page.
        // You can also throw an exception while in development.
        return _errorRoute();

      case '/add-comment':
        // Validation of correct data type
        return MaterialPageRoute(
          builder: (_) => AddCommentScreen(
            username: args['username'],
            userId: args['userId'],
            postId: args['postId'],
            profileImageUrl: args['profileImageUrl'],
          ),
        );

      case '/game-screen':
        return MaterialPageRoute(
          builder: (_) => GameScreen(
            game: args['game'],
          ),
        );

      case '/new-game':
        return MaterialPageRoute(builder: (_) => NewGame());

      case '/conversation':
        return MaterialPageRoute(
            builder: (_) => Conversation(
                  otherUid: args['otherUid'],
                ));

      case '/group-conversation':
        return MaterialPageRoute(
            builder: (_) => GroupConversation(
                  groupId: args['groupId'],
                ));

      case '/group-members':
        return MaterialPageRoute(
            builder: (_) => GroupMembers(
                  groupId: args['groupId'],
                ));

      case '/add-members-to-group':
        return MaterialPageRoute(
            builder: (_) => AddMembersToGroup(
                  args['groupId'],
                ));

      case '/new-group':
        return MaterialPageRoute(builder: (_) => NewGroup());

      case '/group-details':
        return MaterialPageRoute(builder: (_) => GroupDetails(args['groupId']));

      case '/chats':
        return MaterialPageRoute(builder: (_) => Chats());

      case '/about-us':
        return MaterialPageRoute(builder: (_) => AboutUs());
      case '/cookie-use':
        return MaterialPageRoute(builder: (_) => CookieUse());
      case '/help-center':
        return MaterialPageRoute(builder: (_) => HelpCenter());
      case '/legal-notices':
        return MaterialPageRoute(builder: (_) => LegalNotices());
      case '/terms-of-service':
        return MaterialPageRoute(builder: (_) => TermsOfService());
      case '/privacy-policy':
        return MaterialPageRoute(builder: (_) => PrivacyPolicy());

      default:
        // If there is no such named route in the switch statement, e.g. /third
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(builder: (_) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Error'),
        ),
        body: Center(
          child: Text('ERROR'),
        ),
      );
    });
  }
}
