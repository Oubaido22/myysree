/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const { onRequest } = require('firebase-functions/v2/https');

const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.deleteExpiredStories = functions.pubsub
    .schedule('every 1 hours') // adjust frequency as needed
    .timeZone('UTC')
    .onRun(async (context) => {
        const now = admin.firestore.Timestamp.now();
        const expirationTime = now.toMillis() - (24 * 60 * 60 * 1000); // 24 hours in milliseconds

        const expiredStoriesQuerySnapshot = await admin.firestore()
            .collection('statuses')
            .where('createdAt', '<=', new admin.firestore.Timestamp(expirationTime / 1000, 0))
            .get();

        const deletePromises = expiredStoriesQuerySnapshot.docs.map((doc) => doc.ref.delete());
        await Promise.all(deletePromises);

        console.log('Expired stories deleted successfully.');

        return null;
    });
