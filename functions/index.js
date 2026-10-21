// OPTIONAL: push notifications + housekeeping. Needs the Firebase Blaze plan.
const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

async function pushToUser(uid, title, body, data = {}) {
  const snap = await db.doc(`users/${uid}`).get();
  const token = snap.data() && snap.data().fcmToken;
  if (!token) return;
  try {
    await admin.messaging().send({ token, notification: { title, body }, data });
  } catch (e) {
    console.log('push failed', e.message);
  }
}

// Farmer gets notified about a new order.
exports.onOrderCreated = onDocumentCreated('orders/{id}', (event) => {
  const o = event.data.data();
  return pushToUser(o.farmerUid, 'New order received',
    `${o.customerName} ordered ${o.items.length} item(s) - Rs ${o.total}`,
    { orderId: event.params.id });
});

// Customer (or farmer, on cancellation) gets notified when status changes.
exports.onOrderStatusChanged = onDocumentUpdated('orders/{id}', (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();
  if (before.status === after.status) return null;
  const labels = {
    accepted: 'accepted your order', rejected: 'could not accept your order',
    packed: 'packed your order', out_for_delivery: 'sent your order out for delivery',
    delivered: 'marked your order as delivered',
  };
  if (after.status === 'cancelled') {
    return pushToUser(after.farmerUid, 'Order cancelled', `${after.customerName} cancelled an order`,
      { orderId: event.params.id });
  }
  const text = labels[after.status];
  if (!text) return null;
  return pushToUser(after.customerUid, 'Order update', `${after.farmName} ${text}`,
    { orderId: event.params.id });
});

// Harvest alerts are broadcast to everyone following the farm.
exports.onHarvestAlertCreated = onDocumentCreated('harvestAlerts/{id}', async (event) => {
  const a = event.data.data();
  await admin.messaging().send({
    topic: `farm_${a.farmerUid}`,
    notification: { title: `${a.farmName}: ${a.title}`, body: a.message },
    data: { farmId: a.farmerUid },
  });
});

// Hide products that passed their shelf life.
exports.expireOldProducts = onSchedule('every day 02:00', async () => {
  const snap = await db.collection('products').where('isAvailable', '==', true).get();
  const now = Date.now();
  const batch = db.batch();
  snap.forEach((d) => {
    const p = d.data();
    if (!p.harvestDate || p.isPreOrder) return;
    const expires = p.harvestDate.toMillis() + p.shelfLifeDays * 86400000;
    if (expires < now) batch.update(d.ref, { isAvailable: false });
  });
  await batch.commit();
});
