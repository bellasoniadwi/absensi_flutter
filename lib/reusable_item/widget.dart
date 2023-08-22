import 'package:flutter/material.dart';

Image logoWidget(String imageName) {
  return Image.asset(
    imageName,
    fit: BoxFit.fitWidth,
    width: 240,
    height: 240,
    color: Colors.white,
  );
}

TextField reusableTextField(
  String text,
  IconData icon,
  {
    bool isPasswordType = false,
    bool isPasswordVisible = false,
    TextEditingController? controller,
    Function(bool)? onTogglePasswordVisibility,
  }
) {
  return TextField(
    controller: controller,
    obscureText: isPasswordType ? !isPasswordVisible : false, // Use the passed parameter here
    enableSuggestions: !isPasswordType,
    autocorrect: !isPasswordType,
    cursorColor: Colors.white,
    style: TextStyle(color: Colors.white.withOpacity(0.9)),
    decoration: InputDecoration(
      prefixIcon: Icon(
        icon,
        color: Colors.white70,
      ),
      labelText: text,
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.9)),
      filled: true,
      floatingLabelBehavior: FloatingLabelBehavior.never,
      fillColor: Colors.white.withOpacity(0.3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30.0),
        borderSide: const BorderSide(width: 0, style: BorderStyle.none),
      ),
      suffixIcon: isPasswordType
          ? IconButton(
              icon: Icon(
                isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.white70,
              ),
              onPressed: () {
            if (onTogglePasswordVisibility != null) {
              onTogglePasswordVisibility(!isPasswordVisible); // Use the passed parameter here
            }
          },
            )
          : null,
    ),
    keyboardType: isPasswordType
        ? TextInputType.visiblePassword
        : TextInputType.emailAddress,
  );
}



Container AuthButton(BuildContext context, bool isLogin, bool isLoading, Function onTap) {
  return Container(
    width: MediaQuery.of(context).size.width,
    height: 50,
    margin: const EdgeInsets.fromLTRB(0, 10, 0, 20),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(90)),
    child: ElevatedButton(
      onPressed: isLoading ? null : () => onTap(),
      child: isLoading
          ? CircularProgressIndicator( // Show the loading indicator
              valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
            )
          : Text(
            isLogin ? 'LOG IN' : 'SIGN UP',
            style: const TextStyle(
            color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.pressed)) {
              return Colors.black26;
            }
            return Colors.white;
          }),
          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)))),
      
    ),
  );
}