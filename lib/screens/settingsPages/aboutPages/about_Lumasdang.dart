import 'package:flutter/material.dart';

class AboutLumasdang extends StatelessWidget {
  const AboutLumasdang({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Full screen gradient background
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2E8B7B),
              Color(0xFF5CAA7F),
              Color(0xFF8BC88A),
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9, // 60% of screen height
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white, // white modal card
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "About Lumasdang",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "This application is designed to support the monitoring and management of malnutrition by providing a more efficient, accurate, and accessible digital platform for nutritional risk assessment.\n\n"
                        "In response to the persistent challenges of malnutrition including stunting, wasting, micronutrient deficiencies, and the rising prevalence of overweight and obesity, this app aims to improve how nutrition data is collected, managed, and utilized. By replacing manual, paper-based processes with a streamlined digital system, the app helps reduce errors, save time, and enhance timely decision-making for intervention.\n\n"
                        "The app supports health workers, program implementers, and relevant stakeholders in tracking nutritional status, identifying at-risk individuals, and generating reports that can guide evidence-based actions. Ultimately, this application contributes to strengthening nutrition monitoring efforts and supporting healthier communities.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                "Dismiss",
                                style: TextStyle(
                                  color: Colors.pink,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),

                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
