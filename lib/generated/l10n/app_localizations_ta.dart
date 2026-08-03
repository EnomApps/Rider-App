// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get appName => 'Nexmile Rider';

  @override
  String get tagline => 'விரைவான டெலிவரி. புத்துணர்ச்சியான புன்னகை.';

  @override
  String get chooseLanguageTitle => 'உங்கள் மொழியைத் தேர்ந்தெடுக்கவும்';

  @override
  String get chooseLanguageSubtitle => 'உங்களுக்கு வசதியான மொழியைத் தேர்ந்தெடுக்கவும். அமைப்புகளில் எப்போது வேண்டுமானாலும் இதை மாற்றலாம்.';

  @override
  String get searchLanguageHint => 'மொழியைத் தேடுங்கள்';

  @override
  String get noLanguageFound => 'மொழி எதுவும் கிடைக்கவில்லை';

  @override
  String languagesAvailable(int count) {
    return '$count மொழிகள் உள்ளன';
  }

  @override
  String get continueLabel => 'தொடரவும்';

  @override
  String get selectedLabel => 'தேர்ந்தெடுக்கப்பட்டது';

  @override
  String get defaultLabel => 'இயல்பு';

  @override
  String get homeTitle => 'Nexmile-க்கு வரவேற்கிறோம்';

  @override
  String get homeSubtitle => 'புதிய மளிகைப் பொருட்கள், சூடான உணவு மற்றும் அன்றாடத் தேவைகள் உங்கள் அருகிலுள்ள கடைகளிலிருந்து.';

  @override
  String get changeLanguage => 'மொழியை மாற்று';

  @override
  String get languageUpdated => 'மொழி மாற்றப்பட்டது';

  @override
  String get appLanguageLabel => 'செயலி மொழி';

  @override
  String greetingNamed(String name) {
    return 'வணக்கம், $name';
  }

  @override
  String get loginTitle => 'Nexmile-இல் உள்நுழையவும்';

  @override
  String get loginSubtitle => 'உங்கள் மின்னஞ்சல் அல்லது கைபேசி எண்ணை உள்ளிடுங்கள், சரிபார்ப்புக் குறியீட்டை அனுப்புகிறோம்.';

  @override
  String get emailOrPhoneLabel => 'மின்னஞ்சல் அல்லது கைபேசி எண்';

  @override
  String get emailOrPhoneHint => 'name@example.com அல்லது 9876543210';

  @override
  String get invalidEmailOrPhone => 'சரியான மின்னஞ்சல் முகவரி அல்லது 10 இலக்க கைபேசி எண்ணை உள்ளிடவும்';

  @override
  String get sendCode => 'குறியீட்டை அனுப்பு';

  @override
  String get agreeToTermsOnContinue => 'தொடர்வதன் மூலம், எங்கள் சேவை விதிமுறைகள் மற்றும் தனியுரிமைக் கொள்கையை ஏற்கிறீர்கள்.';

  @override
  String get otpTitle => 'நீங்கள்தான் என உறுதிப்படுத்துங்கள்';

  @override
  String otpSubtitle(String target) {
    return '$target க்கு அனுப்பிய 6 இலக்கக் குறியீட்டை உள்ளிடவும்';
  }

  @override
  String get verifyCode => 'சரிபார்க்கவும்';

  @override
  String get resendCode => 'குறியீட்டை மீண்டும் அனுப்பு';

  @override
  String resendCodeIn(int seconds) {
    return '$seconds வினாடிகளில் மீண்டும் அனுப்பலாம்';
  }

  @override
  String get codeResent => 'புதிய குறியீடு அனுப்பப்பட்டது';

  @override
  String get incorrectCode => 'இந்தக் குறியீடு தவறானது அல்லது காலாவதியாகிவிட்டது. புதியதைக் கோரவும்.';

  @override
  String get enterFullCode => '6 இலக்கங்களையும் உள்ளிடவும்';

  @override
  String get accountSuspended => 'இந்தக் கணக்கு இடைநிறுத்தப்பட்டுள்ளது. ஆதரவைத் தொடர்பு கொள்ளவும்.';

  @override
  String get tooManyAttempts => 'பல முறை முயற்சித்துவிட்டீர்கள். சிறிது நேரம் கழித்து மீண்டும் முயற்சிக்கவும்.';

  @override
  String get sessionExpired => 'உங்கள் அமர்வு காலாவதியாகிவிட்டது. மீண்டும் உள்நுழையவும்.';

  @override
  String get networkError => 'இணைய இணைப்பு இல்லை. உங்கள் இணைப்பைச் சரிபார்த்து மீண்டும் முயற்சிக்கவும்.';

  @override
  String get developmentCode => 'டெவலப்மென்ட் குறியீடு';

  @override
  String get signOut => 'வெளியேறு';

  @override
  String get signedOut => 'நீங்கள் வெளியேறிவிட்டீர்கள்';

  @override
  String get somethingWentWrong => 'ஏதோ தவறு நடந்தது. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get profileTitle => 'சுயவிவரம்';

  @override
  String get viewProfile => 'சுயவிவரத்தைப் பார்';

  @override
  String get nameLabel => 'பெயர்';

  @override
  String get emailLabel => 'மின்னஞ்சல்';

  @override
  String get mobileLabel => 'கைபேசி எண்';

  @override
  String get accountStatusLabel => 'கணக்கு நிலை';

  @override
  String get statusActive => 'செயலில்';

  @override
  String get statusPending => 'நிலுவையில்';

  @override
  String get statusSuspended => 'இடைநிறுத்தப்பட்டது';

  @override
  String get verifiedLabel => 'சரிபார்க்கப்பட்டது';

  @override
  String get notProvided => 'சேர்க்கப்படவில்லை';

  @override
  String get retry => 'மீண்டும் முயற்சிக்கவும்';

  @override
  String get loginRiderNote => 'இந்த ஆப் நெக்ஸ்மைல் டெலிவரி பார்ட்னர்களுக்கானது.';

  @override
  String get checkingYourAccount => 'உங்கள் கணக்கைச் சரிபார்க்கிறோம்';

  @override
  String get couldNotLoadAccount => 'உங்கள் கணக்கை ஏற்ற முடியவில்லை. இணைப்பைச் சரிபார்த்து மீண்டும் முயற்சிக்கவும்.';

  @override
  String get onboardingTitle => 'நெக்ஸ்மைல் பார்ட்னராகுங்கள்';

  @override
  String get onboardingSubtitle => 'சில விவரங்கள் மற்றும் உங்கள் ஆவணங்கள், பிறகு எங்கள் குழு உங்களைச் சரிபார்க்கும். பொதுவாக இரண்டு வேலை நாட்கள் ஆகும்.';

  @override
  String stepOfSteps(int current, int total) {
    return 'படி $current / $total';
  }

  @override
  String get stepIdentityTitle => 'உங்களைப் பற்றி';

  @override
  String get stepIdentitySubtitle => 'உங்கள் ஆதார் அட்டையில் உள்ளபடியே பெயரை உள்ளிடவும்.';

  @override
  String get stepVehicleTitle => 'உங்கள் வாகனம்';

  @override
  String get stepVehicleSubtitle => 'நீங்கள் ஓட்டும் வாகனத்தையும் அதன் பதிவு எண்ணையும் தெரிவிக்கவும்.';

  @override
  String get stepIdentityNumbersTitle => 'அடையாள எண்கள்';

  @override
  String get stepIdentityNumbersSubtitle => 'நீங்கள் பிறகு பதிவேற்றும் ஆவணங்களுடன் இவை பொருந்த வேண்டும்.';

  @override
  String get stepLicenceTitle => 'உரிமம் மற்றும் காப்பீடு';

  @override
  String get stepLicenceSubtitle => 'நீங்கள் டெலிவரி தொடங்கும் நாளில் இரண்டும் செல்லுபடியாக இருக்க வேண்டும்.';

  @override
  String get stepBankTitle => 'பணம் பெறும் இடம்';

  @override
  String get stepBankSubtitle => 'உங்கள் வருமானம் இந்தக் கணக்கிற்கே வரும். கவனமாகச் சரிபார்க்கவும்.';

  @override
  String get stepDocumentsTitle => 'உங்கள் ஆவணங்கள்';

  @override
  String get stepDocumentsSubtitle => 'நல்ல வெளிச்சத்தில் ஒவ்வொன்றையும் புகைப்படம் எடுக்கவும். JPG, PNG அல்லது PDF, ஒவ்வொன்றும் 5 MB வரை.';

  @override
  String get stepReviewTitle => 'சரிபார்த்து அனுப்பவும்';

  @override
  String get stepReviewSubtitle => 'அனுப்பியவுடன், எங்கள் குழு பரிசீலிக்கும் வரை உங்கள் விவரங்கள் பூட்டப்படும்.';

  @override
  String get saveAndContinue => 'சேமித்துத் தொடரவும்';

  @override
  String get backLabel => 'பின்செல்';

  @override
  String get fullNameLabel => 'முழுப் பெயர்';

  @override
  String get fullNameHint => 'ஆதாரில் அச்சிடப்பட்டுள்ளபடி';

  @override
  String get dateOfBirthLabel => 'பிறந்த தேதி';

  @override
  String get selectDate => 'தேதியைத் தேர்ந்தெடுக்கவும்';

  @override
  String get vehicleTypeLabel => 'வாகன வகை';

  @override
  String get vehicleMotorcycle => 'மோட்டார் சைக்கிள்';

  @override
  String get vehicleScooter => 'ஸ்கூட்டர்';

  @override
  String get vehicleEv => 'மின்சார வாகனம்';

  @override
  String get vehicleBicycle => 'சைக்கிள்';

  @override
  String get vehicleNumberLabel => 'வாகன எண்';

  @override
  String get vehicleNumberHint => 'TN01AB1234';

  @override
  String get rcNumberLabel => 'RC எண்';

  @override
  String get aadhaarLabel => 'ஆதார் எண்';

  @override
  String get aadhaarHint => '12 இலக்கங்கள்';

  @override
  String get panLabel => 'பான் (PAN)';

  @override
  String get panHint => 'ABCDE1234F';

  @override
  String get drivingLicenceNoLabel => 'ஓட்டுநர் உரிம எண்';

  @override
  String get drivingLicenceExpiryLabel => 'உரிமம் செல்லுபடியாகும் தேதி';

  @override
  String get insuranceNumberLabel => 'காப்பீட்டுப் பாலிசி எண்';

  @override
  String get insuranceExpiryLabel => 'காப்பீடு செல்லுபடியாகும் தேதி';

  @override
  String get bankAccountNameLabel => 'கணக்கு வைத்திருப்பவர் பெயர்';

  @override
  String get bankAccountNumberLabel => 'கணக்கு எண்';

  @override
  String get bankIfscLabel => 'IFSC குறியீடு';

  @override
  String get bankIfscHint => 'SBIN0001234';

  @override
  String documentsProgress(int done, int total) {
    return '$total இல் $done பதிவேற்றப்பட்டது';
  }

  @override
  String get uploadDocument => 'பதிவேற்று';

  @override
  String get replaceDocument => 'மாற்று';

  @override
  String get removeDocument => 'நீக்கு';

  @override
  String get takePhoto => 'புகைப்படம் எடுக்கவும்';

  @override
  String get chooseFromGallery => 'கேலரியிலிருந்து தேர்ந்தெடுக்கவும்';

  @override
  String get chooseFile => 'கோப்பைத் தேர்ந்தெடுக்கவும்';

  @override
  String get uploadingLabel => 'பதிவேற்றுகிறது';

  @override
  String get documentRejected => 'நிராகரிக்கப்பட்டது';

  @override
  String get documentUploaded => 'பதிவேற்றப்பட்டது';

  @override
  String get documentApproved => 'ஏற்கப்பட்டது';

  @override
  String get documentRequired => 'தேவை';

  @override
  String get fileTooLarge => 'அந்தக் கோப்பு 5 MB-ஐ விட பெரியது. ஸ்கேனுக்குப் பதிலாக புகைப்படத்தை முயற்சிக்கவும்.';

  @override
  String get unsupportedFileType => 'JPG, PNG அல்லது PDF கோப்பைத் தேர்ந்தெடுக்கவும்.';

  @override
  String get pickerUnavailable => 'அதைத் திறக்க முடியவில்லை. ஆப்பின் கேமரா மற்றும் புகைப்பட அனுமதிகளைச் சரிபார்க்கவும்.';

  @override
  String get uploadFailed => 'அந்தப் பதிவேற்றம் நிறைவடையவில்லை. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get submitForVerification => 'சரிபார்ப்புக்கு அனுப்பவும்';

  @override
  String get submitConfirmTitle => 'சரிபார்ப்புக்கு அனுப்பலாமா?';

  @override
  String get submitConfirmBody => 'எங்கள் குழு பரிசீலிக்கும் வரை உங்கள் விவரங்களும் ஆவணங்களும் பூட்டப்படும். முடிவு வரும் வரை அவற்றை மாற்ற முடியாது.';

  @override
  String get cancelLabel => 'ரத்து';

  @override
  String get completeEverythingBeforeSubmitting => 'அனுப்பும் முன் எல்லாப் படிகளையும் முடித்து, எல்லா ஆவணங்களையும் பதிவேற்றவும்.';

  @override
  String get checkTheHighlightedFields => 'குறிக்கப்பட்ட புலங்களைச் சரிபார்த்து மீண்டும் முயற்சிக்கவும்.';

  @override
  String get underReviewTitle => 'உங்கள் ஆவணங்களைச் சரிபார்க்கிறோம்';

  @override
  String get underReviewBody => 'எங்கள் குழு பொதுவாக இரண்டு வேலை நாட்களுக்குள் பரிசீலிக்கும். நீங்கள் ஏற்கப்பட்டவுடன் தெரிவிப்போம்.';

  @override
  String get checkAgain => 'மீண்டும் சரிபார்க்கவும்';

  @override
  String get stillUnderReview => 'இன்னும் பரிசீலனையில் உள்ளது';

  @override
  String get rejectedTitle => 'உங்களைச் சரிபார்க்க முடியவில்லை';

  @override
  String get rejectedBody => 'கீழே எங்கள் குழு குறிப்பிட்டதைச் சரிசெய்து, ஆவணங்களை மீண்டும் அனுப்பவும்.';

  @override
  String get rejectionReasonLabel => 'காரணம்';

  @override
  String get fixAndResubmit => 'சரிசெய்து மீண்டும் அனுப்பவும்';

  @override
  String get blockedTitle => 'நீங்கள் இன்னும் ஆன்லைனுக்கு வர முடியாது';

  @override
  String get documentsExpiredMessage => 'உங்கள் உரிமம் அல்லது காப்பீடு காலாவதியாகிவிட்டது. ஆன்லைனுக்கு வர தற்போதைய ஆவணங்களைப் பதிவேற்றவும்.';

  @override
  String get awaitingVerificationMessage => 'உங்கள் ஆவணங்கள் இன்னும் சரிபார்க்கப்படுகின்றன.';

  @override
  String get updateDocuments => 'ஆவணங்களைப் புதுப்பிக்கவும்';

  @override
  String get riderHomeTitle => 'பயணத்திற்குத் தயார்';

  @override
  String get riderHomeSubtitle => 'ஆன்லைனுக்கு வாருங்கள், அருகிலுள்ள டெலிவரிகளை உங்களுக்கு அனுப்புவோம்.';

  @override
  String get dutyStatusLabel => 'பணி நிலை';

  @override
  String get dutyOnline => 'ஆன்லைன்';

  @override
  String get dutyOffline => 'ஆஃப்லைன்';

  @override
  String get dutyOnBreak => 'இடைவேளையில்';

  @override
  String get goOnline => 'ஆன்லைனுக்கு வா';

  @override
  String get goOffline => 'ஆஃப்லைனுக்குச் செல்';

  @override
  String get takeABreak => 'இடைவேளை எடு';

  @override
  String get waitingForOrders => 'அருகில் ஆர்டர்களுக்காகக் காத்திருக்கிறோம்';

  @override
  String get youAreOffline => 'நீங்கள் ஆஃப்லைனில் உள்ளீர்கள். உங்களுக்கு டெலிவரிகள் அனுப்பப்படாது.';

  @override
  String get completedDeliveriesLabel => 'முடிக்கப்பட்ட டெலிவரிகள்';

  @override
  String get ratingLabel => 'மதிப்பீடு';

  @override
  String get notRatedYet => 'இன்னும் மதிப்பிடப்படவில்லை';

  @override
  String get vehicleLabel => 'வாகனம்';

  @override
  String get kycStatusLabel => 'சரிபார்ப்பு';

  @override
  String get kycPending => 'அனுப்பப்படவில்லை';

  @override
  String get kycSubmitted => 'பரிசீலனையில்';

  @override
  String get kycVerified => 'ஏற்கப்பட்டது';

  @override
  String get kycRejected => 'நிராகரிக்கப்பட்டது';

  @override
  String get fieldRequired => 'இது அவசியம்';

  @override
  String get invalidAadhaar => 'உங்கள் ஆதார் எண்ணின் 12 இலக்கங்களை உள்ளிடவும்';

  @override
  String get invalidPan => 'செல்லுபடியாகும் பான் எண்ணை உள்ளிடவும், எ.கா. ABCDE1234F';

  @override
  String get invalidIfsc => 'செல்லுபடியாகும் IFSC குறியீட்டை உள்ளிடவும், எ.கா. SBIN0001234';

  @override
  String get invalidVehicleNumber => 'பதிவுத் தகட்டில் உள்ளபடியே எண்ணை உள்ளிடவும்';

  @override
  String get invalidAccountNumber => 'செல்லுபடியாகும் கணக்கு எண்ணை உள்ளிடவும்';

  @override
  String get dateMustBeFuture => 'இந்தத் தேதி ஏற்கனவே கடந்துவிட்டது';

  @override
  String get mustBeEighteen => 'டெலிவரி செய்ய நீங்கள் குறைந்தது 18 வயது நிரம்பியவராக இருக்க வேண்டும்';

  @override
  String get docAadhaarFront => 'ஆதார் அட்டை (முன்பக்கம்)';

  @override
  String get docAadhaarBack => 'ஆதார் அட்டை (பின்பக்கம்)';

  @override
  String get docDrivingLicence => 'ஓட்டுநர் உரிமம்';

  @override
  String get docVehicleRc => 'வாகனப் பதிவுச் சான்றிதழ்';

  @override
  String get docInsurance => 'வாகனக் காப்பீடு';

  @override
  String get docProfilePhoto => 'சுயவிவரப் புகைப்படம்';

  @override
  String get docPan => 'பான் அட்டை';

  @override
  String get docBankProof => 'ரத்து செய்யப்பட்ட காசோலை அல்லது வங்கி அறிக்கை';
}
