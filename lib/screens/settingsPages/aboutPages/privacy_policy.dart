  import 'package:flutter/material.dart';

  class PrivacyPolicy extends StatelessWidget {
    const PrivacyPolicy({super.key});

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
                              text: "Privacy Policy\n\n",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            TextSpan(
                              text: "The application is committed to protecting user privacy and ensuring the confidentiality of all collected data.\n\n",
                            ),

                            // Section 1
                            TextSpan(
                              text: "1. Information Collected\n\n",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: "The app may collect personal, demographic, and nutritional data necessary for monitoring and reporting purposes.\n\n",
                            ),

                            // Section 2
                            TextSpan(
                              text: "2. Use of Information\n\n",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text:
                                "\u2022 Monitor nutritional status\n"
                                "\u2022 Support program planning and evaluation\n"
                                "\u2022 Generate reports for authorized stakeholders\n\n",
                            ),

                            // Section 3
                            TextSpan(
                              text: "3. Data Protection\n\n",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: "Appropriate technical and organizational measures are implemented to safeguard data against unauthorized access, loss, or misuse.\n\n",
                            ),

                            // Section 4
                            TextSpan(
                              text: "4. Data Sharing\n\n",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: "Information will only be shared with authorized personnel or institutions and strictly for health, research, or program-related purposes, in accordance with applicable laws and ethical standards.\n\n",
                            ),

                            // Section 5
                            TextSpan(
                              text: "5. User Consent\n\n",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: "By using this app, users consent to the collection and use of information as described in this Privacy Policy.\n\n",
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
