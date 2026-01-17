import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_mr.dart';

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
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('mr'),
  ];

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Smart Farming\nFor a Better Future'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'AI-powered insights for optimal crop growth and yield.'**
  String get welcomeSubtitle;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get login;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @helloAgain.
  ///
  /// In en, this message translates to:
  /// **'Hello Again!'**
  String get helloAgain;

  /// No description provided for @joinRevolution.
  ///
  /// In en, this message translates to:
  /// **'Join the smart farming revolution'**
  String get joinRevolution;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back, you\'ve been missed!'**
  String get welcomeBack;

  /// No description provided for @farmer.
  ///
  /// In en, this message translates to:
  /// **'Farmer'**
  String get farmer;

  /// No description provided for @agriOfficer.
  ///
  /// In en, this message translates to:
  /// **'Agri Officer'**
  String get agriOfficer;

  /// No description provided for @mobileHint.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number (10 digits)'**
  String get mobileHint;

  /// No description provided for @otpHint.
  ///
  /// In en, this message translates to:
  /// **'Enter 6-digit OTP'**
  String get otpHint;

  /// No description provided for @getOtp.
  ///
  /// In en, this message translates to:
  /// **'Get OTP'**
  String get getOtp;

  /// No description provided for @notMember.
  ///
  /// In en, this message translates to:
  /// **'Not a member? Register'**
  String get notMember;

  /// No description provided for @alreadyMember.
  ///
  /// In en, this message translates to:
  /// **'Already a member? Login'**
  String get alreadyMember;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Farmer Dashboard'**
  String get dashboardTitle;

  /// No description provided for @todaysWeather.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Weather'**
  String get todaysWeather;

  /// No description provided for @planNewCrop.
  ///
  /// In en, this message translates to:
  /// **'Plan New Crop'**
  String get planNewCrop;

  /// No description provided for @addNewCrop.
  ///
  /// In en, this message translates to:
  /// **'Add New Crop'**
  String get addNewCrop;

  /// No description provided for @currentCrops.
  ///
  /// In en, this message translates to:
  /// **'Current Crops'**
  String get currentCrops;

  /// No description provided for @previousCrops.
  ///
  /// In en, this message translates to:
  /// **'Previous Crops'**
  String get previousCrops;

  /// No description provided for @cropHealth.
  ///
  /// In en, this message translates to:
  /// **'Crop Health'**
  String get cropHealth;

  /// No description provided for @checkHealth.
  ///
  /// In en, this message translates to:
  /// **'Check Crop Health'**
  String get checkHealth;

  /// No description provided for @detectDisease.
  ///
  /// In en, this message translates to:
  /// **'Detect Diseases & Gets Cures'**
  String get detectDisease;

  /// No description provided for @marketInsights.
  ///
  /// In en, this message translates to:
  /// **'Market Insights'**
  String get marketInsights;

  /// No description provided for @marketplace.
  ///
  /// In en, this message translates to:
  /// **'Marketplace'**
  String get marketplace;

  /// No description provided for @buySell.
  ///
  /// In en, this message translates to:
  /// **'Buy & Sell Crops'**
  String get buySell;

  /// No description provided for @addCropTitle.
  ///
  /// In en, this message translates to:
  /// **'Add New Crop'**
  String get addCropTitle;

  /// No description provided for @currentConditions.
  ///
  /// In en, this message translates to:
  /// **'Current Conditions'**
  String get currentConditions;

  /// No description provided for @cropType.
  ///
  /// In en, this message translates to:
  /// **'Crop Type'**
  String get cropType;

  /// No description provided for @cropTypeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Wheat, Rice, Tomato'**
  String get cropTypeHint;

  /// No description provided for @enterCropType.
  ///
  /// In en, this message translates to:
  /// **'Please enter crop type'**
  String get enterCropType;

  /// No description provided for @sowingDate.
  ///
  /// In en, this message translates to:
  /// **'Sowing Date'**
  String get sowingDate;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @selectDateError.
  ///
  /// In en, this message translates to:
  /// **'Please select sowing date'**
  String get selectDateError;

  /// No description provided for @soilMoisture.
  ///
  /// In en, this message translates to:
  /// **'Soil Moisture'**
  String get soilMoisture;

  /// No description provided for @moistureDry.
  ///
  /// In en, this message translates to:
  /// **'Dry'**
  String get moistureDry;

  /// No description provided for @moistureMoist.
  ///
  /// In en, this message translates to:
  /// **'Moist'**
  String get moistureMoist;

  /// No description provided for @moistureWet.
  ///
  /// In en, this message translates to:
  /// **'Extremely Moist'**
  String get moistureWet;

  /// No description provided for @addCropButton.
  ///
  /// In en, this message translates to:
  /// **'Add Crop'**
  String get addCropButton;

  /// No description provided for @purchaseHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Purchase History'**
  String get purchaseHistoryTitle;

  /// No description provided for @noPurchases.
  ///
  /// In en, this message translates to:
  /// **'No purchases yet'**
  String get noPurchases;

  /// No description provided for @quintalsFrom.
  ///
  /// In en, this message translates to:
  /// **'Quintals from'**
  String get quintalsFrom;

  /// No description provided for @cropHealthCheck.
  ///
  /// In en, this message translates to:
  /// **'Crop Health Check'**
  String get cropHealthCheck;

  /// No description provided for @takePhotoPrompt.
  ///
  /// In en, this message translates to:
  /// **'Take or upload a photo of the leaf'**
  String get takePhotoPrompt;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @analyzeCrop.
  ///
  /// In en, this message translates to:
  /// **'Analyze Crop Health'**
  String get analyzeCrop;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @diseaseName.
  ///
  /// In en, this message translates to:
  /// **'Disease Name:'**
  String get diseaseName;

  /// No description provided for @confidence.
  ///
  /// In en, this message translates to:
  /// **'Confidence:'**
  String get confidence;

  /// No description provided for @possibleCauses.
  ///
  /// In en, this message translates to:
  /// **'Possible Causes'**
  String get possibleCauses;

  /// No description provided for @prevention.
  ///
  /// In en, this message translates to:
  /// **'Prevention'**
  String get prevention;

  /// No description provided for @healthyCropMessage.
  ///
  /// In en, this message translates to:
  /// **'Your crop looks healthy! Keep up the good work.'**
  String get healthyCropMessage;

  /// No description provided for @marketplaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Marketplace'**
  String get marketplaceTitle;

  /// No description provided for @buyCropsTab.
  ///
  /// In en, this message translates to:
  /// **'Buy Crops'**
  String get buyCropsTab;

  /// No description provided for @sellCropsTab.
  ///
  /// In en, this message translates to:
  /// **'Sell Crops'**
  String get sellCropsTab;

  /// No description provided for @searchBuy.
  ///
  /// In en, this message translates to:
  /// **'Search crops to buy...'**
  String get searchBuy;

  /// No description provided for @searchSell.
  ///
  /// In en, this message translates to:
  /// **'Search crops to sell...'**
  String get searchSell;

  /// No description provided for @growthTime.
  ///
  /// In en, this message translates to:
  /// **'Growth Time:'**
  String get growthTime;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @sellDetails.
  ///
  /// In en, this message translates to:
  /// **'Sell Details'**
  String get sellDetails;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi', 'mr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'mr':
      return AppLocalizationsMr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
