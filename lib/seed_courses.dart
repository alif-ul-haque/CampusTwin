import 'package:cloud_firestore/cloud_firestore.dart';

class CourseSeeder {
  static Future<void> seedCourses() async {
    final firestore = FirebaseFirestore.instance;
    final coursesCollection = firestore.collection('course_catalog');

    final courses = [
      // Level-1, Term-1
      { 'code': 'CSE-101', 'name': 'Discrete Mathematics', 'credit': 3.00, 'level': 1, 'term': 1, 'type': 'Theory', 'isElective': false, 'electiveGroup': null },
      { 'code': 'CHEM-101', 'name': 'Fundamentals of Chemistry', 'credit': 3.00, 'level': 1, 'term': 1, 'type': 'Theory', 'isElective': false, 'electiveGroup': null },
      { 'code': 'CHEM-102', 'name': 'Chemistry Sessional', 'credit': 1.50, 'level': 1, 'term': 1, 'type': 'Sessional', 'isElective': false, 'electiveGroup': null },
      { 'code': 'EECE-163', 'name': 'Electrical Circuit Analysis', 'credit': 3.00, 'level': 1, 'term': 1, 'type': 'Theory', 'isElective': false, 'electiveGroup': null },
      { 'code': 'EECE-164', 'name': 'Electrical Circuit Analysis Sessional', 'credit': 0.75, 'level': 1, 'term': 1, 'type': 'Sessional', 'isElective': false, 'electiveGroup': null },
      { 'code': 'GEBS-101', 'name': 'Bangladesh Studies', 'credit': 2.00, 'level': 1, 'term': 1, 'type': 'Theory', 'isElective': false, 'electiveGroup': null },
      { 'code': 'MATH-101', 'name': 'Differential and Integral Calculus', 'credit': 3.00, 'level': 1, 'term': 1, 'type': 'Theory', 'isElective': false, 'electiveGroup': null },
      { 'code': 'PHY-101', 'name': 'Waves and Oscillations, Optics and Modern Physics', 'credit': 3.00, 'level': 1, 'term': 1, 'type': 'Theory', 'isElective': false, 'electiveGroup': null },
      { 'code': 'PHY-102', 'name': 'Physics Sessional', 'credit': 1.50, 'level': 1, 'term': 1, 'type': 'Sessional', 'isElective': false, 'electiveGroup': null },

      // Level-1, Term-2
      { 'code': 'CSE-103', 'name': 'Digital Logic Design', 'credit': 3.00, 'level': 1, 'term': 2, 'type': 'Theory', 'isElective': false, 'electiveGroup': null },
      { 'code': 'CSE-104', 'name': 'Digital Logic Design Sessional', 'credit': 1.50, 'level': 1, 'term': 2, 'type': 'Sessional', 'isElective': false, 'electiveGroup': null },
      { 'code': 'CSE-105', 'name': 'Structured Programming Language', 'credit': 3.00, 'level': 1, 'term': 2, 'type': 'Theory', 'isElective': false, 'electiveGroup': null },
      { 'code': 'CSE-106', 'name': 'Structured Programming Language Sessional', 'credit': 1.50, 'level': 1, 'term': 2, 'type': 'Sessional', 'isElective': false, 'electiveGroup': null },
      { 'code': 'EECE-169', 'name': 'Electronic Devices and Circuits', 'credit': 3.00, 'level': 1, 'term': 2, 'type': 'Theory', 'isElective': false, 'electiveGroup': null },
      { 'code': 'EECE-170', 'name': 'Electronic Devices and Circuits Sessional', 'credit': 0.75, 'level': 1, 'term': 2, 'type': 'Sessional', 'isElective': false, 'electiveGroup': null },
      { 'code': 'ENG-102', 'name': 'Communicative English-I', 'credit': 1.50, 'level': 1, 'term': 2, 'type': 'Sessional', 'isElective': false, 'electiveGroup': null },
      { 'code': 'MATH-105', 'name': 'Vector Analysis, Matrix and Coordinate Geometry', 'credit': 3.00, 'level': 1, 'term': 2, 'type': 'Theory', 'isElective': false, 'electiveGroup': null },
      { 'code': 'ME-122', 'name': 'Fundamental of Mechanical Engineering Sessional', 'credit': 2.00, 'level': 1, 'term': 2, 'type': 'Sessional', 'isElective': false, 'electiveGroup': null },

      // Level-2, Term-1
      { 'code': 'CSE-203', 'name': 'Data Structures and Algorithms-I', 'credit': 3.00, 'level': 2, 'term': 1, 'type': 'Theory', 'isElective': false, 'electiveGroup': null },
      { 'code': 'CSE-204', 'name': 'Data Structures and Algorithms-I Sessional', 'credit': 1.50, 'level': 2, 'term': 1, 'type': 'Sessional', 'isElective': false, 'electiveGroup': null },
      { 'code': 'CSE-205', 'name': 'Object Oriented Programming Language', 'credit': 3.00, 'level': 2, 'term': 1, 'type': 'Theory', 'isElective': false, 'electiveGroup': null },
      { 'code': 'CSE-206', 'name': 'Object Oriented Programming Language Sessional-I', 'credit': 1.50, 'level': 2, 'term': 1, 'type': 'Sessional', 'isElective': false, 'electiveGroup': null },
      { 'code': 'CSE-217', 'name': 'Theory of Computation', 'credit': 3.00, 'level': 2, 'term': 1, 'type': 'Theory', 'isElective': false, 'electiveGroup': null },
      { 'code': 'EECE-269', 'name': 'Electrical Drives and Instrumentation', 'credit': 3.00, 'level': 2, 'term': 1, 'type': 'Theory', 'isElective': false, 'electiveGroup': null },
      { 'code': 'EECE-270', 'name': 'Electrical Drives and Instrumentation Sessional', 'credit': 0.75, 'level': 2, 'term': 1, 'type': 'Sessional', 'isElective': false, 'electiveGroup': null },
      { 'code': 'ENG-202', 'name': 'Communicative English-II', 'credit': 1.50, 'level': 2, 'term': 1, 'type': 'Sessional', 'isElective': false, 'electiveGroup': null },
      { 'code': 'MATH-205', 'name': 'Differential Equations, Laplace Transform and Fourier Transform', 'credit': 3.00, 'level': 2, 'term': 1, 'type': 'Theory', 'isElective': false, 'electiveGroup': null },

      // Level-2, Term-2
      { 'code': 'CE-250', 'name': 'Engineering Drawing and CAD Sessional', 'credit': 1.50, 'level': 2, 'term': 2, 'type': 'Sessional', 'isElective': false, 'electiveGroup': null },
      { 'code': 'CSE-213', 'name': 'Computer Architecture', 'credit': 3.00, 'level': 2, 'term': 2, 'type': 'Theory', 'isElective': false, 'electiveGroup': null },
      { 'code': 'CSE-215', 'name': 'Data Structures and Algorithms-II', 'credit': 3.00, 'level': 2, 'term': 2, 'type': 'Theory', 'isElective': false, 'electiveGroup': null },
      { 'code': 'CSE-216', 'name': 'Data Structures and Algorithms-II Sessional', 'credit': 1.50, 'level': 2, 'term': 2, 'type': 'Sessional', 'isElective': false, 'electiveGroup': null },
      { 'code': 'CSE-219', 'name': 'Mathematical Analysis for Computer Science', 'credit': 3.00, 'level': 2, 'term': 2, 'type': 'Theory', 'isElective': false, 'electiveGroup': null },
      { 'code': 'CSE-220', 'name': 'Object Oriented Programming Sessional-II', 'credit': 0.75, 'level': 2, 'term': 2, 'type': 'Sessional', 'isElective': false, 'electiveGroup': null },
      { 'code': 'EECE-279', 'name': 'Digital Electronics and Pulse Technique', 'credit': 3.00, 'level': 2, 'term': 2, 'type': 'Theory', 'isElective': false, 'electiveGroup': null },
      { 'code': 'EECE-280', 'name': 'Digital Electronics and Pulse Technique Sessional', 'credit': 0.75, 'level': 2, 'term': 2, 'type': 'Sessional', 'isElective': false, 'electiveGroup': null },
      { 'code': 'GELM-275', 'name': 'Leadership and Management', 'credit': 2.00, 'level': 2, 'term': 2, 'type': 'Theory', 'isElective': false, 'electiveGroup': null },
      { 'code': 'MATH-207', 'name': 'Complex Variable and Statistics', 'credit': 3.00, 'level': 2, 'term': 2, 'type': 'Theory', 'isElective': false, 'electiveGroup': null },

      // Level-3, Term-1
      { 'code': 'CSE-301', 'name': 'Database Management Systems', 'credit': 3.00, 'level': 3, 'term': 1, 'type': 'Theory', 'isElective': false, 'electiveGroup': null },
      { 'code': 'CSE-302', 'name': 'Database Management Systems Sessional', 'credit': 1.50, 'level': 3, 'term': 1, 'type': 'Sessional', 'isElective': false, 'electiveGroup': null },
      { 'code': 'CSE-303', 'name': 'Compiler', 'credit': 3.00, 'level': 3, 'term': 1, 'type': 'Theory', 'isElective': false, 'electiveGroup': null },
      { 'code': 'CSE-304', 'name': 'Compiler Sessional', 'credit': 0.75, 'level': 3, 'term': 1, 'type': 'Sessional', 'isElective': false, 'electiveGroup': null },
      { 'code': 'CSE-305', 'name': 'Microprocessors, Micro-controllers and Assembly Language', 'credit': 3.00, 'level': 3, 'term': 1, 'type': 'Theory', 'isElective': false, 'electiveGroup': null },
      { 'code': 'CSE-306', 'name': 'Microprocessors, Micro-controllers and Assembly Language Sessional', 'credit': 1.50, 'level': 3, 'term': 1, 'type': 'Sessional', 'isElective': false, 'electiveGroup': null },
      { 'code': 'CSE-307', 'name': 'Operating System', 'credit': 3.00, 'level': 3, 'term': 1, 'type': 'Theory', 'isElective': false, 'electiveGroup': null },
      { 'code': 'CSE-308', 'name': 'Operating System Sessional', 'credit': 0.75, 'level': 3, 'term': 1, 'type': 'Sessional', 'isElective': false, 'electiveGroup': null },
      { 'code': 'CSE-317', 'name': 'Data Communication', 'credit': 3.00, 'level': 3, 'term': 1, 'type': 'Theory', 'isElective': false, 'electiveGroup': null },
      { 'code': 'CSE-318', 'name': 'Data Communication Sessional', 'credit': 0.75, 'level': 3, 'term': 1, 'type': 'Sessional', 'isElective': false, 'electiveGroup': null },

      // Level-3, Term-2
      { 'code': 'CSE-309', 'name': 'Computer Network', 'credit': 3.00, 'level': 3, 'term': 2, 'type': 'Theory', 'isElective': false, 'electiveGroup': null },
      { 'code': 'CSE-310', 'name': 'Computer Network Sessional', 'credit': 1.50, 'level': 3, 'term': 2, 'type': 'Sessional', 'isElective': false, 'electiveGroup': null },
      { 'code': 'CSE-315', 'name': 'Digital System Design', 'credit': 2.00, 'level': 3, 'term': 2, 'type': 'Theory', 'isElective': false, 'electiveGroup': null },
      { 'code': 'CSE-316', 'name': 'Digital System Design Sessional', 'credit': 0.75, 'level': 3, 'term': 2, 'type': 'Sessional', 'isElective': false, 'electiveGroup': null },
      { 'code': 'CSE-319', 'name': 'Software Engineering', 'credit': 3.00, 'level': 3, 'term': 2, 'type': 'Theory', 'isElective': false, 'electiveGroup': null },
      { 'code': 'CSE-320', 'name': 'Software Engineering Sessional', 'credit': 0.75, 'level': 3, 'term': 2, 'type': 'Sessional', 'isElective': false, 'electiveGroup': null },
      { 'code': 'CSE-364', 'name': 'Software Development Project - I', 'credit': 1.50, 'level': 3, 'term': 2, 'type': 'Sessional', 'isElective': false, 'electiveGroup': null },
      { 'code': 'GERM-352', 'name': 'Fundamentals of Research Methodology', 'credit': 2.00, 'level': 3, 'term': 2, 'type': 'Theory', 'isElective': false, 'electiveGroup': null },
      { 'code': 'GES-301', 'name': 'Fundamentals of Sociology', 'credit': 2.00, 'level': 3, 'term': 2, 'type': 'Theory', 'isElective': false, 'electiveGroup': null },
      { 'code': 'GESL-303', 'name': 'Environment, Sustainability and Law', 'credit': 2.00, 'level': 3, 'term': 2, 'type': 'Theory', 'isElective': false, 'electiveGroup': null },
      { 'code': 'CSE-350', 'name': 'Industrial Training', 'credit': 1.00, 'level': 3, 'term': 2, 'type': 'Sessional', 'isElective': false, 'electiveGroup': null },

      // Level-4, Term-1
      { 'code': 'CSE-400', 'name': 'Final Year Research & Design Project', 'credit': 3.00, 'level': 4, 'term': 1, 'type': 'Sessional', 'isElective': false, 'electiveGroup': null },
      { 'code': 'CSE-405', 'name': 'Computer Interfacing', 'credit': 3.00, 'level': 4, 'term': 1, 'type': 'Theory', 'isElective': false, 'electiveGroup': null },
      { 'code': 'CSE-406', 'name': 'Computer Interfacing Sessional', 'credit': 0.75, 'level': 4, 'term': 1, 'type': 'Sessional', 'isElective': false, 'electiveGroup': null },
      { 'code': 'CSE-415', 'name': 'Human Computer Interaction', 'credit': 3.00, 'level': 4, 'term': 1, 'type': 'Theory', 'isElective': false, 'electiveGroup': null },
      { 'code': 'CSE-429', 'name': 'Computer Security', 'credit': 3.00, 'level': 4, 'term': 1, 'type': 'Theory', 'isElective': false, 'electiveGroup': null },
      { 'code': 'CSE-464', 'name': 'Software Development Project-II', 'credit': 1.50, 'level': 4, 'term': 1, 'type': 'Sessional', 'isElective': false, 'electiveGroup': null },
      { 'code': 'GEEM-433', 'name': 'Engineering Ethics and Moral Philosophy', 'credit': 2.00, 'level': 4, 'term': 1, 'type': 'Theory', 'isElective': false, 'electiveGroup': null },

      // Technical Elective-I
      { 'code': 'CSE-407', 'name': 'Applied Statistics and Queuing Theory', 'credit': 3.00, 'level': 4, 'term': 1, 'type': 'Theory', 'isElective': true, 'electiveGroup': 'Technical Elective-I' },
      { 'code': 'CSE-417', 'name': 'Blockchaining and Cryptocurrency Technology', 'credit': 3.00, 'level': 4, 'term': 1, 'type': 'Theory', 'isElective': true, 'electiveGroup': 'Technical Elective-I' },
      { 'code': 'CSE-419', 'name': 'Advanced Algorithms', 'credit': 3.00, 'level': 4, 'term': 1, 'type': 'Theory', 'isElective': true, 'electiveGroup': 'Technical Elective-I' },
      { 'code': 'CSE-421', 'name': 'Basic Graph Theory', 'credit': 3.00, 'level': 4, 'term': 1, 'type': 'Theory', 'isElective': true, 'electiveGroup': 'Technical Elective-I' },
      { 'code': 'CSE-423', 'name': 'Fault Tolerance System', 'credit': 3.00, 'level': 4, 'term': 1, 'type': 'Theory', 'isElective': true, 'electiveGroup': 'Technical Elective-I' },
      { 'code': 'CSE-425', 'name': 'Basic Multimedia Theory', 'credit': 3.00, 'level': 4, 'term': 1, 'type': 'Theory', 'isElective': true, 'electiveGroup': 'Technical Elective-I' },
      { 'code': 'CSE-427', 'name': 'Digital Image Processing', 'credit': 3.00, 'level': 4, 'term': 1, 'type': 'Theory', 'isElective': true, 'electiveGroup': 'Technical Elective-I' },
      { 'code': 'CSE-431', 'name': 'Object Oriented Software Engineering', 'credit': 3.00, 'level': 4, 'term': 1, 'type': 'Theory', 'isElective': true, 'electiveGroup': 'Technical Elective-I' },
      { 'code': 'CSE-433', 'name': 'Artificial Neural Networks and Fuzzy Systems', 'credit': 3.00, 'level': 4, 'term': 1, 'type': 'Theory', 'isElective': true, 'electiveGroup': 'Technical Elective-I' },
      { 'code': 'CSE-435', 'name': 'Distributed Algorithms', 'credit': 3.00, 'level': 4, 'term': 1, 'type': 'Theory', 'isElective': true, 'electiveGroup': 'Technical Elective-I' },
      { 'code': 'CSE-437', 'name': 'Bioinformatics', 'credit': 3.00, 'level': 4, 'term': 1, 'type': 'Theory', 'isElective': true, 'electiveGroup': 'Technical Elective-I' },
      { 'code': 'CSE-439', 'name': 'Robotics', 'credit': 3.00, 'level': 4, 'term': 1, 'type': 'Theory', 'isElective': true, 'electiveGroup': 'Technical Elective-I' },
      { 'code': 'CSE-447', 'name': 'Telecommunication Engineering', 'credit': 3.00, 'level': 4, 'term': 1, 'type': 'Theory', 'isElective': true, 'electiveGroup': 'Technical Elective-I' },

      // Level-4, Term-2
      { 'code': 'CSE-400', 'name': 'Final Year Research & Design Project', 'credit': 3.00, 'level': 4, 'term': 2, 'type': 'Sessional', 'isElective': false, 'electiveGroup': null },
      { 'code': 'CSE-401', 'name': 'Information System Design and Development', 'credit': 3.00, 'level': 4, 'term': 2, 'type': 'Theory', 'isElective': false, 'electiveGroup': null },
      { 'code': 'CSE-403', 'name': 'Artificial Intelligence', 'credit': 3.00, 'level': 4, 'term': 2, 'type': 'Theory', 'isElective': false, 'electiveGroup': null },
      { 'code': 'CSE-404', 'name': 'Artificial Intelligence Sessional', 'credit': 0.75, 'level': 4, 'term': 2, 'type': 'Sessional', 'isElective': false, 'electiveGroup': null },
      { 'code': 'CSE-413', 'name': 'Computer Graphics', 'credit': 3.00, 'level': 4, 'term': 2, 'type': 'Theory', 'isElective': false, 'electiveGroup': null },
      { 'code': 'CSE-414', 'name': 'Computer Graphics Sessional', 'credit': 0.75, 'level': 4, 'term': 2, 'type': 'Sessional', 'isElective': false, 'electiveGroup': null },
      { 'code': 'GEPM-463', 'name': 'Project Management and Finance', 'credit': 2.00, 'level': 4, 'term': 2, 'type': 'Theory', 'isElective': false, 'electiveGroup': null },

      // Technical Elective-II
      { 'code': 'CSE-411', 'name': 'VLSI Design', 'credit': 3.00, 'level': 4, 'term': 2, 'type': 'Theory', 'isElective': true, 'electiveGroup': 'Technical Elective-II' },
      { 'code': 'CSE-412', 'name': 'VLSI Design Sessional', 'credit': 0.75, 'level': 4, 'term': 2, 'type': 'Sessional', 'isElective': true, 'electiveGroup': 'Technical Elective-II' },
      { 'code': 'CSE-441', 'name': 'Machine Learning', 'credit': 3.00, 'level': 4, 'term': 2, 'type': 'Theory', 'isElective': true, 'electiveGroup': 'Technical Elective-II' },
      { 'code': 'CSE-442', 'name': 'Machine Learning Sessional', 'credit': 0.75, 'level': 4, 'term': 2, 'type': 'Sessional', 'isElective': true, 'electiveGroup': 'Technical Elective-II' },
      { 'code': 'CSE-443', 'name': 'Pattern Recognition', 'credit': 3.00, 'level': 4, 'term': 2, 'type': 'Theory', 'isElective': true, 'electiveGroup': 'Technical Elective-II' },
      { 'code': 'CSE-444', 'name': 'Pattern Recognition Sessional', 'credit': 0.75, 'level': 4, 'term': 2, 'type': 'Sessional', 'isElective': true, 'electiveGroup': 'Technical Elective-II' },
      { 'code': 'CSE-445', 'name': 'Digital Signal Processing', 'credit': 3.00, 'level': 4, 'term': 2, 'type': 'Theory', 'isElective': true, 'electiveGroup': 'Technical Elective-II' },
      { 'code': 'CSE-446', 'name': 'Digital Signal Processing Sessional', 'credit': 0.75, 'level': 4, 'term': 2, 'type': 'Sessional', 'isElective': true, 'electiveGroup': 'Technical Elective-II' },
      { 'code': 'CSE-449', 'name': 'Mobile and Ubiquitous Computing', 'credit': 3.00, 'level': 4, 'term': 2, 'type': 'Theory', 'isElective': true, 'electiveGroup': 'Technical Elective-II' },
      { 'code': 'CSE-450', 'name': 'Mobile and Ubiquitous Computing Sessional', 'credit': 0.75, 'level': 4, 'term': 2, 'type': 'Sessional', 'isElective': true, 'electiveGroup': 'Technical Elective-II' },
      { 'code': 'CSE-451', 'name': 'Simulation and Modeling', 'credit': 3.00, 'level': 4, 'term': 2, 'type': 'Theory', 'isElective': true, 'electiveGroup': 'Technical Elective-II' },
      { 'code': 'CSE-452', 'name': 'Simulation and Modeling Sessional', 'credit': 0.75, 'level': 4, 'term': 2, 'type': 'Sessional', 'isElective': true, 'electiveGroup': 'Technical Elective-II' },
      { 'code': 'CSE-455', 'name': 'Natural Language Processing', 'credit': 3.00, 'level': 4, 'term': 2, 'type': 'Theory', 'isElective': true, 'electiveGroup': 'Technical Elective-II' },
      { 'code': 'CSE-456', 'name': 'Natural Language Processing Sessional', 'credit': 0.75, 'level': 4, 'term': 2, 'type': 'Sessional', 'isElective': true, 'electiveGroup': 'Technical Elective-II' },
      { 'code': 'CSE-457', 'name': 'Advanced Database Management Systems', 'credit': 3.00, 'level': 4, 'term': 2, 'type': 'Theory', 'isElective': true, 'electiveGroup': 'Technical Elective-II' },
      { 'code': 'CSE-458', 'name': 'Advanced Database Management Systems Sessional', 'credit': 0.75, 'level': 4, 'term': 2, 'type': 'Sessional', 'isElective': true, 'electiveGroup': 'Technical Elective-II' },
      { 'code': 'CSE-459', 'name': 'Internet of Things (IoT)', 'credit': 3.00, 'level': 4, 'term': 2, 'type': 'Theory', 'isElective': true, 'electiveGroup': 'Technical Elective-II' },
      { 'code': 'CSE-460', 'name': 'Internet of Things (IoT) Sessional', 'credit': 0.75, 'level': 4, 'term': 2, 'type': 'Sessional', 'isElective': true, 'electiveGroup': 'Technical Elective-II' },
      { 'code': 'CSE-461', 'name': 'Industrial Revolution', 'credit': 3.00, 'level': 4, 'term': 2, 'type': 'Theory', 'isElective': true, 'electiveGroup': 'Technical Elective-II' },
      { 'code': 'CSE-462', 'name': 'Industrial Revolution Sessional', 'credit': 0.75, 'level': 4, 'term': 2, 'type': 'Sessional', 'isElective': true, 'electiveGroup': 'Technical Elective-II' },
      { 'code': 'CSE-465', 'name': 'Cyber & Physical Security', 'credit': 3.00, 'level': 4, 'term': 2, 'type': 'Theory', 'isElective': true, 'electiveGroup': 'Technical Elective-II' },
      { 'code': 'CSE-466', 'name': 'Cyber & Physical Security Sessional', 'credit': 0.75, 'level': 4, 'term': 2, 'type': 'Sessional', 'isElective': true, 'electiveGroup': 'Technical Elective-II' },
    ];

    final batch = firestore.batch();
    
    try {
      // Check if courses already exist to prevent duplicate seeding
      final snapshot = await coursesCollection.limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        print('✅ Courses already seeded — skipping.');
        return;
      }

      for (var course in courses) {
        final docRef = coursesCollection.doc(course['code'] as String);
        batch.set(docRef, course);
      }

      await batch.commit();
      print('✅ Successfully seeded ${courses.length} courses to Firestore.');
    } catch (e, stack) {
      print('❌ CourseSeeder failed: $e');
      print(stack);
    }
  }
}
