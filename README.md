# ASMOLG

**ASMOLG** (“A Smart Modular Learning Gateway”) is an enterprise-grade, full-stack learning platform engineered to deliver comprehensive engineering notes and educational resources. It seamlessly integrates a modern Flutter frontend, robust Node.js/Express backend services, Firebase functions, and secure payment processing to provide an end-to-end solution for students and educators.

---

## 🚀 Project Overview

ASMOLG empowers engineering students with:  
- **Centralized Access** to subject-wise notes, tutorials, and reference materials  
- **Interactive UI/UX**, featuring dashboards, search, and personalized recommendations  
- **Secure Payment Integration** for subscription plans and on-demand content purchases  
- **Real-Time Notifications** and offline/online status handling  
- **Scalable, Modular Architecture** leveraging Flutter, Angular/Dart, Firebase, and Node.js

---

## ✨ Key Features

1. **User Authentication & Authorization**  
   - Firebase Auth (email/password, social login)  
   - Role-based access control (students, instructors, administrators)  

2. **Content Management**  
   - Dynamic course and department cards  
   - Subject pages with PDF viewer, video embeds, and quizzes  

3. **Full-Stack Integration**  
   - **Frontend:** Flutter mobile app & Angular/Dart web components  
   - **Backend:** Node.js + Express.js RESTful APIs + Firebase Cloud Functions  

4. **Payment Gateway**  
   - Stripe & Razorpay integration  
   - Secure webhook handling for real-time payment status updates  

5. **Notifications & Offline Support**  
   - Firebase Cloud Messaging for push notifications  
   - Offline/online status detection and local caching  

6. **Analytics & Reporting**  
   - Usage metrics, progress tracking, and administrative dashboards  

---

## 🛠️ Technology Stack

| Layer               | Technology                                |
| ------------------- | ----------------------------------------- |
| **Frontend**        | Flutter (mobile), Angular/Dart (web)      |
| **Backend**         | Node.js, Express.js, Firebase Functions   |
| **Database**        | Firestore (Cloud Firestore)               |
| **Authentication**  | Firebase Auth                             |
| **Payments**        | Stripe, Razorpay                          |
| **Notifications**   | Firebase Cloud Messaging, Cloud Functions |
| **Hosting & CDN**   | Firebase Hosting, Google App Engine       |
| **CI/CD**           | GitHub Actions, Docker                    |

---

## 💻 Installation & Setup

```bash
# Clone the repository
git clone https://github.com/YourUsername/asmolg.git
cd asmolg
````

### Configure Firebase

* Place your `google-services.json` (Android) and/or `GoogleService-Info.plist` (iOS) in the appropriate platform directories
* Update `firebase_options.dart` with your Firebase project credentials

### Frontend (Flutter)

```bash
cd lib
flutter pub get
flutter run
```

### Environment Variables

1. Create a `.env` file in the `backend` directory
2. Add your Stripe and Razorpay API keys:

   ```env
   RAZORPAY_KEY=your_razorpay_key
   ```
3. Configure Firebase Admin credentials if using service accounts

### Deploy & Serve

* **Firebase Hosting & Functions**

  ```bash
  firebase deploy --only hosting,functions
  ```
* **App Engine (optional)**

  ```bash
  gcloud app deploy
  ```

---

## 📸 Screenshots

<table>
  <tr>
    <td><img src="https://github.com/user-attachments/assets/30a3c6bb-236b-4dfa-a7a5-0362bfffa22e" width="200"/></td>
    <td><img src="https://github.com/user-attachments/assets/a06068b1-51ee-49ee-b04b-2e896fa4d184"width="200"/></td>
    <td><img src="https://github.com/user-attachments/assets/7b804396-bbb0-4e04-a4d8-a8b6ea7cc0a9" width="200"/></td>
  </tr>
  <tr>
    <td><img src="https://github.com/user-attachments/assets/f7bffd84-0041-43b6-b984-4fb765359ef6" width="200"/></td>
    <td><img src="https://github.com/user-attachments/assets/6c5df4da-f8e5-40bb-a8d6-3b0cb752dc39" width="200"/></td>
    <td><img src="https://github.com/user-attachments/assets/61cde432-25a5-479f-8a74-17add220452a" width="200"/></td>
  </tr>
  <tr>
    <td><img src="https://github.com/user-attachments/assets/5df435b6-9ae0-40b4-88f1-65ed2d5888f1" width="200"/></td>
    <td><img src="https://github.com/user-attachments/assets/e03044f1-2ce8-491f-8c98-a5834f2adf21" width="200"/></td>
    <td><img src="https://github.com/user-attachments/assets/e39c48a0-c7c9-4de4-ab55-95b557cc60a3" width="200"/></td>
  </tr><tr>
    <td><img src="https://github.com/user-attachments/assets/56c5c0ee-06c5-4c44-827d-0ce6e07c6af9" width="200"/></td>
    <td><img src="https://github.com/user-attachments/assets/aa4b7f11-6cec-4f8b-b430-d4944d452f39" width="200"/></td>
    <td><img src="https://github.com/user-attachments/assets/4290fa5c-dc01-4efc-8c58-e602193be10a" width="200"/></td>
  </tr>
   <tr>
    <td><img src="https://github.com/user-attachments/assets/997e7b21-c6a8-4094-8029-f4494936c967" width="200"/></td>
  </tr>
</table>


## 🤝 Contributing

```bash
# Fork the repository
# Create a feature branch
git checkout -b feature/YourFeature

# Commit your changes
git commit -m "Add YourFeature"

# Push to your branch
git push origin feature/YourFeature
```

Open a Pull Request describing your changes.
Please ensure all new features include appropriate tests and documentation.

---

## 📝 License

This project is licensed under the **MIT License**. See the `LICENSE` file for details.

---

## 📞 Contact

For support or business inquiries, please contact **Triroop Education Pvt. Ltd.**

* **Phone:** +91 9011694002
* **Email:** [triroopeducationpvtltd@gmail.com](mailto:triroopeducationpvtltd@gmail.com)

## 🎉 Contributors

- **Aditya Deshmukh**  
- **Saurabh Aralkar**  

---

Thank you for choosing ASMOLG – your gateway to engineering excellence.


```)
