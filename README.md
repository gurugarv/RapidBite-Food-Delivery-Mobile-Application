# 🍔 RapidBite – Flutter Food Delivery App

![RapidBite](https://via.placeholder.com/1200x600/01696f/ffffff?text=RAPIDBITE)  
**A complete Flutter‑based food delivery platform** with customer ordering, real‑time tracking, and restaurant owner dashboard. Supports location services, Razorpay payments, SQLite persistence, and Google Maps integration.

[![Flutter](https://img.shields.io/badge/Flutter-3.0%2B-blue?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0%2B-blue?logo=dart)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![SQLite](https://img.shields.io/badge/SQLite-sqflite-green)](https://pub.dev/packages/sqflite)

---

## 🚀 Project Overview

**RapidBite** solves the problem of **designing a food delivery app compatible with Android Auto** – users can browse menus, place orders, and track deliveries from car infotainment using voice commands and distraction‑free UI. Built as a full‑stack Flutter app with both **customer** and **restaurant owner** interfaces.[file:11]

**Team:** Myiesha Chaudhary (A211), Lavanya Jadhav (A222), **Garv Singh (A230)**

---

## 🌟 Features

### Customer Flow
- **Animated Splash** – Logo video intro → Login/Signup
- **Authentication** – Email/password login with SQLite validation + error snackbars
- **Location Services** – GPS permissions → Current lat/long → Nearby restaurants on Google Maps
- **Restaurant Search** – Map markers → Tap to view restaurant menu
- **Menu Browsing** – Food items, prices, add/remove from cart, subtotal calculation
- **Cart & Checkout** – Quantity editing, coupon codes (e.g., SAVE10), optional donations, final total
- **Razorpay Payments** – Secure payment gateway with success/failure handling
- **Order Tracking** – Live map with restaurant + user location updates
- **Dashboard** – Recent orders, recommendations, quick actions
- **Order History** – Past orders, reorder, receipts
- **Profile & Settings** – Edit details, password change, notifications, privacy

### Restaurant Owner Dashboard
- **Owner Dashboard** – Sales summary, new orders, stats
- **Owner Orders** – Accept/reject orders, status updates
- **Menu Management** – Add/edit/remove items, availability, pricing
- **Notifications** – Real‑time order alerts, mark as read
- **Analytics** – Sales trends, popular items, charts/graphs

[file:11]

---

## 🛠️ Tech Stack

| Category | Technologies |
|----------|--------------|
| **Framework** | Flutter, Dart |
| **Database** | SQLite (`sqflite`), `database_helper.dart` |
| **Location** | `geolocator`, Google Maps API |
| **Payments** | Razorpay Flutter SDK |
| **Media** | `video_player`, Lottie animations |
| **Navigation** | `main.dart` route management |
| **State** | Provider / setState (local persistence) |


**Key Files:**[file:11]
- `database_helper.dart` – User tables, insert/fetch credentials
- `main.dart` – Central navigation hub
- `payment_page.dart` – Razorpay success/failure handlers

---
<img width="570" height="493" alt="Screenshot 2026-04-02 at 10 01 31 PM" src="https://github.com/user-attachments/assets/208480d8-a8c6-4607-9ffc-0daeddfbe76a" />

## 🚀 Quick Setup

1. **Clone & Dependencies**
   ```bash
   git clone https://github.com/garvsingh/rapidbite.git
   cd rapidbite
   flutter pub get
