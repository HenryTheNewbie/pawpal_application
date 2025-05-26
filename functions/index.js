const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// Work in Progress!

exports.sendChatNotification = functions.database
  .ref('/conversations/{conversationId}/messages/{messageId}')
  .onCreate(async (snapshot, context) => {
    const message = snapshot.val();
    const { sender, text } = message;

    const conversationId = context.params.conversationId;

    const convSnapshot = await admin.database().ref(`conversations/${conversationId}/participants`).once('value');
    const participants = convSnapshot.val();

    const recipient = participants.find(p => p !== sender);
    const userSnapshot = await admin.database().ref(`users`).orderByChild('email').equalTo(recipient).once('value');

    if (!userSnapshot.exists()) return null;

    const recipientUid = Object.keys(userSnapshot.val())[0];
    const recipientData = userSnapshot.val()[recipientUid];

    const token = recipientData.fcmToken;
    if (!token) return null;

    const payload = {
      notification: {
        title: 'New Message',
        body: text,
      },
      token,
    };

    return admin.messaging().send(payload);
  });