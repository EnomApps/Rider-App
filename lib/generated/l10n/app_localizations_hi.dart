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
  String get chooseLanguageSubtitle => 'वह भाषा चुनें जिसमें आप सहज हों. आप इसे कभी भी सेटिंग्स में बदल सकते हैं.';

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
  String get homeSubtitle => 'ताज़ा किराना, गरम खाना और रोज़मर्रा की ज़रूरतें आपके पास की दुकानों से.';

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
  String get loginSubtitle => 'अपना ईमेल या मोबाइल नंबर दर्ज करें, हम आपको सत्यापन कोड भेजेंगे.';

  @override
  String get emailOrPhoneLabel => 'ईमेल या मोबाइल नंबर';

  @override
  String get emailOrPhoneHint => 'name@example.com या 9876543210';

  @override
  String get invalidEmailOrPhone => 'सही ईमेल पता या 10 अंकों का मोबाइल नंबर दर्ज करें';

  @override
  String get sendCode => 'कोड भेजें';

  @override
  String get agreeToTermsOnContinue => 'आगे बढ़ने पर आप हमारी सेवा की शर्तों और गोपनीयता नीति से सहमत होते हैं.';

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
  String get incorrectCode => 'यह कोड ग़लत है या समाप्त हो चुका है. नया कोड मँगाएँ.';

  @override
  String get enterFullCode => 'पूरे 6 अंक दर्ज करें';

  @override
  String get accountSuspended => 'यह खाता निलंबित कर दिया गया है. कृपया सहायता से संपर्क करें.';

  @override
  String get tooManyAttempts => 'बहुत अधिक प्रयास हो गए. कृपया कुछ देर बाद फिर कोशिश करें.';

  @override
  String get sessionExpired => 'आपका सत्र समाप्त हो गया है. कृपया फिर से साइन इन करें.';

  @override
  String get networkError => 'इंटरनेट कनेक्शन नहीं है. अपना कनेक्शन जाँचें और फिर कोशिश करें.';

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
  String get couldNotLoadAccount => 'हम आपका खाता लोड नहीं कर सके। अपना कनेक्शन जाँचकर फिर कोशिश करें।';

  @override
  String get notARiderAccountTitle => 'यह डिलीवरी पार्टनर खाता नहीं है';

  @override
  String get notARiderAccount => 'यह ईमेल या मोबाइल नंबर पहले से नेक्समाइल ग्राहक के रूप में पंजीकृत है। साइन आउट करके डिलीवरी पार्टनर बनने के लिए दूसरा उपयोग करें।';

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
  String get onboardingSubtitle => 'कुछ जानकारी और आपके दस्तावेज़, फिर हमारी टीम आपको सत्यापित करती है। आम तौर पर दो कार्यदिवस लगते हैं।';

  @override
  String stepOfSteps(int current, int total) {
    return 'चरण $current / $total';
  }

  @override
  String get stepIdentityTitle => 'आपके बारे में';

  @override
  String get stepIdentitySubtitle => 'अपना नाम ठीक वैसे ही लिखें जैसे आपके आधार कार्ड पर है।';

  @override
  String get stepVehicleTitle => 'आपका वाहन';

  @override
  String get stepVehicleSubtitle => 'बताएँ कि आप क्या चलाते हैं और उसका नंबर क्या है।';

  @override
  String get stepIdentityNumbersTitle => 'पहचान संख्याएँ';

  @override
  String get stepIdentityNumbersSubtitle => 'ये उन दस्तावेज़ों से मेल खानी चाहिए जो आप आगे अपलोड करेंगे।';

  @override
  String get stepLicenceTitle => 'लाइसेंस और बीमा';

  @override
  String get stepLicenceSubtitle => 'डिलीवरी शुरू करने के दिन दोनों वैध होने चाहिए।';

  @override
  String get stepBankTitle => 'भुगतान कहाँ मिलेगा';

  @override
  String get stepBankSubtitle => 'आपकी कमाई इसी खाते में आएगी। इसे ध्यान से जाँचें।';

  @override
  String get stepDocumentsTitle => 'आपके दस्तावेज़';

  @override
  String get stepDocumentsSubtitle => 'हर दस्तावेज़ की अच्छी रोशनी में फ़ोटो लें। JPG, PNG या PDF, हर एक 5 MB तक।';

  @override
  String get stepReviewTitle => 'जाँचें और भेजें';

  @override
  String get stepReviewSubtitle => 'भेजने के बाद, जब तक हमारी टीम समीक्षा नहीं कर लेती, आपकी जानकारी लॉक रहेगी।';

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
  String get fileTooLarge => 'वह फ़ाइल 5 MB से बड़ी है। स्कैन के बजाय फ़ोटो आज़माएँ।';

  @override
  String get unsupportedFileType => 'JPG, PNG या PDF चुनें।';

  @override
  String get pickerUnavailable => 'हम उसे नहीं खोल सके। ऐप की कैमरा और फ़ोटो अनुमतियाँ जाँचें।';

  @override
  String get uploadFailed => 'वह अपलोड पूरा नहीं हुआ। कृपया फिर कोशिश करें।';

  @override
  String get submitForVerification => 'सत्यापन के लिए भेजें';

  @override
  String get submitConfirmTitle => 'सत्यापन के लिए भेजें?';

  @override
  String get submitConfirmBody => 'हमारी टीम की समीक्षा तक आपकी जानकारी और दस्तावेज़ लॉक रहेंगे। निर्णय आने तक आप उन्हें बदल नहीं सकेंगे।';

  @override
  String get cancelLabel => 'रद्द करें';

  @override
  String get completeEverythingBeforeSubmitting => 'भेजने से पहले हर चरण पूरा करें और सभी दस्तावेज़ अपलोड करें।';

  @override
  String get checkTheHighlightedFields => 'चिह्नित फ़ील्ड जाँचकर फिर कोशिश करें।';

  @override
  String get underReviewTitle => 'हम आपके दस्तावेज़ सत्यापित कर रहे हैं';

  @override
  String get underReviewBody => 'हमारी टीम आम तौर पर दो कार्यदिवसों में समीक्षा कर लेती है। स्वीकृति मिलते ही हम आपको बता देंगे।';

  @override
  String get checkAgain => 'फिर जाँचें';

  @override
  String get stillUnderReview => 'अब भी समीक्षा में है';

  @override
  String get rejectedTitle => 'हम आपको सत्यापित नहीं कर सके';

  @override
  String get rejectedBody => 'नीचे हमारी टीम ने जो बताया है उसे ठीक करके दस्तावेज़ फिर भेजें।';

  @override
  String get rejectionReasonLabel => 'कारण';

  @override
  String get fixAndResubmit => 'ठीक करके फिर भेजें';

  @override
  String get blockedTitle => 'आप अभी ऑनलाइन नहीं हो सकते';

  @override
  String get documentsExpiredMessage => 'आपका लाइसेंस या बीमा समाप्त हो चुका है। ऑनलाइन होने के लिए मौजूदा दस्तावेज़ अपलोड करें।';

  @override
  String get awaitingVerificationMessage => 'आपके दस्तावेज़ अब भी सत्यापित किए जा रहे हैं।';

  @override
  String get updateDocuments => 'दस्तावेज़ अपडेट करें';

  @override
  String get riderHomeTitle => 'चलने के लिए तैयार';

  @override
  String get riderHomeSubtitle => 'ऑनलाइन हों और हम आपको आस-पास की डिलीवरी भेजेंगे।';

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
  String get youAreOffline => 'आप ऑफ़लाइन हैं। आपको कोई डिलीवरी नहीं भेजी जाएगी।';

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
  String get invalidVehicleNumber => 'नंबर ठीक वैसे ही दर्ज करें जैसा नंबर प्लेट पर है';

  @override
  String get invalidAccountNumber => 'वैध खाता संख्या दर्ज करें';

  @override
  String get dateMustBeFuture => 'यह तारीख़ पहले ही बीत चुकी है';

  @override
  String get mustBeEighteen => 'डिलीवरी करने के लिए आपकी उम्र कम से कम 18 वर्ष होनी चाहिए';

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
  String get orderBoardSubtitle => 'सबसे नज़दीकी रेस्टोरेंट पहले. सूची अपने आप ताज़ा होती रहती है.';

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
  String get orderAlreadyTaken => 'यह ऑर्डर किसी और राइडर ने ले लिया. यह नई सूची है.';

  @override
  String get orderNoLongerYours => 'यह ऑर्डर अब आपका नहीं है.';

  @override
  String get boardEmptyTitle => 'अभी कोई ऑर्डर नहीं';

  @override
  String get boardEmptyBody => 'ऑनलाइन बने रहें. रेस्टोरेंट व्यस्त होते ही सूची अपने आप भर जाएगी.';

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
  String get boardNoLocationBody => 'ऑर्डर रेस्टोरेंट की दूरी के हिसाब से दिखते हैं, इसलिए कुछ भी दिखाने के लिए आपकी लोकेशन ज़रूरी है.';

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
  String get noActiveDeliveryBody => 'सूची से कोई ऑर्डर स्वीकार करें, वह यहाँ दिखने लगेगा.';

  @override
  String get confirmPickupButton => 'मैंने ले लिया है';

  @override
  String get pickupCodeTitle => 'पिकअप कोड';

  @override
  String get pickupCodeSubtitle => 'रेस्टोरेंट से कोड पूछें और यहाँ लिखें.';

  @override
  String get pickupCodeHint => 'कोड';

  @override
  String get wrongPickupCode => 'यह कोड मेल नहीं खाया. रेस्टोरेंट से दोबारा पूछें.';

  @override
  String get pickupConfirmed => 'ऑर्डर ले लिया. अब ग्राहक तक पहुँचाएँ.';

  @override
  String get confirmDeliveryButton => 'पहुँचा दिया';

  @override
  String get confirmDeliveryTitle => 'डिलीवरी की पुष्टि करें';

  @override
  String get confirmDeliveryBody => 'तभी पुष्टि करें जब ऑर्डर ग्राहक के हाथ में पहुँच चुका हो.';

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
  String get releaseOrderBody => 'यह दूसरे राइडर के लिए सूची में वापस चला जाएगा. खाना लेने से पहले ही ऐसा कर सकते हैं.';

  @override
  String get releaseReasonHint => 'कारण (ज़रूरी नहीं)';

  @override
  String get orderReleased => 'वापस कर दिया. यह दूसरे राइडर के लिए फिर उपलब्ध है.';

  @override
  String get finishCurrentOrderFirst => 'पहले अपना मौजूदा ऑर्डर पूरा करें या वापस कर दें.';

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
  String get locationUnavailableMessage => 'हम आपकी लोकेशन नहीं पढ़ पा रहे. लोकेशन चालू करें और Nexmile Rider को अनुमति दें.';

  @override
  String get locationPermissionTitle => 'लोकेशन ज़रूरी है';

  @override
  String get locationPermissionBody => 'ऑर्डर आपकी दूरी के हिसाब से बाँटे जाते हैं, और ग्राहक नक्शे पर आपको देखता है. ऑनलाइन होने के लिए लोकेशन की अनुमति दें.';

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
}
