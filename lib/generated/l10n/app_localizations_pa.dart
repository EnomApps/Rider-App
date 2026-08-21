// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Panjabi Punjabi (`pa`).
class AppLocalizationsPa extends AppLocalizations {
  AppLocalizationsPa([String locale = 'pa']) : super(locale);

  @override
  String get appName => 'Nexmile Rider';

  @override
  String get tagline => 'ਤੇਜ਼ ਡਿਲੀਵਰੀ। ਤਾਜ਼ੀ ਮੁਸਕਾਨ।';

  @override
  String get chooseLanguageTitle => 'ਆਪਣੀ ਭਾਸ਼ਾ ਚੁਣੋ';

  @override
  String get chooseLanguageSubtitle => 'ਉਹ ਭਾਸ਼ਾ ਚੁਣੋ ਜਿਸ ਵਿੱਚ ਤੁਸੀਂ ਸਹਿਜ ਹੋ। ਤੁਸੀਂ ਇਸਨੂੰ ਕਿਸੇ ਵੀ ਸਮੇਂ ਸੈਟਿੰਗਾਂ ਵਿੱਚ ਬਦਲ ਸਕਦੇ ਹੋ।';

  @override
  String get searchLanguageHint => 'ਭਾਸ਼ਾ ਖੋਜੋ';

  @override
  String get noLanguageFound => 'ਕੋਈ ਭਾਸ਼ਾ ਨਹੀਂ ਮਿਲੀ';

  @override
  String languagesAvailable(int count) {
    return '$count ਭਾਸ਼ਾਵਾਂ ਉਪਲਬਧ ਹਨ';
  }

  @override
  String get continueLabel => 'ਅੱਗੇ ਵਧੋ';

  @override
  String get selectedLabel => 'ਚੁਣੀ ਗਈ';

  @override
  String get defaultLabel => 'ਡਿਫਾਲਟ';

  @override
  String get homeTitle => 'Nexmile ਵਿੱਚ ਤੁਹਾਡਾ ਸੁਆਗਤ ਹੈ';

  @override
  String get homeSubtitle => 'ਤਾਜ਼ਾ ਕਰਿਆਨਾ, ਗਰਮ ਖਾਣਾ ਅਤੇ ਰੋਜ਼ਾਨਾ ਲੋੜਾਂ ਤੁਹਾਡੇ ਨੇੜਲੀਆਂ ਦੁਕਾਨਾਂ ਤੋਂ।';

  @override
  String get changeLanguage => 'ਭਾਸ਼ਾ ਬਦਲੋ';

  @override
  String get languageUpdated => 'ਭਾਸ਼ਾ ਬਦਲ ਦਿੱਤੀ ਗਈ';

  @override
  String get appLanguageLabel => 'ਐਪ ਦੀ ਭਾਸ਼ਾ';

  @override
  String greetingNamed(String name) {
    return 'ਸਤ ਸ੍ਰੀ ਅਕਾਲ, $name';
  }

  @override
  String get loginTitle => 'Nexmile ਵਿੱਚ ਸਾਈਨ ਇਨ ਕਰੋ';

  @override
  String get loginSubtitle => 'ਆਪਣਾ ਈਮੇਲ ਜਾਂ ਮੋਬਾਈਲ ਨੰਬਰ ਦਰਜ ਕਰੋ, ਅਸੀਂ ਤਸਦੀਕ ਕੋਡ ਭੇਜਾਂਗੇ।';

  @override
  String get emailOrPhoneLabel => 'ਈਮੇਲ ਜਾਂ ਮੋਬਾਈਲ ਨੰਬਰ';

  @override
  String get emailOrPhoneHint => 'name@example.com ਜਾਂ 9876543210';

  @override
  String get invalidEmailOrPhone => 'ਸਹੀ ਈਮੇਲ ਪਤਾ ਜਾਂ 10 ਅੰਕਾਂ ਦਾ ਮੋਬਾਈਲ ਨੰਬਰ ਦਰਜ ਕਰੋ';

  @override
  String get sendCode => 'ਕੋਡ ਭੇਜੋ';

  @override
  String get agreeToTermsOnContinue => 'ਅੱਗੇ ਵਧ ਕੇ ਤੁਸੀਂ ਸਾਡੀਆਂ ਸੇਵਾ ਸ਼ਰਤਾਂ ਅਤੇ ਪਰਦੇਦਾਰੀ ਨੀਤੀ ਨਾਲ ਸਹਿਮਤ ਹੁੰਦੇ ਹੋ।';

  @override
  String get otpTitle => 'ਪੁਸ਼ਟੀ ਕਰੋ ਕਿ ਇਹ ਤੁਸੀਂ ਹੋ';

  @override
  String otpSubtitle(String target) {
    return '$target \'ਤੇ ਭੇਜਿਆ 6 ਅੰਕਾਂ ਦਾ ਕੋਡ ਦਰਜ ਕਰੋ';
  }

  @override
  String get verifyCode => 'ਤਸਦੀਕ ਕਰੋ';

  @override
  String get resendCode => 'ਕੋਡ ਦੁਬਾਰਾ ਭੇਜੋ';

  @override
  String resendCodeIn(int seconds) {
    return '$seconds ਸਕਿੰਟਾਂ ਵਿੱਚ ਦੁਬਾਰਾ ਭੇਜੋ';
  }

  @override
  String get codeResent => 'ਨਵਾਂ ਕੋਡ ਭੇਜ ਦਿੱਤਾ ਗਿਆ ਹੈ';

  @override
  String get incorrectCode => 'ਇਹ ਕੋਡ ਗਲਤ ਹੈ ਜਾਂ ਮਿਆਦ ਪੁੱਗ ਗਈ ਹੈ। ਨਵਾਂ ਕੋਡ ਮੰਗਵਾਓ।';

  @override
  String get enterFullCode => 'ਪੂਰੇ 6 ਅੰਕ ਦਰਜ ਕਰੋ';

  @override
  String get accountSuspended => 'ਇਹ ਖਾਤਾ ਮੁਅੱਤਲ ਕਰ ਦਿੱਤਾ ਗਿਆ ਹੈ। ਕਿਰਪਾ ਕਰਕੇ ਸਹਾਇਤਾ ਨਾਲ ਸੰਪਰਕ ਕਰੋ।';

  @override
  String get tooManyAttempts => 'ਬਹੁਤ ਵਾਰ ਕੋਸ਼ਿਸ਼ ਹੋ ਗਈ। ਕਿਰਪਾ ਕਰਕੇ ਥੋੜ੍ਹੀ ਦੇਰ ਬਾਅਦ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।';

  @override
  String get sessionExpired => 'ਤੁਹਾਡਾ ਸੈਸ਼ਨ ਖਤਮ ਹੋ ਗਿਆ ਹੈ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਸਾਈਨ ਇਨ ਕਰੋ।';

  @override
  String get networkError => 'ਇੰਟਰਨੈੱਟ ਕਨੈਕਸ਼ਨ ਨਹੀਂ ਹੈ। ਆਪਣਾ ਕਨੈਕਸ਼ਨ ਜਾਂਚੋ ਅਤੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।';

  @override
  String get developmentCode => 'ਡਿਵੈਲਪਮੈਂਟ ਕੋਡ';

  @override
  String get signOut => 'ਸਾਈਨ ਆਊਟ';

  @override
  String get signedOut => 'ਤੁਸੀਂ ਸਾਈਨ ਆਊਟ ਹੋ ਗਏ ਹੋ';

  @override
  String get somethingWentWrong => 'ਕੁਝ ਗਲਤ ਹੋ ਗਿਆ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।';

  @override
  String get profileTitle => 'ਪ੍ਰੋਫਾਈਲ';

  @override
  String get viewProfile => 'ਪ੍ਰੋਫਾਈਲ ਦੇਖੋ';

  @override
  String get nameLabel => 'ਨਾਮ';

  @override
  String get emailLabel => 'ਈਮੇਲ';

  @override
  String get mobileLabel => 'ਮੋਬਾਈਲ ਨੰਬਰ';

  @override
  String get accountStatusLabel => 'ਖਾਤੇ ਦੀ ਸਥਿਤੀ';

  @override
  String get statusActive => 'ਸਰਗਰਮ';

  @override
  String get statusPending => 'ਬਕਾਇਆ';

  @override
  String get statusSuspended => 'ਮੁਅੱਤਲ';

  @override
  String get verifiedLabel => 'ਤਸਦੀਕਸ਼ੁਦਾ';

  @override
  String get notProvided => 'ਸ਼ਾਮਲ ਨਹੀਂ ਕੀਤਾ';

  @override
  String get retry => 'ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ';

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

  @override
  String get ordersTab => 'Orders';

  @override
  String get deliveryTab => 'Delivery';

  @override
  String get historyTab => 'History';

  @override
  String get orderBoardTitle => 'Orders near you';

  @override
  String get orderBoardSubtitle => 'Nearest restaurant first. The list refreshes on its own.';

  @override
  String orderNumberLabel(String number) {
    return 'Order $number';
  }

  @override
  String get pickupLabel => 'Pick up';

  @override
  String get dropoffLabel => 'Deliver to';

  @override
  String distanceMetres(String metres) {
    return '$metres m';
  }

  @override
  String distanceKilometres(String km) {
    return '$km km';
  }

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get earningsLabel => 'You earn';

  @override
  String get collectCashLabel => 'Collect cash';

  @override
  String get prepaidLabel => 'Paid online';

  @override
  String collectAtDoor(String amount) {
    return 'Collect $amount from the customer';
  }

  @override
  String get nothingToCollect => 'Already paid. Do not ask for money.';

  @override
  String get acceptOrder => 'Accept';

  @override
  String get viewOrder => 'View';

  @override
  String get orderAccepted => 'Order accepted. Head to the restaurant.';

  @override
  String get orderAlreadyTaken => 'Another rider took this one. Here is the latest list.';

  @override
  String get orderNoLongerYours => 'This order is no longer yours.';

  @override
  String get boardEmptyTitle => 'No orders right now';

  @override
  String get boardEmptyBody => 'Stay online. The list updates on its own as restaurants get busy.';

  @override
  String get boardOfflineTitle => 'You are offline';

  @override
  String get boardOfflineBody => 'Go online to start receiving orders.';

  @override
  String get boardBusyTitle => 'Finish your delivery first';

  @override
  String get boardBusyBody => 'You can take another order once this one is delivered.';

  @override
  String get boardNoLocationTitle => 'We cannot find you';

  @override
  String get boardNoLocationBody => 'Orders are sorted by how close the restaurant is, so we need your location to show you anything.';

  @override
  String get boardNotVerifiedTitle => 'Not approved to ride yet';

  @override
  String get activeDeliveryTitle => 'Your delivery';

  @override
  String get headToRestaurant => 'Head to the restaurant';

  @override
  String get deliverToCustomer => 'Deliver to the customer';

  @override
  String get noActiveDeliveryTitle => 'Nothing in hand';

  @override
  String get noActiveDeliveryBody => 'Accept an order from the board and it will show up here.';

  @override
  String get confirmPickupButton => 'I have collected it';

  @override
  String get pickupCodeTitle => 'Pickup code';

  @override
  String get pickupCodeSubtitle => 'Ask the restaurant for the code and type it here.';

  @override
  String get pickupCodeHint => 'Code';

  @override
  String get wrongPickupCode => 'That code did not match. Check it with the restaurant.';

  @override
  String get pickupConfirmed => 'Picked up. Deliver to the customer.';

  @override
  String get confirmDeliveryButton => 'Delivered';

  @override
  String get confirmDeliveryTitle => 'Confirm delivery';

  @override
  String get confirmDeliveryBody => 'Only confirm once the customer has the order in hand.';

  @override
  String confirmDeliveryCashBody(String amount) {
    return 'Collect $amount first, then confirm.';
  }

  @override
  String get deliveryConfirmed => 'Delivered. Thanks, you are back online.';

  @override
  String get releaseOrderButton => 'Hand it back';

  @override
  String get releaseOrderTitle => 'Hand this order back?';

  @override
  String get releaseOrderBody => 'It goes back on the board for another rider. You can only do this before you collect the food.';

  @override
  String get releaseReasonHint => 'Reason (optional)';

  @override
  String get orderReleased => 'Handed back. It is available to other riders again.';

  @override
  String get finishCurrentOrderFirst => 'Finish or hand back your current order first.';

  @override
  String get callRestaurant => 'Call restaurant';

  @override
  String get callCustomer => 'Call customer';

  @override
  String get openInMaps => 'Directions';

  @override
  String get customerNoteLabel => 'Note from the customer';

  @override
  String get orderItemsLabel => 'What is in the bag';

  @override
  String get orderDetailsTitle => 'Order details';

  @override
  String get historyTitle => 'Past deliveries';

  @override
  String get historyEmptyTitle => 'No deliveries yet';

  @override
  String get historyEmptyBody => 'Orders you have completed will be listed here.';

  @override
  String get orderDelivered => 'Delivered';

  @override
  String get orderCancelled => 'Cancelled';

  @override
  String get orderPreparing => 'Being prepared';

  @override
  String get orderReadyForPickup => 'Ready for pickup';

  @override
  String get orderAssigned => 'Assigned to you';

  @override
  String get orderPickedUp => 'Picked up';

  @override
  String get orderOutForDelivery => 'On the way';

  @override
  String get trackingOn => 'Location sharing on';

  @override
  String get locationUnavailableMessage => 'We cannot read your location. Turn on location and allow it for Nexmile Rider.';

  @override
  String get locationPermissionTitle => 'Location needed';

  @override
  String get locationPermissionBody => 'Dispatch sorts orders by how close you are, and the customer follows you on a map. Allow location to go online.';

  @override
  String get locationSettingsButton => 'Open settings';

  @override
  String get enableLocationButton => 'Allow location';

  @override
  String amountRupees(String amount) {
    return '₹$amount';
  }

  @override
  String get shiftTab => 'Shift';
}
