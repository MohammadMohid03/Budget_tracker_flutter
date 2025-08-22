# Flutter Budget Tracker App

A beautifully animated, cross-platform budget and expense tracking application built with Flutter and Firebase. This app provides a fluid, visually engaging user experience with glassmorphism effects, animated gradients, and interactive charts, all powered by a secure and scalable Firebase backend.

---

## ✨ Key Features

-   **Firebase Authentication:** Secure email & password sign-up and login.
-   **Expense Management:** Easily add, edit, and delete expenses.
-   **Categorization:** Assign expenses to categories like Food, Transport, and Shopping for better tracking.
-   **Dynamic Home Dashboard:** Get an at-a-glance view of your spending for the current month and your total overall spending.
-   **Interactive Charts:** Visualize your spending habits with:
    -   A **Bar Chart** for spending by category.
    -   A **Pie Chart** for expense distribution.
    -   A **Line Chart** to track spending trends over the last 30 days.
-   **Monthly Budgeting:** Set monthly spending limits for different categories and track your progress with visual progress bars.
-   **Data Persistence:** All data is securely stored and synced in real-time using Cloud Firestore.
-   **Stunning UI/UX:** A consistent, modern design featuring:
    -   Animated gradient backgrounds.
    -   Glassmorphism card effects.
    -   Smooth page transitions and entrance animations.
-   **Custom App Icon:** A fully branded app experience from the home screen.

---

## 📸 Screenshots

| Home Screen                                       | Add Expense Screen                                    |
| ------------------------------------------------- | ----------------------------------------------------- |
| ![Home Screen](https://github.com/user-attachments/assets/b548b6e4-ad89-4e4a-a529-3e1acd49024e)| ![Add Expense Screen](https://github.com/user-attachments/assets/3ec4e538-0d1f-44b2-8cb4-16ed3a0dcaf1)|

| Budget Screen                                     | Charts Screen                                     |
| ------------------------------------------------- | ------------------------------------------------- |
| ![Budget Screen](https://github.com/user-attachments/assets/6aacad22-43a7-4755-b963-a2cd92f8726c)| ![Chart Screen](https://github.com/user-attachments/assets/4c5a9731-2b63-4f5f-a59e-be4d8dccc673)|

---

## 🛠️ Technology Stack

-   **Framework:** Flutter
-   **Backend & Database:** Firebase (Authentication, Cloud Firestore)
-   **State Management:** `StatefulWidget` & `setState`
-   **Key Packages:**
    -   `firebase_core`, `firebase_auth`, `cloud_firestore`
    -   `fl_chart` for beautiful, interactive charts.
    -   `intl` for date formatting.
    -   `flutter_launcher_icons` for generating the app icon.

---

## 🚀 Getting Started

To get a local copy up and running, follow these simple steps.

### Prerequisites

-   You must have Flutter installed on your machine. [Flutter Installation Guide](https://flutter.dev/docs/get-started/install)
-   A code editor like VS Code or Android Studio.

### Installation & Setup

1.  **Clone the repository:**
    ```sh
    git clone https://github.com/MohammadMohid03/Budget_tracker_flutter.git
    ```

2.  **Navigate to the project directory:**
    ```sh
    cd Budget_tracker_flutter
    ```

3.  **Install dependencies:**
    ```sh
    flutter pub get
    ```

4.  **Set up Firebase:**
    This project requires a Firebase backend. Follow the detailed instructions in the section below.

5.  **Run the app:**
    ```sh
    flutter run
    ```

---

## 🔥 Firebase Configuration

This app will not run without a Firebase project. Follow these steps carefully.

1.  **Create a Firebase Project:**
    -   Go to the [Firebase Console](https://console.firebase.google.com/) and create a new project.

2.  **Add a Flutter App:**
    -   Inside your project, click on the Flutter icon to add a new Flutter app. Follow the on-screen instructions provided by the Firebase CLI.
    -   This will automatically handle adding the necessary Android and iOS apps and downloading the configuration files. The command is typically:
      ```sh
      flutterfire configure
      ```

3.  **Enable Authentication:**
    -   In the Firebase Console, go to **Authentication** (under the "Build" section).
    -   Click on the **Sign-in method** tab.
    -   Enable the **Email/Password** provider and save.

4.  **Set up Cloud Firestore:**
    -   Go to **Firestore Database** (under the "Build" section).
    -   Click **Create database**.
    -   Start in **Test mode** for initial setup. You can apply the secure rules later.
    -   Choose a location for your database.

5.  **Update Firestore Security Rules:**
    -   Go to the **Rules** tab in the Firestore Database section.
    -   Replace the default rules with the following secure rules and **Publish** them:
    ```javascript
    rules_version = '2';

    service cloud.firestore {
      match /databases/{database}/documents {

        match /expenses/{expenseId} {
          allow create: if request.auth != null && request.auth.uid == request.resource.data.userId;
          allow read, update, delete: if request.auth != null && request.auth.uid == resource.data.userId;
        }

        match /budgets/{budgetId} {
          allow create: if request.auth != null && request.auth.uid == request.resource.data.userId;
          allow read, update, delete: if request.auth != null && request.auth.uid == resource.data.userId;
        }
      }
    }
    ```

6.  **Create Firestore Index:**
    -   The app requires a composite index to filter and sort expenses efficiently.
    -   Go to the **Indexes** tab in the Firestore Database section.
    -   Click **Create Index**.
    -   **Collection ID:** `expenses`
    -   **Fields to index:**
        1.  `userId` -> **Ascending**
        2.  `date` -> **Descending**
    -   **Query scopes:** Collection
    -   Click **Create** and wait for the index to finish building.

Your backend is now fully configured! You can run the app.

---
