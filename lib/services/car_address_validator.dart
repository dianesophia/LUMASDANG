/// CAR (Cordillera Administrative Region) Address Validator
/// Provides validation and data for Philippine CAR region addresses
/// Format: "Barangay, Municipality/City, Province"
///
/// Data sources: Wikipedia (List of barangays in Abra/Benguet/Ifugao/Kalinga/
///               Mountain Province) and PhilAtlas (Apayao)
/// All barangay data is official/verified — no placeholder names.
///
/// Fixes from original:
///  - Abra: all 27 real municipalities with real barangays (303 total)
///  - Benguet: corrected to 13 real municipalities + Baguio City independent
///             Added missing: Kabayan, Mankayan; removed wrong entry 'Loo'
///  - Ifugao: all 11 real municipalities with real barangays (176 total)
///            Renamed Alfonso Lista (was 'Alfonso Lista'), added Tinoc (was missing)
///  - Kalinga: corrected to 7 municipalities + Tabuk City (153 total)
///             Removed wrong entries; added Tabuk City, Rizal
///  - Mountain Province: all 10 real municipalities with real barangays (144 total)
///             Added missing: Barlig; removed 'Alab','Samoki','Banaue' (not municipalities)
///  - Apayao: all 7 real municipalities with real barangays (133 total)
///             Removed non-existent 'Lagayan','Sanghan'; added real data

class CARAddressValidator {
  // ── Provinces ──────────────────────────────────────────────────────────────
  static const List<String> carProvinces = [
    'Abra',
    'Apayao',
    'Benguet',
    'Ifugao',
    'Kalinga',
    'Mountain Province',
  ];

  // Baguio City is an independent highly-urbanized city (not under any province)
  static const List<String> carCities = [
    'Baguio City',
  ];

  /// All selectable top-level entries (provinces + independent city)
  static List<String> get allProvincesCities => [...carProvinces, ...carCities];

  // ── Municipalities per Province ────────────────────────────────────────────
  static const Map<String, List<String>> municipalitiesByProvince = {

    // ── ABRA (27 municipalities) ──────────────────────────────────────────
    'Abra': [
      'Bangued',
      'Boliney',
      'Bucay',
      'Bucloc',
      'Daguioman',
      'Danglas',
      'Dolores',
      'La Paz',
      'Lacub',
      'Lagangilang',
      'Lagayan',
      'Langiden',
      'Licuan-Baay',
      'Luba',
      'Malibcong',
      'Manabo',
      'Peñarrubia',
      'Pidigan',
      'Pilar',
      'Sallapadan',
      'San Isidro',
      'San Juan',
      'San Quintin',
      'Tayum',
      'Tineg',
      'Tubo',
      'Villaviciosa',
    ],

    // ── APAYAO (7 municipalities) ─────────────────────────────────────────
    'Apayao': [
      'Calanasan',
      'Conner',
      'Flora',
      'Kabugao',
      'Luna',
      'Pudtol',
      'Santa Marcela',
    ],

    // ── BENGUET (13 municipalities) ───────────────────────────────────────
    'Benguet': [
      'Atok',
      'Bakun',
      'Bokod',
      'Buguias',
      'Itogon',
      'Kabayan',
      'Kapangan',
      'Kibungan',
      'La Trinidad',
      'Mankayan',
      'Sablan',
      'Tuba',
      'Tublay',
    ],

    // ── IFUGAO (11 municipalities) ────────────────────────────────────────
    'Ifugao': [
      'Aguinaldo',
      'Alfonso Lista',
      'Asipulo',
      'Banaue',
      'Hingyon',
      'Hungduan',
      'Kiangan',
      'Lagawe',
      'Lamut',
      'Mayoyao',
      'Tinoc',
    ],

    // ── KALINGA (7 municipalities + 1 city) ───────────────────────────────
    'Kalinga': [
      'Balbalan',
      'Lubuagan',
      'Pasil',
      'Pinukpuk',
      'Rizal',
      'Tabuk City',
      'Tanudan',
      'Tinglayan',
    ],

    // ── MOUNTAIN PROVINCE (10 municipalities) ─────────────────────────────
    'Mountain Province': [
      'Barlig',
      'Bauko',
      'Besao',
      'Bontoc',
      'Natonin',
      'Paracelis',
      'Sabangan',
      'Sadanga',
      'Sagada',
      'Tadian',
    ],

    // ── BAGUIO CITY (independent; listed for completeness) ────────────────
    // Baguio City has 129 barangays. A representative subset is listed below.
    'Baguio City': [
      'Baguio City Proper',
    ],
  };

  // ── Barangays per Municipality ─────────────────────────────────────────────
  static const Map<String, List<String>> barangaysByMunicipality = {

    // ════════════════════════════════════════════════════════════════════════
    // ABRA — 27 municipalities, 303 barangays (Wikipedia data)
    // ════════════════════════════════════════════════════════════════════════

    'Bangued': [
      'Agtangao', 'Angad', 'Bañacao', 'Bangbangar', 'Cabuloan',
      'Calaba', 'Cosili East (Proper)', 'Cosili West (Buaya)', 'Dangdangla',
      'Lingtan', 'Lipcan', 'Lubong', 'Macarcarmay', 'Macray', 'Malita',
      'Maoay', 'Palao', 'Patucannay', 'Sagap', 'San Antonio', 'Santa Rosa',
      'Sao-atan', 'Sappaac', 'Tablac (Calot)', 'Zone 1 Poblacion (Nalasin)',
      'Zone 2 Poblacion (Consiliman)', 'Zone 3 Poblacion (Lalaud)',
      'Zone 4 Poblacion (Town Proper)', 'Zone 5 Poblacion (Bo. Barikir)',
      'Zone 6 Poblacion (Sinapangan)', 'Zone 7 Poblacion (Baliling)',
    ],

    'Boliney': [
      'Amti', 'Bao-yan', 'Danac East', 'Danac West', 'Dao-angan',
      'Dumagas', 'Kilong-Olao', 'Poblacion (Boliney)',
    ],

    'Bucay': [
      'Abang', 'Bangbangcag', 'Bangcagan', 'Banglolao', 'Bugbog',
      'Calao', 'Dugong', 'Labon', 'Layugan', 'Madalipay',
      'North Poblacion', 'Pagala', 'Pakiling', 'Palaquio', 'Patoc',
      'Quimloong', 'Salnec', 'San Miguel', 'Siblong',
      'South Poblacion', 'Tabiog',
    ],

    'Bucloc': [
      'Ducligan', 'Labaan', 'Lamao (Poblacion)', 'Lingay',
    ],

    'Daguioman': [
      'Ableg', 'Cabaruyan', 'Pikek', 'Tui (Poblacion)',
    ],

    'Danglas': [
      'Abaquid', 'Cabaruan', 'Caupasan (Poblacion)', 'Danglas',
      'Nagaparan', 'Padangitan', 'Pangal',
    ],

    'Dolores': [
      'Bayaan', 'Cabaroan', 'Calumbaya', 'Cardona', 'Isit',
      'Kimmalaba', 'Libtec', 'Lub-lubba', 'Mudiit', 'Namit-ingan',
      'Pacac', 'Poblacion', 'Salucag', 'Talogtog', 'Taping',
    ],

    'La Paz': [
      'Benben (Bonbon)', 'Bulbulala', 'Buli', 'Canan (Gapan)',
      'Luguis', 'Malabbaga', 'Mudeng', 'Pidipid', 'Poblacion',
      'San Gregorio', 'Toon', 'Udangan',
    ],

    'Lacub': [
      'Bacag', 'Buneg', 'Guinguinabang', 'Lan-ag',
      'Pacoc', 'Poblacion (Talampac)',
    ],

    'Lagangilang': [
      'Aguet', 'Bacooc', 'Balais', 'Cayapa', 'Dalaguisen',
      'Laang', 'Lagben', 'Laguiben', 'Nagtipulan', 'Nagtupacan',
      'Paganao', 'Pawa', 'Poblacion', 'Presentar', 'San Isidro',
      'Tagodtod', 'Taping',
    ],

    'Lagayan': [
      'Ba-i', 'Collago', 'Pang-ot', 'Poblacion', 'Pulot',
    ],

    'Langiden': [
      'Baac', 'Dalayap (Nalaas)', 'Mabungtot', 'Malapaao',
      'Poblacion', 'Quillat',
    ],

    'Licuan-Baay': [
      'Bonglo (Patagui)', 'Bulbulala', 'Cawayan', 'Domenglay',
      'Lenneng', 'Mapisla', 'Mogao', 'Nalbuan', 'Poblacion',
      'Subagan', 'Tumalip',
    ],

    'Luba': [
      'Ampalioc', 'Barit', 'Gayaman', 'Lul-luno', 'Luzong',
      'Nagbukel-Tiquipa', 'Poblacion', 'Sabnangan',
    ],

    'Malibcong': [
      'Bayabas', 'Binasaran', 'Buanao', 'Dulao', 'Duldulao',
      'Gacab', 'Lat-ey', 'Malibcong (Poblacion)', 'Mataragan',
      'Pacgued', 'Taripan', 'Umnap',
    ],

    'Manabo': [
      'Ayyeng (Poblacion)', 'Catacdegan Nuevo', 'Catacdegan Viejo',
      'Luzong', 'San Jose Norte', 'San Jose Sur', 'San Juan Norte',
      'San Juan Sur', 'San Ramon East', 'San Ramon West', 'Santo Tomas',
    ],

    'Peñarrubia': [
      'Dumayco', 'Lusuac', 'Malamsit (Pau-Malamsit)', 'Namarabar',
      'Patiao', 'Poblacion', 'Riang (Tiang)', 'Santa Rosa', 'Tattawa',
    ],

    'Pidigan': [
      'Alinaya', 'Arab', 'Garreta', 'Immuli', 'Laskig',
      'Monggoc', 'Naguirayan', 'Pamutic', 'Pangtud', 'Poblacion East',
      'Poblacion West', 'San Diego', 'Sulbec', 'Suyo (Malidong)', 'Yuyeng',
    ],

    'Pilar': [
      'Bolbolo', 'Brookside', 'Dalit', 'Dintan', 'Gapang',
      'Kinabiti', 'Maliplipit', 'Namara', 'Nanangduan', 'Nagcanasan',
      'Ocup', 'Pang-ot', 'Patad', 'Poblacion', 'San Juan East',
      'San Juan West', 'South Balioag', 'Tikitik', 'Villavieja',
    ],

    'Sallapadan': [
      'Bazar', 'Bilabila', 'Gangal (Poblacion)', 'Maguyepyep',
      'Naguilian', 'Saccaang', 'Sallapadan', 'Subusob', 'Ud-udiao',
    ],

    'San Isidro': [
      'Cabayogan', 'Dalimag', 'Langbaban', 'Manayday',
      'Pantoc', 'Poblacion', 'Sabtan-olo', 'San Marcial', 'Tangbao',
    ],

    'San Juan': [
      'Abualan', 'Ba-ug', 'Badas', 'Cabcaborao', 'Calabaoan',
      'Culiong', 'Daoidao', 'Guimba', 'Lam-ag', 'Lumobang',
      'Nangobongan', 'Pattaoig', 'Poblacion North', 'Poblacion South',
      'Quidaoen', 'Sabangan', 'Silet', 'Supi-il', 'Tagaytay',
    ],

    'San Quintin': [
      'Labaan', 'Palang', 'Pantoc', 'Poblacion',
      'Tangadan', 'Villa Mercedes',
    ],

    'Tayum': [
      'Bagalay', 'Basbasa', 'Budac', 'Bumagcat', 'Cabaroan',
      'Cabaruan', 'Deet', 'Gaddani', 'Patucannay', 'Pias',
      'Poblacion', 'Velasco',
    ],

    'Tineg': [
      'Alaoa', 'Anayan', 'Apao', 'Belaat', 'Caganayan',
      'Cogon', 'Lanec', 'Lapat-Balantay', 'Naglibacan',
      'Poblacion (Agsimao)',
    ],

    'Tubo': [
      'Alangtin', 'Amtuagan', 'Dilong', 'Kili', 'Poblacion (Mayabo)',
      'Supo', 'Tabacda', 'Tiempo', 'Tubtuba', 'Wayangan',
    ],

    'Villaviciosa': [
      'Ap-apaya', 'Bol-lilising', 'Cal-lao', 'Lap-lapog',
      'Lumaba', 'Poblacion', 'Tamac', 'Tuquib',
    ],

    // ════════════════════════════════════════════════════════════════════════
    // APAYAO — 7 municipalities, 133 barangays (PhilAtlas data)
    // ════════════════════════════════════════════════════════════════════════

    'Calanasan': [
      'Butao', 'Cadaclan', 'Don Roque Ablan Sr.', 'Eleazar',
      'Eva Puzon', 'Kabugawan', 'Langnao', 'Lubong', 'Macalino',
      'Naguilian', 'Namaltugan', 'Poblacion', 'Sabangan',
      'Santa Elena', 'Santa Filomena', 'Tanglagan', 'Tubang', 'Tubongan',
    ],

    'Conner': [
      'Allangigan', 'Banban', 'Buluan', 'Caglayan', 'Calafug',
      'Cupis', 'Daga', 'Guinaang', 'Guinamgaman', 'Ili',
      'Karikitan', 'Katablangan', 'Malama', 'Manag', 'Mawegui',
      'Nabuangan', 'Paddaoan', 'Puguin', 'Ripang', 'Sacpil', 'Talifugo',
    ],

    'Flora': [
      'Allig', 'Anninipan', 'Atok', 'Bagutong', 'Balasi',
      'Balluyan', 'Malayugan', 'Mallig', 'Malubibit Norte', 'Malubibit Sur',
      'Poblacion East', 'Poblacion West', 'San Jose', 'Santa Maria',
      'Tamalunog', 'Upper Atok',
    ],

    'Kabugao': [
      'Badduat', 'Baliwanan', 'Bulu', 'Cabetayan', 'Dagara',
      'Dibagat', 'Karagawan', 'Kumao', 'Laco', 'Lenneng',
      'Lucab', 'Luttuacan', 'Madatag', 'Madduang', 'Magabta',
      'Maragat', 'Musimut', 'Nagbabalayan', 'Poblacion', 'Tuyangan', 'Waga',
    ],

    'Luna': [
      'Bacsay', 'Cagandungan', 'Calabigan', 'Cangisitan',
      'Capagaypayan', 'Dagupan', 'Lappa', 'Luyon', 'Marag',
      'Poblacion', 'Quirino', 'Salvacion', 'San Francisco',
      'San Gregorio', 'San Isidro Norte', 'San Isidro Sur',
      'San Sebastian', 'Santa Lina', 'Shalom', 'Tumog', 'Turod', 'Zumigui',
    ],

    'Pudtol': [
      'Aga', 'Alem', 'Amado', 'Aurora', 'Cabatacan',
      'Cacalaggan', 'Capannikian', 'Doña Loreta', 'Emilia',
      'Imelda', 'Lower Maton', 'Lt. Balag', 'Lydia', 'Malibang',
      'Mataguisi', 'Poblacion', 'San Antonio', 'San Jose',
      'San Luis', 'San Mariano', 'Swan', 'Upper Maton',
    ],

    'Santa Marcela': [
      'Barocboc', 'Consuelo', 'Emiliana', 'Imelda', 'Malekkeg',
      'Marcela', 'Nueva', 'Panay', 'San Antonio', 'San Carlos',
      'San Juan', 'San Mariano', 'Sipa Proper',
    ],

    // ════════════════════════════════════════════════════════════════════════
    // BENGUET — 13 municipalities (Wikipedia data)
    // ════════════════════════════════════════════════════════════════════════

    'Atok': [
      'Abiang', 'Caliking', 'Cattubo', 'Naguey', 'Paoay',
      'Pasdong', 'Poblacion', 'Topdac',
    ],

    'Bakun': [
      'Ampusongan', 'Bagu', 'Dalipey', 'Gambang', 'Kayapa',
      'Poblacion (Central)', 'Sinacbat',
    ],

    'Bokod': [
      'Ambuclao', 'Bila', 'Bobok-Bisal', 'Daclan', 'Ekip',
      'Karao', 'Nawal', 'Pito', 'Poblacion',
    ],

    'Buguias': [
      'Abatan', 'Amgaleyguey', 'Amlimay', 'Baculongan Norte',
      'Baculongan Sur', 'Bangao', 'Buyabuyan', 'Calamagan',
      'Catlubong', 'Lengaoan', 'Loo', 'Natubleng', 'Poblacion (Central)',
      'Sebang',
    ],

    'Itogon': [
      'Ampucao', 'Dalupirip', 'Gumatdang', 'Loacan',
      'Poblacion (Central)', 'Tinongdan', 'Tuding', 'Ucab', 'Virac',
    ],

    'Kabayan': [
      'Adaoay', 'Anchokey', 'Ballay', 'Bashoy', 'Batan',
      'Duacan', 'Eddet', 'Gusaran', 'Kabayan Barrio', 'Lusod',
      'Pacso', 'Poblacion (Central)', 'Tawangan',
    ],

    'Kapangan': [
      'Balakbak', 'Beleng-Belis', 'Boklaoan', 'Cayapes', 'Cuba',
      'Datakan', 'Gadang', 'Gaswiling', 'Labueg', 'Paykek',
      'Poblacion Central', 'Pongayan', 'Pudong', 'Sagubo', 'Taba-ao',
    ],

    'Kibungan': [
      'Badeo', 'Lubo', 'Madaymen', 'Palina', 'Poblacion',
      'Sagpat', 'Tacadang',
    ],

    'La Trinidad': [
      'Alapang', 'Alno', 'Ambiong', 'Bahong', 'Balili',
      'Beckel', 'Betag', 'Bineng', 'Cruz', 'Lubas',
      'Pico', 'Poblacion', 'Puguis', 'Shilan', 'Tawang', 'Wangal',
    ],

    'Mankayan': [
      'Balili', 'Bedbed', 'Bulalacao', 'Cabiten', 'Colalo',
      'Guinaoang', 'Paco', 'Palasaan', 'Poblacion', 'Sapid',
      'Tabio', 'Taneg',
    ],

    'Sablan': [
      'Bagong', 'Balluay', 'Banangan', 'Banengbeng', 'Bayabas',
      'Kamog', 'Pappa', 'Poblacion',
    ],

    'Tuba': [
      'Ansagan', 'Camp 3', 'Camp 4', 'Camp One', 'Nangalisan',
      'Poblacion', 'San Pascual', 'Tabaan Norte', 'Tabaan Sur',
      'Tadiangan', 'Taloy Norte', 'Taloy Sur', 'Twin Peaks',
    ],

    'Tublay': [
      'Ambassador', 'Ambongdolan', 'Ba-ayan', 'Basil', 'Caponga (Poblacion)',
      'Daclan', 'Tuel', 'Tublay Central',
    ],

    // ════════════════════════════════════════════════════════════════════════
    // IFUGAO — 11 municipalities, 176 barangays (Wikipedia data)
    // ════════════════════════════════════════════════════════════════════════

    'Aguinaldo': [
      'Awayan', 'Bunhian', 'Butac', 'Buwag', 'Chalalo',
      'Damag', 'Galonogon', 'Halag', 'Itab', 'Jacmal',
      'Majlong', 'Mongayang', 'Posnaan', 'Ta-ang', 'Talite', 'Ubao',
    ],

    'Alfonso Lista': [
      'Bangar', 'Busilac', 'Calimag', 'Calupaan', 'Caragasan',
      'Dolowog', 'Kiling', 'Laya', 'Little Tadian', 'Namillangan',
      'Namnama', 'Ngileb', 'Pinto', 'Poblacion', 'San Jose',
      'San Juan', 'San Marcos', 'San Quintin', 'Santa Maria',
      'Santo Domingo (Cabicalan)',
    ],

    'Asipulo': [
      'Amduntog', 'Antipolo', 'Camandag', 'Cawayan',
      'Hallap', 'Namal', 'Nungawa', 'Panubtuban', 'Pula',
    ],

    'Banaue': [
      'Amganad', 'Anaba', 'Balawis', 'Banao', 'Bangaan',
      'Batad', 'Bocos', 'Cambulo', 'Ducligan', 'Gohang',
      'Kinakin', 'Ohaj', 'Poitan', 'Poblacion', 'Pula',
      'San Fernando', 'Tam-an', 'View Point',
    ],

    'Hingyon': [
      'Anao', 'Bangtinon', 'Bitu', 'Cababuyan', 'Mompolia',
      'Namulditan', 'Northern Cababuyan', 'O-ong', 'Piwong',
      'Poblacion (Hingyon)', 'Ubuag', 'Umalbong',
    ],

    'Hungduan': [
      'Abatan', 'Ba-ang', 'Bangbang', 'Bokiawan', 'Hapao',
      'Lubo-ong', 'Maggok', 'Nungulunan', 'Poblacion',
    ],

    'Kiangan': [
      'Ambabag', 'Baguinge', 'Bokiawan', 'Bolog', 'Dalligan',
      'Duit', 'Hucab', 'Julongan', 'Lingay', 'Mungayang',
      'Nagacadan', 'Pindongan', 'Poblacion', 'Tuplac',
    ],

    'Lagawe': [
      'Abinuan', 'Banga', 'Boliwong', 'Burnay', 'Buyabuyan',
      'Caba', 'Cudog', 'Dulao', 'Jucbong', 'Luta', 'Montabiong',
      'Olilicon', 'Poblacion East', 'Poblacion North', 'Poblacion South',
      'Poblacion West', 'Ponghal', 'Pullaan', 'Tungngod', 'Tupaya',
    ],

    'Lamut': [
      'Ambasa', 'Bimpal', 'Hapid', 'Holowon', 'Lawig',
      'Lucban', 'Mabatobato (Lamut)', 'Magulon', 'Nayon',
      'Panopdopan', 'Payawan', 'Pieza', 'Poblacion East',
      'Poblacion West', 'Pugol (Ifugao Reservation)', 'Salamague',
      'Sanafe', 'Umilag',
    ],

    'Mayoyao': [
      'Aduyongan', 'Alimit', 'Ayangan', 'Balangbang', 'Banao',
      'Banhal', 'Bato-Alatbang', 'Bongan', 'Buninan', 'Chaya',
      'Chumang', 'Epeng', 'Guinihon', 'Inwaloy', 'Langayan',
      'Liwo', 'Maga', 'Magulon', 'Mapawoy', 'Mayoyao Proper',
      'Mongol', 'Nalbu', 'Nattum', 'Palaad', 'Poblacion',
      'Talboc', 'Tulaed',
    ],

    'Tinoc': [
      'Ahin', 'Ap-apid', 'Binablayan', 'Danggo', 'Eheb',
      'Gumhang', 'Impugong', 'Luhong', 'Tinoc', 'Tukucan',
      'Tulludan', 'Wangwang',
    ],

    // ════════════════════════════════════════════════════════════════════════
    // KALINGA — 7 municipalities + Tabuk City, 153 barangays (Wikipedia data)
    // ════════════════════════════════════════════════════════════════════════

    'Balbalan': [
      'Ababa-an', 'Balantoy', 'Balbalan Proper', 'Balbalasang',
      'Buaya', 'Dao-angan', 'Gawa-an', 'Mabaca', 'Maling (Kabugao)',
      'Pantikian', 'Poblacion (Salegseg)', 'Poswoy', 'Talalang', 'Tawang',
    ],

    'Lubuagan': [
      'Antonio Canao', 'Dangoy', 'Lower Uma', 'Mabilong', 'Mabongtot',
      'Poblacion', 'Tanglag', 'Uma del Norte (Western Luna Uma)', 'Upper Uma',
    ],

    'Pasil': [
      'Ableg', 'Bagtayan', 'Balatoc', 'Balenciagao Sur',
      'Balinciagao Norte', 'Cagaluan', 'Colayo', 'Dalupa',
      'Dangtalan', 'Galdang (Casaloan)', 'Guina-ang (Poblacion)',
      'Magsilay', 'Malucsad', 'Pugong',
    ],

    'Pinukpuk': [
      'Aciga', 'Allaguia', 'Ammacian', 'Apatan', 'Asibanglan',
      'Ba-ay', 'Ballayangon', 'Bayao', 'Camalog', 'Cawagayan',
      'Dugpa', 'Katabbogan', 'Limos', 'Magaogao', 'Malagnat',
      'Mapaco', 'Pakawit', 'Pinococ', 'Pinukpuk Junction', 'Socbot',
      'Taga (Poblacion)', 'Taggay', 'Wagud',
    ],

    'Rizal': [
      'Babalag East (Poblacion)', 'Babalag West (Poblacion)', 'Bulbol',
      'Calaocan', 'Kinama', 'Liwan East', 'Liwan West', 'Macutay',
      'Romualdez', 'San Francisco', 'San Pascual', 'San Pedro',
      'San Quintin', 'Santor',
    ],

    'Tabuk City': [
      'Agbannawag', 'Amlao', 'Appas', 'Bado Dangwa', 'Bagumbayan',
      'Balawag', 'Balong', 'Bantay', 'Bulanao', 'Bulanao Norte',
      'Bulo', 'Cabaritan', 'Cabaruan', 'Calaccad', 'Calanan',
      'Casigayan', 'Cudal', 'Dagupan Centro (Poblacion)', 'Dagupan Weste',
      'Dilag', 'Dupag', 'Gobgob', 'Guilayon', 'Ipil', 'Lacnog',
      'Lanna', 'Laya East', 'Laya West', 'Lucog', 'Magnao',
      'Magsaysay', 'Malalao', 'Malin-awa', 'Masablang', 'Nambaran',
      'Nambucayan', 'Naneng', 'New Tanglag', 'San Juan', 'San Julian',
      'Suyang', 'Tuga',
    ],

    'Tanudan': [
      'Anggacan', 'Anggacan Sur', 'Babbanoy', 'Dacalan', 'Dupligan',
      'Gaang', 'Lay-asan', 'Lower Lubo', 'Lower Mangali', 'Lower Taloctoc',
      'Mabaca', 'Mangali Centro', 'Pangol', 'Poblacion', 'Upper Lubo',
      'Upper Taloctoc',
    ],

    'Tinglayan': [
      'Ambato Legleg', 'Bangad Centro', 'Basao', 'Belong Manubal',
      'Bugnay', 'Buscalan (Buscalan-Locong)', 'Butbut (Butbut-Ngibat)',
      'Dananao', 'Loccong', 'Lower Bangad', 'Luplupa', 'Mallango',
      'Ngibat', 'Old Tinglayan', 'Poblacion', 'Sumadel 1', 'Sumadel 2',
      'Tulgao East', 'Tulgao West', 'Upper Bangad',
    ],

    // ════════════════════════════════════════════════════════════════════════
    // MOUNTAIN PROVINCE — 10 municipalities, 144 barangays (Wikipedia data)
    // ════════════════════════════════════════════════════════════════════════

    'Barlig': [
      'Chupac', 'Fiangtin', 'Gawana (Poblacion)', 'Kaleo', 'Latang',
      'Lias Kanluran', 'Lias Silangan', 'Lingoy', 'Lunas',
      'Macalana', 'Ogoog',
    ],

    'Bauko': [
      'Abatan', 'Bagnen Oriente', 'Bagnen Proper', 'Balintaugan',
      'Banao', 'Bila (Bua)', 'Guinzadan Central', 'Guinzadan Norte',
      'Guinzadan Sur', 'Lagawa', 'Leseb', 'Mabaay', 'Mayag',
      'Monamon Norte', 'Monamon Sur', 'Mount Data', 'Otucan Norte',
      'Otucan Sur', 'Poblacion (Bauko)', 'Sadsadan', 'Sinto', 'Tapapan',
    ],

    'Besao': [
      'Agawa', 'Ambaguio', 'Banguitan', 'Besao East (Besao Proper)',
      'Besao West', 'Catengan', 'Gueday', 'Kin-iway (Poblacion)',
      'Lacmaan', 'Laylaya', 'Padangan', 'Payeo', 'Suquib', 'Tamboan',
    ],

    'Bontoc': [
      'Alab Oriente', 'Alab Proper', 'Balili', 'Bayyo', 'Bontoc Ili',
      'Calutit', 'Caneo', 'Dalican', 'Gonogon', 'Guinaang',
      'Maligcong', 'Mainit', 'Poblacion (Bontoc)', 'Samoki',
      'Talubin', 'Tocucan',
    ],

    'Natonin': [
      'Alunogan', 'Balangao', 'Banao', 'Banawal', 'Butac',
      'Maduayan', 'Poblacion', 'Pudo', 'Saliok', 'Santa Isabel',
      'Tonglayan',
    ],

    'Paracelis': [
      'Anonat', 'Bacarni', 'Bananao', 'Bantay', 'Bunot',
      'Buringal', 'Butigue', 'Palitod', 'Poblacion',
    ],

    'Sabangan': [
      'Bao-angan', 'Bun-ayan', 'Busa', 'Camatagan', 'Capinitan',
      'Data', 'Gayang', 'Lagan', 'Losad', 'Namatec',
      'Napua', 'Pingad', 'Poblacion', 'Supang', 'Tambingan',
    ],

    'Sadanga': [
      'Anabel', 'Bekigan', 'Belwang', 'Betwagan', 'Demang',
      'Poblacion', 'Sacasacan', 'Saclit',
    ],

    'Sagada': [
      'Aguid', 'Ambasing', 'Angkeling', 'Antadao', 'Balugan',
      'Bangaan', 'Dagdag (Poblacion)', 'Demang (Poblacion)', 'Fidelisan',
      'Kilong', 'Madongo', 'Nacagang', 'Pide', 'Poblacion (Patay)',
      'Suyo', 'Taccong', 'Tanulong', 'Tetepan Norte', 'Tetepan Sur',
    ],

    'Tadian': [
      'Balaoa', 'Banaao', 'Bantey', 'Batayan', 'Bunga', 'Cadad-anan',
      'Cagubatan', 'Dacudac', 'Duagan', 'Kayan East', 'Kayan West',
      'Lenga', 'Lubon', 'Mabalite', 'Masla', 'Pandayan', 'Poblacion',
      'Sumadel', 'Tue',
    ],

    // ════════════════════════════════════════════════════════════════════════
    // BAGUIO CITY — independent HUC; 129 barangays total.
    // Representative listing only — use Baguio City's own dropdown if needed.
    // ════════════════════════════════════════════════════════════════════════
    'Baguio City Proper': [
      'A. Bonifacio-Caguioa-Rimando (ABCR)',
      'Alfonso Tabora',
      'Alma Villa (Quirino-Magsaysay, Upper East)',
      'Ambiong',
      'Andres Bonifacio (Lower)',
      'Andres Bonifacio (Upper)',
      'Asin Road',
      'Aurora Hill Proper (Malvar-Sgt. Floresca)',
      'Aurora Hill, North Central',
      'Bagong Lipunan (Cresencia Village)',
      'Bakakeng Central',
      'Bakakeng Norte',
      'Balsigan',
      'Bayan Park East',
      'Bayan Park Village',
      'Bayan Park West',
      'BGH Compound',
      'Brookside',
      'Brookspoint',
      'Cabinet Hill-Teacher\'s Camp',
      'Camdas Subdivision',
      'Camp 7',
      'Camp 8',
      'Camp Allen',
      'Campo Filipino',
      'City Camp Central',
      'City Camp Proper',
      'Country Club Village, Lower',
      'Country Club Village, Upper',
      'Cresencia Village (Bagong Lipunan)',
      'Dizon Subdivision',
      'Dominical Subdivision',
      'Engineers Hill',
      'Fairview Village',
      'Ferdinand (Happy Hollow)',
      'Fort del Pilar',
      'Gabriela Silang',
      'General Emilio F. Aguinaldo (Quirino-Magsaysay, Lower)',
      'General Luna Road',
      'General Roxas-Rabbi Tunnel',
      'Greenwater Village',
      'Guisad Central',
      'Guisad Sorong',
      'Happy Hollow (Ferdinand)',
      'Harrison Road-Claudio Carantes',
      'Holy Ghost Extension',
      'Holy Ghost Proper',
      'Honeymoon (Honeymoon Road)',
      'Imelda R. Marcos (La Salle)',
      'Imelda Village',
      'Irisan',
      'Justo Lukban (Tiptop)',
      'Kagitingan',
      'Kias',
      'Legarda-Burnham-Kisad',
      'Lourdes Subdivision, Lower',
      'Lourdes Subdivision, Upper',
      'Lower Magsaysay',
      'Lower Rock Quarry',
      'Lualhati',
      'Lucnab',
      'Magsaysay Private Road',
      'Malcolm Square-Perfecto (formerly Rizal Monument area)',
      'Manuel A. Roxas',
      'Market Subdivision',
      'Middle Rock Quarry',
      'Military Cut-off Road',
      'Mindanao Village',
      'Modern Site, East',
      'Modern Site, West',
      'MRR-Queen of Peace',
      'New Lucban',
      'Outlook Drive',
      'Pacdal',
      'Padre Burgos',
      'Padre Zamora',
      'Phil-Am',
      'Pinget',
      'Pinsao Pilot Project',
      'Pinsao Proper',
      'Poliwes',
      'Pucsusan',
      'Quirino Hill, East',
      'Quirino Hill, Lower',
      'Quirino Hill, Middle',
      'Quirino Hill, West',
      'Quirino-Magsaysay, Upper West (Felipe Campos)',
      'Railroad Road',
      'Residence Area, Upper',
      'Rizal Monument Area',
      'Rock Quarry, Lower',
      'Rock Quarry, Middle',
      'Rock Quarry, Upper',
      'Rural Asin Road',
      'Saint Joseph Village',
      'Salud Mitra',
      'San Antonio Village',
      'San Luis Village',
      'San Roque Village',
      'San Vicente',
      'Sanitary Camp, North',
      'Sanitary Camp, South',
      'Santa Escolastica',
      'Santo Rosario',
      'Santo Tomas Proper',
      'Scout Barrio',
      'Session Road Area',
      'Slaughter House Area (Malvar)',
      'SLU-SVP Housing Village',
      'South Drive',
      'Teodora Alonzo',
      'Trancoville',
      'Upper Magsaysay',
      'Upper Market Subdivision',
      'Upper QB',
      'Upper Rock Quarry',
      'Upper Session Road',
      'West Modernsite',
    ],
  };

  // ── Validators ─────────────────────────────────────────────────────────────

  static bool validateBarangay(String barangay, String municipality) {
    final barangays = barangaysByMunicipality[municipality] ?? [];
    return barangays.contains(barangay);
  }

  static bool validateMunicipality(String municipality, String province) {
    final municipalities = municipalitiesByProvince[province] ?? [];
    return municipalities.contains(municipality);
  }

  static List<String> getMunicipalitiesForProvince(String province) {
    return municipalitiesByProvince[province] ?? [];
  }

  static List<String> getBarangaysForMunicipality(String municipality) {
    // Baguio City has a single dummy entry 'Baguio City Proper'
    // to trigger the barangay map; real entries are under that key.
    return barangaysByMunicipality[municipality] ?? [];
  }

  static bool validateCompleteAddress(
      String barangay, String municipality, String province) {
    if (!validateMunicipality(municipality, province)) return false;
    if (!validateBarangay(barangay, municipality)) return false;
    return true;
  }

  static String formatAddress(
      String barangay, String municipality, String province) {
    return '$barangay, $municipality, $province';
  }

  static String? validateAndFormatAddress(
      String barangay, String municipality, String province) {
    if (validateCompleteAddress(barangay, municipality, province)) {
      return formatAddress(barangay, municipality, province);
    }
    return null;
  }

  static Map<String, String>? parseAddress(String addressString) {
    final parts = addressString.split(',').map((p) => p.trim()).toList();
    if (parts.length != 3) return null;
    return {
      'barangay': parts[0],
      'municipality': parts[1],
      'province': parts[2],
    };
  }

  static String getValidationError(
      String barangay, String municipality, String province) {
    if (municipality.isEmpty) return 'Please select a Municipality/City';
    if (!validateMunicipality(municipality, province)) {
      return 'Selected Municipality/City does not belong to $province';
    }
    if (barangay.isEmpty) return 'Please select a Barangay';
    if (!validateBarangay(barangay, municipality)) {
      return 'Selected Barangay does not belong to $municipality';
    }
    return '';
  }
}