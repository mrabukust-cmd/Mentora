// Firebase Cloud Function to send push notifications
// Deploy this to Firebase Functions

const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// Send push notification when a document is added to pushNotifications collection
exports.sendPushNotification = functions.firestore
  .document('pushNotifications/{notificationId}')
  .onCreate(async (snapshot, context) => {
    try {
      const data = snapshot.data();
      
      if (data.status !== 'pending') {
        return null;
      }
      
      const { fcmToken, title, body, data: notificationData } = data;
      
      if (!fcmToken) {
        console.error('No FCM token provided');
        await snapshot.ref.update({ status: 'failed', error: 'No FCM token' });
        return null;
      }
      
      // Prepare notification message
      const message = {
        token: fcmToken,
        notification: {
          title: title,
          body: body,
        },
        data: notificationData || {},
        android: {
          priority: 'high',
          notification: {
            sound: 'default',
            channelId: 'mentora_channel',
            priority: 'high',
            defaultSound: true,
            defaultVibrateTimings: true,
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
              'content-available': 1,
            },
          },
        },
      };
      
      // Send notification
      const response = await admin.messaging().send(message);
      console.log('✅ Notification sent successfully:', response);
      
      // Update status to sent
      await snapshot.ref.update({ 
        status: 'sent',
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        response: response,
      });
      
      return response;
    } catch (error) {
      console.error('❌ Error sending notification:', error);
      
      // Update status to failed
      await snapshot.ref.update({ 
        status: 'failed',
        error: error.message,
      });
      
      return null;
    }
  });

// Update badge count when notifications change
exports.updateBadgeCount = functions.firestore
  .document('notifications/{notificationId}')
  .onWrite(async (change, context) => {
    try {
      // Get the notification data
      const notification = change.after.exists ? change.after.data() : null;
      
      if (!notification) {
        return null;
      }
      
      const userId = notification.userId;
      
      // Count unread notifications for this user
      const unreadSnapshot = await admin.firestore()
        .collection('notifications')
        .where('userId', '==', userId)
        .where('isRead', '==', false)
        .get();
      
      const unreadCount = unreadSnapshot.size;
      
      // Get user's FCM token
      const userDoc = await admin.firestore()
        .collection('users')
        .doc(userId)
        .get();
      
      const fcmToken = userDoc.data()?.fcmToken;
      
      if (!fcmToken) {
        console.log('No FCM token for user:', userId);
        return null;
      }
      
      // Update badge count on iOS
      const message = {
        token: fcmToken,
        data: {
          badgeCount: unreadCount.toString(),
        },
        apns: {
          payload: {
            aps: {
              badge: unreadCount,
            },
          },
        },
      };
      
      await admin.messaging().send(message);
      console.log(`✅ Badge count updated to ${unreadCount} for user: ${userId}`);
      
      return null;
    } catch (error) {
      console.error('❌ Error updating badge count:', error);
      return null;
    }
  });

// Send notification when a request is created
exports.onRequestCreated = functions.firestore
  .document('requests/{requestId}')
  .onCreate(async (snapshot, context) => {
    try {
      const request = snapshot.data();
      const { mentorId, requesterId, skillName, message } = request;
      
      // Get requester's name
      const requesterDoc = await admin.firestore()
        .collection('users')
        .doc(requesterId)
        .get();
      
      const requesterData = requesterDoc.data();
      const requesterName = `${requesterData.firstName || ''} ${requesterData.lastName || ''}`.trim();
      
      // Get mentor's FCM token
      const mentorDoc = await admin.firestore()
        .collection('users')
        .doc(mentorId)
        .get();
      
      const fcmToken = mentorDoc.data()?.fcmToken;
      
      if (!fcmToken) {
        console.log('No FCM token for mentor:', mentorId);
        return null;
      }
      
      // Create notification in Firestore
      await admin.firestore().collection('notifications').add({
        userId: mentorId,
        type: 'request_received',
        title: 'New Request',
        message: `${requesterName} wants to learn ${skillName} from you`,
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        relatedRequestId: context.params.requestId,
      });
      
      // Send push notification
      await admin.firestore().collection('pushNotifications').add({
        fcmToken: fcmToken,
        title: '🎓 New Learning Request',
        body: `${requesterName} wants to learn ${skillName} from you`,
        data: {
          type: 'request_received',
          requestId: context.params.requestId,
          skillName: skillName,
        },
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        status: 'pending',
      });
      
      console.log('✅ Request notification sent to mentor:', mentorId);
      return null;
    } catch (error) {
      console.error('❌ Error sending request notification:', error);
      return null;
    }
  });

// Send notification when request status changes
exports.onRequestStatusChanged = functions.firestore
  .document('requests/{requestId}')
  .onUpdate(async (change, context) => {
    try {
      const beforeData = change.before.data();
      const afterData = change.after.data();
      
      // Check if status changed
      if (beforeData.status === afterData.status) {
        return null;
      }
      
      const { requesterId, mentorId, skillName, status } = afterData;
      
      // Get mentor's name
      const mentorDoc = await admin.firestore()
        .collection('users')
        .doc(mentorId)
        .get();
      
      const mentorData = mentorDoc.data();
      const mentorName = `${mentorData.firstName || ''} ${mentorData.lastName || ''}`.trim();
      
      // Get requester's FCM token
      const requesterDoc = await admin.firestore()
        .collection('users')
        .doc(requesterId)
        .get();
      
      const fcmToken = requesterDoc.data()?.fcmToken;
      
      if (!fcmToken) {
        console.log('No FCM token for requester:', requesterId);
        return null;
      }
      
      let title = '';
      let body = '';
      let notificationType = '';
      
      if (status === 'accepted') {
        title = '✅ Request Accepted!';
        body = `${mentorName} accepted your request to learn ${skillName}`;
        notificationType = 'request_accepted';
      } else if (status === 'rejected') {
        title = '❌ Request Not Accepted';
        body = `Your request to learn ${skillName} was not accepted`;
        notificationType = 'request_rejected';
      } else if (status === 'completed') {
        title = '🎉 Session Completed!';
        body = `Your session for ${skillName} with ${mentorName} is complete`;
        notificationType = 'session_completed';
      } else {
        return null;
      }
      
      // Create notification in Firestore
      await admin.firestore().collection('notifications').add({
        userId: requesterId,
        type: notificationType,
        title: title,
        message: body,
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        relatedRequestId: context.params.requestId,
      });
      
      // Send push notification
      await admin.firestore().collection('pushNotifications').add({
        fcmToken: fcmToken,
        title: title,
        body: body,
        data: {
          type: notificationType,
          requestId: context.params.requestId,
          skillName: skillName,
        },
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        status: 'pending',
      });
      
      console.log(`✅ Status change notification sent to requester: ${requesterId}`);
      return null;
    } catch (error) {
      console.error('❌ Error sending status change notification:', error);
      return null;
    }
  });