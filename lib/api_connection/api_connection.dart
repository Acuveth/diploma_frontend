class API {
  // Connecting to the database
  static const hostConnect = "http://192.168.1.210/diploma_backend";

  // Authentication
  static const signUp = "$hostConnect/user/authentication/signup.php";
  static const logIn = "$hostConnect/user/authentication/login.php";

  // Profile
  static const getProfile = "$hostConnect/user/profile/get_profile.php";
  static const updateProfilePicture = "$hostConnect/user/profile/update_profile_picture.php";

  // Live messages
  static const getMessages = "$hostConnect/messages/get_messages.php";
  static const sendMessages = "$hostConnect/messages/send_messages.php";

  // Offline Questions
  static const offlineQuestions = "$hostConnect/offlineQuiz/get_offline_quiz.php";
  static const submitAnswerOfflineQuestions = "$hostConnect/offlineQuiz/submit_answer_offline.php";

  // Lecture Progress
  static const getLectureProgress = "$hostConnect/offlineQuiz/get_lecture_progress.php";
  static const updateLectureProgress = "$hostConnect/offlineQuiz/update_lecture_progress.php";

  // Live Questions
  static const activateLiveQuestions = "$hostConnect/liveQuiz/activate_live_questions.php";
  static const getActiveQuestion = "$hostConnect/liveQuiz/get_live_questions.php";
  static const submitAnswerLiveQuestion = "$hostConnect/liveQuiz/post_live_questions_answer.php";

  //Leaderboard
  static const getLeaderdoard = "$hostConnect/leaderboard/get_leaderboard.php";

}
