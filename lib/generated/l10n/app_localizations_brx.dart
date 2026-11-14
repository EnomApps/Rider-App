// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bodo (`brx`).
class AppLocalizationsBrx extends AppLocalizations {
  AppLocalizationsBrx([String locale = 'brx']) : super(locale);

  @override
  String get appName => 'Nexmile Rider';

  @override
  String get tagline => 'गोख्रों डेलिभारि। गोदान मिनिस्लु।';

  @override
  String get chooseLanguageTitle => 'नोंथांनि राव सायख';

  @override
  String get chooseLanguageSubtitle =>
      'नोंथांनो गोसो जायो एरै रावखौ सायख। नोंथाङो बेखौ जेब्लाबाबो सेटिंसआव सोलायनो हागोन।';

  @override
  String get searchLanguageHint => 'राव नागिर';

  @override
  String get noLanguageFound => 'जेबो राव मोनाखै';

  @override
  String languagesAvailable(int count) {
    return '$count राव मोननो हायो';
  }

  @override
  String get continueLabel => 'लाबोबाय था';

  @override
  String get selectedLabel => 'सायखनाय';

  @override
  String get defaultLabel => 'डिफल्ट';

  @override
  String get homeTitle => 'Nexmile आव आजादा';

  @override
  String get homeSubtitle =>
      'गोदान किराना, गोदै आहार आरो सानफ्रोमबो नांगौ बेसादफोर नोंथांनि खात्रिनि दुखानिफ्राय।';

  @override
  String get changeLanguage => 'राव सोलाय';

  @override
  String get languageUpdated => 'राव सोलायबाय';

  @override
  String get appLanguageLabel => 'एपनि राव';

  @override
  String greetingNamed(String name) {
    return 'आजादा, $name';
  }

  @override
  String get loginTitle => 'Nexmile आव साइन इन खालाम';

  @override
  String get loginSubtitle =>
      'नोंथांनि इमेइल एबा मबाइल नामबार दा, जों थि खालामनाय कड दैथाय होगोन।';

  @override
  String get emailOrPhoneLabel => 'इमेइल एबा मबाइल नामबार';

  @override
  String get emailOrPhoneHint => 'name@example.com एबा 9876543210';

  @override
  String get invalidEmailOrPhone => 'थार इमेइल थं एबा 10 अंकनि मबाइल नामबार दा';

  @override
  String get sendCode => 'कड दैथाय हो';

  @override
  String get agreeToTermsOnContinue =>
      'लाबोबाय थानाय जों नोंथाङो जोंनि सिबिथाइनि नेमखान्थि आरो गुबैथि नीति जों रोंगौ।';

  @override
  String get otpTitle => 'बेयो नोंथाङ नामा थि खालाम';

  @override
  String otpSubtitle(String target) {
    return '$target आव दैथाय होनाय 6 अंकनि कड दा';
  }

  @override
  String get verifyCode => 'थि खालाम';

  @override
  String get resendCode => 'कड फिन दैथाय हो';

  @override
  String resendCodeIn(int seconds) {
    return '$seconds सेकेन्डआव फिन दैथाय हो';
  }

  @override
  String get codeResent => 'गोदान कड दैथाय होबाय';

  @override
  String get incorrectCode => 'बे कडआ गोरोन्थि एबा समआ जोबबाय। गोदान कड बे।';

  @override
  String get enterFullCode => 'आबुं 6 अंक दा';

  @override
  String get accountSuspended =>
      'बे एकाउन्टखौ थाबाय होनाय जाबाय। अन्नानै मददनि जों सोंख्रीमा खालाम।';

  @override
  String get tooManyAttempts =>
      'गोबां बार नाजानाय जाबाय। अन्नानै मोनसे सम उनाव फिन नाजा।';

  @override
  String get sessionExpired =>
      'नोंथांनि सेसननि समआ जोबबाय। अन्नानै फिन साइन इन खालाम।';

  @override
  String get networkError => 'इन्टारनेट जोनाय गैया। जोनायखौ नाय आरो फिन नाजा।';

  @override
  String get developmentCode => 'डेभेलपमेन्ट कड';

  @override
  String get signOut => 'साइन आउट';

  @override
  String get signedOut => 'नोंथाङ साइन आउट जाबाय';

  @override
  String get somethingWentWrong => 'मा मानो गोरोन्थि जाबाय। अन्नानै फिन नाजा।';

  @override
  String get profileTitle => 'प्रफाइल';

  @override
  String get viewProfile => 'प्रफाइल नाय';

  @override
  String get nameLabel => 'मुं';

  @override
  String get emailLabel => 'इमेइल';

  @override
  String get mobileLabel => 'मबाइल नामबार';

  @override
  String get accountStatusLabel => 'एकाउन्टनि थाखो';

  @override
  String get statusActive => 'मावथि';

  @override
  String get statusPending => 'नेथाबाय';

  @override
  String get statusSuspended => 'थाबाय होनाय';

  @override
  String get verifiedLabel => 'थि खालामनाय';

  @override
  String get notProvided => 'दाजाबदेराखै';

  @override
  String get retry => 'फिन नाजा';

  @override
  String get loginRiderNote => 'This app is for Nexmile delivery partners.';

  @override
  String get checkingYourAccount => 'Checking your account';

  @override
  String get couldNotLoadAccount =>
      'We could not load your account. Check your connection and try again.';

  @override
  String get notARiderAccountTitle => 'This is not a delivery partner account';

  @override
  String get notARiderAccount =>
      'This email or mobile number is already registered on another Nexmile account. Sign out and use a different one to join as a delivery partner.';

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
  String get onboardingSubtitle =>
      'A few details and your documents, then our team verifies you. It usually takes up to two working days.';

  @override
  String stepOfSteps(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get stepIdentityTitle => 'About you';

  @override
  String get stepIdentitySubtitle =>
      'Enter your name exactly as it appears on your Aadhaar card.';

  @override
  String get stepVehicleTitle => 'Your vehicle';

  @override
  String get stepVehicleSubtitle =>
      'Tell us what you ride and the number plate it carries.';

  @override
  String get stepIdentityNumbersTitle => 'Identity numbers';

  @override
  String get stepIdentityNumbersSubtitle =>
      'These must match the documents you upload later.';

  @override
  String get stepLicenceTitle => 'Licence and insurance';

  @override
  String get stepLicenceSubtitle =>
      'Both must be valid on the day you start delivering.';

  @override
  String get stepBankTitle => 'Where you get paid';

  @override
  String get stepBankSubtitle =>
      'Your earnings are settled to this account. Check it carefully.';

  @override
  String get stepDocumentsTitle => 'Your documents';

  @override
  String get stepDocumentsSubtitle =>
      'Photograph each one in good light. JPG, PNG or PDF, up to 5 MB each.';

  @override
  String get stepReviewTitle => 'Check and submit';

  @override
  String get stepReviewSubtitle =>
      'Once you submit, your details are locked until our team has reviewed them.';

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
  String get vehicleWalk => 'On foot';

  @override
  String get vehicleNoPapersNote =>
      'No vehicle number or RC needed. You will be asked for Aadhaar and PAN only.';

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
  String get fileTooLarge =>
      'That file is over 5 MB. Try a photo instead of a scan.';

  @override
  String get unsupportedFileType => 'Choose a JPG, PNG or PDF.';

  @override
  String get pickerUnavailable =>
      'We could not open that. Check the app\'s camera and photo permissions.';

  @override
  String get uploadFailed =>
      'That upload did not go through. Please try again.';

  @override
  String get submitForVerification => 'Submit for verification';

  @override
  String get submitConfirmTitle => 'Submit for verification?';

  @override
  String get submitConfirmBody =>
      'Your details and documents will be locked while our team reviews them. You cannot change them until a decision is made.';

  @override
  String get cancelLabel => 'Cancel';

  @override
  String get completeEverythingBeforeSubmitting =>
      'Finish every step and upload all the documents before submitting.';

  @override
  String get checkTheHighlightedFields =>
      'Check the highlighted fields and try again.';

  @override
  String get underReviewTitle => 'We are verifying your documents';

  @override
  String get underReviewBody =>
      'Our team usually reviews within two working days. We will let you know as soon as you are approved.';

  @override
  String get checkAgain => 'Check again';

  @override
  String get stillUnderReview => 'Still under review';

  @override
  String get rejectedTitle => 'We could not verify you';

  @override
  String get rejectedBody =>
      'Fix what our team noted below, then send your documents again.';

  @override
  String get rejectionReasonLabel => 'Reason';

  @override
  String get fixAndResubmit => 'Fix and submit again';

  @override
  String get blockedTitle => 'You cannot go online yet';

  @override
  String get documentsExpiredMessage =>
      'Your licence or insurance has expired. Upload current documents to go online.';

  @override
  String get awaitingVerificationMessage =>
      'Your documents are still being verified.';

  @override
  String get updateDocuments => 'Update documents';

  @override
  String get riderHomeTitle => 'Ready to ride';

  @override
  String get riderHomeSubtitle =>
      'Go online and we will send you nearby deliveries.';

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
  String get youAreOffline =>
      'You are offline. No deliveries will be sent to you.';

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
  String get invalidVehicleNumber =>
      'Enter the number exactly as it appears on the plate';

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
  String get orderBoardSubtitle =>
      'Nearest restaurant first. The list refreshes on its own.';

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
  String get orderAlreadyTaken =>
      'Another rider took this one. Here is the latest list.';

  @override
  String get orderNoLongerYours => 'This order is no longer yours.';

  @override
  String get boardEmptyTitle => 'No orders right now';

  @override
  String get boardEmptyBody =>
      'Stay online. The list updates on its own as restaurants get busy.';

  @override
  String get boardOfflineTitle => 'You are offline';

  @override
  String get boardOfflineBody => 'Go online to start receiving orders.';

  @override
  String get boardBusyTitle => 'Finish your delivery first';

  @override
  String get boardBusyBody =>
      'You can take another order once this one is delivered.';

  @override
  String get boardNoLocationTitle => 'We cannot find you';

  @override
  String get boardNoLocationBody =>
      'Orders are sorted by how close the restaurant is, so we need your location to show you anything.';

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
  String get noActiveDeliveryBody =>
      'Accept an order from the board and it will show up here.';

  @override
  String get confirmPickupButton => 'I have collected it';

  @override
  String get pickupCodeTitle => 'Pickup code';

  @override
  String get pickupCodeSubtitle =>
      'Ask the restaurant for the code and type it here.';

  @override
  String get pickupCodeHint => 'Code';

  @override
  String get wrongPickupCode =>
      'That code did not match. Check it with the restaurant.';

  @override
  String get pickupConfirmed => 'Picked up. Deliver to the customer.';

  @override
  String get confirmDeliveryButton => 'Delivered';

  @override
  String get confirmDeliveryTitle => 'Confirm delivery';

  @override
  String get confirmDeliveryBody =>
      'Only confirm once the customer has the order in hand.';

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
  String get releaseOrderBody =>
      'It goes back on the board for another rider. You can only do this before you collect the food.';

  @override
  String get releaseReasonHint => 'Reason (optional)';

  @override
  String get orderReleased =>
      'Handed back. It is available to other riders again.';

  @override
  String get finishCurrentOrderFirst =>
      'Finish or hand back your current order first.';

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
  String get historyEmptyBody =>
      'Orders you have completed will be listed here.';

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
  String get locationUnavailableMessage =>
      'We cannot read your location. Turn on location and allow it for Nexmile Rider.';

  @override
  String get locationPermissionTitle => 'Location needed';

  @override
  String get locationPermissionBody =>
      'Dispatch sorts orders by how close you are, and the customer follows you on a map. Allow location to go online.';

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
}
