# Firestore layer — setup notes

## 1. `pubspec.yaml`
```yaml
dependencies:
  cloud_firestore: ^5.4.0
  firebase_auth: ^5.3.0   # if not already added — user_id everywhere == auth.uid
```
Run `flutter pub get` after adding.

## 2. Collections created (match the ER diagram, snake_case, plural)
`users`, `expense_categories`, `expenses`, `budgets`, `courses`, `assignments`,
`study_plans`, `study_sessions`, `habit_logs`, `stress_predictions`, `ai_chats`,
`notifications`, `daily_checkins`, `achievements`, `user_achievements`.

`users/{uid}` — the document id **is** the Firebase Auth `uid`. No password
field is stored in Firestore; Firebase Auth already owns credentials.

## 3. Files added
- `lib/models/app_models.dart` — one class per entity, `fromMap`/`toMap`.
- `lib/repositories/base_repository.dart` — generic `FirestoreRepository<T>`
  (get/create/set/update/delete/fetchByUser/watchByUser).
- `lib/repositories/app_repositories.dart` — one repository per collection,
  extending the base, plus entity-specific queries (e.g.
  `ExpenseRepository.fetchForMonth`, `HabitLogRepository.fetchRecent`).
- `firestore.rules` — ownership rules (`user_id == request.auth.uid`).
  Deploy with `firebase deploy --only firestore:rules`.

## 4. Composite indexes you'll need
Firestore will throw a link to auto-create these the first time each query
runs, but for a clean deploy add them to `firestore.indexes.json` ahead of
time:
- `expenses`: `user_id` ASC, `expense_date` ASC
- `assignments`: `course_id` ASC, `due_date` ASC
- `study_sessions`: `plan_id` ASC, `session_date` ASC
- `habit_logs`: `user_id` ASC, `log_date` DESC
- `stress_predictions`: `user_id` ASC, `predicted_at` DESC
- `ai_chats`: `user_id` ASC, `created_at` ASC
- `notifications`: `user_id` ASC, `is_read` ASC, `created_at` DESC
- `daily_checkins`: `user_id` ASC, `checkin_date` ASC

## 5. Usage example
```dart
final expenseRepo = ExpenseRepository();
final uid = FirebaseAuth.instance.currentUser!.uid;

// create
await expenseRepo.create(Expense(
  id: '',
  userId: uid,
  categoryId: someCategoryId,
  amount: 250,
  note: 'Lunch',
  expenseDate: DateTime.now(),
));

// live list for a screen
StreamBuilder<List<Expense>>(
  stream: expenseRepo.watchByUser(uid, orderBy: 'expense_date', descending: true),
  builder: (context, snap) { ... },
);
```

## 6. Not wired in yet — flag if you want these next
- `AuthRepository` (signUp/signIn/signOut wrapping `firebase_auth` +
  `UserRepository.createProfile`).
- Wiring the existing mock pages (`PlannerPage`, `HabitTrackerPage`,
  budget/course pages if any) to these repositories instead of the
  in-memory mocks.
- A Cloud Function to update `Budget.remaining_budget` when an `Expense`
  is created/deleted (keeping it in sync server-side rather than trusting
  the client).
- Cloud Functions for `assignments`/`study_sessions` writes (rules above
  currently block client writes to these — see comments in `firestore.rules`).
