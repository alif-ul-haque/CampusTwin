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
  ];

  for (const [name, fn] of steps) {
    await fn();
    console.log(`+ ${name} seeded`);
  }
  console.log('\nDone. All 15 collections are now visible in the console:');
  console.log('https://console.firebase.google.com/project/campustwin-2a63e/firestore');
  process.exit(0);
}

main().catch((e) => {
  console.error('Seed failed:', e.message);
  process.exit(1);
});
