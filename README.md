# CareFlow — Clinic Management System

> A real-time digital clinic management system built with Flutter, Dart, Supabase, and PostgreSQL.

CareFlow is a modern clinic management platform designed to connect **patients, doctors, and clinics** in one centralized system.

It digitizes the clinic workflow — from patient registration and doctor discovery to appointment booking, consultation, medical records, payments, queue management, and follow-ups.

---

## 🚀 Project Overview

Traditional clinic management often depends on:

- Manual appointment registers
- Paper-based medical records
- Phone calls for appointment booking
- Manual patient queues
- Separate systems for doctors and patients
- Difficulty tracking patient history
- Limited communication between patients and doctors
- Manual payment and billing processes

CareFlow provides a centralized digital solution where patients, doctors, and clinic administrators can manage their activities through role-based interfaces.

---

## 🎯 Problem Statement

Many clinics still depend on disconnected and partially manual processes for:

- Patient registration
- Appointment scheduling
- Doctor availability
- Medical records
- Queue management
- Billing
- Payments
- Follow-up management
- Patient communication

This can result in delays, duplicate work, poor information accessibility, and difficulty maintaining accurate records.

### CareFlow Solution

**Patients**
- Discover doctors
- Book appointments
- Check queue status
- View medical records
- View prescriptions
- Manage health information
- Track appointments and payments

**Doctors**
- View appointments
- Manage consultations
- Access patient information
- Add medical records
- Manage prescriptions
- Handle follow-ups

**Clinics**
- Manage doctors
- Manage patients
- Manage appointments
- Monitor queues
- Manage clinic operations
- View analytics

---

# ✨ Key Features

## 👤 Patient Module

- Patient registration and login
- Patient dashboard
- Doctor discovery
- Doctor details
- Appointment booking
- Appointment management
- Queue tracking
- QR check-in
- Consultation information
- Medical records
- Test results
- Prescriptions
- Health information
- Follow-up management
- Payment tracking
- Billing information
- Notifications
- Messages
- Profile management
- Health preferences
- Privacy and security
- Help and support

## 👨‍⚕️ Doctor Module

- Doctor authentication
- Doctor dashboard
- Appointment management
- Patient information
- Consultation management
- Medical record management
- Prescription management
- Follow-up management
- Payment request management
- Doctor profile
- Appointment status tracking

## 🏥 Clinic Module

- Clinic dashboard
- Clinic profile
- Doctor management
- Add doctor
- Doctor details
- Patient management
- Patient details
- Appointment management
- Appointment details
- Queue management
- Clinic analytics
- Clinic home dashboard
- Clinic profile management

---

# 📅 Appointment Management

CareFlow provides a digital appointment workflow:

```text
Patient
   ↓
Select Doctor
   ↓
View Doctor Details
   ↓
Select Appointment
   ↓
Book Appointment
   ↓
Payment
   ↓
Appointment Confirmation
   ↓
Clinic Queue
   ↓
QR Check-in
   ↓
Consultation
   ↓
Medical Records
   ↓
Prescription / Follow-up
```

---

# 🔄 Clinic Workflow

```text
Patient Registration
        ↓
Doctor Discovery
        ↓
Appointment Booking
        ↓
Payment
        ↓
Appointment Confirmation
        ↓
Queue Management
        ↓
Patient Check-in
        ↓
Doctor Consultation
        ↓
Medical Records
        ↓
Prescription
        ↓
Follow-up
```

---

# 🔐 Authentication & Security

CareFlow uses Supabase Authentication for user authentication.

The system is designed around role-based access:

```text
                    CareFlow
                       |
          ┌────────────┼────────────┐
          ↓            ↓            ↓
       Patient       Doctor       Clinic
          |            |            |
       Patient       Doctor       Clinic
      Dashboard     Dashboard     Dashboard
```

Database-level security is implemented using **Row Level Security (RLS)** where applicable so users can access data according to their role and ownership.

---

# 🗄️ Database

CareFlow uses **PostgreSQL** through Supabase.

The database manages information such as:

- User profiles
- Patients
- Doctors
- Clinics
- Appointments
- Medical records
- Prescriptions
- Payments
- Queues
- Notifications
- Messages
- Follow-ups

The application is designed to use real database data rather than hardcoded patient or doctor information.

---

# ⚡ Real-Time Architecture

```text
                Flutter Application
                       |
                       ↓
                Supabase Client
                       |
             ┌─────────┼─────────┐
             ↓         ↓         ↓
        PostgreSQL    Auth     Storage
             |
             ↓
      Real-Time Updates
             |
             ↓
      Flutter UI Updates
```

---

# 🛠️ Technology Stack

| Technology | Purpose |
|---|---|
| Flutter | Cross-platform application development |
| Dart | Application programming language |
| Supabase | Backend-as-a-Service |
| PostgreSQL | Relational database |
| Supabase Auth | Authentication |
| Supabase Storage | File and image storage |
| Supabase Realtime | Real-time updates |
| Supabase Edge Functions | Backend/server-side logic |
| SQL | Database operations |
| Git | Version control |
| GitHub | Source code hosting |

---

# 📱 Application Structure

```text
careflow/
│
├── android/
├── ios/
├── linux/
├── macos/
├── windows/
├── web/
│
├── assets/
│   └── images/
│
├── database/
│   └── schema.sql
│
├── docs/
│
├── lib/
│   ├── core/
│   │   ├── app.dart
│   │   ├── config/
│   │   ├── constants/
│   │   └── theme/
│   │
│   ├── features/
│   │   └── careflow/
│   │       ├── models/
│   │       ├── screens/
│   │       ├── services/
│   │       └── widgets/
│   │
│   ├── models/
│   ├── screens/
│   │   ├── auth/
│   │   ├── clinic/
│   │   ├── doctor/
│   │   ├── patient/
│   │   └── profile/
│   │
│   ├── services/
│   ├── ui/
│   └── widgets/
│
├── sql/
│
├── supabase/
│   ├── functions/
│   └── *.sql
│
├── test/
├── pubspec.yaml
├── README.md
└── .gitignore
```

---

# 🧩 Main Application Modules

### Authentication

```text
Login
Register
Role Identification
Session Management
Logout
```

### Patient

```text
Dashboard
Doctors
Appointments
Queue
QR Check-in
Consultation
Medical Records
Prescriptions
Payments
Notifications
Profile
```

### Doctor

```text
Dashboard
Appointments
Patients
Consultations
Medical Records
Prescriptions
Follow-ups
Payments
Profile
```

### Clinic

```text
Dashboard
Doctors
Patients
Appointments
Queue
Analytics
Clinic Profile
```

---

# 💳 Payment Management

CareFlow includes a payment workflow for appointment-related transactions.

```text
Appointment
     ↓
Payment Request
     ↓
Payment Processing
     ↓
Payment Verification
     ↓
Appointment Confirmation
```

Payment-related backend operations can be handled through Supabase Edge Functions.

---

# 📲 QR Check-in

CareFlow includes QR-based patient check-in.

```text
Patient Appointment
        ↓
Generate / Access QR
        ↓
Clinic Check-in
        ↓
Appointment Verification
        ↓
Queue
```

This helps reduce manual check-in and connects the appointment workflow with clinic queue management.

---

# 📊 Clinic Analytics

The clinic module provides an analytics section for monitoring clinic operations.

Possible operational metrics include:

- Appointments
- Patients
- Doctors
- Queue activity
- Appointment status
- Clinic activity

---

# 🗃️ Data Management

CareFlow follows a database-driven approach.

The application does **not depend on hardcoded patient information**.

```text
Flutter UI
    ↓
Service Layer
    ↓
Supabase
    ↓
PostgreSQL
    ↓
Real Database Data
```

If the database contains no records, the application should display appropriate empty states rather than inventing fake data.

---

# ⚙️ Setup

## 1. Clone the repository

```bash
git clone https://github.com/Tetra-Smart4/Care-Flow.git
cd Care-Flow
```

## 2. Install Flutter dependencies

```bash
flutter pub get
```

## 3. Configure Supabase

Create a Supabase project and configure:

- Supabase URL
- Publishable/Anon Key
- PostgreSQL database
- Authentication
- Storage
- Required SQL schema
- Required Edge Functions

## 4. Configure application keys

Run the application using your Supabase project configuration.

### General

```bash
flutter run --dart-define=SUPABASE_URL=https://cwzymgamqijeoeqnnkvc.supabase.co --dart-define=SUPABASE_ANON_KEY="sb_publishable_novQC_rpsn_E5PX3tR1Scg_DWS10ry7"
```

### PowerShell

```powershell
flutter run `
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLISHABLE_ANON_KEY
```

Replace the placeholder values with your own project configuration.

---

# 🗄️ Database Setup

SQL files are provided inside the project.

Important database files include:

```text
database/
└── schema.sql

sql/
├── careflow_full_missing_features.sql
└── clinic_module_v1.sql

supabase/
├── patient_schema.sql
└── demo_payment_rpc.sql
```

### Important

Before executing SQL scripts against an existing CareFlow database:

1. Check the current database schema.
2. Verify existing tables.
3. Check existing columns.
4. Check foreign keys.
5. Check Row Level Security policies.
6. Avoid creating duplicate tables.
7. Apply migrations carefully.

---

# 🧪 Testing

Run Flutter analysis:

```bash
flutter analyze
```

Run tests:

```bash
flutter test
```

Run the application:

```bash
flutter run
```

---

# 📁 Project Documentation

Additional documentation is available inside:

```text
docs/
```

Important documents include:

```text
docs/SUPABASE_SETUP.md
docs/careflow_specification.md
```

Database scripts are available inside:

```text
database/
sql/
supabase/
```

---

# 🔒 Security Guidelines

Never commit private credentials to GitHub.

Do NOT commit:

```text
.env
.env.*
service-role keys
database passwords
private API secrets
payment provider secret keys
```

Use environment variables or secure backend configuration for sensitive credentials.

The Flutter application should only contain credentials intended for client-side use.

---

# 🌐 GitHub Repository

**Repository:**  
https://github.com/Tetra-Smart4/Care-Flow

---

# 🎯 Project Objectives

CareFlow aims to:

- Digitize clinic operations
- Reduce manual appointment management
- Improve patient experience
- Improve doctor workflow
- Centralize patient information
- Reduce unnecessary waiting
- Improve clinic queue management
- Provide better access to medical information
- Enable secure digital communication
- Provide a scalable clinic management architecture

---

# 🔮 Future Scope

Future versions of CareFlow can introduce:

- Video consultation
- Online prescription delivery
- Medicine ordering
- Advanced clinic analytics
- AI-assisted symptom analysis
- Smart doctor recommendations
- Automated appointment reminders
- WhatsApp/SMS notifications
- Digital health reports
- Insurance integration
- Multi-clinic support
- Advanced payment integration
- Cloud-based medical document management
- Hospital integration
- Wearable health-data integration

---

# ✅ Advantages

- Centralized clinic management
- Role-based access
- Real-time backend
- Digital appointment booking
- Reduced manual work
- Digital medical records
- Queue management
- QR-based check-in
- Scalable PostgreSQL database
- Cross-platform Flutter application
- Secure authentication
- Modular application architecture

---

# ⚠️ Limitations

- Requires internet connectivity for cloud-based functionality
- Depends on Supabase backend availability
- Some advanced healthcare integrations require external services
- Payment gateway integration requires proper production configuration
- Production deployment requires additional security and compliance review

---

# 👥 Team

## Tetra Smart

**Project:** CareFlow — Clinic Management System

CareFlow is developed as a team-based academic/project initiative focused on improving clinic management through modern mobile application technologies.

---

# 📌 Project Status

**Current Version:** V1.0

### Implemented

- Flutter application
- Supabase integration
- PostgreSQL database
- Authentication
- Patient module
- Doctor module
- Clinic module
- Appointment management
- Queue management
- QR check-in
- Medical records
- Prescriptions
- Payments
- Notifications
- Clinic management
- Real-time backend architecture

---

# 📜 License

This project is developed for educational and project demonstration purposes.

---

## CareFlow

### Connect. Manage. Care.

**Flutter + Dart + Supabase + PostgreSQL**
