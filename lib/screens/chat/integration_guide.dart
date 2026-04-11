// // ============================================================
// // HOW TO INTEGRATE CHAT INTO YOUR EXISTING REQUEST FLOW
// // ============================================================

// // ─── STEP 1: When mentor ACCEPTS a request ──────────────────
// // In your existing "accept request" function, add the chat creation:

// Future<void> acceptSkillRequest({
//   required String requestId,
//   required String mentorId,
//   required String learnerId,
// }) async {
//   final chatService = ChatService();

//   // Your existing accept logic
//   await FirebaseFirestore.instance
//       .collection('skillRequests')
//       .doc(requestId)
//       .update({'status': 'accepted'});

//   // ✅ ADD THIS: Create a conversation automatically
//   final conversationId = await chatService.createConversationOnAccept(
//     requestId: requestId,
//     mentorId: mentorId,
//     learnerId: learnerId,
//   );

//   print('Chat unlocked! Conversation: $conversationId');
// }

// // ─── STEP 2: Show "Chat" button only after acceptance ────────
// // In your request card/profile widget:

// Widget buildRequestCard(SkillRequest request, String currentUserId) {
//   return Column(
//     children: [
//       // ... your existing card UI ...

//       // ✅ Only show Chat button if request is accepted
//       if (request.status == 'accepted' && request.conversationId != null)
//         ElevatedButton.icon(
//           onPressed: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (_) => ChatScreen(
//                   conversationId: request.conversationId!,
//                   currentUserId: currentUserId,
//                   otherUserId: request.otherUserId(currentUserId),
//                   otherUserName: request.otherUserName(currentUserId),
//                   otherUserPhoto: request.otherUserPhoto(currentUserId),
//                 ),
//               ),
//             );
//           },
//           icon: const Icon(Icons.chat_bubble_rounded),
//           label: const Text('Chat'),
//           style: ElevatedButton.styleFrom(
//             backgroundColor: const Color(0xFF6C63FF),
//             foregroundColor: Colors.white,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//           ),
//         ),
//     ],
//   );
// }

// // ─── STEP 3: Add Messages tab to your bottom nav ─────────────
// // In your main scaffold, add a Messages tab with unread badge:

// StreamBuilder<int>(
//   stream: chatService.streamTotalUnread(currentUserId),
//   builder: (context, snapshot) {
//     final unread = snapshot.data ?? 0;
//     return Badge(
//       isLabelVisible: unread > 0,
//       label: Text('$unread'),
//       child: const Icon(Icons.chat_bubble_outline_rounded),
//     );
//   },
// ),

// // ─── STEP 4: Add to pubspec.yaml ─────────────────────────────
// /*
// dependencies:
//   flutter:
//     sdk: flutter
//   cloud_firestore: ^4.17.0
//   firebase_messaging: ^14.9.0
//   timeago: ^3.6.0
//   intl: ^0.19.0
// */

// // ─── STEP 5: Firestore Security Rules ────────────────────────
// /*
// rules_version = '2';
// service cloud.firestore {
//   match /databases/{database}/documents {
  
//     // Conversations: only participants can read/write
//     match /conversations/{convId} {
//       allow read, write: if request.auth.uid in resource.data.participants;
      
//       match /messages/{msgId} {
//         allow read: if request.auth.uid in 
//           get(/databases/$(database)/documents/conversations/$(convId)).data.participants;
//         allow create: if request.auth.uid == request.resource.data.senderId
//           && request.auth.uid in 
//           get(/databases/$(database)/documents/conversations/$(convId)).data.participants;
//         allow update: if request.auth.uid in 
//           get(/databases/$(database)/documents/conversations/$(convId)).data.participants;
//       }
//     }
//   }
// }
// */

// // ─── STEP 6: Cloud Function for push notifications ───────────
// /*
// // functions/index.js
// const functions = require("firebase-functions");
// const admin = require("firebase-admin");
// admin.initializeApp();

// exports.sendChatNotification = functions.firestore
//   .document("notifications/{notifId}")
//   .onCreate(async (snap) => {
//     const data = snap.data();
//     if (data.sent) return;

//     await admin.messaging().send({
//       token: data.fcmToken,
//       notification: { title: data.title, body: data.body },
//       data: { type: "chat", conversationId: data.conversationId },
//     });

//     await snap.ref.update({ sent: true });
//   });
// */
