// providers/request_provider.dart
import 'package:flutter/foundation.dart';
import 'package:mentora/services/request_service.dart';

enum RequestStatus { idle, loading, success, error }

class RequestProvider extends ChangeNotifier {
  final RequestService _requestService = RequestService();

  // State
  RequestStatus _status = RequestStatus.idle;
  String? _errorMessage;
  List<Map<String, dynamic>> _sentRequests = [];
  List<Map<String, dynamic>> _receivedRequests = [];

  // Getters
  RequestStatus get status => _status;
  String? get errorMessage => _errorMessage;
  List<Map<String, dynamic>> get sentRequests => _sentRequests;
  List<Map<String, dynamic>> get receivedRequests => _receivedRequests;
  bool get isLoading => _status == RequestStatus.loading;

  // Stream subscriptions
  Stream<List<Map<String, dynamic>>>? _sentRequestsStream;
  Stream<List<Map<String, dynamic>>>? _receivedRequestsStream;

  void initialize() {
    _sentRequestsStream = _requestService.getMySentRequests();
    _receivedRequestsStream = _requestService.getMyReceivedRequests();

    _sentRequestsStream!.listen(
      (requests) {
        _sentRequests = requests;
        notifyListeners();
      },
      onError: (error) {
        _setError(error.toString());
      },
    );

    _receivedRequestsStream!.listen(
      (requests) {
        _receivedRequests = requests;
        notifyListeners();
      },
      onError: (error) {
        _setError(error.toString());
      },
    );
  }

  void _setLoading() {
    _status = RequestStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setSuccess() {
    _status = RequestStatus.success;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _status = RequestStatus.error;
    _errorMessage = message;
    notifyListeners();
  }

  Future<bool> createRequest({
    required String mentorId,
    required String mentorName,
    required String mentorEmail,
    required String skillName,
    required String skillCategory,
    required String message,
    DateTime? preferredDate,
    String? preferredTime,
  }) async {
    _setLoading();
    try {
      await _requestService.createRequest(
        mentorId: mentorId,
        mentorName: mentorName,
        mentorEmail: mentorEmail,
        skillName: skillName,
        skillCategory: skillCategory,
        message: message,
        preferredDate: preferredDate,
        preferredTime: preferredTime,
      );
      _setSuccess();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> acceptRequest({
    required String requestId,
    required DateTime sessionDate,
    required String sessionTime,
    required String meetingLocation,
  }) async {
    _setLoading();
    try {
      await _requestService.acceptRequest(
        requestId: requestId,
        sessionDate: sessionDate,
        sessionTime: sessionTime,
        meetingLocation: meetingLocation,
      );
      _setSuccess();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> rejectRequest(String requestId) async {
    _setLoading();
    try {
      await _requestService.rejectRequest(requestId);
      _setSuccess();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> completeRequest(String requestId) async {
    _setLoading();
    try {
      await _requestService.completeRequest(requestId);
      _setSuccess();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> submitRating({
    required String requestId,
    required double rating,
    String? review,
  }) async {
    _setLoading();
    try {
      await _requestService.submitRating(
        requestId: requestId,
        rating: rating,
        review: review,
      );
      _setSuccess();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> cancelRequest(String requestId) async {
    _setLoading();
    try {
      await _requestService.cancelRequest(requestId);
      _setSuccess();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    _status = RequestStatus.idle;
    notifyListeners();
  }

  @override
  void dispose() {
    // Clean up streams if needed
    super.dispose();
  }
}

// Update main.dart to include RequestProvider
// In your MultiProvider:
/*
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => ThemeProvider()..loadTheme()),
    ChangeNotifierProvider(create: (_) => LanguageProvider()),
    ChangeNotifierProvider(create: (_) => RequestProvider()..initialize()),
  ],
  child: const MyApp(),
)
*/