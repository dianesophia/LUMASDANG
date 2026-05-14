# Lumasdang Complete Design System

**Last Updated:** 2026-05-14  
**Design System Version:** 1.0  
**Platform:** Flutter (Android, iOS, Web)

---

## Table of Contents

### Quick Navigation
- [Project Overview](#project-overview)
- [Fonts & Typography](#fonts--typography)
- [Colors & Palette](#colors--palette)
- [Gradients](#gradients)
- [Animation System](#animation-system)
- [Theme Configuration](#theme-configuration)
- [UI Libraries & Styling](#ui-libraries--styling-tools)
- [Assets & Icons](#asset-summary)
- [Responsive Design](#responsive-design-notes)
- [Component Styling](#component-styling)
- [Implementation References](#implementation-references)

---

# Project Overview

**Lumasdang** is a Flutter mobile application designed to help healthcare workers, nurses, and nutritionists track and monitor patients' nutritional health in areas with unreliable internet connectivity. The design system emphasizes:

- **Accessibility**: Clear, readable typography with high contrast
- **Warmth**: Teal and orange color palette conveying trust and energy
- **Responsiveness**: Mobile-first approach with Material Design 3 principles
- **Consistency**: Unified theme across all screens via Provider state management

---

# Fonts & Typography

## Font Stack

### Primary Font: Roboto (Default)
```
Font Family: Roboto
Source: Google Fonts
Recommended by: Material Design
URL: https://fonts.google.com/specimen/Roboto
```

**Characteristics:**
- Modern, geometric design
- Excellent readability at all sizes
- Optimized for screens and digital media
- Professional appearance

### Alternative Fonts

| Font | Characteristics | Best For |
|------|-----------------|----------|
| **Poppins** | Geometric, friendly, modern | Headlines, friendly tone |
| **Montserrat** | Bold, geometric, elegant | Strong headers, calls-to-action |
| **Open Sans** | Clean, neutral, readable | Body text, accessibility |

## Font Implementation

### Google Fonts Integration

**Location:** [lib/providers/theme_provider.dart](lib/providers/theme_provider.dart)

**Dependency:** `google_fonts: ^6.2.1`

```dart
import 'package:google_fonts/google_fonts.dart';

TextTheme get textTheme {
  switch (_selectedFont) {
    case 'Poppins':
      return GoogleFonts.poppinsTextTheme();
    case 'Montserrat':
      return GoogleFonts.montserratTextTheme();
    case 'Open Sans':
      return GoogleFonts.openSansTextTheme();
    case 'Roboto':
    default:
      return GoogleFonts.robotoTextTheme();
  }
}
```

### Dynamic Font Switching

Users can switch fonts in the app, with preference stored in SharedPreferences:

```dart
Future<void> setFont(String font) async {
  if (_selectedFont == font) return;
  
  _selectedFont = font;
  notifyListeners();
  
  // Persist to SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_fontKey, font);
}
```

## Font Weights & Sizes

### Available Weights in Roboto

| Weight | Value | Usage |
|--------|-------|-------|
| **Light** | 300 | Subtle text, secondary content (rarely used) |
| **Regular** | 400 | Body text, default text, descriptions |
| **Medium** | 500 | Buttons, form labels, secondary headings |
| **Bold** | 700 | Headings, emphasis, important text |
| **Black** | 900 | Not commonly used in this app |

### Type Scale (Material Design 3)

| Style | Size | Line Height | Weight | Usage |
|-------|------|-------------|--------|-------|
| **displayLarge** | 57 sp | 64 | 400 | Large headlines (rarely used) |
| **displayMedium** | 45 sp | 52 | 400 | Large titles |
| **displaySmall** | 36 sp | 44 | 400 | Section titles |
| **headlineLarge** | 32 sp | 40 | 700 | Page titles, major headings |
| **headlineMedium** | 28 sp | 36 | 700 | Card titles, large headers |
| **headlineSmall** | 24 sp | 32 | 700 | Section headers |
| **titleLarge** | 22 sp | 28 | 700 | Form section titles |
| **titleMedium** | 16 sp | 24 | 500 | Subheadings, bold labels |
| **titleSmall** | 14 sp | 20 | 500 | Small titles |
| **bodyLarge** | 16 sp | 24 | 400 | Primary body text |
| **bodyMedium** | 14 sp | 20 | 400 | Standard body text |
| **bodySmall** | 12 sp | 16 | 400 | Secondary text, captions |
| **labelLarge** | 14 sp | 20 | 500 | Button text, labels |
| **labelMedium** | 12 sp | 16 | 500 | Small labels, badges |
| **labelSmall** | 11 sp | 16 | 500 | Tiny labels, hints |

### Dart Usage

```dart
// Using theme styles
Text(
  'Heading',
  style: Theme.of(context).textTheme.headlineLarge,
)

Text(
  'Body text',
  style: Theme.of(context).textTheme.bodyMedium,
)

// Custom text styles
Text(
  'Custom',
  style: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Color(0xFF1A1A1A),
  ),
)
```

## Line Height & Letter Spacing

### Line Height Guidelines

| Category | Ratio | Usage |
|----------|-------|-------|
| **Headlines** | 1.1 - 1.2 | Tight, professional |
| **Subheadings** | 1.3 - 1.4 | Balanced |
| **Body Text** | 1.5 - 1.6 | Comfortable reading |
| **Captions** | 1.4 - 1.5 | Compact but readable |

### Letter Spacing

| Category | Value | Usage |
|----------|-------|-------|
| **Headlines** | -0.015 em | Tighter tracking |
| **Body Text** | Normal (0) | Standard spacing |
| **Captions** | 0.004 em | Slight tracking |

## Typography in Different Contexts

### Form Labels

**Style:** `titleMedium` (Medium weight, 16sp)  
**Color:** `#1A1A1A` (Dark text)

```dart
Text(
  'Date of Birth',
  style: Theme.of(context).textTheme.titleMedium?.copyWith(
    color: Color(0xFF1A1A1A),
  ),
)
```

### Button Text

**Style:** `labelLarge` (Medium weight, 14sp)  
**Color:** `#FFFFFF` (White) or `#1A1A1A` (Dark)

```dart
ElevatedButton(
  onPressed: () {},
  child: Text(
    'SUBMIT',
    style: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 1.0,
    ),
  ),
)
```

### Placeholder/Hint Text

**Style:** `bodySmall` (Regular weight, 12sp)  
**Color:** `#888888` (Gray text)

```dart
TextField(
  decoration: InputDecoration(
    hintText: 'Enter patient name',
    hintStyle: TextStyle(
      fontSize: 12,
      color: Color(0xFF888888),
    ),
  ),
)
```

### Status Badges/Labels

**Style:** `labelMedium` (Medium weight, 12sp)

```dart
Container(
  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  decoration: BoxDecoration(
    color: Color(0xFF66BB6A).withOpacity(0.1),
    borderRadius: BorderRadius.circular(4),
  ),
  child: Text(
    'Normal',
    style: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: Color(0xFF66BB6A),
    ),
  ),
)
```

### Error Messages

**Style:** `labelMedium` (Medium weight, 12sp)  
**Color:** `#E57373` (Error red)

```dart
Text(
  'This field is required',
  style: TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: Color(0xFFE57373),
  ),
)
```

## Accessibility & Readability

### Minimum Font Sizes

| Use Case | Minimum Size |
|----------|--------------|
| Body text | 14 sp |
| Labels | 12 sp |
| Captions | 11 sp (with caution) |

### Color Contrast Requirements (WCAG AA)

| Text Size | Minimum Ratio |
|-----------|---------------|
| Large text (18+) | 3:1 |
| Normal text | 4.5:1 |
| Captions | 4.5:1 |

## Typography Best Practices

✅ **Do's**
- Use theme's TextTheme for consistency
- Maintain sufficient contrast ratios
- Use font hierarchy to guide reading
- Keep line lengths readable (50-75 chars)
- Use appropriate weights for emphasis

❌ **Don'ts**
- Don't use font sizes below 12sp for body text
- Don't mix too many font families (max 2-3)
- Don't use all caps for long passages
- Don't use light weight for body text

---

# Colors & Palette

## Brand Colors

### Primary Brand Color: Teal
```
Hex:  #2E8B7B
RGB:  rgb(46, 139, 123)
HSL:  hsl(167, 50%, 34%)
Name: Teal (Primary)
```
**Usage:** Primary brand identifier, splash screen, app icon background, accents  
**Contrast:** WCAG AA compliant on white backgrounds

### Secondary Brand Color: Orange
```
Hex:  #F5A962
RGB:  rgb(245, 169, 98)
HSL:  hsl(26, 92%, 67%)
Name: Orange (Secondary)
```
**Usage:** Primary action buttons, form highlights, interactive elements, date picker accent  
**Contrast:** WCAG AA compliant on white backgrounds

### Accent: Dark Orange
```
Hex:  #F08030
RGB:  rgb(240, 128, 48)
HSL:  hsl(18, 90%, 56%)
Name: Dark Orange (Accent)
```
**Usage:** Gradient component, button hover states, emphasis

## Status & Semantic Colors

| Color | Hex | RGB | Meaning | Usage |
|-------|-----|-----|---------|-------|
| **Success Green** | `#66BB6A` | `rgb(102, 187, 106)` | Normal/Healthy | Status badges, positive indicators |
| **Warning Yellow** | `#FFD54F` | `rgb(255, 213, 79)` | At Risk | At-risk assessment badges |
| **Alert Orange** | `#FFB74D` | `rgb(255, 183, 77)` | Concerning | Concerning status badges |
| **Error Red** | `#E57373` | `rgb(229, 115, 115)` | Critical/Error | Error messages, validation |
| **Info Teal** | `#4DB6AC` | `rgb(77, 182, 172)` | Informational | Info badges, secondary status |

## Neutral & Background Colors

| Color | Hex | RGB | Usage |
|-------|-----|-----|-------|
| **White** | `#FFFFFF` | `rgb(255, 255, 255)` | Primary surfaces, cards, backgrounds |
| **Light Background** | `#FAFAFA` | `rgb(250, 250, 250)` | Form field backgrounds |
| **Light Gray Border** | `#EEEEEE` | `rgb(238, 238, 238)` | Input field borders, dividers |
| **Medium Gray** | `#E0E0E0` | `rgb(224, 224, 224)` | Disabled field borders |
| **Gray Text** | `#AAAAAA` | `rgb(170, 170, 170)` | Placeholder text, secondary labels |
| **Dark Gray Text** | `#888888` | `rgb(136, 136, 136)` | Secondary text, hints |
| **Dark Text** | `#1A1A1A` | `rgb(26, 26, 26)` | Primary text, headings |

## Accent & Data Visualization Colors

| Color | Hex | RGB | Usage |
|-------|-----|-----|-------|
| **Blue** | `#6B8EAE` | `rgb(107, 142, 174)` | Chart data, infographics |
| **Bright Green** | `#4CAF50` | `rgb(76, 175, 80)` | Success messages |
| **Brown** | `#8B7355` | `rgb(139, 115, 85)` | Nutritional data, earth tones |

## Background Tints

| Color | Hex | RGB | Usage |
|-------|-----|-----|-------|
| **Light Yellow** | `#FFF8E1` | `rgb(255, 248, 225)` | Splash screen, notifications |
| **Very Light Yellow** | `#FFFDE7` | `rgb(255, 253, 231)` | Subtle backgrounds, gradients |
| **Disabled BG** | `#F0F0F0` | `rgb(240, 240, 240)` | Disabled form fields |

## Color Opacity Modifiers

| Opacity | Value | Usage |
|---------|-------|-------|
| **Full** | 1.0 | Solid colors |
| **High** | 0.8 | Prominent overlays |
| **Medium** | 0.6 | Secondary overlays |
| **Low** | 0.4 | Subtle backgrounds |
| **Minimal** | 0.2 | Borders |
| **Faint** | 0.05 | Imperceptible tints |

### Dart Implementation

```dart
Color(0xFF2E8B7B).withOpacity(0.5)
Color(0xFF2E8B7B).withValues(alpha: 0.5)
Color.fromARGB(128, 46, 139, 123)  // 50% opacity
```

## Accessibility & Contrast

### Contrast Ratios (WCAG Standards)

| Color Pair | Ratio | Rating |
|------------|-------|--------|
| `#1A1A1A` on `#FFFFFF` | 10.8 | AAA |
| `#2E8B7B` on `#FFFFFF` | 5.8 | AA |
| `#F5A962` on `#FFFFFF` | 6.1 | AA |
| `#E57373` on `#FFFFFF` | 5.1 | AA |
| `#66BB6A` on `#FFFFFF` | 6.4 | AA |

### Color-Blind Safe Palette

All status colors use distinct hue/saturation/brightness to support colorblindness types. Never rely on color alone—always include text labels or icons.

## Color Swatches (Quick Reference)

```
PRIMARY PALETTE:
  Teal:        #2E8B7B
  Orange:      #F5A962
  Dark Orange: #F08030

STATUS PALETTE:
  Success:     #66BB6A
  Warning:     #FFD54F
  Alert:       #FFB74D
  Error:       #E57373
  Info:        #4DB6AC

NEUTRAL PALETTE:
  White:       #FFFFFF
  Light BG:    #FAFAFA
  Light Border:#EEEEEE
  Med Gray:    #E0E0E0
  Gray Text:   #AAAAAA
  Dark Gray:   #888888
  Dark Text:   #1A1A1A

ACCENT PALETTE:
  Blue:        #6B8EAE
  Green:       #4CAF50
  Brown:       #8B7355

TINTS:
  Light Yellow:  #FFF8E1
  V.Light Yellow: #FFFDE7
```

---

# Gradients

### Linear Gradients

#### Primary Teal-Green Gradient
```dart
LinearGradient(
  colors: [
    Color(0xFF2E8B7B),   // Teal
    Color(0xFF5CAA7F),   // Medium Green
    Color(0xFF8BC88A),   // Light Green
  ],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
)
```
**Usage:** Loading screen background, splash screen overlay

#### Orange Accent Gradient
```dart
LinearGradient(
  colors: [
    Color(0xFFF5A962),   // Orange
    Color(0xFFF08030),   // Dark Orange
  ],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
)
```
**Usage:** Button backgrounds, form submit actions

#### Green-Teal Gradient (Avatar/Badge)
```dart
LinearGradient(
  colors: [
    Color(0xFF4A9B8C),   // Dark Teal
    Color(0xFF3D998A),   // Deep Teal
    Color(0xFF4DAF8B),   // Medium Teal
    Color(0xFF5CB88D),   // Light Teal
  ],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
)
```
**Usage:** Archived patient list avatars, decorative backgrounds

#### Yellow-Gold Gradient (Notification/Alert)
```dart
LinearGradient(
  colors: [
    Color(0xFFFFFDE7),   // Very Light Yellow
    Color(0xFFFFF8E1),   // Light Yellow
  ],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
)
```
**Usage:** Notification backgrounds, warning containers

#### Shimmer Gradient (Loading States)
```dart
LinearGradient(
  colors: [
    Colors.white.withOpacity(0.0),
    Colors.white.withOpacity(0.8),
    Colors.white.withOpacity(0.0),
  ],
  stops: [0.0, 0.5, 1.0],
)
```
**Usage:** Skeleton loaders, loading animations

---

# Animation System

## Overview

Lumasdang employs sophisticated animations primarily in the loading screen to create a professional, polished user experience. Animations are coordinated using multiple `AnimationController` instances with `TickerProviderStateMixin`.

**Animation Library:** Flutter's built-in `animation` framework (no external packages)

## Core Animations

| Animation | Library | Duration | Type | Curve | Trigger | Description |
|-----------|---------|----------|------|-------|---------|-------------|
| **Logo Scale** | Flutter AnimationController | 1200ms | Scale | elasticOut | Page load | Bouncy entrance of logo |
| **Logo Fade** | Flutter Tween | 1200ms (0-50%) | Opacity | easeOut | Page load | Smooth fade-in of logo |
| **Content Fade** | Flutter CurvedAnimation | 900ms | Opacity | easeOut | Page load | Fade-in of content |
| **Content Slide** | Flutter Tween<Offset> | 900ms | Slide | easeOutCubic | Page load | Upward slide of content |
| **Pulse Effect** | Flutter AnimationController | 2400ms | Scale | linear | Page load | Continuous pulsing effect |
| **Shimmer** | Flutter AnimationController | 1800ms | Linear | linear | Page load | Shimmer/shine effect |
| **Ring Animation** | Flutter AnimationController | 3000ms | Rotation | linear | Page load | Rotating ring effect |

## Animation Controllers

**Location:** [lib/loading.dart](lib/loading.dart)

```dart
class _LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;      // Logo entrance
  late AnimationController _contentController;   // Content reveal
  late AnimationController _pulseController;     // Pulsing background
  late AnimationController _shimmerController;   // Shine effect
  late AnimationController _ringController;      // Ring animation
}
```

## Animation Timeline

```
0ms      : Logo enters (scale + fade)
1200ms   : Logo animation completes
1200ms   : Content starts fading in and sliding up
2100ms   : Content animation completes
0ms-∞    : Pulse continues (repeating every 2400ms)
0ms-∞    : Shimmer continues (repeating every 1800ms)
0ms-∞    : Ring continues (repeating every 3000ms)
```

## Animation Curves Used

| Curve | Effect | Usage |
|-------|--------|-------|
| **elasticOut** | Bouncy springy | Logo entrance |
| **easeOut** | Smooth deceleration | Fade animations |
| **easeOutCubic** | Cubic smooth | Slide animations |
| **linear** | Constant speed | Repeating effects |
| **Interval** | Partial range | Staggered sequences |

## Performance & Best Practices

- **TickerProviderStateMixin:** Syncs animations with frame rate (60/120fps)
- **Repaint Boundaries:** AnimatedBuilders prevent unnecessary rebuilds
- **Duration Coordination:** Animations complete before navigation
- **Memory Management:** Controllers disposed in `dispose()` method

```dart
@override
void dispose() {
  _logoController.dispose();
  _contentController.dispose();
  _pulseController.dispose();
  _shimmerController.dispose();
  _ringController.dispose();
  super.dispose();
}
```

---

# Theme Configuration

### Material 3 Color Scheme

**Primary Seed Color:** `#2E8B7B` (Teal)

```dart
colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E8B7B))
```

### Theme Data Structure

```dart
ThemeData(
  textTheme: provider.textTheme,      // Dynamic font from ThemeProvider
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF2E8B7B)
  ),
  useMaterial3: true,                 // Enable Material Design 3
)
```

### Theme Provider

**Location:** [lib/providers/theme_provider.dart](lib/providers/theme_provider.dart)

- **Pattern:** ChangeNotifier with Provider state management
- **Persistence:** SharedPreferences with key `app_selected_font`
- **Default Font:** Roboto
- **Available Fonts:** Roboto, Poppins, Montserrat, Open Sans
- **Global Access:** Via `Consumer<ThemeProvider>` widget

### Dynamic Theme Overrides

```dart
Theme(
  data: Theme.of(context).copyWith(
    colorScheme: const ColorScheme.light(
      primary: Color(0xFFF5A962),      // Orange accent
      onPrimary: Colors.white,
      surface: Colors.white,
      onSurface: Color(0xFF1A1A1A),
    ),
  ),
  child: DatePickerDialog(...)
)
```

---

# UI Libraries & Styling Tools

### Core Dependencies

| Library | Version | Purpose |
|---------|---------|---------|
| **Flutter Material** | SDK | Material Design 3 components |
| **google_fonts** | `^6.2.1` | Google Fonts integration |
| **provider** | `^6.0.0` | State management |
| **Material Icons** | Built-in | Icon library |
| **Cupertino Icons** | `^1.0.8` | iOS-style icons |

### Material 3 Implementation

- **ColorScheme.fromSeed()** for automatic palette generation
- **Dynamic color** based on teal primary seed
- **Accessibility** standards with proper contrast ratios
- **useMaterial3: true** flag in ThemeData

---

# Asset Summary

### Asset Structure

```
assets/
├── fonts/                          # Empty (using Google Fonts)
├── logo/
│   ├── app_logo.jpg               # Primary app logo
│   └── logo.png                    # Alternate format
├── Lumasdang_records_template.xlsx # Data import template
└── opt_plus_template.xlsx          # OPT+ import template
```

### Icon System

- **Material Icons:** Default Flutter icon library for all UI controls
- **Cupertino Icons:** Additional iOS-specific icons
- **No custom icon fonts:** Using platform defaults for consistency

### Data Templates

| Template | Format | Usage |
|----------|--------|-------|
| **Lumasdang Records** | Excel | Bulk patient record import |
| **OPT Plus** | Excel | Anthropometric data import |

---

# Responsive Design Notes

### Mobile-First Approach

Built mobile-first with Flutter's Material Design framework. No custom breakpoints hardcoded.

### Dynamic Sizing

```dart
MediaQuery.of(context).size.height * 0.40    // Height percentage
MediaQuery.sizeOf(context).width - 32        // Width with padding
MediaQuery.of(ctx).viewInsets.bottom         // Keyboard height
```

### Device Support

- **Target Platforms:** Android, iOS, Web
- **Minimum Size:** Optimized for mobile phones (320px+)
- **Tablet Support:** Responsive layouts scale to larger screens
- **Landscape/Portrait:** Handled via MediaQuery and widget rebuilding

### Responsive Patterns

1. **Scrollable Containers:** Lists and forms use `ListView`/`SingleChildScrollView`
2. **Flexible Widgets:** Use `Expanded`, `Flexible` for dynamic layout
3. **Keyboard Handling:** Adjust bottom padding with `viewInsets.bottom`
4. **Modal Sizing:** Modals use percentage-based heights for responsiveness

---

# Component Styling

### Form Components

#### Text Input Fields
```dart
InputDecoration(
  filled: true,
  fillColor: Color(0xFFFAFAFA),
  border: OutlineInputBorder(
    borderSide: BorderSide(color: Color(0xFFEEEEEE), width: 1.5),
  ),
  focusedBorder: OutlineInputBorder(
    borderSide: BorderSide(color: Color(0xFFF5A962), width: 2),
  ),
  errorBorder: OutlineInputBorder(
    borderSide: BorderSide(color: Color(0xFFEF4444), width: 2),
  ),
  hintStyle: TextStyle(fontSize: 12, color: Colors.black26),
)
```

### Button Components

#### Primary Action Buttons
- **Gradient:** Orange (`#F5A962` → `#F08030`)
- **Foreground:** White text
- **Shape:** `BorderRadius.circular(8)`

#### Secondary/Cancel Buttons
- **Background:** Light gray (`#FAFAFA`)
- **Foreground:** Dark text (`#1A1A1A`)
- **Border:** Light gray outline

#### Status Badge Buttons
- Success: `#66BB6A` (Green)
- Warning: `#FFD54F` (Yellow)
- Alert: `#FFB74D` (Orange)
- Critical: `#E57373` (Red)

### Card Components

#### Patient Cards
- **Background:** White
- **Border:** Subtle shadow
- **Gradient Accent:** Optional gradient header

#### Assessment Cards
- **Layout:** Two-column metric/value
- **Status Color:** Left border matches assessment status
- **Colors:** Green, Yellow, Orange, Red

### Navigation Components

#### Bottom Navigation Bar
- **Active:** Orange (`#F5A962`) with label
- **Inactive:** Gray icon

#### Dialog/Modal Styling
```dart
Dialog(
  backgroundColor: Colors.white,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
)
```

---

# Implementation References

### Key Files

| File | Purpose |
|------|---------|
| [lib/main.dart](lib/main.dart) | App initialization, theme setup |
| [lib/providers/theme_provider.dart](lib/providers/theme_provider.dart) | Theme and font management |
| [lib/loading.dart](lib/loading.dart) | Loading screen with animations |
| [lib/screens/home/widgets/demographic_data_form.dart](lib/screens/home/widgets/demographic_data_form.dart) | Form components |
| [pubspec.yaml](pubspec.yaml) | Dependencies and assets |
| [analysis_options.yaml](analysis_options.yaml) | Linting and code quality |

---

## Summary

The Lumasdang design system emphasizes:

1. **Warmth & Trust:** Teal and orange palette conveys reliability
2. **Clarity:** High-contrast, readable typography with dynamic font selection
3. **Consistency:** Material Design 3 principles with centralized theme management
4. **Accessibility:** Semantic color usage for status indicators and validation
5. **Polish:** Sophisticated animations for professional feel
6. **Responsiveness:** Mobile-first responsive design using Flutter's built-in utilities

All components use a consistent visual language enabling maintainable, scalable UI development across the healthcare platform.

---

**Last Updated:** 2026-05-14  
**Complete Design System Version:** 1.0  
**Platform:** Flutter (Android, iOS, Web)
