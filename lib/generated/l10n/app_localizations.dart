import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_as.dart';
import 'app_localizations_bn.dart';
import 'app_localizations_brx.dart';
import 'app_localizations_doi.dart';
import 'app_localizations_en.dart';
import 'app_localizations_gu.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_kn.dart';
import 'app_localizations_kok.dart';
import 'app_localizations_ks.dart';
import 'app_localizations_mai.dart';
import 'app_localizations_ml.dart';
import 'app_localizations_mni.dart';
import 'app_localizations_mr.dart';
import 'app_localizations_ne.dart';
import 'app_localizations_or.dart';
import 'app_localizations_pa.dart';
import 'app_localizations_sa.dart';
import 'app_localizations_sat.dart';
import 'app_localizations_sd.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_te.dart';
import 'app_localizations_ur.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('as'),
    Locale('bn'),
    Locale('brx'),
    Locale('doi'),
    Locale('en'),
    Locale('gu'),
    Locale('hi'),
    Locale('kn'),
    Locale('kok'),
    Locale('ks'),
    Locale('mai'),
    Locale('ml'),
    Locale('mni'),
    Locale('mr'),
    Locale('ne'),
    Locale('or'),
    Locale('pa'),
    Locale('sa'),
    Locale('sat'),
    Locale('sd'),
    Locale('ta'),
    Locale('te'),
    Locale('ur'),
  ];

  /// The application name. Kept as-is (Latin script) in every locale.
  ///
  /// In en, this message translates to:
  /// **'Nexmile Rider'**
  String get appName;

  /// Brand tagline shown under the logo on the splash screen.
  ///
  /// In en, this message translates to:
  /// **'Fast Delivery. Fresh Smiles.'**
  String get tagline;

  /// Headline of the language selection screen.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get chooseLanguageTitle;

  /// Supporting copy under the language screen headline.
  ///
  /// In en, this message translates to:
  /// **'Pick the language you are most comfortable with. You can change it anytime from Settings.'**
  String get chooseLanguageSubtitle;

  /// Placeholder text inside the language search field.
  ///
  /// In en, this message translates to:
  /// **'Search language'**
  String get searchLanguageHint;

  /// Empty state shown when the search query matches no language.
  ///
  /// In en, this message translates to:
  /// **'No language found'**
  String get noLanguageFound;

  /// Count of languages offered by the app.
  ///
  /// In en, this message translates to:
  /// **'{count} languages available'**
  String languagesAvailable(int count);

  /// Generic confirm action.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// Accessibility label on the currently selected language tile.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selectedLabel;

  /// Badge shown on English, the default language.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultLabel;

  /// Greeting headline on the dashboard.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Nexmile'**
  String get homeTitle;

  /// Supporting copy on the dashboard.
  ///
  /// In en, this message translates to:
  /// **'Fresh groceries, hot food and daily essentials delivered from shops near you.'**
  String get homeSubtitle;

  /// Action that reopens the language selection screen.
  ///
  /// In en, this message translates to:
  /// **'Change language'**
  String get changeLanguage;

  /// Snackbar confirmation shown after the language changes.
  ///
  /// In en, this message translates to:
  /// **'Language updated'**
  String get languageUpdated;

  /// Label preceding the name of the currently active language.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get appLanguageLabel;

  /// Personalised greeting on the dashboard.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String greetingNamed(String name);

  /// Headline of the sign-in screen. Serves new and returning customers alike: the API creates the account on first successful verification.
  ///
  /// In en, this message translates to:
  /// **'Sign in to Nexmile'**
  String get loginTitle;

  /// Supporting copy on the sign-in screen.
  ///
  /// In en, this message translates to:
  /// **'Enter your email or mobile number and we will send you a verification code.'**
  String get loginSubtitle;

  /// Label of the single sign-in field, which accepts either.
  ///
  /// In en, this message translates to:
  /// **'Email or mobile number'**
  String get emailOrPhoneLabel;

  /// Placeholder showing both accepted formats. Keep the example values as-is; translate only the word 'or'.
  ///
  /// In en, this message translates to:
  /// **'name@example.com or 9876543210'**
  String get emailOrPhoneHint;

  /// Validation error when the sign-in field is neither a valid email nor a valid Indian mobile number.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address or 10-digit mobile number'**
  String get invalidEmailOrPhone;

  /// Primary button on the sign-in screen.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendCode;

  /// Implicit-consent note under the sign-in button. There is no registration form, so this is the only place terms can be surfaced.
  ///
  /// In en, this message translates to:
  /// **'By continuing you agree to our Terms of Service and Privacy Policy.'**
  String get agreeToTermsOnContinue;

  /// Headline of the code verification screen.
  ///
  /// In en, this message translates to:
  /// **'Verify it is you'**
  String get otpTitle;

  /// Supporting copy naming the email or mobile number the code went to.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code we sent to {target}'**
  String otpSubtitle(String target);

  /// Primary button on the code verification screen.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verifyCode;

  /// Action that requests a fresh code.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendCode;

  /// Cooldown label. The wait comes from the server's resend_after value.
  ///
  /// In en, this message translates to:
  /// **'Resend code in {seconds}s'**
  String resendCodeIn(int seconds);

  /// Snackbar confirming a fresh code.
  ///
  /// In en, this message translates to:
  /// **'A new code has been sent'**
  String get codeResent;

  /// Error for a wrong or expired code. Five wrong attempts burn the code, so the copy points at requesting another.
  ///
  /// In en, this message translates to:
  /// **'That code is not correct or has expired. Request a new one.'**
  String get incorrectCode;

  /// Error shown when Verify is pressed with an incomplete code.
  ///
  /// In en, this message translates to:
  /// **'Enter all 6 digits'**
  String get enterFullCode;

  /// Shown on HTTP 403 from the API.
  ///
  /// In en, this message translates to:
  /// **'This account has been suspended. Please contact support.'**
  String get accountSuspended;

  /// Shown on HTTP 429. Codes are limited to 5 per hour per identifier, 60 seconds apart.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a while and try again.'**
  String get tooManyAttempts;

  /// Shown when the refresh token is rejected and the session cannot be restored.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please sign in again.'**
  String get sessionExpired;

  /// Shown when the request never reached the server.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Check your connection and try again.'**
  String get networkError;

  /// Label on the card showing the API's debug_code. Only present outside production, while there is no SMS gateway.
  ///
  /// In en, this message translates to:
  /// **'Development code'**
  String get developmentCode;

  /// Action that ends the session on this device.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// Snackbar after signing out.
  ///
  /// In en, this message translates to:
  /// **'You have been signed out'**
  String get signedOut;

  /// Generic fallback error.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get somethingWentWrong;

  /// Title of the profile screen, and the label of the dashboard row that opens it.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// Dashboard action that opens the profile screen.
  ///
  /// In en, this message translates to:
  /// **'View profile'**
  String get viewProfile;

  /// Profile field label.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// Profile field label.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// Profile field label.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get mobileLabel;

  /// Profile field label.
  ///
  /// In en, this message translates to:
  /// **'Account status'**
  String get accountStatusLabel;

  /// Account status. Customers are active immediately after verifying a code.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// Account status. Not expected for customers — riders await approval, customers do not.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// Account status.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get statusSuspended;

  /// Badge next to a mobile number the customer has verified by code.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verifiedLabel;

  /// Placeholder for a profile field the customer has not filled in. Signing in with a phone leaves the email empty, and vice versa.
  ///
  /// In en, this message translates to:
  /// **'Not added'**
  String get notProvided;

  /// Action on the profile screen when the refresh failed.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// Line under the sign-in copy. The OTP flow is shared with the customer app, so the rider app says plainly which one this is.
  ///
  /// In en, this message translates to:
  /// **'This app is for Nexmile delivery partners.'**
  String get loginRiderNote;

  /// Shown while the rider profile and KYC file are being fetched after sign-in.
  ///
  /// In en, this message translates to:
  /// **'Checking your account'**
  String get checkingYourAccount;

  /// Shown when the profile fetch fails and there is nothing to display.
  ///
  /// In en, this message translates to:
  /// **'We could not load your account. Check your connection and try again.'**
  String get couldNotLoadAccount;

  /// Headline shown when the rider endpoints answer 403 because the signed-in account has another role.
  ///
  /// In en, this message translates to:
  /// **'This is not a delivery partner account'**
  String get notARiderAccountTitle;

  /// Shown when the signed-in account is not a rider but its role is not known. An account's role is fixed when it is created, so no retry will ever clear this.
  ///
  /// In en, this message translates to:
  /// **'This email or mobile number is already registered on another Nexmile account. Sign out and use a different one to join as a delivery partner.'**
  String get notARiderAccount;

  /// Shown when the signed-in account has a role other than rider, naming that role.
  ///
  /// In en, this message translates to:
  /// **'This email or mobile number is already registered as a Nexmile {role}. Sign out and use a different one to join as a delivery partner.'**
  String notARiderAccountFor(String role);

  /// Account role, used inside notARiderAccountFor. Lower case: it appears mid-sentence.
  ///
  /// In en, this message translates to:
  /// **'customer'**
  String get roleCustomer;

  /// Account role, used inside notARiderAccountFor. Lower case: it appears mid-sentence.
  ///
  /// In en, this message translates to:
  /// **'merchant'**
  String get roleMerchant;

  /// Account role, used inside notARiderAccountFor. Lower case: it appears mid-sentence.
  ///
  /// In en, this message translates to:
  /// **'administrator'**
  String get roleAdmin;

  /// Action that signs out so a different email or mobile number can be used.
  ///
  /// In en, this message translates to:
  /// **'Use another account'**
  String get useAnotherAccount;

  /// Headline of the rider onboarding wizard.
  ///
  /// In en, this message translates to:
  /// **'Become a Nexmile partner'**
  String get onboardingTitle;

  /// Supporting copy on the first step of onboarding.
  ///
  /// In en, this message translates to:
  /// **'A few details and your documents, then our team verifies you. It usually takes up to two working days.'**
  String get onboardingSubtitle;

  /// Progress label above the onboarding form.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String stepOfSteps(int current, int total);

  /// Onboarding step 1 headline.
  ///
  /// In en, this message translates to:
  /// **'About you'**
  String get stepIdentityTitle;

  /// Onboarding step 1 supporting copy.
  ///
  /// In en, this message translates to:
  /// **'Enter your name exactly as it appears on your Aadhaar card.'**
  String get stepIdentitySubtitle;

  /// Onboarding step 2 headline.
  ///
  /// In en, this message translates to:
  /// **'Your vehicle'**
  String get stepVehicleTitle;

  /// Onboarding step 2 supporting copy.
  ///
  /// In en, this message translates to:
  /// **'Tell us what you ride and the number plate it carries.'**
  String get stepVehicleSubtitle;

  /// Onboarding step 3 headline.
  ///
  /// In en, this message translates to:
  /// **'Identity numbers'**
  String get stepIdentityNumbersTitle;

  /// Onboarding step 3 supporting copy.
  ///
  /// In en, this message translates to:
  /// **'These must match the documents you upload later.'**
  String get stepIdentityNumbersSubtitle;

  /// Onboarding step 4 headline.
  ///
  /// In en, this message translates to:
  /// **'Licence and insurance'**
  String get stepLicenceTitle;

  /// Onboarding step 4 supporting copy.
  ///
  /// In en, this message translates to:
  /// **'Both must be valid on the day you start delivering.'**
  String get stepLicenceSubtitle;

  /// Onboarding step 5 headline.
  ///
  /// In en, this message translates to:
  /// **'Where you get paid'**
  String get stepBankTitle;

  /// Onboarding step 5 supporting copy.
  ///
  /// In en, this message translates to:
  /// **'Your earnings are settled to this account. Check it carefully.'**
  String get stepBankSubtitle;

  /// Onboarding step 6 headline.
  ///
  /// In en, this message translates to:
  /// **'Your documents'**
  String get stepDocumentsTitle;

  /// Onboarding step 6 supporting copy.
  ///
  /// In en, this message translates to:
  /// **'Photograph each one in good light. JPG, PNG or PDF, up to 5 MB each.'**
  String get stepDocumentsSubtitle;

  /// Onboarding step 7 headline.
  ///
  /// In en, this message translates to:
  /// **'Check and submit'**
  String get stepReviewTitle;

  /// Onboarding step 7 supporting copy.
  ///
  /// In en, this message translates to:
  /// **'Once you submit, your details are locked until our team has reviewed them.'**
  String get stepReviewSubtitle;

  /// Primary action on every onboarding step.
  ///
  /// In en, this message translates to:
  /// **'Save and continue'**
  String get saveAndContinue;

  /// Secondary action that returns to the previous onboarding step.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backLabel;

  /// Onboarding field label.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullNameLabel;

  /// Placeholder in the full name field.
  ///
  /// In en, this message translates to:
  /// **'As printed on your Aadhaar'**
  String get fullNameHint;

  /// Onboarding field label.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get dateOfBirthLabel;

  /// Placeholder shown in a date field before a date is picked.
  ///
  /// In en, this message translates to:
  /// **'Select a date'**
  String get selectDate;

  /// Onboarding field label.
  ///
  /// In en, this message translates to:
  /// **'Vehicle type'**
  String get vehicleTypeLabel;

  /// Vehicle type option.
  ///
  /// In en, this message translates to:
  /// **'Motorcycle'**
  String get vehicleMotorcycle;

  /// Vehicle type option.
  ///
  /// In en, this message translates to:
  /// **'Scooter'**
  String get vehicleScooter;

  /// Vehicle type option.
  ///
  /// In en, this message translates to:
  /// **'Electric vehicle'**
  String get vehicleEv;

  /// Vehicle type option.
  ///
  /// In en, this message translates to:
  /// **'Bicycle'**
  String get vehicleBicycle;

  /// Vehicle type option for a rider who delivers walking.
  ///
  /// In en, this message translates to:
  /// **'On foot'**
  String get vehicleWalk;

  /// Shown in place of the vehicle number and RC fields when the rider walks or cycles.
  ///
  /// In en, this message translates to:
  /// **'No vehicle number or RC needed. You will be asked for Aadhaar and PAN only.'**
  String get vehicleNoPapersNote;

  /// Onboarding field label.
  ///
  /// In en, this message translates to:
  /// **'Vehicle number'**
  String get vehicleNumberLabel;

  /// Placeholder for the number plate. Keep the example as-is in every language.
  ///
  /// In en, this message translates to:
  /// **'TN01AB1234'**
  String get vehicleNumberHint;

  /// Onboarding field label. RC is the vehicle registration certificate.
  ///
  /// In en, this message translates to:
  /// **'RC number'**
  String get rcNumberLabel;

  /// Onboarding field label.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar number'**
  String get aadhaarLabel;

  /// Placeholder in the Aadhaar field.
  ///
  /// In en, this message translates to:
  /// **'12 digits'**
  String get aadhaarHint;

  /// Onboarding field label. India's permanent account number.
  ///
  /// In en, this message translates to:
  /// **'PAN'**
  String get panLabel;

  /// Placeholder showing the PAN format. Keep the example as-is in every language.
  ///
  /// In en, this message translates to:
  /// **'ABCDE1234F'**
  String get panHint;

  /// Onboarding field label.
  ///
  /// In en, this message translates to:
  /// **'Driving licence number'**
  String get drivingLicenceNoLabel;

  /// Onboarding date field label.
  ///
  /// In en, this message translates to:
  /// **'Licence valid until'**
  String get drivingLicenceExpiryLabel;

  /// Onboarding field label.
  ///
  /// In en, this message translates to:
  /// **'Insurance policy number'**
  String get insuranceNumberLabel;

  /// Onboarding date field label.
  ///
  /// In en, this message translates to:
  /// **'Insurance valid until'**
  String get insuranceExpiryLabel;

  /// Onboarding field label.
  ///
  /// In en, this message translates to:
  /// **'Account holder name'**
  String get bankAccountNameLabel;

  /// Onboarding field label.
  ///
  /// In en, this message translates to:
  /// **'Account number'**
  String get bankAccountNumberLabel;

  /// Onboarding field label. Identifies the bank branch.
  ///
  /// In en, this message translates to:
  /// **'IFSC code'**
  String get bankIfscLabel;

  /// Placeholder showing the IFSC format. Keep the example as-is in every language.
  ///
  /// In en, this message translates to:
  /// **'SBIN0001234'**
  String get bankIfscHint;

  /// Progress line above the document checklist.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} uploaded'**
  String documentsProgress(int done, int total);

  /// Action on an empty document row.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get uploadDocument;

  /// Action on a document row that already has a file.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get replaceDocument;

  /// Action that deletes an uploaded document.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeDocument;

  /// Option in the document upload sheet.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get takePhoto;

  /// Option in the document upload sheet.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get chooseFromGallery;

  /// Option in the document upload sheet, for a PDF.
  ///
  /// In en, this message translates to:
  /// **'Choose a file'**
  String get chooseFile;

  /// Shown on a document row while its file is in flight.
  ///
  /// In en, this message translates to:
  /// **'Uploading'**
  String get uploadingLabel;

  /// Badge on a document an admin turned down.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get documentRejected;

  /// Badge on a document that is on file and awaiting review.
  ///
  /// In en, this message translates to:
  /// **'Uploaded'**
  String get documentUploaded;

  /// Badge on a document an admin accepted.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get documentApproved;

  /// Badge on a document that has not been uploaded yet.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get documentRequired;

  /// Badge on a document the API allows but does not require.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get documentOptional;

  /// Error when the chosen file exceeds the API's limit.
  ///
  /// In en, this message translates to:
  /// **'That file is over 5 MB. Try a photo instead of a scan.'**
  String get fileTooLarge;

  /// Error when the chosen file is of a type the API refuses.
  ///
  /// In en, this message translates to:
  /// **'Choose a JPG, PNG or PDF.'**
  String get unsupportedFileType;

  /// Error when the camera or file browser could not be opened, usually a denied permission.
  ///
  /// In en, this message translates to:
  /// **'We could not open that. Check the app\'s camera and photo permissions.'**
  String get pickerUnavailable;

  /// Error when the server refused an uploaded document.
  ///
  /// In en, this message translates to:
  /// **'That upload did not go through. Please try again.'**
  String get uploadFailed;

  /// Final action of the onboarding wizard.
  ///
  /// In en, this message translates to:
  /// **'Submit for verification'**
  String get submitForVerification;

  /// Title of the confirmation dialog before submitting KYC.
  ///
  /// In en, this message translates to:
  /// **'Submit for verification?'**
  String get submitConfirmTitle;

  /// Body of the confirmation dialog before submitting KYC.
  ///
  /// In en, this message translates to:
  /// **'Your details and documents will be locked while our team reviews them. You cannot change them until a decision is made.'**
  String get submitConfirmBody;

  /// Dismisses a dialog without acting.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelLabel;

  /// Shown when submit is refused because something is outstanding.
  ///
  /// In en, this message translates to:
  /// **'Finish every step and upload all the documents before submitting.'**
  String get completeEverythingBeforeSubmitting;

  /// Shown when the server rejects a form with field errors.
  ///
  /// In en, this message translates to:
  /// **'Check the highlighted fields and try again.'**
  String get checkTheHighlightedFields;

  /// Headline of the waiting screen shown while KYC status is submitted.
  ///
  /// In en, this message translates to:
  /// **'We are verifying your documents'**
  String get underReviewTitle;

  /// Supporting copy on the waiting screen.
  ///
  /// In en, this message translates to:
  /// **'Our team usually reviews within two working days. We will let you know as soon as you are approved.'**
  String get underReviewBody;

  /// Action on the waiting screen that refetches the KYC status.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get checkAgain;

  /// Snackbar shown when a refresh finds no change.
  ///
  /// In en, this message translates to:
  /// **'Still under review'**
  String get stillUnderReview;

  /// Headline shown when KYC is rejected.
  ///
  /// In en, this message translates to:
  /// **'We could not verify you'**
  String get rejectedTitle;

  /// Supporting copy shown when KYC is rejected.
  ///
  /// In en, this message translates to:
  /// **'Fix what our team noted below, then send your documents again.'**
  String get rejectedBody;

  /// Label above the admin's rejection note.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get rejectionReasonLabel;

  /// Action that reopens the onboarding wizard after a rejection.
  ///
  /// In en, this message translates to:
  /// **'Fix and submit again'**
  String get fixAndResubmit;

  /// Headline shown when KYC is verified but the API still refuses to dispatch the rider.
  ///
  /// In en, this message translates to:
  /// **'You cannot go online yet'**
  String get blockedTitle;

  /// Shown on HTTP 403 from duty-status when a document has lapsed.
  ///
  /// In en, this message translates to:
  /// **'Your licence or insurance has expired. Upload current documents to go online.'**
  String get documentsExpiredMessage;

  /// Shown on HTTP 403 from duty-status while KYC is under review.
  ///
  /// In en, this message translates to:
  /// **'Your documents are still being verified.'**
  String get awaitingVerificationMessage;

  /// Action that opens the document checklist to replace a lapsed document.
  ///
  /// In en, this message translates to:
  /// **'Update documents'**
  String get updateDocuments;

  /// Headline of the rider home screen.
  ///
  /// In en, this message translates to:
  /// **'Ready to ride'**
  String get riderHomeTitle;

  /// Supporting copy on the rider home screen.
  ///
  /// In en, this message translates to:
  /// **'Go online and we will send you nearby deliveries.'**
  String get riderHomeSubtitle;

  /// Label above the online/offline control.
  ///
  /// In en, this message translates to:
  /// **'Duty status'**
  String get dutyStatusLabel;

  /// Duty status: available for deliveries.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get dutyOnline;

  /// Duty status: not working.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get dutyOffline;

  /// Duty status: working but not dispatchable.
  ///
  /// In en, this message translates to:
  /// **'On a break'**
  String get dutyOnBreak;

  /// Action that sets duty status to available.
  ///
  /// In en, this message translates to:
  /// **'Go online'**
  String get goOnline;

  /// Action that sets duty status to offline.
  ///
  /// In en, this message translates to:
  /// **'Go offline'**
  String get goOffline;

  /// Action that sets duty status to on a break.
  ///
  /// In en, this message translates to:
  /// **'Take a break'**
  String get takeABreak;

  /// Status line shown on the home screen while the rider is online and idle.
  ///
  /// In en, this message translates to:
  /// **'Waiting for orders nearby'**
  String get waitingForOrders;

  /// Status line shown on the home screen while the rider is offline.
  ///
  /// In en, this message translates to:
  /// **'You are offline. No deliveries will be sent to you.'**
  String get youAreOffline;

  /// Statistic on the rider home screen.
  ///
  /// In en, this message translates to:
  /// **'Deliveries completed'**
  String get completedDeliveriesLabel;

  /// Statistic on the rider home screen.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get ratingLabel;

  /// Shown in place of a rating before the first rated delivery.
  ///
  /// In en, this message translates to:
  /// **'Not rated yet'**
  String get notRatedYet;

  /// Profile field label.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get vehicleLabel;

  /// Profile field label for the KYC status.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get kycStatusLabel;

  /// KYC status: the rider has not sent the file yet.
  ///
  /// In en, this message translates to:
  /// **'Not submitted'**
  String get kycPending;

  /// KYC status: with an admin.
  ///
  /// In en, this message translates to:
  /// **'Under review'**
  String get kycSubmitted;

  /// KYC status: approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get kycVerified;

  /// KYC status: turned down.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get kycRejected;

  /// Validation error for an empty required field.
  ///
  /// In en, this message translates to:
  /// **'This is required'**
  String get fieldRequired;

  /// Validation error for the Aadhaar field.
  ///
  /// In en, this message translates to:
  /// **'Enter the 12 digits of your Aadhaar number'**
  String get invalidAadhaar;

  /// Validation error for the PAN field. Keep the example as-is.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid PAN, like ABCDE1234F'**
  String get invalidPan;

  /// Validation error for the IFSC field. Keep the example as-is.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid IFSC code, like SBIN0001234'**
  String get invalidIfsc;

  /// Validation error for the vehicle number field.
  ///
  /// In en, this message translates to:
  /// **'Enter the number exactly as it appears on the plate'**
  String get invalidVehicleNumber;

  /// Validation error for the bank account number field.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid account number'**
  String get invalidAccountNumber;

  /// Validation error when a licence or insurance expiry is in the past.
  ///
  /// In en, this message translates to:
  /// **'This date has already passed'**
  String get dateMustBeFuture;

  /// Validation error on the date of birth field.
  ///
  /// In en, this message translates to:
  /// **'You must be at least 18 years old to deliver'**
  String get mustBeEighteen;

  /// KYC document name.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar card (front)'**
  String get docAadhaarFront;

  /// KYC document name.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar card (back)'**
  String get docAadhaarBack;

  /// KYC document name.
  ///
  /// In en, this message translates to:
  /// **'Driving licence'**
  String get docDrivingLicence;

  /// KYC document name.
  ///
  /// In en, this message translates to:
  /// **'Vehicle registration certificate'**
  String get docVehicleRc;

  /// KYC document name.
  ///
  /// In en, this message translates to:
  /// **'Vehicle insurance'**
  String get docInsurance;

  /// KYC document name.
  ///
  /// In en, this message translates to:
  /// **'Profile photo'**
  String get docProfilePhoto;

  /// KYC document name.
  ///
  /// In en, this message translates to:
  /// **'PAN card'**
  String get docPan;

  /// KYC document name.
  ///
  /// In en, this message translates to:
  /// **'Cancelled cheque or bank statement'**
  String get docBankProof;

  /// Bottom navigation label for the order board.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get ordersTab;

  /// Bottom navigation label for the order the rider is carrying.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get deliveryTab;

  /// Bottom navigation label for past deliveries.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTab;

  /// Headline of the available-orders board.
  ///
  /// In en, this message translates to:
  /// **'Orders near you'**
  String get orderBoardTitle;

  /// Supporting copy under the order board headline.
  ///
  /// In en, this message translates to:
  /// **'Nearest restaurant first. The list refreshes on its own.'**
  String get orderBoardSubtitle;

  /// An order's reference, shown as a heading on cards and screens.
  ///
  /// In en, this message translates to:
  /// **'Order {number}'**
  String orderNumberLabel(String number);

  /// Label for the restaurant an order is collected from.
  ///
  /// In en, this message translates to:
  /// **'Pick up'**
  String get pickupLabel;

  /// Label for the customer's address.
  ///
  /// In en, this message translates to:
  /// **'Deliver to'**
  String get dropoffLabel;

  /// A short distance. Keep the unit abbreviation.
  ///
  /// In en, this message translates to:
  /// **'{metres} m'**
  String distanceMetres(String metres);

  /// A longer distance. Keep the unit abbreviation.
  ///
  /// In en, this message translates to:
  /// **'{km} km'**
  String distanceKilometres(String km);

  /// How many lines are on the ticket.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String itemCount(int count);

  /// Label for the rider's delivery fee on an order card.
  ///
  /// In en, this message translates to:
  /// **'You earn'**
  String get earningsLabel;

  /// Label for the amount to collect at the door.
  ///
  /// In en, this message translates to:
  /// **'Collect cash'**
  String get collectCashLabel;

  /// Shown instead of a cash amount when the customer has already paid.
  ///
  /// In en, this message translates to:
  /// **'Paid online'**
  String get prepaidLabel;

  /// Prominent reminder on the delivery screen for a cash order.
  ///
  /// In en, this message translates to:
  /// **'Collect {amount} from the customer'**
  String collectAtDoor(String amount);

  /// Shown on the delivery screen when the order was prepaid.
  ///
  /// In en, this message translates to:
  /// **'Already paid. Do not ask for money.'**
  String get nothingToCollect;

  /// Button that takes an order off the board.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get acceptOrder;

  /// Button that opens an order's full details.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get viewOrder;

  /// Confirmation after accepting an order.
  ///
  /// In en, this message translates to:
  /// **'Order accepted. Head to the restaurant.'**
  String get orderAccepted;

  /// Shown when an accept lost the race. Routine on a shared board, not a fault.
  ///
  /// In en, this message translates to:
  /// **'Another rider took this one. Here is the latest list.'**
  String get orderAlreadyTaken;

  /// Shown when an order 404s because it was reassigned or cancelled.
  ///
  /// In en, this message translates to:
  /// **'This order is no longer yours.'**
  String get orderNoLongerYours;

  /// Empty state on the board while the rider is online and eligible.
  ///
  /// In en, this message translates to:
  /// **'No orders right now'**
  String get boardEmptyTitle;

  /// Supporting copy for the ordinary empty board.
  ///
  /// In en, this message translates to:
  /// **'Stay online. The list updates on its own as restaurants get busy.'**
  String get boardEmptyBody;

  /// Empty state on the board when duty status is offline or on a break.
  ///
  /// In en, this message translates to:
  /// **'You are offline'**
  String get boardOfflineTitle;

  /// Supporting copy for the offline empty board.
  ///
  /// In en, this message translates to:
  /// **'Go online to start receiving orders.'**
  String get boardOfflineBody;

  /// Empty state on the board while the rider is carrying an order.
  ///
  /// In en, this message translates to:
  /// **'Finish your delivery first'**
  String get boardBusyTitle;

  /// Supporting copy shown when the rider already has an order.
  ///
  /// In en, this message translates to:
  /// **'You can take another order once this one is delivered.'**
  String get boardBusyBody;

  /// Empty state on the board when no position has been sent.
  ///
  /// In en, this message translates to:
  /// **'We cannot find you'**
  String get boardNoLocationTitle;

  /// Supporting copy shown when dispatch has no position for the rider.
  ///
  /// In en, this message translates to:
  /// **'Orders are sorted by how close the restaurant is, so we need your location to show you anything.'**
  String get boardNoLocationBody;

  /// Empty state on the board when KYC is not approved or documents have lapsed.
  ///
  /// In en, this message translates to:
  /// **'Not approved to ride yet'**
  String get boardNotVerifiedTitle;

  /// Headline of the screen for the order in hand.
  ///
  /// In en, this message translates to:
  /// **'Your delivery'**
  String get activeDeliveryTitle;

  /// What the rider does next, straight after accepting.
  ///
  /// In en, this message translates to:
  /// **'Head to the restaurant'**
  String get headToRestaurant;

  /// What the rider does next, after collecting the food.
  ///
  /// In en, this message translates to:
  /// **'Deliver to the customer'**
  String get deliverToCustomer;

  /// Empty state shown when the rider is carrying no order.
  ///
  /// In en, this message translates to:
  /// **'Nothing in hand'**
  String get noActiveDeliveryTitle;

  /// Supporting copy for the empty delivery screen.
  ///
  /// In en, this message translates to:
  /// **'Accept an order from the board and it will show up here.'**
  String get noActiveDeliveryBody;

  /// Button that opens the pickup code entry.
  ///
  /// In en, this message translates to:
  /// **'I have collected it'**
  String get confirmPickupButton;

  /// Title of the sheet where the merchant's code is typed.
  ///
  /// In en, this message translates to:
  /// **'Pickup code'**
  String get pickupCodeTitle;

  /// Supporting copy in the pickup code sheet.
  ///
  /// In en, this message translates to:
  /// **'Ask the restaurant for the code and type it here.'**
  String get pickupCodeSubtitle;

  /// Placeholder inside the pickup code field.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get pickupCodeHint;

  /// Error shown when the pickup code is refused.
  ///
  /// In en, this message translates to:
  /// **'That code did not match. Check it with the restaurant.'**
  String get wrongPickupCode;

  /// Confirmation after a successful pickup.
  ///
  /// In en, this message translates to:
  /// **'Picked up. Deliver to the customer.'**
  String get pickupConfirmed;

  /// Button that closes an order out.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get confirmDeliveryButton;

  /// Title of the confirmation dialog before closing an order.
  ///
  /// In en, this message translates to:
  /// **'Confirm delivery'**
  String get confirmDeliveryTitle;

  /// Warning in the delivery confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Only confirm once the customer has the order in hand.'**
  String get confirmDeliveryBody;

  /// Warning in the delivery confirmation dialog for a cash order.
  ///
  /// In en, this message translates to:
  /// **'Collect {amount} first, then confirm.'**
  String confirmDeliveryCashBody(String amount);

  /// Confirmation after closing an order out.
  ///
  /// In en, this message translates to:
  /// **'Delivered. Thanks, you are back online.'**
  String get deliveryConfirmed;

  /// Button that returns an order to the board.
  ///
  /// In en, this message translates to:
  /// **'Hand it back'**
  String get releaseOrderButton;

  /// Title of the sheet for returning an order.
  ///
  /// In en, this message translates to:
  /// **'Hand this order back?'**
  String get releaseOrderTitle;

  /// Explanation in the hand-back sheet.
  ///
  /// In en, this message translates to:
  /// **'It goes back on the board for another rider. You can only do this before you collect the food.'**
  String get releaseOrderBody;

  /// Placeholder in the hand-back reason field.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get releaseReasonHint;

  /// Confirmation after handing an order back.
  ///
  /// In en, this message translates to:
  /// **'Handed back. It is available to other riders again.'**
  String get orderReleased;

  /// Shown when going offline is refused because an order is in hand.
  ///
  /// In en, this message translates to:
  /// **'Finish or hand back your current order first.'**
  String get finishCurrentOrderFirst;

  /// Button that dials the pickup contact.
  ///
  /// In en, this message translates to:
  /// **'Call restaurant'**
  String get callRestaurant;

  /// Button that dials the delivery contact.
  ///
  /// In en, this message translates to:
  /// **'Call customer'**
  String get callCustomer;

  /// Button that opens the address in a maps app.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get openInMaps;

  /// Label above the customer's instructions.
  ///
  /// In en, this message translates to:
  /// **'Note from the customer'**
  String get customerNoteLabel;

  /// Heading above the list of items on an order.
  ///
  /// In en, this message translates to:
  /// **'What is in the bag'**
  String get orderItemsLabel;

  /// Title of the single-order screen.
  ///
  /// In en, this message translates to:
  /// **'Order details'**
  String get orderDetailsTitle;

  /// Headline of the delivery history screen.
  ///
  /// In en, this message translates to:
  /// **'Past deliveries'**
  String get historyTitle;

  /// Empty state on the history screen.
  ///
  /// In en, this message translates to:
  /// **'No deliveries yet'**
  String get historyEmptyTitle;

  /// Supporting copy for the empty history screen.
  ///
  /// In en, this message translates to:
  /// **'Orders you have completed will be listed here.'**
  String get historyEmptyBody;

  /// Order status: completed.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get orderDelivered;

  /// Order status: called off.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get orderCancelled;

  /// Order status: the kitchen is still cooking.
  ///
  /// In en, this message translates to:
  /// **'Being prepared'**
  String get orderPreparing;

  /// Order status: waiting at the counter.
  ///
  /// In en, this message translates to:
  /// **'Ready for pickup'**
  String get orderReadyForPickup;

  /// Order status: taken by this rider, not yet collected.
  ///
  /// In en, this message translates to:
  /// **'Assigned to you'**
  String get orderAssigned;

  /// Order status: collected from the restaurant.
  ///
  /// In en, this message translates to:
  /// **'Picked up'**
  String get orderPickedUp;

  /// Order status: heading to the customer.
  ///
  /// In en, this message translates to:
  /// **'On the way'**
  String get orderOutForDelivery;

  /// Confirms the position heartbeat is running while on duty.
  ///
  /// In en, this message translates to:
  /// **'Location sharing on'**
  String get trackingOn;

  /// Shown when the device refuses a position fix.
  ///
  /// In en, this message translates to:
  /// **'We cannot read your location. Turn on location and allow it for Nexmile Rider.'**
  String get locationUnavailableMessage;

  /// Title of the banner asking for location access.
  ///
  /// In en, this message translates to:
  /// **'Location needed'**
  String get locationPermissionTitle;

  /// Explains why the app needs a position.
  ///
  /// In en, this message translates to:
  /// **'Dispatch sorts orders by how close you are, and the customer follows you on a map. Allow location to go online.'**
  String get locationPermissionBody;

  /// Button that opens the operating system location settings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get locationSettingsButton;

  /// Button that requests location permission.
  ///
  /// In en, this message translates to:
  /// **'Allow location'**
  String get enableLocationButton;

  /// A money amount. Keep the rupee sign.
  ///
  /// In en, this message translates to:
  /// **'₹{amount}'**
  String amountRupees(String amount);

  /// Bottom navigation label for the duty and summary tab.
  ///
  /// In en, this message translates to:
  /// **'Shift'**
  String get shiftTab;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'as',
    'bn',
    'brx',
    'doi',
    'en',
    'gu',
    'hi',
    'kn',
    'kok',
    'ks',
    'mai',
    'ml',
    'mni',
    'mr',
    'ne',
    'or',
    'pa',
    'sa',
    'sat',
    'sd',
    'ta',
    'te',
    'ur',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'as':
      return AppLocalizationsAs();
    case 'bn':
      return AppLocalizationsBn();
    case 'brx':
      return AppLocalizationsBrx();
    case 'doi':
      return AppLocalizationsDoi();
    case 'en':
      return AppLocalizationsEn();
    case 'gu':
      return AppLocalizationsGu();
    case 'hi':
      return AppLocalizationsHi();
    case 'kn':
      return AppLocalizationsKn();
    case 'kok':
      return AppLocalizationsKok();
    case 'ks':
      return AppLocalizationsKs();
    case 'mai':
      return AppLocalizationsMai();
    case 'ml':
      return AppLocalizationsMl();
    case 'mni':
      return AppLocalizationsMni();
    case 'mr':
      return AppLocalizationsMr();
    case 'ne':
      return AppLocalizationsNe();
    case 'or':
      return AppLocalizationsOr();
    case 'pa':
      return AppLocalizationsPa();
    case 'sa':
      return AppLocalizationsSa();
    case 'sat':
      return AppLocalizationsSat();
    case 'sd':
      return AppLocalizationsSd();
    case 'ta':
      return AppLocalizationsTa();
    case 'te':
      return AppLocalizationsTe();
    case 'ur':
      return AppLocalizationsUr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
