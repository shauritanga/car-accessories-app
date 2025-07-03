const functions = require("firebase-functions/v1/auth");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
admin.initializeApp();

exports.addProduct = onDocumentCreated("products/{productId}", (event) => {
  const newProduct = event.data.data(); // Get the data of the newly created document.
  console.log("New product created:", newProduct);
  // You can process the data or trigger other actions here.
  return null;
});

exports.userCreated = functions.user().onCreate((user) => {
  console.log("New user created:", user.uid);
  return null;
});

exports.userDeleted = functions.user().onDelete((user) => {
  console.log("User deleted:", user.uid);
  return null;
});

// Push notification to seller on new order
const functionsV1 = require('firebase-functions');
exports.notifySellerOfNewOrder = functionsV1.firestore
  .document('orders/{orderId}')
  .onCreate(async (snap, context) => {
    const order = snap.data();
    const sellerId = order.sellerId;
    if (!sellerId) return null;

    // Get seller's FCM token
    const sellerDoc = await admin.firestore().collection('users').doc(sellerId).get();
    const fcmToken = sellerDoc.get('fcmToken');
    if (!fcmToken) return null;

    // Compose notification
    const payload = {
      notification: {
        title: 'New Order!',
        body: `You have received a new order (#${context.params.orderId}).`,
      },
      data: {
        orderId: context.params.orderId,
      },
    };

    // Send notification
    return admin.messaging().sendToDevice(fcmToken, payload);
  });

// Push notification to recipient on new chat message
exports.notifyUserOfNewMessage = functionsV1.firestore
  .document('conversations/{conversationId}/messages/{messageId}')
  .onCreate(async (snap, context) => {
    const message = snap.data();
    if (!message) return null;
    const receiverId = message.receiverId;
    const senderId = message.senderId;
    const content = message.content;

    // Get receiver's FCM token
    const receiverDoc = await admin.firestore().collection('users').doc(receiverId).get();
    const fcmToken = receiverDoc.get('fcmToken');
    if (!fcmToken) return null;

    // Get sender's name
    const senderDoc = await admin.firestore().collection('users').doc(senderId).get();
    const senderName = senderDoc.get('name') || 'Someone';

    // Compose notification
    const payload = {
      notification: {
        title: `New message from ${senderName}`,
        body: content,
      },
      data: {
        conversationId: context.params.conversationId,
        senderId,
      },
    };

    // Send notification
    return admin.messaging().sendToDevice(fcmToken, payload);
  });
