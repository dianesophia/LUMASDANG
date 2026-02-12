# Patient Profile Module

This folder contains the patient profile overview screen and its related widgets.

## File Structure

```
patient_profile/
├── patient_profile_overview.dart   # Main screen
├── widgets/
│   ├── profile_info_card.dart      # Patient info card with avatar
│   ├── assessment_table.dart       # Assessment history table
│   ├── trends_section.dart         # Z-score interpretation trends charts
│   └── trend_line_painter.dart     # Custom painter for trend lines
└── README.md                        # This file
```

## Components

### patient_profile_overview.dart
Main screen that displays the patient's profile with:
- Patient information card
- Assessment history table
- Z-score interpretation trends

### widgets/profile_info_card.dart
Displays patient's basic information:
- Avatar
- Name
- Address
- Birthdate
- Age and Sex

### widgets/assessment_table.dart
Shows a table of all patient assessments with:
- Date, Height, Weight, MUAC
- Classification (Normal, At Risk, Overweight, etc.)
- Add New Assessment button

### widgets/trends_section.dart
Visualizes patient growth trends with:
- Height trend chart
- Weight trend chart
- MUAC trend chart

### widgets/trend_line_painter.dart
Custom painter for drawing trend line charts with:
- Line graphs
- Gradient fills
- Data point markers

## Design System

- **Primary Color**: #2E8B7B (Teal)
- **Accent Color**: #F5A962 (Orange)
- **Success Color**: #4CAF50 (Green)
- **Warning Color**: #FF9800 (Orange)
- **Error Color**: #E53935 (Red)
