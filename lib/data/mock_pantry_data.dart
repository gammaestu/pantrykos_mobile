import 'package:flutter/material.dart';
import '../models/recipe_model.dart';

/// Rich, authentic Indonesian Anak-Kos mock dataset for PantryKos.
class MockPantryData {
  MockPantryData._();

  /// Complete catalog of Kulkas Virtual ingredients
  static const List<PantryIngredient> allIngredients = [
    // Karbohidrat
    PantryIngredient(
      id: 'nasi_sisa',
      name: 'Nasi Sisa Semalam',
      emoji: '🍚',
      category: IngredientCategory.karbohidrat,
      stockHint: '1 piring di Magic Com',
    ),
    PantryIngredient(
      id: 'indomie_goreng',
      name: 'Indomie Goreng',
      emoji: '🍜',
      category: IngredientCategory.karbohidrat,
      stockHint: 'Stok wajib anak kos',
    ),
    PantryIngredient(
      id: 'indomie_kuah',
      name: 'Indomie Kuah Soto',
      emoji: '🍲',
      category: IngredientCategory.karbohidrat,
      stockHint: 'Penyelamat hujan malam',
    ),
    PantryIngredient(
      id: 'roti_tawar',
      name: 'Roti Tawar',
      emoji: '🍞',
      category: IngredientCategory.karbohidrat,
      stockHint: 'Sisa 4 lembar',
    ),

    // Protein
    PantryIngredient(
      id: 'telur',
      name: 'Telur Ayam',
      emoji: '🥚',
      category: IngredientCategory.protein,
      stockHint: 'Sisa 4 butir di pintu kulkas',
    ),
    PantryIngredient(
      id: 'sosis',
      name: 'Sosis Sapi / Ayam',
      emoji: '🌭',
      category: IngredientCategory.protein,
      stockHint: 'Siap makan / goreng',
    ),
    PantryIngredient(
      id: 'kornet',
      name: 'Kornet Sapi Sachet',
      emoji: '🥫',
      category: IngredientCategory.protein,
      stockHint: '1 kaleng/sachet',
    ),
    PantryIngredient(
      id: 'tempe',
      name: 'Tempe Papan',
      emoji: '🫘',
      category: IngredientCategory.protein,
      stockHint: 'Setengah papan segar',
    ),
    PantryIngredient(
      id: 'keju',
      name: 'Keju Quick Melt',
      emoji: '🧀',
      category: IngredientCategory.protein,
      stockHint: '2 slice lembaran',
    ),
    PantryIngredient(
      id: 'tahu',
      name: 'Tahu Putih',
      emoji: '🧊',
      category: IngredientCategory.protein,
      stockHint: '3 potong di wadah air',
    ),

    // Bumbu Kos
    PantryIngredient(
      id: 'bawang_merah',
      name: 'Bawang Merah',
      emoji: '🧅',
      category: IngredientCategory.bumbuKos,
      stockHint: 'Bumbu dasar tumisan',
    ),
    PantryIngredient(
      id: 'bawang_putih',
      name: 'Bawang Putih',
      emoji: '🧄',
      category: IngredientCategory.bumbuKos,
      stockHint: 'Wangi gurih instan',
    ),
    PantryIngredient(
      id: 'cabai',
      name: 'Cabai Rawit Setan',
      emoji: '🌶️',
      category: IngredientCategory.bumbuKos,
      stockHint: 'Pedas nampol',
    ),
    PantryIngredient(
      id: 'kecap',
      name: 'Kecap Manis Sachet',
      emoji: '🫙',
      category: IngredientCategory.bumbuKos,
      stockHint: 'Manis legit karamel',
    ),
    PantryIngredient(
      id: 'daun_bawang',
      name: 'Daun Bawang',
      emoji: '🌿',
      category: IngredientCategory.bumbuKos,
      stockHint: 'Penyegar aroma masakan',
    ),
    PantryIngredient(
      id: 'tomat',
      name: 'Tomat Segar',
      emoji: '🍅',
      category: IngredientCategory.bumbuKos,
      stockHint: 'Asam segar alami',
    ),
    PantryIngredient(
      id: 'margarin',
      name: 'Margarin Sachet',
      emoji: '🧈',
      category: IngredientCategory.bumbuKos,
      stockHint: 'Pengganti minyak lebih gurih',
    ),
  ];

  /// Default active ingredients out-of-the-box so users immediately see
  /// a mix of "Siap Masak (100%)" and "Kurang 1 Bahan" badges.
  static const Set<String> defaultActiveIngredientIds = {
    'nasi_sisa',
    'indomie_goreng',
    'telur',
    'sosis',
    'tempe',
    'bawang_merah',
    'bawang_putih',
    'cabai',
    'kecap',
  };

  /// Simulated AI Fridge Scanner detections with confidence scores & normalized bounding boxes
  static const List<ScannedIngredientDetection> simulatedScanDetections = [
    ScannedIngredientDetection(
      ingredientId: 'telur',
      label: 'Telur Ayam',
      confidencePercent: 98,
      normalizedBox: Rect.fromLTWH(0.08, 0.16, 0.36, 0.22),
      freshnessTag: 'Segar • 4 Butir',
    ),
    ScannedIngredientDetection(
      ingredientId: 'indomie_goreng',
      label: 'Indomie Goreng',
      confidencePercent: 99,
      normalizedBox: Rect.fromLTWH(0.50, 0.14, 0.42, 0.24),
      freshnessTag: 'Kemasan Utuh',
    ),
    ScannedIngredientDetection(
      ingredientId: 'sosis',
      label: 'Sosis Sapi',
      confidencePercent: 94,
      normalizedBox: Rect.fromLTWH(0.10, 0.46, 0.38, 0.20),
      freshnessTag: 'Chiller Rak 2',
    ),
    ScannedIngredientDetection(
      ingredientId: 'daun_bawang',
      label: 'Daun Bawang',
      confidencePercent: 92,
      normalizedBox: Rect.fromLTWH(0.54, 0.44, 0.36, 0.21),
      freshnessTag: 'Siap Iris',
    ),
    ScannedIngredientDetection(
      ingredientId: 'keju',
      label: 'Keju Quick Melt',
      confidencePercent: 96,
      normalizedBox: Rect.fromLTWH(0.14, 0.71, 0.35, 0.18),
      freshnessTag: '2 Slice Tersisa',
    ),
    ScannedIngredientDetection(
      ingredientId: 'kornet',
      label: 'Kornet Sapi',
      confidencePercent: 95,
      normalizedBox: Rect.fromLTWH(0.53, 0.70, 0.37, 0.19),
      freshnessTag: '1 Sachet',
    ),
  ];

  /// Authentic Indonesian Anak-Kos Recipes
  static const List<RecipeModel> recipes = [
    // 1. Nasi Goreng Mawut Rice Cooker (100% Ready with default active ingredients!)
    RecipeModel(
      id: 'nasgor_mawut_magiccom',
      title: 'Nasi Goreng Mawut Rice Cooker',
      subtitle: 'Hemat gas! Perpaduan nasi sisa, Indomie goreng & sosis di satu panci.',
      description:
          'Solusi legendaris anak kos saat kompor habis gas atau malas cuci banyak piring. Cukup cemplungkan nasi sisa semalam, remahan Indomie Goreng, irisan sosis, dan bumbu kecap pedas langsung ke dalam Rice Cooker!',
      imageUrl:
          'https://images.unsplash.com/photo-1603133872878-684f208fb84b?auto=format&fit=crop&w=1000&q=80',
      primaryAccent: Color(0xFF3B82F6),
      secondaryAccent: Color(0xFF06B6D4),
      cookingTimeMinutes: 12,
      cookingTool: CookingTool.riceCooker,
      estimatedCostRupiah: 8000,
      calories: 540,
      difficulty: 'Gampang Banget',
      servings: '1-2 Porsi Kenyang',
      kosHackTip:
          'Gunakan nasi sisa semalam yang agak pera supaya hasil mawut tidak lembek saat diaduk di dalam teflon panci Rice Cooker.',
      ingredients: [
        RecipeIngredientItem(
          ingredientId: 'nasi_sisa',
          displayName: 'Nasi Sisa Semalam',
          measure: '1 piring penuh',
        ),
        RecipeIngredientItem(
          ingredientId: 'indomie_goreng',
          displayName: 'Indomie Goreng',
          measure: '1 bungkus (diremas)',
        ),
        RecipeIngredientItem(
          ingredientId: 'telur',
          displayName: 'Telur Ayam',
          measure: '1 butir',
        ),
        RecipeIngredientItem(
          ingredientId: 'sosis',
          displayName: 'Sosis Sapi / Ayam',
          measure: '2 buah, iris serong',
        ),
        RecipeIngredientItem(
          ingredientId: 'bawang_putih',
          displayName: 'Bawang Putih',
          measure: '2 siung, geprek cincang',
        ),
        RecipeIngredientItem(
          ingredientId: 'cabai',
          displayName: 'Cabai Rawit Setan',
          measure: '4 buah, iris tipis',
        ),
        RecipeIngredientItem(
          ingredientId: 'kecap',
          displayName: 'Kecap Manis Sachet',
          measure: '1.5 sdm',
        ),
      ],
      steps: [
        CookingStep(
          stepNumber: 1,
          title: 'Rebus Setengah Matang Mie di Rice Cooker',
          instruction:
              'Masukkan sedikit air ke panci Rice Cooker, tekan tombol Cook. Saat mendidih, rebus kepingan Indomie Goreng selama 2 menit saja lalu tiriskan airnya.',
          kosTip:
              'Sisakan sekitar 2 sendok makan air rebusan agar bumbu mudah menyatu dengan nasi nanti.',
          timerSeconds: 120,
          timerLabel: 'Rebus Mie Setengah Matang',
        ),
        CookingStep(
          stepNumber: 2,
          title: 'Tumis Bawang, Cabai & Sosis',
          instruction:
              'Tuang minyak bumbu Indomie ke dalam panci Rice Cooker yang kering. Masukkan bawang putih cincang, cabai rawit, dan irisan sosis. Tekan tombol Cook dan aduk hingga harum.',
          kosTip:
              'Jika tombol Rice Cooker membal ke Warm, tahan sebentar dengan sendok kayu atau tunggu 30 detik hingga thermostat panas kembali.',
          timerSeconds: 90,
          timerLabel: 'Tumis Bumbu & Sosis',
        ),
        CookingStep(
          stepNumber: 3,
          title: 'Orak-Arik Telur di Pinggir Panci',
          instruction:
              'Geser sosis ke tepi panci, pecahkan 1 butir telur ayam di tengah, diamkan 20 detik lalu orak-arik cepat menggunakan centong nasi plastik.',
          kosTip:
              'Jangan pakai sendok besi agar lapisan anti-lengket panci Rice Cooker kosan tetap awet!',
          timerSeconds: 45,
          timerLabel: 'Masak Orak-Arik Telur',
        ),
        CookingStep(
          stepNumber: 4,
          title: 'Aduk Mawut Nasi, Mie & Bumbu Kecap',
          instruction:
              'Masukkan nasi sisa, mie rebus, seluruh bumbu bubuk Indomie, dan kecap manis. Aduk rata selama 3 menit dalam mode Cook sampai berasap dan sedikit berkerak wangi.',
          kosTip:
              'Tutup Rice Cooker selama 1 menit terakhir agar uap panas meresapkan rasa bumbu ke dalam nasi.',
          timerSeconds: 180,
          timerLabel: 'Aduk & Matangkan Mawut',
        ),
      ],
    ),

    // 2. Tempe Penyet Sambal Bawang (100% Ready with default active ingredients!)
    RecipeModel(
      id: 'tempe_penyet_sambal_bawang',
      title: 'Tempe Penyet Sambal Bawang Kosan',
      subtitle: 'Lauk penyelamat tanggal tua! Gurih garing di luar, pedas nampol.',
      description:
          'Menu wajib akhir bulan yang rasanya nggak pernah gagal bikin nambah nasi. Tempe goreng garing dengan siraman minyak panas di atas ulekan bawang putih dan cabai rawit segar.',
      imageUrl:
          'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=1000&q=80',
      primaryAccent: Color(0xFF10B981),
      secondaryAccent: Color(0xFF3B82F6),
      cookingTimeMinutes: 10,
      cookingTool: CookingTool.teflon,
      estimatedCostRupiah: 5500,
      calories: 380,
      difficulty: 'Gampang Banget',
      servings: '1 Porsi + Nasi',
      kosHackTip:
          'Nggak punya cobek di kos? Bungkus cabai & bawang yang sudah digoreng layu pakai plastik bersih, lalu tumbuk dengan bagian bawah gelas belimbing tebal!',
      ingredients: [
        RecipeIngredientItem(
          ingredientId: 'tempe',
          displayName: 'Tempe Papan',
          measure: '4 potong tebal, kerat-kerat',
        ),
        RecipeIngredientItem(
          ingredientId: 'nasi_sisa',
          displayName: 'Nasi Sisa Semalam',
          measure: '1 porsi hangat',
        ),
        RecipeIngredientItem(
          ingredientId: 'bawang_putih',
          displayName: 'Bawang Putih',
          measure: '3 siung utuh',
        ),
        RecipeIngredientItem(
          ingredientId: 'bawang_merah',
          displayName: 'Bawang Merah',
          measure: '2 siung',
        ),
        RecipeIngredientItem(
          ingredientId: 'cabai',
          displayName: 'Cabai Rawit Setan',
          measure: '9 buah (sesuai nyali)',
        ),
      ],
      steps: [
        CookingStep(
          stepNumber: 1,
          title: 'Marinasi Kilat & Goreng Tempe',
          instruction:
              'Kerat-kerat permukaan tempe, lumuri sedikit air garam. Panaskan teflon dengan sedikit minyak, goreng tempe hingga kedua sisinya kuning keemasan dan garing.',
          kosTip:
              'Keratan tipis di permukaan tempe membuat bagian luarnya ekstra crispy dan bumbunya meresap sampai ke tengah.',
          timerSeconds: 210,
          timerLabel: 'Goreng Tempe Hingga Garing',
        ),
        CookingStep(
          stepNumber: 2,
          title: 'Goreng Layu Cabai & Bawang',
          instruction:
              'Di sisa minyak teflon, masukkan cabai rawit, bawang putih, dan bawang merah selama 45 detik saja supaya mudah dihaluskan dan tidak meletup.',
          kosTip:
              'Tusuk sedikit ujung cabai rawit dengan garpu sebelum digoreng supaya cabai tidak meledak di teflon!',
          timerSeconds: 45,
          timerLabel: 'Layukan Cabai & Bawang',
        ),
        CookingStep(
          stepNumber: 3,
          title: 'Penyet & Siram Minyak Panas',
          instruction:
              'Tumbuk kasar cabai dan bawang bersama garam & sejumput gula. Siram 1 sendok makan minyak bekas goreng tempe yang masih panas mendesis, lalu penyet tempe di atasnya!',
          kosTip:
              'Sajikan langsung di atas nasi hangat supaya sari sambal bawangnya meresap ke nasi.',
        ),
      ],
    ),

    // 3. Nasi Gila Sosis Teflon (Kurang 1 Bahan: Daun Bawang with default active!)
    RecipeModel(
      id: 'nasi_gila_sosis_teflon',
      title: 'Nasi Gila Sosis & Telur Teflon',
      subtitle: 'Tumisan sosis telur pedas manis ala gerobak malam Jakarta.',
      description:
          'Rindu jajanan Nasi Gila tengah malam tapi uang saku menipis? Bikin sendiri versi teflon dengan potongan sosis melimpah, telur orak-arik lembut, dan saus kecap cabai yang kental menggugah selera.',
      imageUrl:
          'https://images.unsplash.com/photo-1512058564366-18510be2db19?auto=format&fit=crop&w=1000&q=80',
      primaryAccent: Color(0xFF2563EB),
      secondaryAccent: Color(0xFFF59E0B),
      cookingTimeMinutes: 10,
      cookingTool: CookingTool.teflon,
      estimatedCostRupiah: 9500,
      calories: 510,
      difficulty: 'Mudah',
      servings: '1 Porsi Jumbonya Kos',
      kosHackTip:
          'Masukkan kecap manis langsung ke pinggiran teflon yang sangat panas sebelum diaduk agar muncul aroma smoky karamel khas abang-abang gerobak.',
      ingredients: [
        RecipeIngredientItem(
          ingredientId: 'nasi_sisa',
          displayName: 'Nasi Sisa Semalam',
          measure: '1 piring',
        ),
        RecipeIngredientItem(
          ingredientId: 'sosis',
          displayName: 'Sosis Sapi / Ayam',
          measure: '3 buah, iris bulat',
        ),
        RecipeIngredientItem(
          ingredientId: 'telur',
          displayName: 'Telur Ayam',
          measure: '1 butir',
        ),
        RecipeIngredientItem(
          ingredientId: 'bawang_merah',
          displayName: 'Bawang Merah',
          measure: '3 siung, iris tipis',
        ),
        RecipeIngredientItem(
          ingredientId: 'bawang_putih',
          displayName: 'Bawang Putih',
          measure: '2 siung, cincang',
        ),
        RecipeIngredientItem(
          ingredientId: 'cabai',
          displayName: 'Cabai Rawit Setan',
          measure: '5 buah, iris serong',
        ),
        RecipeIngredientItem(
          ingredientId: 'kecap',
          displayName: 'Kecap Manis Sachet',
          measure: '2 sdm',
        ),
        RecipeIngredientItem(
          ingredientId: 'daun_bawang',
          displayName: 'Daun Bawang',
          measure: '1 batang, iris halus',
        ),
      ],
      steps: [
        CookingStep(
          stepNumber: 1,
          title: 'Bikin Orak-Arik Telur Setengah Matang',
          instruction:
              'Panaskan teflon, kocok lepas 1 butir telur dengan sedikit garam. Masak orak-arik cepat selama 40 detik selagi masih lembut, lalu sisihkan di piring.',
          kosTip:
              'Jangan masak telur terlalu kering di awal karena nanti akan dimasak lagi bersama saus.',
          timerSeconds: 40,
          timerLabel: 'Orak-Arik Telur Lembut',
        ),
        CookingStep(
          stepNumber: 2,
          title: 'Tumis Bawang, Cabai & Sosis Sampai Mekar',
          instruction:
              'Tumis bawang merah, bawang putih, dan cabai rawit hingga harum. Masukkan irisan sosis dan masak hingga pinggirannya sedikit kecokelatan.',
          kosTip:
              'Api sedang-besar membuat sosis cepat garing di luar namun tetap juicy di dalam.',
          timerSeconds: 90,
          timerLabel: 'Tumis Sosis & Bumbu',
        ),
        CookingStep(
          stepNumber: 3,
          title: 'Karamelisasi Kecap & Siram ke Nasi',
          instruction:
              'Kembalikan telur orak-arik ke teflon, tuang kecap manis dan 3 sdm air. Masak hingga mendidih kental, taburi irisan daun bawang, lalu tuang di atas nasi hangat!',
          kosTip:
              'Aduk cepat selama 60 detik terakhir agar bumbu mengental sempurna menyelimuti sosis.',
          timerSeconds: 60,
          timerLabel: 'Karamelisasi Saus Gila',
        ),
      ],
    ),

    // 4. Omelet Mie Sosis Keju (Kurang 1 Bahan: Keju Quick Melt with default active!)
    RecipeModel(
      id: 'omelet_mie_sosis_keju',
      title: 'Omelet Mie Sosis Keju Lumer',
      subtitle: 'Upgrade Martabak Mie level sultan kos dengan lelehan keju gurih.',
      description:
          'Bosan makan Indomie gitu-gitu aja? Sulap jadi Omelet Mie tebal ala cafe dengan isian sosis dan keju quick melt di tengahnya. Renyah di bagian luar, lembut dan lumer begitu dibelah!',
      imageUrl:
          'https://images.unsplash.com/photo-1525351484163-7529414344d8?auto=format&fit=crop&w=1000&q=80',
      primaryAccent: Color(0xFFF59E0B),
      secondaryAccent: Color(0xFF3B82F6),
      cookingTimeMinutes: 10,
      cookingTool: CookingTool.teflon,
      estimatedCostRupiah: 9000,
      calories: 490,
      difficulty: 'Mudah',
      servings: '1 Porsi Tebal',
      kosHackTip:
          'Gunakan piring datar untuk membantu membalik omelet di teflon supaya bentuk bulatnya tetap utuh dan tidak hancur!',
      ingredients: [
        RecipeIngredientItem(
          ingredientId: 'indomie_goreng',
          displayName: 'Indomie Goreng',
          measure: '1 bungkus',
        ),
        RecipeIngredientItem(
          ingredientId: 'telur',
          displayName: 'Telur Ayam',
          measure: '2 butir',
        ),
        RecipeIngredientItem(
          ingredientId: 'sosis',
          displayName: 'Sosis Sapi / Ayam',
          measure: '1 buah, potong dadu kecil',
        ),
        RecipeIngredientItem(
          ingredientId: 'keju',
          displayName: 'Keju Quick Melt',
          measure: '1-2 lembar, potong memanjang',
        ),
        RecipeIngredientItem(
          ingredientId: 'cabai',
          displayName: 'Cabai Rawit Setan',
          measure: '2 buah, iris tipis',
        ),
      ],
      steps: [
        CookingStep(
          stepNumber: 1,
          title: 'Rebus Mie & Kocok Bersama Telur',
          instruction:
              'Rebus Indomie hingga lunak lalu tiriskan sampai benar-benar kering. Campurkan mie dengan bumbu Indomie, potongan sosis, cabai, dan 2 butir telur kocok.',
          kosTip:
              'Pastikan mie sudah agak hangat (tidak terlalu panas) sebelum dicampur telur agar telur tidak matang duluan.',
          timerSeconds: 150,
          timerLabel: 'Rebus Mie Instan',
        ),
        CookingStep(
          stepNumber: 2,
          title: 'Masak Lapisan Pertama & Isi Keju',
          instruction:
              'Panaskan teflon dengan api kecil. Tuang setengah adonan mie telur, tata lembaran keju di tengahnya, lalu tutup dengan sisa adonan mie.',
          kosTip:
              'Wajib gunakan api kecil agar bagian luar tidak gosong sebelum bagian tengahnya matang.',
          timerSeconds: 120,
          timerLabel: 'Masak Sisi Bawah Omelet',
        ),
        CookingStep(
          stepNumber: 3,
          title: 'Balik Omelet Hingga Keemasan & Lumer',
          instruction:
              'Balik omelet dengan hati-hati. Masak sisi satunya selama 90 detik sambil ditekan perlahan dengan spatula sampai keju di dalamnya meleleh sempurna.',
          kosTip:
              'Potong 4 bagian seperti pizza dan nikmati selagi hangat!',
          timerSeconds: 90,
          timerLabel: 'Matangkan Sisi Atas',
        ),
      ],
    ),

    // 5. Orak-Arik Telur Kornet Pedas (Kurang 1 Bahan: Kornet with default active!)
    RecipeModel(
      id: 'orak_arik_telur_kornet',
      title: 'Orak-Arik Telur Kornet Pedas Mercon',
      subtitle: 'Masak 8 menit selesai! Gurih berdaging, teman setia nasi hangat.',
      description:
          'Perpaduan kornet sapi gurih dan telur orak-arik dengan tumisan bawang merah serta cabai rawit melimpah. Satu resep ini bisa buat makan siang sekaligus disimpan buat makan malam!',
      imageUrl:
          'https://images.unsplash.com/photo-1582169296194-e4d644c48063?auto=format&fit=crop&w=1000&q=80',
      primaryAccent: Color(0xFF06B6D4),
      secondaryAccent: Color(0xFF3B82F6),
      cookingTimeMinutes: 8,
      cookingTool: CookingTool.teflon,
      estimatedCostRupiah: 10000,
      calories: 430,
      difficulty: 'Gampang Banget',
      servings: '2 Porsi Lauk',
      kosHackTip:
          'Tumis kornet lebih dulu sampai agak kering dan berwarna cokelat tua sebelum telur masuk—ini rahasia supaya kornet tidak amis dan super wangi!',
      ingredients: [
        RecipeIngredientItem(
          ingredientId: 'telur',
          displayName: 'Telur Ayam',
          measure: '2 butir',
        ),
        RecipeIngredientItem(
          ingredientId: 'kornet',
          displayName: 'Kornet Sapi Sachet',
          measure: '1 sachet (50g)',
        ),
        RecipeIngredientItem(
          ingredientId: 'bawang_merah',
          displayName: 'Bawang Merah',
          measure: '4 siung, iris tipis',
        ),
        RecipeIngredientItem(
          ingredientId: 'bawang_putih',
          displayName: 'Bawang Putih',
          measure: '2 siung, cincang',
        ),
        RecipeIngredientItem(
          ingredientId: 'cabai',
          displayName: 'Cabai Rawit Setan',
          measure: '7 buah, iris serong',
        ),
        RecipeIngredientItem(
          ingredientId: 'nasi_sisa',
          displayName: 'Nasi Sisa Semalam',
          measure: '1 piring hangat',
        ),
      ],
      steps: [
        CookingStep(
          stepNumber: 1,
          title: 'Tumis Harum Bawang & Cabai Mercon',
          instruction:
              'Panaskan 2 sdm minyak di teflon. Tumis bawang merah, bawang putih, dan irisan cabai rawit sampai layu dan aromanya menyebar ke seluruh kamar kos.',
          kosTip:
              'Buka sedikit jendela kamar kos supaya aroma pedas cabai tidak bikin bersin!',
          timerSeconds: 60,
          timerLabel: 'Tumis Bumbu Mercon',
        ),
        CookingStep(
          stepNumber: 2,
          title: 'Sangrai Kornet Sampai Wangi Karamel',
          instruction:
              'Masukkan kornet sapi sachet, tekan-tekan dengan spatula dan masak selama 2 menit hingga teksturnya berbulir agak kering dan berubah warna.',
          kosTip:
              'Kornet yang terkaramelisasi akan memberikan rasa smoky seperti daging asap.',
          timerSeconds: 120,
          timerLabel: 'Sangrai Kornet Sapi',
        ),
        CookingStep(
          stepNumber: 3,
          title: 'Pecahkan Telur & Aduk Cepat',
          instruction:
              'Pecahkan 2 butir telur langsung ke teflon. Biarkan 15 detik, lalu aduk cepat bersama kornet hingga menyatu dan matang merata.',
          kosTip:
              'Tidak perlu tambah banyak garam karena kornet sudah gurih asin.',
          timerSeconds: 60,
          timerLabel: 'Orak-Arik Telur & Kornet',
        ),
      ],
    ),

    // 6. Sup Telur Tomat Panci Listrik (Kurang 2 Bahan: Tomat, Daun Bawang)
    RecipeModel(
      id: 'sup_telur_tomat_panci_listrik',
      title: 'Sup Telur Tomat Serabut Panci Listrik',
      subtitle: 'Comfort food hangat 10 menit saat hujan atau badan lagi kurang fit.',
      description:
          'Sup rumahan bergaya oriental yang super praktis dimasak pakai Panci Listrik kosan. Kuah tomat segar berpadu dengan serabut telur lembut yang menenangkan perut.',
      imageUrl:
          'https://images.unsplash.com/photo-1547592166-23ac45744acd?auto=format&fit=crop&w=1000&q=80',
      primaryAccent: Color(0xFF0EA5E9),
      secondaryAccent: Color(0xFF10B981),
      cookingTimeMinutes: 10,
      cookingTool: CookingTool.panciListrik,
      estimatedCostRupiah: 7500,
      calories: 260,
      difficulty: 'Gampang Banget',
      servings: '1 Mangkuk Besar',
      kosHackTip:
          'Tuang kocokan telur perlahan dari ketinggian 15 cm sambil kuah diaduk memutar satu arah dengan garpu untuk menghasilkan serabut telur tipis ala restoran!',
      ingredients: [
        RecipeIngredientItem(
          ingredientId: 'telur',
          displayName: 'Telur Ayam',
          measure: '2 butir, kocok lepas',
        ),
        RecipeIngredientItem(
          ingredientId: 'tomat',
          displayName: 'Tomat Segar',
          measure: '2 buah, potong dadu',
        ),
        RecipeIngredientItem(
          ingredientId: 'bawang_putih',
          displayName: 'Bawang Putih',
          measure: '2 siung, geprek cincang',
        ),
        RecipeIngredientItem(
          ingredientId: 'daun_bawang',
          displayName: 'Daun Bawang',
          measure: '1 batang, iris kasar',
        ),
        RecipeIngredientItem(
          ingredientId: 'sosis',
          displayName: 'Sosis Sapi / Ayam',
          measure: '1 buah, iris tipis',
        ),
      ],
      steps: [
        CookingStep(
          stepNumber: 1,
          title: 'Tumis Bawang & Tomat di Panci Listrik',
          instruction:
              'Nyalakan Panci Listrik mode sedang. Tumis bawang putih hingga wangi, lalu masukkan potongan tomat dan sosis. Tekan-tekan tomat sampai mengeluarkan sari merah alaminya.',
          kosTip:
              'Menumis tomat terlebih dahulu di awal membuat warna kuah sup merah cantik dan rasanya jauh lebih gurih.',
          timerSeconds: 90,
          timerLabel: 'Tumis Tomat Sampai Lumat',
        ),
        CookingStep(
          stepNumber: 2,
          title: 'Didihkan Kuah Kaldu Hangat',
          instruction:
              'Tuang 400ml air matang ke dalam panci listrik, bumbui dengan garam, lada, dan sejumput gula pasir. Tunggu hingga air mendidih berbuih.',
          kosTip:
              'Sejumput kecil gula pasir akan menyeimbangkan rasa asam dari tomat segar.',
          timerSeconds: 150,
          timerLabel: 'Didihkan Kuah Sup',
        ),
        CookingStep(
          stepNumber: 3,
          title: 'Bikin Serabut Telur & Tabur Daun Bawang',
          instruction:
              'Aduk kuah memutar, tuang kocokan telur perlahan hingga membentuk serabut halus. Taburkan daun bawang, matikan panci listrik, dan sajikan hangat!',
          kosTip:
              'Segera matikan listrik begitu telur masuk agar tekstur serabut telur tetap selembut sutra.',
          timerSeconds: 30,
          timerLabel: 'Bentuk Serabut Telur',
        ),
      ],
    ),

    // 7. Indomie Kuah Susu Keju Panci Listrik
    RecipeModel(
      id: 'indomie_hack_keju_panci',
      title: 'Indomie Kuah Creamy Keju Telur',
      subtitle: 'Hack viral anak kos: kuah kental gurih keju dengan telur setengah matang.',
      description:
          'Upgrade Indomie Kuah biasa menjadi hidangan ramen creamy ala Jepang hanya dengan Panci Listrik. Lelehan keju quick melt dan kuning telur setengah matang bikin kuahnya super kental!',
      imageUrl:
          'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=1000&q=80',
      primaryAccent: Color(0xFF6366F1),
      secondaryAccent: Color(0xFF06B6D4),
      cookingTimeMinutes: 7,
      cookingTool: CookingTool.panciListrik,
      estimatedCostRupiah: 8500,
      calories: 480,
      difficulty: 'Gampang Banget',
      servings: '1 Mangkuk Ramen',
      kosHackTip:
          'Gunakan hanya 2/3 takaran bumbu bubuk Indomie karena lelehan keju sudah menambah rasa gurih asin pada kuah.',
      ingredients: [
        RecipeIngredientItem(
          ingredientId: 'indomie_kuah',
          displayName: 'Indomie Kuah Soto',
          measure: '1 bungkus',
        ),
        RecipeIngredientItem(
          ingredientId: 'telur',
          displayName: 'Telur Ayam',
          measure: '1 butir',
        ),
        RecipeIngredientItem(
          ingredientId: 'keju',
          displayName: 'Keju Quick Melt',
          measure: '1 lembar',
        ),
        RecipeIngredientItem(
          ingredientId: 'sosis',
          displayName: 'Sosis Sapi / Ayam',
          measure: '1 buah, kerat mekar',
        ),
        RecipeIngredientItem(
          ingredientId: 'cabai',
          displayName: 'Cabai Rawit Setan',
          measure: '3 buah, iris',
        ),
      ],
      steps: [
        CookingStep(
          stepNumber: 1,
          title: 'Rebus Mie & Sosis Mekar',
          instruction:
              'Didihkan 300ml air di Panci Listrik. Masukkan mie dan sosis yang sudah dikerat ujungnya selama 2 menit hingga sosis mekar.',
          kosTip:
              'Jangan pakai air terlalu banyak supaya kuahnya nanti kental dan creamy.',
          timerSeconds: 120,
          timerLabel: 'Rebus Mie & Sosis',
        ),
        CookingStep(
          stepNumber: 2,
          title: 'Poach Telur & Lelehkan Keju',
          instruction:
              'Masukkan bumbu, pecahkan telur utuh di tengah mie (jangan diaduk), dan letakkan selembar keju quick melt di atasnya. Tutup panci selama 60 detik.',
          kosTip:
              'Menutup panci membuat uap panas melelehkan keju sekaligus mematangkan putih telur sementara kuningnya tetap lumer.',
          timerSeconds: 60,
          timerLabel: 'Lelehkan Keju & Telur',
        ),
      ],
    ),

    // 8. Nasi Telur Pontianak Rice Cooker
    RecipeModel(
      id: 'nasi_telur_pontianak_magiccom',
      title: 'Nasi Telur Ceplok Bawang Putih Kecap',
      subtitle: 'Viral & super hemat! Telur ceplok setengah matang disiram bawang putih kecap.',
      description:
          'Menu penyelamat ketika stok kulkas hampir kosong. Cukup telur ayam, bawang putih cincang wangi, cabai, dan saus kecap manis gurih yang meresap ke nasi hangat.',
      imageUrl:
          'https://images.unsplash.com/photo-1525351484163-7529414344d8?auto=format&fit=crop&w=1000&q=80',
      primaryAccent: Color(0xFF10B981),
      secondaryAccent: Color(0xFF3B82F6),
      cookingTimeMinutes: 6,
      cookingTool: CookingTool.riceCooker,
      estimatedCostRupiah: 5000,
      calories: 390,
      difficulty: 'Gampang Banget',
      servings: '1 Porsi Hemat',
      kosHackTip:
          'Siram campuran kecap manis dan bawang putih langsung di atas putih telur saat masih mendesis agar kecapnya berbusa dan wangi karamel!',
      ingredients: [
        RecipeIngredientItem(
          ingredientId: 'nasi_sisa',
          displayName: 'Nasi Sisa Semalam',
          measure: '1 piring hangat',
        ),
        RecipeIngredientItem(
          ingredientId: 'telur',
          displayName: 'Telur Ayam',
          measure: '1-2 butir',
        ),
        RecipeIngredientItem(
          ingredientId: 'bawang_putih',
          displayName: 'Bawang Putih',
          measure: '3 siung, cincang halus',
        ),
        RecipeIngredientItem(
          ingredientId: 'kecap',
          displayName: 'Kecap Manis Sachet',
          measure: '2 sdm',
        ),
        RecipeIngredientItem(
          ingredientId: 'cabai',
          displayName: 'Cabai Rawit Setan',
          measure: '3 buah, iris kecil',
        ),
      ],
      steps: [
        CookingStep(
          stepNumber: 1,
          title: 'Goreng Bawang Putih Cincang di Panci',
          instruction:
              'Panaskan 2 sdm minyak di dalam panci Rice Cooker (atau teflon). Masukkan bawang putih cincang dan cabai, goreng 45 detik sampai kuning keemasan.',
          kosTip:
              'Perhatikan warna bawang putih—begitu mulai kuning langsat langsung lanjutkan ke langkah berikutnya agar tidak pahit.',
          timerSeconds: 45,
          timerLabel: 'Goreng Bawang Putih Wangi',
        ),
        CookingStep(
          stepNumber: 2,
          title: 'Ceplok Telur & Siram Saus Kecap',
          instruction:
              'Pecahkan telur tepat di atas bawang putih goreng. Saat pinggiran putih telur mulai garing berenda, tuang kecap manis mengelilingi telur dan biarkan mendidih 40 detik.',
          kosTip:
              'Angkat selagi kuning telur masih setengah matang dan pecahkan di atas nasi hangat!',
          timerSeconds: 45,
          timerLabel: 'Masak Telur Ceplok Kecap',
        ),
      ],
    ),
  ];

  /// Helper to look up a PantryIngredient by ID
  static PantryIngredient? findIngredientById(String id) {
    for (final item in allIngredients) {
      if (item.id == id) return item;
    }
    return null;
  }
}
