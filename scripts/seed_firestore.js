// =============================================================================
// Firestore seed script (firebase-admin SDK — bypasses security rules).
//
// Seeds every collection with one or more sample docs using the EXACT field
// names from lib/models/app_models.dart so you can verify the schema against
// the ER diagram in the Firebase console.
//
// Usage:
//   1. Console -> Project settings (gear) -> Service accounts ->
//      Generate new private key -> save as service-account.json in this folder
//   2. npm install firebase-admin
//   3. node scripts/seed_firestore.js
// =============================================================================

const admin = require('firebase-admin');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');
const path = require('path');

const serviceAccount = path.join(__dirname, '..', 'service-account.json');

admin.initializeApp({
  credential: admin.cert(serviceAccount),
});

const db = getFirestore();

const UID = 'demo_uid_001';

const now = Timestamp.now();

// ── 1. users ────────────────────────────────────────────────────────────────
async function seedUsers() {
  await db.collection('users').doc(UID).set({
    full_name: 'Taz Bin Wasis',
    email: 'tazbiswas734@gmail.com',
    department: 'CSE',
    semester: 5,
    profile_photo: null,
    created_at: now,
  });
}

// ── 2. expense_categories (catalog) ─────────────────────────────────────────
const EXPENSE_CATEGORIES = [
  ['food', 'Food', 5000],
  ['transport', 'Transport', 2000],
  ['tuition', 'Tuition Fees', 8000],
  ['books', 'Books & Supplies', 1500],
  ['hostel', 'Hostel Rent', 3000],
  ['mobile', 'Mobile Recharge', 800],
  ['internet', 'Internet', 1200],
  ['health', 'Health & Medical', 1000],
  ['entertainment', 'Entertainment', 500],
  ['other_expense', 'Other Expenses', 2000],
];

async function seedExpenseCategories() {
  const col = db.collection('expense_categories');
  const batch = db.batch();
  for (const [id, name, limit] of EXPENSE_CATEGORIES) {
    batch.set(col.doc(id), { category_name: name, monthly_limit: limit });
  }
  await batch.commit();
}

// ── 3. expenses ─────────────────────────────────────────────────────────────
async function seedExpenses() {
  const col = db.collection('expenses');
  const batch = db.batch();
  const rows = [
    { category_id: 'food', amount: 250, note: 'Lunch at cafeteria', date: new Date(2026, 7, 10) },
    { category_id: 'transport', amount: 120, note: 'CNG to campus', date: new Date(2026, 7, 12) },
    { category_id: 'books', amount: 850, note: 'DBMS reference book', date: new Date(2026, 7, 15) },
  ];
  rows.forEach((r, i) => {
    batch.set(col.doc(`exp_${i + 1}`), {
      user_id: UID,
      category_id: r.category_id,
      amount: r.amount,
      note: r.note,
      expense_date: Timestamp.fromDate(r.date),
    });
  });
  await batch.commit();
}

// ── 4. budgets ──────────────────────────────────────────────────────────────
async function seedBudgets() {
  await db.collection('budgets').doc('budget_2026_08').set({
    user_id: UID,
    month: '2026-08',
    total_budget: 15000,
    remaining_budget: 13780,
  });
}

// ── 5. courses ──────────────────────────────────────────────────────────────
async function seedCourses() {
  const col = db.collection('courses');
  const batch = db.batch();
  batch.set(col.doc('course_cse301'), {
    user_id: UID,
    course_title: 'Database Systems',
    course_code: 'CSE301',
    credit: 3,
    instructor: 'Dr. Rahman',
    attendance_percent: 87,
  });
  batch.set(col.doc('course_cse311'), {
    user_id: UID,
    course_title: 'Operating Systems',
    course_code: 'CSE311',
    credit: 3,
    instructor: 'Dr. Islam',
    attendance_percent: 74,
  });
  await batch.commit();
}

// ── 6. assignments ──────────────────────────────────────────────────────────
async function seedAssignments() {
  const col = db.collection('assignments');
  const batch = db.batch();
  batch.set(col.doc('assign_1'), {
    course_id: 'course_cse301',
    title: 'ER Diagram & Normalization Lab',
    due_date: Timestamp.fromDate(new Date(2026, 7, 20)),
    difficulty: 'hard',
    status: 'inProgress',
  });
  batch.set(col.doc('assign_2'), {
    course_id: 'course_cse311',
    title: 'Process Scheduling Report',
    due_date: Timestamp.fromDate(new Date(2026, 7, 25)),
    difficulty: 'medium',
    status: 'pending',
  });
  await batch.commit();
}

// ── 7. study_plans ──────────────────────────────────────────────────────────
async function seedStudyPlans() {
  await db.collection('study_plans').doc('plan_week_1').set({
    user_id: UID,
    generated_date: Timestamp.fromDate(new Date(2026, 7, 10)),
    total_hours: 18.5,
    status: 'active',
  });
}

// ── 8. study_sessions ───────────────────────────────────────────────────────
async function seedStudySessions() {
  const col = db.collection('study_sessions');
  const batch = db.batch();
  batch.set(col.doc('session_1'), {
    plan_id: 'plan_week_1',
    course_id: 'course_cse301',
    session_date: Timestamp.fromDate(new Date(2026, 7, 12, 9, 0)),
    duration_minutes: 90,
    priority: 'high',
    completed: true,
  });
  batch.set(col.doc('session_2'), {
    plan_id: 'plan_week_1',
    course_id: 'course_cse311',
    session_date: Timestamp.fromDate(new Date(2026, 7, 13, 15, 0)),
    duration_minutes: 60,
    priority: 'medium',
    completed: false,
  });
  await batch.commit();
}

// ── 9. habit_logs ───────────────────────────────────────────────────────────
async function seedHabitLogs() {
  const col = db.collection('habit_logs');
  const batch = db.batch();
  batch.set(col.doc('habit_1'), {
    user_id: UID,
    log_date: Timestamp.fromDate(new Date(2026, 7, 10)),
    sleep_hours: 7.2,
    exercise_minutes: 30,
    water_intake_liter: 2.5,
    screen_time_hours: 4.5,
  });
  batch.set(col.doc('habit_2'), {
    user_id: UID,
    log_date: Timestamp.fromDate(new Date(2026, 7, 11)),
    sleep_hours: 6.8,
    exercise_minutes: 45,
    water_intake_liter: 3.0,
    screen_time_hours: 5.2,
  });
  await batch.commit();
}

// ── 10. stress_predictions ──────────────────────────────────────────────────
async function seedStressPredictions() {
  await db.collection('stress_predictions').doc('stress_1').set({
    user_id: UID,
    score: 68,
    level: 'moderate',
    explanation: 'Moderate stress — exam week approaching.',
    predicted_at: now,
  });
}

// ── 11. ai_chats ────────────────────────────────────────────────────────────
async function seedAIChats() {
  await db.collection('ai_chats').doc('chat_1').set({
    user_id: UID,
    question: 'How should I plan my week?',
    response:
      'Start with high-priority subjects early in the day and revise at night.',
    created_at: now,
  });
}

// ── 12. notifications ───────────────────────────────────────────────────────
async function seedNotifications() {
  await db.collection('notifications').doc('notif_1').set({
    user_id: UID,
    title: 'Assignment due soon',
    message: 'ER Diagram & Normalization Lab is due in 3 days.',
    type: 'reminder',
    is_read: false,
    created_at: now,
  });
}

// ── 13. daily_checkins ──────────────────────────────────────────────────────
async function seedDailyCheckins() {
  await db.collection('daily_checkins').doc('checkin_1').set({
    user_id: UID,
    checkin_date: Timestamp.fromDate(new Date(2026, 7, 11)),
    day_number: 4,
    reward_points: 40,
    completed: true,
  });
}

// ── 14. achievements (catalog) ──────────────────────────────────────────────
const ACHIEVEMENTS = [
  ['ach_1', 'First Check-In', 'Check in for the first time', 10],
  ['ach_2', '7 Day Streak', 'Check in 7 days in a row', 50],
  ['ach_3', '30 Day Streak', 'Check in 30 days in a row', 200],
  ['ach_4', 'Study Master', 'Complete 10 study sessions', 100],
  ['ach_5', 'Budget Keeper', 'Stay within budget for a month', 150],
];

async function seedAchievements() {
  const col = db.collection('achievements');
  const batch = db.batch();
  for (const [id, name, desc, points] of ACHIEVEMENTS) {
    batch.set(col.doc(id), {
      badge_name: name,
      description: desc,
      reward_points: points,
    });
  }
  await batch.commit();
}

// ── 15. user_achievements ───────────────────────────────────────────────────
async function seedUserAchievements() {
  await db.collection('user_achievements').doc('ua_1').set({
    user_id: UID,
    achievement_id: 'ach_1',
    earned_date: now,
  });
}

// ── 16. course_catalog (global CSE syllabus — no user_id needed) ─────────────
async function seedCourseCatalog() {
  const col = db.collection('course_catalog');
  // Check if already seeded
  const existing = await col.limit(1).get();
  if (!existing.empty) {
    console.log('  (course_catalog already seeded — skipping)');
    return;
  }

  const courses = [
    // Level-1, Term-1
    { code: 'CSE-101', name: 'Discrete Mathematics', credit: 3.00, level: 1, term: 1, type: 'Theory', isElective: false, electiveGroup: null },
    { code: 'CHEM-101', name: 'Fundamentals of Chemistry', credit: 3.00, level: 1, term: 1, type: 'Theory', isElective: false, electiveGroup: null },
    { code: 'CHEM-102', name: 'Chemistry Sessional', credit: 1.50, level: 1, term: 1, type: 'Sessional', isElective: false, electiveGroup: null },
    { code: 'EECE-163', name: 'Electrical Circuit Analysis', credit: 3.00, level: 1, term: 1, type: 'Theory', isElective: false, electiveGroup: null },
    { code: 'EECE-164', name: 'Electrical Circuit Analysis Sessional', credit: 0.75, level: 1, term: 1, type: 'Sessional', isElective: false, electiveGroup: null },
    { code: 'GEBS-101', name: 'Bangladesh Studies', credit: 2.00, level: 1, term: 1, type: 'Theory', isElective: false, electiveGroup: null },
    { code: 'MATH-101', name: 'Differential and Integral Calculus', credit: 3.00, level: 1, term: 1, type: 'Theory', isElective: false, electiveGroup: null },
    { code: 'PHY-101', name: 'Waves and Oscillations, Optics and Modern Physics', credit: 3.00, level: 1, term: 1, type: 'Theory', isElective: false, electiveGroup: null },
    { code: 'PHY-102', name: 'Physics Sessional', credit: 1.50, level: 1, term: 1, type: 'Sessional', isElective: false, electiveGroup: null },
    // Level-1, Term-2
    { code: 'CSE-103', name: 'Digital Logic Design', credit: 3.00, level: 1, term: 2, type: 'Theory', isElective: false, electiveGroup: null },
    { code: 'CSE-104', name: 'Digital Logic Design Sessional', credit: 1.50, level: 1, term: 2, type: 'Sessional', isElective: false, electiveGroup: null },
    { code: 'CSE-105', name: 'Structured Programming Language', credit: 3.00, level: 1, term: 2, type: 'Theory', isElective: false, electiveGroup: null },
    { code: 'CSE-106', name: 'Structured Programming Language Sessional', credit: 1.50, level: 1, term: 2, type: 'Sessional', isElective: false, electiveGroup: null },
    { code: 'EECE-169', name: 'Electronic Devices and Circuits', credit: 3.00, level: 1, term: 2, type: 'Theory', isElective: false, electiveGroup: null },
    { code: 'EECE-170', name: 'Electronic Devices and Circuits Sessional', credit: 0.75, level: 1, term: 2, type: 'Sessional', isElective: false, electiveGroup: null },
    { code: 'ENG-102', name: 'Communicative English-I', credit: 1.50, level: 1, term: 2, type: 'Sessional', isElective: false, electiveGroup: null },
    { code: 'MATH-105', name: 'Vector Analysis, Matrix and Coordinate Geometry', credit: 3.00, level: 1, term: 2, type: 'Theory', isElective: false, electiveGroup: null },
    { code: 'ME-122', name: 'Fundamental of Mechanical Engineering Sessional', credit: 2.00, level: 1, term: 2, type: 'Sessional', isElective: false, electiveGroup: null },
    // Level-2, Term-1
    { code: 'CSE-203', name: 'Data Structures and Algorithms-I', credit: 3.00, level: 2, term: 1, type: 'Theory', isElective: false, electiveGroup: null },
    { code: 'CSE-204', name: 'Data Structures and Algorithms-I Sessional', credit: 1.50, level: 2, term: 1, type: 'Sessional', isElective: false, electiveGroup: null },
    { code: 'CSE-205', name: 'Object Oriented Programming Language', credit: 3.00, level: 2, term: 1, type: 'Theory', isElective: false, electiveGroup: null },
    { code: 'CSE-206', name: 'Object Oriented Programming Language Sessional-I', credit: 1.50, level: 2, term: 1, type: 'Sessional', isElective: false, electiveGroup: null },
    { code: 'CSE-217', name: 'Theory of Computation', credit: 3.00, level: 2, term: 1, type: 'Theory', isElective: false, electiveGroup: null },
    { code: 'EECE-269', name: 'Electrical Drives and Instrumentation', credit: 3.00, level: 2, term: 1, type: 'Theory', isElective: false, electiveGroup: null },
    { code: 'EECE-270', name: 'Electrical Drives and Instrumentation Sessional', credit: 0.75, level: 2, term: 1, type: 'Sessional', isElective: false, electiveGroup: null },
    { code: 'ENG-202', name: 'Communicative English-II', credit: 1.50, level: 2, term: 1, type: 'Sessional', isElective: false, electiveGroup: null },
    { code: 'MATH-205', name: 'Differential Equations, Laplace Transform and Fourier Transform', credit: 3.00, level: 2, term: 1, type: 'Theory', isElective: false, electiveGroup: null },
    // Level-2, Term-2
    { code: 'CE-250', name: 'Engineering Drawing and CAD Sessional', credit: 1.50, level: 2, term: 2, type: 'Sessional', isElective: false, electiveGroup: null },
    { code: 'CSE-213', name: 'Computer Architecture', credit: 3.00, level: 2, term: 2, type: 'Theory', isElective: false, electiveGroup: null },
    { code: 'CSE-215', name: 'Data Structures and Algorithms-II', credit: 3.00, level: 2, term: 2, type: 'Theory', isElective: false, electiveGroup: null },
    { code: 'CSE-216', name: 'Data Structures and Algorithms-II Sessional', credit: 1.50, level: 2, term: 2, type: 'Sessional', isElective: false, electiveGroup: null },
    { code: 'CSE-219', name: 'Mathematical Analysis for Computer Science', credit: 3.00, level: 2, term: 2, type: 'Theory', isElective: false, electiveGroup: null },
    { code: 'CSE-220', name: 'Object Oriented Programming Sessional-II', credit: 0.75, level: 2, term: 2, type: 'Sessional', isElective: false, electiveGroup: null },
    { code: 'EECE-279', name: 'Digital Electronics and Pulse Technique', credit: 3.00, level: 2, term: 2, type: 'Theory', isElective: false, electiveGroup: null },
    { code: 'EECE-280', name: 'Digital Electronics and Pulse Technique Sessional', credit: 0.75, level: 2, term: 2, type: 'Sessional', isElective: false, electiveGroup: null },
    { code: 'GELM-275', name: 'Leadership and Management', credit: 2.00, level: 2, term: 2, type: 'Theory', isElective: false, electiveGroup: null },
    { code: 'MATH-207', name: 'Complex Variable and Statistics', credit: 3.00, level: 2, term: 2, type: 'Theory', isElective: false, electiveGroup: null },
    // Level-3, Term-1
    { code: 'CSE-301', name: 'Database Management Systems', credit: 3.00, level: 3, term: 1, type: 'Theory', isElective: false, electiveGroup: null },
    { code: 'CSE-302', name: 'Database Management Systems Sessional', credit: 1.50, level: 3, term: 1, type: 'Sessional', isElective: false, electiveGroup: null },
    { code: 'CSE-303', name: 'Compiler', credit: 3.00, level: 3, term: 1, type: 'Theory', isElective: false, electiveGroup: null },
    { code: 'CSE-304', name: 'Compiler Sessional', credit: 0.75, level: 3, term: 1, type: 'Sessional', isElective: false, electiveGroup: null },
    { code: 'CSE-305', name: 'Microprocessors, Micro-controllers and Assembly Language', credit: 3.00, level: 3, term: 1, type: 'Theory', isElective: false, electiveGroup: null },
    { code: 'CSE-306', name: 'Microprocessors, Micro-controllers and Assembly Language Sessional', credit: 1.50, level: 3, term: 1, type: 'Sessional', isElective: false, electiveGroup: null },
    { code: 'CSE-307', name: 'Operating System', credit: 3.00, level: 3, term: 1, type: 'Theory', isElective: false, electiveGroup: null },
    { code: 'CSE-308', name: 'Operating System Sessional', credit: 0.75, level: 3, term: 1, type: 'Sessional', isElective: false, electiveGroup: null },
    { code: 'CSE-317', name: 'Data Communication', credit: 3.00, level: 3, term: 1, type: 'Theory', isElective: false, electiveGroup: null },
    { code: 'CSE-318', name: 'Data Communication Sessional', credit: 0.75, level: 3, term: 1, type: 'Sessional', isElective: false, electiveGroup: null },
    // Level-3, Term-2
    { code: 'CSE-309', name: 'Computer Network', credit: 3.00, level: 3, term: 2, type: 'Theory', isElective: false, electiveGroup: null },
    { code: 'CSE-310', name: 'Computer Network Sessional', credit: 1.50, level: 3, term: 2, type: 'Sessional', isElective: false, electiveGroup: null },
    { code: 'CSE-315', name: 'Digital System Design', credit: 2.00, level: 3, term: 2, type: 'Theory', isElective: false, electiveGroup: null },
    { code: 'CSE-316', name: 'Digital System Design Sessional', credit: 0.75, level: 3, term: 2, type: 'Sessional', isElective: false, electiveGroup: null },
    { code: 'CSE-319', name: 'Software Engineering', credit: 3.00, level: 3, term: 2, type: 'Theory', isElective: false, electiveGroup: null },
    { code: 'CSE-320', name: 'Software Engineering Sessional', credit: 0.75, level: 3, term: 2, type: 'Sessional', isElective: false, electiveGroup: null },
    { code: 'CSE-364', name: 'Software Development Project - I', credit: 1.50, level: 3, term: 2, type: 'Sessional', isElective: false, electiveGroup: null },
    { code: 'GERM-352', name: 'Fundamentals of Research Methodology', credit: 2.00, level: 3, term: 2, type: 'Theory', isElective: false, electiveGroup: null },
    { code: 'GES-301', name: 'Fundamentals of Sociology', credit: 2.00, level: 3, term: 2, type: 'Theory', isElective: false, electiveGroup: null },
    { code: 'GESL-303', name: 'Environment, Sustainability and Law', credit: 2.00, level: 3, term: 2, type: 'Theory', isElective: false, electiveGroup: null },
    { code: 'CSE-350', name: 'Industrial Training', credit: 1.00, level: 3, term: 2, type: 'Sessional', isElective: false, electiveGroup: null },
    // Level-4, Term-1
    { code: 'CSE-400-T1', name: 'Final Year Research & Design Project', credit: 3.00, level: 4, term: 1, type: 'Sessional', isElective: false, electiveGroup: null },
    { code: 'CSE-405', name: 'Computer Interfacing', credit: 3.00, level: 4, term: 1, type: 'Theory', isElective: false, electiveGroup: null },
    { code: 'CSE-406', name: 'Computer Interfacing Sessional', credit: 0.75, level: 4, term: 1, type: 'Sessional', isElective: false, electiveGroup: null },
    { code: 'CSE-415', name: 'Human Computer Interaction', credit: 3.00, level: 4, term: 1, type: 'Theory', isElective: false, electiveGroup: null },
    { code: 'CSE-429', name: 'Computer Security', credit: 3.00, level: 4, term: 1, type: 'Theory', isElective: false, electiveGroup: null },
    { code: 'CSE-464', name: 'Software Development Project-II', credit: 1.50, level: 4, term: 1, type: 'Sessional', isElective: false, electiveGroup: null },
    { code: 'GEEM-433', name: 'Engineering Ethics and Moral Philosophy', credit: 2.00, level: 4, term: 1, type: 'Theory', isElective: false, electiveGroup: null },
    // Level-4, Term-1 Technical Elective-I
    { code: 'CSE-407', name: 'Applied Statistics and Queuing Theory', credit: 3.00, level: 4, term: 1, type: 'Theory', isElective: true, electiveGroup: 'Technical Elective-I' },
    { code: 'CSE-417', name: 'Blockchaining and Cryptocurrency Technology', credit: 3.00, level: 4, term: 1, type: 'Theory', isElective: true, electiveGroup: 'Technical Elective-I' },
    { code: 'CSE-419', name: 'Advanced Algorithms', credit: 3.00, level: 4, term: 1, type: 'Theory', isElective: true, electiveGroup: 'Technical Elective-I' },
    { code: 'CSE-421', name: 'Basic Graph Theory', credit: 3.00, level: 4, term: 1, type: 'Theory', isElective: true, electiveGroup: 'Technical Elective-I' },
    { code: 'CSE-423', name: 'Fault Tolerance System', credit: 3.00, level: 4, term: 1, type: 'Theory', isElective: true, electiveGroup: 'Technical Elective-I' },
    { code: 'CSE-425', name: 'Basic Multimedia Theory', credit: 3.00, level: 4, term: 1, type: 'Theory', isElective: true, electiveGroup: 'Technical Elective-I' },
    { code: 'CSE-427', name: 'Digital Image Processing', credit: 3.00, level: 4, term: 1, type: 'Theory', isElective: true, electiveGroup: 'Technical Elective-I' },
    { code: 'CSE-431', name: 'Object Oriented Software Engineering', credit: 3.00, level: 4, term: 1, type: 'Theory', isElective: true, electiveGroup: 'Technical Elective-I' },
    { code: 'CSE-433', name: 'Artificial Neural Networks and Fuzzy Systems', credit: 3.00, level: 4, term: 1, type: 'Theory', isElective: true, electiveGroup: 'Technical Elective-I' },
    { code: 'CSE-435', name: 'Distributed Algorithms', credit: 3.00, level: 4, term: 1, type: 'Theory', isElective: true, electiveGroup: 'Technical Elective-I' },
    { code: 'CSE-437', name: 'Bioinformatics', credit: 3.00, level: 4, term: 1, type: 'Theory', isElective: true, electiveGroup: 'Technical Elective-I' },
    { code: 'CSE-439', name: 'Robotics', credit: 3.00, level: 4, term: 1, type: 'Theory', isElective: true, electiveGroup: 'Technical Elective-I' },
    { code: 'CSE-447', name: 'Telecommunication Engineering', credit: 3.00, level: 4, term: 1, type: 'Theory', isElective: true, electiveGroup: 'Technical Elective-I' },
    // Level-4, Term-2
    { code: 'CSE-400-T2', name: 'Final Year Research & Design Project', credit: 3.00, level: 4, term: 2, type: 'Sessional', isElective: false, electiveGroup: null },
    { code: 'CSE-401', name: 'Information System Design and Development', credit: 3.00, level: 4, term: 2, type: 'Theory', isElective: false, electiveGroup: null },
    { code: 'CSE-403', name: 'Artificial Intelligence', credit: 3.00, level: 4, term: 2, type: 'Theory', isElective: false, electiveGroup: null },
    { code: 'CSE-404', name: 'Artificial Intelligence Sessional', credit: 0.75, level: 4, term: 2, type: 'Sessional', isElective: false, electiveGroup: null },
    { code: 'CSE-413', name: 'Computer Graphics', credit: 3.00, level: 4, term: 2, type: 'Theory', isElective: false, electiveGroup: null },
    { code: 'CSE-414', name: 'Computer Graphics Sessional', credit: 0.75, level: 4, term: 2, type: 'Sessional', isElective: false, electiveGroup: null },
    { code: 'GEPM-463', name: 'Project Management and Finance', credit: 2.00, level: 4, term: 2, type: 'Theory', isElective: false, electiveGroup: null },
    // Level-4, Term-2 Technical Elective-II
    { code: 'CSE-411', name: 'VLSI Design', credit: 3.00, level: 4, term: 2, type: 'Theory', isElective: true, electiveGroup: 'Technical Elective-II' },
    { code: 'CSE-412', name: 'VLSI Design Sessional', credit: 0.75, level: 4, term: 2, type: 'Sessional', isElective: true, electiveGroup: 'Technical Elective-II' },
    { code: 'CSE-441', name: 'Machine Learning', credit: 3.00, level: 4, term: 2, type: 'Theory', isElective: true, electiveGroup: 'Technical Elective-II' },
    { code: 'CSE-442', name: 'Machine Learning Sessional', credit: 0.75, level: 4, term: 2, type: 'Sessional', isElective: true, electiveGroup: 'Technical Elective-II' },
    { code: 'CSE-443', name: 'Pattern Recognition', credit: 3.00, level: 4, term: 2, type: 'Theory', isElective: true, electiveGroup: 'Technical Elective-II' },
    { code: 'CSE-444', name: 'Pattern Recognition Sessional', credit: 0.75, level: 4, term: 2, type: 'Sessional', isElective: true, electiveGroup: 'Technical Elective-II' },
    { code: 'CSE-445', name: 'Digital Signal Processing', credit: 3.00, level: 4, term: 2, type: 'Theory', isElective: true, electiveGroup: 'Technical Elective-II' },
    { code: 'CSE-446', name: 'Digital Signal Processing Sessional', credit: 0.75, level: 4, term: 2, type: 'Sessional', isElective: true, electiveGroup: 'Technical Elective-II' },
    { code: 'CSE-449', name: 'Mobile and Ubiquitous Computing', credit: 3.00, level: 4, term: 2, type: 'Theory', isElective: true, electiveGroup: 'Technical Elective-II' },
    { code: 'CSE-450', name: 'Mobile and Ubiquitous Computing Sessional', credit: 0.75, level: 4, term: 2, type: 'Sessional', isElective: true, electiveGroup: 'Technical Elective-II' },
    { code: 'CSE-451', name: 'Simulation and Modeling', credit: 3.00, level: 4, term: 2, type: 'Theory', isElective: true, electiveGroup: 'Technical Elective-II' },
    { code: 'CSE-452', name: 'Simulation and Modeling Sessional', credit: 0.75, level: 4, term: 2, type: 'Sessional', isElective: true, electiveGroup: 'Technical Elective-II' },
    { code: 'CSE-455', name: 'Natural Language Processing', credit: 3.00, level: 4, term: 2, type: 'Theory', isElective: true, electiveGroup: 'Technical Elective-II' },
    { code: 'CSE-456', name: 'Natural Language Processing Sessional', credit: 0.75, level: 4, term: 2, type: 'Sessional', isElective: true, electiveGroup: 'Technical Elective-II' },
    { code: 'CSE-457', name: 'Advanced Database Management Systems', credit: 3.00, level: 4, term: 2, type: 'Theory', isElective: true, electiveGroup: 'Technical Elective-II' },
    { code: 'CSE-458', name: 'Advanced Database Management Systems Sessional', credit: 0.75, level: 4, term: 2, type: 'Sessional', isElective: true, electiveGroup: 'Technical Elective-II' },
    { code: 'CSE-459', name: 'Internet of Things (IoT)', credit: 3.00, level: 4, term: 2, type: 'Theory', isElective: true, electiveGroup: 'Technical Elective-II' },
    { code: 'CSE-460', name: 'Internet of Things (IoT) Sessional', credit: 0.75, level: 4, term: 2, type: 'Sessional', isElective: true, electiveGroup: 'Technical Elective-II' },
    { code: 'CSE-461', name: 'Industrial Revolution', credit: 3.00, level: 4, term: 2, type: 'Theory', isElective: true, electiveGroup: 'Technical Elective-II' },
    { code: 'CSE-462', name: 'Industrial Revolution Sessional', credit: 0.75, level: 4, term: 2, type: 'Sessional', isElective: true, electiveGroup: 'Technical Elective-II' },
    { code: 'CSE-465', name: 'Cyber & Physical Security', credit: 3.00, level: 4, term: 2, type: 'Theory', isElective: true, electiveGroup: 'Technical Elective-II' },
    { code: 'CSE-466', name: 'Cyber & Physical Security Sessional', credit: 0.75, level: 4, term: 2, type: 'Sessional', isElective: true, electiveGroup: 'Technical Elective-II' },
  ];

  // Firestore batch can handle max 500 writes; split if needed
  const BATCH_SIZE = 400;
  for (let i = 0; i < courses.length; i += BATCH_SIZE) {
    const batch = db.batch();
    const chunk = courses.slice(i, i + BATCH_SIZE);
    for (const course of chunk) {
      batch.set(col.doc(course.code), course);
    }
    await batch.commit();
    console.log(`  Wrote courses ${i + 1}–${Math.min(i + BATCH_SIZE, courses.length)}`);
  }
}

// ── Run all ─────────────────────────────────────────────────────────────────
async function main() {
  const steps = [
    ['users', seedUsers],
    ['expense_categories', seedExpenseCategories],
    ['expenses', seedExpenses],
    ['budgets', seedBudgets],
    ['courses', seedCourses],
    ['assignments', seedAssignments],
    ['study_plans', seedStudyPlans],
    ['study_sessions', seedStudySessions],
    ['habit_logs', seedHabitLogs],
    ['stress_predictions', seedStressPredictions],
    ['ai_chats', seedAIChats],
    ['notifications', seedNotifications],
    ['daily_checkins', seedDailyCheckins],
    ['achievements', seedAchievements],
    ['user_achievements', seedUserAchievements],
    ['course_catalog', seedCourseCatalog],
  ];

  for (const [name, fn] of steps) {
    await fn();
    console.log(`+ ${name} seeded`);
  }
  console.log('\nDone. All collections are now visible in the console:');
  console.log('https://console.firebase.google.com/project/campustwin-2a63e/firestore');
  process.exit(0);
}

main().catch((e) => {
  console.error('Seed failed:', e.message);
  process.exit(1);
});
