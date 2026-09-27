// GENERATED from the live catalog on 2026-09-24 (GET /app/services,
// /app/packs, /app/categories, one provider and one pack detail) by the
// session's gen_mock_catalog.js, plus edge cases the live data lacks:
// Salle Les Oliviers has paused bookings, Studio Lumière has 12 services (the profile
// lists 10), "Drone aerial shots" has no photos, and one saved favourite is
// no longer listed. Regenerate rather than hand-edit.
//
// Plain maps on purpose: the mock repositories build API-shaped JSON from
// them and parse it with the same fromJson the live responses go through.

/// Categories. `listed: false` mirrors live "Transport": its services are
/// visible but /app/categories leaves it out.
const List<Map<String, Object?>> mockCatalogCategories = <Map<String, Object?>>[
  {
    "id": "bb28c638-c0ea-4140-b9d9-fd5535a6c4b6",
    "slug": "salles-des-fetes",
    "nameEn": "Venues",
    "nameAr": "قاعات الحفلات",
    "icon": "building",
    "position": 0,
    "listed": true
  },
  {
    "id": "7d3855dd-4bd3-430a-9ffc-09d4f269eb4a",
    "slug": "photographie",
    "nameEn": "Photography",
    "nameAr": "التصوير",
    "icon": "camera",
    "position": 1,
    "listed": true
  },
  {
    "id": "d892155b-2c9b-4e0f-8fb5-db15b54af350",
    "slug": "traiteur",
    "nameEn": "Catering",
    "nameAr": "الإطعام",
    "icon": "utensils",
    "position": 2,
    "listed": true
  },
  {
    "id": "601c07e5-d2c8-4619-bbb4-bbb546803413",
    "slug": "musique-dj",
    "nameEn": "Music & DJ",
    "nameAr": "الموسيقى",
    "icon": "music",
    "position": 3,
    "listed": true
  },
  {
    "id": "9ec8cbe5-ead7-42b4-99d1-fccc49fdad50",
    "slug": "decoration",
    "nameEn": "Decoration",
    "nameAr": "الديكور",
    "icon": "sparkles",
    "position": 4,
    "listed": true
  },
  {
    "id": "0b52682c-4d00-49df-b18a-2c30c363a331",
    "slug": "fleurs",
    "nameEn": "Flowers",
    "nameAr": "الزهور",
    "icon": "flower",
    "position": 5,
    "listed": true
  },
  {
    "id": "137d6aeb-8aa1-4c3e-a9cd-ca5a67c4e1d1",
    "slug": "gateaux-patisserie",
    "nameEn": "Cakes & pastry",
    "nameAr": "الحلويات",
    "icon": "cake",
    "position": 6,
    "listed": true
  },
  {
    "id": "76e7dc65-d132-4e1b-8ec0-1b09437997f2",
    "slug": "beaute",
    "nameEn": "Beauty",
    "nameAr": "",
    "icon": "brush",
    "position": 7,
    "listed": true
  },
  {
    "id": "3b472770-bd00-44ce-b2cc-a1dba7b327c5",
    "slug": "transport",
    "nameEn": "Transport",
    "nameAr": "النقل",
    "icon": "car",
    "position": 99,
    "listed": false
  }
];

const List<Map<String, Object?>> mockCatalogProviders = <Map<String, Object?>>[
  {
    "id": "3552815d-6aca-43fc-ace8-0409ee3a762e",
    "businessName": "Studio Lumière",
    "categoryId": "7d3855dd-4bd3-430a-9ffc-09d4f269eb4a",
    "verified": true,
    "completedBookingsCount": 7,
    "yearsActive": 15,
    "replyTime": "2 h",
    "acceptingBookings": true,
    "bioEn": "Wedding and engagement photography in Algiers since 2014.",
    "bioAr": "تصوير الأعراس والخطوبة في الجزائر العاصمة منذ 2014.",
    "languagesSpoken": [
      "ar",
      "fr",
      "en"
    ],
    "wilayas": [
      9,
      16,
      42
    ],
    "identityPassed": true,
    "registrationPassed": true,
    "replyPassed": true,
    "memberSince": "2025-01-03T00:00:00.000Z"
  },
  {
    "id": "c62532f4-6fa9-4752-9f82-cdbea4b0dd07",
    "businessName": "Salle Yasmine",
    "categoryId": "bb28c638-c0ea-4140-b9d9-fd5535a6c4b6",
    "verified": true,
    "completedBookingsCount": 9,
    "yearsActive": 5,
    "replyTime": "1 h",
    "acceptingBookings": true,
    "bioEn": "Salle Yasmine — venues for weddings, engagements and family celebrations across several wilayas.",
    "bioAr": "Salle Yasmine — خدمات للأعراس والخطوبة والمناسبات العائلية.",
    "languagesSpoken": [
      "ar",
      "fr",
      "en"
    ],
    "wilayas": [
      9,
      16
    ],
    "identityPassed": true,
    "registrationPassed": true,
    "replyPassed": true,
    "memberSince": "2025-03-04T00:00:00.000Z"
  },
  {
    "id": "e1ad2116-c6a2-4d3f-a9ea-c4168694f925",
    "businessName": "Douceurs d'Oran",
    "categoryId": "137d6aeb-8aa1-4c3e-a9cd-ca5a67c4e1d1",
    "verified": true,
    "completedBookingsCount": 5,
    "yearsActive": 13,
    "replyTime": null,
    "acceptingBookings": true,
    "bioEn": "Douceurs d'Oran — cakes & pastry for weddings, engagements and family celebrations across several wilayas.",
    "bioAr": "Douceurs d'Oran — خدمات للأعراس والخطوبة والمناسبات العائلية.",
    "languagesSpoken": [
      "ar",
      "fr"
    ],
    "wilayas": [
      27,
      31
    ],
    "identityPassed": true,
    "registrationPassed": true,
    "replyPassed": false,
    "memberSince": "2025-05-05T00:00:00.000Z"
  },
  {
    "id": "6db77516-86a1-49ef-8b57-2c610c4e90ca",
    "businessName": "Traiteur El Djazair",
    "categoryId": "d892155b-2c9b-4e0f-8fb5-db15b54af350",
    "verified": true,
    "completedBookingsCount": 17,
    "yearsActive": 10,
    "replyTime": "3 h",
    "acceptingBookings": true,
    "bioEn": "Traiteur El Djazair — catering for weddings, engagements and family celebrations across several wilayas.",
    "bioAr": "Traiteur El Djazair — خدمات للأعراس والخطوبة والمناسبات العائلية.",
    "languagesSpoken": [
      "ar",
      "fr",
      "en"
    ],
    "wilayas": [
      9,
      16,
      35
    ],
    "identityPassed": true,
    "registrationPassed": false,
    "replyPassed": true,
    "memberSince": "2025-07-06T00:00:00.000Z"
  },
  {
    "id": "94305376-287a-4966-9546-8c3afd247e88",
    "businessName": "Salle El Bahia",
    "categoryId": "bb28c638-c0ea-4140-b9d9-fd5535a6c4b6",
    "verified": true,
    "completedBookingsCount": 5,
    "yearsActive": 14,
    "replyTime": null,
    "acceptingBookings": true,
    "bioEn": "Salle El Bahia — venues for weddings, engagements and family celebrations across the wilaya.",
    "bioAr": "Salle El Bahia — خدمات للأعراس والخطوبة والمناسبات العائلية.",
    "languagesSpoken": [
      "ar",
      "fr"
    ],
    "wilayas": [
      31
    ],
    "identityPassed": true,
    "registrationPassed": true,
    "replyPassed": false,
    "memberSince": "2025-09-07T00:00:00.000Z"
  },
  {
    "id": "874ec054-c8d1-4c70-810c-52c9debac14f",
    "businessName": "Orchestre Andalou",
    "categoryId": "601c07e5-d2c8-4619-bbb4-bbb546803413",
    "verified": true,
    "completedBookingsCount": 4,
    "yearsActive": 1,
    "replyTime": null,
    "acceptingBookings": true,
    "bioEn": "Orchestre Andalou — music & dj for weddings, engagements and family celebrations across several wilayas.",
    "bioAr": "Orchestre Andalou — خدمات للأعراس والخطوبة والمناسبات العائلية.",
    "languagesSpoken": [
      "ar",
      "fr",
      "en"
    ],
    "wilayas": [
      19,
      25
    ],
    "identityPassed": true,
    "registrationPassed": true,
    "replyPassed": false,
    "memberSince": "2025-11-08T00:00:00.000Z"
  },
  {
    "id": "aebed654-e28b-4191-8ec2-531031ca3314",
    "businessName": "Pâtisserie Meriem",
    "categoryId": "137d6aeb-8aa1-4c3e-a9cd-ca5a67c4e1d1",
    "verified": true,
    "completedBookingsCount": 4,
    "yearsActive": 2,
    "replyTime": null,
    "acceptingBookings": true,
    "bioEn": "Pâtisserie Meriem — cakes & pastry for weddings, engagements and family celebrations across the wilaya.",
    "bioAr": "Pâtisserie Meriem — خدمات للأعراس والخطوبة والمناسبات العائلية.",
    "languagesSpoken": [
      "ar",
      "fr"
    ],
    "wilayas": [
      16
    ],
    "identityPassed": true,
    "registrationPassed": true,
    "replyPassed": false,
    "memberSince": "2025-01-09T00:00:00.000Z"
  },
  {
    "id": "fe9734e0-24c4-4640-ae2a-d07220ed3f5a",
    "businessName": "Salle Les Oliviers",
    "categoryId": "bb28c638-c0ea-4140-b9d9-fd5535a6c4b6",
    "verified": true,
    "completedBookingsCount": 5,
    "yearsActive": 1,
    "replyTime": null,
    "acceptingBookings": false,
    "bioEn": "Salle Les Oliviers — venues for weddings, engagements and family celebrations across several wilayas.",
    "bioAr": "Salle Les Oliviers — خدمات للأعراس والخطوبة والمناسبات العائلية.",
    "languagesSpoken": [
      "ar",
      "fr",
      "en"
    ],
    "wilayas": [
      9,
      42
    ],
    "identityPassed": true,
    "registrationPassed": true,
    "replyPassed": false,
    "memberSince": "2025-03-10T00:00:00.000Z"
  },
  {
    "id": "96a1f496-ffee-4a92-8204-76f8066a62e4",
    "businessName": "Flora Design",
    "categoryId": "0b52682c-4d00-49df-b18a-2c30c363a331",
    "verified": true,
    "completedBookingsCount": 6,
    "yearsActive": 2,
    "replyTime": null,
    "acceptingBookings": true,
    "bioEn": "Flora Design — flowers for weddings, engagements and family celebrations across several wilayas.",
    "bioAr": "Flora Design — خدمات للأعراس والخطوبة والمناسبات العائلية.",
    "languagesSpoken": [
      "ar",
      "fr"
    ],
    "wilayas": [
      16,
      42
    ],
    "identityPassed": true,
    "registrationPassed": false,
    "replyPassed": false,
    "memberSince": "2025-05-11T00:00:00.000Z"
  },
  {
    "id": "de14bc74-7094-4e15-a1b9-3b1f50a5e607",
    "businessName": "Studio Yasmine Photo",
    "categoryId": "7d3855dd-4bd3-430a-9ffc-09d4f269eb4a",
    "verified": true,
    "completedBookingsCount": 5,
    "yearsActive": 6,
    "replyTime": null,
    "acceptingBookings": true,
    "bioEn": "Studio Yasmine Photo — photography for weddings, engagements and family celebrations across several wilayas.",
    "bioAr": "Studio Yasmine Photo — خدمات للأعراس والخطوبة والمناسبات العائلية.",
    "languagesSpoken": [
      "ar",
      "fr",
      "en"
    ],
    "wilayas": [
      9,
      16
    ],
    "identityPassed": true,
    "registrationPassed": true,
    "replyPassed": false,
    "memberSince": "2025-07-12T00:00:00.000Z"
  },
  {
    "id": "94991c78-a5b7-4c3d-8aa6-a7fefcb75d64",
    "businessName": "Rym Events Déco",
    "categoryId": "9ec8cbe5-ead7-42b4-99d1-fccc49fdad50",
    "verified": true,
    "completedBookingsCount": 7,
    "yearsActive": 2,
    "replyTime": null,
    "acceptingBookings": true,
    "bioEn": "Rym Events Déco — decoration for weddings, engagements and family celebrations across the wilaya.",
    "bioAr": "Rym Events Déco — خدمات للأعراس والخطوبة والمناسبات العائلية.",
    "languagesSpoken": [
      "ar",
      "fr"
    ],
    "wilayas": [
      31
    ],
    "identityPassed": true,
    "registrationPassed": true,
    "replyPassed": false,
    "memberSince": "2025-09-13T00:00:00.000Z"
  },
  {
    "id": "a08cde8f-1369-492a-8dd3-8187341af983",
    "businessName": "Limousine Prestige",
    "categoryId": "3b472770-bd00-44ce-b2cc-a1dba7b327c5",
    "verified": true,
    "completedBookingsCount": 5,
    "yearsActive": 13,
    "replyTime": null,
    "acceptingBookings": true,
    "bioEn": "Limousine Prestige — transport for weddings, engagements and family celebrations across several wilayas.",
    "bioAr": "Limousine Prestige — خدمات للأعراس والخطوبة والمناسبات العائلية.",
    "languagesSpoken": [
      "ar",
      "fr",
      "en"
    ],
    "wilayas": [
      9,
      16
    ],
    "identityPassed": true,
    "registrationPassed": true,
    "replyPassed": false,
    "memberSince": "2025-11-14T00:00:00.000Z"
  }
];

/// `photos` are file names under assets/mock/photos/. `ratingCounts` is
/// the 5→1 star breakdown. `order` is creation order (for "newest").
const List<Map<String, Object?>> mockCatalogServices = <Map<String, Object?>>[
  {
    "id": "892e3d17-0f2e-4348-a5f0-5a0df2b285ef",
    "providerId": "3552815d-6aca-43fc-ace8-0409ee3a762e",
    "titleEn": "Wedding photo & video coverage",
    "titleAr": "تغطية زفاف بالصورة والفيديو",
    "categoryId": "7d3855dd-4bd3-430a-9ffc-09d4f269eb4a",
    "basePrice": "120000.00",
    "priceType": "per_event",
    "avgRating": "5.00",
    "ratingCount": 2,
    "ratingCounts": [
      2,
      0,
      0,
      0,
      0
    ],
    "bookingsCount": 2,
    "wilayas": [
      9,
      16,
      42
    ],
    "photos": [
      "pexels-photographie-1.webp",
      "pexels-photographie-2.webp",
      "pexels-photographie-3.webp"
    ],
    "descriptionEn": "Wedding photo & video coverage. Studio Lumière takes care of every detail, from the first call to the day itself. Send a request with your date and the provider confirms within 48 hours.",
    "descriptionAr": "تغطية زفاف بالصورة والفيديو. يتكفّل Studio Lumière بكل التفاصيل، من أول اتصال حتى يوم المناسبة. أرسل طلبًا مع التاريخ وسيؤكد مقدّم الخدمة خلال 48 ساعة.",
    "cancellationEn": "Free cancellation up to 7 days before the event. After that, the deposit agreed with the provider is kept.",
    "cancellationAr": "إلغاء مجاني حتى 7 أيام قبل المناسبة. بعد ذلك يحتفظ مقدّم الخدمة بالعربون المتفق عليه.",
    "facts": [
      {
        "labelEn": "Team",
        "labelAr": "الفريق",
        "valueEn": "2 photographers",
        "valueAr": "مصوران"
      },
      {
        "labelEn": "Delivery",
        "labelAr": "التسليم",
        "valueEn": "3 weeks",
        "valueAr": "3 أسابيع"
      }
    ],
    "extras": [
      {
        "id": "892e3d17-0f2e-4348-a5f0-5a0df2b285ef-x0",
        "nameEn": "Drone footage",
        "nameAr": "تصوير بالدرون",
        "price": "15000.00"
      },
      {
        "id": "892e3d17-0f2e-4348-a5f0-5a0df2b285ef-x1",
        "nameEn": "Printed album",
        "nameAr": "ألبوم مطبوع",
        "price": "18000.00"
      }
    ],
    "maxGuests": null,
    "maxEventsPerDay": 2,
    "order": 0
  },
  {
    "id": "98209b95-db94-43d3-9c27-e6ab2132fd60",
    "providerId": "3552815d-6aca-43fc-ace8-0409ee3a762e",
    "titleEn": "Engagement photo session",
    "titleAr": "جلسة تصوير الخطوبة",
    "categoryId": "7d3855dd-4bd3-430a-9ffc-09d4f269eb4a",
    "basePrice": "35000.00",
    "priceType": "per_event",
    "avgRating": "4.00",
    "ratingCount": 1,
    "ratingCounts": [
      0,
      1,
      0,
      0,
      0
    ],
    "bookingsCount": 2,
    "wilayas": [
      9,
      16
    ],
    "photos": [
      "pexels-photographie-2.webp",
      "pexels-photographie-3.webp",
      "pexels-photographie-4.webp"
    ],
    "descriptionEn": "Engagement photo session. Studio Lumière takes care of every detail, from the first call to the day itself. Send a request with your date and the provider confirms within 48 hours.",
    "descriptionAr": "جلسة تصوير الخطوبة. يتكفّل Studio Lumière بكل التفاصيل، من أول اتصال حتى يوم المناسبة. أرسل طلبًا مع التاريخ وسيؤكد مقدّم الخدمة خلال 48 ساعة.",
    "cancellationEn": null,
    "cancellationAr": null,
    "facts": [
      {
        "labelEn": "Team",
        "labelAr": "الفريق",
        "valueEn": "2 photographers",
        "valueAr": "مصوران"
      },
      {
        "labelEn": "Delivery",
        "labelAr": "التسليم",
        "valueEn": "3 weeks",
        "valueAr": "3 أسابيع"
      }
    ],
    "extras": [
      {
        "id": "98209b95-db94-43d3-9c27-e6ab2132fd60-x0",
        "nameEn": "Drone footage",
        "nameAr": "تصوير بالدرون",
        "price": "15000.00"
      },
      {
        "id": "98209b95-db94-43d3-9c27-e6ab2132fd60-x1",
        "nameEn": "Printed album",
        "nameAr": "ألبوم مطبوع",
        "price": "18000.00"
      }
    ],
    "maxGuests": null,
    "maxEventsPerDay": 2,
    "order": 1
  },
  {
    "id": "f491ca64-3892-4191-b146-e557b441374d",
    "providerId": "c62532f4-6fa9-4752-9f82-cdbea4b0dd07",
    "titleEn": "Grande salle · 150 seats",
    "titleAr": "القاعة الكبرى · 150 مقعدًا",
    "categoryId": "bb28c638-c0ea-4140-b9d9-fd5535a6c4b6",
    "basePrice": "250000.00",
    "priceType": "per_event",
    "avgRating": "4.00",
    "ratingCount": 1,
    "ratingCounts": [
      0,
      1,
      0,
      0,
      0
    ],
    "bookingsCount": 2,
    "wilayas": [
      9
    ],
    "photos": [
      "pexels-salles-des-fetes-1.webp",
      "pexels-salles-des-fetes-2.webp",
      "pexels-salles-des-fetes-3.webp"
    ],
    "descriptionEn": "Grande salle · 150 seats. Salle Yasmine takes care of every detail, from the first call to the day itself. Send a request with your date and the provider confirms within 48 hours.",
    "descriptionAr": "القاعة الكبرى · 150 مقعدًا. يتكفّل Salle Yasmine بكل التفاصيل، من أول اتصال حتى يوم المناسبة. أرسل طلبًا مع التاريخ وسيؤكد مقدّم الخدمة خلال 48 ساعة.",
    "cancellationEn": "Free cancellation up to 7 days before the event. After that, the deposit agreed with the provider is kept.",
    "cancellationAr": "إلغاء مجاني حتى 7 أيام قبل المناسبة. بعد ذلك يحتفظ مقدّم الخدمة بالعربون المتفق عليه.",
    "facts": [
      {
        "labelEn": "Capacity",
        "labelAr": "السعة",
        "valueEn": "300 guests",
        "valueAr": "300 ضيف"
      },
      {
        "labelEn": "Parking",
        "labelAr": "موقف السيارات",
        "valueEn": "Available",
        "valueAr": "متوفر"
      }
    ],
    "extras": [
      {
        "id": "f491ca64-3892-4191-b146-e557b441374d-x0",
        "nameEn": "Extra hour",
        "nameAr": "ساعة إضافية",
        "price": "20000.00"
      }
    ],
    "maxGuests": 300,
    "maxEventsPerDay": 1,
    "order": 2
  },
  {
    "id": "39d80b05-0886-445e-95ba-d227a877fd3f",
    "providerId": "e1ad2116-c6a2-4d3f-a9ea-c4168694f925",
    "titleEn": "Pâtisserie & wedding cake",
    "titleAr": "حلويات وكعكة الزفاف",
    "categoryId": "137d6aeb-8aa1-4c3e-a9cd-ca5a67c4e1d1",
    "basePrice": "55000.00",
    "priceType": "per_event",
    "avgRating": "0.00",
    "ratingCount": 0,
    "ratingCounts": [
      0,
      0,
      0,
      0,
      0
    ],
    "bookingsCount": 3,
    "wilayas": [
      27,
      31
    ],
    "photos": [
      "pexels-gateaux-patisserie-1.webp",
      "pexels-gateaux-patisserie-2.webp",
      "pexels-gateaux-patisserie-3.webp"
    ],
    "descriptionEn": "Pâtisserie & wedding cake. Douceurs d'Oran takes care of every detail, from the first call to the day itself. Send a request with your date and the provider confirms within 48 hours.",
    "descriptionAr": "حلويات وكعكة الزفاف. يتكفّل Douceurs d'Oran بكل التفاصيل، من أول اتصال حتى يوم المناسبة. أرسل طلبًا مع التاريخ وسيؤكد مقدّم الخدمة خلال 48 ساعة.",
    "cancellationEn": null,
    "cancellationAr": null,
    "facts": [
      {
        "labelEn": "Tasting",
        "labelAr": "التذوق",
        "valueEn": "Free",
        "valueAr": "مجاني"
      },
      {
        "labelEn": "Order",
        "labelAr": "الطلب",
        "valueEn": "2 weeks ahead",
        "valueAr": "قبل أسبوعين"
      }
    ],
    "extras": [
      {
        "id": "39d80b05-0886-445e-95ba-d227a877fd3f-x0",
        "nameEn": "Tasting box",
        "nameAr": "علبة تذوق",
        "price": "3000.00"
      }
    ],
    "maxGuests": null,
    "maxEventsPerDay": 2,
    "order": 3
  },
  {
    "id": "5d76f867-bda5-4741-90c3-c575906aaf7a",
    "providerId": "6db77516-86a1-49ef-8b57-2c610c4e90ca",
    "titleEn": "Algerian wedding buffet",
    "titleAr": "بوفيه زفاف جزائري",
    "categoryId": "d892155b-2c9b-4e0f-8fb5-db15b54af350",
    "basePrice": "3200.00",
    "priceType": "per_person",
    "avgRating": "0.00",
    "ratingCount": 0,
    "ratingCounts": [
      0,
      0,
      0,
      0,
      0
    ],
    "bookingsCount": 1,
    "wilayas": [
      9
    ],
    "photos": [
      "pexels-traiteur-1.webp",
      "pexels-traiteur-2.webp",
      "pexels-traiteur-3.webp"
    ],
    "descriptionEn": "Algerian wedding buffet. Traiteur El Djazair takes care of every detail, from the first call to the day itself. Send a request with your date and the provider confirms within 48 hours.",
    "descriptionAr": "بوفيه زفاف جزائري. يتكفّل Traiteur El Djazair بكل التفاصيل، من أول اتصال حتى يوم المناسبة. أرسل طلبًا مع التاريخ وسيؤكد مقدّم الخدمة خلال 48 ساعة.",
    "cancellationEn": "Free cancellation up to 7 days before the event. After that, the deposit agreed with the provider is kept.",
    "cancellationAr": "إلغاء مجاني حتى 7 أيام قبل المناسبة. بعد ذلك يحتفظ مقدّم الخدمة بالعربون المتفق عليه.",
    "facts": [
      {
        "labelEn": "Service staff",
        "labelAr": "طاقم الخدمة",
        "valueEn": "Included",
        "valueAr": "مشمول"
      },
      {
        "labelEn": "Menu tasting",
        "labelAr": "تذوق القائمة",
        "valueEn": "On request",
        "valueAr": "عند الطلب"
      }
    ],
    "extras": [
      {
        "id": "5d76f867-bda5-4741-90c3-c575906aaf7a-x0",
        "nameEn": "Dessert buffet",
        "nameAr": "بوفيه حلويات",
        "price": "40000.00"
      }
    ],
    "maxGuests": 500,
    "maxEventsPerDay": 2,
    "order": 4
  },
  {
    "id": "087596a7-870a-486f-aa3b-d70def6bba33",
    "providerId": "94305376-287a-4966-9546-8c3afd247e88",
    "titleEn": "Sea-view wedding hall · 300 guests",
    "titleAr": "قاعة أعراس مطلة على البحر · 300 ضيف",
    "categoryId": "bb28c638-c0ea-4140-b9d9-fd5535a6c4b6",
    "basePrice": "380000.00",
    "priceType": "per_event",
    "avgRating": "3.00",
    "ratingCount": 2,
    "ratingCounts": [
      0,
      0,
      2,
      0,
      0
    ],
    "bookingsCount": 2,
    "wilayas": [
      31
    ],
    "photos": [
      "pexels-salles-des-fetes-2.webp",
      "pexels-salles-des-fetes-3.webp",
      "pexels-salles-des-fetes-4.webp"
    ],
    "descriptionEn": "Sea-view wedding hall · 300 guests. Salle El Bahia takes care of every detail, from the first call to the day itself. Send a request with your date and the provider confirms within 48 hours.",
    "descriptionAr": "قاعة أعراس مطلة على البحر · 300 ضيف. يتكفّل Salle El Bahia بكل التفاصيل، من أول اتصال حتى يوم المناسبة. أرسل طلبًا مع التاريخ وسيؤكد مقدّم الخدمة خلال 48 ساعة.",
    "cancellationEn": null,
    "cancellationAr": null,
    "facts": [
      {
        "labelEn": "Capacity",
        "labelAr": "السعة",
        "valueEn": "300 guests",
        "valueAr": "300 ضيف"
      },
      {
        "labelEn": "Parking",
        "labelAr": "موقف السيارات",
        "valueEn": "Available",
        "valueAr": "متوفر"
      }
    ],
    "extras": [
      {
        "id": "087596a7-870a-486f-aa3b-d70def6bba33-x0",
        "nameEn": "Extra hour",
        "nameAr": "ساعة إضافية",
        "price": "20000.00"
      }
    ],
    "maxGuests": 300,
    "maxEventsPerDay": 1,
    "order": 5
  },
  {
    "id": "c238525a-b7ba-414e-b6df-85ba9fbb8066",
    "providerId": "874ec054-c8d1-4c70-810c-52c9debac14f",
    "titleEn": "Malouf orchestra · full evening",
    "titleAr": "جوق المالوف · سهرة كاملة",
    "categoryId": "601c07e5-d2c8-4619-bbb4-bbb546803413",
    "basePrice": "150000.00",
    "priceType": "per_event",
    "avgRating": "3.00",
    "ratingCount": 1,
    "ratingCounts": [
      0,
      0,
      1,
      0,
      0
    ],
    "bookingsCount": 2,
    "wilayas": [
      19,
      25
    ],
    "photos": [
      "pexels-musique-dj-1.webp",
      "pexels-musique-dj-2.webp",
      "pexels-musique-dj-3.webp"
    ],
    "descriptionEn": "Malouf orchestra · full evening. Orchestre Andalou takes care of every detail, from the first call to the day itself. Send a request with your date and the provider confirms within 48 hours.",
    "descriptionAr": "جوق المالوف · سهرة كاملة. يتكفّل Orchestre Andalou بكل التفاصيل، من أول اتصال حتى يوم المناسبة. أرسل طلبًا مع التاريخ وسيؤكد مقدّم الخدمة خلال 48 ساعة.",
    "cancellationEn": "Free cancellation up to 7 days before the event. After that, the deposit agreed with the provider is kept.",
    "cancellationAr": "إلغاء مجاني حتى 7 أيام قبل المناسبة. بعد ذلك يحتفظ مقدّم الخدمة بالعربون المتفق عليه.",
    "facts": [
      {
        "labelEn": "Band",
        "labelAr": "الفرقة",
        "valueEn": "6 musicians",
        "valueAr": "6 عازفين"
      },
      {
        "labelEn": "Duration",
        "labelAr": "المدة",
        "valueEn": "4 hours",
        "valueAr": "4 ساعات"
      }
    ],
    "extras": [
      {
        "id": "c238525a-b7ba-414e-b6df-85ba9fbb8066-x0",
        "nameEn": "Extra hour",
        "nameAr": "ساعة إضافية",
        "price": "15000.00"
      }
    ],
    "maxGuests": null,
    "maxEventsPerDay": 2,
    "order": 6
  },
  {
    "id": "5efae45f-afc5-4378-944a-17ba7492691f",
    "providerId": "aebed654-e28b-4191-8ec2-531031ca3314",
    "titleEn": "Tiered wedding cake",
    "titleAr": "كعكة زفاف بطبقات",
    "categoryId": "137d6aeb-8aa1-4c3e-a9cd-ca5a67c4e1d1",
    "basePrice": "45000.00",
    "priceType": "per_event",
    "avgRating": "0.00",
    "ratingCount": 0,
    "ratingCounts": [
      0,
      0,
      0,
      0,
      0
    ],
    "bookingsCount": 2,
    "wilayas": [
      16
    ],
    "photos": [
      "pexels-gateaux-patisserie-2.webp",
      "pexels-gateaux-patisserie-3.webp",
      "pexels-gateaux-patisserie-4.webp"
    ],
    "descriptionEn": "Tiered wedding cake. Pâtisserie Meriem takes care of every detail, from the first call to the day itself. Send a request with your date and the provider confirms within 48 hours.",
    "descriptionAr": "كعكة زفاف بطبقات. يتكفّل Pâtisserie Meriem بكل التفاصيل، من أول اتصال حتى يوم المناسبة. أرسل طلبًا مع التاريخ وسيؤكد مقدّم الخدمة خلال 48 ساعة.",
    "cancellationEn": null,
    "cancellationAr": null,
    "facts": [
      {
        "labelEn": "Tasting",
        "labelAr": "التذوق",
        "valueEn": "Free",
        "valueAr": "مجاني"
      },
      {
        "labelEn": "Order",
        "labelAr": "الطلب",
        "valueEn": "2 weeks ahead",
        "valueAr": "قبل أسبوعين"
      }
    ],
    "extras": [
      {
        "id": "5efae45f-afc5-4378-944a-17ba7492691f-x0",
        "nameEn": "Tasting box",
        "nameAr": "علبة تذوق",
        "price": "3000.00"
      }
    ],
    "maxGuests": null,
    "maxEventsPerDay": 2,
    "order": 7
  },
  {
    "id": "d5fce8fc-5589-4453-a268-219bb633748d",
    "providerId": "3552815d-6aca-43fc-ace8-0409ee3a762e",
    "titleEn": "Premium wedding album · 40 pages",
    "titleAr": "ألبوم زفاف فاخر · 40 صفحة",
    "categoryId": "7d3855dd-4bd3-430a-9ffc-09d4f269eb4a",
    "basePrice": "28000.00",
    "priceType": "per_event",
    "avgRating": "5.00",
    "ratingCount": 1,
    "ratingCounts": [
      1,
      0,
      0,
      0,
      0
    ],
    "bookingsCount": 2,
    "wilayas": [
      9
    ],
    "photos": [
      "pexels-photographie-3.webp",
      "pexels-photographie-4.webp",
      "pexels-photographie-5.webp"
    ],
    "descriptionEn": "Premium wedding album · 40 pages. Studio Lumière takes care of every detail, from the first call to the day itself. Send a request with your date and the provider confirms within 48 hours.",
    "descriptionAr": "ألبوم زفاف فاخر · 40 صفحة. يتكفّل Studio Lumière بكل التفاصيل، من أول اتصال حتى يوم المناسبة. أرسل طلبًا مع التاريخ وسيؤكد مقدّم الخدمة خلال 48 ساعة.",
    "cancellationEn": "Free cancellation up to 7 days before the event. After that, the deposit agreed with the provider is kept.",
    "cancellationAr": "إلغاء مجاني حتى 7 أيام قبل المناسبة. بعد ذلك يحتفظ مقدّم الخدمة بالعربون المتفق عليه.",
    "facts": [
      {
        "labelEn": "Team",
        "labelAr": "الفريق",
        "valueEn": "2 photographers",
        "valueAr": "مصوران"
      },
      {
        "labelEn": "Delivery",
        "labelAr": "التسليم",
        "valueEn": "3 weeks",
        "valueAr": "3 أسابيع"
      }
    ],
    "extras": [
      {
        "id": "d5fce8fc-5589-4453-a268-219bb633748d-x0",
        "nameEn": "Drone footage",
        "nameAr": "تصوير بالدرون",
        "price": "15000.00"
      },
      {
        "id": "d5fce8fc-5589-4453-a268-219bb633748d-x1",
        "nameEn": "Printed album",
        "nameAr": "ألبوم مطبوع",
        "price": "18000.00"
      }
    ],
    "maxGuests": null,
    "maxEventsPerDay": 2,
    "order": 8
  },
  {
    "id": "c26208fb-7edd-4941-b90d-770bad834434",
    "providerId": "fe9734e0-24c4-4640-ae2a-d07220ed3f5a",
    "titleEn": "Garden barbecue menu",
    "titleAr": "قائمة شواء في الحديقة",
    "categoryId": "d892155b-2c9b-4e0f-8fb5-db15b54af350",
    "basePrice": "2600.00",
    "priceType": "per_person",
    "avgRating": "5.00",
    "ratingCount": 2,
    "ratingCounts": [
      2,
      0,
      0,
      0,
      0
    ],
    "bookingsCount": 2,
    "wilayas": [
      9,
      42
    ],
    "photos": [
      "pexels-traiteur-2.webp",
      "pexels-traiteur-3.webp",
      "pexels-traiteur-4.webp"
    ],
    "descriptionEn": "Garden barbecue menu. Salle Les Oliviers takes care of every detail, from the first call to the day itself. Send a request with your date and the provider confirms within 48 hours.",
    "descriptionAr": "قائمة شواء في الحديقة. يتكفّل Salle Les Oliviers بكل التفاصيل، من أول اتصال حتى يوم المناسبة. أرسل طلبًا مع التاريخ وسيؤكد مقدّم الخدمة خلال 48 ساعة.",
    "cancellationEn": null,
    "cancellationAr": null,
    "facts": [
      {
        "labelEn": "Service staff",
        "labelAr": "طاقم الخدمة",
        "valueEn": "Included",
        "valueAr": "مشمول"
      },
      {
        "labelEn": "Menu tasting",
        "labelAr": "تذوق القائمة",
        "valueEn": "On request",
        "valueAr": "عند الطلب"
      }
    ],
    "extras": [
      {
        "id": "c26208fb-7edd-4941-b90d-770bad834434-x0",
        "nameEn": "Dessert buffet",
        "nameAr": "بوفيه حلويات",
        "price": "40000.00"
      }
    ],
    "maxGuests": 500,
    "maxEventsPerDay": 2,
    "order": 9
  },
  {
    "id": "d1f300e9-1950-4d28-b149-43b5eefb5f5c",
    "providerId": "3552815d-6aca-43fc-ace8-0409ee3a762e",
    "titleEn": "Cinematic wedding film",
    "titleAr": "فيلم زفاف سينمائي",
    "categoryId": "7d3855dd-4bd3-430a-9ffc-09d4f269eb4a",
    "basePrice": "90000.00",
    "priceType": "per_event",
    "avgRating": "5.00",
    "ratingCount": 1,
    "ratingCounts": [
      1,
      0,
      0,
      0,
      0
    ],
    "bookingsCount": 1,
    "wilayas": [
      9
    ],
    "photos": [
      "pexels-photographie-4.webp",
      "pexels-photographie-5.webp",
      "pexels-photographie-6.webp"
    ],
    "descriptionEn": "Cinematic wedding film. Studio Lumière takes care of every detail, from the first call to the day itself. Send a request with your date and the provider confirms within 48 hours.",
    "descriptionAr": "فيلم زفاف سينمائي. يتكفّل Studio Lumière بكل التفاصيل، من أول اتصال حتى يوم المناسبة. أرسل طلبًا مع التاريخ وسيؤكد مقدّم الخدمة خلال 48 ساعة.",
    "cancellationEn": "Free cancellation up to 7 days before the event. After that, the deposit agreed with the provider is kept.",
    "cancellationAr": "إلغاء مجاني حتى 7 أيام قبل المناسبة. بعد ذلك يحتفظ مقدّم الخدمة بالعربون المتفق عليه.",
    "facts": [
      {
        "labelEn": "Team",
        "labelAr": "الفريق",
        "valueEn": "2 photographers",
        "valueAr": "مصوران"
      },
      {
        "labelEn": "Delivery",
        "labelAr": "التسليم",
        "valueEn": "3 weeks",
        "valueAr": "3 أسابيع"
      }
    ],
    "extras": [
      {
        "id": "d1f300e9-1950-4d28-b149-43b5eefb5f5c-x0",
        "nameEn": "Drone footage",
        "nameAr": "تصوير بالدرون",
        "price": "15000.00"
      },
      {
        "id": "d1f300e9-1950-4d28-b149-43b5eefb5f5c-x1",
        "nameEn": "Printed album",
        "nameAr": "ألبوم مطبوع",
        "price": "18000.00"
      }
    ],
    "maxGuests": null,
    "maxEventsPerDay": 2,
    "order": 10
  },
  {
    "id": "c2aee393-049f-4db4-aa1a-74cff3c15efa",
    "providerId": "96a1f496-ffee-4a92-8204-76f8066a62e4",
    "titleEn": "Wedding car flowers",
    "titleAr": "زهور سيارة الزفاف",
    "categoryId": "0b52682c-4d00-49df-b18a-2c30c363a331",
    "basePrice": "9000.00",
    "priceType": "per_event",
    "avgRating": "5.00",
    "ratingCount": 1,
    "ratingCounts": [
      1,
      0,
      0,
      0,
      0
    ],
    "bookingsCount": 1,
    "wilayas": [
      16,
      42
    ],
    "photos": [
      "pexels-fleurs-1.webp",
      "pexels-fleurs-2.webp",
      "pexels-fleurs-3.webp"
    ],
    "descriptionEn": "Wedding car flowers. Flora Design takes care of every detail, from the first call to the day itself. Send a request with your date and the provider confirms within 48 hours.",
    "descriptionAr": "زهور سيارة الزفاف. يتكفّل Flora Design بكل التفاصيل، من أول اتصال حتى يوم المناسبة. أرسل طلبًا مع التاريخ وسيؤكد مقدّم الخدمة خلال 48 ساعة.",
    "cancellationEn": null,
    "cancellationAr": null,
    "facts": [
      {
        "labelEn": "Flowers",
        "labelAr": "الزهور",
        "valueEn": "Fresh, seasonal",
        "valueAr": "طازجة وموسمية"
      },
      {
        "labelEn": "Delivery",
        "labelAr": "التوصيل",
        "valueEn": "Included",
        "valueAr": "مشمول"
      }
    ],
    "extras": [
      {
        "id": "c2aee393-049f-4db4-aa1a-74cff3c15efa-x0",
        "nameEn": "Bridal bouquet",
        "nameAr": "باقة العروس",
        "price": "8000.00"
      }
    ],
    "maxGuests": null,
    "maxEventsPerDay": 2,
    "order": 11
  },
  {
    "id": "90639ce6-9ca2-472c-86d6-b514f7178564",
    "providerId": "c62532f4-6fa9-4752-9f82-cdbea4b0dd07",
    "titleEn": "Salle des fêtes · 400 guests",
    "titleAr": "قاعة الحفلات · 400 ضيف",
    "categoryId": "bb28c638-c0ea-4140-b9d9-fd5535a6c4b6",
    "basePrice": "420000.00",
    "priceType": "per_event",
    "avgRating": "5.00",
    "ratingCount": 1,
    "ratingCounts": [
      1,
      0,
      0,
      0,
      0
    ],
    "bookingsCount": 1,
    "wilayas": [
      9,
      16
    ],
    "photos": [
      "pexels-salles-des-fetes-3.webp",
      "pexels-salles-des-fetes-4.webp",
      "pexels-salles-des-fetes-5.webp"
    ],
    "descriptionEn": "Salle des fêtes · 400 guests. Salle Yasmine takes care of every detail, from the first call to the day itself. Send a request with your date and the provider confirms within 48 hours.",
    "descriptionAr": "قاعة الحفلات · 400 ضيف. يتكفّل Salle Yasmine بكل التفاصيل، من أول اتصال حتى يوم المناسبة. أرسل طلبًا مع التاريخ وسيؤكد مقدّم الخدمة خلال 48 ساعة.",
    "cancellationEn": "Free cancellation up to 7 days before the event. After that, the deposit agreed with the provider is kept.",
    "cancellationAr": "إلغاء مجاني حتى 7 أيام قبل المناسبة. بعد ذلك يحتفظ مقدّم الخدمة بالعربون المتفق عليه.",
    "facts": [
      {
        "labelEn": "Capacity",
        "labelAr": "السعة",
        "valueEn": "300 guests",
        "valueAr": "300 ضيف"
      },
      {
        "labelEn": "Parking",
        "labelAr": "موقف السيارات",
        "valueEn": "Available",
        "valueAr": "متوفر"
      }
    ],
    "extras": [
      {
        "id": "90639ce6-9ca2-472c-86d6-b514f7178564-x0",
        "nameEn": "Extra hour",
        "nameAr": "ساعة إضافية",
        "price": "20000.00"
      }
    ],
    "maxGuests": 300,
    "maxEventsPerDay": 1,
    "order": 12
  },
  {
    "id": "705e892f-6b77-4d2b-952c-f3ad5d38c9dd",
    "providerId": "de14bc74-7094-4e15-a1b9-3b1f50a5e607",
    "titleEn": "Photo booth with instant prints",
    "titleAr": "كشك تصوير مع طباعة فورية",
    "categoryId": "7d3855dd-4bd3-430a-9ffc-09d4f269eb4a",
    "basePrice": "30000.00",
    "priceType": "per_event",
    "avgRating": "5.00",
    "ratingCount": 1,
    "ratingCounts": [
      1,
      0,
      0,
      0,
      0
    ],
    "bookingsCount": 1,
    "wilayas": [
      9,
      16
    ],
    "photos": [
      "pexels-photographie-5.webp",
      "pexels-photographie-6.webp",
      "pexels-photographie-1.webp"
    ],
    "descriptionEn": "Photo booth with instant prints. Studio Yasmine Photo takes care of every detail, from the first call to the day itself. Send a request with your date and the provider confirms within 48 hours.",
    "descriptionAr": "كشك تصوير مع طباعة فورية. يتكفّل Studio Yasmine Photo بكل التفاصيل، من أول اتصال حتى يوم المناسبة. أرسل طلبًا مع التاريخ وسيؤكد مقدّم الخدمة خلال 48 ساعة.",
    "cancellationEn": null,
    "cancellationAr": null,
    "facts": [
      {
        "labelEn": "Team",
        "labelAr": "الفريق",
        "valueEn": "2 photographers",
        "valueAr": "مصوران"
      },
      {
        "labelEn": "Delivery",
        "labelAr": "التسليم",
        "valueEn": "3 weeks",
        "valueAr": "3 أسابيع"
      }
    ],
    "extras": [
      {
        "id": "705e892f-6b77-4d2b-952c-f3ad5d38c9dd-x0",
        "nameEn": "Drone footage",
        "nameAr": "تصوير بالدرون",
        "price": "15000.00"
      },
      {
        "id": "705e892f-6b77-4d2b-952c-f3ad5d38c9dd-x1",
        "nameEn": "Printed album",
        "nameAr": "ألبوم مطبوع",
        "price": "18000.00"
      }
    ],
    "maxGuests": null,
    "maxEventsPerDay": 2,
    "order": 13
  },
  {
    "id": "6435499e-1636-4f5c-8727-d66e26007062",
    "providerId": "6db77516-86a1-49ef-8b57-2c610c4e90ca",
    "titleEn": "Waiters & service team",
    "titleAr": "فريق النُدُل والخدمة",
    "categoryId": "d892155b-2c9b-4e0f-8fb5-db15b54af350",
    "basePrice": "6000.00",
    "priceType": "per_hour",
    "avgRating": "5.00",
    "ratingCount": 1,
    "ratingCounts": [
      1,
      0,
      0,
      0,
      0
    ],
    "bookingsCount": 1,
    "wilayas": [
      9,
      16,
      35
    ],
    "photos": [
      "pexels-traiteur-3.webp",
      "pexels-traiteur-4.webp",
      "pexels-traiteur-1.webp"
    ],
    "descriptionEn": "Waiters & service team. Traiteur El Djazair takes care of every detail, from the first call to the day itself. Send a request with your date and the provider confirms within 48 hours.",
    "descriptionAr": "فريق النُدُل والخدمة. يتكفّل Traiteur El Djazair بكل التفاصيل، من أول اتصال حتى يوم المناسبة. أرسل طلبًا مع التاريخ وسيؤكد مقدّم الخدمة خلال 48 ساعة.",
    "cancellationEn": "Free cancellation up to 7 days before the event. After that, the deposit agreed with the provider is kept.",
    "cancellationAr": "إلغاء مجاني حتى 7 أيام قبل المناسبة. بعد ذلك يحتفظ مقدّم الخدمة بالعربون المتفق عليه.",
    "facts": [
      {
        "labelEn": "Service staff",
        "labelAr": "طاقم الخدمة",
        "valueEn": "Included",
        "valueAr": "مشمول"
      },
      {
        "labelEn": "Menu tasting",
        "labelAr": "تذوق القائمة",
        "valueEn": "On request",
        "valueAr": "عند الطلب"
      }
    ],
    "extras": [
      {
        "id": "6435499e-1636-4f5c-8727-d66e26007062-x0",
        "nameEn": "Dessert buffet",
        "nameAr": "بوفيه حلويات",
        "price": "40000.00"
      }
    ],
    "maxGuests": 500,
    "maxEventsPerDay": 2,
    "order": 14
  },
  {
    "id": "6252a3b3-cd93-4126-ad2a-2010a598aaa8",
    "providerId": "c62532f4-6fa9-4752-9f82-cdbea4b0dd07",
    "titleEn": "Menu mariage traditionnel",
    "titleAr": "قائمة زفاف تقليدية",
    "categoryId": "d892155b-2c9b-4e0f-8fb5-db15b54af350",
    "basePrice": "2800.00",
    "priceType": "per_person",
    "avgRating": "5.00",
    "ratingCount": 1,
    "ratingCounts": [
      1,
      0,
      0,
      0,
      0
    ],
    "bookingsCount": 1,
    "wilayas": [
      9,
      16
    ],
    "photos": [
      "pexels-traiteur-4.webp",
      "pexels-traiteur-1.webp",
      "pexels-traiteur-2.webp"
    ],
    "descriptionEn": "Menu mariage traditionnel. Salle Yasmine takes care of every detail, from the first call to the day itself. Send a request with your date and the provider confirms within 48 hours.",
    "descriptionAr": "قائمة زفاف تقليدية. يتكفّل Salle Yasmine بكل التفاصيل، من أول اتصال حتى يوم المناسبة. أرسل طلبًا مع التاريخ وسيؤكد مقدّم الخدمة خلال 48 ساعة.",
    "cancellationEn": null,
    "cancellationAr": null,
    "facts": [
      {
        "labelEn": "Service staff",
        "labelAr": "طاقم الخدمة",
        "valueEn": "Included",
        "valueAr": "مشمول"
      },
      {
        "labelEn": "Menu tasting",
        "labelAr": "تذوق القائمة",
        "valueEn": "On request",
        "valueAr": "عند الطلب"
      }
    ],
    "extras": [
      {
        "id": "6252a3b3-cd93-4126-ad2a-2010a598aaa8-x0",
        "nameEn": "Dessert buffet",
        "nameAr": "بوفيه حلويات",
        "price": "40000.00"
      }
    ],
    "maxGuests": 500,
    "maxEventsPerDay": 2,
    "order": 15
  },
  {
    "id": "4e36825b-6108-4dc6-b126-fede7832abee",
    "providerId": "fe9734e0-24c4-4640-ae2a-d07220ed3f5a",
    "titleEn": "Fairy lights & lanterns",
    "titleAr": "أضواء وفوانيس",
    "categoryId": "9ec8cbe5-ead7-42b4-99d1-fccc49fdad50",
    "basePrice": "35000.00",
    "priceType": "per_event",
    "avgRating": "5.00",
    "ratingCount": 1,
    "ratingCounts": [
      1,
      0,
      0,
      0,
      0
    ],
    "bookingsCount": 1,
    "wilayas": [
      9,
      42
    ],
    "photos": [
      "pexels-decoration-1.webp",
      "pexels-decoration-2.webp",
      "pexels-decoration-3.webp"
    ],
    "descriptionEn": "Fairy lights & lanterns. Salle Les Oliviers takes care of every detail, from the first call to the day itself. Send a request with your date and the provider confirms within 48 hours.",
    "descriptionAr": "أضواء وفوانيس. يتكفّل Salle Les Oliviers بكل التفاصيل، من أول اتصال حتى يوم المناسبة. أرسل طلبًا مع التاريخ وسيؤكد مقدّم الخدمة خلال 48 ساعة.",
    "cancellationEn": "Free cancellation up to 7 days before the event. After that, the deposit agreed with the provider is kept.",
    "cancellationAr": "إلغاء مجاني حتى 7 أيام قبل المناسبة. بعد ذلك يحتفظ مقدّم الخدمة بالعربون المتفق عليه.",
    "facts": [
      {
        "labelEn": "Setup",
        "labelAr": "التركيب",
        "valueEn": "The day before",
        "valueAr": "قبل يوم"
      },
      {
        "labelEn": "Style",
        "labelAr": "الأسلوب",
        "valueEn": "Made to measure",
        "valueAr": "حسب الطلب"
      }
    ],
    "extras": [
      {
        "id": "4e36825b-6108-4dc6-b126-fede7832abee-x0",
        "nameEn": "Lighting",
        "nameAr": "الإضاءة",
        "price": "12000.00"
      }
    ],
    "maxGuests": null,
    "maxEventsPerDay": 2,
    "order": 16
  },
  {
    "id": "4653dbbe-2577-4e63-88b1-2249de4a0b00",
    "providerId": "874ec054-c8d1-4c70-810c-52c9debac14f",
    "titleEn": "Zorna & bendir procession",
    "titleAr": "موكب الزرنة والبندير",
    "categoryId": "601c07e5-d2c8-4619-bbb4-bbb546803413",
    "basePrice": "40000.00",
    "priceType": "per_event",
    "avgRating": "5.00",
    "ratingCount": 1,
    "ratingCounts": [
      1,
      0,
      0,
      0,
      0
    ],
    "bookingsCount": 1,
    "wilayas": [
      19,
      25
    ],
    "photos": [
      "pexels-musique-dj-2.webp",
      "pexels-musique-dj-3.webp",
      "pexels-musique-dj-4.webp"
    ],
    "descriptionEn": "Zorna & bendir procession. Orchestre Andalou takes care of every detail, from the first call to the day itself. Send a request with your date and the provider confirms within 48 hours.",
    "descriptionAr": "موكب الزرنة والبندير. يتكفّل Orchestre Andalou بكل التفاصيل، من أول اتصال حتى يوم المناسبة. أرسل طلبًا مع التاريخ وسيؤكد مقدّم الخدمة خلال 48 ساعة.",
    "cancellationEn": null,
    "cancellationAr": null,
    "facts": [
      {
        "labelEn": "Band",
        "labelAr": "الفرقة",
        "valueEn": "6 musicians",
        "valueAr": "6 عازفين"
      },
      {
        "labelEn": "Duration",
        "labelAr": "المدة",
        "valueEn": "4 hours",
        "valueAr": "4 ساعات"
      }
    ],
    "extras": [
      {
        "id": "4653dbbe-2577-4e63-88b1-2249de4a0b00-x0",
        "nameEn": "Extra hour",
        "nameAr": "ساعة إضافية",
        "price": "15000.00"
      }
    ],
    "maxGuests": null,
    "maxEventsPerDay": 2,
    "order": 17
  },
  {
    "id": "40e36160-7691-4cc4-9a80-150d610b1f5e",
    "providerId": "94305376-287a-4966-9546-8c3afd247e88",
    "titleEn": "White & gold hall decoration",
    "titleAr": "تزيين القاعة بالأبيض والذهبي",
    "categoryId": "9ec8cbe5-ead7-42b4-99d1-fccc49fdad50",
    "basePrice": "70000.00",
    "priceType": "per_event",
    "avgRating": "5.00",
    "ratingCount": 1,
    "ratingCounts": [
      1,
      0,
      0,
      0,
      0
    ],
    "bookingsCount": 1,
    "wilayas": [
      31
    ],
    "photos": [
      "pexels-decoration-2.webp",
      "pexels-decoration-3.webp",
      "pexels-decoration-4.webp"
    ],
    "descriptionEn": "White & gold hall decoration. Salle El Bahia takes care of every detail, from the first call to the day itself. Send a request with your date and the provider confirms within 48 hours.",
    "descriptionAr": "تزيين القاعة بالأبيض والذهبي. يتكفّل Salle El Bahia بكل التفاصيل، من أول اتصال حتى يوم المناسبة. أرسل طلبًا مع التاريخ وسيؤكد مقدّم الخدمة خلال 48 ساعة.",
    "cancellationEn": "Free cancellation up to 7 days before the event. After that, the deposit agreed with the provider is kept.",
    "cancellationAr": "إلغاء مجاني حتى 7 أيام قبل المناسبة. بعد ذلك يحتفظ مقدّم الخدمة بالعربون المتفق عليه.",
    "facts": [
      {
        "labelEn": "Setup",
        "labelAr": "التركيب",
        "valueEn": "The day before",
        "valueAr": "قبل يوم"
      },
      {
        "labelEn": "Style",
        "labelAr": "الأسلوب",
        "valueEn": "Made to measure",
        "valueAr": "حسب الطلب"
      }
    ],
    "extras": [
      {
        "id": "40e36160-7691-4cc4-9a80-150d610b1f5e-x0",
        "nameEn": "Lighting",
        "nameAr": "الإضاءة",
        "price": "12000.00"
      }
    ],
    "maxGuests": null,
    "maxEventsPerDay": 2,
    "order": 18
  },
  {
    "id": "2dc38173-ec66-44b6-88d7-3129333be9ee",
    "providerId": "94991c78-a5b7-4c3d-8aa6-a7fefcb75d64",
    "titleEn": "Balloon decoration for birthdays",
    "titleAr": "تزيين أعياد الميلاد بالبالونات",
    "categoryId": "9ec8cbe5-ead7-42b4-99d1-fccc49fdad50",
    "basePrice": "15000.00",
    "priceType": "per_event",
    "avgRating": "5.00",
    "ratingCount": 1,
    "ratingCounts": [
      1,
      0,
      0,
      0,
      0
    ],
    "bookingsCount": 1,
    "wilayas": [
      31
    ],
    "photos": [
      "pexels-decoration-3.webp",
      "pexels-decoration-4.webp",
      "pexels-decoration-1.webp"
    ],
    "descriptionEn": "Balloon decoration for birthdays. Rym Events Déco takes care of every detail, from the first call to the day itself. Send a request with your date and the provider confirms within 48 hours.",
    "descriptionAr": "تزيين أعياد الميلاد بالبالونات. يتكفّل Rym Events Déco بكل التفاصيل، من أول اتصال حتى يوم المناسبة. أرسل طلبًا مع التاريخ وسيؤكد مقدّم الخدمة خلال 48 ساعة.",
    "cancellationEn": null,
    "cancellationAr": null,
    "facts": [
      {
        "labelEn": "Setup",
        "labelAr": "التركيب",
        "valueEn": "The day before",
        "valueAr": "قبل يوم"
      },
      {
        "labelEn": "Style",
        "labelAr": "الأسلوب",
        "valueEn": "Made to measure",
        "valueAr": "حسب الطلب"
      }
    ],
    "extras": [
      {
        "id": "2dc38173-ec66-44b6-88d7-3129333be9ee-x0",
        "nameEn": "Lighting",
        "nameAr": "الإضاءة",
        "price": "12000.00"
      }
    ],
    "maxGuests": null,
    "maxEventsPerDay": 2,
    "order": 19
  },
  {
    "id": "163eb765-5339-4ce3-9a1e-120ecb18552c",
    "providerId": "94991c78-a5b7-4c3d-8aa6-a7fefcb75d64",
    "titleEn": "Corporate event stage",
    "titleAr": "منصة فعاليات الشركات",
    "categoryId": "9ec8cbe5-ead7-42b4-99d1-fccc49fdad50",
    "basePrice": "90000.00",
    "priceType": "on_quote",
    "avgRating": "4.75",
    "ratingCount": 4,
    "ratingCounts": [
      3,
      1,
      0,
      0,
      0
    ],
    "bookingsCount": 5,
    "wilayas": [
      31
    ],
    "photos": [
      "pexels-decoration-4.webp",
      "pexels-decoration-1.webp",
      "pexels-decoration-2.webp"
    ],
    "descriptionEn": "Corporate event stage. Rym Events Déco takes care of every detail, from the first call to the day itself. Send a request with your date and the provider confirms within 48 hours.",
    "descriptionAr": "منصة فعاليات الشركات. يتكفّل Rym Events Déco بكل التفاصيل، من أول اتصال حتى يوم المناسبة. أرسل طلبًا مع التاريخ وسيؤكد مقدّم الخدمة خلال 48 ساعة.",
    "cancellationEn": "Free cancellation up to 7 days before the event. After that, the deposit agreed with the provider is kept.",
    "cancellationAr": "إلغاء مجاني حتى 7 أيام قبل المناسبة. بعد ذلك يحتفظ مقدّم الخدمة بالعربون المتفق عليه.",
    "facts": [
      {
        "labelEn": "Setup",
        "labelAr": "التركيب",
        "valueEn": "The day before",
        "valueAr": "قبل يوم"
      },
      {
        "labelEn": "Style",
        "labelAr": "الأسلوب",
        "valueEn": "Made to measure",
        "valueAr": "حسب الطلب"
      }
    ],
    "extras": [
      {
        "id": "163eb765-5339-4ce3-9a1e-120ecb18552c-x0",
        "nameEn": "Lighting",
        "nameAr": "الإضاءة",
        "price": "12000.00"
      }
    ],
    "maxGuests": null,
    "maxEventsPerDay": 2,
    "order": 20
  },
  {
    "id": "6a3014a4-fa28-474a-9acf-d1369a2b8ed1",
    "providerId": "a08cde8f-1369-492a-8dd3-8187341af983",
    "titleEn": "Guest shuttle · 30 seats",
    "titleAr": "حافلة نقل الضيوف · 30 مقعدًا",
    "categoryId": "3b472770-bd00-44ce-b2cc-a1dba7b327c5",
    "basePrice": "25000.00",
    "priceType": "per_day",
    "avgRating": "4.60",
    "ratingCount": 5,
    "ratingCounts": [
      3,
      2,
      0,
      0,
      0
    ],
    "bookingsCount": 5,
    "wilayas": [
      9,
      16
    ],
    "photos": [
      "pexels-transport-1.webp",
      "pexels-transport-2.webp",
      "pexels-transport-3.webp"
    ],
    "descriptionEn": "Guest shuttle · 30 seats. Limousine Prestige takes care of every detail, from the first call to the day itself. Send a request with your date and the provider confirms within 48 hours.",
    "descriptionAr": "حافلة نقل الضيوف · 30 مقعدًا. يتكفّل Limousine Prestige بكل التفاصيل، من أول اتصال حتى يوم المناسبة. أرسل طلبًا مع التاريخ وسيؤكد مقدّم الخدمة خلال 48 ساعة.",
    "cancellationEn": null,
    "cancellationAr": null,
    "facts": [
      {
        "labelEn": "Driver",
        "labelAr": "السائق",
        "valueEn": "Included",
        "valueAr": "مشمول"
      },
      {
        "labelEn": "Decoration",
        "labelAr": "التزيين",
        "valueEn": "Ribbons and flowers",
        "valueAr": "شرائط وزهور"
      }
    ],
    "extras": [
      {
        "id": "6a3014a4-fa28-474a-9acf-d1369a2b8ed1-x0",
        "nameEn": "Extra hour",
        "nameAr": "ساعة إضافية",
        "price": "5000.00"
      }
    ],
    "maxGuests": null,
    "maxEventsPerDay": 2,
    "order": 21
  },
  {
    "id": "ebfa4d7c-60c5-4003-abbf-578bc9432b43",
    "providerId": "6db77516-86a1-49ef-8b57-2c610c4e90ca",
    "titleEn": "Corporate lunch boxes",
    "titleAr": "وجبات غداء للشركات",
    "categoryId": "d892155b-2c9b-4e0f-8fb5-db15b54af350",
    "basePrice": "1200.00",
    "priceType": "per_person",
    "avgRating": "4.50",
    "ratingCount": 2,
    "ratingCounts": [
      1,
      1,
      0,
      0,
      0
    ],
    "bookingsCount": 3,
    "wilayas": [
      9,
      16,
      35
    ],
    "photos": [
      "pexels-traiteur-1.webp",
      "pexels-traiteur-2.webp",
      "pexels-traiteur-3.webp"
    ],
    "descriptionEn": "Corporate lunch boxes. Traiteur El Djazair takes care of every detail, from the first call to the day itself. Send a request with your date and the provider confirms within 48 hours.",
    "descriptionAr": "وجبات غداء للشركات. يتكفّل Traiteur El Djazair بكل التفاصيل، من أول اتصال حتى يوم المناسبة. أرسل طلبًا مع التاريخ وسيؤكد مقدّم الخدمة خلال 48 ساعة.",
    "cancellationEn": "Free cancellation up to 7 days before the event. After that, the deposit agreed with the provider is kept.",
    "cancellationAr": "إلغاء مجاني حتى 7 أيام قبل المناسبة. بعد ذلك يحتفظ مقدّم الخدمة بالعربون المتفق عليه.",
    "facts": [
      {
        "labelEn": "Service staff",
        "labelAr": "طاقم الخدمة",
        "valueEn": "Included",
        "valueAr": "مشمول"
      },
      {
        "labelEn": "Menu tasting",
        "labelAr": "تذوق القائمة",
        "valueEn": "On request",
        "valueAr": "عند الطلب"
      }
    ],
    "extras": [
      {
        "id": "ebfa4d7c-60c5-4003-abbf-578bc9432b43-x0",
        "nameEn": "Dessert buffet",
        "nameAr": "بوفيه حلويات",
        "price": "40000.00"
      }
    ],
    "maxGuests": 500,
    "maxEventsPerDay": 2,
    "order": 22
  },
  {
    "id": "d16b52eb-1653-4752-8e74-6a89dcb53350",
    "providerId": "fe9734e0-24c4-4640-ae2a-d07220ed3f5a",
    "titleEn": "Garden venue among olive trees",
    "titleAr": "حديقة بين أشجار الزيتون",
    "categoryId": "bb28c638-c0ea-4140-b9d9-fd5535a6c4b6",
    "basePrice": "300000.00",
    "priceType": "per_event",
    "avgRating": "4.50",
    "ratingCount": 2,
    "ratingCounts": [
      1,
      1,
      0,
      0,
      0
    ],
    "bookingsCount": 2,
    "wilayas": [
      9,
      42
    ],
    "photos": [
      "pexels-salles-des-fetes-4.webp",
      "pexels-salles-des-fetes-5.webp",
      "pexels-salles-des-fetes-6.webp"
    ],
    "descriptionEn": "Garden venue among olive trees. Salle Les Oliviers takes care of every detail, from the first call to the day itself. Send a request with your date and the provider confirms within 48 hours.",
    "descriptionAr": "حديقة بين أشجار الزيتون. يتكفّل Salle Les Oliviers بكل التفاصيل، من أول اتصال حتى يوم المناسبة. أرسل طلبًا مع التاريخ وسيؤكد مقدّم الخدمة خلال 48 ساعة.",
    "cancellationEn": null,
    "cancellationAr": null,
    "facts": [
      {
        "labelEn": "Capacity",
        "labelAr": "السعة",
        "valueEn": "300 guests",
        "valueAr": "300 ضيف"
      },
      {
        "labelEn": "Parking",
        "labelAr": "موقف السيارات",
        "valueEn": "Available",
        "valueAr": "متوفر"
      }
    ],
    "extras": [
      {
        "id": "d16b52eb-1653-4752-8e74-6a89dcb53350-x0",
        "nameEn": "Extra hour",
        "nameAr": "ساعة إضافية",
        "price": "20000.00"
      }
    ],
    "maxGuests": 300,
    "maxEventsPerDay": 1,
    "order": 23
  },
  {
    "id": "1d46f321-b687-4b4c-a94c-5919e34a0e57",
    "providerId": "aebed654-e28b-4191-8ec2-531031ca3314",
    "titleEn": "Baklava & makrout trays",
    "titleAr": "صواني البقلاوة والمقروط",
    "categoryId": "137d6aeb-8aa1-4c3e-a9cd-ca5a67c4e1d1",
    "basePrice": "14000.00",
    "priceType": "per_event",
    "avgRating": "4.50",
    "ratingCount": 2,
    "ratingCounts": [
      1,
      1,
      0,
      0,
      0
    ],
    "bookingsCount": 2,
    "wilayas": [
      16
    ],
    "photos": [
      "pexels-gateaux-patisserie-3.webp",
      "pexels-gateaux-patisserie-4.webp",
      "pexels-gateaux-patisserie-5.webp"
    ],
    "descriptionEn": "Baklava & makrout trays. Pâtisserie Meriem takes care of every detail, from the first call to the day itself. Send a request with your date and the provider confirms within 48 hours.",
    "descriptionAr": "صواني البقلاوة والمقروط. يتكفّل Pâtisserie Meriem بكل التفاصيل، من أول اتصال حتى يوم المناسبة. أرسل طلبًا مع التاريخ وسيؤكد مقدّم الخدمة خلال 48 ساعة.",
    "cancellationEn": "Free cancellation up to 7 days before the event. After that, the deposit agreed with the provider is kept.",
    "cancellationAr": "إلغاء مجاني حتى 7 أيام قبل المناسبة. بعد ذلك يحتفظ مقدّم الخدمة بالعربون المتفق عليه.",
    "facts": [
      {
        "labelEn": "Tasting",
        "labelAr": "التذوق",
        "valueEn": "Free",
        "valueAr": "مجاني"
      },
      {
        "labelEn": "Order",
        "labelAr": "الطلب",
        "valueEn": "2 weeks ahead",
        "valueAr": "قبل أسبوعين"
      }
    ],
    "extras": [
      {
        "id": "1d46f321-b687-4b4c-a94c-5919e34a0e57-x0",
        "nameEn": "Tasting box",
        "nameAr": "علبة تذوق",
        "price": "3000.00"
      }
    ],
    "maxGuests": null,
    "maxEventsPerDay": 2,
    "order": 24
  },
  {
    "id": "3a8ad056-300b-4914-939b-35fd59a0ada1",
    "providerId": "96a1f496-ffee-4a92-8204-76f8066a62e4",
    "titleEn": "Table centrepieces · 20 tables",
    "titleAr": "تنسيقات الطاولات · 20 طاولة",
    "categoryId": "0b52682c-4d00-49df-b18a-2c30c363a331",
    "basePrice": "60000.00",
    "priceType": "per_event",
    "avgRating": "4.33",
    "ratingCount": 3,
    "ratingCounts": [
      1,
      2,
      0,
      0,
      0
    ],
    "bookingsCount": 4,
    "wilayas": [
      16,
      42
    ],
    "photos": [
      "pexels-fleurs-2.webp",
      "pexels-fleurs-3.webp",
      "pexels-fleurs-4.webp"
    ],
    "descriptionEn": "Table centrepieces · 20 tables. Flora Design takes care of every detail, from the first call to the day itself. Send a request with your date and the provider confirms within 48 hours.",
    "descriptionAr": "تنسيقات الطاولات · 20 طاولة. يتكفّل Flora Design بكل التفاصيل، من أول اتصال حتى يوم المناسبة. أرسل طلبًا مع التاريخ وسيؤكد مقدّم الخدمة خلال 48 ساعة.",
    "cancellationEn": null,
    "cancellationAr": null,
    "facts": [
      {
        "labelEn": "Flowers",
        "labelAr": "الزهور",
        "valueEn": "Fresh, seasonal",
        "valueAr": "طازجة وموسمية"
      },
      {
        "labelEn": "Delivery",
        "labelAr": "التوصيل",
        "valueEn": "Included",
        "valueAr": "مشمول"
      }
    ],
    "extras": [
      {
        "id": "3a8ad056-300b-4914-939b-35fd59a0ada1-x0",
        "nameEn": "Bridal bouquet",
        "nameAr": "باقة العروس",
        "price": "8000.00"
      }
    ],
    "maxGuests": null,
    "maxEventsPerDay": 2,
    "order": 25
  },
  {
    "id": "b15c4ecc-6ada-4da7-85b2-684aeefaa4fa",
    "providerId": "c62532f4-6fa9-4752-9f82-cdbea4b0dd07",
    "titleEn": "Décor floral cérémonie",
    "titleAr": "ديكور زهور الحفل",
    "categoryId": "9ec8cbe5-ead7-42b4-99d1-fccc49fdad50",
    "basePrice": "65000.00",
    "priceType": "per_event",
    "avgRating": "4.33",
    "ratingCount": 3,
    "ratingCounts": [
      1,
      2,
      0,
      0,
      0
    ],
    "bookingsCount": 3,
    "wilayas": [
      9,
      16
    ],
    "photos": [
      "pexels-decoration-1.webp",
      "pexels-decoration-2.webp",
      "pexels-decoration-3.webp"
    ],
    "descriptionEn": "Décor floral cérémonie. Salle Yasmine takes care of every detail, from the first call to the day itself. Send a request with your date and the provider confirms within 48 hours.",
    "descriptionAr": "ديكور زهور الحفل. يتكفّل Salle Yasmine بكل التفاصيل، من أول اتصال حتى يوم المناسبة. أرسل طلبًا مع التاريخ وسيؤكد مقدّم الخدمة خلال 48 ساعة.",
    "cancellationEn": "Free cancellation up to 7 days before the event. After that, the deposit agreed with the provider is kept.",
    "cancellationAr": "إلغاء مجاني حتى 7 أيام قبل المناسبة. بعد ذلك يحتفظ مقدّم الخدمة بالعربون المتفق عليه.",
    "facts": [
      {
        "labelEn": "Setup",
        "labelAr": "التركيب",
        "valueEn": "The day before",
        "valueAr": "قبل يوم"
      },
      {
        "labelEn": "Style",
        "labelAr": "الأسلوب",
        "valueEn": "Made to measure",
        "valueAr": "حسب الطلب"
      }
    ],
    "extras": [
      {
        "id": "b15c4ecc-6ada-4da7-85b2-684aeefaa4fa-x0",
        "nameEn": "Lighting",
        "nameAr": "الإضاءة",
        "price": "12000.00"
      }
    ],
    "maxGuests": null,
    "maxEventsPerDay": 2,
    "order": 26
  },
  {
    "id": "0eee6a75-2bc2-4a7c-a150-2377eddad5e0",
    "providerId": "6db77516-86a1-49ef-8b57-2c610c4e90ca",
    "titleEn": "Henna night dinner",
    "titleAr": "عشاء ليلة الحناء",
    "categoryId": "d892155b-2c9b-4e0f-8fb5-db15b54af350",
    "basePrice": "2200.00",
    "priceType": "per_person",
    "avgRating": "4.33",
    "ratingCount": 3,
    "ratingCounts": [
      1,
      2,
      0,
      0,
      0
    ],
    "bookingsCount": 3,
    "wilayas": [
      9
    ],
    "photos": [
      "pexels-traiteur-2.webp",
      "pexels-traiteur-3.webp",
      "pexels-traiteur-4.webp"
    ],
    "descriptionEn": "Henna night dinner. Traiteur El Djazair takes care of every detail, from the first call to the day itself. Send a request with your date and the provider confirms within 48 hours.",
    "descriptionAr": "عشاء ليلة الحناء. يتكفّل Traiteur El Djazair بكل التفاصيل، من أول اتصال حتى يوم المناسبة. أرسل طلبًا مع التاريخ وسيؤكد مقدّم الخدمة خلال 48 ساعة.",
    "cancellationEn": null,
    "cancellationAr": null,
    "facts": [
      {
        "labelEn": "Service staff",
        "labelAr": "طاقم الخدمة",
        "valueEn": "Included",
        "valueAr": "مشمول"
      },
      {
        "labelEn": "Menu tasting",
        "labelAr": "تذوق القائمة",
        "valueEn": "On request",
        "valueAr": "عند الطلب"
      }
    ],
    "extras": [
      {
        "id": "0eee6a75-2bc2-4a7c-a150-2377eddad5e0-x0",
        "nameEn": "Dessert buffet",
        "nameAr": "بوفيه حلويات",
        "price": "40000.00"
      }
    ],
    "maxGuests": 500,
    "maxEventsPerDay": 2,
    "order": 27
  },
  {
    "id": "729626dc-a7c5-45e8-ba3a-32d34bfb24fa",
    "providerId": "e1ad2116-c6a2-4d3f-a9ea-c4168694f925",
    "titleEn": "Birthday cake · 3 tiers",
    "titleAr": "كعكة عيد ميلاد · 3 طبقات",
    "categoryId": "137d6aeb-8aa1-4c3e-a9cd-ca5a67c4e1d1",
    "basePrice": "15000.00",
    "priceType": "per_event",
    "avgRating": "4.00",
    "ratingCount": 2,
    "ratingCounts": [
      0,
      2,
      0,
      0,
      0
    ],
    "bookingsCount": 2,
    "wilayas": [
      27,
      31
    ],
    "photos": [
      "pexels-gateaux-patisserie-4.webp",
      "pexels-gateaux-patisserie-5.webp",
      "pexels-gateaux-patisserie-6.webp"
    ],
    "descriptionEn": "Birthday cake · 3 tiers. Douceurs d'Oran takes care of every detail, from the first call to the day itself. Send a request with your date and the provider confirms within 48 hours.",
    "descriptionAr": "كعكة عيد ميلاد · 3 طبقات. يتكفّل Douceurs d'Oran بكل التفاصيل، من أول اتصال حتى يوم المناسبة. أرسل طلبًا مع التاريخ وسيؤكد مقدّم الخدمة خلال 48 ساعة.",
    "cancellationEn": "Free cancellation up to 7 days before the event. After that, the deposit agreed with the provider is kept.",
    "cancellationAr": "إلغاء مجاني حتى 7 أيام قبل المناسبة. بعد ذلك يحتفظ مقدّم الخدمة بالعربون المتفق عليه.",
    "facts": [
      {
        "labelEn": "Tasting",
        "labelAr": "التذوق",
        "valueEn": "Free",
        "valueAr": "مجاني"
      },
      {
        "labelEn": "Order",
        "labelAr": "الطلب",
        "valueEn": "2 weeks ahead",
        "valueAr": "قبل أسبوعين"
      }
    ],
    "extras": [
      {
        "id": "729626dc-a7c5-45e8-ba3a-32d34bfb24fa-x0",
        "nameEn": "Tasting box",
        "nameAr": "علبة تذوق",
        "price": "3000.00"
      }
    ],
    "maxGuests": null,
    "maxEventsPerDay": 2,
    "order": 28
  },
  {
    "id": "5f051263-678e-46c0-81fe-5a6cce582a0c",
    "providerId": "94305376-287a-4966-9546-8c3afd247e88",
    "titleEn": "Terrace for engagements",
    "titleAr": "تراس لحفلات الخطوبة",
    "categoryId": "bb28c638-c0ea-4140-b9d9-fd5535a6c4b6",
    "basePrice": "150000.00",
    "priceType": "per_event",
    "avgRating": "4.00",
    "ratingCount": 2,
    "ratingCounts": [
      0,
      2,
      0,
      0,
      0
    ],
    "bookingsCount": 2,
    "wilayas": [
      31
    ],
    "photos": [
      "pexels-salles-des-fetes-5.webp",
      "pexels-salles-des-fetes-6.webp",
      "pexels-salles-des-fetes-1.webp"
    ],
    "descriptionEn": "Terrace for engagements. Salle El Bahia takes care of every detail, from the first call to the day itself. Send a request with your date and the provider confirms within 48 hours.",
    "descriptionAr": "تراس لحفلات الخطوبة. يتكفّل Salle El Bahia بكل التفاصيل، من أول اتصال حتى يوم المناسبة. أرسل طلبًا مع التاريخ وسيؤكد مقدّم الخدمة خلال 48 ساعة.",
    "cancellationEn": null,
    "cancellationAr": null,
    "facts": [
      {
        "labelEn": "Capacity",
        "labelAr": "السعة",
        "valueEn": "300 guests",
        "valueAr": "300 ضيف"
      },
      {
        "labelEn": "Parking",
        "labelAr": "موقف السيارات",
        "valueEn": "Available",
        "valueAr": "متوفر"
      }
    ],
    "extras": [
      {
        "id": "5f051263-678e-46c0-81fe-5a6cce582a0c-x0",
        "nameEn": "Extra hour",
        "nameAr": "ساعة إضافية",
        "price": "20000.00"
      }
    ],
    "maxGuests": 300,
    "maxEventsPerDay": 1,
    "order": 29
  },
  {
    "id": "2a3eddf1-8fc8-4d2a-97db-374f313d65ff",
    "providerId": "de14bc74-7094-4e15-a1b9-3b1f50a5e607",
    "titleEn": "Bride getting-ready session",
    "titleAr": "جلسة تحضير العروس",
    "categoryId": "7d3855dd-4bd3-430a-9ffc-09d4f269eb4a",
    "basePrice": "25000.00",
    "priceType": "per_event",
    "avgRating": "4.00",
    "ratingCount": 1,
    "ratingCounts": [
      0,
      1,
      0,
      0,
      0
    ],
    "bookingsCount": 2,
    "wilayas": [
      9
    ],
    "photos": [
      "pexels-photographie-6.webp",
      "pexels-photographie-1.webp",
      "pexels-photographie-2.webp"
    ],
    "descriptionEn": "Bride getting-ready session. Studio Yasmine Photo takes care of every detail, from the first call to the day itself. Send a request with your date and the provider confirms within 48 hours.",
    "descriptionAr": "جلسة تحضير العروس. يتكفّل Studio Yasmine Photo بكل التفاصيل، من أول اتصال حتى يوم المناسبة. أرسل طلبًا مع التاريخ وسيؤكد مقدّم الخدمة خلال 48 ساعة.",
    "cancellationEn": "Free cancellation up to 7 days before the event. After that, the deposit agreed with the provider is kept.",
    "cancellationAr": "إلغاء مجاني حتى 7 أيام قبل المناسبة. بعد ذلك يحتفظ مقدّم الخدمة بالعربون المتفق عليه.",
    "facts": [
      {
        "labelEn": "Team",
        "labelAr": "الفريق",
        "valueEn": "2 photographers",
        "valueAr": "مصوران"
      },
      {
        "labelEn": "Delivery",
        "labelAr": "التسليم",
        "valueEn": "3 weeks",
        "valueAr": "3 أسابيع"
      }
    ],
    "extras": [
      {
        "id": "2a3eddf1-8fc8-4d2a-97db-374f313d65ff-x0",
        "nameEn": "Drone footage",
        "nameAr": "تصوير بالدرون",
        "price": "15000.00"
      },
      {
        "id": "2a3eddf1-8fc8-4d2a-97db-374f313d65ff-x1",
        "nameEn": "Printed album",
        "nameAr": "ألبوم مطبوع",
        "price": "18000.00"
      }
    ],
    "maxGuests": null,
    "maxEventsPerDay": 2,
    "order": 30
  },
  {
    "id": "ffdbb58f-f387-4eb0-8fe3-841a6ba886bf",
    "providerId": "de14bc74-7094-4e15-a1b9-3b1f50a5e607",
    "titleEn": "Henna night photography (women team)",
    "titleAr": "تصوير ليلة الحناء (فريق نسائي)",
    "categoryId": "7d3855dd-4bd3-430a-9ffc-09d4f269eb4a",
    "basePrice": "40000.00",
    "priceType": "per_event",
    "avgRating": "2.00",
    "ratingCount": 1,
    "ratingCounts": [
      0,
      0,
      0,
      1,
      0
    ],
    "bookingsCount": 2,
    "wilayas": [
      9,
      16
    ],
    "photos": [
      "pexels-photographie-1.webp",
      "pexels-photographie-2.webp",
      "pexels-photographie-3.webp"
    ],
    "descriptionEn": "Henna night photography (women team). Studio Yasmine Photo takes care of every detail, from the first call to the day itself. Send a request with your date and the provider confirms within 48 hours.",
    "descriptionAr": "تصوير ليلة الحناء (فريق نسائي). يتكفّل Studio Yasmine Photo بكل التفاصيل، من أول اتصال حتى يوم المناسبة. أرسل طلبًا مع التاريخ وسيؤكد مقدّم الخدمة خلال 48 ساعة.",
    "cancellationEn": null,
    "cancellationAr": null,
    "facts": [
      {
        "labelEn": "Team",
        "labelAr": "الفريق",
        "valueEn": "2 photographers",
        "valueAr": "مصوران"
      },
      {
        "labelEn": "Delivery",
        "labelAr": "التسليم",
        "valueEn": "3 weeks",
        "valueAr": "3 أسابيع"
      }
    ],
    "extras": [
      {
        "id": "ffdbb58f-f387-4eb0-8fe3-841a6ba886bf-x0",
        "nameEn": "Drone footage",
        "nameAr": "تصوير بالدرون",
        "price": "15000.00"
      },
      {
        "id": "ffdbb58f-f387-4eb0-8fe3-841a6ba886bf-x1",
        "nameEn": "Printed album",
        "nameAr": "ألبوم مطبوع",
        "price": "18000.00"
      }
    ],
    "maxGuests": null,
    "maxEventsPerDay": 2,
    "order": 31
  },
  {
    "id": "b1f3b1e5-a9e3-41f8-9b6d-6b4aff9cf33a",
    "providerId": "96a1f496-ffee-4a92-8204-76f8066a62e4",
    "titleEn": "Ceremony flower arch",
    "titleAr": "قوس الزهور للحفل",
    "categoryId": "0b52682c-4d00-49df-b18a-2c30c363a331",
    "basePrice": "48000.00",
    "priceType": "per_event",
    "avgRating": "2.00",
    "ratingCount": 1,
    "ratingCounts": [
      0,
      0,
      0,
      1,
      0
    ],
    "bookingsCount": 1,
    "wilayas": [
      16,
      42
    ],
    "photos": [
      "pexels-fleurs-3.webp",
      "pexels-fleurs-4.webp",
      "pexels-fleurs-1.webp"
    ],
    "descriptionEn": "Ceremony flower arch. Flora Design takes care of every detail, from the first call to the day itself. Send a request with your date and the provider confirms within 48 hours.",
    "descriptionAr": "قوس الزهور للحفل. يتكفّل Flora Design بكل التفاصيل، من أول اتصال حتى يوم المناسبة. أرسل طلبًا مع التاريخ وسيؤكد مقدّم الخدمة خلال 48 ساعة.",
    "cancellationEn": "Free cancellation up to 7 days before the event. After that, the deposit agreed with the provider is kept.",
    "cancellationAr": "إلغاء مجاني حتى 7 أيام قبل المناسبة. بعد ذلك يحتفظ مقدّم الخدمة بالعربون المتفق عليه.",
    "facts": [
      {
        "labelEn": "Flowers",
        "labelAr": "الزهور",
        "valueEn": "Fresh, seasonal",
        "valueAr": "طازجة وموسمية"
      },
      {
        "labelEn": "Delivery",
        "labelAr": "التوصيل",
        "valueEn": "Included",
        "valueAr": "مشمول"
      }
    ],
    "extras": [
      {
        "id": "b1f3b1e5-a9e3-41f8-9b6d-6b4aff9cf33a-x0",
        "nameEn": "Bridal bouquet",
        "nameAr": "باقة العروس",
        "price": "8000.00"
      }
    ],
    "maxGuests": null,
    "maxEventsPerDay": 2,
    "order": 32
  },
  {
    "id": "fdde22b6-62a5-46f7-b4f6-a7db7fd68247",
    "providerId": "94991c78-a5b7-4c3d-8aa6-a7fefcb75d64",
    "titleEn": "Engagement table styling",
    "titleAr": "تنسيق طاولة الخطوبة",
    "categoryId": "9ec8cbe5-ead7-42b4-99d1-fccc49fdad50",
    "basePrice": "28000.00",
    "priceType": "per_event",
    "avgRating": "0.00",
    "ratingCount": 0,
    "ratingCounts": [
      0,
      0,
      0,
      0,
      0
    ],
    "bookingsCount": 1,
    "wilayas": [
      31
    ],
    "photos": [
      "pexels-decoration-2.webp",
      "pexels-decoration-3.webp",
      "pexels-decoration-4.webp"
    ],
    "descriptionEn": "Engagement table styling. Rym Events Déco takes care of every detail, from the first call to the day itself. Send a request with your date and the provider confirms within 48 hours.",
    "descriptionAr": "تنسيق طاولة الخطوبة. يتكفّل Rym Events Déco بكل التفاصيل، من أول اتصال حتى يوم المناسبة. أرسل طلبًا مع التاريخ وسيؤكد مقدّم الخدمة خلال 48 ساعة.",
    "cancellationEn": null,
    "cancellationAr": null,
    "facts": [
      {
        "labelEn": "Setup",
        "labelAr": "التركيب",
        "valueEn": "The day before",
        "valueAr": "قبل يوم"
      },
      {
        "labelEn": "Style",
        "labelAr": "الأسلوب",
        "valueEn": "Made to measure",
        "valueAr": "حسب الطلب"
      }
    ],
    "extras": [
      {
        "id": "fdde22b6-62a5-46f7-b4f6-a7db7fd68247-x0",
        "nameEn": "Lighting",
        "nameAr": "الإضاءة",
        "price": "12000.00"
      }
    ],
    "maxGuests": null,
    "maxEventsPerDay": 2,
    "order": 33
  },
  {
    "id": "fef1bd1a-a8ba-4209-8b3a-a90582f3a5dc",
    "providerId": "a08cde8f-1369-492a-8dd3-8187341af983",
    "titleEn": "Wedding car with driver",
    "titleAr": "سيارة زفاف مع سائق",
    "categoryId": "3b472770-bd00-44ce-b2cc-a1dba7b327c5",
    "basePrice": "35000.00",
    "priceType": "per_event",
    "avgRating": "0.00",
    "ratingCount": 0,
    "ratingCounts": [
      0,
      0,
      0,
      0,
      0
    ],
    "bookingsCount": 0,
    "wilayas": [
      9,
      16
    ],
    "photos": [
      "pexels-transport-2.webp",
      "pexels-transport-3.webp",
      "pexels-transport-4.webp"
    ],
    "descriptionEn": "Wedding car with driver. Limousine Prestige takes care of every detail, from the first call to the day itself. Send a request with your date and the provider confirms within 48 hours.",
    "descriptionAr": "سيارة زفاف مع سائق. يتكفّل Limousine Prestige بكل التفاصيل، من أول اتصال حتى يوم المناسبة. أرسل طلبًا مع التاريخ وسيؤكد مقدّم الخدمة خلال 48 ساعة.",
    "cancellationEn": "Free cancellation up to 7 days before the event. After that, the deposit agreed with the provider is kept.",
    "cancellationAr": "إلغاء مجاني حتى 7 أيام قبل المناسبة. بعد ذلك يحتفظ مقدّم الخدمة بالعربون المتفق عليه.",
    "facts": [
      {
        "labelEn": "Driver",
        "labelAr": "السائق",
        "valueEn": "Included",
        "valueAr": "مشمول"
      },
      {
        "labelEn": "Decoration",
        "labelAr": "التزيين",
        "valueEn": "Ribbons and flowers",
        "valueAr": "شرائط وزهور"
      }
    ],
    "extras": [
      {
        "id": "fef1bd1a-a8ba-4209-8b3a-a90582f3a5dc-x0",
        "nameEn": "Extra hour",
        "nameAr": "ساعة إضافية",
        "price": "5000.00"
      }
    ],
    "maxGuests": null,
    "maxEventsPerDay": 2,
    "order": 34
  },
  {
    "id": "e92cd94c-e7c2-4ea0-8377-e852476e6934",
    "providerId": "aebed654-e28b-4191-8ec2-531031ca3314",
    "titleEn": "Dessert table for 100 guests",
    "titleAr": "طاولة حلويات لـ 100 ضيف",
    "categoryId": "137d6aeb-8aa1-4c3e-a9cd-ca5a67c4e1d1",
    "basePrice": "60000.00",
    "priceType": "per_event",
    "avgRating": "0.00",
    "ratingCount": 0,
    "ratingCounts": [
      0,
      0,
      0,
      0,
      0
    ],
    "bookingsCount": 0,
    "wilayas": [
      16
    ],
    "photos": [
      "pexels-gateaux-patisserie-5.webp",
      "pexels-gateaux-patisserie-6.webp",
      "pexels-gateaux-patisserie-1.webp"
    ],
    "descriptionEn": "Dessert table for 100 guests. Pâtisserie Meriem takes care of every detail, from the first call to the day itself. Send a request with your date and the provider confirms within 48 hours.",
    "descriptionAr": "طاولة حلويات لـ 100 ضيف. يتكفّل Pâtisserie Meriem بكل التفاصيل، من أول اتصال حتى يوم المناسبة. أرسل طلبًا مع التاريخ وسيؤكد مقدّم الخدمة خلال 48 ساعة.",
    "cancellationEn": null,
    "cancellationAr": null,
    "facts": [
      {
        "labelEn": "Tasting",
        "labelAr": "التذوق",
        "valueEn": "Free",
        "valueAr": "مجاني"
      },
      {
        "labelEn": "Order",
        "labelAr": "الطلب",
        "valueEn": "2 weeks ahead",
        "valueAr": "قبل أسبوعين"
      }
    ],
    "extras": [
      {
        "id": "e92cd94c-e7c2-4ea0-8377-e852476e6934-x0",
        "nameEn": "Tasting box",
        "nameAr": "علبة تذوق",
        "price": "3000.00"
      }
    ],
    "maxGuests": null,
    "maxEventsPerDay": 2,
    "order": 35
  },
  {
    "id": "d9b44905-d69e-4d92-97ee-324b4b3659c7",
    "providerId": "94305376-287a-4966-9546-8c3afd247e88",
    "titleEn": "Seafood dinner menu",
    "titleAr": "قائمة عشاء بالمأكولات البحرية",
    "categoryId": "d892155b-2c9b-4e0f-8fb5-db15b54af350",
    "basePrice": "3500.00",
    "priceType": "per_person",
    "avgRating": "0.00",
    "ratingCount": 0,
    "ratingCounts": [
      0,
      0,
      0,
      0,
      0
    ],
    "bookingsCount": 0,
    "wilayas": [
      31
    ],
    "photos": [
      "pexels-traiteur-3.webp",
      "pexels-traiteur-4.webp",
      "pexels-traiteur-1.webp"
    ],
    "descriptionEn": "Seafood dinner menu. Salle El Bahia takes care of every detail, from the first call to the day itself. Send a request with your date and the provider confirms within 48 hours.",
    "descriptionAr": "قائمة عشاء بالمأكولات البحرية. يتكفّل Salle El Bahia بكل التفاصيل، من أول اتصال حتى يوم المناسبة. أرسل طلبًا مع التاريخ وسيؤكد مقدّم الخدمة خلال 48 ساعة.",
    "cancellationEn": "Free cancellation up to 7 days before the event. After that, the deposit agreed with the provider is kept.",
    "cancellationAr": "إلغاء مجاني حتى 7 أيام قبل المناسبة. بعد ذلك يحتفظ مقدّم الخدمة بالعربون المتفق عليه.",
    "facts": [
      {
        "labelEn": "Service staff",
        "labelAr": "طاقم الخدمة",
        "valueEn": "Included",
        "valueAr": "مشمول"
      },
      {
        "labelEn": "Menu tasting",
        "labelAr": "تذوق القائمة",
        "valueEn": "On request",
        "valueAr": "عند الطلب"
      }
    ],
    "extras": [
      {
        "id": "d9b44905-d69e-4d92-97ee-324b4b3659c7-x0",
        "nameEn": "Dessert buffet",
        "nameAr": "بوفيه حلويات",
        "price": "40000.00"
      }
    ],
    "maxGuests": 500,
    "maxEventsPerDay": 2,
    "order": 36
  },
  {
    "id": "d2d478a8-18d8-4910-ae68-bcb2ddf2481c",
    "providerId": "e1ad2116-c6a2-4d3f-a9ea-c4168694f925",
    "titleEn": "Traditional Oranian sweets tray",
    "titleAr": "صينية حلويات وهرانية تقليدية",
    "categoryId": "137d6aeb-8aa1-4c3e-a9cd-ca5a67c4e1d1",
    "basePrice": "12000.00",
    "priceType": "per_event",
    "avgRating": "0.00",
    "ratingCount": 0,
    "ratingCounts": [
      0,
      0,
      0,
      0,
      0
    ],
    "bookingsCount": 0,
    "wilayas": [
      27,
      31
    ],
    "photos": [
      "pexels-gateaux-patisserie-6.webp",
      "pexels-gateaux-patisserie-1.webp",
      "pexels-gateaux-patisserie-2.webp"
    ],
    "descriptionEn": "Traditional Oranian sweets tray. Douceurs d'Oran takes care of every detail, from the first call to the day itself. Send a request with your date and the provider confirms within 48 hours.",
    "descriptionAr": "صينية حلويات وهرانية تقليدية. يتكفّل Douceurs d'Oran بكل التفاصيل، من أول اتصال حتى يوم المناسبة. أرسل طلبًا مع التاريخ وسيؤكد مقدّم الخدمة خلال 48 ساعة.",
    "cancellationEn": null,
    "cancellationAr": null,
    "facts": [
      {
        "labelEn": "Tasting",
        "labelAr": "التذوق",
        "valueEn": "Free",
        "valueAr": "مجاني"
      },
      {
        "labelEn": "Order",
        "labelAr": "الطلب",
        "valueEn": "2 weeks ahead",
        "valueAr": "قبل أسبوعين"
      }
    ],
    "extras": [
      {
        "id": "d2d478a8-18d8-4910-ae68-bcb2ddf2481c-x0",
        "nameEn": "Tasting box",
        "nameAr": "علبة تذوق",
        "price": "3000.00"
      }
    ],
    "maxGuests": null,
    "maxEventsPerDay": 2,
    "order": 37
  },
  {
    "id": "97ce1de9-f176-4cbe-9b42-c33ac9e44015",
    "providerId": "874ec054-c8d1-4c70-810c-52c9debac14f",
    "titleEn": "Solo oud for dinners",
    "titleAr": "عزف منفرد على العود للعشاء",
    "categoryId": "601c07e5-d2c8-4619-bbb4-bbb546803413",
    "basePrice": "20000.00",
    "priceType": "per_hour",
    "avgRating": "0.00",
    "ratingCount": 0,
    "ratingCounts": [
      0,
      0,
      0,
      0,
      0
    ],
    "bookingsCount": 0,
    "wilayas": [
      19,
      25
    ],
    "photos": [
      "pexels-musique-dj-3.webp",
      "pexels-musique-dj-4.webp",
      "pexels-musique-dj-1.webp"
    ],
    "descriptionEn": "Solo oud for dinners. Orchestre Andalou takes care of every detail, from the first call to the day itself. Send a request with your date and the provider confirms within 48 hours.",
    "descriptionAr": "عزف منفرد على العود للعشاء. يتكفّل Orchestre Andalou بكل التفاصيل، من أول اتصال حتى يوم المناسبة. أرسل طلبًا مع التاريخ وسيؤكد مقدّم الخدمة خلال 48 ساعة.",
    "cancellationEn": "Free cancellation up to 7 days before the event. After that, the deposit agreed with the provider is kept.",
    "cancellationAr": "إلغاء مجاني حتى 7 أيام قبل المناسبة. بعد ذلك يحتفظ مقدّم الخدمة بالعربون المتفق عليه.",
    "facts": [
      {
        "labelEn": "Band",
        "labelAr": "الفرقة",
        "valueEn": "6 musicians",
        "valueAr": "6 عازفين"
      },
      {
        "labelEn": "Duration",
        "labelAr": "المدة",
        "valueEn": "4 hours",
        "valueAr": "4 ساعات"
      }
    ],
    "extras": [
      {
        "id": "97ce1de9-f176-4cbe-9b42-c33ac9e44015-x0",
        "nameEn": "Extra hour",
        "nameAr": "ساعة إضافية",
        "price": "15000.00"
      }
    ],
    "maxGuests": null,
    "maxEventsPerDay": 2,
    "order": 38
  },
  {
    "id": "5694447d-206a-456b-bf89-6c0ee94b6e21",
    "providerId": "96a1f496-ffee-4a92-8204-76f8066a62e4",
    "titleEn": "Bridal bouquet",
    "titleAr": "باقة العروس",
    "categoryId": "0b52682c-4d00-49df-b18a-2c30c363a331",
    "basePrice": "12000.00",
    "priceType": "per_event",
    "avgRating": "0.00",
    "ratingCount": 0,
    "ratingCounts": [
      0,
      0,
      0,
      0,
      0
    ],
    "bookingsCount": 0,
    "wilayas": [
      16
    ],
    "photos": [
      "pexels-fleurs-4.webp",
      "pexels-fleurs-1.webp",
      "pexels-fleurs-2.webp"
    ],
    "descriptionEn": "Bridal bouquet. Flora Design takes care of every detail, from the first call to the day itself. Send a request with your date and the provider confirms within 48 hours.",
    "descriptionAr": "باقة العروس. يتكفّل Flora Design بكل التفاصيل، من أول اتصال حتى يوم المناسبة. أرسل طلبًا مع التاريخ وسيؤكد مقدّم الخدمة خلال 48 ساعة.",
    "cancellationEn": null,
    "cancellationAr": null,
    "facts": [
      {
        "labelEn": "Flowers",
        "labelAr": "الزهور",
        "valueEn": "Fresh, seasonal",
        "valueAr": "طازجة وموسمية"
      },
      {
        "labelEn": "Delivery",
        "labelAr": "التوصيل",
        "valueEn": "Included",
        "valueAr": "مشمول"
      }
    ],
    "extras": [
      {
        "id": "5694447d-206a-456b-bf89-6c0ee94b6e21-x0",
        "nameEn": "Bridal bouquet",
        "nameAr": "باقة العروس",
        "price": "8000.00"
      }
    ],
    "maxGuests": null,
    "maxEventsPerDay": 2,
    "order": 39
  },
  {
    "id": "18c3b72d-5007-438a-a30b-c70aadeab1a3",
    "providerId": "aebed654-e28b-4191-8ec2-531031ca3314",
    "titleEn": "Graduation cupcakes",
    "titleAr": "كب كيك التخرج",
    "categoryId": "137d6aeb-8aa1-4c3e-a9cd-ca5a67c4e1d1",
    "basePrice": "6000.00",
    "priceType": "per_event",
    "avgRating": "0.00",
    "ratingCount": 0,
    "ratingCounts": [
      0,
      0,
      0,
      0,
      0
    ],
    "bookingsCount": 0,
    "wilayas": [
      16
    ],
    "photos": [
      "pexels-gateaux-patisserie-1.webp",
      "pexels-gateaux-patisserie-2.webp",
      "pexels-gateaux-patisserie-3.webp"
    ],
    "descriptionEn": "Graduation cupcakes. Pâtisserie Meriem takes care of every detail, from the first call to the day itself. Send a request with your date and the provider confirms within 48 hours.",
    "descriptionAr": "كب كيك التخرج. يتكفّل Pâtisserie Meriem بكل التفاصيل، من أول اتصال حتى يوم المناسبة. أرسل طلبًا مع التاريخ وسيؤكد مقدّم الخدمة خلال 48 ساعة.",
    "cancellationEn": "Free cancellation up to 7 days before the event. After that, the deposit agreed with the provider is kept.",
    "cancellationAr": "إلغاء مجاني حتى 7 أيام قبل المناسبة. بعد ذلك يحتفظ مقدّم الخدمة بالعربون المتفق عليه.",
    "facts": [
      {
        "labelEn": "Tasting",
        "labelAr": "التذوق",
        "valueEn": "Free",
        "valueAr": "مجاني"
      },
      {
        "labelEn": "Order",
        "labelAr": "الطلب",
        "valueEn": "2 weeks ahead",
        "valueAr": "قبل أسبوعين"
      }
    ],
    "extras": [
      {
        "id": "18c3b72d-5007-438a-a30b-c70aadeab1a3-x0",
        "nameEn": "Tasting box",
        "nameAr": "علبة تذوق",
        "price": "3000.00"
      }
    ],
    "maxGuests": null,
    "maxEventsPerDay": 2,
    "order": 40
  },
  {
    "id": "mock-lumiere-1",
    "providerId": "3552815d-6aca-43fc-ace8-0409ee3a762e",
    "titleEn": "Engagement photo session",
    "titleAr": "جلسة تصوير خطوبة",
    "categoryId": "7d3855dd-4bd3-430a-9ffc-09d4f269eb4a",
    "basePrice": "35000.00",
    "priceType": "per_event",
    "avgRating": "4.60",
    "ratingCount": 5,
    "ratingCounts": [
      3,
      2,
      0,
      0,
      0
    ],
    "bookingsCount": 10,
    "wilayas": [
      16,
      9,
      35
    ],
    "photos": [
      "pexels-photographie-2.webp",
      "pexels-photographie-3.webp",
      "pexels-photographie-4.webp"
    ],
    "descriptionEn": "Engagement photo session. Studio Lumière takes care of every detail, from the first call to the day itself.",
    "descriptionAr": "جلسة تصوير خطوبة. يتكفّل Studio Lumière بكل التفاصيل من أول اتصال حتى يوم المناسبة.",
    "cancellationEn": null,
    "cancellationAr": null,
    "facts": [
      {
        "labelEn": "Team",
        "labelAr": "الفريق",
        "valueEn": "2 photographers",
        "valueAr": "مصوران"
      },
      {
        "labelEn": "Delivery",
        "labelAr": "التسليم",
        "valueEn": "3 weeks",
        "valueAr": "3 أسابيع"
      }
    ],
    "extras": [],
    "maxGuests": null,
    "maxEventsPerDay": 2,
    "order": 41
  },
  {
    "id": "mock-lumiere-2",
    "providerId": "3552815d-6aca-43fc-ace8-0409ee3a762e",
    "titleEn": "Studio portraits",
    "titleAr": "صور بورتريه في الأستوديو",
    "categoryId": "7d3855dd-4bd3-430a-9ffc-09d4f269eb4a",
    "basePrice": "6000.00",
    "priceType": "per_hour",
    "avgRating": "0.00",
    "ratingCount": 0,
    "ratingCounts": [
      0,
      0,
      0,
      0,
      0
    ],
    "bookingsCount": 0,
    "wilayas": [
      16,
      9,
      35
    ],
    "photos": [
      "pexels-photographie-3.webp",
      "pexels-photographie-4.webp",
      "pexels-photographie-5.webp"
    ],
    "descriptionEn": "Studio portraits. Studio Lumière takes care of every detail, from the first call to the day itself.",
    "descriptionAr": "صور بورتريه في الأستوديو. يتكفّل Studio Lumière بكل التفاصيل من أول اتصال حتى يوم المناسبة.",
    "cancellationEn": null,
    "cancellationAr": null,
    "facts": [
      {
        "labelEn": "Team",
        "labelAr": "الفريق",
        "valueEn": "2 photographers",
        "valueAr": "مصوران"
      },
      {
        "labelEn": "Delivery",
        "labelAr": "التسليم",
        "valueEn": "3 weeks",
        "valueAr": "3 أسابيع"
      }
    ],
    "extras": [],
    "maxGuests": null,
    "maxEventsPerDay": 2,
    "order": 42
  },
  {
    "id": "mock-lumiere-3",
    "providerId": "3552815d-6aca-43fc-ace8-0409ee3a762e",
    "titleEn": "Henna night coverage",
    "titleAr": "تغطية ليلة الحناء",
    "categoryId": "7d3855dd-4bd3-430a-9ffc-09d4f269eb4a",
    "basePrice": "45000.00",
    "priceType": "per_event",
    "avgRating": "4.90",
    "ratingCount": 7,
    "ratingCounts": [
      6,
      1,
      0,
      0,
      0
    ],
    "bookingsCount": 14,
    "wilayas": [
      16,
      9,
      35
    ],
    "photos": [
      "pexels-photographie-4.webp",
      "pexels-photographie-5.webp",
      "pexels-photographie-6.webp"
    ],
    "descriptionEn": "Henna night coverage. Studio Lumière takes care of every detail, from the first call to the day itself.",
    "descriptionAr": "تغطية ليلة الحناء. يتكفّل Studio Lumière بكل التفاصيل من أول اتصال حتى يوم المناسبة.",
    "cancellationEn": null,
    "cancellationAr": null,
    "facts": [
      {
        "labelEn": "Team",
        "labelAr": "الفريق",
        "valueEn": "2 photographers",
        "valueAr": "مصوران"
      },
      {
        "labelEn": "Delivery",
        "labelAr": "التسليم",
        "valueEn": "3 weeks",
        "valueAr": "3 أسابيع"
      }
    ],
    "extras": [],
    "maxGuests": null,
    "maxEventsPerDay": 2,
    "order": 43
  },
  {
    "id": "mock-lumiere-4",
    "providerId": "3552815d-6aca-43fc-ace8-0409ee3a762e",
    "titleEn": "Wedding video teaser",
    "titleAr": "فيديو قصير للعرس",
    "categoryId": "7d3855dd-4bd3-430a-9ffc-09d4f269eb4a",
    "basePrice": "30000.00",
    "priceType": "per_event",
    "avgRating": "4.20",
    "ratingCount": 4,
    "ratingCounts": [
      1,
      3,
      0,
      0,
      0
    ],
    "bookingsCount": 8,
    "wilayas": [
      16,
      9,
      35
    ],
    "photos": [
      "pexels-photographie-5.webp",
      "pexels-photographie-6.webp",
      "pexels-photographie-1.webp"
    ],
    "descriptionEn": "Wedding video teaser. Studio Lumière takes care of every detail, from the first call to the day itself.",
    "descriptionAr": "فيديو قصير للعرس. يتكفّل Studio Lumière بكل التفاصيل من أول اتصال حتى يوم المناسبة.",
    "cancellationEn": null,
    "cancellationAr": null,
    "facts": [
      {
        "labelEn": "Team",
        "labelAr": "الفريق",
        "valueEn": "2 photographers",
        "valueAr": "مصوران"
      },
      {
        "labelEn": "Delivery",
        "labelAr": "التسليم",
        "valueEn": "3 weeks",
        "valueAr": "3 أسابيع"
      }
    ],
    "extras": [],
    "maxGuests": null,
    "maxEventsPerDay": 2,
    "order": 44
  },
  {
    "id": "mock-lumiere-5",
    "providerId": "3552815d-6aca-43fc-ace8-0409ee3a762e",
    "titleEn": "Photo album printing",
    "titleAr": "طباعة ألبوم الصور",
    "categoryId": "7d3855dd-4bd3-430a-9ffc-09d4f269eb4a",
    "basePrice": "18000.00",
    "priceType": "per_event",
    "avgRating": "0.00",
    "ratingCount": 0,
    "ratingCounts": [
      0,
      0,
      0,
      0,
      0
    ],
    "bookingsCount": 0,
    "wilayas": [
      16,
      9,
      35
    ],
    "photos": [
      "pexels-photographie-6.webp",
      "pexels-photographie-1.webp",
      "pexels-photographie-2.webp"
    ],
    "descriptionEn": "Photo album printing. Studio Lumière takes care of every detail, from the first call to the day itself.",
    "descriptionAr": "طباعة ألبوم الصور. يتكفّل Studio Lumière بكل التفاصيل من أول اتصال حتى يوم المناسبة.",
    "cancellationEn": null,
    "cancellationAr": null,
    "facts": [
      {
        "labelEn": "Team",
        "labelAr": "الفريق",
        "valueEn": "2 photographers",
        "valueAr": "مصوران"
      },
      {
        "labelEn": "Delivery",
        "labelAr": "التسليم",
        "valueEn": "3 weeks",
        "valueAr": "3 أسابيع"
      }
    ],
    "extras": [],
    "maxGuests": null,
    "maxEventsPerDay": 2,
    "order": 45
  },
  {
    "id": "mock-lumiere-6",
    "providerId": "3552815d-6aca-43fc-ace8-0409ee3a762e",
    "titleEn": "Drone aerial shots",
    "titleAr": "لقطات جوية بالدرون",
    "categoryId": "7d3855dd-4bd3-430a-9ffc-09d4f269eb4a",
    "basePrice": "25000.00",
    "priceType": "per_event",
    "avgRating": "4.50",
    "ratingCount": 2,
    "ratingCounts": [
      1,
      1,
      0,
      0,
      0
    ],
    "bookingsCount": 4,
    "wilayas": [
      16,
      9,
      35
    ],
    "photos": [],
    "descriptionEn": "Drone aerial shots. Studio Lumière takes care of every detail, from the first call to the day itself.",
    "descriptionAr": "لقطات جوية بالدرون. يتكفّل Studio Lumière بكل التفاصيل من أول اتصال حتى يوم المناسبة.",
    "cancellationEn": null,
    "cancellationAr": null,
    "facts": [
      {
        "labelEn": "Team",
        "labelAr": "الفريق",
        "valueEn": "2 photographers",
        "valueAr": "مصوران"
      },
      {
        "labelEn": "Delivery",
        "labelAr": "التسليم",
        "valueEn": "3 weeks",
        "valueAr": "3 أسابيع"
      }
    ],
    "extras": [],
    "maxGuests": null,
    "maxEventsPerDay": 2,
    "order": 46
  },
  {
    "id": "mock-lumiere-7",
    "providerId": "3552815d-6aca-43fc-ace8-0409ee3a762e",
    "titleEn": "Birthday party coverage",
    "titleAr": "تغطية حفلة عيد ميلاد",
    "categoryId": "7d3855dd-4bd3-430a-9ffc-09d4f269eb4a",
    "basePrice": "28000.00",
    "priceType": "per_event",
    "avgRating": "4.00",
    "ratingCount": 3,
    "ratingCounts": [
      0,
      3,
      0,
      0,
      0
    ],
    "bookingsCount": 6,
    "wilayas": [
      16,
      9,
      35
    ],
    "photos": [
      "pexels-photographie-1.webp",
      "pexels-photographie-2.webp",
      "pexels-photographie-3.webp"
    ],
    "descriptionEn": "Birthday party coverage. Studio Lumière takes care of every detail, from the first call to the day itself.",
    "descriptionAr": "تغطية حفلة عيد ميلاد. يتكفّل Studio Lumière بكل التفاصيل من أول اتصال حتى يوم المناسبة.",
    "cancellationEn": null,
    "cancellationAr": null,
    "facts": [
      {
        "labelEn": "Team",
        "labelAr": "الفريق",
        "valueEn": "2 photographers",
        "valueAr": "مصوران"
      },
      {
        "labelEn": "Delivery",
        "labelAr": "التسليم",
        "valueEn": "3 weeks",
        "valueAr": "3 أسابيع"
      }
    ],
    "extras": [],
    "maxGuests": null,
    "maxEventsPerDay": 2,
    "order": 47
  },
  {
    "id": "mock-lumiere-8",
    "providerId": "3552815d-6aca-43fc-ace8-0409ee3a762e",
    "titleEn": "Corporate event photography",
    "titleAr": "تصوير الفعاليات المؤسسية",
    "categoryId": "7d3855dd-4bd3-430a-9ffc-09d4f269eb4a",
    "basePrice": "50000.00",
    "priceType": "per_day",
    "avgRating": "0.00",
    "ratingCount": 0,
    "ratingCounts": [
      0,
      0,
      0,
      0,
      0
    ],
    "bookingsCount": 0,
    "wilayas": [
      16,
      9,
      35
    ],
    "photos": [
      "pexels-photographie-2.webp",
      "pexels-photographie-3.webp",
      "pexels-photographie-4.webp"
    ],
    "descriptionEn": "Corporate event photography. Studio Lumière takes care of every detail, from the first call to the day itself.",
    "descriptionAr": "تصوير الفعاليات المؤسسية. يتكفّل Studio Lumière بكل التفاصيل من أول اتصال حتى يوم المناسبة.",
    "cancellationEn": null,
    "cancellationAr": null,
    "facts": [
      {
        "labelEn": "Team",
        "labelAr": "الفريق",
        "valueEn": "2 photographers",
        "valueAr": "مصوران"
      },
      {
        "labelEn": "Delivery",
        "labelAr": "التسليم",
        "valueEn": "3 weeks",
        "valueAr": "3 أسابيع"
      }
    ],
    "extras": [],
    "maxGuests": null,
    "maxEventsPerDay": 2,
    "order": 48
  }
];

/// `items` are service ids, in the order the provider set.
const List<Map<String, Object?>> mockCatalogPacks = <Map<String, Object?>>[
  {
    "id": "e03b28ba-30dd-4eb0-ada3-4d74d878ffee",
    "providerId": "94305376-287a-4966-9546-8c3afd247e88",
    "nameEn": "Mariage Vue sur Mer",
    "nameAr": "زفاف بإطلالة على البحر",
    "eventType": "wedding",
    "wilayaCode": 31,
    "price": "528000.00",
    "sumOfItems": "600000.00",
    "savings": "72000.00",
    "savingsPercent": 12,
    "items": [
      "087596a7-870a-486f-aa3b-d70def6bba33",
      "40e36160-7691-4cc4-9a80-150d610b1f5e",
      "5f051263-678e-46c0-81fe-5a6cce582a0c"
    ],
    "wilayas": [
      31
    ],
    "descriptionEn": "Everything for your celebration from Salle El Bahia, booked together at one price.",
    "descriptionAr": "كل ما تحتاجه لمناسبتك من Salle El Bahia في حجز واحد وبسعر واحد.",
    "maxGuests": 300,
    "photos": [
      "pexels-salles-des-fetes-2.webp",
      "pexels-salles-des-fetes-3.webp",
      "pexels-salles-des-fetes-4.webp",
      "pexels-decoration-2.webp",
      "pexels-decoration-3.webp"
    ],
    "avgRating": "0.00",
    "ratingCount": 0,
    "bookingsCount": 0
  },
  {
    "id": "384ad0fe-c56f-435f-a9bb-a97605fee82d",
    "providerId": "3552815d-6aca-43fc-ace8-0409ee3a762e",
    "nameEn": "Photo + Vidéo Mariage",
    "nameAr": "باقة صور وفيديو الزفاف",
    "eventType": "wedding",
    "wilayaCode": 16,
    "price": "155000.00",
    "sumOfItems": "183000.00",
    "savings": "28000.00",
    "savingsPercent": 15.3,
    "items": [
      "892e3d17-0f2e-4348-a5f0-5a0df2b285ef",
      "98209b95-db94-43d3-9c27-e6ab2132fd60",
      "d5fce8fc-5589-4453-a268-219bb633748d"
    ],
    "wilayas": [
      9
    ],
    "descriptionEn": "Everything for your celebration from Studio Lumière, booked together at one price.",
    "descriptionAr": "كل ما تحتاجه لمناسبتك من Studio Lumière في حجز واحد وبسعر واحد.",
    "maxGuests": null,
    "photos": [
      "pexels-photographie-1.webp",
      "pexels-photographie-2.webp",
      "pexels-photographie-3.webp",
      "pexels-photographie-4.webp",
      "pexels-photographie-5.webp"
    ],
    "avgRating": "0.00",
    "ratingCount": 0,
    "bookingsCount": 0
  },
  {
    "id": "2ed8ef06-7c7b-4fba-8138-aad86c3889e7",
    "providerId": "fe9734e0-24c4-4640-ae2a-d07220ed3f5a",
    "nameEn": "Fiançailles au Jardin",
    "nameAr": "خطوبة في الحديقة",
    "eventType": "engagement",
    "wilayaCode": 42,
    "price": "303000.00",
    "sumOfItems": "337600.00",
    "savings": "34600.00",
    "savingsPercent": 10.2,
    "items": [
      "c26208fb-7edd-4941-b90d-770bad834434",
      "4e36825b-6108-4dc6-b126-fede7832abee",
      "d16b52eb-1653-4752-8e74-6a89dcb53350"
    ],
    "wilayas": [
      9,
      42
    ],
    "descriptionEn": "Everything for your celebration from Salle Les Oliviers, booked together at one price.",
    "descriptionAr": "كل ما تحتاجه لمناسبتك من Salle Les Oliviers في حجز واحد وبسعر واحد.",
    "maxGuests": 500,
    "photos": [
      "pexels-traiteur-2.webp",
      "pexels-traiteur-3.webp",
      "pexels-traiteur-4.webp",
      "pexels-decoration-1.webp",
      "pexels-decoration-2.webp"
    ],
    "avgRating": "0.00",
    "ratingCount": 0,
    "bookingsCount": 0
  },
  {
    "id": "309d67dd-6c33-4dc5-84f9-90ff00884bb3",
    "providerId": "c62532f4-6fa9-4752-9f82-cdbea4b0dd07",
    "nameEn": "Essentiel Mariage",
    "nameAr": "باقة الزفاف الأساسية",
    "eventType": "wedding",
    "wilayaCode": 9,
    "price": "606000.00",
    "sumOfItems": "672800.00",
    "savings": "66800.00",
    "savingsPercent": 9.9,
    "items": [
      "f491ca64-3892-4191-b146-e557b441374d",
      "90639ce6-9ca2-472c-86d6-b514f7178564",
      "6252a3b3-cd93-4126-ad2a-2010a598aaa8"
    ],
    "wilayas": [
      9
    ],
    "descriptionEn": "Everything for your celebration from Salle Yasmine, booked together at one price.",
    "descriptionAr": "كل ما تحتاجه لمناسبتك من Salle Yasmine في حجز واحد وبسعر واحد.",
    "maxGuests": 500,
    "photos": [
      "pexels-salles-des-fetes-1.webp",
      "pexels-salles-des-fetes-2.webp",
      "pexels-salles-des-fetes-3.webp",
      "pexels-salles-des-fetes-4.webp",
      "pexels-salles-des-fetes-5.webp"
    ],
    "avgRating": "5.00",
    "ratingCount": 1,
    "bookingsCount": 2
  },
  {
    "id": "f83bf1b1-ee0c-4889-95fa-239429d2c9f9",
    "providerId": "874ec054-c8d1-4c70-810c-52c9debac14f",
    "nameEn": "Soirée Malouf",
    "nameAr": "سهرة المالوف",
    "eventType": "wedding",
    "wilayaCode": 25,
    "price": "171000.00",
    "sumOfItems": "190000.00",
    "savings": "19000.00",
    "savingsPercent": 10,
    "items": [
      "c238525a-b7ba-414e-b6df-85ba9fbb8066",
      "4653dbbe-2577-4e63-88b1-2249de4a0b00"
    ],
    "wilayas": [
      19,
      25
    ],
    "descriptionEn": "Everything for your celebration from Orchestre Andalou, booked together at one price.",
    "descriptionAr": "كل ما تحتاجه لمناسبتك من Orchestre Andalou في حجز واحد وبسعر واحد.",
    "maxGuests": null,
    "photos": [
      "pexels-musique-dj-1.webp",
      "pexels-musique-dj-2.webp",
      "pexels-musique-dj-3.webp",
      "pexels-musique-dj-4.webp"
    ],
    "avgRating": "5.00",
    "ratingCount": 1,
    "bookingsCount": 1
  },
  {
    "id": "65b6aa7c-387f-4677-9a84-c7c18d9971c7",
    "providerId": "aebed654-e28b-4191-8ec2-531031ca3314",
    "nameEn": "Table des Douceurs",
    "nameAr": "طاولة الحلويات",
    "eventType": "wedding",
    "wilayaCode": 16,
    "price": "107000.00",
    "sumOfItems": "119000.00",
    "savings": "12000.00",
    "savingsPercent": 10.1,
    "items": [
      "5efae45f-afc5-4378-944a-17ba7492691f",
      "1d46f321-b687-4b4c-a94c-5919e34a0e57",
      "e92cd94c-e7c2-4ea0-8377-e852476e6934"
    ],
    "wilayas": [
      16
    ],
    "descriptionEn": "Everything for your celebration from Pâtisserie Meriem, booked together at one price.",
    "descriptionAr": "كل ما تحتاجه لمناسبتك من Pâtisserie Meriem في حجز واحد وبسعر واحد.",
    "maxGuests": null,
    "photos": [
      "pexels-gateaux-patisserie-2.webp",
      "pexels-gateaux-patisserie-3.webp",
      "pexels-gateaux-patisserie-4.webp",
      "pexels-gateaux-patisserie-5.webp",
      "pexels-gateaux-patisserie-6.webp"
    ],
    "avgRating": "0.00",
    "ratingCount": 0,
    "bookingsCount": 0
  },
  {
    "id": "cc5deb82-bac3-4b4f-8198-dddf36a13498",
    "providerId": "3552815d-6aca-43fc-ace8-0409ee3a762e",
    "nameEn": "Pack Fiançailles Photo",
    "nameAr": "باقة تصوير الخطوبة",
    "eventType": "engagement",
    "wilayaCode": 16,
    "price": "138000.00",
    "sumOfItems": "155000.00",
    "savings": "17000.00",
    "savingsPercent": 11,
    "items": [
      "892e3d17-0f2e-4348-a5f0-5a0df2b285ef",
      "98209b95-db94-43d3-9c27-e6ab2132fd60"
    ],
    "wilayas": [
      9,
      16
    ],
    "descriptionEn": "Everything for your celebration from Studio Lumière, booked together at one price.",
    "descriptionAr": "كل ما تحتاجه لمناسبتك من Studio Lumière في حجز واحد وبسعر واحد.",
    "maxGuests": null,
    "photos": [
      "pexels-photographie-1.webp",
      "pexels-photographie-2.webp",
      "pexels-photographie-3.webp",
      "pexels-photographie-4.webp"
    ],
    "avgRating": "0.00",
    "ratingCount": 0,
    "bookingsCount": 0
  },
  {
    "id": "0d12c8ac-8ca9-4ac4-bddd-046320d7a064",
    "providerId": "6db77516-86a1-49ef-8b57-2c610c4e90ca",
    "nameEn": "Soirée Henné",
    "nameAr": "سهرة الحناء",
    "eventType": "henna",
    "wilayaCode": 16,
    "price": "8000.00",
    "sumOfItems": "9200.00",
    "savings": "1200.00",
    "savingsPercent": 13,
    "items": [
      "5d76f867-bda5-4741-90c3-c575906aaf7a",
      "6435499e-1636-4f5c-8727-d66e26007062"
    ],
    "wilayas": [
      9
    ],
    "descriptionEn": "Everything for your celebration from Traiteur El Djazair, booked together at one price.",
    "descriptionAr": "كل ما تحتاجه لمناسبتك من Traiteur El Djazair في حجز واحد وبسعر واحد.",
    "maxGuests": 500,
    "photos": [
      "pexels-traiteur-1.webp",
      "pexels-traiteur-2.webp",
      "pexels-traiteur-3.webp",
      "pexels-traiteur-4.webp"
    ],
    "avgRating": "4.00",
    "ratingCount": 3,
    "bookingsCount": 4
  }
];

const List<Map<String, Object?>> mockCatalogReviews = <Map<String, Object?>>[
  {
    "id": "892e3d17-0f2e-4348-a5f0-5a0df2b285ef-r0",
    "serviceId": "892e3d17-0f2e-4348-a5f0-5a0df2b285ef",
    "providerId": "3552815d-6aca-43fc-ace8-0409ee3a762e",
    "authorName": "Amel B.",
    "rating": 5,
    "comment": "Everything was perfect, thank you !",
    "reply": "Merci beaucoup pour votre confiance !",
    "daysAgo": 3
  },
  {
    "id": "892e3d17-0f2e-4348-a5f0-5a0df2b285ef-r1",
    "serviceId": "892e3d17-0f2e-4348-a5f0-5a0df2b285ef",
    "providerId": "3552815d-6aca-43fc-ace8-0409ee3a762e",
    "authorName": "Omar A.",
    "rating": 5,
    "comment": "Un travail exceptionnel, je recommande vivement.",
    "reply": null,
    "daysAgo": 14
  },
  {
    "id": "98209b95-db94-43d3-9c27-e6ab2132fd60-r0",
    "serviceId": "98209b95-db94-43d3-9c27-e6ab2132fd60",
    "providerId": "3552815d-6aca-43fc-ace8-0409ee3a762e",
    "authorName": "Omar A.",
    "rating": 4,
    "comment": "Très bien dans l'ensemble, quelques petits détails.",
    "reply": null,
    "daysAgo": 4
  },
  {
    "id": "f491ca64-3892-4191-b146-e557b441374d-r0",
    "serviceId": "f491ca64-3892-4191-b146-e557b441374d",
    "providerId": "c62532f4-6fa9-4752-9f82-cdbea4b0dd07",
    "authorName": "Yasmine K.",
    "rating": 4,
    "comment": "عمل جيد جدًا مع بعض التأخير البسيط.",
    "reply": null,
    "daysAgo": 5
  },
  {
    "id": "087596a7-870a-486f-aa3b-d70def6bba33-r0",
    "serviceId": "087596a7-870a-486f-aa3b-d70def6bba33",
    "providerId": "94305376-287a-4966-9546-8c3afd247e88",
    "authorName": "Karim D.",
    "rating": 3,
    "comment": "مقبول لكن التواصل يحتاج إلى تحسين.",
    "reply": null,
    "daysAgo": 8
  },
  {
    "id": "087596a7-870a-486f-aa3b-d70def6bba33-r1",
    "serviceId": "087596a7-870a-486f-aa3b-d70def6bba33",
    "providerId": "94305376-287a-4966-9546-8c3afd247e88",
    "authorName": "Nesrine T.",
    "rating": 3,
    "comment": "Correct but communication could be better.",
    "reply": null,
    "daysAgo": 19
  },
  {
    "id": "c238525a-b7ba-414e-b6df-85ba9fbb8066-r0",
    "serviceId": "c238525a-b7ba-414e-b6df-85ba9fbb8066",
    "providerId": "874ec054-c8d1-4c70-810c-52c9debac14f",
    "authorName": "Nesrine T.",
    "rating": 3,
    "comment": "Correct but communication could be better.",
    "reply": "Merci beaucoup pour votre confiance !",
    "daysAgo": 9
  },
  {
    "id": "d5fce8fc-5589-4453-a268-219bb633748d-r0",
    "serviceId": "d5fce8fc-5589-4453-a268-219bb633748d",
    "providerId": "3552815d-6aca-43fc-ace8-0409ee3a762e",
    "authorName": "Amel B.",
    "rating": 5,
    "comment": "خدمة رائعة واحترافية، أنصح بها بشدة.",
    "reply": null,
    "daysAgo": 4
  },
  {
    "id": "c26208fb-7edd-4941-b90d-770bad834434-r0",
    "serviceId": "c26208fb-7edd-4941-b90d-770bad834434",
    "providerId": "fe9734e0-24c4-4640-ae2a-d07220ed3f5a",
    "authorName": "Omar A.",
    "rating": 5,
    "comment": "Everything was perfect, thank you !",
    "reply": "Merci beaucoup pour votre confiance !",
    "daysAgo": 5
  },
  {
    "id": "c26208fb-7edd-4941-b90d-770bad834434-r1",
    "serviceId": "c26208fb-7edd-4941-b90d-770bad834434",
    "providerId": "fe9734e0-24c4-4640-ae2a-d07220ed3f5a",
    "authorName": "Yasmine K.",
    "rating": 5,
    "comment": "Un travail exceptionnel, je recommande vivement.",
    "reply": null,
    "daysAgo": 16
  },
  {
    "id": "d1f300e9-1950-4d28-b149-43b5eefb5f5c-r0",
    "serviceId": "d1f300e9-1950-4d28-b149-43b5eefb5f5c",
    "providerId": "3552815d-6aca-43fc-ace8-0409ee3a762e",
    "authorName": "Yasmine K.",
    "rating": 5,
    "comment": "Un travail exceptionnel, je recommande vivement.",
    "reply": null,
    "daysAgo": 6
  },
  {
    "id": "c2aee393-049f-4db4-aa1a-74cff3c15efa-r0",
    "serviceId": "c2aee393-049f-4db4-aa1a-74cff3c15efa",
    "providerId": "96a1f496-ffee-4a92-8204-76f8066a62e4",
    "authorName": "Sofiane M.",
    "rating": 5,
    "comment": "خدمة رائعة واحترافية، أنصح بها بشدة.",
    "reply": null,
    "daysAgo": 7
  },
  {
    "id": "90639ce6-9ca2-472c-86d6-b514f7178564-r0",
    "serviceId": "90639ce6-9ca2-472c-86d6-b514f7178564",
    "providerId": "c62532f4-6fa9-4752-9f82-cdbea4b0dd07",
    "authorName": "Lina H.",
    "rating": 5,
    "comment": "Everything was perfect, thank you !",
    "reply": "Merci beaucoup pour votre confiance !",
    "daysAgo": 8
  },
  {
    "id": "705e892f-6b77-4d2b-952c-f3ad5d38c9dd-r0",
    "serviceId": "705e892f-6b77-4d2b-952c-f3ad5d38c9dd",
    "providerId": "de14bc74-7094-4e15-a1b9-3b1f50a5e607",
    "authorName": "Karim D.",
    "rating": 5,
    "comment": "Un travail exceptionnel, je recommande vivement.",
    "reply": null,
    "daysAgo": 9
  },
  {
    "id": "6435499e-1636-4f5c-8727-d66e26007062-r0",
    "serviceId": "6435499e-1636-4f5c-8727-d66e26007062",
    "providerId": "6db77516-86a1-49ef-8b57-2c610c4e90ca",
    "authorName": "Nesrine T.",
    "rating": 5,
    "comment": "خدمة رائعة واحترافية، أنصح بها بشدة.",
    "reply": null,
    "daysAgo": 3
  },
  {
    "id": "6252a3b3-cd93-4126-ad2a-2010a598aaa8-r0",
    "serviceId": "6252a3b3-cd93-4126-ad2a-2010a598aaa8",
    "providerId": "c62532f4-6fa9-4752-9f82-cdbea4b0dd07",
    "authorName": "Walid S.",
    "rating": 5,
    "comment": "Everything was perfect, thank you !",
    "reply": "Merci beaucoup pour votre confiance !",
    "daysAgo": 4
  },
  {
    "id": "4e36825b-6108-4dc6-b126-fede7832abee-r0",
    "serviceId": "4e36825b-6108-4dc6-b126-fede7832abee",
    "providerId": "fe9734e0-24c4-4640-ae2a-d07220ed3f5a",
    "authorName": "Amel B.",
    "rating": 5,
    "comment": "Un travail exceptionnel, je recommande vivement.",
    "reply": null,
    "daysAgo": 5
  },
  {
    "id": "4653dbbe-2577-4e63-88b1-2249de4a0b00-r0",
    "serviceId": "4653dbbe-2577-4e63-88b1-2249de4a0b00",
    "providerId": "874ec054-c8d1-4c70-810c-52c9debac14f",
    "authorName": "Omar A.",
    "rating": 5,
    "comment": "خدمة رائعة واحترافية، أنصح بها بشدة.",
    "reply": null,
    "daysAgo": 6
  },
  {
    "id": "40e36160-7691-4cc4-9a80-150d610b1f5e-r0",
    "serviceId": "40e36160-7691-4cc4-9a80-150d610b1f5e",
    "providerId": "94305376-287a-4966-9546-8c3afd247e88",
    "authorName": "Yasmine K.",
    "rating": 5,
    "comment": "Everything was perfect, thank you !",
    "reply": "Merci beaucoup pour votre confiance !",
    "daysAgo": 7
  },
  {
    "id": "2dc38173-ec66-44b6-88d7-3129333be9ee-r0",
    "serviceId": "2dc38173-ec66-44b6-88d7-3129333be9ee",
    "providerId": "94991c78-a5b7-4c3d-8aa6-a7fefcb75d64",
    "authorName": "Sofiane M.",
    "rating": 5,
    "comment": "Un travail exceptionnel, je recommande vivement.",
    "reply": null,
    "daysAgo": 8
  },
  {
    "id": "163eb765-5339-4ce3-9a1e-120ecb18552c-r0",
    "serviceId": "163eb765-5339-4ce3-9a1e-120ecb18552c",
    "providerId": "94991c78-a5b7-4c3d-8aa6-a7fefcb75d64",
    "authorName": "Lina H.",
    "rating": 5,
    "comment": "خدمة رائعة واحترافية، أنصح بها بشدة.",
    "reply": null,
    "daysAgo": 9
  },
  {
    "id": "163eb765-5339-4ce3-9a1e-120ecb18552c-r1",
    "serviceId": "163eb765-5339-4ce3-9a1e-120ecb18552c",
    "providerId": "94991c78-a5b7-4c3d-8aa6-a7fefcb75d64",
    "authorName": "Karim D.",
    "rating": 5,
    "comment": "Everything was perfect, thank you !",
    "reply": null,
    "daysAgo": 20
  },
  {
    "id": "163eb765-5339-4ce3-9a1e-120ecb18552c-r2",
    "serviceId": "163eb765-5339-4ce3-9a1e-120ecb18552c",
    "providerId": "94991c78-a5b7-4c3d-8aa6-a7fefcb75d64",
    "authorName": "Nesrine T.",
    "rating": 5,
    "comment": "Un travail exceptionnel, je recommande vivement.",
    "reply": null,
    "daysAgo": 31
  },
  {
    "id": "163eb765-5339-4ce3-9a1e-120ecb18552c-r3",
    "serviceId": "163eb765-5339-4ce3-9a1e-120ecb18552c",
    "providerId": "94991c78-a5b7-4c3d-8aa6-a7fefcb75d64",
    "authorName": "Walid S.",
    "rating": 4,
    "comment": "عمل جيد جدًا مع بعض التأخير البسيط.",
    "reply": null,
    "daysAgo": 42
  },
  {
    "id": "6a3014a4-fa28-474a-9acf-d1369a2b8ed1-r0",
    "serviceId": "6a3014a4-fa28-474a-9acf-d1369a2b8ed1",
    "providerId": "a08cde8f-1369-492a-8dd3-8187341af983",
    "authorName": "Karim D.",
    "rating": 5,
    "comment": "Everything was perfect, thank you !",
    "reply": "Merci beaucoup pour votre confiance !",
    "daysAgo": 3
  },
  {
    "id": "6a3014a4-fa28-474a-9acf-d1369a2b8ed1-r1",
    "serviceId": "6a3014a4-fa28-474a-9acf-d1369a2b8ed1",
    "providerId": "a08cde8f-1369-492a-8dd3-8187341af983",
    "authorName": "Nesrine T.",
    "rating": 5,
    "comment": "Un travail exceptionnel, je recommande vivement.",
    "reply": null,
    "daysAgo": 14
  },
  {
    "id": "6a3014a4-fa28-474a-9acf-d1369a2b8ed1-r2",
    "serviceId": "6a3014a4-fa28-474a-9acf-d1369a2b8ed1",
    "providerId": "a08cde8f-1369-492a-8dd3-8187341af983",
    "authorName": "Walid S.",
    "rating": 5,
    "comment": "خدمة رائعة واحترافية، أنصح بها بشدة.",
    "reply": null,
    "daysAgo": 25
  },
  {
    "id": "6a3014a4-fa28-474a-9acf-d1369a2b8ed1-r3",
    "serviceId": "6a3014a4-fa28-474a-9acf-d1369a2b8ed1",
    "providerId": "a08cde8f-1369-492a-8dd3-8187341af983",
    "authorName": "Amel B.",
    "rating": 4,
    "comment": "Very good, a little late on the day.",
    "reply": null,
    "daysAgo": 36
  },
  {
    "id": "ebfa4d7c-60c5-4003-abbf-578bc9432b43-r0",
    "serviceId": "ebfa4d7c-60c5-4003-abbf-578bc9432b43",
    "providerId": "6db77516-86a1-49ef-8b57-2c610c4e90ca",
    "authorName": "Nesrine T.",
    "rating": 5,
    "comment": "Un travail exceptionnel, je recommande vivement.",
    "reply": null,
    "daysAgo": 4
  },
  {
    "id": "ebfa4d7c-60c5-4003-abbf-578bc9432b43-r1",
    "serviceId": "ebfa4d7c-60c5-4003-abbf-578bc9432b43",
    "providerId": "6db77516-86a1-49ef-8b57-2c610c4e90ca",
    "authorName": "Walid S.",
    "rating": 4,
    "comment": "عمل جيد جدًا مع بعض التأخير البسيط.",
    "reply": null,
    "daysAgo": 15
  },
  {
    "id": "d16b52eb-1653-4752-8e74-6a89dcb53350-r0",
    "serviceId": "d16b52eb-1653-4752-8e74-6a89dcb53350",
    "providerId": "fe9734e0-24c4-4640-ae2a-d07220ed3f5a",
    "authorName": "Walid S.",
    "rating": 5,
    "comment": "خدمة رائعة واحترافية، أنصح بها بشدة.",
    "reply": null,
    "daysAgo": 5
  },
  {
    "id": "d16b52eb-1653-4752-8e74-6a89dcb53350-r1",
    "serviceId": "d16b52eb-1653-4752-8e74-6a89dcb53350",
    "providerId": "fe9734e0-24c4-4640-ae2a-d07220ed3f5a",
    "authorName": "Amel B.",
    "rating": 4,
    "comment": "Very good, a little late on the day.",
    "reply": null,
    "daysAgo": 16
  },
  {
    "id": "1d46f321-b687-4b4c-a94c-5919e34a0e57-r0",
    "serviceId": "1d46f321-b687-4b4c-a94c-5919e34a0e57",
    "providerId": "aebed654-e28b-4191-8ec2-531031ca3314",
    "authorName": "Amel B.",
    "rating": 5,
    "comment": "Everything was perfect, thank you !",
    "reply": "Merci beaucoup pour votre confiance !",
    "daysAgo": 6
  },
  {
    "id": "1d46f321-b687-4b4c-a94c-5919e34a0e57-r1",
    "serviceId": "1d46f321-b687-4b4c-a94c-5919e34a0e57",
    "providerId": "aebed654-e28b-4191-8ec2-531031ca3314",
    "authorName": "Omar A.",
    "rating": 4,
    "comment": "Très bien dans l'ensemble, quelques petits détails.",
    "reply": null,
    "daysAgo": 17
  },
  {
    "id": "3a8ad056-300b-4914-939b-35fd59a0ada1-r0",
    "serviceId": "3a8ad056-300b-4914-939b-35fd59a0ada1",
    "providerId": "96a1f496-ffee-4a92-8204-76f8066a62e4",
    "authorName": "Omar A.",
    "rating": 5,
    "comment": "Un travail exceptionnel, je recommande vivement.",
    "reply": null,
    "daysAgo": 7
  },
  {
    "id": "3a8ad056-300b-4914-939b-35fd59a0ada1-r1",
    "serviceId": "3a8ad056-300b-4914-939b-35fd59a0ada1",
    "providerId": "96a1f496-ffee-4a92-8204-76f8066a62e4",
    "authorName": "Yasmine K.",
    "rating": 4,
    "comment": "عمل جيد جدًا مع بعض التأخير البسيط.",
    "reply": null,
    "daysAgo": 18
  },
  {
    "id": "3a8ad056-300b-4914-939b-35fd59a0ada1-r2",
    "serviceId": "3a8ad056-300b-4914-939b-35fd59a0ada1",
    "providerId": "96a1f496-ffee-4a92-8204-76f8066a62e4",
    "authorName": "Sofiane M.",
    "rating": 4,
    "comment": "Very good, a little late on the day.",
    "reply": null,
    "daysAgo": 29
  },
  {
    "id": "b15c4ecc-6ada-4da7-85b2-684aeefaa4fa-r0",
    "serviceId": "b15c4ecc-6ada-4da7-85b2-684aeefaa4fa",
    "providerId": "c62532f4-6fa9-4752-9f82-cdbea4b0dd07",
    "authorName": "Yasmine K.",
    "rating": 5,
    "comment": "خدمة رائعة واحترافية، أنصح بها بشدة.",
    "reply": null,
    "daysAgo": 8
  },
  {
    "id": "b15c4ecc-6ada-4da7-85b2-684aeefaa4fa-r1",
    "serviceId": "b15c4ecc-6ada-4da7-85b2-684aeefaa4fa",
    "providerId": "c62532f4-6fa9-4752-9f82-cdbea4b0dd07",
    "authorName": "Sofiane M.",
    "rating": 4,
    "comment": "Very good, a little late on the day.",
    "reply": null,
    "daysAgo": 19
  },
  {
    "id": "b15c4ecc-6ada-4da7-85b2-684aeefaa4fa-r2",
    "serviceId": "b15c4ecc-6ada-4da7-85b2-684aeefaa4fa",
    "providerId": "c62532f4-6fa9-4752-9f82-cdbea4b0dd07",
    "authorName": "Lina H.",
    "rating": 4,
    "comment": "Très bien dans l'ensemble, quelques petits détails.",
    "reply": null,
    "daysAgo": 30
  },
  {
    "id": "0eee6a75-2bc2-4a7c-a150-2377eddad5e0-r0",
    "serviceId": "0eee6a75-2bc2-4a7c-a150-2377eddad5e0",
    "providerId": "6db77516-86a1-49ef-8b57-2c610c4e90ca",
    "authorName": "Sofiane M.",
    "rating": 5,
    "comment": "Everything was perfect, thank you !",
    "reply": "Merci beaucoup pour votre confiance !",
    "daysAgo": 9
  },
  {
    "id": "0eee6a75-2bc2-4a7c-a150-2377eddad5e0-r1",
    "serviceId": "0eee6a75-2bc2-4a7c-a150-2377eddad5e0",
    "providerId": "6db77516-86a1-49ef-8b57-2c610c4e90ca",
    "authorName": "Lina H.",
    "rating": 4,
    "comment": "Très bien dans l'ensemble, quelques petits détails.",
    "reply": null,
    "daysAgo": 20
  },
  {
    "id": "0eee6a75-2bc2-4a7c-a150-2377eddad5e0-r2",
    "serviceId": "0eee6a75-2bc2-4a7c-a150-2377eddad5e0",
    "providerId": "6db77516-86a1-49ef-8b57-2c610c4e90ca",
    "authorName": "Karim D.",
    "rating": 4,
    "comment": "عمل جيد جدًا مع بعض التأخير البسيط.",
    "reply": null,
    "daysAgo": 31
  },
  {
    "id": "729626dc-a7c5-45e8-ba3a-32d34bfb24fa-r0",
    "serviceId": "729626dc-a7c5-45e8-ba3a-32d34bfb24fa",
    "providerId": "e1ad2116-c6a2-4d3f-a9ea-c4168694f925",
    "authorName": "Lina H.",
    "rating": 4,
    "comment": "Très bien dans l'ensemble, quelques petits détails.",
    "reply": null,
    "daysAgo": 3
  },
  {
    "id": "729626dc-a7c5-45e8-ba3a-32d34bfb24fa-r1",
    "serviceId": "729626dc-a7c5-45e8-ba3a-32d34bfb24fa",
    "providerId": "e1ad2116-c6a2-4d3f-a9ea-c4168694f925",
    "authorName": "Karim D.",
    "rating": 4,
    "comment": "عمل جيد جدًا مع بعض التأخير البسيط.",
    "reply": null,
    "daysAgo": 14
  },
  {
    "id": "5f051263-678e-46c0-81fe-5a6cce582a0c-r0",
    "serviceId": "5f051263-678e-46c0-81fe-5a6cce582a0c",
    "providerId": "94305376-287a-4966-9546-8c3afd247e88",
    "authorName": "Karim D.",
    "rating": 4,
    "comment": "عمل جيد جدًا مع بعض التأخير البسيط.",
    "reply": null,
    "daysAgo": 4
  },
  {
    "id": "5f051263-678e-46c0-81fe-5a6cce582a0c-r1",
    "serviceId": "5f051263-678e-46c0-81fe-5a6cce582a0c",
    "providerId": "94305376-287a-4966-9546-8c3afd247e88",
    "authorName": "Nesrine T.",
    "rating": 4,
    "comment": "Very good, a little late on the day.",
    "reply": null,
    "daysAgo": 15
  },
  {
    "id": "2a3eddf1-8fc8-4d2a-97db-374f313d65ff-r0",
    "serviceId": "2a3eddf1-8fc8-4d2a-97db-374f313d65ff",
    "providerId": "de14bc74-7094-4e15-a1b9-3b1f50a5e607",
    "authorName": "Nesrine T.",
    "rating": 4,
    "comment": "Very good, a little late on the day.",
    "reply": "Merci beaucoup pour votre confiance !",
    "daysAgo": 5
  },
  {
    "id": "ffdbb58f-f387-4eb0-8fe3-841a6ba886bf-r0",
    "serviceId": "ffdbb58f-f387-4eb0-8fe3-841a6ba886bf",
    "providerId": "de14bc74-7094-4e15-a1b9-3b1f50a5e607",
    "authorName": "Walid S.",
    "rating": 3,
    "comment": "Correct, sans plus.",
    "reply": null,
    "daysAgo": 6
  },
  {
    "id": "b1f3b1e5-a9e3-41f8-9b6d-6b4aff9cf33a-r0",
    "serviceId": "b1f3b1e5-a9e3-41f8-9b6d-6b4aff9cf33a",
    "providerId": "96a1f496-ffee-4a92-8204-76f8066a62e4",
    "authorName": "Amel B.",
    "rating": 3,
    "comment": "مقبول لكن التواصل يحتاج إلى تحسين.",
    "reply": null,
    "daysAgo": 7
  },
  {
    "id": "mock-lumiere-1-r0",
    "serviceId": "mock-lumiere-1",
    "providerId": "3552815d-6aca-43fc-ace8-0409ee3a762e",
    "authorName": "Omar A.",
    "rating": 5,
    "comment": "خدمة رائعة واحترافية، أنصح بها بشدة.",
    "reply": null,
    "daysAgo": 9
  },
  {
    "id": "mock-lumiere-1-r1",
    "serviceId": "mock-lumiere-1",
    "providerId": "3552815d-6aca-43fc-ace8-0409ee3a762e",
    "authorName": "Yasmine K.",
    "rating": 5,
    "comment": "Everything was perfect, thank you !",
    "reply": null,
    "daysAgo": 20
  },
  {
    "id": "mock-lumiere-1-r2",
    "serviceId": "mock-lumiere-1",
    "providerId": "3552815d-6aca-43fc-ace8-0409ee3a762e",
    "authorName": "Sofiane M.",
    "rating": 5,
    "comment": "Un travail exceptionnel, je recommande vivement.",
    "reply": null,
    "daysAgo": 31
  },
  {
    "id": "mock-lumiere-1-r3",
    "serviceId": "mock-lumiere-1",
    "providerId": "3552815d-6aca-43fc-ace8-0409ee3a762e",
    "authorName": "Lina H.",
    "rating": 4,
    "comment": "عمل جيد جدًا مع بعض التأخير البسيط.",
    "reply": null,
    "daysAgo": 42
  },
  {
    "id": "mock-lumiere-3-r0",
    "serviceId": "mock-lumiere-3",
    "providerId": "3552815d-6aca-43fc-ace8-0409ee3a762e",
    "authorName": "Sofiane M.",
    "rating": 5,
    "comment": "Un travail exceptionnel, je recommande vivement.",
    "reply": null,
    "daysAgo": 4
  },
  {
    "id": "mock-lumiere-3-r1",
    "serviceId": "mock-lumiere-3",
    "providerId": "3552815d-6aca-43fc-ace8-0409ee3a762e",
    "authorName": "Lina H.",
    "rating": 5,
    "comment": "خدمة رائعة واحترافية، أنصح بها بشدة.",
    "reply": null,
    "daysAgo": 15
  },
  {
    "id": "mock-lumiere-3-r2",
    "serviceId": "mock-lumiere-3",
    "providerId": "3552815d-6aca-43fc-ace8-0409ee3a762e",
    "authorName": "Karim D.",
    "rating": 5,
    "comment": "Everything was perfect, thank you !",
    "reply": null,
    "daysAgo": 26
  },
  {
    "id": "mock-lumiere-3-r3",
    "serviceId": "mock-lumiere-3",
    "providerId": "3552815d-6aca-43fc-ace8-0409ee3a762e",
    "authorName": "Nesrine T.",
    "rating": 5,
    "comment": "Un travail exceptionnel, je recommande vivement.",
    "reply": null,
    "daysAgo": 37
  },
  {
    "id": "mock-lumiere-4-r0",
    "serviceId": "mock-lumiere-4",
    "providerId": "3552815d-6aca-43fc-ace8-0409ee3a762e",
    "authorName": "Lina H.",
    "rating": 5,
    "comment": "خدمة رائعة واحترافية، أنصح بها بشدة.",
    "reply": null,
    "daysAgo": 5
  },
  {
    "id": "mock-lumiere-4-r1",
    "serviceId": "mock-lumiere-4",
    "providerId": "3552815d-6aca-43fc-ace8-0409ee3a762e",
    "authorName": "Karim D.",
    "rating": 4,
    "comment": "Very good, a little late on the day.",
    "reply": null,
    "daysAgo": 16
  },
  {
    "id": "mock-lumiere-4-r2",
    "serviceId": "mock-lumiere-4",
    "providerId": "3552815d-6aca-43fc-ace8-0409ee3a762e",
    "authorName": "Nesrine T.",
    "rating": 4,
    "comment": "Très bien dans l'ensemble, quelques petits détails.",
    "reply": null,
    "daysAgo": 27
  },
  {
    "id": "mock-lumiere-4-r3",
    "serviceId": "mock-lumiere-4",
    "providerId": "3552815d-6aca-43fc-ace8-0409ee3a762e",
    "authorName": "Walid S.",
    "rating": 4,
    "comment": "عمل جيد جدًا مع بعض التأخير البسيط.",
    "reply": null,
    "daysAgo": 38
  },
  {
    "id": "mock-lumiere-6-r0",
    "serviceId": "mock-lumiere-6",
    "providerId": "3552815d-6aca-43fc-ace8-0409ee3a762e",
    "authorName": "Nesrine T.",
    "rating": 5,
    "comment": "Un travail exceptionnel, je recommande vivement.",
    "reply": null,
    "daysAgo": 7
  },
  {
    "id": "mock-lumiere-6-r1",
    "serviceId": "mock-lumiere-6",
    "providerId": "3552815d-6aca-43fc-ace8-0409ee3a762e",
    "authorName": "Walid S.",
    "rating": 4,
    "comment": "عمل جيد جدًا مع بعض التأخير البسيط.",
    "reply": null,
    "daysAgo": 18
  },
  {
    "id": "mock-lumiere-7-r0",
    "serviceId": "mock-lumiere-7",
    "providerId": "3552815d-6aca-43fc-ace8-0409ee3a762e",
    "authorName": "Walid S.",
    "rating": 4,
    "comment": "عمل جيد جدًا مع بعض التأخير البسيط.",
    "reply": null,
    "daysAgo": 8
  },
  {
    "id": "mock-lumiere-7-r1",
    "serviceId": "mock-lumiere-7",
    "providerId": "3552815d-6aca-43fc-ace8-0409ee3a762e",
    "authorName": "Amel B.",
    "rating": 4,
    "comment": "Very good, a little late on the day.",
    "reply": null,
    "daysAgo": 19
  },
  {
    "id": "mock-lumiere-7-r2",
    "serviceId": "mock-lumiere-7",
    "providerId": "3552815d-6aca-43fc-ace8-0409ee3a762e",
    "authorName": "Omar A.",
    "rating": 4,
    "comment": "Très bien dans l'ensemble, quelques petits détails.",
    "reply": null,
    "daysAgo": 30
  }
];

/// What client@eventor.test has saved on a fresh mock backend.
const List<Map<String, Object?>> mockFavouriteSeeds = <Map<String, Object?>>[
  {
    "kind": "service",
    "targetId": "892e3d17-0f2e-4348-a5f0-5a0df2b285ef",
    "daysAgo": 1
  },
  {
    "kind": "service",
    "targetId": "f491ca64-3892-4191-b146-e557b441374d",
    "daysAgo": 2
  },
  {
    "kind": "service",
    "targetId": "5d76f867-bda5-4741-90c3-c575906aaf7a",
    "daysAgo": 4
  },
  {
    "kind": "pack",
    "targetId": "309d67dd-6c33-4dc5-84f9-90ff00884bb3",
    "daysAgo": 5
  },
  {
    "kind": "service",
    "targetId": "mock-retired-service",
    "daysAgo": 9
  }
];

/// Saved items that are no longer listed — kept as the snapshot the server
/// would still return, shown greyed out on 17.
const List<Map<String, Object?>> mockRetiredFavourites = <Map<String, Object?>>[
  {
    "id": "mock-retired-service",
    "kind": "service",
    "titleEn": "Décor floral cérémonie",
    "titleAr": "ديكور زهور للحفل",
    "providerName": "Flora Design",
    "categoryId": "0b52682c-4d00-49df-b18a-2c30c363a331",
    "fromPrice": "35000.00",
    "avgRating": "4.50",
    "ratingCount": 6
  }
];
