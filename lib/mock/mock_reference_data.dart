// GENERATED from the live API on 2026-09-23 (GET /app/wilayas and
// GET /app/categories). Reference data for mock mode; regenerate if the
// backend lists change.

import '../core/models/account.dart';

/// All 58 wilayas, as the live API lists them.
const List<Wilaya> mockWilayas = <Wilaya>[
  Wilaya(code: 1, nameEn: 'Adrar', nameAr: 'أدرار'),
  Wilaya(code: 2, nameEn: 'Chlef', nameAr: 'الشلف'),
  Wilaya(code: 3, nameEn: 'Laghouat', nameAr: 'الأغواط'),
  Wilaya(code: 4, nameEn: 'Oum El Bouaghi', nameAr: 'أم البواقي'),
  Wilaya(code: 5, nameEn: 'Batna', nameAr: 'باتنة'),
  Wilaya(code: 6, nameEn: 'Béjaïa', nameAr: 'بجاية'),
  Wilaya(code: 7, nameEn: 'Biskra', nameAr: 'بسكرة'),
  Wilaya(code: 8, nameEn: 'Béchar', nameAr: 'بشار'),
  Wilaya(code: 9, nameEn: 'Blida', nameAr: 'البليدة'),
  Wilaya(code: 10, nameEn: 'Bouira', nameAr: 'البويرة'),
  Wilaya(code: 11, nameEn: 'Tamanrasset', nameAr: 'تمنراست'),
  Wilaya(code: 12, nameEn: 'Tébessa', nameAr: 'تبسة'),
  Wilaya(code: 13, nameEn: 'Tlemcen', nameAr: 'تلمسان'),
  Wilaya(code: 14, nameEn: 'Tiaret', nameAr: 'تيارت'),
  Wilaya(code: 15, nameEn: 'Tizi Ouzou', nameAr: 'تيزي وزو'),
  Wilaya(code: 16, nameEn: 'Alger', nameAr: 'الجزائر'),
  Wilaya(code: 17, nameEn: 'Djelfa', nameAr: 'الجلفة'),
  Wilaya(code: 18, nameEn: 'Jijel', nameAr: 'جيجل'),
  Wilaya(code: 19, nameEn: 'Sétif', nameAr: 'سطيف'),
  Wilaya(code: 20, nameEn: 'Saïda', nameAr: 'سعيدة'),
  Wilaya(code: 21, nameEn: 'Skikda', nameAr: 'سكيكدة'),
  Wilaya(code: 22, nameEn: 'Sidi Bel Abbès', nameAr: 'سيدي بلعباس'),
  Wilaya(code: 23, nameEn: 'Annaba', nameAr: 'عنابة'),
  Wilaya(code: 24, nameEn: 'Guelma', nameAr: 'قالمة'),
  Wilaya(code: 25, nameEn: 'Constantine', nameAr: 'قسنطينة'),
  Wilaya(code: 26, nameEn: 'Médéa', nameAr: 'المدية'),
  Wilaya(code: 27, nameEn: 'Mostaganem', nameAr: 'مستغانم'),
  Wilaya(code: 28, nameEn: 'M\'Sila', nameAr: 'المسيلة'),
  Wilaya(code: 29, nameEn: 'Mascara', nameAr: 'معسكر'),
  Wilaya(code: 30, nameEn: 'Ouargla', nameAr: 'ورقلة'),
  Wilaya(code: 31, nameEn: 'Oran', nameAr: 'وهران'),
  Wilaya(code: 32, nameEn: 'El Bayadh', nameAr: 'البيض'),
  Wilaya(code: 33, nameEn: 'Illizi', nameAr: 'إليزي'),
  Wilaya(code: 34, nameEn: 'Bordj Bou Arréridj', nameAr: 'برج بوعريريج'),
  Wilaya(code: 35, nameEn: 'Boumerdès', nameAr: 'بومرداس'),
  Wilaya(code: 36, nameEn: 'El Tarf', nameAr: 'الطارف'),
  Wilaya(code: 37, nameEn: 'Tindouf', nameAr: 'تندوف'),
  Wilaya(code: 38, nameEn: 'Tissemsilt', nameAr: 'تيسمسيلت'),
  Wilaya(code: 39, nameEn: 'El Oued', nameAr: 'الوادي'),
  Wilaya(code: 40, nameEn: 'Khenchela', nameAr: 'خنشلة'),
  Wilaya(code: 41, nameEn: 'Souk Ahras', nameAr: 'سوق أهراس'),
  Wilaya(code: 42, nameEn: 'Tipaza', nameAr: 'تيبازة'),
  Wilaya(code: 43, nameEn: 'Mila', nameAr: 'ميلة'),
  Wilaya(code: 44, nameEn: 'Aïn Defla', nameAr: 'عين الدفلى'),
  Wilaya(code: 45, nameEn: 'Naâma', nameAr: 'النعامة'),
  Wilaya(code: 46, nameEn: 'Aïn Témouchent', nameAr: 'عين تموشنت'),
  Wilaya(code: 47, nameEn: 'Ghardaïa', nameAr: 'غرداية'),
  Wilaya(code: 48, nameEn: 'Relizane', nameAr: 'غليزان'),
  Wilaya(code: 49, nameEn: 'Timimoun', nameAr: 'تيميمون'),
  Wilaya(code: 50, nameEn: 'Bordj Badji Mokhtar', nameAr: 'برج باجي مختار'),
  Wilaya(code: 51, nameEn: 'Ouled Djellal', nameAr: 'أولاد جلال'),
  Wilaya(code: 52, nameEn: 'Béni Abbès', nameAr: 'بني عباس'),
  Wilaya(code: 53, nameEn: 'In Salah', nameAr: 'عين صالح'),
  Wilaya(code: 54, nameEn: 'In Guezzam', nameAr: 'عين قزام'),
  Wilaya(code: 55, nameEn: 'Touggourt', nameAr: 'تقرت'),
  Wilaya(code: 56, nameEn: 'Djanet', nameAr: 'جانت'),
  Wilaya(code: 57, nameEn: 'El M\'Ghair', nameAr: 'المغير'),
  Wilaya(code: 58, nameEn: 'El Meniaa', nameAr: 'المنيعة'),
];

/// The service categories, as the live API lists them. "Beauty" really has no
/// Arabic name on the server; kept as-is so mock mode shows the same gap.
const List<ServiceCategory> mockCategories = <ServiceCategory>[
  ServiceCategory(
    id: 'bb28c638-c0ea-4140-b9d9-fd5535a6c4b6',
    nameEn: 'Venues',
    nameAr: 'قاعات الحفلات',
  ),
  ServiceCategory(
    id: '7d3855dd-4bd3-430a-9ffc-09d4f269eb4a',
    nameEn: 'Photography',
    nameAr: 'التصوير',
  ),
  ServiceCategory(
    id: 'd892155b-2c9b-4e0f-8fb5-db15b54af350',
    nameEn: 'Catering',
    nameAr: 'الإطعام',
  ),
  ServiceCategory(
    id: '601c07e5-d2c8-4619-bbb4-bbb546803413',
    nameEn: 'Music & DJ',
    nameAr: 'الموسيقى',
  ),
  ServiceCategory(
    id: '9ec8cbe5-ead7-42b4-99d1-fccc49fdad50',
    nameEn: 'Decoration',
    nameAr: 'الديكور',
  ),
  ServiceCategory(
    id: '0b52682c-4d00-49df-b18a-2c30c363a331',
    nameEn: 'Flowers',
    nameAr: 'الزهور',
  ),
  ServiceCategory(
    id: '137d6aeb-8aa1-4c3e-a9cd-ca5a67c4e1d1',
    nameEn: 'Cakes & pastry',
    nameAr: 'الحلويات',
  ),
  ServiceCategory(
    id: '76e7dc65-d132-4e1b-8ec0-1b09437997f2',
    nameEn: 'Beauty',
    nameAr: '',
  ),
];
