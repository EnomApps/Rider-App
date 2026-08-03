// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Kashmiri (`ks`).
class AppLocalizationsKs extends AppLocalizations {
  AppLocalizationsKs([String locale = 'ks']) : super(locale);

  @override
  String get appName => 'Nexmile Rider';

  @override
  String get tagline => 'تیز ڈیلیوری۔ تازٕ مُسکراہٹ۔';

  @override
  String get chooseLanguageTitle => 'پنُن زبان ژارٕو';

  @override
  String get chooseLanguageSubtitle => 'یِم زبان چھِوٕ آسان محسوس کران سُہ ژارٕو۔ توہہِ ہیٚکِو یہ کُنہِ وقتہٕ سیٹِنگز منٛز بدلاوِتھ۔';

  @override
  String get searchLanguageHint => 'زبان ژھانڈٕو';

  @override
  String get noLanguageFound => 'کانہہ زبان نہ لبنہٕ آیہ';

  @override
  String languagesAvailable(int count) {
    return '$count زباناہ چھِ دستیاب';
  }

  @override
  String get continueLabel => 'برونہہ گژھِو';

  @override
  String get selectedLabel => 'ژارنہٕ آمُت';

  @override
  String get defaultLabel => 'ڈیفالٹ';

  @override
  String get homeTitle => 'Nexmile منٛز خوش آمدید';

  @override
  String get homeSubtitle => 'تازٕ گروسری، گرٕم کھَنہٕ تہٕ روزمرٕ ضرورتہٕ توہنٛدِن نزدیٚکی دُکانن پؠٹھٕ۔';

  @override
  String get changeLanguage => 'زبان بدلاوٕو';

  @override
  String get languageUpdated => 'زبان آیہ بدلاونہٕ';

  @override
  String get appLanguageLabel => 'ایپ زبان';

  @override
  String greetingNamed(String name) {
    return 'آداب، $name';
  }

  @override
  String get loginTitle => 'Nexmile منٛز سائن اِن کرِو';

  @override
  String get loginSubtitle => 'پنُن ای میل یا موبائل نمبر لیٚکھِو، اسہٕ سوزو توہہِ تصدیقی کوڈ۔';

  @override
  String get emailOrPhoneLabel => 'ای میل یا موبائل نمبر';

  @override
  String get emailOrPhoneHint => 'name@example.com یا 9876543210';

  @override
  String get invalidEmailOrPhone => 'صحیح ای میل پتہٕ یا 10 ہندسن ہُند موبائل نمبر لیٚکھِو';

  @override
  String get sendCode => 'کوڈ سوزِو';

  @override
  String get agreeToTermsOnContinue => 'برونہہ گژھِتھ چھِوٕ توہہِ ساني سروس شرطن تہٕ پرائیویسی پالیسی سٕتؠ رٲضی گژھان۔';

  @override
  String get otpTitle => 'تصدیق کرِو زِ یہ چھِوٕ توہہِ';

  @override
  String otpSubtitle(String target) {
    return '$target پؠٹھٕ سوزنہٕ آمُت 6 ہندسن ہُند کوڈ لیٚکھِو';
  }

  @override
  String get verifyCode => 'تصدیق کرِو';

  @override
  String get resendCode => 'کوڈ دوبارٕ سوزِو';

  @override
  String resendCodeIn(int seconds) {
    return '$seconds سیکنڈن منٛز دوبارٕ سوزِو';
  }

  @override
  String get codeResent => 'نوٚو کوڈ آو سوزنہٕ';

  @override
  String get incorrectCode => 'یہ کوڈ چھُ غلط یا اَمِ ہُند وقت چھُ گۆمُت۔ نوٚو کوڈ ژھۆنڈِو۔';

  @override
  String get enterFullCode => 'پورٕ 6 ہندسہٕ لیٚکھِو';

  @override
  String get accountSuspended => 'یہ کھاتہٕ چھُ معطل کرنہٕ آمُت۔ مہربٲنی کٔرِتھ سپورٹ سٕتؠ رٲبطہٕ کرِو۔';

  @override
  String get tooManyAttempts => 'زیادٕ کوششہٕ آیہ کرنہٕ۔ مہربٲنی کٔرِتھ کینٛہہ وقتہٕ پتہٕ دوبارٕ کوشش کرِو۔';

  @override
  String get sessionExpired => 'توہنٛد سیشن چھُ ختم گۆمُت۔ مہربٲنی کٔرِتھ دوبارٕ سائن اِن کرِو۔';

  @override
  String get networkError => 'انٹرنیٹ کنکشن چھُ نہ۔ پنُن کنکشن چیک کٔرِتھ دوبارٕ کوشش کرِو۔';

  @override
  String get developmentCode => 'ڈیویلپمنٹ کوڈ';

  @override
  String get signOut => 'سائن آوٹ';

  @override
  String get signedOut => 'توہہِ چھِوٕ سائن آوٹ گژھمٕتؠ';

  @override
  String get somethingWentWrong => 'کینٛہہ غلط گو۔ مہربٲنی کٔرِتھ دوبارٕ کوشش کرِو۔';

  @override
  String get profileTitle => 'پروفائل';

  @override
  String get viewProfile => 'پروفائل وُچھِو';

  @override
  String get nameLabel => 'ناو';

  @override
  String get emailLabel => 'ای میل';

  @override
  String get mobileLabel => 'موبائل نمبر';

  @override
  String get accountStatusLabel => 'کھاتہٕ حالت';

  @override
  String get statusActive => 'فعال';

  @override
  String get statusPending => 'زیرِ التوا';

  @override
  String get statusSuspended => 'معطل';

  @override
  String get verifiedLabel => 'تصدیق شُدٕ';

  @override
  String get notProvided => 'شٲمِل کرنہٕ نہ آمُت';

  @override
  String get retry => 'دوبارٕ کوشش کرِو';

  @override
  String get loginRiderNote => 'This app is for Nexmile delivery partners.';

  @override
  String get checkingYourAccount => 'Checking your account';

  @override
  String get couldNotLoadAccount => 'We could not load your account. Check your connection and try again.';

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
