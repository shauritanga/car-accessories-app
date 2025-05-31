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
