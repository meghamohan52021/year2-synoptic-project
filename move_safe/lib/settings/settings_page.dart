import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:local_auth/local_auth.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String selectedDisability = '';
  TextEditingController disabilityController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController dobController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController(text: '**********');

  // Track original values to detect edits
  String originalName = '';
  String originalDob = '';
  String originalEmail = '';
  String originalPassword = '';
  String originalDisability = '';
  String originalDisabilityDetails = '';

  bool isLoading = true;
  bool isNameEditable = false;
  bool isDOBEditable = false;
  bool isEmailEditable = false;
  bool isPasswordEditable = false;

  @override
  void initState() {
    super.initState();
    fetchUserDataByEmail();
  }

  Future<void> fetchUserDataByEmail() async {
    final currentUserEmail = FirebaseAuth.instance.currentUser?.email;
    if (currentUserEmail == null) return;

    final ref = FirebaseDatabase.instance.ref('users');
    final snapshot = await ref.get();

    if (snapshot.exists) {
      for (final user in snapshot.children) {
        if (user.value is! Map) continue; 
        final data = Map<String, dynamic>.from(user.value as Map);
        if (data['email'] == currentUserEmail) {
          setState(() {
            nameController.text = data['name'] ?? '';
            dobController.text = data['dob'] ?? '';
            emailController.text = data['email'] ?? '';
            selectedDisability = data['hasDisability'] ?? '';
            disabilityController.text = data['disabilityDetails'] ?? '';
            isLoading = false;
            originalName = nameController.text;
            originalDob = dobController.text;
            originalEmail = emailController.text;
            originalPassword = passwordController.text;
            originalDisability = selectedDisability;
            originalDisabilityDetails = disabilityController.text;
          });
          break;
        }
      }
    }
  }
  

// Future<void> saveDisabilityData() async {
//   final ref = FirebaseDatabase.instance.ref('users');
//   final snapshot = await ref.get();

//   if (snapshot.exists) {
//     for (final user in snapshot.children) {
//       final data = Map<String, dynamic>.from(user.value as Map);

//       if (data['email'] == FirebaseAuth.instance.currentUser?.email) {
//         // prepare data
//         final updateData = {
//           'hasDisability': selectedDisability,
//           'disabilityDetails': selectedDisability == 'Yes'
//               ? disabilityController.text.trim()
//               : '', // clear it if "No"
//         };

//         await ref.child(user.key!).update(updateData);

//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Disability info saved to database!')),
//         );
//         break;
//       }
//     }
//   }
// }

// 
final LocalAuthentication auth = LocalAuthentication();
Future<void> enableBiometrics(String type) async {
  final canCheck = await auth.canCheckBiometrics;

  if (!canCheck) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$type not available')),
    );
    return;
  }

  final didAuthenticate = await auth.authenticate(
    localizedReason: 'Authenticate to enable $type login',
    options: const AuthenticationOptions(biometricOnly: true),
  );

  if (didAuthenticate) {
    final ref = FirebaseDatabase.instance.ref('users');
    final snapshot = await ref.get();
    final currentUserEmail = FirebaseAuth.instance.currentUser?.email;

    if (snapshot.exists) {
      for (final user in snapshot.children) {
        if (user.value is! Map) continue;
        final data = Map<String, dynamic>.from(user.value as Map);
        if (data['email'] == currentUserEmail) {
          await ref.child(user.key!).update({'useBiometrics': true});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$type enabled successfully')),
          );
          return;
        }
      }
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$type authentication failed')),
    );
  }
}



Future<void> saveDisabilityData() async {
  final ref = FirebaseDatabase.instance.ref('users');
  final snapshot = await ref.get();
  final currentUserEmail = FirebaseAuth.instance.currentUser?.email;
  print('Logged in Email: $currentUserEmail');

  if (snapshot.exists) {
    for (final user in snapshot.children) {
      if (user.value is! Map) continue;
      final data = Map<String, dynamic>.from(user.value as Map);

      if (data['email'] == currentUserEmail) {
        final updateData = <String, dynamic>{};

        if (nameController.text.trim() != originalName) {
          updateData['name'] = nameController.text.trim();
        }
        if (dobController.text.trim() != originalDob) {
          updateData['dob'] = dobController.text.trim();
        }
        if (emailController.text.trim() != originalEmail) {
          updateData['email'] = emailController.text.trim();
        }
        if (passwordController.text.trim() != originalPassword) {
          updateData['password'] = passwordController.text.trim();
        }
        if (selectedDisability != originalDisability) {
          updateData['hasDisability'] = selectedDisability;
        }

        if (selectedDisability == 'Yes' &&
            disabilityController.text.trim() != originalDisabilityDetails) {
          updateData['disabilityDetails'] = disabilityController.text.trim();
        }

        if (selectedDisability == 'No') {
          await ref.child(user.key!).child('disabilityDetails').remove();
        }


        if (updateData.isNotEmpty) {
          await ref.child(user.key!).update(updateData);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Changes saved successfully!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No changes to save.')),
          );
        }

        return;
      }
    }
  }
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF9C4DFF),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 10, top: 10),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ),
                  const Text(
                    'SETTINGS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 30),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListView(
                        children: [
                          _buildEditableField(
                            controller: nameController,
                            isEditable: isNameEditable,                           
                            label: 'Name',
                            onEdit: () {
                              setState(() => isNameEditable = !isNameEditable);
                            },
                          ),
                          _buildEditableField(
                            controller: dobController,
                            isEditable: isDOBEditable,
                            label: 'DOB',
                            onEdit: () {
                              setState(() => isDOBEditable = !isDOBEditable);
                            },
                          ),
                          _buildEditableField(
                            controller: emailController,
                            isEditable: isEmailEditable,
                            label: 'Email',
                            onEdit: () {
                              setState(() => isEmailEditable = !isEmailEditable);
                            },
                          ),
                          _buildEditableField(
                            controller: passwordController,
                            isEditable: isPasswordEditable,
                            label: 'Password',
                            obscure: _obscurePassword,
                            onEdit: () {
                              setState(() => isPasswordEditable = !isPasswordEditable);},
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Column(
                                children: [
                                  const Icon(Icons.face, size: 60,color: Colors.black),
                                  const SizedBox(height: 5),
                                  _buildAddButton("Face ID"),
                                ],
                              ),
                              Column(
                                children: [
                                  const Icon(Icons.fingerprint, size: 60, color: Colors.black),
                                  const SizedBox(height: 5),
                                  _buildAddButton("Fingerprint"),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 25),
                          const Text(
                            'Do you have a disability?',
                            style: TextStyle(color: Colors.black),
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            value: selectedDisability.isEmpty ? null : selectedDisability,
                            style: TextStyle(color: const Color.fromARGB(255, 87, 86, 86)),
                            dropdownColor: Color(0xFFE6E6FA), 
                            items: const [
                              DropdownMenuItem(value: 'Yes', child: Text('Yes')),
                              DropdownMenuItem(value: 'No', child: Text('No')),                             
                            ],
                            onChanged: (value) {
                              setState(() {
                                selectedDisability = value!;
                              });
                            },
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(horizontal: 12),
                              border: OutlineInputBorder(),
                              hintText: '- Select -',
                            ),
                          ),
                          const SizedBox(height: 15),
                          if (selectedDisability == 'Yes') ...[
                            const Text(
                              'If yes, what disability?',
                              style: TextStyle(color: Colors.black),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: disabilityController,
                              style: const TextStyle(color: Colors.black),
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: 'Type your condition...',
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: saveDisabilityData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),),
                            child: const Text(
                              'Save',
                              style: TextStyle(color: Colors.white, fontSize: 16),),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
  bool _obscurePassword = true;
  Widget _buildEditableField({
    required TextEditingController controller,
    required bool isEditable,
    required String label,
    required VoidCallback onEdit,
    bool obscure = false,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: controller,
              obscureText: obscure && !isEditable,
              readOnly: !isEditable,
              style: TextStyle(color: const Color.fromARGB(255, 87, 86, 86)),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[200],
                labelText: label,
                border: const OutlineInputBorder(),
                suffixIcon: suffixIcon,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onEdit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            child: const Text('edit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(String type) {
    return ElevatedButton(
      onPressed: () => enableBiometrics(type),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
      ),
      child: const Text('add', style: TextStyle(color: Colors.white)),
    );
  }
}
