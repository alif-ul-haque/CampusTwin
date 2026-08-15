import 'app_settings.dart';

/// Lightweight localization. Reads the active locale from [AppSettings]
/// and returns the English or Bengali translation for each key.
class AppStrings {
  AppStrings._();

  static bool get _isBn => AppSettings.instance.locale.languageCode == 'bn';
  static String _t(String en, String bn) => _isBn ? bn : en;

  // ── Navigation ─────────────────────────────────────────────────────────
  static String get tabHome => _t('Home', 'হোম');
  static String get tabPlanner => _t('Planner', 'পরিকল্পনা');
  static String get tabHabits => _t('Habits', 'অভ্যাস');
  static String get tabBudget => _t('Budget', 'বাজেট');
  static String get tabAssistant => _t('Assistant', 'সহকারী');

  // ── Greeting ───────────────────────────────────────────────────────────
  static String get goodMorning => _t('Good morning', 'শুভ সকাল');
  static String get goodAfternoon => _t('Good afternoon', 'শুভ অপরাহ্ন');
  static String get goodEvening => _t('Good evening', 'শুভ সন্ধ্যা');

  // ── Settings ───────────────────────────────────────────────────────────
  static String get settings => _t('Settings', 'সেটিংস');
  static String get appTheme => _t('App Theme', 'অ্যাপ থিম');
  static String get notifications => _t('Notifications', 'নোটিফিকেশন');
  static String get language => _t('Language', 'ভাষা');
  static String get signOut => _t('Sign Out', 'সাইন আউট');
  static String get light => _t('Light', 'লাইট');
  static String get dark => _t('Dark', 'ডার্ক');
  static String get system => _t('System', 'সিস্টেম');
  static String get english => _t('English', 'ইংরেজি');  static String get bengali => _t('Bengali', 'বাংলা');
  static String get on => _t('On', 'চালু');
  static String get off => _t('Off', 'বন্ধ');

  // ── Profile ────────────────────────────────────────────────────────────
  static String get profile => _t('Profile', 'প্রোফাইল');
  static String get editProfile => _t('Edit Profile', 'প্রোফাইল সম্পাদনা');
  static String get changePhoto => _t('Change Photo', 'ছবি পরিবর্তন');
  static String get chooseFromGallery =>
      _t('Choose from Gallery', 'গ্যালারি থেকে বেছে নিন');
  static String get choosePreset =>
      _t('Choose a preset avatar', 'প্রিসেট অ্যাভাটার বেছে নিন');
  static String get save => _t('Save', 'সংরক্ষণ');
  static String get cancel => _t('Cancel', 'বাতিল');
  static String get department => _t('Department', 'বিভাগ');
  static String get semester => _t('Semester', 'সেমিস্টার');
  static String get studentId => _t('Student ID', 'স্টুডেন্ট আইডি');
  static String get phone => _t('Phone', 'ফোন');
  static String get notSet => _t('Not set', 'সেট করা হয়নি');
  static String get enrolledCourses =>
      _t('Enrolled Courses', 'নিবন্ধিত কোর্স');
  static String get subjects => _t('subjects', 'বিষয়');
  static String get viewInPlanner =>
      _t('View in Planner', 'পরিকল্পনায় দেখুন');
  static String get quickAccess => _t('Quick Access', 'দ্রুত অ্যাক্সেস');
  static String get name => _t('Full Name', 'পুরো নাম');
  static String get nickname => _t('Nickname', 'ডাক নাম');
  static String get email => _t('Email', 'ইমেইল');

  // ── Notifications page ─────────────────────────────────────────────────
  static String get notificationCenter =>
      _t('Notifications', 'নোটিফিকেশন');
  static String get markAllRead =>
      _t('Mark all as read', 'সব পড়া হয়েছে');
  static String get notificationsOffTitle =>
      _t('Notifications are off', 'নোটিফিকেশন বন্ধ আছে');
  static String get notificationsOffBody =>
      _t('Turn them on to get deadline, streak and budget alerts.',
          'সময়সীমা, স্ট্রিক ও বাজেট সতর্কতা পেতে চালু করুন।');
  static String get noNotifications =>
      _t('You\'re all caught up!', 'সব পড়ে ফেলেছেন!');

  // ── Common quick links ─────────────────────────────────────────────────
  static String get habitTracker =>
      _t('Habit Tracker', 'অভ্যাস ট্র্যাকার');
  static String get checkTodayProgress =>
      _t('Check today\'s progress', 'আজকের অগ্রগতি দেখুন');
  static String get expenseManager =>
      _t('Expense Manager', 'ব্যয় ব্যবস্থাপক');
  static String get viewBudget =>
      _t('View budget & spending', 'বাজেট ও ব্যয় দেখুন');
  static String get leaderboard => _t('Leaderboard', 'লিডারবোর্ড');
  static String get seeRankings =>
      _t('See class-wide rankings', 'শ্রেণি র‍্যাংকিং দেখুন');
  static String get appBlocker => _t('App Blocker', 'অ্যাপ ব্লকার');
  static String get blockApps =>
      _t('Block distracting apps', 'বিক্ষেপী অ্যাপ ব্লক করুন');
  static String get twinDashboard => _t('Twin Dashboard', 'টুইন ড্যাশবোর্ড');
  static String get backHome =>
      _t('Back to home overview', 'হোমে ফিরে যান');
  static String get saved => _t('Profile updated', 'প্রোফাইল আপডেট হয়েছে');
  static String get stressLow => _t('Low', 'কম');
  static String get stressMedium => _t('Medium', 'মাঝারি');
  static String get stressHigh => _t('High', 'উচ্চ');
  static String get todaySchedule =>
      _t('Today\'s Schedule', 'আজকের রুটিন');
  static String get upcomingDeadlines =>
      _t('Upcoming Deadlines', 'আসন্ন ডেডলাইন');
  static String get ranking => _t('Ranking', 'র‍্যাংকিং');
  static String get streak => _t('Streak', 'স্ট্রিক');
  static String get budgetLeft => _t('Budget Left', 'অবশিষ্ট বাজেট');
  static String get days => _t('days', 'দিন');

  // ── Weekdays & months ──────────────────────────────────────────────────
  static String get wdMon => _t('Mon', 'সোম');
  static String get wdTue => _t('Tue', 'মঙ্গল');
  static String get wdWed => _t('Wed', 'বুধ');
  static String get wdThu => _t('Thu', 'বৃহস্পতি');
  static String get wdFri => _t('Fri', 'শুক্র');
  static String get wdSat => _t('Sat', 'শনি');
  static String get wdSun => _t('Sun', 'রবি');

  static String get wdMonday => _t('Monday', 'সোমবার');
  static String get wdTuesday => _t('Tuesday', 'মঙ্গলবার');
  static String get wdWednesday => _t('Wednesday', 'বুধবার');
  static String get wdThursday => _t('Thursday', 'বৃহস্পতিবার');
  static String get wdFriday => _t('Friday', 'শুক্রবার');
  static String get wdSaturday => _t('Saturday', 'শনিবার');
  static String get wdSunday => _t('Sunday', 'রবিবার');

  static String get mnJan => _t('Jan', 'জানু');
  static String get mnFeb => _t('Feb', 'ফেব্রু');
  static String get mnMar => _t('Mar', 'মার্চ');
  static String get mnApr => _t('Apr', 'এপ্রি');
  static String get mnMay => _t('May', 'মে');
  static String get mnJun => _t('Jun', 'জুন');
  static String get mnJul => _t('Jul', 'জুলা');
  static String get mnAug => _t('Aug', 'আগ');
  static String get mnSep => _t('Sep', 'সেপ্টে');
  static String get mnOct => _t('Oct', 'অক্টো');
  static String get mnNov => _t('Nov', 'নভে');
  static String get mnDec => _t('Dec', 'ডিসে');

  static String get mnJanuary => _t('January', 'জানুয়ারি');
  static String get mnFebruary => _t('February', 'ফেব্রুয়ারি');
  static String get mnMarch => _t('March', 'মার্চ');
  static String get mnApril => _t('April', 'এপ্রিল');
  static String get mnMayL => _t('May', 'মে');
  static String get mnJune => _t('June', 'জুন');
  static String get mnJuly => _t('July', 'জুলাই');
  static String get mnAugust => _t('August', 'আগস্ট');
  static String get mnSeptember => _t('September', 'সেপ্টেম্বর');
  static String get mnOctober => _t('October', 'অক্টোবর');
  static String get mnNovember => _t('November', 'নভেম্বর');
  static String get mnDecember => _t('December', 'ডিসেম্বর');

  // ── Planner page ───────────────────────────────────────────────────────
  static String get plannerTitle => _t('Study planner', 'স্টাডি প্ল্যানার');
  static String get plannerSubtitle =>
      _t('Plan clearly. Study consistently.', 'পরিষ্কার পরিকল্পনা, ধারাবাহিক পড়া।');
  static String get currentWeek => _t('Current week', 'বর্তমান সপ্তাহ');
  static String get previousWeek => _t('Previous week', 'আগের সপ্তাহ');
  static String get nextWeek => _t('Next week', 'পরের সপ্তাহ');
  static String get today => _t('Today', 'আজ');
  static String get weeklyProgress =>
      _t('Weekly progress', 'সাপ্তাহিক অগ্রগতি');
  static String get overviewEmpty =>
      _t('Add a task to start your week.', 'সপ্তাহ শুরু করতে একটি কাজ যোগ করুন।');
  static String tasksCompleted(int completed, int total) =>
      _t('$completed of $total tasks completed',
          '$totalটির মধ্যে $completedটি কাজ সম্পন্ন');
  static String get planned => _t('Planned', 'পরিকল্পিত');
  static String get completed => _t('Completed', 'সম্পন্ন');
  static String get remaining => _t('Remaining', 'অবশিষ্ট');
  static String get todaysPlan => _t('Today\'s plan', 'আজকের পরিকল্পনা');
  static String get readOnly => _t('Read-only', 'শুধু পড়া');
  static String get newTask => _t('New task', 'নতুন কাজ');
  static String get noTasksPlanned =>
      _t('No tasks planned', 'কোনো কাজ পরিকল্পনা করা হয়নি');
  static String get pastDateReadOnly =>
      _t('This date has passed and is now read-only.',
          'তারিখটি পেরিয়ে গেছে, এখন এটি কেবল পড়া যাবে।');
  static String get keepTimeFree =>
      _t('Keep this time free or add a focused study block.',
          'সময়টি ফাঁকা রাখুন বা একটি ফোকাসড স্টাডি ব্লক যোগ করুন।');
  static String get addTask => _t('Add a task', 'কাজ যোগ করুন');
  static String get courseFocus => _t('Course focus', 'কোর্স ফোকাস');
  static String plannedCaption(String hours) =>
      _t('$hours planned', '$hours ঘণ্টা পরিকল্পিত');
  static String get buildBalancedWeek =>
      _t('Build a balanced week', 'সুষম সপ্তাহ গঠন করুন');
  static String get pastWeekArchived =>
      _t('Past week archived', 'পেছনের সপ্তাহ সংরক্ষিত');
  static String get smartPlanReadOnlySub =>
      _t('Tasks in this week can be viewed but not changed.',
          'এই সপ্তাহের কাজ দেখা যাবে তবে পরিবর্তন করা যাবে না।');
  static String get smartPlanActiveSub =>
      _t('Fill free time without changing existing tasks.',
          'বিদ্যমান কাজ না বদলে ফাঁকা সময় পূরণ করুন।');
  static String get addStudyTask =>
      _t('Add study task', 'স্টাডি কাজ যোগ করুন');
  static String get close => _t('Close', 'বন্ধ');
  static String get taskTitle => _t('Task title', 'কাজের শিরোনাম');
  static String get taskUntitled => _t('Untitled task', 'নামহীন কাজ');
  static String get taskTitleHint =>
      _t('What do you want to accomplish?', 'আপনি কী অর্জন করতে চান?');
  static String get enterTaskTitle =>
      _t('Enter a task title.', 'কাজের শিরোনাম লিখুন।');
  static String get atLeast3Chars =>
      _t('Use at least 3 characters.', 'কমপক্ষে ৩টি অক্ষর ব্যবহার করুন।');
  static String get date => _t('Date', 'তারিখ');
  static String get starts => _t('Starts', 'শুরু');
  static String get ends => _t('Ends', 'শেষ');
  static String get taskType => _t('Task type', 'কাজের ধরন');
  static String get course => _t('Course', 'কোর্স');
  static String get generalNoCourse =>
      _t('General / no course', 'সাধারণ / কোনো কোর্স নেই');
  static String get notesOptional =>
      _t('Notes (optional)', 'নোট (ঐচ্ছিক)');
  static String get notesHint =>
      _t('Resources, goals, or reminders', 'রিসোর্স, লক্ষ্য বা স্মরণীয়');
  static String get addToPlanner =>
      _t('Add to planner', 'পরিকল্পনায় যোগ করুন');
  static String get addingTask => _t('Adding task…', 'কাজ যোগ হচ্ছে…');
  static String get markDone => _t('Mark done', 'সম্পন্ন চিহ্নিত');
  static String get markPending => _t('Mark pending', 'বাকি চিহ্নিত');
  static String get deleteTask => _t('Delete task', 'কাজ মুছুন');
  static String get delete => _t('Delete', 'মুছুন');
  static String get taskDeleted => _t('Task deleted.', 'কাজ মুছে ফেলা হয়েছে।');
  static String get couldNotDelete =>
      _t('Could not delete this task. Please try again.',
          'কাজটি মুছতে ব্যর্থ হয়েছে। আবার চেষ্টা করুন।');
  static String get couldNotUpdate =>
      _t('Could not update this task. Please try again.',
          'কাজটি আপডেট করা যায়নি। আবার চেষ্টা করুন।');
  static String get chooseTodayOrFuture =>
      _t('Choose today or a future date to add a task.',
          'কাজ যোগ করতে আজ বা ভবিষ্যতের তারিখ বেছে নিন।');
  static String get taskAdded =>
      _t('Task added to your planner.', 'আপনার পরিকল্পনায় কাজ যোগ হয়েছে।');
  static String get pastTasksReadOnly =>
      _t('Past tasks are read-only.', 'পেছনের কাজগুলো কেবল পড়া যায়।');
  static String get pastTasksReadOnlyDelete =>
      _t('Past tasks are read-only and cannot be deleted.',
          'পেছনের কাজগুলো কেবল পড়া যায়, মুছা যায় না।');
  static String get pastWeeksReadOnly =>
      _t('Past weeks are read-only.', 'পেছনের সপ্তাহগুলো কেবল পড়া যায়।');
  static String get deleteTaskQuestion =>
      _t('Delete task?', 'কাজটি মুছবেন?');
  static String deleteTaskBody(String title) =>
      _t('“$title” will be permanently removed.', '“$title” স্থায়ীভাবে মুছে যাবে।');
  static String get addSmartSuggestions =>
      _t('Add smart suggestions?', 'স্মার্ট পরামর্শ যোগ করবেন?');
  static String get smartSuggestionsBody =>
      _t('CampusTwin will fill available time only. Your existing tasks will stay unchanged.',
          'CampusTwin শুধু ফাঁকা সময় পূরণ করবে। আপনার বিদ্যমান কাজগুলো অপরিবর্তিত থাকবে।');
  static String get notNow => _t('Not now', 'এখন নয়');
  static String get addSuggestions => _t('Add suggestions', 'পরামর্শ যোগ করুন');
  static String get weekUpdated =>
      _t('Your week has been updated with available study blocks.',
          'আপনার সপ্তাহ উপলব্ধ স্টাডি ব্লক দিয়ে আপডেট হয়েছে।');
  static String get couldNotGenerate =>
      _t('Could not generate suggestions right now.',
          'এই মুহূর্তে পরামর্শ তৈরি করা যায়নি।');
  static String get plannerUnavailable =>
      _t('Planner unavailable', 'প্ল্যানার অনুপলব্ধ');
  static String get tryAgain => _t('Try again', 'আবার চেষ্টা করুন');
  static String get couldNotLoad =>
      _t('We could not load your planner. Check your connection and try again.',
          'আপনার প্ল্যানার লোড করা যায়নি। সংযোগ পরীক্ষা করে আবার চেষ্টা করুন।');
  static String get endTimeAfterStart =>
      _t('End time must be at least 5 minutes after start.',
          'শেষ সময় শুরুর কমপক্ষে ৫ মিনিট পরে হতে হবে।');
  static String get couldNotSaveTask =>
      _t('Could not save the task. Please try again.',
          'কাজটি সংরক্ষণ করা যায়নি। আবার চেষ্টা করুন।');

  // ── Planner task types ─────────────────────────────────────────────────
  static String get typeStudy => _t('Study', 'অধ্যয়ন');
  static String get typeAssignment => _t('Assignment', 'অ্যাসাইনমেন্ট');
  static String get typeRevision => _t('Revision', 'পুনরালোচনা');
  static String get typeClass => _t('Class', 'ক্লাস');
  static String get typeExamPrep => _t('Exam prep', 'পরীক্ষার প্রস্তুতি');

  // ── Planner mock subjects & tasks ──────────────────────────────────────
  static String get subDb => _t('Database Systems', 'ডেটাবেস সিস্টেম');
  static String get subDm => _t('Data Mining', 'ডেটা মাইনিং');
  static String get subMl => _t('Machine Learning', 'মেশিন লার্নিং');
  static String get subSe => _t('Software Engineering', 'সফটওয়্যার ইঞ্জিনিয়ারিং');
  static String get subCn => _t('Computer Networks', 'কম্পিউটার নেটওয়ার্ক');
  static String get mockTask1 =>
      _t('Review database normalization', 'ডেটাবেস নরমালাইজেশন রিভিউ');
  static String get mockTask1Note =>
      _t('Focus on 3NF and BCNF examples.', '৩এনএফ ও বিসিএনএফ উদাহরণে ফোকাস করুন।');
  static String get mockTask2 =>
      _t('Data mining practice', 'ডেটা মাইনিং অনুশীলন');
  static String get mockTask2Note =>
      _t('Complete two clustering problems.', 'দুটি ক্লাস্টারিং সমস্যা সমাধান করুন।');
  static String get mockTask3 =>
      _t('ML assignment sprint', 'এমএল অ্যাসাইনমেন্ট স্প্রিন্ট');
  static String get mockTask4 =>
      _t('Networks quiz preparation', 'নেটওয়ার্ক কুইজ প্রস্তুতি');
  static String get mockTask5 =>
      _t('Software project meeting', 'সফটওয়্যার প্রজেক্ট মিটিং');
  static String get mockTask6 =>
      _t('Weekly course review', 'সাপ্তাহিক কোর্স রিভিউ');
  static String get mockGenTask1 =>
      _t('Focused course review', 'ফোকাসড কোর্স রিভিউ');
  static String get mockGenTask2 =>
      _t('Practice and recall', 'অনুশীলন ও মনে রাখা');
  static String get mockGenNote =>
      _t('Suggested from your course load and available time.',
          'আপনার কোর্স লোড ও উপলব্ধ সময় থেকে পরামর্শ দেওয়া হয়েছে।');

  // ── Habits page ────────────────────────────────────────────────────────
  static String get habitPageTitle => _t('Habit Tracker', 'অভ্যাস ট্র্যাকার');
  static String get habitSubtitle =>
      _t('Small daily habits, a stronger you.', 'ছোট দৈনিক অভ্যাস, শক্তিশালী আপনি।');
  static String get yourHabits => _t('Your Habits', 'আপনার অভ্যাস');
  static String get habitStreaks => _t('Habit Streaks', 'অভ্যাস স্ট্রিক');
  static String get weeklyAnalytics => _t('Weekly Analytics', 'সাপ্তাহিক বিশ্লেষণ');
  static String get aiInsights => _t('AI Insights', 'এআই অন্তর্দৃষ্টি');
  static String get score => _t('Score', 'স্কোর');
  static String get todaysHabitSummary =>
      _t('Today\'s Habit Summary', 'আজকের অভ্যাস সারাংশ');
  static String get onTrackToday =>
      _t('Great job — you\'re on track today!', 'দারুণ কাজ — আজ আপনি ট্র্যাকে!');
  static String get keepStreakAlive =>
      _t('A little more effort keeps your streak alive.',
          'আরেকটু চেষ্টা আপনার স্ট্রিক ধরে রাখবে।');
  static String get habitSleep => _t('Sleep', 'ঘুম');
  static String get habitWater => _t('Water', 'পানি');
  static String get habitExercise => _t('Exercise', 'ব্যায়াম');
  static String get habitScreen => _t('Screen', 'স্ক্রিন');
  static String get habitWaterIntake =>
      _t('Water Intake', 'পানি গ্রহণ');
  static String get habitScreenTime =>
      _t('Screen Time', 'স্ক্রিন সময়');
  static String get hydration => _t('Hydration', 'পানি');
  static String logTitle(String name) =>
      _t('Log $name', 'লগ করুন $name');
  static String todaysValue(String unit) =>
      _t('Today\'s value ($unit)', 'আজকের মান ($unit)');
  static String egValue(String target) =>
      _t('e.g. $target', 'যেমন: $target');
  static String get saveEntry => _t('Save entry', 'এন্ট্রি সংরক্ষণ');
  static String checkedInStreak(int day) =>
      _t('Checked in! Day $day streak · +10 pts',
          'চেক-ইন সম্পন্ন! $day দিনের স্ট্রিক · +১০ পয়েন্ট');
  static String get onTrack => _t('On track', 'ট্র্যাকে আছে');
  static String get needsFocus => _t('Needs focus', 'ফোকাস প্রয়োজন');
  static String dailyGoal(int pct) =>
      _t('$pct% of daily goal', 'দৈনিক লক্ষ্যের $pct%');
  static String get dayStreak => _t('day streak', 'দিনের স্ট্রিক');
  static String thisWeekAvg(String avg, String unit) =>
      _t('This week · avg $avg $unit', 'এই সপ্তাহ · গড় $avg $unit');
  static String get metLabel => _t('met', 'পূরণ');
  static String get belowLabel => _t('below', 'নিচে');
  static String get dailyCheckIn => _t('Daily Check-In', 'দৈনিক চেক-ইন');
  static String checkedInDay(int day) =>
      _t('Checked in · Day $day', 'চেক-ইন · দিন $day');
  static String get checkedIn => _t('Checked in', 'চেক-ইন হয়েছে');
  static String get sleepInsightTag =>
      _t('Sleep pattern', 'ঘুমের ধরণ');
  static String get sleepInsight =>
      _t('You slept below 6 hours for 3 consecutive days. Try winding down 30 minutes earlier tonight.',
          'টানা ৩ দিন আপনি ৬ ঘণ্টার কম ঘুমিয়েছেন। আজ রাতে ৩০ মিনিট আগে ঘুমাতে যাওয়ার চেষ্টা করুন।');
  static String get screenInsightTag =>
      _t('Screen time', 'স্ক্রিন সময়');
  static String get screenInsight =>
      _t('Your screen time increased noticeably this week, especially around exam days.',
          'এই সপ্তাহে আপনার স্ক্রিন সময় উল্লেখযোগ্যভাবে বেড়েছে, বিশেষ করে পরীক্ষার দিনগুলোতে।');
  static String get stressInsightTag =>
      _t('Stress & exercise', 'চাপ ও ব্যায়াম');
  static String get stressInsight =>
      _t('Staying consistent with exercise this week helped lower your predicted stress score.',
          'এই সপ্তাহে নিয়মিত ব্যায়াম আপনার আনুমানিক মানসিক চাপ কমাতে সাহায্য করেছে।');

  // ── Budget page ────────────────────────────────────────────────────────
  static String get expenseAdded => _t('Expense added', 'ব্যয় যোগ হয়েছে');
  static String get incomeAdded => _t('Income added', 'আয় যোগ হয়েছে');
  static String get transactionDeleted =>
      _t('Transaction deleted', 'লেনদেন মুছে ফেলা হয়েছে');
  static String get statistics => _t('Statistics', 'পরিসংখ্যান');
  static String get income => _t('Income', 'আয়');
  static String get expense => _t('Expense', 'ব্যয়');
  static String get noIncomeYet => _t('No income yet', 'এখনো কোনো আয় নেই');
  static String spentPercent(int pct) =>
      _t('$pct% spent', '$pct% ব্যয় হয়েছে');
  static String get transactions => _t('Transactions', 'লেনদেন');
  static String get backToToday => _t('Back to today', 'আজকে ফিরুন');
  static String get nothingLogged =>
      _t('Nothing logged on this day.\nTap + to add an expense or income.',
          'এই দিনে কোনো লেনদেন নেই।\nব্যয় বা আয় যোগ করতে + চাপুন।');
  static String viewAllTransactions(int count) =>
      _t('View all $count transactions', 'সব $countটি লেনদেন দেখুন');
  static String get weekly => _t('Weekly', 'সাপ্তাহিক');
  static String get monthly => _t('Monthly', 'মাসিক');
  static String get yearly => _t('Yearly', 'বার্ষিক');
  static String get incomeVsExpense =>
      _t('Income vs Expense', 'আয় বনাম ব্যয়');
  static String incomeLegend(String amount) =>
      _t('Income $amount', 'আয় $amount');
  static String expenseLegend(String amount) =>
      _t('Expense $amount', 'ব্যয় $amount');
  static String youSaved(String amount) =>
      _t('You saved $amount in this period.',
          'এই সময়ে আপনি $amount সাশ্রয় করেছেন।');
  static String youOverspent(String amount) =>
      _t('You overspent by $amount in this period.',
          'এই সময়ে আপনি $amount বেশি ব্যয় করেছেন।');
  static String get byCategory => _t('By Category', 'বিভাগ অনুযায়ী');
  static String get noExpenses =>
      _t('No expenses in this period.', 'এই সময়ে কোনো ব্যয় নেই।');
  static String get noIncome =>
      _t('No income in this period.', 'এই সময়ে কোনো আয় নেই।');
  static String get spent => _t('spent', 'ব্যয় হয়েছে');
  static String get earned => _t('earned', 'আয় হয়েছে');
  static String get jumpToToday => _t('Jump to today', 'আজকে যান');
  static String get noNoteExpense => _t('Expense', 'ব্যয়');
  static String get noNoteIncome => _t('Income source', 'আয়ের উৎস');
  static String get nothingLeftOnDay =>
      _t('Nothing left on this day.', 'এই দিনে কিছুই নেই।');
  static String get whatToAdd =>
      _t('What do you want to add?', 'আপনি কী যোগ করতে চান?');
  static String get addTypeSubtitle =>
      _t('Track where your money goes and where it comes from.',
          'টাকা কোথায় খরচ হয় ও কোথা থেকে আসে তা ট্র্যাক করুন।');
  static String get expenseOption =>
      _t('Food, transport, fees…', 'খাবার, পরিবহন, ফি…');
  static String get incomeOption =>
      _t('Pocket money, tutoring…', 'পকেট মানি, টিউশনি…');
  static String get enterValidAmount =>
      _t('Enter a valid amount.', 'সঠিক পরিমাণ লিখুন।');
  static String get pickExpenseCategory =>
      _t('Pick an expense category.', 'একটি ব্যয় বিভাগ বেছে নিন।');
  static String get pickIncomeSource =>
      _t('Pick an income source.', 'একটি আয়ের উৎস বেছে নিন।');
  static String get addExpense => _t('Add Expense', 'ব্যয় যোগ করুন');
  static String get addIncome => _t('Add Income', 'আয় যোগ করুন');
  static String get amount => _t('Amount', 'পরিমাণ');
  static String get expenseCategory =>
      _t('Expense category', 'ব্যয় বিভাগ');
  static String get incomeSource =>
      _t('Income source', 'আয়ের উৎস');
  static String get noteOptional =>
      _t('Note (optional)', 'নোট (ঐচ্ছিক)');
  static String get noteHint =>
      _t('e.g. Canteen lunch with friends', 'যেমন: বন্ধুদের সাথে ক্যান্টিনে লাঞ্চ');
  static String get saveExpense => _t('Save Expense', 'ব্যয় সংরক্ষণ');
  static String get saveIncome => _t('Save Income', 'আয় সংরক্ষণ');
  static String get calendar => _t('Calendar', 'ক্যালেন্ডার');
  static String balanceCaption(String month, String year) =>
      _t('$month $year · balance', '$month $year · ব্যালেন্স');
  static String thisWeekCaption(String label) =>
      _t('This week · $label', 'এই সপ্তাহ · $label');
  static String yearCaption(String year) =>
      _t('Year $year', 'বছর $year');
  static String dayCount(int count) =>
      _t('$count transaction${count == 1 ? '' : 's'}', '$countটি লেনদেন');

  // ── Budget category labels ─────────────────────────────────────────────
  static String get catFood => _t('Food & Canteen', 'খাবার ও ক্যান্টিন');
  static String get catTransport => _t('Transport', 'পরিবহন');
  static String get catTuition => _t('Tuition Fee', 'টিউশন ফি');
  static String get catBooks => _t('Books & Notes', 'বই ও নোট');
  static String get catStationery => _t('Stationery', 'স্টেশনারি');
  static String get catPrint => _t('Print & Photocopy', 'প্রিন্ট ও ফটোকপি');
  static String get catRecharge => _t('Mobile Recharge', 'মোবাইল রিচার্জ');
  static String get catInternet => _t('Internet', 'ইন্টারনেট');
  static String get catHostel => _t('Hostel / Rent', 'হোস্টেল / ভাড়া');
  static String get catExamFee => _t('Exam Fee', 'পরীক্ষার ফি');
  static String get catClub => _t('Club & Society', 'ক্লাব ও সমিতি');
  static String get catHealth => _t('Health', 'স্বাস্থ্য');
  static String get catEntertainment => _t('Entertainment', 'বিনোদন');
  static String get catShopping => _t('Shopping', 'কেনাকাটা');
  static String get catPocketMoney => _t('Pocket Money', 'পকেট মানি');
  static String get catScholarship => _t('Scholarship', 'স্কলারশিপ');
  static String get catStipend => _t('Stipend', 'স্টাইপেন্ড');
  static String get catTutoring => _t('Tutoring', 'টিউশনি');
  static String get catPartTime => _t('Part-time Job', 'পার্ট-টাইম চাকরি');
  static String get catFreelancing => _t('Freelancing', 'ফ্রিল্যান্সিং');
  static String get catInternship => _t('Internship', 'ইন্টার্নশিপ');
  static String get catAward => _t('Prize / Award', 'পুরস্কার / সম্মাননা');
  static String get catGift => _t('Gift', 'উপহার');
  static String get catSavings => _t('Savings', 'সঞ্চয়');
  static String get catOther => _t('Other', 'অন্যান্য');

  // ── Assistant page ─────────────────────────────────────────────────────
  static String get assistantTitle =>
      _t('Twinny Assistant', 'টুইনি সহকারী');
  static String get assistantSubtitle =>
      _t('Ask me anything about your studies', 'আপনার পড়াশোনা নিয়ে যেকোনো প্রশ্ন করুন');
  static String get askTwinnyHint =>
      _t('Ask Twinny...', 'টুইনিকে প্রশ্ন করুন...');
  static String get askAnythingTitle =>
      _t('Ask Twinny anything!', 'টুইনিকে যেকোনো কিছু জিজ্ঞাসা করুন!');
  static String get askAnythingSubtitle =>
      _t('Study tips, deadline help, stress advice…',
          'স্টাডি টিপস, ডেডলাইন সাহায্য, চাপ নিয়ে পরামর্শ…');
  static String assistantGreeting(String name) =>
      _t('Hi $name! I\'m your Twinny assistant. How can I help you today?',
          'হাই $name! আমি আপনার টুইনি সহকারী। আজ কীভাবে সাহায্য করতে পারি?');  static String get assistantReply1 =>
      _t('Great question! Based on your upcoming deadlines, I\'d suggest focusing on your ML Assignment first — it\'s due tomorrow.',
          'দারুণ প্রশ্ন! আপনার আসন্ন ডেডলাইন অনুযায়ী আগে এমএল অ্যাসাইনমেন্টে ফোকাস করার পরামর্শ দিচ্ছি — কাল জমা দিতে হবে।');
  static String get assistantReply2 =>
      _t('I noticed your stress level is medium. A 15-minute break can help. Why not take a short walk?',
          'আমি লক্ষ্য করেছি আপনার মানসিক চাপ মাঝারি। ১৫ মিনিটের বিরতি সাহায্য করতে পারে। একটু হাঁটাহাঁটি করলে কেমন হয়?');
  static String get assistantReply3 =>
      _t('You\'re making good progress this week. Keep up the consistency!',
          'আপনি এই সপ্তাহে ভালো অগ্রগতি করছেন। ধারাবাহিকতা বজায় রাখুন!');
  static String get assistantReply4 =>
      _t('Good progress on Database Systems! You\'re at 72% of your weekly study target.',
          'ডেটাবেস সিস্টেমে ভালো অগ্রগতি! আপনি সাপ্তাহিক স্টাডি লক্ষ্যের ৭২% পৌঁছেছেন।');
  static String get assistantReply5 =>
      _t('Don\'t forget to review your study plan for tomorrow. I can help you reschedule if needed.',
          'আগামীকালের স্টাডি প্ল্যান রিভিউ করতে ভুলবেন না। দরকার হলে পুনঃনির্ধারণে সাহায্য করতে পারি।');

  // ── App Blocker page ───────────────────────────────────────────────────
  static String get selectAppFirst =>
      _t('Select at least one app to block first.',
          'প্রথমে অন্তত একটি অ্যাপ বেছে নিন।');
  static String get appBlockerTitle => _t('App Blocker', 'অ্যাপ ব্লকার');
  static String blockedCount(int count) =>
      _t('$count blocked', '$countটি ব্লক করা হয়েছে');
  static String get installedApps => _t('Installed Apps', 'ইনস্টল করা অ্যাপ');
  static String appsFound(int count) =>
      _t('$count found', '$countটি পাওয়া গেছে');
  static String get usageAccessTitle =>
      _t('Usage Access Required', 'ব্যবহার অ্যাক্সেস প্রয়োজন');
  static String get usageAccessBody =>
      _t('App Blocker needs "Usage Access" permission to see which apps are installed and running on your phone.\n\nTap below → find Campus Twin → enable the toggle.',
          'অ্যাপ ব্লকারের জন্য "ব্যবহার অ্যাক্সেস" অনুমতি প্রয়োজন, যাতে আপনার ফোনে কোন অ্যাপ ইনস্টল ও চলছে তা দেখা যায়।\n\nনিচে চাপুন → Campus Twin খুঁজুন → টগল চালু করুন।');
  static String get openSettings => _t('Open Settings', 'সেটিংস খুলুন');
  static String get findCampusTwin =>
      _t('Find "Campus Twin"', '"Campus Twin" খুঁজুন');
  static String get enableUsageAccess =>
      _t('Enable Usage Access', 'ব্যবহার অ্যাক্সেস চালু করুন');
  static String get scanningApps =>
      _t('Scanning installed apps…', 'ইনস্টল করা অ্যাপ স্ক্যান হচ্ছে…');
  static String get failedToLoadApps =>
      _t('Failed to load apps', 'অ্যাপ লোড করতে ব্যর্থ হয়েছে');
  static String get retry => _t('Retry', 'আবার চেষ্টা করুন');
  static String get focusModeActive =>
      _t('Focus Mode Active', 'ফোকাস মোড চালু');
  static String get focusModeOff => _t('Focus Mode Off', 'ফোকাস মোড বন্ধ');
  static String focusActiveSub(int count, int minutes) =>
      _t('$count app(s) blocked · $minutes min session',
          '$countটি অ্যাপ ব্লক করা · $minutes মিনিট সেশন');
  static String get focusOffSub =>
      _t('Pick apps from YOUR phone below, then start.',
          'নিচে আপনার ফোন থেকে অ্যাপ বেছে নিন, তারপর শুরু করুন।');
  static String get duration => _t('Duration', 'সময়কাল');
  static String minutes(int minutes) =>
      _t('$minutes min', '$minutes মিনিট');
  static String get start => _t('Start', 'শুরু');
  static String get stop => _t('Stop', 'বন্ধ');
  static String get blocked => _t('Blocked', 'ব্লককৃত');
  static String get focusTips => _t('Focus Tips', 'ফোকাস টিপস');
  static String get tip1 =>
      _t('📵 Blocking apps helps you stay in flow state longer.',
          '📵 অ্যাপ ব্লক করলে আপনি দীর্ঘক্ষণ ফোকাসে থাকতে পারবেন।');
  static String get tip2 =>
      _t('⏱️  Try the 25-min Pomodoro technique for deep work.',
          '⏱️  গভীর কাজের জন্য ২৫ মিনিটের পোমোডোরো কৌশল চেষ্টা করুন।');
  static String get tip3 =>
      _t('🔕 Combine with Do Not Disturb for best results.',
          '🔕 সেরা ফলাফলের জন্য ডু নট ডিস্টার্ব-এর সাথে ব্যবহার করুন।');
  static String get quickFocus => _t('Quick Focus', 'কুইক ফোকাস');
  static String get pomodoro => _t('Pomodoro', 'পোমোডোরো');
  static String get deepWork => _t('Deep Work', 'ডিপ ওয়ার্ক');
  static String get oneHour => _t('1 Hour', '১ ঘণ্টা');
  static String get longSession => _t('Long Session', 'লং সেশন');
  static String get powerBlock => _t('Power Block', 'পাওয়ার ব্লক');
  static String get selectDuration => _t('Select Duration', 'সময়কাল নির্বাচন করুন');

  // ── Leaderboard page ───────────────────────────────────────────────────
  static String get leaderboardTitle => _t('Leaderboard', 'লিডারবোর্ড');
  static String rankBadge(int rank) => _t('Rank #$rank', 'র‍্যাংক #$rank');
  static String get plannerTab => _t('⭐  Planner', '⭐  পরিকল্পনা');
  static String get habitsTab => _t('🔥  Habits', '🔥  অভ্যাস');
  static String get screenTimeTab => _t('📱  Screen Time', '📱  স্ক্রিন সময়');
  static String get you => _t('You', 'আপনি');
  static String stars(int count) => _t('$count stars', '$countটি স্টার');
  static String pts(int count) => _t('$count pts', '$count পয়েন্ট');
  static String minPerDay(int minutes) =>
      _t('$minutes min/day', '$minutes মিনিট/দিন');
  static String streakSummary(int stars, int pts, int mins) =>
      _t('⭐$stars  🔥$pts pts  📱$mins m',
          '⭐$stars  🔥$pts পয়েন্ট  📱$mins মিনিট');

  // ── Welcome page ───────────────────────────────────────────────────────
  static String get heroTitle =>
      _t('Meet your\ndigital twin.', 'আপনার\nডিজিটাল টুইনের সাথে পরিচিত হোন।');
  static String get heroBody =>
      _t('CampusTwin unifies your studies, habits, stress and expenses into one AI-powered system — so it can guide you, not just track you.',
          'CampusTwin আপনার পড়াশোনা, অভ্যাস, চাপ ও খরচকে একটি এআই-চালিত সিস্টেমে একত্র করে — যেন এটি আপনাকে শুধু ট্র্যাক না করে গাইড করতে পারে।');
  static String get aiRecommendations =>
      _t('AI recommendations', 'এআই পরামর্শ');
  static String get stressPrediction =>
      _t('Stress prediction', 'চাপ পূর্বাভাস');
  static String get smartScheduling =>
      _t('Smart scheduling', 'স্মার্ট সময়সূচি');
  static String get signIn => _t('Sign In', 'সাইন ইন');
  static String get createAccount => _t('Create Account', 'অ্যাকাউন্ট তৈরি করুন');

  // ── Login page ─────────────────────────────────────────────────────────
  static String get fillAllFields =>
      _t('Please fill in all fields', 'অনুগ্রহ করে সব ঘর পূরণ করুন');
  static String get brandPill => _t('CampusTwin', 'CampusTwin');
  static String get welcomeBack => _t('Welcome back', 'ফিরে আসায় স্বাগতম');
  static String get signInContinue =>
      _t('Sign in to continue your CampusTwin experience.',
          'CampusTwin অভিজ্ঞতা চালিয়ে যেতে সাইন ইন করুন।');
  static String get secureSignIn => _t('Secure sign in', 'নিরাপদ সাইন ইন');
  static String get personalizedSetup =>
      _t('Personalized setup', 'ব্যক্তিগতকৃত সেটআপ');
  static String get signInCardTitle =>
      _t('Welcome back', 'ফিরে আসায় স্বাগতম');
  static String get signInCardSubtitle =>
      _t('Sign in to continue where your student profile left off.',
          'আপনার শিক্ষার্থী প্রোফাইল যেখানে ছিল সেখান থেকে চালিয়ে যেতে সাইন ইন করুন।');
  static String get universityEmail => _t('University Email', 'বিশ্ববিদ্যালয় ইমেইল');
  static String get emailHint => _t('you@university.edu', 'you@university.edu');
  static String get password => _t('Password', 'পাসওয়ার্ড');
  static String get passwordHint => _t('Min. 6 characters', 'ন্যূনতম ৬ অক্ষর');
  static String get forgotPassword =>
      _t('Forgot password?', 'পাসওয়ার্ড ভুলে গেছেন?');
  static String get or => _t('or', 'বা');
  static String get dontHaveAccount =>
      _t('Don\'t have an account? ', 'অ্যাকাউন্ট নেই? ');
  static String get register => _t('Register', 'নিবন্ধন');
  static String get secureBadge => _t('Secure', 'নিরাপদ');

  // ── Register page ──────────────────────────────────────────────────────
  static String get passwordTooShort =>
      _t('Password must be at least 6 characters',
          'পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের হতে হবে');
  static String get createAccountHero =>
      _t('Create account', 'অ্যাকাউন্ট তৈরি করুন');
  static String get setStudentProfile =>
      _t('Set up your student profile and start your CampusTwin journey.',
          'আপনার শিক্ষার্থী প্রোফাইল সেট করুন এবং CampusTwin যাত্রা শুরু করুন।');
  static String get fastOnboarding =>
      _t('Fast onboarding', 'দ্রুত অনবোর্ডিং');
  static String get privateProfile =>
      _t('Private profile', 'গোপনীয় প্রোফাইল');
  static String get createAccountCardTitle =>
      _t('Create your account', 'আপনার অ্যাকাউন্ট তৈরি করুন');
  static String get completeForm =>
      _t('Complete the form below to set up your profile.',
          'প্রোফাইল সেট করতে নিচের ফর্মটি পূরণ করুন।');
  static String get fullName => _t('Full Name', 'পুরো নাম');
  static String get nameHint => _t('Alex Rahman', 'Alex Rahman');
  static String get selectDepartment =>
      _t('Select department', 'বিভাগ নির্বাচন করুন');
  static String get selectSemester =>
      _t('Select semester', 'সেমিস্টার নির্বাচন করুন');
  static String get pleaseSelect =>
      _t('Please select an option.', 'একটি অপশন নির্বাচন করুন।');
  static String get passwordHelper =>
      _t('Use at least 6 characters with a mix of letters and numbers.',
          'অক্ষর ও সংখ্যার মিশ্রণে কমপক্ষে ৬ অক্ষর ব্যবহার করুন।');
  static String get alreadyHaveAccount =>
      _t('Already have an account? ', 'ইতিমধ্যে অ্যাকাউন্ট আছে? ');
  static String get signInLink => _t('Sign In', 'সাইন ইন');

  // ── Auth ───────────────────────────────────────────────────────────────
  static String get authAccountCreated => _t(
      'Account created! A verification link has been sent to your email. Verify it, then sign in.',
      'অ্যাকাউন্ট তৈরি হয়েছে! আপনার ইমেইলে একটি ভেরিফিকেশন লিংক পাঠানো হয়েছে। ভেরিফাই করে সাইন ইন করুন।');
  static String get emailNotVerified => _t(
      'Please verify your email first. A new verification link was sent to your inbox.',
      'আগে আপনার ইমেইল ভেরিফাই করুন। একটি নতুন ভেরিফিকেশন লিংক আপনার ইনবক্সে পাঠানো হয়েছে।');
  static String get authInvalidEmail =>
      _t('Invalid email address.', 'ইমেইল ঠিকানা সঠিক নয়।');
  static String get authUserNotFound =>
      _t('No account found with this email.', 'এই ইমেইলে কোনো অ্যাকাউন্ট পাওয়া যায়নি।');
  static String get authWrongPassword =>
      _t('Incorrect password. Please try again.', 'পাসওয়ার্ড সঠিক নয়। আবার চেষ্টা করুন।');
  static String get authEmailInUse => _t(
      'An account with this email already exists.',
      'এই ইমেইলে ইতিমধ্যে একটি অ্যাকাউন্ট আছে।');
  static String get authWeakPassword =>
      _t('Password is too weak.', 'পাসওয়ার্ড খুব দুর্বল।');
  static String get authTooManyRequests => _t(
      'Too many attempts. Please wait a while.',
      'অনেকবার চেষ্টা করা হয়েছে। কিছুক্ষণ পরে আবার চেষ্টা করুন।');
  static String get authNetworkError => _t(
      'Network error. Check your connection.',
      'নেটওয়ার্ক সমস্যা। আপনার ইন্টারনেট সংযোগ পরীক্ষা করুন।');
  static String get authOperationNotAllowed => _t(
      'Email/Password sign-in is not enabled on this app.',
      'এই অ্যাপে ইমেইল/পাসওয়ার্ড সাইন-ইন সক্ষম নেই।');
  static String get authFailed =>
      _t('Sign-in failed. Please try again.', 'সাইন-ইন ব্যর্থ হয়েছে। আবার চেষ্টা করুন।');
  static String get enterEmailToReset => _t(
      'Enter your email to receive a password reset link.',
      'পাসওয়ার্ড রিসেট লিংক পেতে আপনার ইমেইল লিখুন।');
  static String get sendResetLink =>
      _t('Send Reset Link', 'রিসেট লিংক পাঠান');
  static String get resetEmailSent => _t(
      'Password reset email sent. Check your inbox.',
      'পাসওয়ার্ড রিসেট ইমেইল পাঠানো হয়েছে। আপনার ইনবক্স দেখুন।');

  /// Accepts MIST student emails (202314100@student.mist.ac.bd),
  /// Gmail (user@gmail.com) and any other standard email address.
  static bool isValidEmail(String value) {
    final v = value.trim().toLowerCase();
    final student = RegExp(r'^\d{7,10}@student\.mist\.ac\.bd$');
    final gmail = RegExp(r'^[a-z0-9._%+-]+@gmail\.com$');
    final generic = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return student.hasMatch(v) || gmail.hasMatch(v) || generic.hasMatch(v);
  }

  static String authErrorMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return authInvalidEmail;
      case 'user-not-found':
        return authUserNotFound;
      case 'wrong-password':
      case 'invalid-credential':
        return authWrongPassword;
      case 'email-already-in-use':
        return authEmailInUse;
      case 'weak-password':
        return authWeakPassword;
      case 'too-many-requests':
        return authTooManyRequests;
      case 'network-request-failed':
        return authNetworkError;
      case 'operation-not-allowed':
        return authOperationNotAllowed;
      default:
        return '$authFailed ($code)';
    }
  }
}
