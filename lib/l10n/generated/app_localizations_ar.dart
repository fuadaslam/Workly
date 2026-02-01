// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'مدير الخدمة السعودي';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get signUp => 'إنشاء حساب';

  @override
  String get dashboard => 'لوحة القيادة';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get attendance => 'الحضور';

  @override
  String get services => 'الخدمات';

  @override
  String get staff => 'الموظفون';

  @override
  String get loading => 'جاري التحميل...';

  @override
  String get error => 'خطأ';

  @override
  String get success => 'نجاح';

  @override
  String get cancel => 'إلغاء';

  @override
  String get save => 'حفظ';

  @override
  String get edit => 'تعديل';

  @override
  String get delete => 'حذف';

  @override
  String get systemCheck => 'فحص النظام';

  @override
  String get connectedToSupabase => 'متصل بـ Supabase';

  @override
  String get connectionFailed => 'فشل الاتصال';

  @override
  String get proceedToApp => 'الانتقال إلى التطبيق';

  @override
  String get configurationRequired => 'التكوين مطلوب';

  @override
  String get configurationMessage =>
      'يرجى تحديث lib/core/constants/supabase_env.dart باستخدام عنوان URL ومفتاح Anon الخاص بـ Supabase.';

  @override
  String get createAccount => 'إنشاء حساب جديد';

  @override
  String get welcomeBack => 'مرحباً بك مجدداً';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get alreadyHaveAccount => 'لديك حساب بالفعل؟ سجل دخولك';

  @override
  String get dontHaveAccount => 'ليس لديك حساب؟ أنشئ حساباً';

  @override
  String get signUpSuccessful =>
      'تم إنشاء الحساب بنجاح! يرجى التحقق من بريدك الإلكتروني للتأكيد.';

  @override
  String get profileNotFound =>
      'لم يتم العثور على الملف الشخصي. يرجى الاتصال بالدعم.';

  @override
  String get contactSupport => 'اتصل بالدعم';
}
