# CareFlow — Complete UI, Screens, Services & Feature Specification

## 1. Project Stack

- Frontend: Flutter + Dart
- Backend: Supabase
- Database: PostgreSQL
- Authentication: Supabase Auth
- Storage: Supabase Storage
- Realtime: Supabase Realtime
- Server logic: Supabase Edge Functions
- Notifications: Firebase Cloud Messaging / Supabase-triggered notifications
- Architecture: Feature-based + service/repository pattern

---

## 2. Authentication & Onboarding

Screens:

1. Splash Screen
2. Onboarding 1
3. Onboarding 2
4. Onboarding 3
5. Welcome / Get Started
6. Choose Role
   - Patient
   - Doctor
   - Clinic
7. Login
8. Register
9. Email Verification
10. Forgot Password
11. Reset Password
12. OTP Verification
13. Change Password
14. Session Expired
15. Account Locked
16. Account Verification Pending
17. Delete Account
18. Logout Confirmation

Flow:

Splash → Onboarding → Welcome → Choose Role → Login/Register → Verification → Role Dashboard

---

# 3. Patient Module

## Patient Navigation

- Home
- Appointments
- Records
- Messages
- Profile

## Patient Dashboard

- Greeting
- Book Appointment
- My Health
- Prescriptions
- Test Results
- Upcoming Appointment
- Health Summary
- Recent Activity

## Patient Screens

### Appointments
- Upcoming
- Past
- Cancelled
- Reschedule
- Appointment Details
- Check-in

### Find Doctor
- Search
- Specialty
- Location
- Availability
- Doctor Profile
- Book Appointment

### Medical Records
- Consultation Records
- Prescriptions
- Lab Reports
- Medical Documents
- Upload Document
- Medical Timeline

### Health
- Vitals
- Blood Pressure
- Heart Rate
- Weight
- Blood Sugar
- Health Trends

### Prescriptions
- Active
- Completed
- Prescription Details
- Download Prescription

### Test Results
- Pending
- Available
- Result Details

### Messages
- Doctor Chat
- Clinic Chat
- Notifications
- Attachments

### Payments
- Bills
- Payment History
- Receipts

### Profile
- Personal Information
- Health Preferences
- Notifications
- Privacy & Security
- Help & Support
- Sign Out

---

# 4. Doctor Module

## Doctor Navigation

- Home
- Appointments
- Patients
- Records
- Profile

## Doctor Dashboard

Display:

- Today's Appointments
- New Patients
- Follow-ups
- Messages
- Today's Schedule
- Patient Alerts
- Reports Awaiting Review
- Prescription Alerts

## Doctor Screens

### Appointments
- Today's Schedule
- Upcoming
- Completed
- Cancelled
- Appointment Details
- Start Consultation
- Complete Consultation

### Patients
- Patient List
- Search
- Patient Profile
- Medical History
- Allergies
- Previous Visits
- Prescriptions
- Lab Reports
- Documents

### Consultation
- Patient Information
- Symptoms
- Diagnosis
- Vitals
- Notes
- Prescription
- Lab Test
- Follow-up Date
- Complete Consultation

### Prescriptions
- Create
- Active
- Previous
- Templates

### Reports
- Lab Reports
- Imaging
- Pending Review
- Reviewed

### Messages
- Patient Conversations
- Attachments
- Read Status

### Profile
- Personal Information
- Professional Details
- Specialization
- Qualification
- Availability
- Consultation Fee
- Notifications
- Privacy
- Help & Support
- Logout

---

# 5. Clinic Manager Module

## Clinic Navigation

- Home
- Doctors
- Patients
- Appointments
- Analytics
- Profile
- Staff
- Billing
- Inventory
- Reports
- Notifications
- Settings

## Clinic Dashboard

Display:

- Doctors
- Patients
- Today's Appointments
- New Patients
- Follow-ups
- Messages
- Satisfaction
- Revenue
- Pending Payments
- Today's Overview
- Weekly/Monthly Performance

Quick Actions:

- Add Doctor
- Add Staff
- Register Patient
- Create Appointment
- Generate Report
- Add Service

---

# 6. Doctor Management

Features:

- Add Doctor
- Edit Doctor
- View Doctor
- Activate/Deactivate
- Assign Department
- Assign Schedule
- Set Consultation Fee
- View Appointments
- View Patients
- View Performance
- Manage Documents

Doctor Details:

- Personal Information
- Professional Information
- Specialization
- Qualification
- Experience
- License Number
- Schedule
- Appointments
- Patients
- Performance
- Reviews
- Documents

---

# 7. Patient Management

Features:

- Register Patient
- Edit Patient
- Search Patient
- Filter Patient
- View Patient
- Assign Doctor
- Appointment History
- Medical History
- Prescriptions
- Lab Results
- Payments
- Documents

Patient Profile:

- Patient ID
- Name
- Age
- Gender
- Phone
- Email
- Blood Group
- Allergies
- Chronic Conditions
- Emergency Contact

---

# 8. Appointment Management

Appointment lifecycle:

Requested
→ Confirmed
→ Checked In
→ Consultation
→ Completed
→ Invoice Generated
→ Payment Completed

Features:

- Create Appointment
- Reschedule
- Cancel
- Confirm
- Check-in
- Start Consultation
- Complete
- No-show
- Walk-in Appointment
- Calendar View
- Doctor Availability
- Queue Management

---

# 9. Staff Management

Staff types:

- Doctors
- Nurses
- Receptionists
- Lab Technicians
- Accountants
- Administrators

Features:

- Add Staff
- Assign Role
- Assign Department
- Manage Permissions
- Activate/Deactivate
- Staff Attendance
- Staff Schedule

---

# 10. Billing & Payments

Dashboard:

- Today's Revenue
- Pending Payments
- Paid Amount
- Invoices
- Payments
- Refunds

Invoice:

- Patient
- Services
- Consultation
- Tests
- Medicines
- Tax
- Discount
- Total

Payment methods:

- Cash
- UPI
- Card
- Online Payment

Features:

- Generate Invoice
- Payment Tracking
- Receipt
- Refund
- Payment History

---

# 11. Pharmacy / Inventory

Features:

- Add Medicine
- Edit Medicine
- Stock In
- Stock Out
- Expiry Tracking
- Low Stock Alerts
- Supplier Management
- Purchase Records
- Medicine Categories
- Inventory Transactions

Dashboard:

- Total Items
- Low Stock
- Expiring Soon
- Today's Stock Movement

---

# 12. Laboratory Module

Workflow:

Doctor Orders Test
→ Lab Receives Request
→ Technician Performs Test
→ Result Entered
→ Report Generated
→ Doctor Notified
→ Patient Sees Report

Screens:

- Lab Dashboard
- Pending Tests
- Test Orders
- Test Details
- Enter Results
- Generate Report
- Completed Tests
- Reports Awaiting Review

---

# 13. Notifications

Notification types:

- Appointment Confirmed
- Appointment Reminder
- Appointment Cancelled
- Test Result Available
- Prescription Updated
- Payment Received
- Doctor Message
- Low Inventory
- New Patient
- System Notification

Use Supabase Realtime where appropriate.

---

# 14. Analytics

Clinic analytics:

- Appointments
- Patients
- Revenue
- Doctors
- Services
- Satisfaction

Charts:

- Weekly Appointments
- Monthly Revenue
- Patient Growth
- Doctor Performance
- Cancellation Rate
- No-show Rate
- Popular Services
- Revenue Trends

---

# 15. Reports

Generate:

- Daily Report
- Weekly Report
- Monthly Report
- Doctor Report
- Patient Report
- Revenue Report
- Appointment Report
- Inventory Report
- Staff Report

Export:

- PDF
- CSV
- Excel

---

# 16. Messaging

Realtime chat between:

- Patient ↔ Doctor
- Patient ↔ Clinic
- Clinic ↔ Staff

Features:

- Text
- Images
- PDF Reports
- Prescription Attachments
- Read/Unread
- Online Status
- Typing Indicator

Use Supabase Realtime.

---

# 17. Profile System

## Patient

- Personal Information
- Health Preferences
- Notifications
- Privacy & Security
- Help & Support
- Sign Out

## Doctor

- Personal Information
- Professional Details
- Availability
- Notifications
- Privacy & Security
- Help & Support
- Sign Out

## Clinic

- Clinic Information
- Staff Management
- Working Hours
- Notifications
- Privacy & Security
- Subscription
- Help & Support
- Sign Out

---

# 18. Database Architecture

Recommended tables:

- profiles
- roles
- clinics
- clinic_staff
- doctors
- patients
- doctor_availability
- appointments
- appointment_status_history
- medical_records
- medical_documents
- vitals
- prescriptions
- prescription_items
- lab_tests
- lab_orders
- lab_results
- messages
- message_attachments
- notifications
- invoices
- invoice_items
- payments
- medicines
- inventory
- suppliers
- inventory_transactions
- services
- reviews
- audit_logs

---

# 19. Flutter Project Architecture

lib/

    core/
        config/
        theme/
        routing/
        constants/
        utils/

    models/
        user_model.dart
        patient_model.dart
        doctor_model.dart
        clinic_model.dart
        appointment_model.dart
        prescription_model.dart
        medical_record_model.dart
        lab_result_model.dart
        invoice_model.dart
        payment_model.dart
        notification_model.dart

    services/
        auth_service.dart
        profile_service.dart
        patient_service.dart
        doctor_service.dart
        clinic_service.dart
        appointment_service.dart
        medical_record_service.dart
        prescription_service.dart
        lab_service.dart
        billing_service.dart
        payment_service.dart
        inventory_service.dart
        notification_service.dart
        messaging_service.dart
        analytics_service.dart
        report_service.dart
        logout_service.dart

    repositories/
        auth_repository.dart
        appointment_repository.dart
        patient_repository.dart
        doctor_repository.dart
        clinic_repository.dart

    screens/
        auth/
        patient/
        doctor/
        clinic/
        appointments/
        medical_records/
        prescriptions/
        laboratory/
        billing/
        inventory/
        messaging/
        analytics/
        notifications/
        profile/

    widgets/
        app_card.dart
        stat_card.dart
        appointment_card.dart
        patient_card.dart
        doctor_card.dart
        empty_state.dart
        loading_state.dart
        error_state.dart
        confirmation_dialog.dart

---

# 20. Realtime Features

Use Supabase Realtime for:

- Appointments
- Messages
- Notifications
- Lab Results
- Prescriptions
- Payments
- Inventory
- Patient Updates

Do not fake realtime data with hardcoded timers.

---

# 21. Security

Use:

- Supabase Auth
- PostgreSQL Row Level Security
- Role-based authorization
- Clinic-based data isolation
- Audit logs
- Secure file storage
- Server-side validation
- Edge Functions for sensitive operations

Access rules:

Patient:
- Own profile
- Own medical records
- Own appointments
- Own prescriptions
- Own payments

Doctor:
- Assigned patients
- Assigned appointments
- Clinical records required for care

Clinic Manager:
- Clinic doctors
- Clinic patients
- Clinic appointments
- Clinic staff
- Clinic billing
- Clinic analytics

Admin:
- Platform-level management

---

# 22. UI Design System

Use the uploaded CareFlow reference as the visual baseline.

Colors:

Primary Blue: #1677E8
Green: #35B96F
Dark Navy: #10245C
Background: #F5F9FC
Card: #FFFFFF

Style:

- Rounded cards
- Soft shadows
- Large whitespace
- Blue/green healthcare palette
- 16–20px corner radius
- Clean typography
- Bottom navigation
- Status badges
- Large dashboard statistics
- Minimal icons
- Smooth transitions
- Consistent spacing
- Responsive layouts

Do not turn the application into a generic admin dashboard. Preserve the CareFlow visual identity.

---

# 23. Additional Features

High-value:

1. Smart appointment scheduling
2. Doctor availability
3. Patient queue management
4. Walk-in registration
5. Digital prescriptions
6. Lab workflow
7. Billing
8. Inventory
9. Realtime messaging
10. Clinic analytics
11. Staff management
12. Role-based permissions
13. Audit logs
14. Automated appointment reminders
15. Low-stock alerts
16. Payment tracking
17. PDF medical reports
18. Patient medical timeline

Advanced:

19. Teleconsultation
20. QR patient check-in
21. Digital token/queue system
22. Insurance information
23. Referral management
24. Multi-branch clinic support
25. Doctor leave management
26. Staff attendance
27. Subscription management
28. Emergency contact
29. Health trend graphs
30. Backup/export system

---

# 24. Master AI Coding Prompt

Build CareFlow as a production-style Flutter + Dart healthcare clinic management application using Supabase and PostgreSQL.

Use the provided CareFlow UI reference as the visual design source. Recreate the same clean blue/green healthcare design language across every screen.

Implement complete role-based navigation for Patient, Doctor and Clinic Manager.

Do not use fake/static data in the final application.

All users, appointments, patients, doctors, medical records, prescriptions, laboratory results, notifications, messages, invoices, payments and inventory must come from PostgreSQL through Supabase services.

Implement:

- Authentication
- Role-based routing
- Profile management
- Patient dashboard
- Doctor dashboard
- Clinic manager dashboard
- Appointment management
- Doctor management
- Patient management
- Medical records
- Prescriptions
- Laboratory workflow
- Billing
- Payments
- Inventory
- Notifications
- Messaging
- Analytics
- Reports
- Settings

Use clean architecture with models, repositories, services, screens and reusable widgets.

Do not put Supabase queries directly into UI widgets.

Implement loading, empty, error and success states for every data-driven screen.

Implement proper Supabase RLS policies for Patient, Doctor, Clinic Manager and Admin access.

Use Supabase Realtime for appointments, messages, notifications, laboratory updates, prescriptions, payments and inventory changes.

The Clinic Manager dashboard must provide clinic statistics, appointments, doctors, patients, revenue, satisfaction, analytics, staff management, billing, inventory and reports.

The Patient dashboard must provide appointment booking, doctor discovery, medical records, prescriptions, laboratory results, health metrics, payments and messaging.

The Doctor dashboard must provide today's schedule, patient management, consultations, medical history, prescriptions, laboratory orders, reports and messaging.

Maintain the CareFlow visual identity shown in the reference image:
- white cards
- blue/green gradient branding
- rounded components
- soft shadows
- healthcare illustrations
- clean typography
- compact bottom navigation
- professional medical UI

Every screen must be responsive, reusable and connected to real backend data.

Avoid:
- duplicate screens
- duplicate database records
- hardcoded dashboard statistics
- fake API responses
- placeholder services
- broken routes
- missing services

Build in this order:

1. Database schema
2. Relationships
3. RLS policies
4. Supabase configuration
5. Authentication
6. Profiles
7. Role routing
8. Patient module
9. Doctor module
10. Clinic Manager module
11. Appointments
12. Medical records
13. Prescriptions
14. Laboratory
15. Billing
16. Inventory
17. Messaging
18. Analytics
19. Reports
20. Security
21. Testing

Before finishing, run:

flutter pub get
dart format .
flutter analyze

Fix all analyzer errors and broken routes before considering the project complete.
