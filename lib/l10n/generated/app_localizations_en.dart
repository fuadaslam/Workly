// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Saudi Service Manager';

  @override
  String get login => 'Login';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get signIn => 'Sign In';

  @override
  String get signOut => 'Sign Out';

  @override
  String get signUp => 'Sign Up';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get profile => 'Profile';

  @override
  String get attendance => 'Attendance';

  @override
  String get services => 'Services';

  @override
  String get staff => 'Staff';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get systemCheck => 'System Check';

  @override
  String get connectedToSupabase => 'Connected to Supabase';

  @override
  String get connectionFailed => 'Connection Failed';

  @override
  String get proceedToApp => 'Proceed to App';

  @override
  String get configurationRequired => 'Configuration Required';

  @override
  String get configurationMessage =>
      'Please update lib/core/constants/supabase_env.dart with your Supabase URL and Anon Key.';

  @override
  String get createAccount => 'Create Account';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get fullName => 'Full Name';

  @override
  String get alreadyHaveAccount => 'Already have an account? Sign In';

  @override
  String get dontHaveAccount => 'Don\'t have an account? Sign Up';

  @override
  String get signUpSuccessful =>
      'Sign up successful! Please check your email for confirmation.';

  @override
  String get profileNotFound => 'Profile not found. Please contact support.';

  @override
  String get contactSupport => 'Contact Support';
}
