/// App-wide constants.
library;

/// Firebase Storage needs the paid Blaze plan, so it stays switched off.
/// When false, photos are stored as compressed base64 strings in Firestore.
const bool useFirebaseStorage = false;
