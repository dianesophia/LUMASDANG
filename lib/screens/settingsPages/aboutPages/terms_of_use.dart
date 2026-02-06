  import 'package:flutter/material.dart';

  class TermsOfUse extends StatelessWidget {
    const TermsOfUse({super.key});

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
                  maxHeight: MediaQuery.of(context).size.height * 0.9, 
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
                        const SizedBox(height: 20),
                       RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                            height: 1.5,
                          ),
                          children: [
                            TextSpan(
                              text: "Terms and Conditions\n",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            TextSpan(
                              text: "By accessing or using this application, you agree to comply with and be bound by the following Terms and Conditions. If you do not agree, please discontinue use of the app.\n\n",
                            ),

                            // Section 1
                            TextSpan(
                              text: "1. Purpose of Use\n",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: "This app is intended solely for nutrition monitoring, data collection, reporting, and program support. It is not a substitute for professional medical diagnosis or treatment.\n\n",
                            ),

                            // Section 2
                            TextSpan(
                              text: "2. User Responsibility\n",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text:
                                "\u2022 Providing accurate, truthful, and up-to-date information\n"
                                "\u2022 Using the app only for lawful and ethical purposes\n"
                                "\u2022 Maintaining the confidentiality of their login credentials\n\n",
                            ),

                            // Section 3
                            TextSpan(
                              text: "3. Data Accuracy\n",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: "While the app is designed to improve data quality, users acknowledge that results and reports depend on the accuracy of the data entered.\n\n",
                            ),

                            // Section 4
                            TextSpan(
                              text: "4. Access and Availability\n",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: "The developers reserve the right to update, modify, suspend, or discontinue any part of the app at any time to improve functionality or ensure security.\n\n",
                            ),

                            // Section 5
                            TextSpan(
                              text: "5. Limitation of Liability\n",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: "The developers shall not be held liable for any loss, damage, or misuse arising from incorrect data entry, unauthorized access, or improper use of the app.\n\n",
                            ),
                          ],
                        ),
                      ),


                        const SizedBox(height: 20),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text(
                                  "Agree",
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
