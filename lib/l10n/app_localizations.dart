import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr')
  ];

  /// No description provided for @app_title.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Wouri TV'**
  String get app_title;

  /// No description provided for @app_description.
  ///
  /// In en, this message translates to:
  /// **'Access a catalog of varied Cameroonian and African films and series, watch online or download the content to read offline, watch on all your media (Smartphone, Tablet, Television, PC ....) and well Moreover...'**
  String get app_description;

  /// No description provided for @home_bt.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get home_bt;

  /// No description provided for @connexion_title.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get connexion_title;

  /// No description provided for @inscription_title.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get inscription_title;

  /// No description provided for @email_label.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email_label;

  /// No description provided for @password_label.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password_label;

  /// No description provided for @forgot_password.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgot_password;

  /// No description provided for @login_button.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login_button;

  /// No description provided for @signup_button.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signup_button;

  /// No description provided for @or_continue_with.
  ///
  /// In en, this message translates to:
  /// **'Or continue with'**
  String get or_continue_with;

  /// No description provided for @google_button.
  ///
  /// In en, this message translates to:
  /// **'Google'**
  String get google_button;

  /// No description provided for @facebook_button.
  ///
  /// In en, this message translates to:
  /// **'Facebook'**
  String get facebook_button;

  /// No description provided for @already_have_account.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Login'**
  String get already_have_account;

  /// No description provided for @no_account.
  ///
  /// In en, this message translates to:
  /// **'No account? Sign Up'**
  String get no_account;

  /// No description provided for @email_required.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get email_required;

  /// No description provided for @email_invalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get email_invalid;

  /// No description provided for @password_required.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get password_required;

  /// No description provided for @password_min_length.
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least 6 characters'**
  String get password_min_length;

  /// No description provided for @signup_success.
  ///
  /// In en, this message translates to:
  /// **'Registration successful! Check your email.'**
  String get signup_success;

  /// No description provided for @reset_password_success.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent!'**
  String get reset_password_success;

  /// No description provided for @error_google.
  ///
  /// In en, this message translates to:
  /// **'Google error: {error}'**
  String error_google(Object error);

  /// No description provided for @error_facebook.
  ///
  /// In en, this message translates to:
  /// **'Facebook error: {error}'**
  String error_facebook(Object error);

  /// No description provided for @error_general.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String error_general(Object error);

  /// No description provided for @enter_email_first.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get enter_email_first;

  /// No description provided for @google_signin_progress.
  ///
  /// In en, this message translates to:
  /// **'Google login in progress...'**
  String get google_signin_progress;

  /// No description provided for @facebook_signin_progress.
  ///
  /// In en, this message translates to:
  /// **'Facebook login in progress...'**
  String get facebook_signin_progress;

  /// No description provided for @fullname_label.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullname_label;

  /// No description provided for @fullname_required.
  ///
  /// In en, this message translates to:
  /// **'FullName is required'**
  String get fullname_required;

  /// No description provided for @app_subtitle.
  ///
  /// In en, this message translates to:
  /// **'The Crossroads of African Cinemas'**
  String get app_subtitle;

  /// No description provided for @welcome_message.
  ///
  /// In en, this message translates to:
  /// **'Welcome {name}'**
  String welcome_message(String name);

  /// No description provided for @nav_home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get nav_home;

  /// No description provided for @nav_search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get nav_search;

  /// No description provided for @nav_my_list.
  ///
  /// In en, this message translates to:
  /// **'My List'**
  String get nav_my_list;

  /// No description provided for @nav_profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get nav_profile;

  /// No description provided for @popular_movies.
  ///
  /// In en, this message translates to:
  /// **'Popular Movies'**
  String get popular_movies;

  /// No description provided for @popular_series.
  ///
  /// In en, this message translates to:
  /// **'Popular Series'**
  String get popular_series;

  /// No description provided for @new_releases.
  ///
  /// In en, this message translates to:
  /// **'New Releases'**
  String get new_releases;

  /// No description provided for @latest_additions.
  ///
  /// In en, this message translates to:
  /// **'Latest Additions'**
  String get latest_additions;

  /// No description provided for @recommended_for_you.
  ///
  /// In en, this message translates to:
  /// **'Recommended for You'**
  String get recommended_for_you;

  /// No description provided for @see_all.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get see_all;

  /// No description provided for @search_title.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search_title;

  /// No description provided for @search_hint.
  ///
  /// In en, this message translates to:
  /// **'Search movies, series...'**
  String get search_hint;

  /// No description provided for @search_empty.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get search_empty;

  /// No description provided for @search_prompt.
  ///
  /// In en, this message translates to:
  /// **'Start searching for your favorite content'**
  String get search_prompt;

  /// No description provided for @my_list_title.
  ///
  /// In en, this message translates to:
  /// **'My Watchlist'**
  String get my_list_title;

  /// No description provided for @my_list_description.
  ///
  /// In en, this message translates to:
  /// **'Your favorite movies and series'**
  String get my_list_description;

  /// No description provided for @profile_title.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile_title;

  /// No description provided for @account_settings.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get account_settings;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logout_confirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get logout_confirm;

  /// No description provided for @no_movie.
  ///
  /// In en, this message translates to:
  /// **'No movie available'**
  String get no_movie;

  /// No description provided for @no_title.
  ///
  /// In en, this message translates to:
  /// **'No title'**
  String get no_title;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// No description provided for @premium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premium;

  /// No description provided for @episode.
  ///
  /// In en, this message translates to:
  /// **'Episodes'**
  String get episode;

  /// No description provided for @look.
  ///
  /// In en, this message translates to:
  /// **'Watch'**
  String get look;

  /// No description provided for @connexion_required_liste.
  ///
  /// In en, this message translates to:
  /// **'You need to be connected to continue'**
  String get connexion_required_liste;

  /// No description provided for @liste_remove.
  ///
  /// In en, this message translates to:
  /// **'Movie deleted from your list'**
  String get liste_remove;

  /// No description provided for @liste_add.
  ///
  /// In en, this message translates to:
  /// **'Movie added to your list'**
  String get liste_add;

  /// No description provided for @recommand_add.
  ///
  /// In en, this message translates to:
  /// **'Recommendation added'**
  String get recommand_add;

  /// No description provided for @recommand_delete.
  ///
  /// In en, this message translates to:
  /// **'Recommendation deleted'**
  String get recommand_delete;

  /// No description provided for @suggestion.
  ///
  /// In en, this message translates to:
  /// **'This might interest you'**
  String get suggestion;

  /// No description provided for @no_suggestion.
  ///
  /// In en, this message translates to:
  /// **'No suggestion'**
  String get no_suggestion;

  /// No description provided for @resume_reading.
  ///
  /// In en, this message translates to:
  /// **'Resume reading'**
  String get resume_reading;

  /// No description provided for @resume_reading_question.
  ///
  /// In en, this message translates to:
  /// **'Do you want to continue where you left off or start from the beginning?'**
  String get resume_reading_question;

  /// No description provided for @from_beginning.
  ///
  /// In en, this message translates to:
  /// **'From beginning'**
  String get from_beginning;

  /// No description provided for @continue_watching.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continue_watching;

  /// No description provided for @show_less.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get show_less;

  /// No description provided for @show_more.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get show_more;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'remaining'**
  String get remaining;

  /// No description provided for @profil_ok.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully!'**
  String get profil_ok;

  /// No description provided for @pwd_new.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get pwd_new;

  /// No description provided for @bt_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get bt_cancel;

  /// No description provided for @bt_confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get bt_confirm;

  /// No description provided for @pwd_update.
  ///
  /// In en, this message translates to:
  /// **'Password updated!'**
  String get pwd_update;

  /// No description provided for @logout_desc.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logout_desc;

  /// No description provided for @bt_logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get bt_logout;

  /// No description provided for @txt_email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get txt_email;

  /// No description provided for @txt_user.
  ///
  /// In en, this message translates to:
  /// **'User ID'**
  String get txt_user;

  /// No description provided for @txt_perso.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get txt_perso;

  /// No description provided for @txt_nom.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get txt_nom;

  /// No description provided for @txt_phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get txt_phone;

  /// No description provided for @profile_update.
  ///
  /// In en, this message translates to:
  /// **'Update Profile'**
  String get profile_update;

  /// No description provided for @txt_pwd.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get txt_pwd;

  /// No description provided for @txt_cpte.
  ///
  /// In en, this message translates to:
  /// **'Account Information'**
  String get txt_cpte;

  /// No description provided for @txt_create.
  ///
  /// In en, this message translates to:
  /// **'Created on'**
  String get txt_create;

  /// No description provided for @app_version.
  ///
  /// In en, this message translates to:
  /// **'Apps version'**
  String get app_version;

  /// No description provided for @apple_button.
  ///
  /// In en, this message translates to:
  /// **'Apple'**
  String get apple_button;

  /// No description provided for @apple_signin_progress.
  ///
  /// In en, this message translates to:
  /// **'Apple login in progress...'**
  String get apple_signin_progress;

  /// No description provided for @error_apple.
  ///
  /// In en, this message translates to:
  /// **'Apple error: {error}'**
  String error_apple(Object error);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'fr': return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
