# 📱 Lumasdang - Nutritional Assessment & Patient Management System

## 🎯 Overview

**Lumasdang** is a mobile application designed to help healthcare workers, nurses, and nutritionists easily track and monitor the nutritional health of patients, especially children. The app is particularly useful in areas where internet connectivity may be unreliable.

### What Problem Does It Solve?

In many healthcare settings, especially in rural or underserved areas, healthcare workers need to:
- ✅ Record patient information and health assessments offline
- ✅ Track nutritional status using WHO (World Health Organization) standards
- ✅ Automatically calculate health metrics based on patient measurements
- ✅ Securely store patient data locally on the phone
- ✅ Sync data to the cloud when internet becomes available

Lumasdang solves all of these problems in one easy-to-use app.

---

## ✨ Main Features

### 1. **User Authentication**
- **Email/Password Login**: Traditional login system with account creation
- **Offline Login**: Can sign in even without internet using cached credentials
- **Secure Password Storage**: Passwords are encrypted and never stored in plain text

### 2. **Patient Management**
- **Add New Patients**: Record patient demographic information (name, age, gender, address, contact details)
- **View Patient List**: See all patients you've recorded with filtering options
- **Patient Profiles**: Detailed view of each patient including:
  - Basic information (age, gender, address)
  - Contact details for parents/guardians
  - Medical history
  - Vaccination schedules
  - Deworming records
  - Dietary information

### 3. **Nutritional Assessment**
- **Body Measurements**: Record weight, height, and MUAC (Mid-Upper Arm Circumference)
- **Automatic Calculations**: The app automatically calculates:
  - Weight-for-Age status
  - Height-for-Age status
  - Weight-for-Height status (for children 0-5 years)
  - BMI (Body Mass Index)
- **WHO Standards**: Uses international WHO growth standards for accurate assessment
- **Trend Tracking**: See how patient's nutrition improves or declines over time with charts

### 4. **Health Monitoring**
- **Vaccination Records**: Track all vaccinations (BCG, Hepatitis B, MMR, etc.)
- **Deworming Records**: Monitor deworming medication and dates
- **Oral Health Assessment**: Record dental/oral health status
- **Dietary Information**: Track breastfeeding status and complementary feeding
- **Health Status Flags**: Note if patient has fever, diarrhea, cough, or other conditions

### 5. **Offline Mode**
- **Work Without Internet**: Complete all functions without internet connection
- **Automatic Syncing**: When internet returns, data automatically uploads to cloud
- **No Data Loss**: Nothing is lost when offline; everything is saved locally first
- **Seamless Experience**: User doesn't need to worry about connectivity

### 6. **Data Syncing**
- **Cloud Backup**: All data is backed up on secure cloud servers (Firebase)
- **Multi-Device Sync**: Access your data from multiple devices
- **Shared Patient Records**: Share patient information with other healthcare workers in your clinic
- **Real-Time Updates**: See changes made by other team members

### 7. **Security Features**
- **Encrypted Storage**: All sensitive data is encrypted on the phone
- **Secure Cloud Connection**: Data travels securely to cloud servers
- **Password Protection**: Strong password requirements for accounts

### 8. **Customization**
- **Font Size Adjustment**: Increase or decrease text size for better readability
- **Theme Options**: Choose different visual styles
- **Language Support**: Available in multiple languages

### 9. **Data Management**
- **Calendar View**: See when assessments were done using calendar interface
- **Import/Export Records**: Download records in Excel format for backup or sharing
- **Archive Old Patients**: Keep old records organized by archiving
- **Search & Filter**: Quickly find specific patients

### 10. **Reporting**
- **Assessment Reports**: Generate detailed reports of patient assessments
- **Trends & Analytics**: Visual charts showing patient progress over time
- **Export to Excel**: Download data in spreadsheet format

### 11. **OPT Plus Reporting** 
- **Government Reporting**: Generate OPT Plus summary reports for government submission
- **Age Band Analysis**: Automatic categorization of children by age groups (0-5, 6-11, 12-23, 24-35, 36-47, 48-59 months)
- **Nutritional Indicators**: Calculate counts for wasted/stunted children, overweight/obesity, and other health indicators
- **Excel Template Integration**: Uses official OPT Plus Excel templates for standardized reporting

### 12. **Lumasdang Records System**
- **Comprehensive Patient Records**: Generate complete patient records in Excel format
- **Barangay-Level Data**: Organize and export data by barangay (local community)
- **Assessment History**: Include all historical assessments for each child
- **Standardized Format**: Uses official Lumasdang records template for consistency

### 13. **Advanced Security Features**
- **Password Change**: Securely update account password with authentication
- **Username Management**: Change username with availability checking
- **Email Updates**: Update email address with verification process
- **Display Name Customization**: Personalize how your name appears in the app
- **Profile Picture Upload**: Add and update profile photos with base64 encoding

### 14. **Enhanced Notification System**
- **Real-time Notifications**: Get instant updates about new patients and assessments
- **Offline Notifications**: View notifications even without internet connection
- **Filtered Views**: Filter notifications by type (patients, assessments, system updates)
- **Calendar Integration**: Link notifications to calendar events and appointments

### 15. **Multi-User Collaboration**
- **Barangay-Based Sharing**: Share patient data within your barangay/clinic
- **User Management**: Multiple healthcare workers can collaborate on patient records
- **Audit Trail**: Track who created and modified patient data
- **Role-Based Access**: Different permission levels for different user types

---

## 🛠️ Tools & Technologies Used

### **Core Development**
| Tool | What It Is | Why It's Used |
|------|-----------|---------------|
| **Flutter** | A framework for building mobile apps | Allows us to create apps that work on both Android and iPhone from one codebase |
| **Dart** | A programming language | Used to write the app code; it's fast and reliable |

### **Authentication & Security**
| Tool | What It Is | Why It's Used |
|------|-----------|---------------|
| **Firebase Authentication** | Cloud-based login system | Securely manages user accounts and passwords |
| **Flutter Secure Storage** | Encrypted data storage | Safely stores sensitive information like passwords on the phone |

### **Cloud & Data Storage**
| Tool | What It Is | Why It's Used |
|------|-----------|---------------|
| **Firebase (Google Cloud)** | Cloud storage and database | Safely backs up all patient data in the cloud |
| **Cloud Firestore** | Cloud database | Stores and retrieves patient information efficiently |
| **Hive** | Local database on phone | Saves data directly on the phone for offline access |

### **Features & Functionality**
| Tool | What It Is | Why It's Used |
|------|-----------|---------------|
| **Growth Standards** | WHO growth measurement library | Calculates accurate nutritional status based on international standards |
| **Connectivity Plus** | Internet detection | Checks if phone is connected to internet |
| **Share Plus** | Data sharing | Allows sharing patient records with other people |
| **Excel** | Spreadsheet format | Exports data to Excel files for backup and reporting |
| **URL Launcher** | Link opener | Opens web links and makes phone calls |
| **Provider** | State management | Keeps app UI updated when data changes |
| **Image Picker** | Camera access | Allows taking photos for patient profiles |
| **Image Compress** | Photo optimization | Reduces image file sizes for efficient storage |
| **Local Auth** | Biometric authentication | Enables fingerprint/face recognition for secure login |
| **Secure Storage** | Encrypted local storage | Safely stores sensitive data like passwords and tokens |
| **HTTP** | Network requests | Handles API calls and external data fetching |
| **UUID** | Unique identifiers | Generates unique IDs for records and documents |
| **Archive** | File compression | Creates ZIP files for data export and backup |
| **XML** | Data parsing | Processes XML data for reporting templates |

### **User Interface**
| Tool | What It Is | Why It's Used |
|------|-----------|---------------|
| **Material Design** | Google design system | Makes the app look modern and professional |
| **Google Fonts** | Custom fonts | Allows beautiful, readable text styles |
| **Color Picker** | Color selection tool | Lets users customize app appearance |

---

## Formulas Used
The app performs several common health calculations related to nutrition and growth:

- **BMI (Body Mass Index):**  
  BMI = weight (kg) ÷ [height (m) × height (m)]
  - A number that shows if someone is underweight, normal, or overweight based on their size.

- **WHO Growth Z-scores:**  
  - These are standard measurements used by health professionals to compare a child’s measurements (weight, height, or weight-for-height) to a reference population.
  - A Z-score of 0 means the child is exactly average; positive or negative values show how many standard deviations the child is above or below average.
  - The app uses the WHO growth standards library to compute these scores automatically.

- **Weight-for-Age, Height-for-Age, Weight-for-Height:**
  - These are specific Z-score categories that indicate whether a child is underweight, stunted, or wasted/overweight.
  - For example, weight-for-height compares a child’s weight to the expected weight for someone of the same height.
  - No manual formula is shown to the user; the app handles the calculation behind the scenes using WHO data.

## 📊 How the App Works (Step-by-Step)

### **Step 1: Opening the App**
1. User opens Lumasdang app
2. App checks if internet is available
3. If user is not logged in, they see the login screen

### **Step 2: Logging In**
**Option A - Using Email & Password:**
1. User enters their email/phone number and password
2. Firebase checks these credentials
3. If correct, user is logged in and sees home screen
4. App saves login session for next time

**Option B - Offline Login:**
1. If internet is down, user can still log in
2. App uses saved credentials from last time
3. Works seamlessly without internet

### **Step 3: Home Screen - Dashboard**
After logging in, user sees:
- **Quick Stats**: Number of patients, assessments done today
- **Recent Patients**: List of recently viewed patient records
- **Quick Actions**: Buttons to add new patient, view assessments
- **Notifications**: Important alerts about upcoming tasks

### **Step 4: Adding a New Patient**
1. User taps "Add New Patient" button
2. Fills in patient details:
   - Name, age, gender
   - Address and contact information
   - Parent/guardian details
3. App saves patient locally on phone (instantly, any internet)
4. When internet comes back, patient syncs to cloud

### **Step 5: Recording Patient Assessment**
1. User selects a patient from list
2. Taps "New Assessment"
3. Enters measurement data:
   - Date of measurement
   - Weight (in kilograms)
   - Height (in centimeters)
   - MUAC - arm circumference (in centimeters)
4. App **automatically calculates**:
   - Weight-for-Age status
   - Height-for-Age status
   - Weight-for-Height (for young children)
   - BMI
5. Data is saved locally on phone
6. When internet returns, data syncs to cloud

### **Step 6: Viewing Patient Health Status**
User can see:
- **Nutritional Status**: Is child normal, malnourished, or overweight?
- **Growth Trends**: Charts showing weight and height progress
- **Health Records**: Vaccination status, deworming, dental health
- **Dietary Info**: Breastfeeding, diet type
- **Assessment History**: All past measurements and dates

### **Step 7: Data Syncing**
**What happens automatically:**
1. When internet connects, app detects it
2. All unsaved data on phone is sent to cloud
3. Cloud data is downloaded to phone
4. User can see updates from teammates
5. No manual action needed!

### **Step 8: Sharing & Exporting**
Users can:
- **Share Patient Records**: Send patient data to other healthcare workers
- **Export to Excel**: Download records as spreadsheet file
- **Print Reports**: Generate printable assessment reports
- **Archive Patients**: Move old records to archive for organization

---

## 🌐 Offline Capability Explained Simply

### **How It Works Without Internet:**

**Saving Data Offline:**
- User records patient info or assessment
- App saves it **locally on the phone** (in Hive database)
- User sees "syncing pending" indicator
- Data is ready to sync when internet returns

**Syncing When Internet Returns:**
- App detects internet is back
- Automatically uploads all pending data to cloud
- Downloads any updates from other team members
- Seamless and automatic!

**Important Points:**
- ✅ **Nothing is lost** - All data stays on phone until uploaded
- ✅ **Works fully offline** - All features available without internet
- ✅ **Automatic syncing** - No manual action needed
- ✅ **Conflict handling** - If two people edit same record, latest version wins

### **Example Scenario:**
1. **Monday, No Internet:** Healthcare worker screens 10 patients. All data saved locally.
2. **Tuesday Morning:** Internet comes back. App automatically syncs all 10 records to cloud.
3. **Tuesday Afternoon:** Another worker in different clinic can now see those records.

---

## 🔐 Security & Privacy

### **How User Passwords Are Protected:**
- Passwords are **encrypted** (scrambled) before being stored
- Never stored in plain text
- Only Firebase (Google's secure servers) can decrypt them
- User has no way to recover old passwords; must reset instead

### **How Patient Data Is Protected:**
- All data on phone is encrypted
- All data sent to cloud uses secure connections (HTTPS)
- Only authorized users can access their data
- Passwords are required to access detailed records

### **Data Privacy:**
- App only collects essential patient health information
- No tracking of user behavior
- Data is only shared with other users at same organization
- Users can request data deletion anytime

---

## 🚀 Installation Guide

### **Step 1: Requirements**
Before installing, make sure you have:
- **Android Phone** (version 5.0 or higher) OR **iPhone** (version 11.0 or higher)
- **Flutter installed** on your computer (for developers)
- **Google account** (for Firebase setup)
- **Git** for downloading the code

### **Step 2: Download the Project**

**For Developers (Using Git):**
```bash
git clone https://github.com/your-username/lumasdang.git
cd lumasdang
```

**For Non-Developers:**
- Download the project as ZIP file
- Extract to a folder

### **Step 3: Install Dependencies**

Open terminal/command prompt in project folder:
```bash
flutter pub get
```

This downloads all necessary libraries the app needs.

### **Step 4: Firebase Setup**

**Create Firebase Project:**
1. Go to https://console.firebase.google.com/
2. Create new project (name it "Lumasdang")
3. Create Android and iOS apps in Firebase
4. Download configuration files:
   - `google-services.json` (for Android)
   - `GoogleService-Info.plist` (for iOS)
5. Save these files in correct folders in the project

**Android Setup:**
- Copy `google-services.json` to: `android/app/`

**iOS Setup:**
- Copy `GoogleService-Info.plist` to: `ios/Runner/`

### **Step 5: Build & Run**

**On Android Phone:**
```bash
flutter run
```

**On iPhone:**
```bash
flutter run -i
```

**For Release (to share with others):**
```bash
flutter build apk  # Android
flutter build ios  # iPhone
```


## 📂 Project Structure Explained

```
lumasdang/
├── lib/                          # Main app code
│   ├── main.dart                 # Entry point of app
│   ├── loading.dart              # Splash/loading screen
│   ├── firebase_options.dart     # Firebase configuration
│   │
│   ├── providers/                # App state management
│   │   └── theme_provider.dart   # Handles theme and font settings
│   │
│   ├── services/                 # Core functionality
│   │   ├── local_db_service.dart        # Local phone database (Hive)
│   │   ├── firestore_service.dart       # Cloud database operations
│   │   ├── connectivity_service.dart    # Internet detection & syncing
│   │   ├── auth_service.dart            # User authentication
│   │   ├── anthropometric_calculator.dart # Nutrition calculations
│   │   ├── image_service.dart           # Photo handling
│   │   └── [other services].dart        # Additional utilities
│   │
│   ├── screens/                  # Different app pages/screens
│   │   ├── authPages/
│   │   │   ├── login.dart        # Login screen
│   │   │   └── register.dart     # Registration screen
│   │   ├── home/
│   │   │   └── home_page.dart    # Home/Dashboard screen
│   │   ├── patient_list.dart     # List of all patients
│   │   ├── patient_profile/      # Individual patient details
│   │   ├── settingsPages/        # Settings screens
│   │   ├── lumasdang_records/    # Data records view
│   │   └── [other screens]/      # Other pages
│   │
│   └── assets/                   # Images, fonts, files
│       ├── logo/                 # App logo and icons
│       ├── fonts/                # Custom fonts
│       └── [Excel templates]/    # Data templates
│
├── android/                      # Android-specific code
│   └── app/
│       ├── src/main/AndroidManifest.xml  # App permissions
│       └── google-services.json  # Firebase config (Android)
│
├── ios/                          # iOS-specific code
│   └── Runner/
│       ├── Info.plist            # App permissions (iOS)
│       └── GoogleService-Info.plist  # Firebase config (iOS)
│
├── pubspec.yaml                  # App configuration and dependencies
├── firebase.json                 # Firebase hosting settings
└── README.md                     # This file!
```

### **What Each Folder Does:**

| Folder | Purpose |
|--------|---------|
| **lib/** | Contains all app code and logic |
| **providers/** | Manages app state (theme, preferences) |
| **services/** | Handles business logic (database, auth, internet) |
| **screens/** | User interface pages (login, home, patient list) |
| **assets/** | Images, logos, and data files |
| **android/** | Android-specific settings and permissions |
| **ios/** | iPhone-specific settings and permissions |

---

## 🎓 Key Concepts Explained

### **What is Firebase?**
Firebase is Google's cloud service that:
- Stores user accounts securely
- Backs up all patient data in cloud
- Lets multiple users access data from different phones
- Provides real-time database (Firestore)

### **What is Hive?**
Hive is a local database on your phone that:
- Stores data directly on the device
- Works without internet
- Is very fast for quick access
- Syncs with cloud when internet is available

### **What is State Management (Provider)?**
State management keeps track of:
- User login status
- Current theme/font settings
- Patient data being viewed
- UI updates when data changes


### **What is WHO Growth Standards?**
WHO (World Health Organization) standards:
- International guidelines for child health
- Determine if child is growing normally
- Based on comparing measurements to millions of healthy children
- Used by doctors worldwide

---

## 📋 Features & Functionality Matrix

| Feature | Works Offline | Needs Internet | Auto-Syncs |
|---------|---------------|----------------|-----------|
| View saved patients | ✅ Yes | ❌ No | N/A |
| Add new patient | ✅ Yes | ❌ No | ✅ Yes |
| Record assessment | ✅ Yes | ❌ No | ✅ Yes |
| Login with password | ❌ No | ✅ Yes | N/A |
| View cloud data | ❌ No | ✅ Yes | ✅ Yes |
| Export to Excel | ✅ Yes | ✅ Yes | N/A |
| Calculate WHO stats | ✅ Yes | ❌ No | N/A |
| Sync data | ❌ No | ✅ Yes | ✅ Yes |

---

## 🐛 Troubleshooting

### **"Permission Denied" Error**
**Solution:**
- Grant permissions for: Camera, Photos, Location (if needed)
- Restart app


### **Data Not Syncing**
**Solution:**
- Check internet connection
- Restart app
- If problem persists, restart phone

### **App Crashes When Opening**
**Solution:**
- Clear app cache: Settings → Clear Cache
- Update app to latest version
- If problem continues, reinstall app

### **Forgot Password**
**Solution:**
- On login screen, tap "Forgot Password?"
- Enter email address
- Check email for password reset link
- Create new password and log in

---

## 👥 For Different Users

### **For Healthcare Workers (Nurses, Nutritionists)**
- Focus on **Nutritional Assessment** and **Health Monitoring** features
- Use **offline mode** in clinics without internet
- Export **reports** for supervisors


### **For Developers**
- Code is well-organized in services/screens structure
- Uses **Provider** for state management (easy to modify)
- **Firebase** for cloud operations
- **Hive** for local storage
- Easy to add new features

### **For Teachers/Documentation**
- App demonstrates real-world mobile development
- Shows cloud + local database sync pattern
- Demonstrates biometric authentication
- Uses international health standards (WHO)
- Good example of offline-first app architecture

---

## 📚 Technologies Stack Summary

```
Frontend: Flutter + Dart
Local Database: Hive
Cloud Database: Firebase Firestore
Authentication: Firebase Auth + Local Auth
State Management: Provider
Health Standards: WHO Growth Standards
Import/Export: Excel, CSV
Cloud Services: Google Firebase
Security: Encrypted Storage
```

---

## 🤝 Contributing

To add features or fix bugs:
1. Create a new branch: `git checkout -b feature/your-feature`
2. Make changes and test
3. Commit: `git commit -m "Add your feature"`
4. Push: `git push origin feature/your-feature`
5. Create Pull Request

---

## 📄 License

This project is for healthcare use and is proprietary. Please contact project owner for usage rights.

---

## 🎉 Acknowledgments

This app was developed using:
- **Flutter Framework** by Google
- **Firebase Services** by Google
- **WHO Growth Standards** - International health guidelines
- **Flutter Community** packages and libraries

Special thanks to healthcare workers who tested and provided feedback!

---

## Developers

- Fuentes, Diane Sophia <dianesophiafuentes10@gmail.com>
- Languido, Paulo <languidopaulo@gmail.com>"

---

**Version**: 1.2.0  
**Last Updated**: March 2026  
**Supported Platforms**: Android 5.0+
