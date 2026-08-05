// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Santali (`sat`).
class AppLocalizationsSat extends AppLocalizations {
  AppLocalizationsSat([String locale = 'sat']) : super(locale);

  @override
  String get appName => 'Nexmile Rider';

  @override
  String get tagline => 'ᱞᱚᱜᱚᱱ ᱰᱮᱞᱤᱵᱷᱟᱨᱤ᱾ ᱱᱟᱶᱟ ᱞᱟᱸᱰᱟ᱾';

  @override
  String get chooseLanguageTitle => 'ᱟᱢᱟᱜ ᱯᱟᱹᱨᱥᱤ ᱵᱟᱪᱷᱟᱣ ᱢᱮ';

  @override
  String get chooseLanguageSubtitle => 'ᱟᱢ ᱡᱟᱦᱟᱸ ᱯᱟᱹᱨᱥᱤ ᱨᱮ ᱥᱩᱦᱩᱞ ᱟᱢ ᱚᱱᱟ ᱵᱟᱪᱷᱟᱣ ᱢᱮ᱾ ᱟᱢ ᱱᱚᱶᱟ ᱡᱟᱦᱟᱸ ᱚᱠᱛᱚ ᱥᱮᱴᱤᱝᱥ ᱨᱮ ᱵᱚᱫᱚᱞ ᱫᱟᱲᱮᱭᱟᱜ-ᱟᱢ᱾';

  @override
  String get searchLanguageHint => 'ᱯᱟᱹᱨᱥᱤ ᱯᱟᱱᱛᱮ ᱢᱮ';

  @override
  String get noLanguageFound => 'ᱡᱟᱦᱟᱸ ᱯᱟᱹᱨᱥᱤ ᱵᱟᱝ ᱧᱟᱢ ᱞᱮᱱᱟ';

  @override
  String languagesAvailable(int count) {
    return '$count ᱯᱟᱹᱨᱥᱤ ᱢᱮᱱᱟᱜ-ᱟ';
  }

  @override
  String get continueLabel => 'ᱞᱟᱦᱟ ᱪᱟᱞᱟᱣ ᱢᱮ';

  @override
  String get selectedLabel => 'ᱵᱟᱪᱷᱟᱣᱟᱠᱟᱱ';

  @override
  String get defaultLabel => 'ᱰᱤᱯᱷᱚᱞᱴ';

  @override
  String get homeTitle => 'Nexmile ᱨᱮ ᱡᱚᱦᱟᱨ';

  @override
  String get homeSubtitle => 'ᱱᱟᱶᱟ ᱠᱤᱨᱟᱱᱟ, ᱨᱟᱹᱲᱟᱹ ᱡᱚᱢᱟᱜ ᱟᱨ ᱫᱤᱱ ᱫᱤᱱᱟᱜ ᱡᱤᱱᱤᱥ ᱟᱢᱟᱜ ᱡᱟᱹᱛᱤᱭᱟᱹᱨ ᱫᱳᱠᱟᱱ ᱠᱷᱚᱱ᱾';

  @override
  String get changeLanguage => 'ᱯᱟᱹᱨᱥᱤ ᱵᱚᱫᱚᱞ ᱢᱮ';

  @override
  String get languageUpdated => 'ᱯᱟᱹᱨᱥᱤ ᱵᱚᱫᱚᱞ ᱮᱱᱟ';

  @override
  String get appLanguageLabel => 'ᱮᱯ ᱯᱟᱹᱨᱥᱤ';

  @override
  String greetingNamed(String name) {
    return 'ᱡᱚᱦᱟᱨ, $name';
  }

  @override
  String get loginTitle => 'Nexmile ᱨᱮ ᱥᱟᱭᱤᱱ ᱤᱱ ᱢᱮ';

  @override
  String get loginSubtitle => 'ᱟᱢᱟᱜ ᱤᱢᱮᱞ ᱵᱟᱝᱠᱷᱟᱱ ᱢᱚᱵᱟᱭᱤᱞ ᱱᱟᱢᱵᱟᱨ ᱚᱞ ᱢᱮ, ᱟᱞᱮ ᱡᱟᱸᱪ ᱠᱳᱰ ᱠᱩᱞ ᱟᱞᱮᱭᱟ᱾';

  @override
  String get emailOrPhoneLabel => 'ᱤᱢᱮᱞ ᱵᱟᱝᱠᱷᱟᱱ ᱢᱚᱵᱟᱭᱤᱞ ᱱᱟᱢᱵᱟᱨ';

  @override
  String get emailOrPhoneHint => 'name@example.com ᱵᱟᱝᱠᱷᱟᱱ 9876543210';

  @override
  String get invalidEmailOrPhone => 'ᱴᱷᱤᱠ ᱤᱢᱮᱞ ᱴᱷᱤᱠᱱᱟ ᱵᱟᱝᱠᱷᱟᱱ 10 ᱮᱞ ᱢᱚᱵᱟᱭᱤᱞ ᱱᱟᱢᱵᱟᱨ ᱚᱞ ᱢᱮ';

  @override
  String get sendCode => 'ᱠᱳᱰ ᱠᱩᱞ ᱢᱮ';

  @override
  String get agreeToTermsOnContinue => 'ᱞᱟᱦᱟ ᱪᱟᱞᱟᱣ ᱠᱟᱛᱮ ᱟᱢ ᱟᱞᱮᱭᱟᱜ ᱥᱮᱵᱟ ᱱᱮᱢ ᱟᱨ ᱩᱠᱩ ᱱᱤᱛᱤ ᱨᱮ ᱨᱟᱡᱤ ᱠᱟᱱᱟᱢ᱾';

  @override
  String get otpTitle => 'ᱱᱚᱶᱟ ᱟᱢᱜᱮ ᱠᱟᱱᱟ ᱡᱟᱸᱪ ᱢᱮ';

  @override
  String otpSubtitle(String target) {
    return '$target ᱛᱮ ᱠᱩᱞ ᱟᱠᱟᱱ 6 ᱮᱞ ᱠᱳᱰ ᱚᱞ ᱢᱮ';
  }

  @override
  String get verifyCode => 'ᱡᱟᱸᱪ ᱢᱮ';

  @override
  String get resendCode => 'ᱠᱳᱰ ᱫᱩᱦᱲᱟᱹ ᱠᱩᱞ ᱢᱮ';

  @override
  String resendCodeIn(int seconds) {
    return '$seconds ᱥᱮᱠᱮᱱᱰ ᱨᱮ ᱫᱩᱦᱲᱟᱹ ᱠᱩᱞ ᱢᱮ';
  }

  @override
  String get codeResent => 'ᱱᱟᱶᱟ ᱠᱳᱰ ᱠᱩᱞ ᱮᱱᱟ';

  @override
  String get incorrectCode => 'ᱱᱚᱶᱟ ᱠᱳᱰ ᱵᱟᱝ ᱴᱷᱤᱠᱟ ᱵᱟᱝᱠᱷᱟᱱ ᱚᱠᱛᱚ ᱪᱟᱵᱟ ᱮᱱᱟ᱾ ᱱᱟᱶᱟ ᱠᱳᱰ ᱢᱟᱹᱜ ᱢᱮ᱾';

  @override
  String get enterFullCode => 'ᱯᱩᱨᱟᱹ 6 ᱮᱞ ᱚᱞ ᱢᱮ';

  @override
  String get accountSuspended => 'ᱱᱚᱶᱟ ᱠᱷᱟᱛᱟ ᱵᱚᱸᱫ ᱠᱟᱱᱟ᱾ ᱫᱟᱭᱟ ᱠᱟᱛᱮ ᱜᱚᱲᱚ ᱥᱟᱶ ᱡᱚᱲᱟᱣ ᱢᱮ᱾';

  @override
  String get tooManyAttempts => 'ᱟᱫᱚᱢ ᱛᱟᱞᱟᱛᱮ ᱠᱩᱨᱩᱢᱩᱴᱩ ᱮᱱᱟ᱾ ᱫᱟᱭᱟ ᱠᱟᱛᱮ ᱛᱤᱸᱜᱩ ᱚᱠᱛᱚ ᱛᱟᱭᱚᱢ ᱫᱩᱦᱲᱟᱹ ᱠᱩᱨᱩᱢᱩᱴᱩ ᱢᱮ᱾';

  @override
  String get sessionExpired => 'ᱟᱢᱟᱜ ᱥᱮᱥᱚᱱ ᱪᱟᱵᱟ ᱮᱱᱟ᱾ ᱫᱟᱭᱟ ᱠᱟᱛᱮ ᱫᱩᱦᱲᱟᱹ ᱥᱟᱭᱤᱱ ᱤᱱ ᱢᱮ᱾';

  @override
  String get networkError => 'ᱤᱱᱴᱟᱨᱱᱮᱴ ᱡᱚᱲᱟᱣ ᱵᱟᱹᱱᱩᱜ-ᱟ᱾ ᱡᱚᱲᱟᱣ ᱧᱮᱞ ᱠᱟᱛᱮ ᱫᱩᱦᱲᱟᱹ ᱠᱩᱨᱩᱢᱩᱴᱩ ᱢᱮ᱾';

  @override
  String get developmentCode => 'ᱰᱮᱵᱷᱞᱚᱯᱢᱮᱱᱴ ᱠᱳᱰ';

  @override
  String get signOut => 'ᱥᱟᱭᱤᱱ ᱟᱣᱴ';

  @override
  String get signedOut => 'ᱟᱢ ᱥᱟᱭᱤᱱ ᱟᱣᱴ ᱮᱱᱟᱢ';

  @override
  String get somethingWentWrong => 'ᱚᱠᱟ ᱦᱚᱸ ᱵᱷᱩᱞ ᱮᱱᱟ᱾ ᱫᱟᱭᱟ ᱠᱟᱛᱮ ᱫᱩᱦᱲᱟᱹ ᱠᱩᱨᱩᱢᱩᱴᱩ ᱢᱮ᱾';

  @override
  String get profileTitle => 'ᱯᱨᱚᱯᱷᱟᱭᱤᱞ';

  @override
  String get viewProfile => 'ᱯᱨᱚᱯᱷᱟᱭᱤᱞ ᱧᱮᱞ ᱢᱮ';

  @override
  String get nameLabel => 'ᱧᱩᱛᱩᱢ';

  @override
  String get emailLabel => 'ᱤᱢᱮᱞ';

  @override
  String get mobileLabel => 'ᱢᱚᱵᱟᱭᱤᱞ ᱱᱟᱢᱵᱟᱨ';

  @override
  String get accountStatusLabel => 'ᱠᱷᱟᱛᱟ ᱫᱚᱥᱟ';

  @override
  String get statusActive => 'ᱪᱟᱹᱞᱩ';

  @override
  String get statusPending => 'ᱛᱟᱸᱜᱤ ᱟᱠᱟᱱ';

  @override
  String get statusSuspended => 'ᱵᱚᱸᱫ ᱟᱠᱟᱱ';

  @override
  String get verifiedLabel => 'ᱡᱟᱸᱪ ᱟᱠᱟᱱ';

  @override
  String get notProvided => 'ᱵᱟᱝ ᱥᱮᱞᱮᱫ ᱟᱠᱟᱱᱟ';

  @override
  String get retry => 'ᱫᱩᱦᱲᱟᱹ ᱠᱩᱨᱩᱢᱩᱴᱩ ᱢᱮ';

  @override
  String get loginRiderNote => 'This app is for Nexmile delivery partners.';

  @override
  String get checkingYourAccount => 'Checking your account';

  @override
  String get couldNotLoadAccount => 'We could not load your account. Check your connection and try again.';

  @override
  String get notARiderAccountTitle => 'This is not a delivery partner account';

  @override
  String get notARiderAccount => 'This email or mobile number is already registered on another Nexmile account. Sign out and use a different one to join as a delivery partner.';

  @override
  String notARiderAccountFor(String role) {
    return 'This email or mobile number is already registered as a Nexmile $role. Sign out and use a different one to join as a delivery partner.';
  }

  @override
  String get roleCustomer => 'customer';

  @override
  String get roleMerchant => 'merchant';

  @override
  String get roleAdmin => 'administrator';

  @override
  String get useAnotherAccount => 'Use another account';

  @override
  String get onboardingTitle => 'Become a Nexmile partner';

  @override
  String get onboardingSubtitle => 'A few details and your documents, then our team verifies you. It usually takes up to two working days.';

  @override
  String stepOfSteps(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get stepIdentityTitle => 'About you';

  @override
  String get stepIdentitySubtitle => 'Enter your name exactly as it appears on your Aadhaar card.';

  @override
  String get stepVehicleTitle => 'Your vehicle';

  @override
  String get stepVehicleSubtitle => 'Tell us what you ride and the number plate it carries.';

  @override
  String get stepIdentityNumbersTitle => 'Identity numbers';

  @override
  String get stepIdentityNumbersSubtitle => 'These must match the documents you upload later.';

  @override
  String get stepLicenceTitle => 'Licence and insurance';

  @override
  String get stepLicenceSubtitle => 'Both must be valid on the day you start delivering.';

  @override
  String get stepBankTitle => 'Where you get paid';

  @override
  String get stepBankSubtitle => 'Your earnings are settled to this account. Check it carefully.';

  @override
  String get stepDocumentsTitle => 'Your documents';

  @override
  String get stepDocumentsSubtitle => 'Photograph each one in good light. JPG, PNG or PDF, up to 5 MB each.';

  @override
  String get stepReviewTitle => 'Check and submit';

  @override
  String get stepReviewSubtitle => 'Once you submit, your details are locked until our team has reviewed them.';

  @override
  String get saveAndContinue => 'Save and continue';

  @override
  String get backLabel => 'Back';

  @override
  String get fullNameLabel => 'Full name';

  @override
  String get fullNameHint => 'As printed on your Aadhaar';

  @override
  String get dateOfBirthLabel => 'Date of birth';

  @override
  String get selectDate => 'Select a date';

  @override
  String get vehicleTypeLabel => 'Vehicle type';

  @override
  String get vehicleMotorcycle => 'Motorcycle';

  @override
  String get vehicleScooter => 'Scooter';

  @override
  String get vehicleEv => 'Electric vehicle';

  @override
  String get vehicleBicycle => 'Bicycle';

  @override
  String get vehicleNumberLabel => 'Vehicle number';

  @override
  String get vehicleNumberHint => 'TN01AB1234';

  @override
  String get rcNumberLabel => 'RC number';

  @override
  String get aadhaarLabel => 'Aadhaar number';

  @override
  String get aadhaarHint => '12 digits';

  @override
  String get panLabel => 'PAN';

  @override
  String get panHint => 'ABCDE1234F';

  @override
  String get drivingLicenceNoLabel => 'Driving licence number';

  @override
  String get drivingLicenceExpiryLabel => 'Licence valid until';

  @override
  String get insuranceNumberLabel => 'Insurance policy number';

  @override
  String get insuranceExpiryLabel => 'Insurance valid until';

  @override
  String get bankAccountNameLabel => 'Account holder name';

  @override
  String get bankAccountNumberLabel => 'Account number';

  @override
  String get bankIfscLabel => 'IFSC code';

  @override
  String get bankIfscHint => 'SBIN0001234';

  @override
  String documentsProgress(int done, int total) {
    return '$done of $total uploaded';
  }

  @override
  String get uploadDocument => 'Upload';

  @override
  String get replaceDocument => 'Replace';

  @override
  String get removeDocument => 'Remove';

  @override
  String get takePhoto => 'Take a photo';

  @override
  String get chooseFromGallery => 'Choose from gallery';

  @override
  String get chooseFile => 'Choose a file';

  @override
  String get uploadingLabel => 'Uploading';

  @override
  String get documentRejected => 'Rejected';

  @override
  String get documentUploaded => 'Uploaded';

  @override
  String get documentApproved => 'Approved';

  @override
  String get documentRequired => 'Required';

  @override
  String get documentOptional => 'Optional';

  @override
  String get fileTooLarge => 'That file is over 5 MB. Try a photo instead of a scan.';

  @override
  String get unsupportedFileType => 'Choose a JPG, PNG or PDF.';

  @override
  String get pickerUnavailable => 'We could not open that. Check the app\'s camera and photo permissions.';

  @override
  String get uploadFailed => 'That upload did not go through. Please try again.';

  @override
  String get submitForVerification => 'Submit for verification';

  @override
  String get submitConfirmTitle => 'Submit for verification?';

  @override
  String get submitConfirmBody => 'Your details and documents will be locked while our team reviews them. You cannot change them until a decision is made.';

  @override
  String get cancelLabel => 'Cancel';

  @override
  String get completeEverythingBeforeSubmitting => 'Finish every step and upload all the documents before submitting.';

  @override
  String get checkTheHighlightedFields => 'Check the highlighted fields and try again.';

  @override
  String get underReviewTitle => 'We are verifying your documents';

  @override
  String get underReviewBody => 'Our team usually reviews within two working days. We will let you know as soon as you are approved.';

  @override
  String get checkAgain => 'Check again';

  @override
  String get stillUnderReview => 'Still under review';

  @override
  String get rejectedTitle => 'We could not verify you';

  @override
  String get rejectedBody => 'Fix what our team noted below, then send your documents again.';

  @override
  String get rejectionReasonLabel => 'Reason';

  @override
  String get fixAndResubmit => 'Fix and submit again';

  @override
  String get blockedTitle => 'You cannot go online yet';

  @override
  String get documentsExpiredMessage => 'Your licence or insurance has expired. Upload current documents to go online.';

  @override
  String get awaitingVerificationMessage => 'Your documents are still being verified.';

  @override
  String get updateDocuments => 'Update documents';

  @override
  String get riderHomeTitle => 'Ready to ride';

  @override
  String get riderHomeSubtitle => 'Go online and we will send you nearby deliveries.';

  @override
  String get dutyStatusLabel => 'Duty status';

  @override
  String get dutyOnline => 'Online';

  @override
  String get dutyOffline => 'Offline';

  @override
  String get dutyOnBreak => 'On a break';

  @override
  String get goOnline => 'Go online';

  @override
  String get goOffline => 'Go offline';

  @override
  String get takeABreak => 'Take a break';

  @override
  String get waitingForOrders => 'Waiting for orders nearby';

  @override
  String get youAreOffline => 'You are offline. No deliveries will be sent to you.';

  @override
  String get completedDeliveriesLabel => 'Deliveries completed';

  @override
  String get ratingLabel => 'Rating';

  @override
  String get notRatedYet => 'Not rated yet';

  @override
  String get vehicleLabel => 'Vehicle';

  @override
  String get kycStatusLabel => 'Verification';

  @override
  String get kycPending => 'Not submitted';

  @override
  String get kycSubmitted => 'Under review';

  @override
  String get kycVerified => 'Approved';

  @override
  String get kycRejected => 'Rejected';

  @override
  String get fieldRequired => 'This is required';

  @override
  String get invalidAadhaar => 'Enter the 12 digits of your Aadhaar number';

  @override
  String get invalidPan => 'Enter a valid PAN, like ABCDE1234F';

  @override
  String get invalidIfsc => 'Enter a valid IFSC code, like SBIN0001234';

  @override
  String get invalidVehicleNumber => 'Enter the number exactly as it appears on the plate';

  @override
  String get invalidAccountNumber => 'Enter a valid account number';

  @override
  String get dateMustBeFuture => 'This date has already passed';

  @override
  String get mustBeEighteen => 'You must be at least 18 years old to deliver';

  @override
  String get docAadhaarFront => 'Aadhaar card (front)';

  @override
  String get docAadhaarBack => 'Aadhaar card (back)';

  @override
  String get docDrivingLicence => 'Driving licence';

  @override
  String get docVehicleRc => 'Vehicle registration certificate';

  @override
  String get docInsurance => 'Vehicle insurance';

  @override
  String get docProfilePhoto => 'Profile photo';

  @override
  String get docPan => 'PAN card';

  @override
  String get docBankProof => 'Cancelled cheque or bank statement';
}
