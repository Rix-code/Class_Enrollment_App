import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  String _fullName = '';
  String _studentId = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create Your Account',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            SizedBox(height: 16.0),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildTextField(
                    label: 'Full Name',
                    onSaved: (value) => _fullName = value!,
                    validator: (value) =>
                    value!.isEmpty ? 'Please enter full name' : null,
                    icon: Icons.person,
                  ),
                  SizedBox(height: 16.0),
                  _buildTextField(
                    label: 'Student ID',
                    onSaved: (value) => _studentId = value!,
                    validator: (value) =>
                    value!.isEmpty ? 'Please enter student ID' : null,
                    icon: Icons.school,
                  ),
                  SizedBox(height: 16.0),
                  _buildTextField(
                    label: 'Email',
                    onSaved: (value) => _email = value!,
                    validator: (value) =>
                    value!.isEmpty ? 'Please enter email' : null,
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  SizedBox(height: 16.0),
                  _buildTextField(
                    label: 'Password',
                    onSaved: (value) => _password = value!,
                    validator: (value) =>
                    value!.isEmpty ? 'Please enter password' : null,
                    icon: Icons.lock,
                    obscureText: true,
                  ),
                  SizedBox(height: 24.0),
                  ElevatedButton(
                    onPressed: _register,
                    child: Text(
                      'Register',
                      style: TextStyle(fontSize: 18.0),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: EdgeInsets.symmetric(vertical: 14.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required FormFieldSetter<String> onSaved,
    required FormFieldValidator<String> validator,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        filled: true,
        fillColor: Colors.grey[200],
      ),
      obscureText: obscureText,
      keyboardType: keyboardType,
      onSaved: onSaved,
      validator: validator,
    );
  }

  void _register() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        await Provider.of<AuthService>(context, listen: false)
            .register(_email, _password, _fullName, _studentId);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }
}