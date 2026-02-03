import 'package:flutter/material.dart';
import 'package:move_safe/home/home_widget.dart';

class SelfDefenceResourcesPage extends StatelessWidget {
  const SelfDefenceResourcesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF874CF4),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // back button
              GestureDetector(
                onTap: () => Navigator.pushReplacementNamed(context, '/home'),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 3),
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.black,
                    size: 24,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // title
              const Center(
                child: Text(
                  'SELF-DEFENCE\nRESOURCES',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 0.9,
                    letterSpacing: 2,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // self defence content container
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20), 
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black, width: 3),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8), 
                    child: ScrollbarTheme(
                      data: ScrollbarThemeData(
                        thumbVisibility: MaterialStateProperty.all(true),
                        trackVisibility: MaterialStateProperty.all(true),
                        thickness: MaterialStateProperty.all(5),
                        thumbColor: MaterialStateProperty.all(Colors.black),
                        radius: const Radius.circular(3),
                      ),
                      child: Scrollbar(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              buildSelfDefenceResourceCard(
                                title: 'Stay Aware',
                                content:
                                    'Always be aware of your\nsurroundings and avoid\ndistractions like your phone or\nheadphones when walking alone.',
                              ),
                              const SizedBox(height: 20),
                              buildSelfDefenceResourceCard(
                                title: 'Use Your Voice as a Weapon',
                                content:
                                    'If you feel threatened, use loud,\nconfident shouting to attract\nattention.',
                              ),
                              const SizedBox(height: 20),
                              buildSelfDefenceResourceCard(
                                title: 'Trust Your Instincts',
                                content:
                                    'If something feels off,\ndon\'t ignore it. Leave the area,\nseek help, or call someone you trust.\nYour intuition is a powerful tool.',
                              ),
                              const SizedBox(height: 20),
                              buildSelfDefenceResourceCard(
                                title: 'Target Vulnerable Areas',
                                content:
                                    'If physically attacked, aim for\nsensitive spots like eyes, throat, or\ngroin. This can create an\nopportunity to run & seek help.',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSelfDefenceResourceCard({
    required String title,
    required String content,
  }) {
    return Container(
      width: 370,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

