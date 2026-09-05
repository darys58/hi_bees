import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_pt.dart';

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
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('pl'),
    Locale('pt')
  ];

  /// No description provided for @voiceControl.
  ///
  /// In en, this message translates to:
  /// **'VOICE CONTROL'**
  String get voiceControl;

  /// No description provided for @voiceControlSmall.
  ///
  /// In en, this message translates to:
  /// **'Voice Control'**
  String get voiceControlSmall;

  /// No description provided for @noApiaries.
  ///
  /// In en, this message translates to:
  /// **'There are no apiaries yet.'**
  String get noApiaries;

  /// No description provided for @hiBeesDetected.
  ///
  /// In en, this message translates to:
  /// **'Listening for intent...\n\nWant help - say \"Help me!\"'**
  String get hiBeesDetected;

  /// No description provided for @listeningForHiBees.
  ///
  /// In en, this message translates to:
  /// **'Listening for \"Hey Maya!\"'**
  String get listeningForHiBees;

  /// No description provided for @iNotUderstood.
  ///
  /// In en, this message translates to:
  /// **'I not uderstood :('**
  String get iNotUderstood;

  /// No description provided for @apiary.
  ///
  /// In en, this message translates to:
  /// **'apiary'**
  String get apiary;

  /// No description provided for @apiaryAcc.
  ///
  /// In en, this message translates to:
  /// **'apiary'**
  String get apiaryAcc;

  /// No description provided for @aPiary.
  ///
  /// In en, this message translates to:
  /// **'Apiary'**
  String get aPiary;

  /// No description provided for @hive.
  ///
  /// In en, this message translates to:
  /// **'hive'**
  String get hive;

  /// No description provided for @allHives.
  ///
  /// In en, this message translates to:
  /// **'all hives'**
  String get allHives;

  /// No description provided for @body.
  ///
  /// In en, this message translates to:
  /// **'body'**
  String get body;

  /// No description provided for @halfBody.
  ///
  /// In en, this message translates to:
  /// **'half body'**
  String get halfBody;

  /// No description provided for @frame.
  ///
  /// In en, this message translates to:
  /// **'frame'**
  String get frame;

  /// No description provided for @frameAcc.
  ///
  /// In en, this message translates to:
  /// **'frame'**
  String get frameAcc;

  /// No description provided for @store.
  ///
  /// In en, this message translates to:
  /// **'store'**
  String get store;

  /// No description provided for @equipment.
  ///
  /// In en, this message translates to:
  /// **'equipment'**
  String get equipment;

  /// No description provided for @feeding.
  ///
  /// In en, this message translates to:
  /// **'feeding'**
  String get feeding;

  /// No description provided for @treatment.
  ///
  /// In en, this message translates to:
  /// **'treatment'**
  String get treatment;

  /// No description provided for @queen.
  ///
  /// In en, this message translates to:
  /// **'queen'**
  String get queen;

  /// No description provided for @setColony.
  ///
  /// In en, this message translates to:
  /// **'colony'**
  String get setColony;

  /// No description provided for @helpMe.
  ///
  /// In en, this message translates to:
  /// **'help me'**
  String get helpMe;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'date'**
  String get date;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'help'**
  String get help;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'close'**
  String get close;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'open'**
  String get open;

  /// No description provided for @open1.
  ///
  /// In en, this message translates to:
  /// **'open'**
  String get open1;

  /// No description provided for @set.
  ///
  /// In en, this message translates to:
  /// **'set'**
  String get set;

  /// No description provided for @allHivesAre.
  ///
  /// In en, this message translates to:
  /// **'\n All Hives are'**
  String get allHivesAre;

  /// No description provided for @big.
  ///
  /// In en, this message translates to:
  /// **'big'**
  String get big;

  /// No description provided for @small.
  ///
  /// In en, this message translates to:
  /// **'small'**
  String get small;

  /// No description provided for @siteOfFrame.
  ///
  /// In en, this message translates to:
  /// **'\n Site of frame ='**
  String get siteOfFrame;

  /// No description provided for @sizeOfFrame.
  ///
  /// In en, this message translates to:
  /// **'\n Size of frame ='**
  String get sizeOfFrame;

  /// No description provided for @drone.
  ///
  /// In en, this message translates to:
  /// **'drone'**
  String get drone;

  /// No description provided for @broodCovered.
  ///
  /// In en, this message translates to:
  /// **'brood covered'**
  String get broodCovered;

  /// No description provided for @larvae.
  ///
  /// In en, this message translates to:
  /// **'larvae'**
  String get larvae;

  /// No description provided for @eggs.
  ///
  /// In en, this message translates to:
  /// **'eggs'**
  String get eggs;

  /// No description provided for @pollen.
  ///
  /// In en, this message translates to:
  /// **'pollen'**
  String get pollen;

  /// No description provided for @honeySealed.
  ///
  /// In en, this message translates to:
  /// **'ripe honey'**
  String get honeySealed;

  /// No description provided for @honey.
  ///
  /// In en, this message translates to:
  /// **'honey'**
  String get honey;

  /// No description provided for @waxComb.
  ///
  /// In en, this message translates to:
  /// **'wax comb'**
  String get waxComb;

  /// No description provided for @waxFundation.
  ///
  /// In en, this message translates to:
  /// **'wax fundation'**
  String get waxFundation;

  /// No description provided for @queenCells.
  ///
  /// In en, this message translates to:
  /// **'queen cells'**
  String get queenCells;

  /// No description provided for @deleteQueenCells.
  ///
  /// In en, this message translates to:
  /// **'delete queen cells'**
  String get deleteQueenCells;

  /// No description provided for @toDo.
  ///
  /// In en, this message translates to:
  /// **'to Do'**
  String get toDo;

  /// No description provided for @isDone.
  ///
  /// In en, this message translates to:
  /// **'is Done'**
  String get isDone;

  /// No description provided for @syrup.
  ///
  /// In en, this message translates to:
  /// **'syrup'**
  String get syrup;

  /// No description provided for @sYrup.
  ///
  /// In en, this message translates to:
  /// **'Syrup'**
  String get sYrup;

  /// No description provided for @kropka.
  ///
  /// In en, this message translates to:
  /// **'.'**
  String get kropka;

  /// No description provided for @candy.
  ///
  /// In en, this message translates to:
  /// **'candy'**
  String get candy;

  /// No description provided for @cAndy.
  ///
  /// In en, this message translates to:
  /// **'Candy'**
  String get cAndy;

  /// No description provided for @invert.
  ///
  /// In en, this message translates to:
  /// **'invert'**
  String get invert;

  /// No description provided for @removedFood.
  ///
  /// In en, this message translates to:
  /// **'removed food'**
  String get removedFood;

  /// No description provided for @leftFood.
  ///
  /// In en, this message translates to:
  /// **'left food'**
  String get leftFood;

  /// No description provided for @dose.
  ///
  /// In en, this message translates to:
  /// **'dose'**
  String get dose;

  /// No description provided for @belts.
  ///
  /// In en, this message translates to:
  /// **'belts'**
  String get belts;

  /// No description provided for @mites.
  ///
  /// In en, this message translates to:
  /// **'mites'**
  String get mites;

  /// No description provided for @queenIs.
  ///
  /// In en, this message translates to:
  /// **'queen is'**
  String get queenIs;

  /// No description provided for @queenWasBornIn20.
  ///
  /// In en, this message translates to:
  /// **'queen was born in 20'**
  String get queenWasBornIn20;

  /// No description provided for @queenWasBornIn.
  ///
  /// In en, this message translates to:
  /// **'queen was born in '**
  String get queenWasBornIn;

  /// No description provided for @numberOfFrame.
  ///
  /// In en, this message translates to:
  /// **'number of frame'**
  String get numberOfFrame;

  /// No description provided for @excluder.
  ///
  /// In en, this message translates to:
  /// **'excluder'**
  String get excluder;

  /// No description provided for @exclud.
  ///
  /// In en, this message translates to:
  /// **'excluder'**
  String get exclud;

  /// No description provided for @eXclud.
  ///
  /// In en, this message translates to:
  /// **'Grid/grate'**
  String get eXclud;

  /// No description provided for @excludNo.
  ///
  /// In en, this message translates to:
  /// **'no excluder'**
  String get excludNo;

  /// No description provided for @on.
  ///
  /// In en, this message translates to:
  /// **'on'**
  String get on;

  /// No description provided for @onBodyNumber.
  ///
  /// In en, this message translates to:
  /// **'on body number'**
  String get onBodyNumber;

  /// No description provided for @bottomBoard.
  ///
  /// In en, this message translates to:
  /// **'bottom board'**
  String get bottomBoard;

  /// No description provided for @dennica.
  ///
  /// In en, this message translates to:
  /// **'bottom board'**
  String get dennica;

  /// No description provided for @isIs.
  ///
  /// In en, this message translates to:
  /// **'is'**
  String get isIs;

  /// No description provided for @beePollenTrap.
  ///
  /// In en, this message translates to:
  /// **'bee pollen trap'**
  String get beePollenTrap;

  /// No description provided for @colony.
  ///
  /// In en, this message translates to:
  /// **'colony'**
  String get colony;

  /// No description provided for @day.
  ///
  /// In en, this message translates to:
  /// **'day'**
  String get day;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'month'**
  String get month;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'year'**
  String get year;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @wrongCommand.
  ///
  /// In en, this message translates to:
  /// **'Wrong command'**
  String get wrongCommand;

  /// No description provided for @inspection.
  ///
  /// In en, this message translates to:
  /// **'inspection'**
  String get inspection;

  /// No description provided for @both.
  ///
  /// In en, this message translates to:
  /// **'both'**
  String get both;

  /// No description provided for @invalidApiaryNumber.
  ///
  /// In en, this message translates to:
  /// **'invalid apiary number'**
  String get invalidApiaryNumber;

  /// No description provided for @allTheHivesAreOpen.
  ///
  /// In en, this message translates to:
  /// **'All the hives are open'**
  String get allTheHivesAreOpen;

  /// No description provided for @allHivesAreClose.
  ///
  /// In en, this message translates to:
  /// **'All hives are close'**
  String get allHivesAreClose;

  /// No description provided for @invalidHiveNumber.
  ///
  /// In en, this message translates to:
  /// **'invalid hive number'**
  String get invalidHiveNumber;

  /// No description provided for @invalidBodyNumber.
  ///
  /// In en, this message translates to:
  /// **'invalid body number'**
  String get invalidBodyNumber;

  /// No description provided for @invalidHalfBodyNumber.
  ///
  /// In en, this message translates to:
  /// **'invalid half body number'**
  String get invalidHalfBodyNumber;

  /// No description provided for @invalidFrameNumber.
  ///
  /// In en, this message translates to:
  /// **'invalid frame number'**
  String get invalidFrameNumber;

  /// No description provided for @frameOn.
  ///
  /// In en, this message translates to:
  /// **'frame on'**
  String get frameOn;

  /// No description provided for @site.
  ///
  /// In en, this message translates to:
  /// **'side'**
  String get site;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @noSave.
  ///
  /// In en, this message translates to:
  /// **'No save - invalid frame number'**
  String get noSave;

  /// No description provided for @noSaveInfo.
  ///
  /// In en, this message translates to:
  /// **'No save - invalid hive number'**
  String get noSaveInfo;

  /// No description provided for @thereAreNoHives.
  ///
  /// In en, this message translates to:
  /// **'There are no hives'**
  String get thereAreNoHives;

  /// No description provided for @alert.
  ///
  /// In en, this message translates to:
  /// **'Alert'**
  String get alert;

  /// No description provided for @subscriptionEndsIn.
  ///
  /// In en, this message translates to:
  /// **'Subscription ends in'**
  String get subscriptionEndsIn;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @activationCodeWillBeSent.
  ///
  /// In en, this message translates to:
  /// **'Thank you for sending your email address. The activation code for the application has been sent to the provided address.'**
  String get activationCodeWillBeSent;

  /// No description provided for @sendAgain.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while sending. Send it again.'**
  String get sendAgain;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @willBeActiveUntil.
  ///
  /// In en, this message translates to:
  /// **'The application is active '**
  String get willBeActiveUntil;

  /// No description provided for @errorWhileActivating.
  ///
  /// In en, this message translates to:
  /// **'Error while activating the application.'**
  String get errorWhileActivating;

  /// No description provided for @activate.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get activate;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @enterYourActivationCode.
  ///
  /// In en, this message translates to:
  /// **'Enter your activation code. If you do not have an activation code, enter your email address to which the free activation code will be sent.\nMore information at heymaya.eu'**
  String get enterYourActivationCode;

  /// No description provided for @activationCodeAfterPaying.
  ///
  /// In en, this message translates to:
  /// **'Enter your activation code. If you do not have an activation code, enter your e-mail address to receive an activation code after paying for the subscription. You can also use the application without activation but without Voice Control.\nMore information at heymaya.eu'**
  String get activationCodeAfterPaying;

  /// No description provided for @codeOrEmail.
  ///
  /// In en, this message translates to:
  /// **'Code or e-mail'**
  String get codeOrEmail;

  /// No description provided for @enterCodeOrEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter code or e-mail'**
  String get enterCodeOrEmail;

  /// No description provided for @noInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection.'**
  String get noInternet;

  /// No description provided for @noActivation.
  ///
  /// In en, this message translates to:
  /// **'No activation'**
  String get noActivation;

  /// No description provided for @subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// No description provided for @hives.
  ///
  /// In en, this message translates to:
  /// **'hives'**
  String get hives;

  /// No description provided for @hivesPlural.
  ///
  /// In en, this message translates to:
  /// **'hives'**
  String get hivesPlural;

  /// No description provided for @hIve.
  ///
  /// In en, this message translates to:
  /// **'Hive'**
  String get hIve;

  /// No description provided for @dAy.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get dAy;

  /// No description provided for @removeThisItem.
  ///
  /// In en, this message translates to:
  /// **'Are you sure to remove this item?'**
  String get removeThisItem;

  /// No description provided for @deletePermanently.
  ///
  /// In en, this message translates to:
  /// **'It will delete item permanently.'**
  String get deletePermanently;

  /// No description provided for @inspectionDeleted.
  ///
  /// In en, this message translates to:
  /// **'The inspection has been deleted'**
  String get inspectionDeleted;

  /// No description provided for @yesDelete.
  ///
  /// In en, this message translates to:
  /// **'Yes Delete'**
  String get yesDelete;

  /// No description provided for @cantDelete.
  ///
  /// In en, this message translates to:
  /// **'You can\'t delete last item!'**
  String get cantDelete;

  /// No description provided for @deleteWholeIspection.
  ///
  /// In en, this message translates to:
  /// **'You can delete whole ispection in screen witch information about all inspections.'**
  String get deleteWholeIspection;

  /// No description provided for @smallFrame.
  ///
  /// In en, this message translates to:
  /// **'frame'**
  String get smallFrame;

  /// No description provided for @fRame.
  ///
  /// In en, this message translates to:
  /// **'Frame'**
  String get fRame;

  /// No description provided for @noDetailsYet.
  ///
  /// In en, this message translates to:
  /// **'There are no details yet.'**
  String get noDetailsYet;

  /// No description provided for @editInspectionHive.
  ///
  /// In en, this message translates to:
  /// **'Edit inspection hive'**
  String get editInspectionHive;

  /// No description provided for @bigInspections.
  ///
  /// In en, this message translates to:
  /// **'INSPECTIONS'**
  String get bigInspections;

  /// No description provided for @noInfoInThisCategory.
  ///
  /// In en, this message translates to:
  /// **'There is no information in this category yet.'**
  String get noInfoInThisCategory;

  /// No description provided for @disable.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get disable;

  /// No description provided for @inspectionHive.
  ///
  /// In en, this message translates to:
  /// **'Inspection hive'**
  String get inspectionHive;

  /// No description provided for @noInspectionYet.
  ///
  /// In en, this message translates to:
  /// **'There are no inspection yet.'**
  String get noInspectionYet;

  /// No description provided for @noFramesInInspection.
  ///
  /// In en, this message translates to:
  /// **'This inspection has no frames recorded yet.'**
  String get noFramesInInspection;

  /// No description provided for @left.
  ///
  /// In en, this message translates to:
  /// **'left'**
  String get left;

  /// No description provided for @right.
  ///
  /// In en, this message translates to:
  /// **'right'**
  String get right;

  /// No description provided for @inspectionSay.
  ///
  /// In en, this message translates to:
  /// **'Inspection:'**
  String get inspectionSay;

  /// No description provided for @oPen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get oPen;

  /// No description provided for @sEt.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get sEt;

  /// No description provided for @number.
  ///
  /// In en, this message translates to:
  /// **'number'**
  String get number;

  /// No description provided for @nUmber.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get nUmber;

  /// No description provided for @iNspection.
  ///
  /// In en, this message translates to:
  /// **'Inspection'**
  String get iNspection;

  /// No description provided for @leftRightBoth.
  ///
  /// In en, this message translates to:
  /// **'on the left/right/both'**
  String get leftRightBoth;

  /// No description provided for @whenTheApiary.
  ///
  /// In en, this message translates to:
  /// **'(when the apiary, hive, body and frame are open say e.g.:)'**
  String get whenTheApiary;

  /// No description provided for @leftRight.
  ///
  /// In en, this message translates to:
  /// **'on the left/right'**
  String get leftRight;

  /// No description provided for @larvaeEggsPollenHoneySealdWaxComb.
  ///
  /// In en, this message translates to:
  /// **'larvae/eggs/pollen/honey/food/ripe/wax/comb'**
  String get larvaeEggsPollenHoneySealdWaxComb;

  /// No description provided for @dElete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get dElete;

  /// No description provided for @workFrameToExtraction.
  ///
  /// In en, this message translates to:
  /// **'work frame/to extraction/to delete/to insulate'**
  String get workFrameToExtraction;

  /// No description provided for @tOdo.
  ///
  /// In en, this message translates to:
  /// **'to do'**
  String get tOdo;

  /// No description provided for @deletedInserted.
  ///
  /// In en, this message translates to:
  /// **'deleted/inserted/insulated/moved left/moved right'**
  String get deletedInserted;

  /// No description provided for @iSdone.
  ///
  /// In en, this message translates to:
  /// **'is done'**
  String get iSdone;

  /// No description provided for @equipmentSay.
  ///
  /// In en, this message translates to:
  /// **'Equipment:'**
  String get equipmentSay;

  /// No description provided for @whenAtLeastApiaryAndHive.
  ///
  /// In en, this message translates to:
  /// **'(when at least the apiary and hive are open say e.g.:)'**
  String get whenAtLeastApiaryAndHive;

  /// No description provided for @frameNumber.
  ///
  /// In en, this message translates to:
  /// **'frame number'**
  String get frameNumber;

  /// No description provided for @inBody.
  ///
  /// In en, this message translates to:
  /// **'in body'**
  String get inBody;

  /// No description provided for @bOttomBoard.
  ///
  /// In en, this message translates to:
  /// **'Bottom board'**
  String get bOttomBoard;

  /// No description provided for @isDisinfectedOkDirty.
  ///
  /// In en, this message translates to:
  /// **'is ok/dirty/clean'**
  String get isDisinfectedOkDirty;

  /// No description provided for @beepOllenTrap.
  ///
  /// In en, this message translates to:
  /// **'Bee pollen trap'**
  String get beepOllenTrap;

  /// No description provided for @queenSay.
  ///
  /// In en, this message translates to:
  /// **'Queen:'**
  String get queenSay;

  /// No description provided for @qUeen.
  ///
  /// In en, this message translates to:
  /// **'Queen'**
  String get qUeen;

  /// No description provided for @wasBornIn.
  ///
  /// In en, this message translates to:
  /// **'was born in'**
  String get wasBornIn;

  /// No description provided for @bornIn.
  ///
  /// In en, this message translates to:
  /// **'born in'**
  String get bornIn;

  /// No description provided for @isVirgine.
  ///
  /// In en, this message translates to:
  /// **'is virgin/artificially inseminated/naturally mated'**
  String get isVirgine;

  /// No description provided for @isFreed.
  ///
  /// In en, this message translates to:
  /// **'is freed/in a cage/in the insulator'**
  String get isFreed;

  /// No description provided for @isVeryGoodCanceled.
  ///
  /// In en, this message translates to:
  /// **'is very good/good/ok/big/small/weak/to exchange/old'**
  String get isVeryGoodCanceled;

  /// No description provided for @isMarked.
  ///
  /// In en, this message translates to:
  /// **'is unmarked/marked white/marked yellow/marked red/marked green/marked blue/gone/missing'**
  String get isMarked;

  /// No description provided for @colonySay.
  ///
  /// In en, this message translates to:
  /// **'Colony:'**
  String get colonySay;

  /// No description provided for @cOlony.
  ///
  /// In en, this message translates to:
  /// **'Colony'**
  String get cOlony;

  /// No description provided for @deadFlight.
  ///
  /// In en, this message translates to:
  /// **'gentle/aggressive/ok/swarming mood/in a cluster/dead'**
  String get deadFlight;

  /// No description provided for @veryWeakStrong.
  ///
  /// In en, this message translates to:
  /// **'very strong/strong/normal/weak/very weak'**
  String get veryWeakStrong;

  /// No description provided for @feedingSay.
  ///
  /// In en, this message translates to:
  /// **'Feeding:'**
  String get feedingSay;

  /// No description provided for @syrupOneToOne.
  ///
  /// In en, this message translates to:
  /// **'syrup one to one'**
  String get syrupOneToOne;

  /// No description provided for @point.
  ///
  /// In en, this message translates to:
  /// **'point'**
  String get point;

  /// No description provided for @liters.
  ///
  /// In en, this message translates to:
  /// **'liters'**
  String get liters;

  /// No description provided for @syrupThreeToTwo.
  ///
  /// In en, this message translates to:
  /// **'syrup three to two'**
  String get syrupThreeToTwo;

  /// No description provided for @lEftFood.
  ///
  /// In en, this message translates to:
  /// **'Left food'**
  String get lEftFood;

  /// No description provided for @rEmoveFood.
  ///
  /// In en, this message translates to:
  /// **'Remove food'**
  String get rEmoveFood;

  /// No description provided for @treatmentSay.
  ///
  /// In en, this message translates to:
  /// **'Treatment:'**
  String get treatmentSay;

  /// No description provided for @apivarolChemistry.
  ///
  /// In en, this message translates to:
  /// **'Chemistry'**
  String get apivarolChemistry;

  /// No description provided for @dosePortionPart.
  ///
  /// In en, this message translates to:
  /// **'dose/portion'**
  String get dosePortionPart;

  /// No description provided for @first.
  ///
  /// In en, this message translates to:
  /// **'1st'**
  String get first;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'remove'**
  String get remove;

  /// No description provided for @remove1.
  ///
  /// In en, this message translates to:
  /// **'removed'**
  String get remove1;

  /// No description provided for @vArroa.
  ///
  /// In en, this message translates to:
  /// **'Varroa'**
  String get vArroa;

  /// No description provided for @bee.
  ///
  /// In en, this message translates to:
  /// **'bee '**
  String get bee;

  /// No description provided for @dateSay.
  ///
  /// In en, this message translates to:
  /// **'Date - say e.g.:'**
  String get dateSay;

  /// No description provided for @setOther.
  ///
  /// In en, this message translates to:
  /// **'Set other'**
  String get setOther;

  /// No description provided for @current.
  ///
  /// In en, this message translates to:
  /// **'current'**
  String get current;

  /// No description provided for @datee.
  ///
  /// In en, this message translates to:
  /// **'date'**
  String get datee;

  /// No description provided for @helpSay.
  ///
  /// In en, this message translates to:
  /// **'Help:'**
  String get helpSay;

  /// No description provided for @forPreciseHelp.
  ///
  /// In en, this message translates to:
  /// **'for precise help say e.g.:'**
  String get forPreciseHelp;

  /// No description provided for @eQuipment.
  ///
  /// In en, this message translates to:
  /// **'Equipment'**
  String get eQuipment;

  /// No description provided for @fEeding.
  ///
  /// In en, this message translates to:
  /// **'Feeding'**
  String get fEeding;

  /// No description provided for @tReatment.
  ///
  /// In en, this message translates to:
  /// **'Treatment'**
  String get tReatment;

  /// No description provided for @dAte.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dAte;

  /// No description provided for @closeHelp.
  ///
  /// In en, this message translates to:
  /// **'Close help'**
  String get closeHelp;

  /// No description provided for @me.
  ///
  /// In en, this message translates to:
  /// **'me'**
  String get me;

  /// No description provided for @legend.
  ///
  /// In en, this message translates to:
  /// **'Legend'**
  String get legend;

  /// No description provided for @normalOr.
  ///
  /// In en, this message translates to:
  /// **'Normal or'**
  String get normalOr;

  /// No description provided for @bold.
  ///
  /// In en, this message translates to:
  /// **'bold'**
  String get bold;

  /// No description provided for @requiredText.
  ///
  /// In en, this message translates to:
  /// **'required text'**
  String get requiredText;

  /// No description provided for @italic.
  ///
  /// In en, this message translates to:
  /// **'Italic'**
  String get italic;

  /// No description provided for @optionalText.
  ///
  /// In en, this message translates to:
  /// **'optional text'**
  String get optionalText;

  /// No description provided for @text1Text2.
  ///
  /// In en, this message translates to:
  /// **'Text1/text2'**
  String get text1Text2;

  /// No description provided for @selectableText.
  ///
  /// In en, this message translates to:
  /// **'selectable text'**
  String get selectableText;

  /// No description provided for @sampleValue.
  ///
  /// In en, this message translates to:
  /// **'sample value'**
  String get sampleValue;

  /// No description provided for @workFrame.
  ///
  /// In en, this message translates to:
  /// **'work frame'**
  String get workFrame;

  /// No description provided for @tryingToConnect.
  ///
  /// In en, this message translates to:
  /// **'Trying to connect'**
  String get tryingToConnect;

  /// No description provided for @theStoreIs.
  ///
  /// In en, this message translates to:
  /// **'The store is'**
  String get theStoreIs;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'available'**
  String get available;

  /// No description provided for @unavailable.
  ///
  /// In en, this message translates to:
  /// **'unavailable'**
  String get unavailable;

  /// No description provided for @notConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get notConnected;

  /// No description provided for @fetchingProducts.
  ///
  /// In en, this message translates to:
  /// **'Fetching products'**
  String get fetchingProducts;

  /// No description provided for @productsForSale.
  ///
  /// In en, this message translates to:
  /// **'Products for Sale'**
  String get productsForSale;

  /// No description provided for @notFound.
  ///
  /// In en, this message translates to:
  /// **'not found'**
  String get notFound;

  /// No description provided for @fetchingConsumables.
  ///
  /// In en, this message translates to:
  /// **'Fetching consumables'**
  String get fetchingConsumables;

  /// No description provided for @purchasedConsumables.
  ///
  /// In en, this message translates to:
  /// **'Purchased consumables'**
  String get purchasedConsumables;

  /// No description provided for @restorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get restorePurchases;

  /// No description provided for @priceChangeAccepted.
  ///
  /// In en, this message translates to:
  /// **'Price change accepted'**
  String get priceChangeAccepted;

  /// No description provided for @priceChangeFailedWithCode.
  ///
  /// In en, this message translates to:
  /// **'Price change failed with code'**
  String get priceChangeFailedWithCode;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @import.
  ///
  /// In en, this message translates to:
  /// **'Data import from the cloud'**
  String get import;

  /// No description provided for @importuj.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importuj;

  /// No description provided for @brakInternetu.
  ///
  /// In en, this message translates to:
  /// **'No internet'**
  String get brakInternetu;

  /// No description provided for @uruchomPonownie.
  ///
  /// In en, this message translates to:
  /// **'Restart your internet connection and try again'**
  String get uruchomPonownie;

  /// No description provided for @importowanie.
  ///
  /// In en, this message translates to:
  /// **'All data from cloud will be added to the local database'**
  String get importowanie;

  /// No description provided for @exportNewToCloud.
  ///
  /// In en, this message translates to:
  /// **'Exporting new data to the cloud'**
  String get exportNewToCloud;

  /// No description provided for @autoEksportDoChmury.
  ///
  /// In en, this message translates to:
  /// **'Automatic data export'**
  String get autoEksportDoChmury;

  /// No description provided for @onlyInspection.
  ///
  /// In en, this message translates to:
  /// **'after launching the application, only detailed data regarding frames, equipment, families, queens, harvests, feeding, and treatment is automatically sent to the cloud. Notes, Harvest, Purchases, Sales and Photos are not sent.'**
  String get onlyInspection;

  /// No description provided for @zarzadzanieDanymi.
  ///
  /// In en, this message translates to:
  /// **'Data management'**
  String get zarzadzanieDanymi;

  /// No description provided for @dopisanieDoBazy.
  ///
  /// In en, this message translates to:
  /// **'adding to the local database'**
  String get dopisanieDoBazy;

  /// No description provided for @importYear.
  ///
  /// In en, this message translates to:
  /// **'Importing data from a selected year'**
  String get importYear;

  /// No description provided for @importYearDesc.
  ///
  /// In en, this message translates to:
  /// **'Only cloud data from the selected year will be added to the local database.'**
  String get importYearDesc;

  /// No description provided for @importYearSubtitle.
  ///
  /// In en, this message translates to:
  /// **'faster import - selected year only'**
  String get importYearSubtitle;

  /// No description provided for @powrotBezZmian.
  ///
  /// In en, this message translates to:
  /// **'Return unchanged'**
  String get powrotBezZmian;

  /// No description provided for @bezPrzegladu.
  ///
  /// In en, this message translates to:
  /// **'without review'**
  String get bezPrzegladu;

  /// No description provided for @harvest.
  ///
  /// In en, this message translates to:
  /// **'harvests'**
  String get harvest;

  /// No description provided for @portion.
  ///
  /// In en, this message translates to:
  /// **'portion'**
  String get portion;

  /// No description provided for @frames.
  ///
  /// In en, this message translates to:
  /// **'frames'**
  String get frames;

  /// No description provided for @frames2.
  ///
  /// In en, this message translates to:
  /// **'frames'**
  String get frames2;

  /// No description provided for @harvestSay.
  ///
  /// In en, this message translates to:
  /// **'Harvest:'**
  String get harvestSay;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'from'**
  String get from;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'to'**
  String get to;

  /// No description provided for @honeyHarvest.
  ///
  /// In en, this message translates to:
  /// **'Honey harvest'**
  String get honeyHarvest;

  /// No description provided for @razy.
  ///
  /// In en, this message translates to:
  /// **''**
  String get razy;

  /// No description provided for @miarka.
  ///
  /// In en, this message translates to:
  /// **'portion'**
  String get miarka;

  /// No description provided for @beePollenHarvest.
  ///
  /// In en, this message translates to:
  /// **'Bee pollen harvest'**
  String get beePollenHarvest;

  /// No description provided for @trut.
  ///
  /// In en, this message translates to:
  /// **'drone'**
  String get trut;

  /// No description provided for @covered.
  ///
  /// In en, this message translates to:
  /// **'capped/sealed'**
  String get covered;

  /// No description provided for @bRood.
  ///
  /// In en, this message translates to:
  /// **'brood'**
  String get bRood;

  /// No description provided for @hArvest.
  ///
  /// In en, this message translates to:
  /// **'Harvest'**
  String get hArvest;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About app'**
  String get about;

  /// No description provided for @versionApp.
  ///
  /// In en, this message translates to:
  /// **'App version: '**
  String get versionApp;

  /// No description provided for @activationCode.
  ///
  /// In en, this message translates to:
  /// **'Activation code: '**
  String get activationCode;

  /// No description provided for @subscryptionTo.
  ///
  /// In en, this message translates to:
  /// **'Subscryption to: '**
  String get subscryptionTo;

  /// No description provided for @onlyNew.
  ///
  /// In en, this message translates to:
  /// **'only not previously shipped, from all categories'**
  String get onlyNew;

  /// No description provided for @exportNewData.
  ///
  /// In en, this message translates to:
  /// **'Only data that has not yet been sent will be sent'**
  String get exportNewData;

  /// No description provided for @eXport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get eXport;

  /// No description provided for @noDataToSend.
  ///
  /// In en, this message translates to:
  /// **'No new data to send'**
  String get noDataToSend;

  /// No description provided for @dataToSend.
  ///
  /// In en, this message translates to:
  /// **'Number of records sent'**
  String get dataToSend;

  /// No description provided for @noInfosToArch.
  ///
  /// In en, this message translates to:
  /// **'No new info to archive'**
  String get noInfosToArch;

  /// No description provided for @aCtivation.
  ///
  /// In en, this message translates to:
  /// **'Activation'**
  String get aCtivation;

  /// No description provided for @refreshActivation.
  ///
  /// In en, this message translates to:
  /// **'Refresh activation'**
  String get refreshActivation;

  /// No description provided for @inspectionDataSend.
  ///
  /// In en, this message translates to:
  /// **'Inspection data has been sent'**
  String get inspectionDataSend;

  /// No description provided for @infoDataSend.
  ///
  /// In en, this message translates to:
  /// **'Info data has been sent'**
  String get infoDataSend;

  /// No description provided for @exportAllData.
  ///
  /// In en, this message translates to:
  /// **'All data will be sent - data in the cloud will be replaced with data sent.'**
  String get exportAllData;

  /// No description provided for @exportDataToCloud.
  ///
  /// In en, this message translates to:
  /// **'Data in the cloud will be replaced with data sent'**
  String get exportDataToCloud;

  /// No description provided for @exportAllToCloud.
  ///
  /// In en, this message translates to:
  /// **'Export all data to the cloud'**
  String get exportAllToCloud;

  /// No description provided for @importEnd.
  ///
  /// In en, this message translates to:
  /// **'Data import completed'**
  String get importEnd;

  /// No description provided for @dataImport.
  ///
  /// In en, this message translates to:
  /// **'Data import from the cloud'**
  String get dataImport;

  /// No description provided for @unablaToSend.
  ///
  /// In en, this message translates to:
  /// **'Unable to send data to the cloud - no internet.'**
  String get unablaToSend;

  /// No description provided for @editFrame.
  ///
  /// In en, this message translates to:
  /// **'Edit frame item'**
  String get editFrame;

  /// No description provided for @toExtraction.
  ///
  /// In en, this message translates to:
  /// **'to extraction'**
  String get toExtraction;

  /// No description provided for @toDelete.
  ///
  /// In en, this message translates to:
  /// **'to delete'**
  String get toDelete;

  /// No description provided for @toInsulate.
  ///
  /// In en, this message translates to:
  /// **'to insulate'**
  String get toInsulate;

  /// No description provided for @deleted.
  ///
  /// In en, this message translates to:
  /// **'deleted'**
  String get deleted;

  /// No description provided for @inserted.
  ///
  /// In en, this message translates to:
  /// **'inserted'**
  String get inserted;

  /// No description provided for @insert.
  ///
  /// In en, this message translates to:
  /// **'insert'**
  String get insert;

  /// No description provided for @iNsert.
  ///
  /// In en, this message translates to:
  /// **'Insert'**
  String get iNsert;

  /// No description provided for @insulated.
  ///
  /// In en, this message translates to:
  /// **'insulated'**
  String get insulated;

  /// No description provided for @movedLeft.
  ///
  /// In en, this message translates to:
  /// **'moved left'**
  String get movedLeft;

  /// No description provided for @movedRight.
  ///
  /// In en, this message translates to:
  /// **'moved right'**
  String get movedRight;

  /// No description provided for @replace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get replace;

  /// No description provided for @saveZ.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveZ;

  /// No description provided for @addingNewEntry.
  ///
  /// In en, this message translates to:
  /// **'Adding a new entry'**
  String get addingNewEntry;

  /// No description provided for @selectEntryType.
  ///
  /// In en, this message translates to:
  /// **'Select an entry type'**
  String get selectEntryType;

  /// No description provided for @resourceOnFrame.
  ///
  /// In en, this message translates to:
  /// **'Resources on frame'**
  String get resourceOnFrame;

  /// No description provided for @resourceOnFramePlus.
  ///
  /// In en, this message translates to:
  /// **'Resources on frame +'**
  String get resourceOnFramePlus;

  /// No description provided for @resourceOnFrameMinus.
  ///
  /// In en, this message translates to:
  /// **'Resources on frame -'**
  String get resourceOnFrameMinus;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get updateAvailable;

  /// No description provided for @updateAvailableMsg.
  ///
  /// In en, this message translates to:
  /// **'A new version of the app is available in the store. Update to get the latest features and fixes.'**
  String get updateAvailableMsg;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateNow;

  /// No description provided for @toDO.
  ///
  /// In en, this message translates to:
  /// **'To do'**
  String get toDO;

  /// No description provided for @itWasDone.
  ///
  /// In en, this message translates to:
  /// **'It was done'**
  String get itWasDone;

  /// No description provided for @edited.
  ///
  /// In en, this message translates to:
  /// **'edited'**
  String get edited;

  /// No description provided for @pleaseWait.
  ///
  /// In en, this message translates to:
  /// **'please wait'**
  String get pleaseWait;

  /// No description provided for @noHarvestYet.
  ///
  /// In en, this message translates to:
  /// **'There are no harvest yet.'**
  String get noHarvestYet;

  /// No description provided for @editHarvest.
  ///
  /// In en, this message translates to:
  /// **'Harvest edition'**
  String get editHarvest;

  /// No description provided for @perga.
  ///
  /// In en, this message translates to:
  /// **'perga'**
  String get perga;

  /// No description provided for @wax.
  ///
  /// In en, this message translates to:
  /// **'wax'**
  String get wax;

  /// No description provided for @hArvests.
  ///
  /// In en, this message translates to:
  /// **'Harvests'**
  String get hArvests;

  /// No description provided for @inspectionDate.
  ///
  /// In en, this message translates to:
  /// **'Inspection date'**
  String get inspectionDate;

  /// No description provided for @harvestDate.
  ///
  /// In en, this message translates to:
  /// **'Harvest date'**
  String get harvestDate;

  /// No description provided for @enter.
  ///
  /// In en, this message translates to:
  /// **'enter'**
  String get enter;

  /// No description provided for @yYYY.
  ///
  /// In en, this message translates to:
  /// **'YYYY'**
  String get yYYY;

  /// No description provided for @apiaryNr.
  ///
  /// In en, this message translates to:
  /// **'Apiary number'**
  String get apiaryNr;

  /// No description provided for @hIveNr.
  ///
  /// In en, this message translates to:
  /// **'Hive number'**
  String get hIveNr;

  /// No description provided for @hiveNr.
  ///
  /// In en, this message translates to:
  /// **'hive nr'**
  String get hiveNr;

  /// No description provided for @bodyNr.
  ///
  /// In en, this message translates to:
  /// **'body nr'**
  String get bodyNr;

  /// No description provided for @frameNr.
  ///
  /// In en, this message translates to:
  /// **'frame nr'**
  String get frameNr;

  /// No description provided for @changeFrame.
  ///
  /// In en, this message translates to:
  /// **'change frame nr'**
  String get changeFrame;

  /// No description provided for @moveFrame.
  ///
  /// In en, this message translates to:
  /// **'move frame'**
  String get moveFrame;

  /// No description provided for @sIze.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get sIze;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'quantity'**
  String get quantity;

  /// No description provided for @pcs.
  ///
  /// In en, this message translates to:
  /// **'pcs.'**
  String get pcs;

  /// No description provided for @cOmments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get cOmments;

  /// No description provided for @comments.
  ///
  /// In en, this message translates to:
  /// **'comments'**
  String get comments;

  /// No description provided for @beePollen.
  ///
  /// In en, this message translates to:
  /// **'bee pollen'**
  String get beePollen;

  /// No description provided for @editingHarvest.
  ///
  /// In en, this message translates to:
  /// **'Editing harvest'**
  String get editingHarvest;

  /// No description provided for @addHarvest.
  ///
  /// In en, this message translates to:
  /// **'Add harvest'**
  String get addHarvest;

  /// No description provided for @pArameterization.
  ///
  /// In en, this message translates to:
  /// **'Parameterization'**
  String get pArameterization;

  /// No description provided for @beePollenZbior.
  ///
  /// In en, this message translates to:
  /// **'Bee pollen harvest'**
  String get beePollenZbior;

  /// No description provided for @honeyZbior.
  ///
  /// In en, this message translates to:
  /// **'Honey harvest'**
  String get honeyZbior;

  /// No description provided for @queenColors.
  ///
  /// In en, this message translates to:
  /// **'black/yellow/red/green/blue/white'**
  String get queenColors;

  /// No description provided for @earlier.
  ///
  /// In en, this message translates to:
  /// **'earlier'**
  String get earlier;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'later'**
  String get later;

  /// No description provided for @lAter.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get lAter;

  /// No description provided for @celsius.
  ///
  /// In en, this message translates to:
  /// **'Celsius'**
  String get celsius;

  /// No description provided for @kelvin.
  ///
  /// In en, this message translates to:
  /// **'Kelvin'**
  String get kelvin;

  /// No description provided for @fahrenheit.
  ///
  /// In en, this message translates to:
  /// **'Fahrenheit'**
  String get fahrenheit;

  /// No description provided for @pogodaNieaktualna.
  ///
  /// In en, this message translates to:
  /// **'No internet connection - weather data may be out of date.'**
  String get pogodaNieaktualna;

  /// No description provided for @temperatureUnit.
  ///
  /// In en, this message translates to:
  /// **'Temperature unit'**
  String get temperatureUnit;

  /// No description provided for @longitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get longitude;

  /// No description provided for @latitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get latitude;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @locationApiary.
  ///
  /// In en, this message translates to:
  /// **'Apiary location data used to retrieve weather information during inspection. Enter the name of the nearest city, latitude and longitude of the apiary or indicate the location of the apiary on the map.'**
  String get locationApiary;

  /// No description provided for @apiaryAdition.
  ///
  /// In en, this message translates to:
  /// **'Apiary edition'**
  String get apiaryAdition;

  /// No description provided for @editingInfo.
  ///
  /// In en, this message translates to:
  /// **'Editing information'**
  String get editingInfo;

  /// No description provided for @addInfo.
  ///
  /// In en, this message translates to:
  /// **'Adding information'**
  String get addInfo;

  /// No description provided for @pArametr.
  ///
  /// In en, this message translates to:
  /// **'Feature'**
  String get pArametr;

  /// No description provided for @vAlue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get vAlue;

  /// No description provided for @mEasure.
  ///
  /// In en, this message translates to:
  /// **'Measure'**
  String get mEasure;

  /// No description provided for @honeyOnSmallFrame.
  ///
  /// In en, this message translates to:
  /// **'The weight of the honey, which is located on one small frame (from a half-body). This should be the average of multiple frames. This value is used to calculate the approximate amount of honey harvested for each hive.'**
  String get honeyOnSmallFrame;

  /// No description provided for @honeyOnBigFrame.
  ///
  /// In en, this message translates to:
  /// **'The weight of the honey, which is located on one big frame (from a body). This should be the average of multiple frames. This value is used to calculate the approximate amount of honey harvested for each hive.'**
  String get honeyOnBigFrame;

  /// No description provided for @beePollenPortion.
  ///
  /// In en, this message translates to:
  /// **'The capacity of the measuring cup that is used to measure the collected pollen. This value is used to calculate the approximate amount of pollen collected for each hive.'**
  String get beePollenPortion;

  /// No description provided for @weightSmallFrame.
  ///
  /// In en, this message translates to:
  /// **'Average honey weight \non small frame'**
  String get weightSmallFrame;

  /// No description provided for @weightBigFrame.
  ///
  /// In en, this message translates to:
  /// **'Average honey weight \non big frame'**
  String get weightBigFrame;

  /// No description provided for @weightDmFrame.
  ///
  /// In en, this message translates to:
  /// **'Average honey weight \non 1 dm² frame'**
  String get weightDmFrame;

  /// No description provided for @enterValue.
  ///
  /// In en, this message translates to:
  /// **'Enter a value'**
  String get enterValue;

  /// No description provided for @weightPortion.
  ///
  /// In en, this message translates to:
  /// **'Bee pollen capacity\nin a measuring cup'**
  String get weightPortion;

  /// No description provided for @paramEdition.
  ///
  /// In en, this message translates to:
  /// **'Parameter edition'**
  String get paramEdition;

  /// No description provided for @rem.
  ///
  /// In en, this message translates to:
  /// **'insert/remove'**
  String get rem;

  /// No description provided for @value.
  ///
  /// In en, this message translates to:
  /// **'value'**
  String get value;

  /// No description provided for @food.
  ///
  /// In en, this message translates to:
  /// **'food'**
  String get food;

  /// No description provided for @noSubscryption.
  ///
  /// In en, this message translates to:
  /// **'no subscryption'**
  String get noSubscryption;

  /// No description provided for @nOData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get nOData;

  /// No description provided for @sAle.
  ///
  /// In en, this message translates to:
  /// **'Sale'**
  String get sAle;

  /// No description provided for @noSaleYet.
  ///
  /// In en, this message translates to:
  /// **'There are no sales yet.'**
  String get noSaleYet;

  /// No description provided for @saleDate.
  ///
  /// In en, this message translates to:
  /// **'Sale date'**
  String get saleDate;

  /// No description provided for @nAme.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nAme;

  /// No description provided for @pRice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get pRice;

  /// No description provided for @editingSale.
  ///
  /// In en, this message translates to:
  /// **'Editing sale'**
  String get editingSale;

  /// No description provided for @addSale.
  ///
  /// In en, this message translates to:
  /// **'Adding sale'**
  String get addSale;

  /// No description provided for @pRoduct.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get pRoduct;

  /// No description provided for @otherSales.
  ///
  /// In en, this message translates to:
  /// **'other sales'**
  String get otherSales;

  /// No description provided for @deleteAllData.
  ///
  /// In en, this message translates to:
  /// **'Erasing all data'**
  String get deleteAllData;

  /// No description provided for @deleteRamkaInfo.
  ///
  /// In en, this message translates to:
  /// **'All data will be deleted! This decision is final and cannot be reversed. If all data has not been exported to the cloud, you will lose it and cannot recover it!'**
  String get deleteRamkaInfo;

  /// No description provided for @aboutHiveApiary.
  ///
  /// In en, this message translates to:
  /// **'about inspections, beehives and apiaries'**
  String get aboutHiveApiary;

  /// No description provided for @harvestDataSend.
  ///
  /// In en, this message translates to:
  /// **'Harvest data has been sent'**
  String get harvestDataSend;

  /// No description provided for @saleDataSend.
  ///
  /// In en, this message translates to:
  /// **'Sales data has been sent'**
  String get saleDataSend;

  /// No description provided for @queenDataSend.
  ///
  /// In en, this message translates to:
  /// **'Queens data has been sent'**
  String get queenDataSend;

  /// No description provided for @purchaseDataSend.
  ///
  /// In en, this message translates to:
  /// **'Purchase data has been sent'**
  String get purchaseDataSend;

  /// No description provided for @noteDataSend.
  ///
  /// In en, this message translates to:
  /// **'The notes have been sent'**
  String get noteDataSend;

  /// No description provided for @editingPurchase.
  ///
  /// In en, this message translates to:
  /// **'Editing purchase'**
  String get editingPurchase;

  /// No description provided for @addPurchase.
  ///
  /// In en, this message translates to:
  /// **'Adding purchase'**
  String get addPurchase;

  /// No description provided for @cAtegory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get cAtegory;

  /// No description provided for @medicines.
  ///
  /// In en, this message translates to:
  /// **'medicines'**
  String get medicines;

  /// No description provided for @lack.
  ///
  /// In en, this message translates to:
  /// **'lack'**
  String get lack;

  /// No description provided for @packaging.
  ///
  /// In en, this message translates to:
  /// **'packaging'**
  String get packaging;

  /// No description provided for @noPurchaseYet.
  ///
  /// In en, this message translates to:
  /// **'No purchases yet.'**
  String get noPurchaseYet;

  /// No description provided for @noCaregory.
  ///
  /// In en, this message translates to:
  /// **'no category'**
  String get noCaregory;

  /// No description provided for @pUrchase.
  ///
  /// In en, this message translates to:
  /// **'Purchase'**
  String get pUrchase;

  /// No description provided for @bees.
  ///
  /// In en, this message translates to:
  /// **'bees'**
  String get bees;

  /// No description provided for @queens.
  ///
  /// In en, this message translates to:
  /// **'queens'**
  String get queens;

  /// No description provided for @tOTAL.
  ///
  /// In en, this message translates to:
  /// **'TOTAL'**
  String get tOTAL;

  /// No description provided for @nOtes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get nOtes;

  /// No description provided for @noNoteYet.
  ///
  /// In en, this message translates to:
  /// **'There are no notes yet.'**
  String get noNoteYet;

  /// No description provided for @editingNote.
  ///
  /// In en, this message translates to:
  /// **'Editing note'**
  String get editingNote;

  /// No description provided for @addNote.
  ///
  /// In en, this message translates to:
  /// **'Adding note'**
  String get addNote;

  /// No description provided for @tItle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get tItle;

  /// No description provided for @nOte.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get nOte;

  /// No description provided for @noteDate.
  ///
  /// In en, this message translates to:
  /// **'Note date'**
  String get noteDate;

  /// No description provided for @eXportData.
  ///
  /// In en, this message translates to:
  /// **'Data export to the cloud'**
  String get eXportData;

  /// No description provided for @editingFrame.
  ///
  /// In en, this message translates to:
  /// **'Editing frame info'**
  String get editingFrame;

  /// No description provided for @addFrame.
  ///
  /// In en, this message translates to:
  /// **'Adding frame info'**
  String get addFrame;

  /// No description provided for @introA.
  ///
  /// In en, this message translates to:
  /// **'\n\nTo create an apiary and individual hives, use the \"+\" icon above. \n\nInformation about the application on the website heymaya.eu is available after selecting the \"?\" icon above.'**
  String get introA;

  /// No description provided for @introB.
  ///
  /// In en, this message translates to:
  /// **'\n\nExample:\n1. Select \"VOICE CONTROL\" - listening starts on its own.\n2. Say \"Hej Maja start\" (from now on say commands with no prefix; \"Hej Maja stop\" ends listening).\n3. Say \"Set apiary number one.\"\n4. Say \"Set hive number one.\"\n5. Say \"Set body number one.\"\n6. Say \"Set frame number one.\"\n7. Say \"Set eggs, twenty percent, on the left side\".'**
  String get introB;

  /// No description provided for @introC.
  ///
  /// In en, this message translates to:
  /// **'\n\nApiary no. 1 will be created with hive no. 1, consisting of one body in which there is one frame with eggs, occupying 20% of the frame area on the left side. You can continue the inspection or end it by selecting \"STOP\" button.'**
  String get introC;

  /// No description provided for @milliliter.
  ///
  /// In en, this message translates to:
  /// **'milliliter'**
  String get milliliter;

  /// No description provided for @resourceLocationSay.
  ///
  /// In en, this message translates to:
  /// **'Resource location - say e.g.:'**
  String get resourceLocationSay;

  /// No description provided for @lOcation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get lOcation;

  /// No description provided for @acid.
  ///
  /// In en, this message translates to:
  /// **'acid'**
  String get acid;

  /// No description provided for @acidG.
  ///
  /// In en, this message translates to:
  /// **'acid'**
  String get acidG;

  /// No description provided for @aCid.
  ///
  /// In en, this message translates to:
  /// **'Acid'**
  String get aCid;

  /// No description provided for @deadBees.
  ///
  /// In en, this message translates to:
  /// **'dead bees'**
  String get deadBees;

  /// No description provided for @dEadBees.
  ///
  /// In en, this message translates to:
  /// **'Dead bees'**
  String get dEadBees;

  /// No description provided for @veryGood.
  ///
  /// In en, this message translates to:
  /// **'very good'**
  String get veryGood;

  /// No description provided for @good.
  ///
  /// In en, this message translates to:
  /// **'good'**
  String get good;

  /// No description provided for @canceled.
  ///
  /// In en, this message translates to:
  /// **'to replace'**
  String get canceled;

  /// No description provided for @exchange.
  ///
  /// In en, this message translates to:
  /// **'old'**
  String get exchange;

  /// No description provided for @unmarked.
  ///
  /// In en, this message translates to:
  /// **'unmarked'**
  String get unmarked;

  /// No description provided for @unmarked1.
  ///
  /// In en, this message translates to:
  /// **'unmarked'**
  String get unmarked1;

  /// No description provided for @markedBlue.
  ///
  /// In en, this message translates to:
  /// **'marked blue'**
  String get markedBlue;

  /// No description provided for @markedOther.
  ///
  /// In en, this message translates to:
  /// **'marked other'**
  String get markedOther;

  /// No description provided for @markedGreen.
  ///
  /// In en, this message translates to:
  /// **'marked green'**
  String get markedGreen;

  /// No description provided for @markedRed.
  ///
  /// In en, this message translates to:
  /// **'marked red'**
  String get markedRed;

  /// No description provided for @markedYellow.
  ///
  /// In en, this message translates to:
  /// **'marked yellow'**
  String get markedYellow;

  /// No description provided for @markedWhite.
  ///
  /// In en, this message translates to:
  /// **'marked white'**
  String get markedWhite;

  /// No description provided for @missing.
  ///
  /// In en, this message translates to:
  /// **'missing'**
  String get missing;

  /// No description provided for @missing1.
  ///
  /// In en, this message translates to:
  /// **'missing'**
  String get missing1;

  /// No description provided for @gone.
  ///
  /// In en, this message translates to:
  /// **'gone'**
  String get gone;

  /// No description provided for @gone1.
  ///
  /// In en, this message translates to:
  /// **'gone'**
  String get gone1;

  /// No description provided for @virgine.
  ///
  /// In en, this message translates to:
  /// **'virgine'**
  String get virgine;

  /// No description provided for @droneLaying.
  ///
  /// In en, this message translates to:
  /// **'drone laying'**
  String get droneLaying;

  /// No description provided for @virgine1.
  ///
  /// In en, this message translates to:
  /// **'unfertilized'**
  String get virgine1;

  /// No description provided for @artificiallyInseminated.
  ///
  /// In en, this message translates to:
  /// **'artificially inseminated'**
  String get artificiallyInseminated;

  /// No description provided for @artificiallyInseminated1.
  ///
  /// In en, this message translates to:
  /// **'artificially inseminated'**
  String get artificiallyInseminated1;

  /// No description provided for @naturallyMated.
  ///
  /// In en, this message translates to:
  /// **'naturally mated'**
  String get naturallyMated;

  /// No description provided for @naturallyMated1.
  ///
  /// In en, this message translates to:
  /// **'naturally mated'**
  String get naturallyMated1;

  /// No description provided for @freed.
  ///
  /// In en, this message translates to:
  /// **'freed'**
  String get freed;

  /// No description provided for @inCage.
  ///
  /// In en, this message translates to:
  /// **'in a cage'**
  String get inCage;

  /// No description provided for @inInsulator.
  ///
  /// In en, this message translates to:
  /// **'in the insulator'**
  String get inInsulator;

  /// No description provided for @isolated.
  ///
  /// In en, this message translates to:
  /// **'isolated'**
  String get isolated;

  /// No description provided for @gentle.
  ///
  /// In en, this message translates to:
  /// **'gentle'**
  String get gentle;

  /// No description provided for @aggressive.
  ///
  /// In en, this message translates to:
  /// **'aggressive'**
  String get aggressive;

  /// No description provided for @aggressive1.
  ///
  /// In en, this message translates to:
  /// **'aggressive'**
  String get aggressive1;

  /// No description provided for @swarmingMood.
  ///
  /// In en, this message translates to:
  /// **'swarming mood'**
  String get swarmingMood;

  /// No description provided for @inCluster.
  ///
  /// In en, this message translates to:
  /// **'in a cluster'**
  String get inCluster;

  /// No description provided for @dead.
  ///
  /// In en, this message translates to:
  /// **'dead'**
  String get dead;

  /// No description provided for @veryStrong.
  ///
  /// In en, this message translates to:
  /// **'very strong'**
  String get veryStrong;

  /// No description provided for @strong.
  ///
  /// In en, this message translates to:
  /// **'strong'**
  String get strong;

  /// No description provided for @normal.
  ///
  /// In en, this message translates to:
  /// **'normal'**
  String get normal;

  /// No description provided for @normal1.
  ///
  /// In en, this message translates to:
  /// **'normal'**
  String get normal1;

  /// No description provided for @weak.
  ///
  /// In en, this message translates to:
  /// **'weak'**
  String get weak;

  /// No description provided for @veryWeak.
  ///
  /// In en, this message translates to:
  /// **'very weak'**
  String get veryWeak;

  /// No description provided for @queenQuality.
  ///
  /// In en, this message translates to:
  /// **'quality'**
  String get queenQuality;

  /// No description provided for @queenMark.
  ///
  /// In en, this message translates to:
  /// **'marking/lack'**
  String get queenMark;

  /// No description provided for @queenState.
  ///
  /// In en, this message translates to:
  /// **'insemination'**
  String get queenState;

  /// No description provided for @queenStart.
  ///
  /// In en, this message translates to:
  /// **'restriction'**
  String get queenStart;

  /// No description provided for @queenBorn.
  ///
  /// In en, this message translates to:
  /// **'yearbook'**
  String get queenBorn;

  /// No description provided for @colonyState.
  ///
  /// In en, this message translates to:
  /// **'colony status'**
  String get colonyState;

  /// No description provided for @colonyForce.
  ///
  /// In en, this message translates to:
  /// **'colony force'**
  String get colonyForce;

  /// No description provided for @dirty.
  ///
  /// In en, this message translates to:
  /// **'dirty'**
  String get dirty;

  /// No description provided for @clean.
  ///
  /// In en, this message translates to:
  /// **'clean'**
  String get clean;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'off'**
  String get off;

  /// No description provided for @off1.
  ///
  /// In en, this message translates to:
  /// **'off'**
  String get off1;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'delete'**
  String get delete;

  /// No description provided for @zalacz.
  ///
  /// In en, this message translates to:
  /// **'on'**
  String get zalacz;

  /// No description provided for @zalacz1.
  ///
  /// In en, this message translates to:
  /// **'on'**
  String get zalacz1;

  /// No description provided for @aDdHive.
  ///
  /// In en, this message translates to:
  /// **'Add hive'**
  String get aDdHive;

  /// No description provided for @aDdQueen.
  ///
  /// In en, this message translates to:
  /// **'Register queen'**
  String get aDdQueen;

  /// No description provided for @nUmberOfFrameInBody.
  ///
  /// In en, this message translates to:
  /// **'Number of frame in body'**
  String get nUmberOfFrameInBody;

  /// No description provided for @selectStatYear.
  ///
  /// In en, this message translates to:
  /// **'Select year for statistics'**
  String get selectStatYear;

  /// No description provided for @zMalychW.
  ///
  /// In en, this message translates to:
  /// **'from small in '**
  String get zMalychW;

  /// No description provided for @zDuzychW.
  ///
  /// In en, this message translates to:
  /// **'from big in '**
  String get zDuzychW;

  /// No description provided for @wEatherForecast.
  ///
  /// In en, this message translates to:
  /// **'Weather forecast'**
  String get wEatherForecast;

  /// No description provided for @lAnguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get lAnguage;

  /// No description provided for @cHooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose language'**
  String get cHooseLanguage;

  /// No description provided for @recentHoney.
  ///
  /// In en, this message translates to:
  /// **'recent honey'**
  String get recentHoney;

  /// No description provided for @black.
  ///
  /// In en, this message translates to:
  /// **'black '**
  String get black;

  /// No description provided for @yellow.
  ///
  /// In en, this message translates to:
  /// **'yellow '**
  String get yellow;

  /// No description provided for @red.
  ///
  /// In en, this message translates to:
  /// **'red '**
  String get red;

  /// No description provided for @green.
  ///
  /// In en, this message translates to:
  /// **'green '**
  String get green;

  /// No description provided for @blue.
  ///
  /// In en, this message translates to:
  /// **'blue '**
  String get blue;

  /// No description provided for @white.
  ///
  /// In en, this message translates to:
  /// **'white '**
  String get white;

  /// No description provided for @frameAfter.
  ///
  /// In en, this message translates to:
  /// **'frame after'**
  String get frameAfter;

  /// No description provided for @framesAfter.
  ///
  /// In en, this message translates to:
  /// **'after inspection'**
  String get framesAfter;

  /// No description provided for @framesBefore.
  ///
  /// In en, this message translates to:
  /// **'before inspection'**
  String get framesBefore;

  /// No description provided for @frameInspections.
  ///
  /// In en, this message translates to:
  /// **'inspections'**
  String get frameInspections;

  /// No description provided for @frameRange.
  ///
  /// In en, this message translates to:
  /// **'Frame range'**
  String get frameRange;

  /// No description provided for @aRrangementOfFrames.
  ///
  /// In en, this message translates to:
  /// **'Arrangement of frames'**
  String get aRrangementOfFrames;

  /// No description provided for @blackColor.
  ///
  /// In en, this message translates to:
  /// **'black'**
  String get blackColor;

  /// No description provided for @yellowColor.
  ///
  /// In en, this message translates to:
  /// **'yellow'**
  String get yellowColor;

  /// No description provided for @redColor.
  ///
  /// In en, this message translates to:
  /// **'red'**
  String get redColor;

  /// No description provided for @greenColor.
  ///
  /// In en, this message translates to:
  /// **'green'**
  String get greenColor;

  /// No description provided for @blueColor.
  ///
  /// In en, this message translates to:
  /// **'blue'**
  String get blueColor;

  /// No description provided for @whiteColor.
  ///
  /// In en, this message translates to:
  /// **'white'**
  String get whiteColor;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'no\ndata'**
  String get noData;

  /// No description provided for @otherColor.
  ///
  /// In en, this message translates to:
  /// **'other'**
  String get otherColor;

  /// No description provided for @tooMuch.
  ///
  /// In en, this message translates to:
  /// **'% too much!\nYou can choose up to'**
  String get tooMuch;

  /// No description provided for @aBout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aBout;

  /// No description provided for @bOdyNumber.
  ///
  /// In en, this message translates to:
  /// **'Body number in the hive'**
  String get bOdyNumber;

  /// No description provided for @fRameNumber.
  ///
  /// In en, this message translates to:
  /// **'Frame number'**
  String get fRameNumber;

  /// No description provided for @one.
  ///
  /// In en, this message translates to:
  /// **'one'**
  String get one;

  /// No description provided for @many.
  ///
  /// In en, this message translates to:
  /// **'many'**
  String get many;

  /// No description provided for @before.
  ///
  /// In en, this message translates to:
  /// **'before'**
  String get before;

  /// No description provided for @after.
  ///
  /// In en, this message translates to:
  /// **'after'**
  String get after;

  /// No description provided for @frameNumberBefore.
  ///
  /// In en, this message translates to:
  /// **'Frame number before inspection'**
  String get frameNumberBefore;

  /// No description provided for @frameNumberAfter.
  ///
  /// In en, this message translates to:
  /// **'Frame number after inspection'**
  String get frameNumberAfter;

  /// No description provided for @frameNumberFrom.
  ///
  /// In en, this message translates to:
  /// **'Frame number from'**
  String get frameNumberFrom;

  /// No description provided for @frameNumberTo.
  ///
  /// In en, this message translates to:
  /// **'Frame number to'**
  String get frameNumberTo;

  /// No description provided for @bOdyType.
  ///
  /// In en, this message translates to:
  /// **'Body type'**
  String get bOdyType;

  /// No description provided for @half.
  ///
  /// In en, this message translates to:
  /// **'half'**
  String get half;

  /// No description provided for @full.
  ///
  /// In en, this message translates to:
  /// **'full'**
  String get full;

  /// No description provided for @fRameSize.
  ///
  /// In en, this message translates to:
  /// **'Frame size'**
  String get fRameSize;

  /// No description provided for @sIteOfFrame.
  ///
  /// In en, this message translates to:
  /// **'Site of frame'**
  String get sIteOfFrame;

  /// No description provided for @rEsources.
  ///
  /// In en, this message translates to:
  /// **'Resources'**
  String get rEsources;

  /// No description provided for @aMountOfWax.
  ///
  /// In en, this message translates to:
  /// **'Amount of wax fundation in %'**
  String get aMountOfWax;

  /// No description provided for @aMountOfComb.
  ///
  /// In en, this message translates to:
  /// **'Amount of wax comb in %'**
  String get aMountOfComb;

  /// No description provided for @aMountOfSealed.
  ///
  /// In en, this message translates to:
  /// **'Amount of ripe honey in %'**
  String get aMountOfSealed;

  /// No description provided for @aMountOfHoney.
  ///
  /// In en, this message translates to:
  /// **'Amount of honey in %'**
  String get aMountOfHoney;

  /// No description provided for @aMountOfPollen.
  ///
  /// In en, this message translates to:
  /// **'Amount of pollen in %'**
  String get aMountOfPollen;

  /// No description provided for @aMountOfEggs.
  ///
  /// In en, this message translates to:
  /// **'Amount of eggs in %'**
  String get aMountOfEggs;

  /// No description provided for @aMountOfLarvae.
  ///
  /// In en, this message translates to:
  /// **'Amount of larvae in %'**
  String get aMountOfLarvae;

  /// No description provided for @aMountOfBrood.
  ///
  /// In en, this message translates to:
  /// **'Amount of covered brood in %'**
  String get aMountOfBrood;

  /// No description provided for @aMountOfDrone.
  ///
  /// In en, this message translates to:
  /// **'Amount of drone brood in %'**
  String get aMountOfDrone;

  /// No description provided for @cOolorOfMother.
  ///
  /// In en, this message translates to:
  /// **'The color of the mother\'s marking'**
  String get cOolorOfMother;

  /// No description provided for @nUmberOfQueenCells.
  ///
  /// In en, this message translates to:
  /// **'Number of queen cells'**
  String get nUmberOfQueenCells;

  /// No description provided for @nUmberOfCellsRemoved.
  ///
  /// In en, this message translates to:
  /// **'Number of queen cells removed'**
  String get nUmberOfCellsRemoved;

  /// No description provided for @bOdy.
  ///
  /// In en, this message translates to:
  /// **'Body'**
  String get bOdy;

  /// No description provided for @honeySealedN.
  ///
  /// In en, this message translates to:
  /// **'ripe\nhoney'**
  String get honeySealedN;

  /// No description provided for @hOney.
  ///
  /// In en, this message translates to:
  /// **'honey'**
  String get hOney;

  /// No description provided for @broodCoveredN.
  ///
  /// In en, this message translates to:
  /// **'brood\ncovered'**
  String get broodCoveredN;

  /// No description provided for @droneN.
  ///
  /// In en, this message translates to:
  /// **'drone'**
  String get droneN;

  /// No description provided for @droneBees.
  ///
  /// In en, this message translates to:
  /// **'drone bees'**
  String get droneBees;

  /// No description provided for @deleteQueenCellsN.
  ///
  /// In en, this message translates to:
  /// **'delete\nqueen cells'**
  String get deleteQueenCellsN;

  /// No description provided for @waxCombN.
  ///
  /// In en, this message translates to:
  /// **'wax\ncomb'**
  String get waxCombN;

  /// No description provided for @waxFundationN.
  ///
  /// In en, this message translates to:
  /// **'wax\nfundation'**
  String get waxFundationN;

  /// No description provided for @queenCellsN.
  ///
  /// In en, this message translates to:
  /// **'queen\ncells'**
  String get queenCellsN;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'all'**
  String get all;

  /// No description provided for @aLl.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get aLl;

  /// No description provided for @thisOne.
  ///
  /// In en, this message translates to:
  /// **'this one'**
  String get thisOne;

  /// No description provided for @rEsourceOnFrame.
  ///
  /// In en, this message translates to:
  /// **'Resource on frame'**
  String get rEsourceOnFrame;

  /// No description provided for @fRameNumbersBeforeAndAfter.
  ///
  /// In en, this message translates to:
  /// **'Frame numbers before / after'**
  String get fRameNumbersBeforeAndAfter;

  /// No description provided for @eXportNote.
  ///
  /// In en, this message translates to:
  /// **'Export all notes to the cloud'**
  String get eXportNote;

  /// No description provided for @eXportHarvest.
  ///
  /// In en, this message translates to:
  /// **'Export all harvests to the cloud'**
  String get eXportHarvest;

  /// No description provided for @eXportPurchase.
  ///
  /// In en, this message translates to:
  /// **'Export all purchases to the cloud'**
  String get eXportPurchase;

  /// No description provided for @eXportSale.
  ///
  /// In en, this message translates to:
  /// **'Export all sales to the cloud'**
  String get eXportSale;

  /// No description provided for @eXportQueens.
  ///
  /// In en, this message translates to:
  /// **'Export all queens to the cloud'**
  String get eXportQueens;

  /// No description provided for @eXportInfo.
  ///
  /// In en, this message translates to:
  /// **'Export of all detailed data to the cloud (equipment, family, queen, harvest, feeding and treatment)'**
  String get eXportInfo;

  /// No description provided for @eXportFrame.
  ///
  /// In en, this message translates to:
  /// **'Export all frame inspection data to the cloud'**
  String get eXportFrame;

  /// No description provided for @fRames.
  ///
  /// In en, this message translates to:
  /// **'Frames'**
  String get fRames;

  /// No description provided for @iNfos.
  ///
  /// In en, this message translates to:
  /// **'Infos'**
  String get iNfos;

  /// No description provided for @oNly.
  ///
  /// In en, this message translates to:
  /// **'Only'**
  String get oNly;

  /// No description provided for @enterNote.
  ///
  /// In en, this message translates to:
  /// **'enter a note'**
  String get enterNote;

  /// No description provided for @enterTitleNote.
  ///
  /// In en, this message translates to:
  /// **'enter a title for the note'**
  String get enterTitleNote;

  /// No description provided for @purchaseData.
  ///
  /// In en, this message translates to:
  /// **'Purchase data'**
  String get purchaseData;

  /// No description provided for @ostatnieInformacje.
  ///
  /// In en, this message translates to:
  /// **'Last information'**
  String get ostatnieInformacje;

  /// No description provided for @oUlu.
  ///
  /// In en, this message translates to:
  /// **'about hive'**
  String get oUlu;

  /// No description provided for @oWyposazeniu.
  ///
  /// In en, this message translates to:
  /// **'about equipment'**
  String get oWyposazeniu;

  /// No description provided for @oRodzinie.
  ///
  /// In en, this message translates to:
  /// **'about colony'**
  String get oRodzinie;

  /// No description provided for @oMatce.
  ///
  /// In en, this message translates to:
  /// **'about queen'**
  String get oMatce;

  /// No description provided for @oZbiorach.
  ///
  /// In en, this message translates to:
  /// **'about harvests'**
  String get oZbiorach;

  /// No description provided for @oDokarmianiu.
  ///
  /// In en, this message translates to:
  /// **'about feeding'**
  String get oDokarmianiu;

  /// No description provided for @oLeczeniu.
  ///
  /// In en, this message translates to:
  /// **'about treatment'**
  String get oLeczeniu;

  /// No description provided for @oZasobachMatkach.
  ///
  /// In en, this message translates to:
  /// **'about resources and mothers'**
  String get oZasobachMatkach;


  /// No description provided for @oZ.
  ///
  /// In en, this message translates to:
  /// **'about honey harvest'**
  String get oZ;

  /// No description provided for @hOneyHarvest.
  ///
  /// In en, this message translates to:
  /// **'Honey harvest'**
  String get hOneyHarvest;

  /// No description provided for @bEePollenHarvest.
  ///
  /// In en, this message translates to:
  /// **'Bee pollen harvest'**
  String get bEePollenHarvest;

  /// No description provided for @hArvestReports.
  ///
  /// In en, this message translates to:
  /// **'Harvest reports'**
  String get hArvestReports;

  /// No description provided for @tReatmentReports.
  ///
  /// In en, this message translates to:
  /// **'Treatment reports'**
  String get tReatmentReports;

  /// No description provided for @rAports.
  ///
  /// In en, this message translates to:
  /// **'Raports'**
  String get rAports;

  /// No description provided for @dEad.
  ///
  /// In en, this message translates to:
  /// **'Dead'**
  String get dEad;

  /// No description provided for @onlyInLocalDatabase.
  ///
  /// In en, this message translates to:
  /// **'only in the local database'**
  String get onlyInLocalDatabase;

  /// No description provided for @mOve.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get mOve;

  /// No description provided for @mOveFrame.
  ///
  /// In en, this message translates to:
  /// **'Przenieś ramkę'**
  String get mOveFrame;

  /// No description provided for @mOvingFrame.
  ///
  /// In en, this message translates to:
  /// **'Moving frame'**
  String get mOvingFrame;

  /// No description provided for @mOveFrameFrom.
  ///
  /// In en, this message translates to:
  /// **'Move frame from:'**
  String get mOveFrameFrom;

  /// No description provided for @mOveFrameTo.
  ///
  /// In en, this message translates to:
  /// **'Move frame to:'**
  String get mOveFrameTo;

  /// No description provided for @mOvingBody.
  ///
  /// In en, this message translates to:
  /// **'Moving body'**
  String get mOvingBody;

  /// No description provided for @mOveBodyFrom.
  ///
  /// In en, this message translates to:
  /// **'Move body from:'**
  String get mOveBodyFrom;

  /// No description provided for @mOveBodyTo.
  ///
  /// In en, this message translates to:
  /// **'Move body to:'**
  String get mOveBodyTo;

  /// No description provided for @hIveLiquidation.
  ///
  /// In en, this message translates to:
  /// **'Hive liquidation'**
  String get hIveLiquidation;

  /// No description provided for @hiveLiquidation.
  ///
  /// In en, this message translates to:
  /// **'hive liquidation'**
  String get hiveLiquidation;

  /// No description provided for @hiveTransfer.
  ///
  /// In en, this message translates to:
  /// **'hive transfer'**
  String get hiveTransfer;

  /// No description provided for @nOteForInspection.
  ///
  /// In en, this message translates to:
  /// **'Note for inspection'**
  String get nOteForInspection;

  /// No description provided for @pAge.
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get pAge;

  /// No description provided for @onPage.
  ///
  /// In en, this message translates to:
  /// **'On page'**
  String get onPage;

  /// No description provided for @hivesOnSite.
  ///
  /// In en, this message translates to:
  /// **'Number of hives on the report page'**
  String get hivesOnSite;

  /// No description provided for @hivesOnSiteReport.
  ///
  /// In en, this message translates to:
  /// **'The number of hives per page of the presented report should not exceed 20.'**
  String get hivesOnSiteReport;

  /// No description provided for @hiveNumbers.
  ///
  /// In en, this message translates to:
  /// **'Hive numbers'**
  String get hiveNumbers;

  /// No description provided for @selectReportYear.
  ///
  /// In en, this message translates to:
  /// **'Select the year of the report'**
  String get selectReportYear;

  /// No description provided for @hIveType.
  ///
  /// In en, this message translates to:
  /// **'Type of hive'**
  String get hIveType;

  /// No description provided for @kIndHive.
  ///
  /// In en, this message translates to:
  /// **'Kind of hive'**
  String get kIndHive;

  /// No description provided for @oTHER.
  ///
  /// In en, this message translates to:
  /// **'OTHER'**
  String get oTHER;

  /// No description provided for @nUc.
  ///
  /// In en, this message translates to:
  /// **'Nuc'**
  String get nUc;

  /// No description provided for @mIni.
  ///
  /// In en, this message translates to:
  /// **'Mini'**
  String get mIni;

  /// No description provided for @wEeddingHive.
  ///
  /// In en, this message translates to:
  /// **'WEDDING BEEHIVE'**
  String get wEeddingHive;

  /// No description provided for @typeNumberOfFrame.
  ///
  /// In en, this message translates to:
  /// **'type and number of frame'**
  String get typeNumberOfFrame;

  /// No description provided for @iTalian.
  ///
  /// In en, this message translates to:
  /// **'Italian (Ligustica)'**
  String get iTalian;

  /// No description provided for @cArniolan.
  ///
  /// In en, this message translates to:
  /// **'Carniolan (Carnica)'**
  String get cArniolan;

  /// No description provided for @cAucasian.
  ///
  /// In en, this message translates to:
  /// **'Caucasian (Caucasica)'**
  String get cAucasian;

  /// No description provided for @cEntral.
  ///
  /// In en, this message translates to:
  /// **'Central European (Mellifera)'**
  String get cEntral;

  /// No description provided for @iBerian.
  ///
  /// In en, this message translates to:
  /// **'Iberian (Iberiensis)'**
  String get iBerian;

  /// No description provided for @pErsian.
  ///
  /// In en, this message translates to:
  /// **'Persian (Media)'**
  String get pErsian;

  /// No description provided for @gReek.
  ///
  /// In en, this message translates to:
  /// **'Greek (Cecropia)'**
  String get gReek;

  /// No description provided for @eAster.
  ///
  /// In en, this message translates to:
  /// **'Eastern (Cerana)'**
  String get eAster;

  /// No description provided for @aNatolian.
  ///
  /// In en, this message translates to:
  /// **'Anatolian (Anatoliaca)'**
  String get aNatolian;

  /// No description provided for @oTherQueen.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get oTherQueen;

  /// No description provided for @bOught.
  ///
  /// In en, this message translates to:
  /// **'Bought'**
  String get bOught;

  /// No description provided for @cOught.
  ///
  /// In en, this message translates to:
  /// **'Cought'**
  String get cOught;

  /// No description provided for @oWn.
  ///
  /// In en, this message translates to:
  /// **'Own'**
  String get oWn;

  /// No description provided for @dAteAcquisition.
  ///
  /// In en, this message translates to:
  /// **'Date of acquisition'**
  String get dAteAcquisition;

  /// No description provided for @dAteLoss.
  ///
  /// In en, this message translates to:
  /// **'Date of loss the queen'**
  String get dAteLoss;

  /// No description provided for @bReed.
  ///
  /// In en, this message translates to:
  /// **'Breed'**
  String get bReed;

  /// No description provided for @sUbspecies.
  ///
  /// In en, this message translates to:
  /// **'Subspecies'**
  String get sUbspecies;

  /// No description provided for @sOurce.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get sOurce;

  /// No description provided for @qUeenMark.
  ///
  /// In en, this message translates to:
  /// **'Queen mark'**
  String get qUeenMark;

  /// No description provided for @qUeenBorn.
  ///
  /// In en, this message translates to:
  /// **'Yearbook'**
  String get qUeenBorn;

  /// No description provided for @iNscription.
  ///
  /// In en, this message translates to:
  /// **'Inscription'**
  String get iNscription;

  /// No description provided for @eDitingQueen.
  ///
  /// In en, this message translates to:
  /// **'Editing queen'**
  String get eDitingQueen;

  /// No description provided for @aDdQueenToHive.
  ///
  /// In en, this message translates to:
  /// **'Add queen to hive'**
  String get aDdQueenToHive;

  /// No description provided for @aDdingQueen.
  ///
  /// In en, this message translates to:
  /// **'QUEEN MANAGEMENT'**
  String get aDdingQueen;

  /// No description provided for @eDit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get eDit;

  /// No description provided for @wHatDoYouWant.
  ///
  /// In en, this message translates to:
  /// **'What can you do?'**
  String get wHatDoYouWant;

  /// No description provided for @dIsconnectOrEdit.
  ///
  /// In en, this message translates to:
  /// **'You can disconnect the queen from the hive or edit her details, e.g. add the date of the queen loss.'**
  String get dIsconnectOrEdit;

  /// No description provided for @eDitQueen.
  ///
  /// In en, this message translates to:
  /// **'You can edit all the queen\'s data, for example, remove the queen\'s loss date, which will make the queen alive again...'**
  String get eDitQueen;

  /// No description provided for @dIsconnectQueen.
  ///
  /// In en, this message translates to:
  /// **'Disconnect the queen'**
  String get dIsconnectQueen;

  /// No description provided for @sElectDate.
  ///
  /// In en, this message translates to:
  /// **'Select a date'**
  String get sElectDate;

  /// No description provided for @lOst.
  ///
  /// In en, this message translates to:
  /// **'Lost'**
  String get lOst;

  /// No description provided for @qUeens.
  ///
  /// In en, this message translates to:
  /// **'Queens'**
  String get qUeens;

  /// No description provided for @noQueensYet.
  ///
  /// In en, this message translates to:
  /// **'There are no queens yet.'**
  String get noQueensYet;

  /// No description provided for @nUmberHives.
  ///
  /// In en, this message translates to:
  /// **'Number of hives'**
  String get nUmberHives;

  /// No description provided for @living.
  ///
  /// In en, this message translates to:
  /// **'all living'**
  String get living;

  /// No description provided for @lost.
  ///
  /// In en, this message translates to:
  /// **'all lost'**
  String get lost;

  /// No description provided for @activ.
  ///
  /// In en, this message translates to:
  /// **'available for this hive'**
  String get activ;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'registered, without hive'**
  String get register;

  /// No description provided for @livingInApiary.
  ///
  /// In en, this message translates to:
  /// **'living it this apiary'**
  String get livingInApiary;

  /// No description provided for @zObuStron.
  ///
  /// In en, this message translates to:
  /// **' on both sides'**
  String get zObuStron;

  /// No description provided for @honeyOnDmFrame.
  ///
  /// In en, this message translates to:
  /// **'The weight of honey contained in 1 dm² of frame (both sides). This should be the average value across multiple frames. This value is used to calculate the approximate amount of honey harvested for each hive.'**
  String get honeyOnDmFrame;

  /// No description provided for @frameDimensions.
  ///
  /// In en, this message translates to:
  /// **'wewnętrzne wymiary ramki'**
  String get frameDimensions;

  /// No description provided for @hiveTypeEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit hive type'**
  String get hiveTypeEdit;

  /// No description provided for @oWnTypeName.
  ///
  /// In en, this message translates to:
  /// **'Own type name'**
  String get oWnTypeName;

  /// No description provided for @wIdth.
  ///
  /// In en, this message translates to:
  /// **'Width'**
  String get wIdth;

  /// No description provided for @hEight.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get hEight;

  /// No description provided for @dImensionsSmallFrame.
  ///
  /// In en, this message translates to:
  /// **'Internal dimensions of the small frame'**
  String get dImensionsSmallFrame;

  /// No description provided for @dImensionsBigFrame.
  ///
  /// In en, this message translates to:
  /// **'Internal dimensions of the big frame'**
  String get dImensionsBigFrame;

  /// No description provided for @pArametersDetermine.
  ///
  /// In en, this message translates to:
  /// **'The parameters determine the internal size of the frames used in the TYPE A hive, which will be used to calculate the honey harvest based on the number of frames received from this hive.'**
  String get pArametersDetermine;

  /// No description provided for @nfcScanning.
  ///
  /// In en, this message translates to:
  /// **'NFC Scanning'**
  String get nfcScanning;

  /// No description provided for @nfcHoldNearTag.
  ///
  /// In en, this message translates to:
  /// **'Hold your phone near the NFC tag'**
  String get nfcHoldNearTag;

  /// No description provided for @nfcNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'NFC is not available on this device'**
  String get nfcNotAvailable;

  /// No description provided for @nfcTagReadError.
  ///
  /// In en, this message translates to:
  /// **'Error reading NFC tag'**
  String get nfcTagReadError;

  /// No description provided for @nfcAssignTag.
  ///
  /// In en, this message translates to:
  /// **'Assign tag to hive'**
  String get nfcAssignTag;

  /// No description provided for @nfcSelectApiary.
  ///
  /// In en, this message translates to:
  /// **'Select apiary'**
  String get nfcSelectApiary;

  /// No description provided for @nfcSelectHive.
  ///
  /// In en, this message translates to:
  /// **'Select hive'**
  String get nfcSelectHive;

  /// No description provided for @nfcAssign.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get nfcAssign;

  /// No description provided for @nfcTagAssigned.
  ///
  /// In en, this message translates to:
  /// **'NFC tag has been assigned to the hive'**
  String get nfcTagAssigned;

  /// No description provided for @nfcNoHivesWithoutTag.
  ///
  /// In en, this message translates to:
  /// **'No hives without NFC tag assigned'**
  String get nfcNoHivesWithoutTag;

  /// No description provided for @nfcButton.
  ///
  /// In en, this message translates to:
  /// **'NFC'**
  String get nfcButton;

  /// No description provided for @nfcTagReadError1.
  ///
  /// In en, this message translates to:
  /// **'Błąd odczytu tagu NFC 1'**
  String get nfcTagReadError1;

  /// No description provided for @nfcTagReadError2.
  ///
  /// In en, this message translates to:
  /// **'Błąd odczytu tagu NFC 2'**
  String get nfcTagReadError2;

  /// No description provided for @nfcTagReadError3.
  ///
  /// In en, this message translates to:
  /// **'Błąd odczytu tagu NFC 3'**
  String get nfcTagReadError3;

  /// No description provided for @nfcTagReadError4.
  ///
  /// In en, this message translates to:
  /// **'Błąd odczytu tagu NFC 4'**
  String get nfcTagReadError4;

  /// No description provided for @calculator.
  ///
  /// In en, this message translates to:
  /// **'Calculators'**
  String get calculator;

  /// No description provided for @sugarSyrup32.
  ///
  /// In en, this message translates to:
  /// **'Sugar syrup 3:2'**
  String get sugarSyrup32;

  /// No description provided for @sugar.
  ///
  /// In en, this message translates to:
  /// **'Sugar'**
  String get sugar;

  /// No description provided for @water.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get water;

  /// No description provided for @result.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get result;

  /// No description provided for @resultLiters.
  ///
  /// In en, this message translates to:
  /// **'Result in liters'**
  String get resultLiters;

  /// No description provided for @resultKilograms.
  ///
  /// In en, this message translates to:
  /// **'Result in kilograms'**
  String get resultKilograms;

  /// No description provided for @syrupLiters.
  ///
  /// In en, this message translates to:
  /// **'Syrup in liters'**
  String get syrupLiters;

  /// No description provided for @syrupKilograms.
  ///
  /// In en, this message translates to:
  /// **'Syrup in kilograms'**
  String get syrupKilograms;

  /// No description provided for @cakeKilograms.
  ///
  /// In en, this message translates to:
  /// **'Cake in kilograms'**
  String get cakeKilograms;

  /// No description provided for @syrupCalculator.
  ///
  /// In en, this message translates to:
  /// **'Syrup calculator'**
  String get syrupCalculator;

  /// No description provided for @sugarSyrup21.
  ///
  /// In en, this message translates to:
  /// **'Sugar syrup 2:1'**
  String get sugarSyrup21;

  /// No description provided for @sugarSyrup11.
  ///
  /// In en, this message translates to:
  /// **'Sugar syrup 1:1'**
  String get sugarSyrup11;

  /// No description provided for @honeySugarCake.
  ///
  /// In en, this message translates to:
  /// **'Honey-sugar cake'**
  String get honeySugarCake;

  /// No description provided for @powderedSugar.
  ///
  /// In en, this message translates to:
  /// **'Powdered\nsugar'**
  String get powderedSugar;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @sendEmail.
  ///
  /// In en, this message translates to:
  /// **'Send by email'**
  String get sendEmail;

  /// No description provided for @noEmailConfigured.
  ///
  /// In en, this message translates to:
  /// **'No email address configured in the app'**
  String get noEmailConfigured;

  /// No description provided for @sendReportToEmail.
  ///
  /// In en, this message translates to:
  /// **'Send report to:'**
  String get sendReportToEmail;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @attachedPdf.
  ///
  /// In en, this message translates to:
  /// **'PDF report attached.'**
  String get attachedPdf;

  /// No description provided for @noLimits.
  ///
  /// In en, this message translates to:
  /// **'no limits'**
  String get noLimits;

  /// No description provided for @summary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summary;

  /// No description provided for @sinceLastInspection.
  ///
  /// In en, this message translates to:
  /// **'days since last inspection'**
  String get sinceLastInspection;

  /// No description provided for @nfcSettings.
  ///
  /// In en, this message translates to:
  /// **'NFC support'**
  String get nfcSettings;

  /// No description provided for @nfcModeOff.
  ///
  /// In en, this message translates to:
  /// **'Disable NFC support'**
  String get nfcModeOff;

  /// No description provided for @nfcModeOffDesc.
  ///
  /// In en, this message translates to:
  /// **'NFC button will be hidden on the home screen'**
  String get nfcModeOffDesc;

  /// No description provided for @nfcModeInfo.
  ///
  /// In en, this message translates to:
  /// **'Open detailed information'**
  String get nfcModeInfo;

  /// No description provided for @nfcModeInfoDesc.
  ///
  /// In en, this message translates to:
  /// **'After reading the NFC tag, detailed information about the hive will be opened'**
  String get nfcModeInfoDesc;

  /// No description provided for @nfcModeSummary.
  ///
  /// In en, this message translates to:
  /// **'Open latest information'**
  String get nfcModeSummary;

  /// No description provided for @nfcModeSummaryDesc.
  ///
  /// In en, this message translates to:
  /// **'After reading the NFC tag, you will be taken to a screen with the latest information from all categories and notes from the Notes regarding the selected hive.'**
  String get nfcModeSummaryDesc;

  /// No description provided for @queenSeen.
  ///
  /// In en, this message translates to:
  /// **'queen seen'**
  String get queenSeen;

  /// No description provided for @queenCellsCount.
  ///
  /// In en, this message translates to:
  /// **'queen cells'**
  String get queenCellsCount;

  /// No description provided for @removedCellsCount.
  ///
  /// In en, this message translates to:
  /// **'removed cells'**
  String get removedCellsCount;

  /// No description provided for @inspectionNote.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get inspectionNote;

  /// No description provided for @frameReview.
  ///
  /// In en, this message translates to:
  /// **'Frame review'**
  String get frameReview;

  /// No description provided for @taskDate.
  ///
  /// In en, this message translates to:
  /// **'Task date'**
  String get taskDate;

  /// No description provided for @queenHistory.
  ///
  /// In en, this message translates to:
  /// **'Queen history'**
  String get queenHistory;

  /// No description provided for @pdfQueenHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Queen history ID {id}'**
  String pdfQueenHistoryTitle(String id);

  /// No description provided for @pdfLp.
  ///
  /// In en, this message translates to:
  /// **'No.'**
  String get pdfLp;

  /// No description provided for @pdfApiaryHive.
  ///
  /// In en, this message translates to:
  /// **'Apiary / Hive'**
  String get pdfApiaryHive;

  /// No description provided for @pdfDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get pdfDate;

  /// No description provided for @pdfHour.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get pdfHour;

  /// No description provided for @pdfTemperature.
  ///
  /// In en, this message translates to:
  /// **'Temp.'**
  String get pdfTemperature;

  /// No description provided for @pdfInformation.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get pdfInformation;

  /// No description provided for @pdfRemarks.
  ///
  /// In en, this message translates to:
  /// **'Remarks'**
  String get pdfRemarks;

  /// No description provided for @pdfLine.
  ///
  /// In en, this message translates to:
  /// **'Line'**
  String get pdfLine;

  /// No description provided for @pdfBreed.
  ///
  /// In en, this message translates to:
  /// **'Breed'**
  String get pdfBreed;

  /// No description provided for @pdfMark.
  ///
  /// In en, this message translates to:
  /// **'Mark'**
  String get pdfMark;

  /// No description provided for @pdfLabel.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get pdfLabel;

  /// No description provided for @pdfSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get pdfSource;

  /// No description provided for @pdfObtainedDate.
  ///
  /// In en, this message translates to:
  /// **'Obtained date'**
  String get pdfObtainedDate;

  /// No description provided for @pdfLostDate.
  ///
  /// In en, this message translates to:
  /// **'Lost'**
  String get pdfLostDate;

  /// No description provided for @pdfGeneratingError.
  ///
  /// In en, this message translates to:
  /// **'PDF generation error'**
  String get pdfGeneratingError;

  /// No description provided for @deleteDataOnSerwer.
  ///
  /// In en, this message translates to:
  /// **'All data on the external server (cloud) that is a backup will be deleted. This deletion is final and cannot be recovered. The data in the app will remain, but it will not be backed up until it is exported to the cloud.'**
  String get deleteDataOnSerwer;

  /// No description provided for @deleteAllDataOnSerwer.
  ///
  /// In en, this message translates to:
  /// **'Deleting cloud backup'**
  String get deleteAllDataOnSerwer;

  /// No description provided for @allDatabaseOnSerwer.
  ///
  /// In en, this message translates to:
  /// **'all data on the external server'**
  String get allDatabaseOnSerwer;

  /// No description provided for @deleteOk.
  ///
  /// In en, this message translates to:
  /// **'The cloud backup has been deleted. Data stored in the app is not backed up.'**
  String get deleteOk;

  /// No description provided for @backupAllData.
  ///
  /// In en, this message translates to:
  /// **'local data backup'**
  String get backupAllData;

  /// No description provided for @showPurchaseSale.
  ///
  /// In en, this message translates to:
  /// **'Show Purchase and Sale buttons'**
  String get showPurchaseSale;

  /// No description provided for @hiveHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Hive {hiveNr} Apiary {apiary} Year {year}'**
  String hiveHistoryTitle(String hiveNr, String apiary, String year);

  /// No description provided for @hiveHistoryTitleAll.
  ///
  /// In en, this message translates to:
  /// **'Hive {hiveNr} Apiary {apiary}'**
  String hiveHistoryTitleAll(String hiveNr, String apiary);

  /// No description provided for @catColumn.
  ///
  /// In en, this message translates to:
  /// **'Cat.'**
  String get catColumn;

  /// No description provided for @tORemove.
  ///
  /// In en, this message translates to:
  /// **'To remove'**
  String get tORemove;

  /// No description provided for @dEleteFoto.
  ///
  /// In en, this message translates to:
  /// **'Deleting photo'**
  String get dEleteFoto;

  /// No description provided for @photoDataSend.
  ///
  /// In en, this message translates to:
  /// **'Photos have been sent'**
  String get photoDataSend;

  /// No description provided for @eXportPhoto.
  ///
  /// In en, this message translates to:
  /// **'Export all photos to the cloud'**
  String get eXportPhoto;

  /// No description provided for @pHotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get pHotos;

  /// No description provided for @selectOnMap.
  ///
  /// In en, this message translates to:
  /// **'Select on map'**
  String get selectOnMap;

  /// No description provided for @selectLocationOnMap.
  ///
  /// In en, this message translates to:
  /// **'Select location'**
  String get selectLocationOnMap;

  /// No description provided for @beeFlightRange.
  ///
  /// In en, this message translates to:
  /// **'Bee flight range (2.5 km)'**
  String get beeFlightRange;

  /// No description provided for @apiaryLocations.
  ///
  /// In en, this message translates to:
  /// **'Apiary locations'**
  String get apiaryLocations;

  /// No description provided for @noApiaryLocations.
  ///
  /// In en, this message translates to:
  /// **'No apiary locations.\nSet the location in the apiary weather settings.'**
  String get noApiaryLocations;

  /// No description provided for @downloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get downloading;

  /// No description provided for @savingToDb.
  ///
  /// In en, this message translates to:
  /// **'Saving to database'**
  String get savingToDb;

  /// No description provided for @rebuildingHives.
  ///
  /// In en, this message translates to:
  /// **'Rebuilding hives'**
  String get rebuildingHives;

  /// No description provided for @rebuildingApiaries.
  ///
  /// In en, this message translates to:
  /// **'Rebuilding apiaries'**
  String get rebuildingApiaries;

  /// No description provided for @finalization.
  ///
  /// In en, this message translates to:
  /// **'Finalization'**
  String get finalization;

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationSettings;

  /// No description provided for @notificationsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications'**
  String get notificationsEnabled;

  /// No description provided for @notificationTime.
  ///
  /// In en, this message translates to:
  /// **'Notification time'**
  String get notificationTime;

  /// No description provided for @notifNotesDesc.
  ///
  /// In en, this message translates to:
  /// **'Remind about task dates from Notes'**
  String get notifNotesDesc;

  /// No description provided for @notifInspectionDesc.
  ///
  /// In en, this message translates to:
  /// **'Remind about hive inspections'**
  String get notifInspectionDesc;

  /// No description provided for @notifFeedingDesc.
  ///
  /// In en, this message translates to:
  /// **'Remind about feeding'**
  String get notifFeedingDesc;

  /// No description provided for @notifTreatmentDesc.
  ///
  /// In en, this message translates to:
  /// **'Remind about treatment'**
  String get notifTreatmentDesc;

  /// No description provided for @remind.
  ///
  /// In en, this message translates to:
  /// **'Remind'**
  String get remind;

  /// No description provided for @remindAfterDays.
  ///
  /// In en, this message translates to:
  /// **'Remind after ... days'**
  String get remindAfterDays;

  /// No description provided for @remindAtTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder time'**
  String get remindAtTime;

  /// No description provided for @aheadSchedule.
  ///
  /// In en, this message translates to:
  /// **'ahead of schedule'**
  String get aheadSchedule;

  /// No description provided for @forr.
  ///
  /// In en, this message translates to:
  /// **'for'**
  String get forr;

  /// No description provided for @sinceLastOne.
  ///
  /// In en, this message translates to:
  /// **'since the last one'**
  String get sinceLastOne;

  /// No description provided for @at.
  ///
  /// In en, this message translates to:
  /// **'  at  '**
  String get at;

  /// No description provided for @pendingNotifications.
  ///
  /// In en, this message translates to:
  /// **'Scheduled notifications'**
  String get pendingNotifications;

  /// No description provided for @noPendingNotifications.
  ///
  /// In en, this message translates to:
  /// **'No scheduled notifications'**
  String get noPendingNotifications;

  /// No description provided for @cancelNotification.
  ///
  /// In en, this message translates to:
  /// **'Cancel notification'**
  String get cancelNotification;

  /// No description provided for @notificationCanceled.
  ///
  /// In en, this message translates to:
  /// **'Notification canceled'**
  String get notificationCanceled;

  /// No description provided for @cancelNotificationConfirm.
  ///
  /// In en, this message translates to:
  /// **'Cancel this notification?'**
  String get cancelNotificationConfirm;

  /// No description provided for @taskExistingTasks.
  ///
  /// In en, this message translates to:
  /// **'Existing tasks'**
  String get taskExistingTasks;

  /// No description provided for @taskExistingMessage.
  ///
  /// In en, this message translates to:
  /// **'There are already tasks planned for this day:'**
  String get taskExistingMessage;

  /// No description provided for @taskAddQuestion.
  ///
  /// In en, this message translates to:
  /// **'Do you want to add a new task to this day?'**
  String get taskAddQuestion;

  /// No description provided for @taskSelectDate.
  ///
  /// In en, this message translates to:
  /// **'Select task date'**
  String get taskSelectDate;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @taskCalendar.
  ///
  /// In en, this message translates to:
  /// **'Task calendar'**
  String get taskCalendar;

  /// No description provided for @taskNoTasks.
  ///
  /// In en, this message translates to:
  /// **'No tasks planned for this day'**
  String get taskNoTasks;

  /// No description provided for @systemLanguage.
  ///
  /// In en, this message translates to:
  /// **'System language'**
  String get systemLanguage;

  /// No description provided for @languageChanged.
  ///
  /// In en, this message translates to:
  /// **'Language changed. The app will restart.'**
  String get languageChanged;

  /// No description provided for @deleteHive.
  ///
  /// In en, this message translates to:
  /// **'Delete hive'**
  String get deleteHive;

  /// No description provided for @moveHive.
  ///
  /// In en, this message translates to:
  /// **'Move hive'**
  String get moveHive;

  /// No description provided for @deleteHiveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete hive {ulNr} from apiary {pasiekaNr}? All data (frames, inspections, notes, photos) will be permanently deleted!'**
  String deleteHiveConfirm(int ulNr, int pasiekaNr);

  /// No description provided for @deleteHiveWarning.
  ///
  /// In en, this message translates to:
  /// **'WARNING: This operation is irreversible!'**
  String get deleteHiveWarning;

  /// No description provided for @hiveDeleted.
  ///
  /// In en, this message translates to:
  /// **'Hive deleted'**
  String get hiveDeleted;

  /// No description provided for @hiveMoved.
  ///
  /// In en, this message translates to:
  /// **'Hive moved'**
  String get hiveMoved;

  /// No description provided for @selectApiary.
  ///
  /// In en, this message translates to:
  /// **'Select apiary'**
  String get selectApiary;

  /// No description provided for @selectHive.
  ///
  /// In en, this message translates to:
  /// **'Select hive'**
  String get selectHive;

  /// No description provided for @sourceApiary.
  ///
  /// In en, this message translates to:
  /// **'Source apiary'**
  String get sourceApiary;

  /// No description provided for @sourceHive.
  ///
  /// In en, this message translates to:
  /// **'Source hive'**
  String get sourceHive;

  /// No description provided for @destApiaryNr.
  ///
  /// In en, this message translates to:
  /// **'Destination apiary nr'**
  String get destApiaryNr;

  /// No description provided for @destHiveNr.
  ///
  /// In en, this message translates to:
  /// **'Destination hive nr'**
  String get destHiveNr;

  /// No description provided for @moveWithHistory.
  ///
  /// In en, this message translates to:
  /// **'With history'**
  String get moveWithHistory;

  /// No description provided for @moveWithoutHistory.
  ///
  /// In en, this message translates to:
  /// **'Without history'**
  String get moveWithoutHistory;

  /// No description provided for @moveWithHistoryDesc.
  ///
  /// In en, this message translates to:
  /// **'Moves all data: frames, inspections, infos, notes, photos'**
  String get moveWithHistoryDesc;

  /// No description provided for @moveWithoutHistoryDesc.
  ///
  /// In en, this message translates to:
  /// **'Creates a new hive with technical parameters, moves the queen'**
  String get moveWithoutHistoryDesc;

  /// No description provided for @hiveAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'A hive with this number already exists in the destination apiary'**
  String get hiveAlreadyExists;

  /// No description provided for @newApiaryWillBeCreated.
  ///
  /// In en, this message translates to:
  /// **'Destination apiary does not exist - it will be created'**
  String get newApiaryWillBeCreated;

  /// No description provided for @cannotMoveSameLocation.
  ///
  /// In en, this message translates to:
  /// **'Cannot move to the same location'**
  String get cannotMoveSameLocation;

  /// No description provided for @movedFrom.
  ///
  /// In en, this message translates to:
  /// **'Moved from apiary {src} / hive {srcUl}'**
  String movedFrom(int src, int srcUl);

  /// No description provided for @movedTo.
  ///
  /// In en, this message translates to:
  /// **'Hive moved to apiary {dst} / hive {dstUl}'**
  String movedTo(int dst, int dstUl);

  /// No description provided for @whatToDoWithOldHive.
  ///
  /// In en, this message translates to:
  /// **'What to do with the old hive?'**
  String get whatToDoWithOldHive;

  /// No description provided for @leaveHive.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leaveHive;

  /// No description provided for @leaveHiveDesc.
  ///
  /// In en, this message translates to:
  /// **'Keeps the old hive with history, creates a new one with the same parameters and moves the queen.'**
  String get leaveHiveDesc;

  /// No description provided for @liquidateHive.
  ///
  /// In en, this message translates to:
  /// **'Liquidate'**
  String get liquidateHive;

  /// No description provided for @liquidateHiveDesc.
  ///
  /// In en, this message translates to:
  /// **'Keeps the old hive with history and adds transfer info, creates a new one with the same parameters and moves the queen.'**
  String get liquidateHiveDesc;

  /// No description provided for @deleteOldHive.
  ///
  /// In en, this message translates to:
  /// **'Delete with data'**
  String get deleteOldHive;

  /// No description provided for @deleteOldHiveDesc.
  ///
  /// In en, this message translates to:
  /// **'Creates a new hive with the same parameters, moves the queen and deletes the old hive.'**
  String get deleteOldHiveDesc;

  /// No description provided for @emptyApiaryDeleted.
  ///
  /// In en, this message translates to:
  /// **'Empty apiary {nr} has been deleted'**
  String emptyApiaryDeleted(int nr);

  /// No description provided for @move.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get move;

  /// No description provided for @moving.
  ///
  /// In en, this message translates to:
  /// **'Moving...'**
  String get moving;

  /// No description provided for @createdInApiary.
  ///
  /// In en, this message translates to:
  /// **'created in the apiary'**
  String get createdInApiary;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'selected'**
  String get selected;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectAll;

  /// No description provided for @deselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect all'**
  String get deselectAll;

  /// No description provided for @pHoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get pHoto;

  /// No description provided for @gAllery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gAllery;

  /// No description provided for @selectHives.
  ///
  /// In en, this message translates to:
  /// **'Select hives'**
  String get selectHives;

  /// No description provided for @selectedHives.
  ///
  /// In en, this message translates to:
  /// **'Selected hives'**
  String get selectedHives;

  /// No description provided for @noHivesInApiary.
  ///
  /// In en, this message translates to:
  /// **'No hives in this apiary'**
  String get noHivesInApiary;

  /// No description provided for @noteCreatedForHives.
  ///
  /// In en, this message translates to:
  /// **'Note created for {count} hives'**
  String noteCreatedForHives(int count);

  /// No description provided for @oxalicAcidSolution.
  ///
  /// In en, this message translates to:
  /// **'Oxalic acid 3.2%'**
  String get oxalicAcidSolution;

  /// No description provided for @oxalicAcid.
  ///
  /// In en, this message translates to:
  /// **'Oxalic acid'**
  String get oxalicAcid;

  /// No description provided for @oxalicSolutionLiters.
  ///
  /// In en, this message translates to:
  /// **'Solution in liters'**
  String get oxalicSolutionLiters;

  /// No description provided for @oxalicColonies.
  ///
  /// In en, this message translates to:
  /// **'Number of colonies'**
  String get oxalicColonies;

  /// No description provided for @oxalicAcidRecipe.
  ///
  /// In en, this message translates to:
  /// **'3.2% oxalic acid solution for dousing bees.\nDose: approximately 50 ml per colony (5 ml per bee alley).'**
  String get oxalicAcidRecipe;

  /// No description provided for @lacticAcidSolution.
  ///
  /// In en, this message translates to:
  /// **'Lactic acid 15%'**
  String get lacticAcidSolution;

  /// No description provided for @lacticAcid.
  ///
  /// In en, this message translates to:
  /// **'Lactic acid'**
  String get lacticAcid;

  /// No description provided for @lacticSolutionLiters.
  ///
  /// In en, this message translates to:
  /// **'Solution 15% in liters'**
  String get lacticSolutionLiters;

  /// No description provided for @lacticColonies.
  ///
  /// In en, this message translates to:
  /// **'Number of colonies'**
  String get lacticColonies;

  /// No description provided for @lacticAcidRecipe.
  ///
  /// In en, this message translates to:
  /// **'15% lactic acid solution for spraying bees on frames.\nDose: 10 ml per frame (approx. 50 ml per colony).'**
  String get lacticAcidRecipe;

  /// No description provided for @queenRearingCalendar.
  ///
  /// In en, this message translates to:
  /// **'Queen rearing'**
  String get queenRearingCalendar;

  /// No description provided for @qrGraftingDate.
  ///
  /// In en, this message translates to:
  /// **'Grafting\ndate'**
  String get qrGraftingDate;

  /// No description provided for @qrNotifTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get qrNotifTime;

  /// No description provided for @qrDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get qrDay;

  /// No description provided for @qrGrafting.
  ///
  /// In en, this message translates to:
  /// **'Transferring one-day-old larvae'**
  String get qrGrafting;

  /// No description provided for @qrCheckAcceptance.
  ///
  /// In en, this message translates to:
  /// **'Check acceptance'**
  String get qrCheckAcceptance;

  /// No description provided for @qrCellsSealed.
  ///
  /// In en, this message translates to:
  /// **'Queen cells sealed'**
  String get qrCellsSealed;

  /// No description provided for @qrHistolysis.
  ///
  /// In en, this message translates to:
  /// **'Histolysis'**
  String get qrHistolysis;

  /// No description provided for @qrCellIsolation.
  ///
  /// In en, this message translates to:
  /// **'Queen cell isolation'**
  String get qrCellIsolation;

  /// No description provided for @qrTransferToNucs.
  ///
  /// In en, this message translates to:
  /// **'Transfer to mating nucs'**
  String get qrTransferToNucs;

  /// No description provided for @qrQueenEmergence.
  ///
  /// In en, this message translates to:
  /// **'Queen emergence'**
  String get qrQueenEmergence;

  /// No description provided for @qrMatingFlights.
  ///
  /// In en, this message translates to:
  /// **'Mating flights'**
  String get qrMatingFlights;

  /// No description provided for @qrCheckLaying.
  ///
  /// In en, this message translates to:
  /// **'Check for laying'**
  String get qrCheckLaying;

  /// No description provided for @qrScheduleNotifications.
  ///
  /// In en, this message translates to:
  /// **'Set notifications'**
  String get qrScheduleNotifications;

  /// No description provided for @qrCancelNotifications.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get qrCancelNotifications;

  /// No description provided for @qrReschedule.
  ///
  /// In en, this message translates to:
  /// **'Reschedule'**
  String get qrReschedule;

  /// No description provided for @qrNotificationsScheduled.
  ///
  /// In en, this message translates to:
  /// **'Notifications scheduled'**
  String get qrNotificationsScheduled;

  /// No description provided for @qrNotificationsCancelled.
  ///
  /// In en, this message translates to:
  /// **'Notifications cancelled'**
  String get qrNotificationsCancelled;

  /// No description provided for @qrNewCalendar.
  ///
  /// In en, this message translates to:
  /// **'New rearing calendar'**
  String get qrNewCalendar;

  /// No description provided for @qrCalendarName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get qrCalendarName;

  /// No description provided for @qrDeleteCalendar.
  ///
  /// In en, this message translates to:
  /// **'Delete calendar?'**
  String get qrDeleteCalendar;

  /// No description provided for @qrNoCalendars.
  ///
  /// In en, this message translates to:
  /// **'No queen rearing calendars.\nAdd a new one with the + button'**
  String get qrNoCalendars;

  /// No description provided for @soundVolume.
  ///
  /// In en, this message translates to:
  /// **'Sound Volume'**
  String get soundVolume;

  /// No description provided for @soundWakeWord.
  ///
  /// In en, this message translates to:
  /// **'Hey Maya detected'**
  String get soundWakeWord;

  /// No description provided for @soundStart.
  ///
  /// In en, this message translates to:
  /// **'Start listening'**
  String get soundStart;

  /// No description provided for @soundListening.
  ///
  /// In en, this message translates to:
  /// **'Back to listening'**
  String get soundListening;

  /// No description provided for @soundSuccess.
  ///
  /// In en, this message translates to:
  /// **'Note saved'**
  String get soundSuccess;

  /// No description provided for @soundOpen.
  ///
  /// In en, this message translates to:
  /// **'Opening'**
  String get soundOpen;

  /// No description provided for @soundClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get soundClose;

  /// No description provided for @soundError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get soundError;

  /// No description provided for @soundNieRozumiem.
  ///
  /// In en, this message translates to:
  /// **'Don\'t understand'**
  String get soundNieRozumiem;

  /// No description provided for @soundNieTutaj.
  ///
  /// In en, this message translates to:
  /// **'Not here'**
  String get soundNieTutaj;

  /// No description provided for @soundPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get soundPlay;

  /// No description provided for @masterVolume.
  ///
  /// In en, this message translates to:
  /// **'Master volume'**
  String get masterVolume;

  /// No description provided for @withoutApiary.
  ///
  /// In en, this message translates to:
  /// **'Without apiary'**
  String get withoutApiary;

  /// No description provided for @hiveNews.
  ///
  /// In en, this message translates to:
  /// **'Hive news'**
  String get hiveNews;

  /// No description provided for @photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photos;

  /// No description provided for @legendWorkFrame.
  ///
  /// In en, this message translates to:
  /// **'work frame'**
  String get legendWorkFrame;

  /// No description provided for @legendToDelete.
  ///
  /// In en, this message translates to:
  /// **'to delete'**
  String get legendToDelete;

  /// No description provided for @legendToExtraction.
  ///
  /// In en, this message translates to:
  /// **'to extraction'**
  String get legendToExtraction;

  /// No description provided for @legendToInsulate.
  ///
  /// In en, this message translates to:
  /// **'to insulate'**
  String get legendToInsulate;

  /// No description provided for @legendQueen.
  ///
  /// In en, this message translates to:
  /// **'queen'**
  String get legendQueen;

  /// No description provided for @legendWaxFoundation.
  ///
  /// In en, this message translates to:
  /// **'wax foundation'**
  String get legendWaxFoundation;

  /// No description provided for @legendWaxComb.
  ///
  /// In en, this message translates to:
  /// **'wax comb'**
  String get legendWaxComb;

  /// No description provided for @legendHoneySealed.
  ///
  /// In en, this message translates to:
  /// **'ripe honey'**
  String get legendHoneySealed;

  /// No description provided for @legendHoneyFood.
  ///
  /// In en, this message translates to:
  /// **'honey/food'**
  String get legendHoneyFood;

  /// No description provided for @legendPollen.
  ///
  /// In en, this message translates to:
  /// **'pollen'**
  String get legendPollen;

  /// No description provided for @legendEggs.
  ///
  /// In en, this message translates to:
  /// **'eggs'**
  String get legendEggs;

  /// No description provided for @legendLarvae.
  ///
  /// In en, this message translates to:
  /// **'larvae'**
  String get legendLarvae;

  /// No description provided for @legendCoveredBrood.
  ///
  /// In en, this message translates to:
  /// **'covered brood'**
  String get legendCoveredBrood;

  /// No description provided for @legendDrone.
  ///
  /// In en, this message translates to:
  /// **'drone'**
  String get legendDrone;

  /// No description provided for @legendInserted.
  ///
  /// In en, this message translates to:
  /// **'inserted'**
  String get legendInserted;

  /// No description provided for @legendDeleted.
  ///
  /// In en, this message translates to:
  /// **'deleted'**
  String get legendDeleted;

  /// No description provided for @legendMovedLeft.
  ///
  /// In en, this message translates to:
  /// **'moved left'**
  String get legendMovedLeft;

  /// No description provided for @legendMovedRight.
  ///
  /// In en, this message translates to:
  /// **'moved right'**
  String get legendMovedRight;

  /// No description provided for @legendInsulated.
  ///
  /// In en, this message translates to:
  /// **'insulated'**
  String get legendInsulated;

  /// No description provided for @legendQueenCell.
  ///
  /// In en, this message translates to:
  /// **'queen cell'**
  String get legendQueenCell;

  /// No description provided for @legendDeleteQueenCell.
  ///
  /// In en, this message translates to:
  /// **'delete queen cell'**
  String get legendDeleteQueenCell;

  /// No description provided for @legendExcluder.
  ///
  /// In en, this message translates to:
  /// **'excluder'**
  String get legendExcluder;

  /// No description provided for @legendBodyNumber.
  ///
  /// In en, this message translates to:
  /// **'body number'**
  String get legendBodyNumber;

  /// No description provided for @sUpport.
  ///
  /// In en, this message translates to:
  /// **'Support opportunities:'**
  String get sUpport;

  /// No description provided for @undoDone.
  ///
  /// In en, this message translates to:
  /// **'Undone'**
  String get undoDone;

  /// No description provided for @undoNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing to undo'**
  String get undoNothing;

  /// No description provided for @undoFailed.
  ///
  /// In en, this message translates to:
  /// **'Undo failed'**
  String get undoFailed;

  /// No description provided for @voicePreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing speech recognition...'**
  String get voicePreparing;

  /// No description provided for @voiceDownloadingModel.
  ///
  /// In en, this message translates to:
  /// **'Downloading the language model ({size}), once only...'**
  String voiceDownloadingModel(String size);

  /// No description provided for @voiceLoadingModel.
  ///
  /// In en, this message translates to:
  /// **'Loading the model...'**
  String get voiceLoadingModel;

  /// No description provided for @voiceBuildingGrammar.
  ///
  /// In en, this message translates to:
  /// **'Building the command grammar...'**
  String get voiceBuildingGrammar;

  /// No description provided for @voiceErrInit.
  ///
  /// In en, this message translates to:
  /// **'Could not prepare speech recognition.'**
  String get voiceErrInit;

  /// No description provided for @voiceErrRecognizer.
  ///
  /// In en, this message translates to:
  /// **'Could not create the Vosk recognizer.'**
  String get voiceErrRecognizer;

  /// No description provided for @voiceErrMicStart.
  ///
  /// In en, this message translates to:
  /// **'Could not start the microphone.'**
  String get voiceErrMicStart;

  /// No description provided for @voiceErrModeSwitch.
  ///
  /// In en, this message translates to:
  /// **'Could not switch listening to mode'**
  String get voiceErrModeSwitch;

  /// No description provided for @voiceErrAudioStream.
  ///
  /// In en, this message translates to:
  /// **'Audio stream error:'**
  String get voiceErrAudioStream;

  /// No description provided for @voiceErrAudioProcess.
  ///
  /// In en, this message translates to:
  /// **'Audio processing error:'**
  String get voiceErrAudioProcess;

  /// No description provided for @voiceErrGrammar.
  ///
  /// In en, this message translates to:
  /// **'Command grammar error:'**
  String get voiceErrGrammar;

  /// No description provided for @voiceNoMicPermission.
  ///
  /// In en, this message translates to:
  /// **'No microphone permission.'**
  String get voiceNoMicPermission;

  /// No description provided for @voiceMicPermAndroid.
  ///
  /// In en, this message translates to:
  /// **'Android: Settings → Apps → Hey Maya → Permissions → Microphone.'**
  String get voiceMicPermAndroid;

  /// No description provided for @voiceMicPermIos.
  ///
  /// In en, this message translates to:
  /// **'iOS: Settings → Hey Maya → Microphone.'**
  String get voiceMicPermIos;

  /// No description provided for @voiceMicBusy.
  ///
  /// In en, this message translates to:
  /// **'Microphone busy.'**
  String get voiceMicBusy;

  /// No description provided for @voiceMicBusyRetrying.
  ///
  /// In en, this message translates to:
  /// **'Microphone busy. Still trying...'**
  String get voiceMicBusyRetrying;

  /// No description provided for @voiceMicBusyWillReturn.
  ///
  /// In en, this message translates to:
  /// **'The microphone is busy. Still trying - I will come back when it is free.'**
  String get voiceMicBusyWillReturn;

  /// No description provided for @voiceMicSilentAndroid.
  ///
  /// In en, this message translates to:
  /// **'The microphone went silent (a call, the assistant or an alarm).'**
  String get voiceMicSilentAndroid;

  /// No description provided for @voiceMicSilentIos.
  ///
  /// In en, this message translates to:
  /// **'The microphone went silent (a call, Siri or an alarm).'**
  String get voiceMicSilentIos;

  /// No description provided for @voiceAudioClosed.
  ///
  /// In en, this message translates to:
  /// **'Audio stream closed by the system.'**
  String get voiceAudioClosed;

  /// No description provided for @voiceResuming.
  ///
  /// In en, this message translates to:
  /// **'Resuming listening...'**
  String get voiceResuming;

  /// No description provided for @voicePaused.
  ///
  /// In en, this message translates to:
  /// **'Listening paused.'**
  String get voicePaused;

  /// No description provided for @voiceStandby.
  ///
  /// In en, this message translates to:
  /// **'Standing by. Say "Hey Maya start" to begin.'**
  String get voiceStandby;

  /// No description provided for @voiceListening.
  ///
  /// In en, this message translates to:
  /// **'Listening for commands.'**
  String get voiceListening;

  /// No description provided for @voiceDictate.
  ///
  /// In en, this message translates to:
  /// **'Dictate the note. Finish by saying "Hey Maya".'**
  String get voiceDictate;

  /// No description provided for @voiceMicRecovering.
  ///
  /// In en, this message translates to:
  /// **'Trying to recover the microphone...'**
  String get voiceMicRecovering;

  /// No description provided for @voiceMicStillBusy.
  ///
  /// In en, this message translates to:
  /// **'Microphone still busy. Still trying...'**
  String get voiceMicStillBusy;

  /// No description provided for @voiceNoteNeedPlace.
  ///
  /// In en, this message translates to:
  /// **'Note for the inspection: first say which apiary and which hive (e.g. "apiary one", "hive seven"). A note for the notepad can be dictated right away.'**
  String get voiceNoteNeedPlace;

  /// No description provided for @voiceNoteUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Note unavailable:'**
  String get voiceNoteUnavailable;

  /// No description provided for @voiceNoteNothingHeard.
  ///
  /// In en, this message translates to:
  /// **'I did not hear a note - nothing was saved.'**
  String get voiceNoteNothingHeard;

  /// No description provided for @voiceNoteSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'The note could NOT be saved'**
  String get voiceNoteSaveFailed;

  /// No description provided for @voiceNoteContent.
  ///
  /// In en, this message translates to:
  /// **'Content:'**
  String get voiceNoteContent;

  /// No description provided for @voiceSetLivePreview.
  ///
  /// In en, this message translates to:
  /// **'Live body preview during commands'**
  String get voiceSetLivePreview;

  /// No description provided for @voiceSetDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Voice diagnostics'**
  String get voiceSetDiagnostics;

  /// No description provided for @voiceSetRecording.
  ///
  /// In en, this message translates to:
  /// **'Note recording'**
  String get voiceSetRecording;

  /// No description provided for @voiceSetLandscape.
  ///
  /// In en, this message translates to:
  /// **'Voice 2 - landscape layout'**
  String get voiceSetLandscape;

  /// No description provided for @voiceSetLandscapeSub.
  ///
  /// In en, this message translates to:
  /// **'Force landscape layout for the live body preview (regardless of device orientation)'**
  String get voiceSetLandscapeSub;

  /// No description provided for @voiceSetSignal.
  ///
  /// In en, this message translates to:
  /// **'Command confirmation signal'**
  String get voiceSetSignal;

  /// No description provided for @voiceNotUnderstood.
  ///
  /// In en, this message translates to:
  /// **'I did not understand the command.'**
  String get voiceNotUnderstood;

  /// No description provided for @voiceEngineNoResponse.
  ///
  /// In en, this message translates to:
  /// **'the engine did not respond within 5 s'**
  String get voiceEngineNoResponse;

  /// No description provided for @voiceUnknownReason.
  ///
  /// In en, this message translates to:
  /// **'unknown reason'**
  String get voiceUnknownReason;

  /// No description provided for @voiceNoteWord.
  ///
  /// In en, this message translates to:
  /// **'the note'**
  String get voiceNoteWord;

  /// No description provided for @voiceNoteAtInspection.
  ///
  /// In en, this message translates to:
  /// **'in the inspection'**
  String get voiceNoteAtInspection;

  /// No description provided for @voiceNoteInNotepad.
  ///
  /// In en, this message translates to:
  /// **'the note in the notepad'**
  String get voiceNoteInNotepad;

  /// No description provided for @voiceNoteWhereNotepad.
  ///
  /// In en, this message translates to:
  /// **'in the Notepad'**
  String get voiceNoteWhereNotepad;

  /// No description provided for @voiceNoteSavedPrefix.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get voiceNoteSavedPrefix;

  /// No description provided for @voiceNoteWithRecording.
  ///
  /// In en, this message translates to:
  /// **'together with the recording'**
  String get voiceNoteWithRecording;

  /// No description provided for @voiceNoteLimitReached.
  ///
  /// In en, this message translates to:
  /// **'(length limit reached)'**
  String get voiceNoteLimitReached;

  /// No description provided for @voiceNoteRecordedOnly.
  ///
  /// In en, this message translates to:
  /// **'I did not recognise any words, but the recording was saved - listen to it'**
  String get voiceNoteRecordedOnly;

  /// No description provided for @voiceNoteNoWords.
  ///
  /// In en, this message translates to:
  /// **'(recording - no words recognised)'**
  String get voiceNoteNoWords;

  /// No description provided for @voiceTipDictating.
  ///
  /// In en, this message translates to:
  /// **'Dictating a note — tap to finish'**
  String get voiceTipDictating;

  /// No description provided for @voiceTipMicUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Microphone unavailable — tap to try again'**
  String get voiceTipMicUnavailable;

  /// No description provided for @voiceTipListening.
  ///
  /// In en, this message translates to:
  /// **'Listening for commands — "Hey Maya stop"'**
  String get voiceTipListening;

  /// No description provided for @voiceTipStandby.
  ///
  /// In en, this message translates to:
  /// **'Standing by — "Hey Maya start"'**
  String get voiceTipStandby;

  /// No description provided for @voiceNoteHeaderNotepad.
  ///
  /// In en, this message translates to:
  /// **'Note for the notepad - finish by saying "Hey Maya"'**
  String get voiceNoteHeaderNotepad;

  /// No description provided for @voiceNoteHeaderInspection.
  ///
  /// In en, this message translates to:
  /// **'Note for the inspection - finish by saying "Hey Maya"'**
  String get voiceNoteHeaderInspection;

  /// No description provided for @voiceListeningDots.
  ///
  /// In en, this message translates to:
  /// **'listening...'**
  String get voiceListeningDots;

  /// No description provided for @voiceNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Note - speak, finish by saying "Hey Maya"'**
  String get voiceNoteHint;

  /// No description provided for @voiceGrammarOutdated.
  ///
  /// In en, this message translates to:
  /// **'WARNING: the loaded grammar does not know the note or undo command - the app bundle contains an outdated grammar file. Rebuild the app (full restart, not hot reload).'**
  String get voiceGrammarOutdated;
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
        'de',
        'en',
        'es',
        'fr',
        'it',
        'pl',
        'pt'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'pl':
      return AppLocalizationsPl();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
