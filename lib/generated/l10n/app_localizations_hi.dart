// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'Nexmile Rider';

  @override
  String get tagline => 'तेज़ डिलीवरी. ताज़ी मुस्कान.';

  @override
  String get chooseLanguageTitle => 'अपनी भाषा चुनें';

  @override
  String get chooseLanguageSubtitle =>
      'वह भाषा चुनें जिसमें आप सहज हों. आप इसे कभी भी सेटिंग्स में बदल सकते हैं.';

  @override
  String get searchLanguageHint => 'भाषा खोजें';

  @override
  String get noLanguageFound => 'कोई भाषा नहीं मिली';

  @override
  String languagesAvailable(int count) {
    return '$count भाषाएँ उपलब्ध हैं';
  }

  @override
  String get continueLabel => 'आगे बढ़ें';

  @override
  String get selectedLabel => 'चयनित';

  @override
  String get defaultLabel => 'डिफ़ॉल्ट';

  @override
  String get homeTitle => 'Nexmile में आपका स्वागत है';

  @override
  String get homeSubtitle =>
      'ताज़ा किराना, गरम खाना और रोज़मर्रा की ज़रूरतें आपके पास की दुकानों से.';

  @override
  String get changeLanguage => 'भाषा बदलें';

  @override
  String get languageUpdated => 'भाषा बदल दी गई';

  @override
  String get appLanguageLabel => 'ऐप की भाषा';

  @override
  String greetingNamed(String name) {
    return 'नमस्ते, $name';
  }

  @override
  String get loginTitle => 'Nexmile में साइन इन करें';

  @override
  String get loginSubtitle =>
      'अपना ईमेल या मोबाइल नंबर दर्ज करें, हम आपको सत्यापन कोड भेजेंगे.';

  @override
  String get emailOrPhoneLabel => 'ईमेल या मोबाइल नंबर';

  @override
  String get emailOrPhoneHint => 'name@example.com या 9876543210';

  @override
  String get invalidEmailOrPhone =>
      'सही ईमेल पता या 10 अंकों का मोबाइल नंबर दर्ज करें';

  @override
  String get loginHeadline => 'Deliver with Nexmile. Earn on your own time.';

  @override
  String get loginOrSignUp => 'Log in or sign up';

  @override
  String get loginEmailHint => 'Enter your email address';

  @override
  String get invalidEmail => 'Enter a valid email address';

  @override
  String get loginHeroBadge => 'Delivery partner';

  @override
  String get sendCode => 'कोड भेजें';

  @override
  String get agreeToTermsOnContinue =>
      'आगे बढ़ने पर आप हमारी सेवा की शर्तों और गोपनीयता नीति से सहमत होते हैं.';

  @override
  String get otpTitle => 'पुष्टि करें कि यह आप हैं';

  @override
  String otpSubtitle(String target) {
    return '$target पर भेजा गया 6 अंकों का कोड दर्ज करें';
  }

  @override
  String get verifyCode => 'सत्यापित करें';

  @override
  String get resendCode => 'कोड दोबारा भेजें';

  @override
  String resendCodeIn(int seconds) {
    return '$seconds सेकंड में दोबारा भेजें';
  }

  @override
  String get codeResent => 'नया कोड भेज दिया गया है';

  @override
  String get incorrectCode =>
      'यह कोड ग़लत है या समाप्त हो चुका है. नया कोड मँगाएँ.';

  @override
  String get enterFullCode => 'पूरे 6 अंक दर्ज करें';

  @override
  String get accountSuspended =>
      'यह खाता निलंबित कर दिया गया है. कृपया सहायता से संपर्क करें.';

  @override
  String get tooManyAttempts =>
      'बहुत अधिक प्रयास हो गए. कृपया कुछ देर बाद फिर कोशिश करें.';

  @override
  String get sessionExpired =>
      'आपका सत्र समाप्त हो गया है. कृपया फिर से साइन इन करें.';

  @override
  String get networkError =>
      'इंटरनेट कनेक्शन नहीं है. अपना कनेक्शन जाँचें और फिर कोशिश करें.';

  @override
  String get developmentCode => 'डेवलपमेंट कोड';

  @override
  String get signOut => 'साइन आउट';

  @override
  String get signedOut => 'आप साइन आउट हो गए हैं';

  @override
  String get somethingWentWrong => 'कुछ ग़लत हो गया. कृपया फिर कोशिश करें.';

  @override
  String get profileTitle => 'प्रोफ़ाइल';

  @override
  String get viewProfile => 'प्रोफ़ाइल देखें';

  @override
  String get nameLabel => 'नाम';

  @override
  String get emailLabel => 'ईमेल';

  @override
  String get mobileLabel => 'मोबाइल नंबर';

  @override
  String get accountStatusLabel => 'खाते की स्थिति';

  @override
  String get statusActive => 'सक्रिय';

  @override
  String get statusPending => 'लंबित';

  @override
  String get statusSuspended => 'निलंबित';

  @override
  String get verifiedLabel => 'सत्यापित';

  @override
  String get notProvided => 'जोड़ा नहीं गया';

  @override
  String get retry => 'फिर कोशिश करें';

  @override
  String get loginRiderNote => 'यह ऐप नेक्समाइल डिलीवरी पार्टनर्स के लिए है।';

  @override
  String get checkingYourAccount => 'आपका खाता जाँचा जा रहा है';

  @override
  String get couldNotLoadAccount =>
      'हम आपका खाता लोड नहीं कर सके। अपना कनेक्शन जाँचकर फिर कोशिश करें।';

  @override
  String get notARiderAccountTitle => 'यह डिलीवरी पार्टनर खाता नहीं है';

  @override
  String get notARiderAccount =>
      'यह ईमेल या मोबाइल नंबर पहले से नेक्समाइल ग्राहक के रूप में पंजीकृत है। साइन आउट करके डिलीवरी पार्टनर बनने के लिए दूसरा उपयोग करें।';

  @override
  String notARiderAccountFor(String role) {
    return 'यह ईमेल या मोबाइल नंबर पहले से नेक्समाइल $role के रूप में पंजीकृत है। साइन आउट करके डिलीवरी पार्टनर बनने के लिए दूसरा उपयोग करें।';
  }

  @override
  String get roleCustomer => 'ग्राहक';

  @override
  String get roleMerchant => 'विक्रेता';

  @override
  String get roleAdmin => 'प्रशासक';

  @override
  String get useAnotherAccount => 'दूसरा खाता उपयोग करें';

  @override
  String get onboardingTitle => 'नेक्समाइल पार्टनर बनें';

  @override
  String get onboardingSubtitle =>
      'कुछ जानकारी और आपके दस्तावेज़, फिर हमारी टीम आपको सत्यापित करती है। आम तौर पर दो कार्यदिवस लगते हैं।';

  @override
  String stepOfSteps(int current, int total) {
    return 'चरण $current / $total';
  }

  @override
  String get stepIdentityTitle => 'आपके बारे में';

  @override
  String get stepIdentitySubtitle =>
      'अपना नाम ठीक वैसे ही लिखें जैसे आपके आधार कार्ड पर है।';

  @override
  String get stepVehicleTitle => 'आपका वाहन';

  @override
  String get stepVehicleSubtitle =>
      'बताएँ कि आप क्या चलाते हैं और उसका नंबर क्या है।';

  @override
  String get stepIdentityNumbersTitle => 'पहचान संख्याएँ';

  @override
  String get stepIdentityNumbersSubtitle =>
      'ये उन दस्तावेज़ों से मेल खानी चाहिए जो आप आगे अपलोड करेंगे।';

  @override
  String get stepLicenceTitle => 'लाइसेंस और बीमा';

  @override
  String get stepLicenceSubtitle =>
      'डिलीवरी शुरू करने के दिन दोनों वैध होने चाहिए।';

  @override
  String get stepBankTitle => 'भुगतान कहाँ मिलेगा';

  @override
  String get stepBankSubtitle =>
      'आपकी कमाई इसी खाते में आएगी। इसे ध्यान से जाँचें।';

  @override
  String get stepDocumentsTitle => 'आपके दस्तावेज़';

  @override
  String get stepDocumentsSubtitle =>
      'हर दस्तावेज़ की अच्छी रोशनी में फ़ोटो लें। JPG, PNG या PDF, हर एक 5 MB तक।';

  @override
  String get stepReviewTitle => 'जाँचें और भेजें';

  @override
  String get stepReviewSubtitle =>
      'भेजने के बाद, जब तक हमारी टीम समीक्षा नहीं कर लेती, आपकी जानकारी लॉक रहेगी।';

  @override
  String get saveAndContinue => 'सहेजें और आगे बढ़ें';

  @override
  String get backLabel => 'पीछे';

  @override
  String get fullNameLabel => 'पूरा नाम';

  @override
  String get fullNameHint => 'जैसा आधार पर छपा है';

  @override
  String get dateOfBirthLabel => 'जन्म तिथि';

  @override
  String get selectDate => 'तारीख़ चुनें';

  @override
  String get vehicleTypeLabel => 'वाहन का प्रकार';

  @override
  String get vehicleMotorcycle => 'मोटरसाइकिल';

  @override
  String get vehicleScooter => 'स्कूटर';

  @override
  String get vehicleEv => 'इलेक्ट्रिक वाहन';

  @override
  String get vehicleBicycle => 'साइकिल';

  @override
  String get vehicleWalk => 'पैदल';

  @override
  String get vehicleNoPapersNote =>
      'वाहन नंबर या आरसी की ज़रूरत नहीं। केवल आधार और पैन मांगा जाएगा।';

  @override
  String get vehicleNumberLabel => 'वाहन नंबर';

  @override
  String get vehicleNumberHint => 'TN01AB1234';

  @override
  String get rcNumberLabel => 'आरसी नंबर';

  @override
  String get aadhaarLabel => 'आधार नंबर';

  @override
  String get aadhaarHint => '12 अंक';

  @override
  String get panLabel => 'पैन (PAN)';

  @override
  String get panHint => 'ABCDE1234F';

  @override
  String get drivingLicenceNoLabel => 'ड्राइविंग लाइसेंस नंबर';

  @override
  String get drivingLicenceExpiryLabel => 'लाइसेंस की वैधता तक';

  @override
  String get insuranceNumberLabel => 'बीमा पॉलिसी नंबर';

  @override
  String get insuranceExpiryLabel => 'बीमे की वैधता तक';

  @override
  String get bankAccountNameLabel => 'खाताधारक का नाम';

  @override
  String get bankAccountNumberLabel => 'खाता संख्या';

  @override
  String get bankIfscLabel => 'IFSC कोड';

  @override
  String get bankIfscHint => 'SBIN0001234';

  @override
  String documentsProgress(int done, int total) {
    return '$total में से $done अपलोड हुए';
  }

  @override
  String get uploadDocument => 'अपलोड करें';

  @override
  String get replaceDocument => 'बदलें';

  @override
  String get removeDocument => 'हटाएँ';

  @override
  String get takePhoto => 'फ़ोटो लें';

  @override
  String get chooseFromGallery => 'गैलरी से चुनें';

  @override
  String get chooseFile => 'फ़ाइल चुनें';

  @override
  String get uploadingLabel => 'अपलोड हो रहा है';

  @override
  String get documentRejected => 'अस्वीकृत';

  @override
  String get documentUploaded => 'अपलोड हुआ';

  @override
  String get documentApproved => 'स्वीकृत';

  @override
  String get documentRequired => 'ज़रूरी';

  @override
  String get documentOptional => 'वैकल्पिक';

  @override
  String get fileTooLarge =>
      'वह फ़ाइल 5 MB से बड़ी है। स्कैन के बजाय फ़ोटो आज़माएँ।';

  @override
  String get unsupportedFileType => 'JPG, PNG या PDF चुनें।';

  @override
  String get pickerUnavailable =>
      'हम उसे नहीं खोल सके। ऐप की कैमरा और फ़ोटो अनुमतियाँ जाँचें।';

  @override
  String get uploadFailed => 'वह अपलोड पूरा नहीं हुआ। कृपया फिर कोशिश करें।';

  @override
  String get submitForVerification => 'सत्यापन के लिए भेजें';

  @override
  String get submitConfirmTitle => 'सत्यापन के लिए भेजें?';

  @override
  String get submitConfirmBody =>
      'हमारी टीम की समीक्षा तक आपकी जानकारी और दस्तावेज़ लॉक रहेंगे। निर्णय आने तक आप उन्हें बदल नहीं सकेंगे।';

  @override
  String get cancelLabel => 'रद्द करें';

  @override
  String get completeEverythingBeforeSubmitting =>
      'भेजने से पहले हर चरण पूरा करें और सभी दस्तावेज़ अपलोड करें।';

  @override
  String get checkTheHighlightedFields =>
      'चिह्नित फ़ील्ड जाँचकर फिर कोशिश करें।';

  @override
  String get underReviewTitle => 'हम आपके दस्तावेज़ सत्यापित कर रहे हैं';

  @override
  String get underReviewBody =>
      'हमारी टीम आम तौर पर दो कार्यदिवसों में समीक्षा कर लेती है। स्वीकृति मिलते ही हम आपको बता देंगे।';

  @override
  String get checkAgain => 'फिर जाँचें';

  @override
  String get stillUnderReview => 'अब भी समीक्षा में है';

  @override
  String get rejectedTitle => 'हम आपको सत्यापित नहीं कर सके';

  @override
  String get rejectedBody =>
      'नीचे हमारी टीम ने जो बताया है उसे ठीक करके दस्तावेज़ फिर भेजें।';

  @override
  String get rejectionReasonLabel => 'कारण';

  @override
  String get fixAndResubmit => 'ठीक करके फिर भेजें';

  @override
  String get blockedTitle => 'आप अभी ऑनलाइन नहीं हो सकते';

  @override
  String get documentsExpiredMessage =>
      'आपका लाइसेंस या बीमा समाप्त हो चुका है। ऑनलाइन होने के लिए मौजूदा दस्तावेज़ अपलोड करें।';

  @override
  String get awaitingVerificationMessage =>
      'आपके दस्तावेज़ अब भी सत्यापित किए जा रहे हैं।';

  @override
  String get updateDocuments => 'दस्तावेज़ अपडेट करें';

  @override
  String get riderHomeTitle => 'चलने के लिए तैयार';

  @override
  String get riderHomeSubtitle =>
      'ऑनलाइन हों और हम आपको आस-पास की डिलीवरी भेजेंगे।';

  @override
  String get dutyStatusLabel => 'ड्यूटी स्थिति';

  @override
  String get dutyOnline => 'ऑनलाइन';

  @override
  String get dutyOffline => 'ऑफ़लाइन';

  @override
  String get dutyOnBreak => 'ब्रेक पर';

  @override
  String get goOnline => 'ऑनलाइन हों';

  @override
  String get goOffline => 'ऑफ़लाइन हों';

  @override
  String get takeABreak => 'ब्रेक लें';

  @override
  String get waitingForOrders => 'आस-पास ऑर्डर का इंतज़ार है';

  @override
  String get youAreOffline =>
      'आप ऑफ़लाइन हैं। आपको कोई डिलीवरी नहीं भेजी जाएगी।';

  @override
  String get completedDeliveriesLabel => 'पूरी हुई डिलीवरी';

  @override
  String get ratingLabel => 'रेटिंग';

  @override
  String get notRatedYet => 'अभी कोई रेटिंग नहीं';

  @override
  String get vehicleLabel => 'वाहन';

  @override
  String get kycStatusLabel => 'सत्यापन';

  @override
  String get kycPending => 'नहीं भेजा गया';

  @override
  String get kycSubmitted => 'समीक्षा में';

  @override
  String get kycVerified => 'स्वीकृत';

  @override
  String get kycRejected => 'अस्वीकृत';

  @override
  String get fieldRequired => 'यह ज़रूरी है';

  @override
  String get invalidAadhaar => 'अपने आधार नंबर के 12 अंक दर्ज करें';

  @override
  String get invalidPan => 'वैध पैन दर्ज करें, जैसे ABCDE1234F';

  @override
  String get invalidIfsc => 'वैध IFSC कोड दर्ज करें, जैसे SBIN0001234';

  @override
  String get invalidVehicleNumber =>
      'नंबर ठीक वैसे ही दर्ज करें जैसा नंबर प्लेट पर है';

  @override
  String get invalidAccountNumber => 'वैध खाता संख्या दर्ज करें';

  @override
  String get dateMustBeFuture => 'यह तारीख़ पहले ही बीत चुकी है';

  @override
  String get mustBeEighteen =>
      'डिलीवरी करने के लिए आपकी उम्र कम से कम 18 वर्ष होनी चाहिए';

  @override
  String get docAadhaarFront => 'आधार कार्ड (सामने)';

  @override
  String get docAadhaarBack => 'आधार कार्ड (पीछे)';

  @override
  String get docDrivingLicence => 'ड्राइविंग लाइसेंस';

  @override
  String get docVehicleRc => 'वाहन पंजीकरण प्रमाणपत्र';

  @override
  String get docInsurance => 'वाहन बीमा';

  @override
  String get docProfilePhoto => 'प्रोफ़ाइल फ़ोटो';

  @override
  String get docPan => 'पैन कार्ड';

  @override
  String get docBankProof => 'रद्द किया गया चेक या बैंक स्टेटमेंट';

  @override
  String get ordersTab => 'ऑर्डर';

  @override
  String get deliveryTab => 'डिलीवरी';

  @override
  String get historyTab => 'इतिहास';

  @override
  String get orderBoardTitle => 'आपके पास के ऑर्डर';

  @override
  String get orderBoardSubtitle =>
      'सबसे नज़दीकी रेस्टोरेंट पहले. सूची अपने आप ताज़ा होती रहती है.';

  @override
  String orderNumberLabel(String number) {
    return 'ऑर्डर $number';
  }

  @override
  String get pickupLabel => 'यहाँ से लें';

  @override
  String get dropoffLabel => 'यहाँ पहुँचाएँ';

  @override
  String distanceMetres(String metres) {
    return '$metres मी';
  }

  @override
  String distanceKilometres(String km) {
    return '$km किमी';
  }

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count चीज़ें',
      one: '1 चीज़',
    );
    return '$_temp0';
  }

  @override
  String get earningsLabel => 'आपकी कमाई';

  @override
  String get collectCashLabel => 'नकद लें';

  @override
  String get prepaidLabel => 'ऑनलाइन भुगतान हो चुका';

  @override
  String collectAtDoor(String amount) {
    return 'ग्राहक से $amount लें';
  }

  @override
  String get nothingToCollect => 'भुगतान हो चुका है. पैसे न माँगें.';

  @override
  String get acceptOrder => 'स्वीकार करें';

  @override
  String get viewOrder => 'देखें';

  @override
  String get orderAccepted => 'ऑर्डर स्वीकार हुआ. रेस्टोरेंट पहुँचें.';

  @override
  String get orderAlreadyTaken =>
      'यह ऑर्डर किसी और राइडर ने ले लिया. यह नई सूची है.';

  @override
  String get orderNoLongerYours => 'यह ऑर्डर अब आपका नहीं है.';

  @override
  String get boardEmptyTitle => 'अभी कोई ऑर्डर नहीं';

  @override
  String get boardEmptyBody =>
      'ऑनलाइन बने रहें. रेस्टोरेंट व्यस्त होते ही सूची अपने आप भर जाएगी.';

  @override
  String get boardOfflineTitle => 'आप ऑफ़लाइन हैं';

  @override
  String get boardOfflineBody => 'ऑर्डर पाने के लिए ऑनलाइन हों.';

  @override
  String get boardBusyTitle => 'पहले अपनी डिलीवरी पूरी करें';

  @override
  String get boardBusyBody => 'यह ऑर्डर पहुँचाने के बाद ही आप दूसरा ले सकेंगे.';

  @override
  String get boardNoLocationTitle => 'हम आपको ढूँढ नहीं पा रहे';

  @override
  String get boardNoLocationBody =>
      'ऑर्डर रेस्टोरेंट की दूरी के हिसाब से दिखते हैं, इसलिए कुछ भी दिखाने के लिए आपकी लोकेशन ज़रूरी है.';

  @override
  String get boardNotVerifiedTitle => 'अभी राइड करने की मंज़ूरी नहीं है';

  @override
  String get activeDeliveryTitle => 'आपकी डिलीवरी';

  @override
  String get headToRestaurant => 'रेस्टोरेंट पहुँचें';

  @override
  String get deliverToCustomer => 'ग्राहक तक पहुँचाएँ';

  @override
  String get noActiveDeliveryTitle => 'अभी कोई ऑर्डर नहीं है';

  @override
  String get noActiveDeliveryBody =>
      'सूची से कोई ऑर्डर स्वीकार करें, वह यहाँ दिखने लगेगा.';

  @override
  String get confirmPickupButton => 'मैंने ले लिया है';

  @override
  String get pickupCodeTitle => 'पिकअप कोड';

  @override
  String get pickupCodeSubtitle => 'रेस्टोरेंट से कोड पूछें और यहाँ लिखें.';

  @override
  String get pickupCodeHint => 'कोड';

  @override
  String get wrongPickupCode =>
      'यह कोड मेल नहीं खाया. रेस्टोरेंट से दोबारा पूछें.';

  @override
  String get pickupConfirmed => 'ऑर्डर ले लिया. अब ग्राहक तक पहुँचाएँ.';

  @override
  String get confirmDeliveryButton => 'पहुँचा दिया';

  @override
  String get confirmDeliveryTitle => 'डिलीवरी की पुष्टि करें';

  @override
  String get confirmDeliveryBody =>
      'तभी पुष्टि करें जब ऑर्डर ग्राहक के हाथ में पहुँच चुका हो.';

  @override
  String confirmDeliveryCashBody(String amount) {
    return 'पहले $amount लें, फिर पुष्टि करें.';
  }

  @override
  String get deliveryConfirmed => 'पहुँचा दिया. धन्यवाद, आप फिर से ऑनलाइन हैं.';

  @override
  String get releaseOrderButton => 'वापस कर दें';

  @override
  String get releaseOrderTitle => 'यह ऑर्डर वापस करना है?';

  @override
  String get releaseOrderBody =>
      'यह दूसरे राइडर के लिए सूची में वापस चला जाएगा. खाना लेने से पहले ही ऐसा कर सकते हैं.';

  @override
  String get releaseReasonHint => 'कारण (ज़रूरी नहीं)';

  @override
  String get orderReleased =>
      'वापस कर दिया. यह दूसरे राइडर के लिए फिर उपलब्ध है.';

  @override
  String get finishCurrentOrderFirst =>
      'पहले अपना मौजूदा ऑर्डर पूरा करें या वापस कर दें.';

  @override
  String get callRestaurant => 'रेस्टोरेंट को कॉल करें';

  @override
  String get callCustomer => 'ग्राहक को कॉल करें';

  @override
  String get openInMaps => 'रास्ता देखें';

  @override
  String get customerNoteLabel => 'ग्राहक का संदेश';

  @override
  String get orderItemsLabel => 'बैग में क्या है';

  @override
  String get orderDetailsTitle => 'ऑर्डर का विवरण';

  @override
  String get historyTitle => 'पिछली डिलीवरी';

  @override
  String get historyEmptyTitle => 'अभी कोई डिलीवरी नहीं';

  @override
  String get historyEmptyBody => 'आपने जो ऑर्डर पूरे किए हैं वे यहाँ दिखेंगे.';

  @override
  String get orderDelivered => 'पहुँचा दिया';

  @override
  String get orderCancelled => 'रद्द';

  @override
  String get orderPreparing => 'तैयार हो रहा है';

  @override
  String get orderReadyForPickup => 'लेने के लिए तैयार';

  @override
  String get orderAssigned => 'आपको सौंपा गया';

  @override
  String get orderPickedUp => 'ले लिया गया';

  @override
  String get orderOutForDelivery => 'रास्ते में';

  @override
  String get trackingOn => 'लोकेशन साझा हो रही है';

  @override
  String get locationUnavailableMessage =>
      'हम आपकी लोकेशन नहीं पढ़ पा रहे. लोकेशन चालू करें और Nexmile Rider को अनुमति दें.';

  @override
  String get locationPermissionTitle => 'लोकेशन ज़रूरी है';

  @override
  String get locationPermissionBody =>
      'ऑर्डर आपकी दूरी के हिसाब से बाँटे जाते हैं, और ग्राहक नक्शे पर आपको देखता है. ऑनलाइन होने के लिए लोकेशन की अनुमति दें.';

  @override
  String get locationSettingsButton => 'सेटिंग्स खोलें';

  @override
  String get enableLocationButton => 'लोकेशन की अनुमति दें';

  @override
  String amountRupees(String amount) {
    return '₹$amount';
  }

  @override
  String get shiftTab => 'शिफ़्ट';

  @override
  String get payoutsTitle => 'Payouts';

  @override
  String get payoutsEntryValue => 'Weekly earnings';

  @override
  String get payoutDetailsTitle => 'Weekly payout';

  @override
  String get payoutsEmptyTitle => 'No payouts yet';

  @override
  String get payoutsEmptyBody =>
      'Your earnings for each week will be listed here once the week is worked out.';

  @override
  String payoutPeriod(String start, String end) {
    return '$start – $end';
  }

  @override
  String get payoutStatusPending => 'Pending';

  @override
  String get payoutStatusProcessing => 'Being processed';

  @override
  String get payoutStatusPaid => 'Paid';

  @override
  String get payoutNotSentNote =>
      'Your earnings for this week have been worked out. The money has not been sent to your bank yet.';

  @override
  String payoutPaidOn(String date) {
    return 'Sent to your bank on $date';
  }

  @override
  String get payoutPaidNote =>
      'The bank transfer for this week has gone through.';

  @override
  String get payoutReferenceLabel => 'Transfer reference';

  @override
  String get payoutNetLabel => 'Amount payable';

  @override
  String get payoutDeliveryEarnings => 'Delivery earnings';

  @override
  String get payoutReferralEarnings => 'Referral earnings';

  @override
  String get payoutCarriedIn => 'From an earlier week';

  @override
  String get payoutCarriedInNote =>
      'Amounts under ₹100 are not transferred on their own. They are added to the next week instead.';

  @override
  String get payoutGross => 'Total earned';

  @override
  String get payoutDeductions => 'Deductions';

  @override
  String get navToRestaurant => 'To the restaurant';

  @override
  String get navToCustomer => 'To the customer';

  @override
  String navHeadTowards(String place) {
    return 'Head towards $place';
  }

  @override
  String navThen(String instruction) {
    return 'Then: $instruction';
  }

  @override
  String get navArrived => 'You have arrived';

  @override
  String navArrivedAt(String place) {
    return 'At $place';
  }

  @override
  String get navFindingRoute => 'Finding the best route…';

  @override
  String get navNoRoute =>
      'Road directions aren\'t available. Showing the straight-line distance.';

  @override
  String get navFindingLocation => 'Finding your location…';

  @override
  String get navLocationOff => 'Turn on location to navigate.';

  @override
  String get navEnd => 'End navigation';

  @override
  String get navRecentre => 'Recentre';

  @override
  String navRemaining(String distance, String time) {
    return '$distance · $time';
  }

  @override
  String navMinutes(String minutes) {
    return '$minutes min';
  }

  @override
  String get navStart => 'Navigate';

  @override
  String get orderReachedRestaurant => 'At the restaurant';

  @override
  String get orderReachedCustomer => 'At the customer';

  @override
  String get reachedRestaurantButton => 'I\'ve reached the restaurant';

  @override
  String get reachedCustomerButton => 'I\'ve reached the customer';

  @override
  String get reachedRestaurantDone => 'The kitchen knows you\'re here';

  @override
  String get reachedCustomerDone => 'The customer knows you\'re outside';

  @override
  String get offerTitle => 'New order';

  @override
  String get offerYouEarn => 'You earn';

  @override
  String get offerPickup => 'Pickup';

  @override
  String get offerDrop => 'Drop';

  @override
  String offerAway(String distance) {
    return '$distance away';
  }

  @override
  String offerTrip(String distance) {
    return '$distance trip';
  }

  @override
  String offerItems(String count) {
    return '$count items';
  }

  @override
  String offerCollectCash(String amount) {
    return 'Collect $amount cash';
  }

  @override
  String get offerPrepaid => 'Prepaid · no cash';

  @override
  String offerFoodReadyIn(String minutes) {
    return 'Food ready in about $minutes min';
  }

  @override
  String get offerSwipeToAccept => 'Swipe to accept';

  @override
  String get offerAccepting => 'Accepting…';

  @override
  String get offerReject => 'Reject';

  @override
  String get offerRejectTitle => 'Why are you declining?';

  @override
  String get offerReasonTooFar => 'Too far';

  @override
  String get offerReasonBusy => 'Busy right now';

  @override
  String get offerReasonVehicle => 'Vehicle problem';

  @override
  String get offerReasonOther => 'Other reason';

  @override
  String get offerTaken => 'Order taken by another rider';

  @override
  String get offerAutoOffline =>
      'You were set offline after missing 3 orders. Go online when you\'re ready.';

  @override
  String get mockLocationBlocked =>
      'Turn off any fake-location app to receive orders.';

  @override
  String get dropoffDoorLabel => 'Flat / floor';

  @override
  String get dropoffStreetLabel => 'Street';

  @override
  String get dropoffLandmarkLabel => 'Landmark';

  @override
  String get doorPhotoLabel => 'Door photo';

  @override
  String get doorPhotoHint => 'Tap to see it bigger';

  @override
  String get doorPhotoUnavailable => 'Photo not available right now';

  @override
  String permStepCount(int step, int total) {
    return '$step of $total';
  }

  @override
  String get permNotNow => 'Not now';

  @override
  String get permLocationTitle => 'Turn on location';

  @override
  String get permLocationBody =>
      'Orders go to the rider closest to the restaurant, and customers follow their food on the map.';

  @override
  String get permLocationNearTitle => 'Orders near you';

  @override
  String get permLocationNearBody =>
      'We offer you orders from restaurants close by, so you ride less and earn more.';

  @override
  String get permLocationTrackTitle => 'Live tracking';

  @override
  String get permLocationTrackBody =>
      'Customers see you on the map, so they call you less.';

  @override
  String get permLocationOnlineTitle => 'Only while you\'re online';

  @override
  String get permLocationOnlineBody =>
      'Go offline and it stops. A notification shows whenever it is in use.';

  @override
  String get permLocationAllow => 'Allow location';

  @override
  String get permNotifyTitle => 'Never miss an order';

  @override
  String get permNotifyBody =>
      'New orders ring like a phone call, even when your screen is locked.';

  @override
  String get permNotifyRingTitle => 'Order alerts that ring';

  @override
  String get permNotifyRingBody => 'Accept or decline straight from the alert.';

  @override
  String get permNotifyUpdatesTitle => 'Payouts and approvals';

  @override
  String get permNotifyUpdatesBody =>
      'Know when your documents are approved and when money is sent.';

  @override
  String get permNotifyControlTitle => 'You stay in control';

  @override
  String get permNotifyControlBody =>
      'Change it any time in your phone\'s Settings.';

  @override
  String get permNotifyAllow => 'Turn on notifications';

  @override
  String get permBatteryTitle => 'Keep orders coming';

  @override
  String get permBatteryBody =>
      'Phones close apps in the background to save battery. Let Nexmile Rider keep running while you\'re online.';

  @override
  String get permBatteryOrdersTitle => 'No missed orders';

  @override
  String get permBatteryOrdersBody =>
      'Offers reach you with the app closed and the phone in your pocket.';

  @override
  String get permBatteryLiveTitle => 'Tracking stays live';

  @override
  String get permBatteryLiveBody =>
      'Customers keep seeing you on the map until you deliver.';

  @override
  String get permBatteryLightTitle => 'Light on battery';

  @override
  String get permBatteryLightBody => 'It only works hard while you\'re online.';

  @override
  String get permBatteryAllow => 'Allow background use';

  @override
  String get permFullScreenTitle => 'Orders on your lock screen';

  @override
  String get permFullScreenBody =>
      'Let new orders appear over the lock screen, like an incoming call, so you can accept in one tap.';

  @override
  String get permFullScreenCallTitle => 'Answer like a call';

  @override
  String get permFullScreenCallBody =>
      'See the order and accept it without unlocking.';

  @override
  String get permFullScreenTimeTitle => 'Respond in time';

  @override
  String get permFullScreenTimeBody =>
      'An offer you don\'t answer moves on to another rider.';

  @override
  String get permFullScreenOnlyTitle => 'Only for new orders';

  @override
  String get permFullScreenOnlyBody =>
      'Nothing else ever appears over your lock screen.';

  @override
  String get setupTitle => 'Phone setup';

  @override
  String get setupIntro =>
      'Finish these so new orders ring even when the app is closed or your phone is locked.';

  @override
  String get setupNotifications => 'Notifications';

  @override
  String get setupNotificationsBody => 'So new orders can ring and show.';

  @override
  String get setupFullScreen => 'Full-screen order alerts';

  @override
  String get setupFullScreenBody =>
      'Shows a new order over your lock screen, like a call.';

  @override
  String get setupBattery => 'Battery: don\'t optimise';

  @override
  String get setupBatteryBody =>
      'Stops your phone closing the app while you\'re online.';

  @override
  String get setupAutostart => 'Autostart';

  @override
  String setupAutostartBody(String brand) {
    return '$brand phones also need Autostart on for Nexmile Rider. Open settings, find Autostart, and switch it on.';
  }

  @override
  String get setupLocation => 'Location';

  @override
  String get setupLocationBody => 'Needed to send you orders nearby.';

  @override
  String get setupAllow => 'Allow';

  @override
  String get setupOpenSettings => 'Open settings';

  @override
  String get setupMarkDone => 'I\'ve done this';

  @override
  String get setupDoneStep => 'Done';

  @override
  String get setupBannerTitle => 'Finish phone setup';

  @override
  String setupBannerBody(String count) {
    return '$count left so order alerts aren\'t missed';
  }

  @override
  String get offerEstimatedEarnings => 'Estimated earnings';

  @override
  String offerPickupLine(String name) {
    return 'Pickup: $name';
  }

  @override
  String offerDropLine(String area) {
    return 'Drop: $area';
  }

  @override
  String offerFromYou(String distance) {
    return 'About $distance from you';
  }

  @override
  String get exitTitle => 'Exit Nexmile Rider?';

  @override
  String get exitBody => 'Are you sure you want to exit the app?';

  @override
  String get exitConfirm => 'Exit';

  @override
  String get onboardingWelcomeTitle => 'Become a Nexmile delivery partner';

  @override
  String get onboardingWelcomeSubtitle =>
      'Deliver in your area, pick your own hours, and get paid every week.';

  @override
  String get onboardingWelcomeNeed => 'Keep these ready';

  @override
  String get onboardingNeedAadhaar => 'Aadhaar card';

  @override
  String get onboardingNeedPan => 'PAN card';

  @override
  String get onboardingNeedLicence => 'Driving licence and vehicle RC';

  @override
  String get onboardingNeedInsurance => 'Vehicle insurance';

  @override
  String get onboardingNeedBank => 'Bank account details';

  @override
  String get onboardingNeedNote =>
      'Riding a bicycle or on foot? You only need Aadhaar, PAN and a bank account.';

  @override
  String get onboardingWelcomeTime => 'Takes about 10 minutes';

  @override
  String get onboardingGetStarted => 'Get started';

  @override
  String get onboardingSavedNote => 'Saved securely after every step';

  @override
  String get docsTip => 'Clear photos in good light get approved fastest.';

  @override
  String get docsAllDone =>
      'All required documents are in. Continue to review.';

  @override
  String get docGroupIdentity => 'Identity proof';

  @override
  String get docGroupVehicle => 'Licence and vehicle papers';

  @override
  String get docGroupMore => 'More documents';

  @override
  String get docTapToAdd => 'Tap to add';

  @override
  String get docUploading => 'Uploading…';

  @override
  String get docView => 'View';

  @override
  String get docSheetSubtitle => 'How to get it approved the first time';

  @override
  String get docTipCorners => 'All four corners inside the photo';

  @override
  String get docTipGlare => 'Sharp text, no glare or shadows';

  @override
  String get docTipOriginal => 'The original document, not a photocopy';

  @override
  String get docTipFace => 'Your face clearly visible, looking straight ahead';

  @override
  String get docTipBackground => 'Plain background and good light';

  @override
  String get docTipNoCap => 'No cap, mask or sunglasses';

  @override
  String get docTipFullPage => 'The full page, with every line readable';

  @override
  String get docSourceCamera => 'Camera';

  @override
  String get docSourceGallery => 'Gallery';

  @override
  String get docSourceFile => 'PDF or file';

  @override
  String get reviewSectionDetails => 'Your details';

  @override
  String get reviewSectionDocuments => 'Documents';

  @override
  String get reviewSectionBank => 'Bank account';

  @override
  String get reviewBankHidden => 'Added · hidden for your security';

  @override
  String get reviewEdit => 'Edit';

  @override
  String get reviewNextTitle => 'What happens next';

  @override
  String get reviewNext1 => 'You submit your application';

  @override
  String get reviewNext2 => 'Our team checks your details and documents';

  @override
  String get reviewNext3 => 'You\'re notified, go online and start earning';

  @override
  String get kycStepSubmitted => 'Application submitted';

  @override
  String get kycStepVerifying => 'Verifying your documents';

  @override
  String get kycStepApproved => 'Approved — go online and start earning';
}
