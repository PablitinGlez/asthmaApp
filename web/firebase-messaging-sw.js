importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-messaging.js");

firebase.initializeApp({
  apiKey: "AIzaSyBJZrPdsthquqgl49VJA8IGwUZLS3jvEpc",
  appId: "1:40445796906:web:51e7f4bcb33ee38a379953",
  messagingSenderId: "40445796906",
  projectId: "asthma-app-ed177",
  authDomain: "asthma-app-ed177.firebaseapp.com",
  storageBucket: "asthma-app-ed177.firebasestorage.app",
  measurementId: "G-V64KR8N5NG"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log("[firebase-messaging-sw.js] Received background message ", payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: "/favicon.png"
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});
