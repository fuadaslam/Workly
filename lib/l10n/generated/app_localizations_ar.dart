// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'ووركلي';

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

  @override
  String get clientDetails => 'تفاصيل العميل';

  @override
  String get contactInfo => 'معلومات التواصل';

  @override
  String get clientName => 'اسم العميل';

  @override
  String get phoneNumber => 'رقم الهاتف';

  @override
  String get projectHistory => 'سجل المشاريع';

  @override
  String get noWorkHistory => 'لم يتم العثور على سجل عمل';

  @override
  String get taskDetails => 'تفاصيل المهمة';

  @override
  String get generalInfo => 'معلومات عامة';

  @override
  String get documents => 'المستندات';

  @override
  String get timeline => 'الخط الزمني';

  @override
  String get dailyUpdateNotes => 'تحديث يومي';

  @override
  String get saveChanges => 'حفظ التغييرات';

  @override
  String get officeDetails => 'تفاصيل المكتب';

  @override
  String get officeName => 'اسم المكتب';

  @override
  String get location => 'الموقع';

  @override
  String get managerName => 'اسم المدير';

  @override
  String get managerPhone => 'هاتف المدير';

  @override
  String get officeMobile => 'جوال المكتب';

  @override
  String get officeLandline => 'هاتف المكتب';

  @override
  String get revenue => 'الإيرادات';

  @override
  String get staffCount => 'عدد الموظفين';

  @override
  String get workloadCapacity => 'سعة عبء العمل';

  @override
  String get assignedStaff => 'الموظفون المعينون';

  @override
  String get officeWorkHistory => 'تاريخ عمل المكتب';

  @override
  String get officeClients => 'عملاء المكتب';

  @override
  String get deleteOffice => 'حذف المكتب';

  @override
  String get editOffice => 'تعديل المكتب';

  @override
  String get confirmDelete => 'هل أنت متأكد أنك تريد حذف هذا؟';

  @override
  String get status => 'الحالة';

  @override
  String get priority => 'الأولوية';

  @override
  String get pending => 'قيد الانتظار';

  @override
  String get inProgress => 'قيد التنفيذ';

  @override
  String get completed => 'مكتمل';

  @override
  String get high => 'عالي';

  @override
  String get medium => 'متوسط';

  @override
  String get low => 'منخفض';

  @override
  String get caseId => 'رقم القضية';

  @override
  String get today => 'اليوم';

  @override
  String get yesterday => 'أمس';

  @override
  String get uploadNew => 'رفع ملف';

  @override
  String get noHistoryFound => 'لا يوجد سجل مسجل بعد';

  @override
  String get notesHint => 'أدخل تحديثات الحالة اليومية هنا...';

  @override
  String get manageStaffComingSoon => 'إدارة تعيين الموظفين قريباً';

  @override
  String get noStaffAssigned => 'لم يتم تعيين موظفين';

  @override
  String get noClientsFound => 'لم يتم العثور على عملاء';

  @override
  String get noPhoneNumber => 'لا يوجد رقم هاتف';

  @override
  String get generalService => 'خدمة عامة';

  @override
  String get assign => 'تعيين';

  @override
  String get executiveOverview => 'نظرة عامة تنفيذية';

  @override
  String get vision2030Portal => 'منصة ووركلي';

  @override
  String get monthlyRevenue => 'الإيرادات الشهرية';

  @override
  String get vsLastMonth => 'مقابل الشهر الماضي';

  @override
  String get activeCases => 'الحالات النشطة';

  @override
  String get pendingApprovals => 'الموافقات المعلقة';

  @override
  String get operationalTrends => 'الاتجاهات التشغيلية';

  @override
  String get viewDetailed => 'عرض التفاصيل';

  @override
  String get superAdmin => 'مشرف عام';

  @override
  String get regionalOffices => 'المكاتب الإقليمية';

  @override
  String get branchManagement => 'إدارة الفروع';

  @override
  String get ksaNetwork => 'الشبكة';

  @override
  String get activeBranches => 'الفروع النشطة';

  @override
  String get addNewOffice => 'إضافة مكتب جديد';

  @override
  String get searchOffices => 'البحث في المكاتب...';

  @override
  String get networkPerformance => 'أداء الشبكة';

  @override
  String get totalRevenue => 'إجمالي الإيرادات';

  @override
  String get avgWorkloadCapacity => 'متوسط قدرة العمل';

  @override
  String get filters => 'تصفية';

  @override
  String get selectLanguage => 'اختر اللغة';

  @override
  String get systemAuthority => 'سلطة النظام';

  @override
  String get assignWork => 'تعيين عمل';

  @override
  String get errorLoadingStaff => 'خطأ في تحميل الموظفين';

  @override
  String get staffDetails => 'تفاصيل الموظف';

  @override
  String get adminDetails => 'تفاصيل المشرف';

  @override
  String get professionalProfile => 'الملف المهني';

  @override
  String get performanceMetrics => 'مقاييس الأداء';

  @override
  String get accessPermissions => 'الوصول والصلاحيات';

  @override
  String get deactivateAccount => 'تعطيل الحساب';

  @override
  String get reactivateAccount => 'إعادة تفعيل الحساب';

  @override
  String get portalRole => 'دور البوابة';

  @override
  String get joinedDate => 'تاريخ الانضمام';

  @override
  String get tasksDone => 'المهام المنجزة';

  @override
  String get efficiency => 'الكفاءة';

  @override
  String get assignedOffice => 'المكتب المعين';

  @override
  String get biometricAuth => 'المصادقة البيومترية';

  @override
  String get noOffice => 'لا يوجد مكتب';

  @override
  String get notAssigned => 'غير معين';

  @override
  String get deactivateUser => 'تعطيل المستخدم';

  @override
  String get reactivateUser => 'إعادة تفعيل المستخدم';

  @override
  String confirmDeactivate(Object name) {
    return 'هل أنت متأكد أنك تريد تعطيل $name؟';
  }

  @override
  String confirmReactivate(Object name) {
    return 'هل أنت متأكد أنك تريد إعادة تفعيل $name؟';
  }

  @override
  String get profileUpdated => 'تم تحديث الملف الشخصي بنجاح';

  @override
  String get errorUpdatingProfile => 'خطأ في تحديث الملف الشخصي';

  @override
  String get enhancedSecurity => 'أمان محسّن لتسجيل الدخول';

  @override
  String get home => 'الرئيسية';

  @override
  String get leaves => 'الإجازات';

  @override
  String get tasks => 'المهام';

  @override
  String get createNewTask => 'إنشاء مهمة جديدة';

  @override
  String get clientPhone => 'هاتف العميل';

  @override
  String get serviceType => 'نوع الخدمة';

  @override
  String get taskCreatedSuccessfully => 'تم إنشاء المهمة بنجاح';

  @override
  String get performance => 'الأداء';

  @override
  String get quickAccess => 'وصول سريع';

  @override
  String get myWorks => 'أعمالي';

  @override
  String get assignedTasks => 'المهام المسندة';

  @override
  String get tasksPending => 'مهام معلقة';

  @override
  String get viewAllWorks => 'عرض جميع الأعمال';

  @override
  String get annualLeaveBalance => 'رصيد الإجازات السنوية';

  @override
  String get apply => 'تقديم';

  @override
  String get completedOverall => 'مكتمل إجمالاً';

  @override
  String get avgResponseTime => 'متوسط وقت الاستجابة';

  @override
  String get scanDoc => 'مسح مستند';

  @override
  String get dailyReport => 'تقرير يومي';

  @override
  String get support => 'الدعم';

  @override
  String get languageSettingsUpdated => 'تم تحديث إعدادات اللغة';

  @override
  String get days => 'أيام';

  @override
  String get checkTaskList => 'تحقق من قائمة المهام للحصول على التفاصيل';

  @override
  String get scannerInitializing => 'جاري تهيئة وحدة الماسح الضوئي...';

  @override
  String get workInbox => 'صندوق المهام';

  @override
  String get searchPassport => 'البحث عن جواز، هوية، عميل...';

  @override
  String get all => 'الكل';

  @override
  String get noTasksFound => 'لم يتم العثور على مهام';

  @override
  String noResultsFor(Object query) {
    return 'لا توجد نتائج لـ \"$query\"';
  }

  @override
  String get workStatus => 'حالة العمل';

  @override
  String get totalFee => 'إجمالي الرسوم';

  @override
  String get paidToday => 'المدفوع اليوم';

  @override
  String get remainingBalance => 'الرصيد المتبقي';

  @override
  String get updateStatus => 'تحديث الحالة';

  @override
  String get leaveManagement => 'إدارة الإجازات';

  @override
  String get leaveHistory => 'أرشيف الإجازات';

  @override
  String get annualBal => 'رصيد سنوي';

  @override
  String validUntil(Object date) {
    return 'صالح حتى $date';
  }

  @override
  String get applyLeave => 'تقديم إجازة';

  @override
  String get generalTask => 'مهمة عامة';

  @override
  String get passport => 'جواز سفر';

  @override
  String get crNumber => 'سجل تجاري';

  @override
  String get medicalReport => 'تقرير طبي';

  @override
  String get documentRemoved => 'تم حذف المستند';

  @override
  String taskUpdated(Object status) {
    return 'تم تحديث المهمة إلى $status';
  }

  @override
  String get errorLoadingHistory => 'خطأ في تحميل السجل';

  @override
  String get newDocument => 'مستند جديد';

  @override
  String get staffAttendance => 'حضور الموظفين';

  @override
  String get realTimeMonitoring => 'مراقبة فورية';

  @override
  String get addOfficeProgress => 'قم بتوسيع تواجدك التشغيلي مع فرع جديد';

  @override
  String get required => 'مطلوب';

  @override
  String get officeAddedSuccessfully => 'تم إضافة المكتب بنجاح';

  @override
  String get workload => 'عبء العمل';

  @override
  String get regionalHub => 'مركز إقليمي';

  @override
  String get branchSettings => 'إعدادات الفرع';

  @override
  String get staffCommandCenter => 'مركز قيادة الموظفين';

  @override
  String get totalControlHub => 'مركز التحكم الشامل';

  @override
  String get manageStaff => 'إدارة الموظفين';

  @override
  String get manageAdmins => 'إدارة المسؤولين';

  @override
  String get newLabel => 'جديد';

  @override
  String get searchStaff => 'البحث عن موظفين...';

  @override
  String get searchAdmins => 'البحث عن مسؤولين...';

  @override
  String get noAdminsFound => 'لم يتم العثور على مسؤولين';

  @override
  String get errorLoading => 'خطأ في التحميل';

  @override
  String get globalAccessControl => 'التحكم الشامل في الوصول';

  @override
  String get removeStaff => 'حذف الموظف؟';

  @override
  String get removeAdmin => 'حذ المسؤول؟';

  @override
  String confirmRemoveAccount(Object name) {
    return 'هل أنت متأكد أنك تريد حذف $name؟ سيؤدي ذلك إلى تعطيل حسابهم.';
  }

  @override
  String get reactivate => 'إعادة تفعيل';

  @override
  String get profileReactivated => 'تم إعادة تفعيل الملف الشخصي';

  @override
  String get registerNewStaff => 'تسجيل موظف جديد';

  @override
  String get registerNewAdmin => 'تسجيل مسؤول جديد';

  @override
  String get addTeamMemberDescription => 'إضافة عضو جديد إلى فريقك العملي';

  @override
  String get grantAdminAccessDescription => 'منح وصول إداري لهذه البوابة';

  @override
  String get initialPassword => 'كلمة المرور الأولية';

  @override
  String get emailAddress => 'البريد الإلكتروني';

  @override
  String get nameRequired => 'الاسم مطلوب';

  @override
  String get emailRequired => 'البريد الإلكتروني مطلوب';

  @override
  String get passwordRequired => 'كلمة المرور مطلوبة';

  @override
  String get phoneRequired => 'رقم الهاتف مطلوب';

  @override
  String get active => 'نشط';

  @override
  String get inactive => 'غير نشط';

  @override
  String get assignNewTask => 'تعيين مهمة جديدة';

  @override
  String get priorityLevel => 'مستوى الأولوية';

  @override
  String get highUrgent => 'عالي - عاجل';

  @override
  String get selectStaffMember => 'اختر موظفاً';

  @override
  String get pleaseSelectStaff => 'يرجى اختيار موظف';

  @override
  String get confirmCreateAssignment => 'تأكيد وإنشاء التعيين';

  @override
  String get taskAssignedSuccessfully => 'تم تعيين المهمة بنجاح!';

  @override
  String get errorCreatingAssignment => 'خطأ في إنشاء التعيين';

  @override
  String get officeUpdatedSuccessfully => 'تم تحديث المكتب بنجاح';

  @override
  String get errorUpdatingOffice => 'خطأ في تحديث المكتب';

  @override
  String get errorDeletingOffice => 'خطأ في حذف المكتب';

  @override
  String get whatsapp => 'واتساب';

  @override
  String get call => 'اتصال';

  @override
  String get adminRegionalCentral => 'مشرف (إقليمي مركزي)';

  @override
  String get superAdminGlobalRoot => 'مشرف عام (شامل)';

  @override
  String get accessSecurity => 'الوصول والأمان';

  @override
  String get securityExecutiveSummary => 'ملخص تنفيذي للأمان';

  @override
  String get activeSessions => 'الجلسات النشطة';

  @override
  String get securityAlerts => 'تنبيهات أمنية';

  @override
  String get roleHierarchyPermissions => 'تسلسل الأدوار والصلاحيات';

  @override
  String get superAdminAccessDesc =>
      'وصول كامل للنظام، تحكم في البنية التحتية، رؤية شاملة.';

  @override
  String get officeAdminAccessDesc =>
      'إدارة الفروع، الإشراف على الموظفين، تقارير إقليمية.';

  @override
  String get staffAccessDesc =>
      'تنفيذ المهام، التفاعل مع العملاء، تحديثات الحالة.';

  @override
  String get auditGlobalLogs => 'تدقيق السجلات العالمية';

  @override
  String registeredSuccessfully(Object role) {
    return 'تم تسجيل $role بنجاح';
  }

  @override
  String get dbSetupRequired =>
      'تكوين قاعدة البيانات مطلوب: يرجى تشغيل نص SQL الموفر لتمكين إنشاء مستخدم مسؤول.';

  @override
  String get registrationError => 'خطأ في التسجيل';

  @override
  String get confirmRegistration => 'تأكيد التسجيل';

  @override
  String get officeAdmin => 'مسؤول مكتب';

  @override
  String get operationalStaff => 'موظف عمليات';

  @override
  String get exportCsv => 'تصدير CSV';

  @override
  String get exportingCsv => 'جاري تصدير CSV...';

  @override
  String get noAuditLogs => 'لا توجد سجلات تدقيق متاحة';

  @override
  String get dangerZone => 'منطقة الخطر';

  @override
  String get actionsUndoneDesc => 'الإجراءات هنا لا يمكن التراجع عنها.';

  @override
  String get revokeTokens => 'إبطال جميع الرموز النشطة';

  @override
  String get revokeTokensTitle => 'إبطال جميع الرموز؟';

  @override
  String get revokeTokensConfirm =>
      'سيؤدي هذا إلى تسجيل خروج جميع المستخدمين عالمياً. هل أنت متأكد؟';

  @override
  String get revoke => 'إبطال';

  @override
  String get justNow => 'الآن';

  @override
  String minsAgo(Object count) {
    return 'منذ $count دقائق';
  }

  @override
  String hoursAgo(Object count) {
    return 'منذ $count ساعات';
  }

  @override
  String get recently => 'مؤخراً';

  @override
  String get systemLogs => 'سجلات النظام';

  @override
  String get generalConfiguration => 'الإعدادات العامة';

  @override
  String get notificationsAlerts => 'التنبيهات والإشعارات';

  @override
  String get infrastructure => 'البنية التحتية';

  @override
  String get regionalLocalization => 'التوطين الإقليمي';

  @override
  String get regionalLocalizationDesc => 'الإنجليزية، العربية، التقويم الهجري';

  @override
  String get businessEntities => 'الكيانات التجارية';

  @override
  String get businessEntitiesDesc => 'إدارة الشركات المسجلة';

  @override
  String get financialControls => 'الضوابط المالية';

  @override
  String get financialControlsDesc => 'تحويل العملة، تكوين الضريبة';

  @override
  String get smsGateway => 'بوابة الرسائل القصيرة';

  @override
  String get smsGatewayDesc => 'تكامل بوابة الرسائل القصيرة';

  @override
  String get smtpServer => 'خادم SMTP';

  @override
  String get smtpServerDesc => 'تكوين Office 365, SendGrid';

  @override
  String get pushNotifications => 'إشعارات الدفع';

  @override
  String get pushNotificationsDesc => 'إدارة Firebase';

  @override
  String get backupSync => 'النسخ الاحتياطي والمزامنة';

  @override
  String get backupSyncDesc => 'نسخ احتياطي تلقائي يومي للسحابة';

  @override
  String get apiIntegration => 'تكامل واجهة برمجة التطبيقات';

  @override
  String get apiIntegrationDesc => 'تكاملات واجهات الربط الخارجية';

  @override
  String get versionControl => 'التحكم في الإصدار';

  @override
  String get versionControlDesc => 'إصدار النظام الحالي v1.4.2';

  @override
  String get systemHealth => 'صحة النظام';

  @override
  String get allServicesOperational => 'جميع الخدمات تعمل بشكل صحيح';

  @override
  String get optimal => 'مثالي';

  @override
  String get up => 'يعمل';

  @override
  String get storage => 'التخزين';

  @override
  String get cpuLoad => 'حمل المعالج';

  @override
  String get apiLatency => 'زمن وصول API';

  @override
  String get noResultsFoundSearch => 'لم يتم العثور على نتائج لبحثك';

  @override
  String get searchSystemSettings => 'البحث في إعدادات النظام...';

  @override
  String get systemHealthPerformance => 'صحة الأداء والنظام';

  @override
  String get realTimeMonitoringGlobal => 'مراقبة فورية لجميع الخدمات العالمية';

  @override
  String get configurationDetails => 'تفاصيل التكوين';

  @override
  String get operationalLogs => 'سجلات التشغيل';

  @override
  String get serviceName => 'اسم الخدمة';

  @override
  String get description => 'الوصف';

  @override
  String get lastUpdated => 'آخر تحديث';

  @override
  String get modifiedBy => 'تم التعديل بواسطة';

  @override
  String get saveVerifyConfig => 'حفظ والتحقق من التكوين';

  @override
  String standardConfigDesc(Object title) {
    return 'التكوين القياسي لـ $title عبر شبكة الفروع.';
  }

  @override
  String configUpdatedNodes(Object title) {
    return 'تم تحديث التكوين لـ $title عبر جميع النقاط.';
  }

  @override
  String get logConfigSynced => 'تم مزامنة التكوين مع قاعدة البيانات الرئيسية';

  @override
  String get logManualCheck => 'تم إجراء فحص يدوي بواسطة محرك النظام';

  @override
  String get logSecurityRenewed => 'تم تجديد شهادة الأمان تلقائياً';

  @override
  String get agents => 'الوكلاء';

  @override
  String get searchAgents => 'البحث عن وكلاء...';

  @override
  String get noAgentsFound => 'لم يتم العثور على وكلاء';

  @override
  String get agentDetails => 'تفاصيل الوكيل';

  @override
  String get agentFee => 'رسوم الوكيل';

  @override
  String get transferToAgent => 'تحويل إلى وكيل';

  @override
  String get mentionAgent => 'الإشارة إلى الوكيل';

  @override
  String get agentStatus => 'حالة الوكيل';

  @override
  String get payAgent => 'دفع للوكيل';

  @override
  String get agentWork => 'عمل الوكيل';

  @override
  String get allAgents => 'جميع الوكلاء';
}
