import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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
    Locale('ar'),
    Locale('en'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Worqly'**
  String get appTitle;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @attendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get attendance;

  /// No description provided for @services.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get services;

  /// No description provided for @staff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get staff;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @systemCheck.
  ///
  /// In en, this message translates to:
  /// **'System Check'**
  String get systemCheck;

  /// No description provided for @connectedToSupabase.
  ///
  /// In en, this message translates to:
  /// **'Connected to Supabase'**
  String get connectedToSupabase;

  /// No description provided for @connectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection Failed'**
  String get connectionFailed;

  /// No description provided for @proceedToApp.
  ///
  /// In en, this message translates to:
  /// **'Proceed to App'**
  String get proceedToApp;

  /// No description provided for @configurationRequired.
  ///
  /// In en, this message translates to:
  /// **'Configuration Required'**
  String get configurationRequired;

  /// No description provided for @configurationMessage.
  ///
  /// In en, this message translates to:
  /// **'Please update lib/core/constants/supabase_env.dart with your Supabase URL and Anon Key.'**
  String get configurationMessage;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign In'**
  String get alreadyHaveAccount;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign Up'**
  String get dontHaveAccount;

  /// No description provided for @signUpSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Sign up successful! Please check your email for confirmation.'**
  String get signUpSuccessful;

  /// No description provided for @profileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Profile not found. Please contact support.'**
  String get profileNotFound;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// No description provided for @clientDetails.
  ///
  /// In en, this message translates to:
  /// **'Client Details'**
  String get clientDetails;

  /// No description provided for @contactInfo.
  ///
  /// In en, this message translates to:
  /// **'Contact Info'**
  String get contactInfo;

  /// No description provided for @clientName.
  ///
  /// In en, this message translates to:
  /// **'Client Name'**
  String get clientName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @projectHistory.
  ///
  /// In en, this message translates to:
  /// **'Project History'**
  String get projectHistory;

  /// No description provided for @noWorkHistory.
  ///
  /// In en, this message translates to:
  /// **'No work history found'**
  String get noWorkHistory;

  /// No description provided for @taskDetails.
  ///
  /// In en, this message translates to:
  /// **'Task Details'**
  String get taskDetails;

  /// No description provided for @generalInfo.
  ///
  /// In en, this message translates to:
  /// **'General Information'**
  String get generalInfo;

  /// No description provided for @documents.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documents;

  /// No description provided for @timeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get timeline;

  /// No description provided for @dailyUpdateNotes.
  ///
  /// In en, this message translates to:
  /// **'Daily Update Notes'**
  String get dailyUpdateNotes;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @officeDetails.
  ///
  /// In en, this message translates to:
  /// **'Office Details'**
  String get officeDetails;

  /// No description provided for @officeName.
  ///
  /// In en, this message translates to:
  /// **'Office Name'**
  String get officeName;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @managerName.
  ///
  /// In en, this message translates to:
  /// **'Manager Name'**
  String get managerName;

  /// No description provided for @managerPhone.
  ///
  /// In en, this message translates to:
  /// **'Manager Phone'**
  String get managerPhone;

  /// No description provided for @officeMobile.
  ///
  /// In en, this message translates to:
  /// **'Office Mobile'**
  String get officeMobile;

  /// No description provided for @officeLandline.
  ///
  /// In en, this message translates to:
  /// **'Office Landline'**
  String get officeLandline;

  /// No description provided for @revenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get revenue;

  /// No description provided for @staffCount.
  ///
  /// In en, this message translates to:
  /// **'Staff Count'**
  String get staffCount;

  /// No description provided for @workloadCapacity.
  ///
  /// In en, this message translates to:
  /// **'Workload Capacity'**
  String get workloadCapacity;

  /// No description provided for @assignedStaff.
  ///
  /// In en, this message translates to:
  /// **'Assigned Staff'**
  String get assignedStaff;

  /// No description provided for @officeWorkHistory.
  ///
  /// In en, this message translates to:
  /// **'Office Work History'**
  String get officeWorkHistory;

  /// No description provided for @officeClients.
  ///
  /// In en, this message translates to:
  /// **'Office Clients'**
  String get officeClients;

  /// No description provided for @deleteOffice.
  ///
  /// In en, this message translates to:
  /// **'Delete Office'**
  String get deleteOffice;

  /// No description provided for @editOffice.
  ///
  /// In en, this message translates to:
  /// **'Edit Office'**
  String get editOffice;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this?'**
  String get confirmDelete;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @priority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get high;

  /// No description provided for @medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// No description provided for @low.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get low;

  /// No description provided for @caseId.
  ///
  /// In en, this message translates to:
  /// **'Case ID'**
  String get caseId;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @uploadNew.
  ///
  /// In en, this message translates to:
  /// **'Upload New'**
  String get uploadNew;

  /// No description provided for @noHistoryFound.
  ///
  /// In en, this message translates to:
  /// **'No history recorded yet'**
  String get noHistoryFound;

  /// No description provided for @notesHint.
  ///
  /// In en, this message translates to:
  /// **'Enter today\'s status updates here...'**
  String get notesHint;

  /// No description provided for @manageStaffComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Manage staff assignments coming soon'**
  String get manageStaffComingSoon;

  /// No description provided for @noStaffAssigned.
  ///
  /// In en, this message translates to:
  /// **'No staff assigned'**
  String get noStaffAssigned;

  /// No description provided for @noClientsFound.
  ///
  /// In en, this message translates to:
  /// **'No clients found'**
  String get noClientsFound;

  /// No description provided for @noPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'No phone number'**
  String get noPhoneNumber;

  /// No description provided for @generalService.
  ///
  /// In en, this message translates to:
  /// **'General Service'**
  String get generalService;

  /// No description provided for @assign.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get assign;

  /// No description provided for @executiveOverview.
  ///
  /// In en, this message translates to:
  /// **'Executive Overview'**
  String get executiveOverview;

  /// No description provided for @vision2030Portal.
  ///
  /// In en, this message translates to:
  /// **'Worqly Platform'**
  String get vision2030Portal;

  /// No description provided for @monthlyRevenue.
  ///
  /// In en, this message translates to:
  /// **'Monthly Revenue'**
  String get monthlyRevenue;

  /// No description provided for @vsLastMonth.
  ///
  /// In en, this message translates to:
  /// **'vs last month'**
  String get vsLastMonth;

  /// No description provided for @activeCases.
  ///
  /// In en, this message translates to:
  /// **'Active Cases'**
  String get activeCases;

  /// No description provided for @pendingApprovals.
  ///
  /// In en, this message translates to:
  /// **'Pending Approvals'**
  String get pendingApprovals;

  /// No description provided for @operationalTrends.
  ///
  /// In en, this message translates to:
  /// **'Operational Trends'**
  String get operationalTrends;

  /// No description provided for @viewDetailed.
  ///
  /// In en, this message translates to:
  /// **'View Detailed'**
  String get viewDetailed;

  /// No description provided for @superAdmin.
  ///
  /// In en, this message translates to:
  /// **'Super Admin'**
  String get superAdmin;

  /// No description provided for @regionalOffices.
  ///
  /// In en, this message translates to:
  /// **'Regional Offices'**
  String get regionalOffices;

  /// No description provided for @branchManagement.
  ///
  /// In en, this message translates to:
  /// **'Branch Management'**
  String get branchManagement;

  /// No description provided for @ksaNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get ksaNetwork;

  /// No description provided for @activeBranches.
  ///
  /// In en, this message translates to:
  /// **'Active Branches'**
  String get activeBranches;

  /// No description provided for @addNewOffice.
  ///
  /// In en, this message translates to:
  /// **'Add New Office'**
  String get addNewOffice;

  /// No description provided for @searchOffices.
  ///
  /// In en, this message translates to:
  /// **'Search offices...'**
  String get searchOffices;

  /// No description provided for @networkPerformance.
  ///
  /// In en, this message translates to:
  /// **'Network Performance'**
  String get networkPerformance;

  /// No description provided for @totalRevenue.
  ///
  /// In en, this message translates to:
  /// **'Total Revenue'**
  String get totalRevenue;

  /// No description provided for @avgWorkloadCapacity.
  ///
  /// In en, this message translates to:
  /// **'Avg. Workload Capacity'**
  String get avgWorkloadCapacity;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @systemAuthority.
  ///
  /// In en, this message translates to:
  /// **'System Authority'**
  String get systemAuthority;

  /// No description provided for @assignWork.
  ///
  /// In en, this message translates to:
  /// **'Assign Work'**
  String get assignWork;

  /// No description provided for @errorLoadingStaff.
  ///
  /// In en, this message translates to:
  /// **'Error loading staff'**
  String get errorLoadingStaff;

  /// No description provided for @staffDetails.
  ///
  /// In en, this message translates to:
  /// **'Staff Details'**
  String get staffDetails;

  /// No description provided for @adminDetails.
  ///
  /// In en, this message translates to:
  /// **'Admin Details'**
  String get adminDetails;

  /// No description provided for @professionalProfile.
  ///
  /// In en, this message translates to:
  /// **'Professional Profile'**
  String get professionalProfile;

  /// No description provided for @performanceMetrics.
  ///
  /// In en, this message translates to:
  /// **'Performance Metrics'**
  String get performanceMetrics;

  /// No description provided for @accessPermissions.
  ///
  /// In en, this message translates to:
  /// **'Access & Permissions'**
  String get accessPermissions;

  /// No description provided for @deactivateAccount.
  ///
  /// In en, this message translates to:
  /// **'Deactivate Account'**
  String get deactivateAccount;

  /// No description provided for @reactivateAccount.
  ///
  /// In en, this message translates to:
  /// **'Reactivate Account'**
  String get reactivateAccount;

  /// No description provided for @portalRole.
  ///
  /// In en, this message translates to:
  /// **'Portal Role'**
  String get portalRole;

  /// No description provided for @joinedDate.
  ///
  /// In en, this message translates to:
  /// **'Joined Date'**
  String get joinedDate;

  /// No description provided for @tasksDone.
  ///
  /// In en, this message translates to:
  /// **'Tasks Done'**
  String get tasksDone;

  /// No description provided for @efficiency.
  ///
  /// In en, this message translates to:
  /// **'Efficiency'**
  String get efficiency;

  /// No description provided for @assignedOffice.
  ///
  /// In en, this message translates to:
  /// **'Assigned Office'**
  String get assignedOffice;

  /// No description provided for @biometricAuth.
  ///
  /// In en, this message translates to:
  /// **'Biometric Auth'**
  String get biometricAuth;

  /// No description provided for @noOffice.
  ///
  /// In en, this message translates to:
  /// **'No Office'**
  String get noOffice;

  /// No description provided for @notAssigned.
  ///
  /// In en, this message translates to:
  /// **'Not Assigned'**
  String get notAssigned;

  /// No description provided for @deactivateUser.
  ///
  /// In en, this message translates to:
  /// **'Deactivate User'**
  String get deactivateUser;

  /// No description provided for @reactivateUser.
  ///
  /// In en, this message translates to:
  /// **'Reactivate User'**
  String get reactivateUser;

  /// No description provided for @confirmDeactivate.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to deactivate {name}?'**
  String confirmDeactivate(Object name);

  /// No description provided for @confirmReactivate.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reactivate {name}?'**
  String confirmReactivate(Object name);

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdated;

  /// No description provided for @errorUpdatingProfile.
  ///
  /// In en, this message translates to:
  /// **'Error updating profile'**
  String get errorUpdatingProfile;

  /// No description provided for @enhancedSecurity.
  ///
  /// In en, this message translates to:
  /// **'Enhanced security for login'**
  String get enhancedSecurity;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @leaves.
  ///
  /// In en, this message translates to:
  /// **'Leaves'**
  String get leaves;

  /// No description provided for @tasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasks;

  /// No description provided for @createNewTask.
  ///
  /// In en, this message translates to:
  /// **'Create New Task'**
  String get createNewTask;

  /// No description provided for @clientPhone.
  ///
  /// In en, this message translates to:
  /// **'Client Phone'**
  String get clientPhone;

  /// No description provided for @serviceType.
  ///
  /// In en, this message translates to:
  /// **'Service Type'**
  String get serviceType;

  /// No description provided for @taskCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Task Created Successfully'**
  String get taskCreatedSuccessfully;

  /// No description provided for @performance.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get performance;

  /// No description provided for @quickAccess.
  ///
  /// In en, this message translates to:
  /// **'Quick Access'**
  String get quickAccess;

  /// No description provided for @myWorks.
  ///
  /// In en, this message translates to:
  /// **'My Works'**
  String get myWorks;

  /// No description provided for @assignedTasks.
  ///
  /// In en, this message translates to:
  /// **'Assigned Tasks'**
  String get assignedTasks;

  /// No description provided for @tasksPending.
  ///
  /// In en, this message translates to:
  /// **'Tasks Pending'**
  String get tasksPending;

  /// No description provided for @viewAllWorks.
  ///
  /// In en, this message translates to:
  /// **'View All Works'**
  String get viewAllWorks;

  /// No description provided for @annualLeaveBalance.
  ///
  /// In en, this message translates to:
  /// **'Annual Leave Balance'**
  String get annualLeaveBalance;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @completedOverall.
  ///
  /// In en, this message translates to:
  /// **'Completed Overall'**
  String get completedOverall;

  /// No description provided for @avgResponseTime.
  ///
  /// In en, this message translates to:
  /// **'Avg. Response Time'**
  String get avgResponseTime;

  /// No description provided for @scanDoc.
  ///
  /// In en, this message translates to:
  /// **'Scan Doc'**
  String get scanDoc;

  /// No description provided for @dailyReport.
  ///
  /// In en, this message translates to:
  /// **'Daily Report'**
  String get dailyReport;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @languageSettingsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Language settings updated'**
  String get languageSettingsUpdated;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get days;

  /// No description provided for @checkTaskList.
  ///
  /// In en, this message translates to:
  /// **'Check your task list for details'**
  String get checkTaskList;

  /// No description provided for @scannerInitializing.
  ///
  /// In en, this message translates to:
  /// **'Scanner module initializing...'**
  String get scannerInitializing;

  /// No description provided for @workInbox.
  ///
  /// In en, this message translates to:
  /// **'Work Inbox'**
  String get workInbox;

  /// No description provided for @searchPassport.
  ///
  /// In en, this message translates to:
  /// **'Search Passport, ID, Client...'**
  String get searchPassport;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @noTasksFound.
  ///
  /// In en, this message translates to:
  /// **'No tasks found'**
  String get noTasksFound;

  /// No description provided for @noResultsFor.
  ///
  /// In en, this message translates to:
  /// **'No results for \"{query}\"'**
  String noResultsFor(Object query);

  /// No description provided for @workStatus.
  ///
  /// In en, this message translates to:
  /// **'Work Status'**
  String get workStatus;

  /// No description provided for @totalFee.
  ///
  /// In en, this message translates to:
  /// **'Total Fee'**
  String get totalFee;

  /// No description provided for @paidToday.
  ///
  /// In en, this message translates to:
  /// **'Paid Today'**
  String get paidToday;

  /// No description provided for @remainingBalance.
  ///
  /// In en, this message translates to:
  /// **'Remaining Balance'**
  String get remainingBalance;

  /// No description provided for @updateStatus.
  ///
  /// In en, this message translates to:
  /// **'Update Status'**
  String get updateStatus;

  /// No description provided for @leaveManagement.
  ///
  /// In en, this message translates to:
  /// **'Leave Management'**
  String get leaveManagement;

  /// No description provided for @leaveHistory.
  ///
  /// In en, this message translates to:
  /// **'Leave History'**
  String get leaveHistory;

  /// No description provided for @annualBal.
  ///
  /// In en, this message translates to:
  /// **'Annual Bal.'**
  String get annualBal;

  /// No description provided for @validUntil.
  ///
  /// In en, this message translates to:
  /// **'Valid until {date}'**
  String validUntil(Object date);

  /// No description provided for @applyLeave.
  ///
  /// In en, this message translates to:
  /// **'Apply Leave'**
  String get applyLeave;

  /// No description provided for @generalTask.
  ///
  /// In en, this message translates to:
  /// **'General Task'**
  String get generalTask;

  /// No description provided for @passport.
  ///
  /// In en, this message translates to:
  /// **'Passport'**
  String get passport;

  /// No description provided for @crNumber.
  ///
  /// In en, this message translates to:
  /// **'CR'**
  String get crNumber;

  /// No description provided for @medicalReport.
  ///
  /// In en, this message translates to:
  /// **'Medical Report'**
  String get medicalReport;

  /// No description provided for @documentRemoved.
  ///
  /// In en, this message translates to:
  /// **'Document Removed'**
  String get documentRemoved;

  /// No description provided for @taskUpdated.
  ///
  /// In en, this message translates to:
  /// **'Task Updated to {status}'**
  String taskUpdated(Object status);

  /// No description provided for @errorLoadingHistory.
  ///
  /// In en, this message translates to:
  /// **'Error loading history'**
  String get errorLoadingHistory;

  /// No description provided for @newDocument.
  ///
  /// In en, this message translates to:
  /// **'New Document'**
  String get newDocument;

  /// No description provided for @staffAttendance.
  ///
  /// In en, this message translates to:
  /// **'Staff Attendance'**
  String get staffAttendance;

  /// No description provided for @realTimeMonitoring.
  ///
  /// In en, this message translates to:
  /// **'REAL-TIME MONITORING'**
  String get realTimeMonitoring;

  /// No description provided for @addOfficeProgress.
  ///
  /// In en, this message translates to:
  /// **'Expand your operational presence with a new branch'**
  String get addOfficeProgress;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @officeAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Office Added Successfully'**
  String get officeAddedSuccessfully;

  /// No description provided for @workload.
  ///
  /// In en, this message translates to:
  /// **'WORKLOAD'**
  String get workload;

  /// No description provided for @regionalHub.
  ///
  /// In en, this message translates to:
  /// **'REGIONAL HUB'**
  String get regionalHub;

  /// No description provided for @branchSettings.
  ///
  /// In en, this message translates to:
  /// **'Branch Settings'**
  String get branchSettings;

  /// No description provided for @staffCommandCenter.
  ///
  /// In en, this message translates to:
  /// **'Staff Command Center'**
  String get staffCommandCenter;

  /// No description provided for @totalControlHub.
  ///
  /// In en, this message translates to:
  /// **'Total Control Hub'**
  String get totalControlHub;

  /// No description provided for @manageStaff.
  ///
  /// In en, this message translates to:
  /// **'Manage Staff'**
  String get manageStaff;

  /// No description provided for @manageAdmins.
  ///
  /// In en, this message translates to:
  /// **'Manage Admins'**
  String get manageAdmins;

  /// No description provided for @newLabel.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newLabel;

  /// No description provided for @searchStaff.
  ///
  /// In en, this message translates to:
  /// **'Search staff...'**
  String get searchStaff;

  /// No description provided for @searchAdmins.
  ///
  /// In en, this message translates to:
  /// **'Search admins...'**
  String get searchAdmins;

  /// No description provided for @noAdminsFound.
  ///
  /// In en, this message translates to:
  /// **'No admins found'**
  String get noAdminsFound;

  /// No description provided for @errorLoading.
  ///
  /// In en, this message translates to:
  /// **'Error loading'**
  String get errorLoading;

  /// No description provided for @globalAccessControl.
  ///
  /// In en, this message translates to:
  /// **'Global Access Control'**
  String get globalAccessControl;

  /// No description provided for @removeStaff.
  ///
  /// In en, this message translates to:
  /// **'Remove Staff?'**
  String get removeStaff;

  /// No description provided for @removeAdmin.
  ///
  /// In en, this message translates to:
  /// **'Remove Admin?'**
  String get removeAdmin;

  /// No description provided for @confirmRemoveAccount.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove {name}? This will deactivate their account.'**
  String confirmRemoveAccount(Object name);

  /// No description provided for @reactivate.
  ///
  /// In en, this message translates to:
  /// **'Reactivate'**
  String get reactivate;

  /// No description provided for @profileReactivated.
  ///
  /// In en, this message translates to:
  /// **'Profile reactivated'**
  String get profileReactivated;

  /// No description provided for @registerNewStaff.
  ///
  /// In en, this message translates to:
  /// **'Register New Staff'**
  String get registerNewStaff;

  /// No description provided for @registerNewAdmin.
  ///
  /// In en, this message translates to:
  /// **'Register New Admin'**
  String get registerNewAdmin;

  /// No description provided for @addTeamMemberDescription.
  ///
  /// In en, this message translates to:
  /// **'Add a new member to your operational team'**
  String get addTeamMemberDescription;

  /// No description provided for @grantAdminAccessDescription.
  ///
  /// In en, this message translates to:
  /// **'Grant administrative access to this portal'**
  String get grantAdminAccessDescription;

  /// No description provided for @initialPassword.
  ///
  /// In en, this message translates to:
  /// **'Initial Password'**
  String get initialPassword;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @phoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get phoneRequired;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'INACTIVE'**
  String get inactive;

  /// No description provided for @assignNewTask.
  ///
  /// In en, this message translates to:
  /// **'Assign New Task'**
  String get assignNewTask;

  /// No description provided for @priorityLevel.
  ///
  /// In en, this message translates to:
  /// **'Priority Level'**
  String get priorityLevel;

  /// No description provided for @highUrgent.
  ///
  /// In en, this message translates to:
  /// **'High - Urgent'**
  String get highUrgent;

  /// No description provided for @selectStaffMember.
  ///
  /// In en, this message translates to:
  /// **'Select Staff Member'**
  String get selectStaffMember;

  /// No description provided for @pleaseSelectStaff.
  ///
  /// In en, this message translates to:
  /// **'Please select a staff member'**
  String get pleaseSelectStaff;

  /// No description provided for @confirmCreateAssignment.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Create Assignment'**
  String get confirmCreateAssignment;

  /// No description provided for @taskAssignedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Task assigned successfully!'**
  String get taskAssignedSuccessfully;

  /// No description provided for @errorCreatingAssignment.
  ///
  /// In en, this message translates to:
  /// **'Error creating assignment'**
  String get errorCreatingAssignment;

  /// No description provided for @officeUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Office updated successfully'**
  String get officeUpdatedSuccessfully;

  /// No description provided for @errorUpdatingOffice.
  ///
  /// In en, this message translates to:
  /// **'Error updating office'**
  String get errorUpdatingOffice;

  /// No description provided for @errorDeletingOffice.
  ///
  /// In en, this message translates to:
  /// **'Error deleting office'**
  String get errorDeletingOffice;

  /// No description provided for @whatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsapp;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @adminRegionalCentral.
  ///
  /// In en, this message translates to:
  /// **'Admin (Regional Central)'**
  String get adminRegionalCentral;

  /// No description provided for @superAdminGlobalRoot.
  ///
  /// In en, this message translates to:
  /// **'Super Admin (Global Root)'**
  String get superAdminGlobalRoot;

  /// No description provided for @accessSecurity.
  ///
  /// In en, this message translates to:
  /// **'Access & Security'**
  String get accessSecurity;

  /// No description provided for @securityExecutiveSummary.
  ///
  /// In en, this message translates to:
  /// **'Security Executive Summary'**
  String get securityExecutiveSummary;

  /// No description provided for @activeSessions.
  ///
  /// In en, this message translates to:
  /// **'Active Sessions'**
  String get activeSessions;

  /// No description provided for @securityAlerts.
  ///
  /// In en, this message translates to:
  /// **'Security Alerts'**
  String get securityAlerts;

  /// No description provided for @roleHierarchyPermissions.
  ///
  /// In en, this message translates to:
  /// **'Role Hierarchy & Permissions'**
  String get roleHierarchyPermissions;

  /// No description provided for @superAdminAccessDesc.
  ///
  /// In en, this message translates to:
  /// **'Full system access, infrastructure control, global visibility.'**
  String get superAdminAccessDesc;

  /// No description provided for @officeAdminAccessDesc.
  ///
  /// In en, this message translates to:
  /// **'Branch management, staff oversight, regional reports.'**
  String get officeAdminAccessDesc;

  /// No description provided for @staffAccessDesc.
  ///
  /// In en, this message translates to:
  /// **'Task execution, client interaction, status updates.'**
  String get staffAccessDesc;

  /// No description provided for @auditGlobalLogs.
  ///
  /// In en, this message translates to:
  /// **'Audit Global Logs'**
  String get auditGlobalLogs;

  /// No description provided for @registeredSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'{role} registered successfully'**
  String registeredSuccessfully(Object role);

  /// No description provided for @dbSetupRequired.
  ///
  /// In en, this message translates to:
  /// **'Database setup required: Please run the provided SQL script to enable admin user creation.'**
  String get dbSetupRequired;

  /// No description provided for @registrationError.
  ///
  /// In en, this message translates to:
  /// **'Registration Error'**
  String get registrationError;

  /// No description provided for @confirmRegistration.
  ///
  /// In en, this message translates to:
  /// **'Confirm Registration'**
  String get confirmRegistration;

  /// No description provided for @officeAdmin.
  ///
  /// In en, this message translates to:
  /// **'Office Admin'**
  String get officeAdmin;

  /// No description provided for @operationalStaff.
  ///
  /// In en, this message translates to:
  /// **'Operational Staff'**
  String get operationalStaff;

  /// No description provided for @exportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get exportCsv;

  /// No description provided for @exportingCsv.
  ///
  /// In en, this message translates to:
  /// **'Exporting CSV...'**
  String get exportingCsv;

  /// No description provided for @noAuditLogs.
  ///
  /// In en, this message translates to:
  /// **'No audit logs available'**
  String get noAuditLogs;

  /// No description provided for @dangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get dangerZone;

  /// No description provided for @actionsUndoneDesc.
  ///
  /// In en, this message translates to:
  /// **'Actions here cannot be undone.'**
  String get actionsUndoneDesc;

  /// No description provided for @revokeTokens.
  ///
  /// In en, this message translates to:
  /// **'Revoke All Active Tokens'**
  String get revokeTokens;

  /// No description provided for @revokeTokensTitle.
  ///
  /// In en, this message translates to:
  /// **'Revoke All Tokens?'**
  String get revokeTokensTitle;

  /// No description provided for @revokeTokensConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will sign out all users globally. Are you sure?'**
  String get revokeTokensConfirm;

  /// No description provided for @revoke.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get revoke;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} mins ago'**
  String minsAgo(Object count);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} hours ago'**
  String hoursAgo(Object count);

  /// No description provided for @recently.
  ///
  /// In en, this message translates to:
  /// **'Recently'**
  String get recently;

  /// No description provided for @systemLogs.
  ///
  /// In en, this message translates to:
  /// **'System Logs'**
  String get systemLogs;

  /// No description provided for @generalConfiguration.
  ///
  /// In en, this message translates to:
  /// **'GENERAL CONFIGURATION'**
  String get generalConfiguration;

  /// No description provided for @notificationsAlerts.
  ///
  /// In en, this message translates to:
  /// **'NOTIFICATIONS & ALERTS'**
  String get notificationsAlerts;

  /// No description provided for @infrastructure.
  ///
  /// In en, this message translates to:
  /// **'INFRASTRUCTURE'**
  String get infrastructure;

  /// No description provided for @regionalLocalization.
  ///
  /// In en, this message translates to:
  /// **'Regional Localization'**
  String get regionalLocalization;

  /// No description provided for @regionalLocalizationDesc.
  ///
  /// In en, this message translates to:
  /// **'English, Arabic, Hijri Calendar'**
  String get regionalLocalizationDesc;

  /// No description provided for @businessEntities.
  ///
  /// In en, this message translates to:
  /// **'Business Entities'**
  String get businessEntities;

  /// No description provided for @businessEntitiesDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage registered companies'**
  String get businessEntitiesDesc;

  /// No description provided for @financialControls.
  ///
  /// In en, this message translates to:
  /// **'Financial Controls'**
  String get financialControls;

  /// No description provided for @financialControlsDesc.
  ///
  /// In en, this message translates to:
  /// **'Currency conversion, Tax config'**
  String get financialControlsDesc;

  /// No description provided for @smsGateway.
  ///
  /// In en, this message translates to:
  /// **'SMS Gateway'**
  String get smsGateway;

  /// No description provided for @smsGatewayDesc.
  ///
  /// In en, this message translates to:
  /// **'SMS gateway integration'**
  String get smsGatewayDesc;

  /// No description provided for @smtpServer.
  ///
  /// In en, this message translates to:
  /// **'SMTP Server'**
  String get smtpServer;

  /// No description provided for @smtpServerDesc.
  ///
  /// In en, this message translates to:
  /// **'Office 365, SendGrid Config'**
  String get smtpServerDesc;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// No description provided for @pushNotificationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Firebase Management'**
  String get pushNotificationsDesc;

  /// No description provided for @backupSync.
  ///
  /// In en, this message translates to:
  /// **'Backup & Sync'**
  String get backupSync;

  /// No description provided for @backupSyncDesc.
  ///
  /// In en, this message translates to:
  /// **'Daily auto-backup to AWS/Cloud'**
  String get backupSyncDesc;

  /// No description provided for @apiIntegration.
  ///
  /// In en, this message translates to:
  /// **'API Integration'**
  String get apiIntegration;

  /// No description provided for @apiIntegrationDesc.
  ///
  /// In en, this message translates to:
  /// **'External API integrations'**
  String get apiIntegrationDesc;

  /// No description provided for @versionControl.
  ///
  /// In en, this message translates to:
  /// **'Version Control'**
  String get versionControl;

  /// No description provided for @versionControlDesc.
  ///
  /// In en, this message translates to:
  /// **'Current System v1.4.2 Build'**
  String get versionControlDesc;

  /// No description provided for @systemHealth.
  ///
  /// In en, this message translates to:
  /// **'System Health'**
  String get systemHealth;

  /// No description provided for @allServicesOperational.
  ///
  /// In en, this message translates to:
  /// **'All services operational'**
  String get allServicesOperational;

  /// No description provided for @optimal.
  ///
  /// In en, this message translates to:
  /// **'Optimal'**
  String get optimal;

  /// No description provided for @up.
  ///
  /// In en, this message translates to:
  /// **'Up'**
  String get up;

  /// No description provided for @storage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storage;

  /// No description provided for @cpuLoad.
  ///
  /// In en, this message translates to:
  /// **'CPU Load'**
  String get cpuLoad;

  /// No description provided for @apiLatency.
  ///
  /// In en, this message translates to:
  /// **'API Latency'**
  String get apiLatency;

  /// No description provided for @noResultsFoundSearch.
  ///
  /// In en, this message translates to:
  /// **'No results found for your search'**
  String get noResultsFoundSearch;

  /// No description provided for @searchSystemSettings.
  ///
  /// In en, this message translates to:
  /// **'Search system settings...'**
  String get searchSystemSettings;

  /// No description provided for @systemHealthPerformance.
  ///
  /// In en, this message translates to:
  /// **'System Health & Performance'**
  String get systemHealthPerformance;

  /// No description provided for @realTimeMonitoringGlobal.
  ///
  /// In en, this message translates to:
  /// **'Real-time monitoring of all global services'**
  String get realTimeMonitoringGlobal;

  /// No description provided for @configurationDetails.
  ///
  /// In en, this message translates to:
  /// **'CONFIGURATION DETAILS'**
  String get configurationDetails;

  /// No description provided for @operationalLogs.
  ///
  /// In en, this message translates to:
  /// **'OPERATIONAL LOGS'**
  String get operationalLogs;

  /// No description provided for @serviceName.
  ///
  /// In en, this message translates to:
  /// **'Service Name'**
  String get serviceName;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last Updated'**
  String get lastUpdated;

  /// No description provided for @modifiedBy.
  ///
  /// In en, this message translates to:
  /// **'Modified By'**
  String get modifiedBy;

  /// No description provided for @saveVerifyConfig.
  ///
  /// In en, this message translates to:
  /// **'Save & Verify Configuration'**
  String get saveVerifyConfig;

  /// No description provided for @standardConfigDesc.
  ///
  /// In en, this message translates to:
  /// **'Standard configuration for {title} across the branch network.'**
  String standardConfigDesc(Object title);

  /// No description provided for @configUpdatedNodes.
  ///
  /// In en, this message translates to:
  /// **'Configuration for {title} updated across all nodes.'**
  String configUpdatedNodes(Object title);

  /// No description provided for @logConfigSynced.
  ///
  /// In en, this message translates to:
  /// **'Configuration synced with master database'**
  String get logConfigSynced;

  /// No description provided for @logManualCheck.
  ///
  /// In en, this message translates to:
  /// **'Manual check performed by System Engine'**
  String get logManualCheck;

  /// No description provided for @logSecurityRenewed.
  ///
  /// In en, this message translates to:
  /// **'Security certificate auto-renewed'**
  String get logSecurityRenewed;

  /// No description provided for @agents.
  ///
  /// In en, this message translates to:
  /// **'Agents'**
  String get agents;

  /// No description provided for @searchAgents.
  ///
  /// In en, this message translates to:
  /// **'Search agents...'**
  String get searchAgents;

  /// No description provided for @noAgentsFound.
  ///
  /// In en, this message translates to:
  /// **'No agents found'**
  String get noAgentsFound;

  /// No description provided for @agentDetails.
  ///
  /// In en, this message translates to:
  /// **'Agent Details'**
  String get agentDetails;

  /// No description provided for @agentFee.
  ///
  /// In en, this message translates to:
  /// **'Agent Fee'**
  String get agentFee;

  /// No description provided for @transferToAgent.
  ///
  /// In en, this message translates to:
  /// **'Transfer to Agent'**
  String get transferToAgent;

  /// No description provided for @mentionAgent.
  ///
  /// In en, this message translates to:
  /// **'Mention Agent'**
  String get mentionAgent;

  /// No description provided for @agentStatus.
  ///
  /// In en, this message translates to:
  /// **'Agent Status'**
  String get agentStatus;

  /// No description provided for @payAgent.
  ///
  /// In en, this message translates to:
  /// **'Pay Agent'**
  String get payAgent;

  /// No description provided for @agentWork.
  ///
  /// In en, this message translates to:
  /// **'Agent Work'**
  String get agentWork;

  /// No description provided for @allAgents.
  ///
  /// In en, this message translates to:
  /// **'All Agents'**
  String get allAgents;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
