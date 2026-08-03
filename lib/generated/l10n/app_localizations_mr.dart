// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Marathi (`mr`).
class AppLocalizationsMr extends AppLocalizations {
  AppLocalizationsMr([String locale = 'mr']) : super(locale);

  @override
  String get appName => 'Nexmile Rider';

  @override
  String get tagline => 'जलद डिलिव्हरी. ताजे स्मित.';

  @override
  String get chooseLanguageTitle => 'तुमची भाषा निवडा';

  @override
  String get chooseLanguageSubtitle => 'तुम्हाला सोयीची वाटेल ती भाषा निवडा. तुम्ही ती कधीही सेटिंग्जमध्ये बदलू शकता.';

  @override
  String get searchLanguageHint => 'भाषा शोधा';

  @override
  String get noLanguageFound => 'कोणतीही भाषा सापडली नाही';

  @override
  String languagesAvailable(int count) {
    return '$count भाषा उपलब्ध आहेत';
  }

  @override
  String get continueLabel => 'पुढे चला';

  @override
  String get selectedLabel => 'निवडलेली';

  @override
  String get defaultLabel => 'डीफॉल्ट';

  @override
  String get homeTitle => 'Nexmile मध्ये आपले स्वागत आहे';

  @override
  String get homeSubtitle => 'ताजा किराणा, गरम जेवण आणि दैनंदिन गरजा तुमच्या जवळच्या दुकानांमधून.';

  @override
  String get changeLanguage => 'भाषा बदला';

  @override
  String get languageUpdated => 'भाषा बदलली';

  @override
  String get appLanguageLabel => 'ॲपची भाषा';

  @override
  String greetingNamed(String name) {
    return 'नमस्कार, $name';
  }

  @override
  String get loginTitle => 'Nexmile मध्ये साइन इन करा';

  @override
  String get loginSubtitle => 'तुमचा ईमेल किंवा मोबाइल क्रमांक टाका, आम्ही पडताळणी कोड पाठवू.';

  @override
  String get emailOrPhoneLabel => 'ईमेल किंवा मोबाइल क्रमांक';

  @override
  String get emailOrPhoneHint => 'name@example.com किंवा 9876543210';

  @override
  String get invalidEmailOrPhone => 'वैध ईमेल पत्ता किंवा 10 अंकी मोबाइल क्रमांक टाका';

  @override
  String get sendCode => 'कोड पाठवा';

  @override
  String get agreeToTermsOnContinue => 'पुढे जाऊन तुम्ही आमच्या सेवा अटी आणि गोपनीयता धोरणाशी सहमत होता.';

  @override
  String get otpTitle => 'तुम्हीच आहात याची खात्री करा';

  @override
  String otpSubtitle(String target) {
    return '$target वर पाठवलेला 6 अंकी कोड टाका';
  }

  @override
  String get verifyCode => 'पडताळा';

  @override
  String get resendCode => 'कोड पुन्हा पाठवा';

  @override
  String resendCodeIn(int seconds) {
    return '$seconds सेकंदांत पुन्हा पाठवा';
  }

  @override
  String get codeResent => 'नवीन कोड पाठवला आहे';

  @override
  String get incorrectCode => 'हा कोड चुकीचा आहे किंवा त्याची मुदत संपली आहे. नवीन कोड मागवा.';

  @override
  String get enterFullCode => 'पूर्ण 6 अंक टाका';

  @override
  String get accountSuspended => 'हे खाते निलंबित करण्यात आले आहे. कृपया सहाय्यताशी संपर्क साधा.';

  @override
  String get tooManyAttempts => 'खूप वेळा प्रयत्न झाले. कृपया थोड्या वेळाने पुन्हा प्रयत्न करा.';

  @override
  String get sessionExpired => 'तुमचे सत्र संपले आहे. कृपया पुन्हा साइन इन करा.';

  @override
  String get networkError => 'इंटरनेट कनेक्शन नाही. तुमचे कनेक्शन तपासा आणि पुन्हा प्रयत्न करा.';

  @override
  String get developmentCode => 'डेव्हलपमेंट कोड';

  @override
  String get signOut => 'साइन आउट';

  @override
  String get signedOut => 'तुम्ही साइन आउट झाला आहात';

  @override
  String get somethingWentWrong => 'काहीतरी चूक झाली. पुन्हा प्रयत्न करा.';

  @override
  String get profileTitle => 'प्रोफाइल';

  @override
  String get viewProfile => 'प्रोफाइल पहा';

  @override
  String get nameLabel => 'नाव';

  @override
  String get emailLabel => 'ईमेल';

  @override
  String get mobileLabel => 'मोबाइल क्रमांक';

  @override
  String get accountStatusLabel => 'खात्याची स्थिती';

  @override
  String get statusActive => 'सक्रिय';

  @override
  String get statusPending => 'प्रलंबित';

  @override
  String get statusSuspended => 'निलंबित';

  @override
  String get verifiedLabel => 'पडताळलेले';

  @override
  String get notProvided => 'जोडलेले नाही';

  @override
  String get retry => 'पुन्हा प्रयत्न करा';

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
