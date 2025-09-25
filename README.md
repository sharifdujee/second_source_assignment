# chat_application

A new Flutter project.

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

## Getting Started

The instruction for run the app in your local machine.

step one: first clone the source code use the following command 
** git clone then url of the repository ** 
example : git clone git clone https://github.com/octocat/Spoon-Knife.git

step two : after clone the app open the app in your IDE/Code Editor

after complete the open process it give error to resolve the error give the following command 
flutter pub get

Note : If your flutter sdk is not match with current project sdk version then you could upgrade your sdk or change the sdk version from pubspec.yaml file.
you also need to change the version of some package like intl, local_notification, firebase_messaging and others package if required.

after complete the package  download and installation the error is gone, now you can run the application.

Step three: for run the application you can see a run button top right or left based on your code editor in andriod studio you can find it top right and vs code you can see run command select option from here based on your IDE, you can also run it via commad flutter run.

Firebase Step instruction:

step one : first go to the firebase console 
https://console.firebase.google.com/u/0/
in firebase console create a new project after clikc the new project enter your project name like chat-application or anything you want, it take some moments, wait until complete it.

step two : after project setup is done you could add app in your firebase project , select flutter icon and click the next 
in this phase you could give the following command in your global terminal like cmd or bash based on your operating system
dart pub global activate flutterfire_cli

then give the next command in your project level terminal : flutterfire configure --project=chat-app-d4cd9

after give the above command you could see the project ios, andriod, web, mac, linux, 
from here you could select your desired platform after select the platform it usually take some time based on your internent speed, after complete this step three new file automatically add in your project,
firebase_otpions, googleservice , google_service.info.plist respotively lib, andriod and ios folder.

Step Three: update your main.dart like following 
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// ...

await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
);

after complete the following process, now you could again run your application.


- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

```markdown
## 📌 Notes
> 📝 **Important:**  
> - Follow the current repository for future updates.  
> - Make sure your internet connection is stable during Firebase setup.




