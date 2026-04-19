from firebase_config import db

db.collection("test").add({
    "message": "Firestore connected successfully"
})

print("Success")
