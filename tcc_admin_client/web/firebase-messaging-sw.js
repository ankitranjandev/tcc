importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js');

// Initialize the Firebase app in the service worker by passing the generated config
firebase.initializeApp({
  apiKey: "AIzaSyCXGqJqXrjQJGQMQtDbk2IeIFzQrB7P0Ko",
  authDomain: "tcc-app-ebb14.firebaseapp.com",
  projectId: "tcc-app-ebb14",
  storageBucket: "tcc-app-ebb14.firebasestorage.app",
  messagingSenderId: "545764390154",
  appId: "1:545764390154:web:533ebfdec3f5fdb9d4f6f3"
});

// Retrieve firebase messaging
const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icons/Icon-192.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});