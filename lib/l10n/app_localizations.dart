import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

// ─── Language Service ─────────────────────────────────────────────────────────
class LanguageService {
  static const String _settingsBox = 'settings';
  static const String _languageKey = 'app_language';

  Box get _box => Hive.box(_settingsBox);

  String get language => _box.get(_languageKey, defaultValue: 'fr') as String;

  Future<void> saveLanguage(String lang) async {
    await _box.put(_languageKey, lang);
  }

  bool get isArabic => language == 'ar';
  TextDirection get textDirection => isArabic ? TextDirection.rtl : TextDirection.ltr;
}

// ─── App Localizations ────────────────────────────────────────────────────────
class AppLocalizations {
  final String lang;
  const AppLocalizations(this.lang);

  bool get isAr => lang == 'ar';
  TextDirection get textDirection => isAr ? TextDirection.rtl : TextDirection.ltr;

  // ── App General ──────────────────────────────────────────────────────────────
  String get appName => isAr ? 'إتود - إدارة الحصص' : 'Étude - Gestion des Séances';
  String get welcome => isAr ? 'مرحباً بكم في إتود' : 'Bienvenue dans Étude';
  String get chooseProfile => isAr
      ? 'اختر ملفك الشخصي لتخصيص تجربتك.\nهذا الاختيار نهائي.'
      : 'Choisissez votre profil pour personnaliser votre expérience.\nCe choix est définitif.';
  String get chooseLanguage => isAr ? 'اختر اللغة' : 'Choisissez la langue';
  String get languageFr => 'Français';
  String get languageAr => 'العربية';
  String get continueBtn => isAr ? 'متابعة' : 'Continuer';
  String get save => isAr ? 'حفظ' : 'Enregistrer';
  String get cancel => isAr ? 'إلغاء' : 'Annuler';
  String get confirm => isAr ? 'تأكيد' : 'Confirmer';
  String get print => isAr ? 'طباعة' : 'Imprimer';
  String get close => isAr ? 'إغلاق' : 'Fermer';
  String get delete => isAr ? 'حذف' : 'Supprimer';
  String get edit => isAr ? 'تعديل' : 'Modifier';
  String get add => isAr ? 'إضافة' : 'Ajouter';
  String get search => isAr ? 'بحث...' : 'Rechercher...';
  String get loading => isAr ? 'جاري التحميل...' : 'Chargement...';
  String get noData => isAr ? 'لا توجد بيانات' : 'Aucune donnée';

  // ── Modes ───────────────────────────────────────────────────────────────────
  String get modeTeacher => isAr ? 'أستاذ مستقل' : 'Enseignant Indépendant';
  String get modeTeacherDesc => isAr
      ? 'أدر مجموعاتك وطلابك ومدفوعاتك بسهولة للاستخدام الشخصي.'
      : 'Gérez vos groupes, élèves et paiements simplement pour votre usage personnel.';
  String get modeCenter => isAr ? 'مركز دراسي' : 'Centre d\'Études';
  String get modeCenterDesc => isAr
      ? 'أدر عدة أساتذة وقاعات وعقوداً وأنشئ تقارير مالية مفصلة.'
      : 'Gérez plusieurs enseignants, salles, contrats et générez des rapports financiers détaillés.';

  // ── Nav / Sections ──────────────────────────────────────────────────────────
  String get dashboard => isAr ? 'لوحة القيادة' : 'Tableau de Bord';
  String get groups => isAr ? 'المجموعات' : 'Groupes';
  String get students => isAr ? 'الطلاب' : 'Élèves';
  String get payments => isAr ? 'المدفوعات' : 'Paiements';
  String get settings => isAr ? 'الإعدادات' : 'Paramètres';
  String get reports => isAr ? 'التقارير' : 'Rapports';
  String get teachers => isAr ? 'الأساتذة' : 'Enseignants';
  String get attendance => isAr ? 'الحضور' : 'Présence';

  // ── Student ─────────────────────────────────────────────────────────────────
  String get student => isAr ? 'الطالب' : 'Élève';
  String get studentName => isAr ? 'الاسم الكامل' : 'Nom & Prénom';
  String get studentPhone => isAr ? 'الهاتف' : 'Téléphone';
  String get studentGroup => isAr ? 'المجموعة' : 'Groupe';
  String get studentStatus => isAr ? 'الحالة' : 'Statut';
  String get sessionsCount => isAr ? 'عدد الحصص' : 'Séances';
  String get lastPayment => isAr ? 'آخر دفع' : 'Dernier paiement';
  String get totalPaid => isAr ? 'المجموع المدفوع' : 'Total payé';
  String get pricePerCycle => isAr ? 'السعر/الدورة' : 'Prix/Cycle';
  String get upToDate => isAr ? 'بالتحديث' : 'À jour';
  String get overdue => isAr ? 'متأخر' : 'En retard';
  String get critical => isAr ? 'حرج' : 'Critique';
  String get sessionsSincePayment => isAr ? 'حصص منذ آخر دفع' : 'Séances depuis paiement';
  String get sessionsRemaining => isAr ? 'حصص متبقية' : 'Séances restantes';
  String get enrollmentFee => isAr ? 'رسوم التسجيل' : 'Frais d\'inscription';

  // ── Group ───────────────────────────────────────────────────────────────────
  String get group => isAr ? 'المجموعة' : 'Groupe';
  String get groupName => isAr ? 'اسم المجموعة' : 'Nom du groupe';
  String get subject => isAr ? 'المادة' : 'Matière';
  String get schedule => isAr ? 'الجدول الزمني' : 'Horaire';
  String get room => isAr ? 'القاعة' : 'Salle';
  String get teacher => isAr ? 'الأستاذ' : 'Enseignant';
  String get totalStudents => isAr ? 'إجمالي الطلاب' : 'Total élèves';
  String get totalRevenue => isAr ? 'إجمالي الإيرادات' : 'Revenu total';

  // ── Teacher Contract ─────────────────────────────────────────────────────────
  String get contractSalarie => isAr ? 'مرتب ثابت' : 'Salarié (fixe)';
  String get contractLocateur => isAr ? 'مستأجر قاعة' : 'Locateur de salle';
  String get contractPourcentage => isAr ? 'بالنسبة المئوية' : 'Au pourcentage';
  String get fixedSalary => isAr ? 'الراتب الثابت' : 'Salaire fixe';
  String get rentPerSession => isAr ? 'إيجار/حصة' : 'Loyer/séance';
  String get percentage => isAr ? 'النسبة المئوية' : 'Pourcentage';
  String get teacherShare => isAr ? 'حصة الأستاذ' : 'Part enseignant';
  String get centerShare => isAr ? 'حصة المركز' : 'Part centre';
  String get grossRevenue => isAr ? 'الإيراد الإجمالي' : 'Revenu brut';
  String get sessionNumber => isAr ? 'عدد الحصص' : 'Nb séances';

  // ── PDF Labels ───────────────────────────────────────────────────────────────
  String get paymentReceipt => isAr ? 'وصل دفع' : 'Reçu de Paiement';
  String get studentReport => isAr ? 'حالة الطالب' : 'État de l\'Élève';
  String get groupReport => isAr ? 'حالة المجموعة' : 'État du Groupe';
  String get teacherReport => isAr ? 'حالة الأستاذ' : 'État de l\'Enseignant';
  String get teacherPaymentReceipt => isAr ? 'وصل تسوية الأستاذ' : 'Reçu de Règlement Enseignant';
  String get studentInfo => isAr ? 'معلومات الطالب' : 'Informations Élève';
  String get paymentDetails => isAr ? 'تفاصيل الدفع' : 'Détails du Paiement';
  String get amountPaid => isAr ? 'المبلغ المدفوع' : 'MONTANT PAYÉ';
  String get month => isAr ? 'الشهر' : 'Mois';
  String get paymentDate => isAr ? 'تاريخ الدفع' : 'Date de paiement';
  String get sessionsCovered => isAr ? 'الحصص المغطاة' : 'Séances couvertes';
  String get receiptNo => isAr ? 'رقم الوصل' : 'N°';
  String get date => isAr ? 'التاريخ' : 'Date';
  String get studentSignature => isAr ? 'توقيع الطالب / ولي الأمر' : 'Signature Élève / Parent';
  String get centerStamp => isAr ? 'ختم المركز' : 'Cachet du Centre';
  String get teacherSignature => isAr ? 'توقيع الأستاذ' : 'Signature Enseignant';
  String get receiptFooter => isAr
      ? 'هذا الوصل يثبت الدفع المُنجز — تطبيق إتود'
      : 'Ce reçu atteste du paiement effectué — Étude App';
  String get presenceHistory => isAr ? 'سجل الحضور' : 'Historique de Présence';
  String get paymentHistory => isAr ? 'سجل المدفوعات' : 'Historique des Paiements';
  String get currentStatus => isAr ? 'الوضع الحالي' : 'Statut Actuel';
  String get groupStudentsTable => isAr ? 'قائمة الطلاب' : 'Liste des Élèves';
  String get groupStats => isAr ? 'إحصائيات المجموعة' : 'Statistiques du Groupe';
  String get teacherGroupsTable => isAr ? 'مجموعات الأستاذ' : 'Groupes de l\'Enseignant';
  String get financialSummary => isAr ? 'ملخص مالي' : 'Résumé Financier';
  String get settlementPeriod => isAr ? 'فترة التسوية' : 'Période de Règlement';
  String get amountDue => isAr ? 'المبلغ المستحق' : 'Montant Dû';
  String get toTeacher => isAr ? 'للأستاذ' : 'À l\'Enseignant';
  String get toCenter => isAr ? 'للمركز' : 'Au Centre';
  String get currency => isAr ? 'د.ت' : 'DT';

  // ── Months ──────────────────────────────────────────────────────────────────
  String monthName(int m) {
    if (isAr) {
      const months = [
        'جانفي', 'فيفري', 'مارس', 'أفريل', 'ماي', 'جوان',
        'جويلية', 'أوت', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
      ];
      return months[m - 1];
    }
    const months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return months[m - 1];
  }

  // Get from context
  static AppLocalizations of(BuildContext context) {
    final lang = Hive.box('settings').get('app_language', defaultValue: 'fr') as String;
    return AppLocalizations(lang);
  }
}
