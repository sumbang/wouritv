// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get app_title => 'Welcome to Wouri TV';

  @override
  String get app_description => 'Access a catalog of varied Cameroonian and African films and series, watch online or download the content to read offline, watch on all your media (Smartphone, Tablet, Television, PC ....) and well Moreover...';

  @override
  String get home_bt => 'Get Started';

  @override
  String get connexion_title => 'Login';

  @override
  String get inscription_title => 'Sign Up';

  @override
  String get email_label => 'Email';

  @override
  String get password_label => 'Password';

  @override
  String get forgot_password => 'Forgot password?';

  @override
  String get login_button => 'Login';

  @override
  String get signup_button => 'Sign Up';

  @override
  String get or_continue_with => 'Or continue with';

  @override
  String get google_button => 'Google';

  @override
  String get facebook_button => 'Facebook';

  @override
  String get already_have_account => 'Already have an account? Login';

  @override
  String get no_account => 'No account? Sign Up';

  @override
  String get email_required => 'Please enter your email';

  @override
  String get email_invalid => 'Invalid email';

  @override
  String get password_required => 'Please enter your password';

  @override
  String get password_min_length => 'Password must contain at least 6 characters';

  @override
  String get signup_success => 'Registration successful! Check your email.';

  @override
  String get reset_password_success => 'Password reset email sent!';

  @override
  String error_google(Object error) {
    return 'Google error: $error';
  }

  @override
  String error_facebook(Object error) {
    return 'Facebook error: $error';
  }

  @override
  String error_general(Object error) {
    return 'Error: $error';
  }

  @override
  String get enter_email_first => 'Please enter your email';

  @override
  String get google_signin_progress => 'Google login in progress...';

  @override
  String get facebook_signin_progress => 'Facebook login in progress...';

  @override
  String get fullname_label => 'Full name';

  @override
  String get fullname_required => 'FullName is required';

  @override
  String get app_subtitle => 'The Crossroads of African Cinemas';

  @override
  String welcome_message(String name) {
    return 'Welcome $name';
  }

  @override
  String get nav_home => 'Home';

  @override
  String get nav_search => 'Search';

  @override
  String get nav_my_list => 'My List';

  @override
  String get nav_profile => 'Profile';

  @override
  String get popular_movies => 'Popular Movies';

  @override
  String get popular_series => 'Popular Series';

  @override
  String get new_releases => 'New Releases';

  @override
  String get latest_additions => 'Latest Additions';

  @override
  String get recommended_for_you => 'Recommended for You';

  @override
  String get see_all => 'See All';

  @override
  String get search_title => 'Search';

  @override
  String get search_hint => 'Search movies, series...';

  @override
  String get search_empty => 'No results found';

  @override
  String get search_prompt => 'Start searching for your favorite content';

  @override
  String get my_list_title => 'My Watchlist';

  @override
  String get my_list_description => 'Your favorite movies and series';

  @override
  String get profile_title => 'Profile';

  @override
  String get account_settings => 'Account Settings';

  @override
  String get logout => 'Logout';

  @override
  String get logout_confirm => 'Are you sure you want to sign out?';

  @override
  String get no_movie => 'No movie available';

  @override
  String get no_title => 'No title';

  @override
  String get free => 'Free';

  @override
  String get premium => 'Premium';

  @override
  String get episode => 'Episodes';

  @override
  String get look => 'Watch';

  @override
  String get connexion_required_liste => 'You need to be connected to continue';

  @override
  String get liste_remove => 'Movie deleted from your list';

  @override
  String get liste_add => 'Movie added to your list';

  @override
  String get recommand_add => 'Recommendation added';

  @override
  String get recommand_delete => 'Recommendation deleted';

  @override
  String get suggestion => 'This might interest you';

  @override
  String get no_suggestion => 'No suggestion';

  @override
  String get resume_reading => 'Resume reading';

  @override
  String get resume_reading_question => 'Do you want to continue where you left off or start from the beginning?';

  @override
  String get from_beginning => 'From beginning';

  @override
  String get continue_watching => 'Continue';

  @override
  String get show_less => 'Show less';

  @override
  String get show_more => 'Show more';

  @override
  String get remaining => 'remaining';

  @override
  String get profil_ok => 'Profile updated successfully!';

  @override
  String get pwd_new => 'New password';

  @override
  String get bt_cancel => 'Cancel';

  @override
  String get bt_confirm => 'Confirm';

  @override
  String get pwd_update => 'Password updated!';

  @override
  String get logout_desc => 'Are you sure you want to log out?';

  @override
  String get bt_logout => 'Log out';

  @override
  String get txt_email => 'Email';

  @override
  String get txt_user => 'User ID';

  @override
  String get txt_perso => 'Personal Information';

  @override
  String get txt_nom => 'Name';

  @override
  String get txt_phone => 'Phone';

  @override
  String get profile_update => 'Update Profile';

  @override
  String get txt_pwd => 'Change Password';

  @override
  String get txt_cpte => 'Account Information';

  @override
  String get txt_create => 'Created on';

  @override
  String get app_version => 'Apps version';

  @override
  String get apple_button => 'Apple';

  @override
  String get apple_signin_progress => 'Apple login in progress...';

  @override
  String error_apple(Object error) {
    return 'Apple error: $error';
  }
}
