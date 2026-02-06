  import 'package:flutter/material.dart';

  class CodeOfConduct extends StatelessWidget {
    const CodeOfConduct({super.key});

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
                        const Text(
                        "Code of Conduct",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
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
                                  text: "All users of this application are expected to adhere to the following standards of conduct:\n\n",
                                ),
                                TextSpan(
                                  text:
                                    "\u2022 Use the app respectfully, ethically, and professionally\n"
                                    "\u2022 Protect the dignity, rights, and privacy of all individuals whose data is collected\n"
                                    "\u2022 Avoid falsification, manipulation, or unauthorized sharing of data\n"
                                    "\u2022 Refrain from using the app for personal, political, or commercial gain\n"
                                    "\u2022 Comply with applicable laws, regulations, and institutional guidelines\n\n",
                                ),
                                TextSpan(
                                  text: "Violation of this Code of Conduct may result in restricted access or removal from the platform.\n\n",
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
