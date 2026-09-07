# Pathshala — Project Specification
*(Tuition App)*


## 1. Overview
- A mobile/web application that connects **teachers** and **students** for private tuition management.
- Eliminates the need for a physical attendance register.
- Digitizes the entire teaching–learning workflow (attendance, communication, payments, content sharing).
- Three user roles: **Teacher**, **Student**, and **Admin**.
- Supports **multiple tuition rooms per teacher** and **multiple room memberships per student** (a student may take tuition from several teachers).
- **Role-based authentication** (OTP/email verification) during signup, capturing role (Teacher/Student), class/grade, and institution.
- **Multi-language support** (Bengali/English toggle) throughout the app, since the primary user base is Bengali-speaking.
- **Push notifications** infrastructure covering all real-time events: new messages, poll creation, new content upload, attendance marked, assignment posted, exam result published, payment due/received, etc.
- **In-app calendar view** showing scheduled class days, exam dates, and payment due dates together in one place.
- **Data privacy**: tuition rooms are strictly private (visible only to joined members); users can request/export their own data.

---

## 2. Teacher Features

### 2.1 Student & Room Management
- Teacher can create and maintain a student list with: **Name, Roll Number, Email**.
- Teacher can create a **Tuition Room** (similar to Google Classroom).
- Each room has a unique **join code**; students use this code to join the room.
- Only members of the room can view room content — content is private and not visible to outsiders.

### 2.2 Messaging
- Teacher can send messages/announcements visible to everyone in the room.
- Teacher can toggle ON/OFF whether students are allowed to chat in the room.
- Teacher can create **Polls** for voting/feedback.
- Teacher can share **images** in messages (e.g., result sheets, notices).

### 2.3 Attendance
- Teacher can take attendance by marking a **tick/check** next to each student's name for a specific date.
- Attendance dates are restricted to the **class days configured for that tuition room** (see 2.5).
- A **summary view** of attendance is available, visible to both teacher and students.
- **Offline attendance sync**: teacher can mark attendance without an internet connection; data syncs automatically once back online.

### 2.4 Notifications & Payments
- **Automated notifications** remind students about upcoming tuition fee payments.
- Teacher can configure the **date/schedule** for these automatic notifications.
- Teacher can also send **custom (manual) notifications** anytime.
- When a teacher receives a payment, they can record it against the respective student's profile (separate "Payments" section).
- The system tracks:
  - Amount paid
  - Outstanding/due amount
  - Number of months a student has been in due (overdue tracking)
- This payment/due tracking is a **teacher-only** feature.
- **Payment history export** (PDF/CSV) so teachers can keep records and share proof of dues/payments with students or parents.

### 2.5 Tuition Room Schedule
- Teacher can define which weekdays the tuition is held (e.g., Sunday, Tuesday, Thursday).
- Attendance can only be marked on the configured class days for that room.

### 2.6 Assignments & Homework
- Teacher can post assignments/homework with a due date to a tuition room.
- Students can submit responses (text, file, or image).
- Teacher can review submissions and assign grades/feedback.

### 2.7 Exams & Performance Tracking
- Teacher can record test/exam scores for each student.
- Scores roll up into a **performance summary/graph** per student.
- Teacher can optionally enable a **leaderboard** view for students (visibility is teacher-controlled).

### 2.8 Parent Access (Optional)
- Teacher can grant a **read-only parent account/view** linked to a student.
- Parents can see the linked child's attendance, dues/payments, and performance — no editing rights.

---

## 3. Student Features

- Students can view the **attendance summary** — either:
  - All students' summary (if the teacher grants access), or
  - Only their own summary (default/restricted access).
- Students can view **all notifications** sent by the teacher (auto + custom), plus an **in-app calendar** of class days, exam dates, and payment due dates.
- Students can **submit assignments/homework** (text, file, or image) posted by the teacher, and see grades/feedback once reviewed.
- Students can view their **exam scores and performance graph**, and a **leaderboard** if the teacher enables it.
- Upon opening the app, students see **two main sections**:
  - **School**
  - **Tuition**
  - (School classes can be added later using the same core feature set, since functionality is identical across both sections.)
- Students can **join a tuition room** using the room code.
- Joined rooms function like a Google Classroom feed/stream.
- Students can send messages in the room **only if the teacher has enabled chat access**.
- Students can **vote in polls** created by the teacher.
- Home page displays **lecture/content material** relevant to the student's class/grade.
  - This material is sourced from YouTube or other links, curated by the Admin.

---

## 4. Admin Features

- Admin manages **Teachers**, **Students**, and **Content**.
- Content consists of links/videos from YouTube channels or other external sources.
- Content visibility rules:
  - Some content is shown to **all students** (general content).
  - Some content is targeted to students based on their **class/grade**, shown in their personal profile/content feed.
  - Class/grade information is collected during **account registration**.
- Content section includes **Search** and **Filter** options, available to all users.
- Admin has an **analytics dashboard**: overall platform usage stats — active teachers/students, most-used content, engagement trends.

---

## 5. User Roles Summary

| Role    | Core Capabilities |
|---------|-------------------|
| Teacher | Manage students, create/manage multiple rooms, set class schedule, take attendance (with offline sync), send messages/polls/images, manage payments/dues (with export), configure notifications, post assignments & grade them, record exam scores, control leaderboard visibility, grant parent access |
| Student | Join multiple rooms, view attendance summary, view notifications & calendar, chat (if enabled), vote in polls, submit assignments, view exam performance/leaderboard, view curated content (School + Tuition sections) |
| Admin   | Manage teachers, students, and content; assign class-based content visibility; provide search/filter for content; view platform analytics dashboard |
| Parent  | (Optional) read-only view of linked child's attendance, dues, and performance |
