process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8081";
process.env.FIREBASE_AUTH_EMULATOR_HOST = "127.0.0.1:9099";
process.env.GCLOUD_PROJECT = "ride-booking-app-e2eb0";

const {initializeApp} = require("firebase-admin/app");
const {getAuth} = require("firebase-admin/auth");
const {FieldValue, getFirestore, Timestamp} = require("firebase-admin/firestore");

initializeApp({projectId: "ride-booking-app-e2eb0"});

const auth = getAuth();
const db = getFirestore();
const email = "powerbi.demo@example.com";
const password = "Demo123456!";

function sample(values, index) {
  return values[index % values.length];
}

async function commitInChunks(writes) {
  const chunks = [];
  for (let start = 0; start < writes.length; start += 450) {
    chunks.push(writes.slice(start, start + 450));
  }

  let nextChunk = 0;
  async function worker() {
    while (nextChunk < chunks.length) {
      const chunkIndex = nextChunk++;
      const batch = db.batch();
      for (const write of chunks[chunkIndex]) {
        batch.set(write.ref, write.data);
      }
      await batch.commit();
      if ((chunkIndex + 1) % 10 === 0 || chunkIndex + 1 === chunks.length) {
        console.log(`Committed ${chunkIndex + 1}/${chunks.length} batches.`);
      }
    }
  }

  await Promise.all(Array.from({length: 8}, () => worker()));
}

async function seedAnalyticsData(userId, now) {
  const writes = [];
  const bookingCount = 17500;
  const foodOrderCount = 12500;
  const eventCount = 20000;
  const day = 86400000;
  const vehicles = ["Green Bike", "Green Car", "Green Premium"];
  const rideStatuses = ["completed", "completed", "completed", "cancelled"];
  const pickups = [
    ["TechnoPark Tower, Vinhomes Ocean Park", 20.9947, 105.9434],
    ["VinUniversity, Gia Lam, Ha Noi", 20.9931, 105.9459],
    ["Times City, Hai Ba Trung, Ha Noi", 20.9959, 105.8681],
    ["Ho Guom, Hoan Kiem, Ha Noi", 21.0287, 105.8524],
  ];
  const destinations = [
    "Royal City, Thanh Xuan, Ha Noi",
    "Aeon Mall Long Bien, Ha Noi",
    "Pho co Ha Noi, Hoan Kiem",
    "Ben xe Gia Lam, Ha Noi",
  ];
  const restaurants = ["Bep Viet", "Pho Thin", "Com Tam Sai Gon", "Bun Cha Ha Noi"];
  const foodStatuses = ["completed", "completed", "completed", "cancelled"];

  for (let i = 0; i < bookingCount; i++) {
    const id = `bulk-booking-${String(i + 1).padStart(4, "0")}`;
    const vehicle = sample(vehicles, i);
    const pickup = sample(pickups, i);
    const distance = Number((2.5 + (i % 25) * 0.7).toFixed(1));
    const basePrice = vehicle === "Green Bike" ? 12000 :
      vehicle === "Green Car" ? 32000 : 45000;
    const estimatedPrice = basePrice + Math.round(distance * 6500);
    const discountAmount = i % 4 === 0 ? Math.min(20000, estimatedPrice) : 0;
    const duration = 15 + (i * 7) % 106;
    const createdAt = now - ((i % 90) * day) - ((i * 137) % day);
    writes.push({
      ref: db.collection("bookings").doc(id),
      data: {
        bookingId: id,
        userId,
        driverId: `demo-driver-${String((i % 30) + 1).padStart(2, "0")}`,
        vehicleType: vehicle,
        pickup: {address: pickup[0], latitude: pickup[1], longitude: pickup[2]},
        destination: {address: sample(destinations, i), latitude: 21.02, longitude: 105.86},
        distance,
        estimatedDuration: 8 + (i % 38),
        estimatedPrice,
        voucherCode: discountAmount ? "RIDE20" : null,
        discountAmount,
        finalPrice: estimatedPrice - discountAmount,
        status: sample(rideStatuses, i),
        completionInteraction: {
          screen: "booking_confirmation_screen",
          completionButton: "Dat xe",
          lastButtonBeforeCompletion: `Chon xe: ${vehicle}`,
          screenDurationMs: duration * 1000,
          screenDurationSeconds: duration,
          buttonClickedAt: new Date(createdAt).toISOString(),
        },
        createdAt: Timestamp.fromMillis(createdAt),
        updatedAt: Timestamp.fromMillis(createdAt + 1800000),
      },
    });
  }

  for (let i = 0; i < foodOrderCount; i++) {
    const id = `bulk-food-${String(i + 1).padStart(4, "0")}`;
    const subtotal = 45000 + (i % 8) * 15000;
    const shippingFee = 12000 + (i % 5) * 3000;
    const discountAmount = i % 3 === 0 ? 15000 : 0;
    const duration = 18 + (i * 11) % 123;
    const createdAt = now - ((i % 90) * day) - ((i * 211) % day);
    writes.push({
      ref: db.collection("food_orders").doc(id),
      data: {
        orderId: id,
        userId,
        restaurant: sample(restaurants, i),
        deliveryAddress: sample(pickups, i)[0],
        subtotal,
        shippingFee,
        voucherCode: discountAmount ? "FOOD15" : null,
        discountAmount,
        totalPrice: subtotal + shippingFee - discountAmount,
        status: sample(foodStatuses, i),
        completionInteraction: {
          screen: "food_order_confirmation_screen",
          completionButton: "Dat don",
          lastButtonBeforeCompletion: discountAmount ? "Chon voucher: FOOD15" : "Xem gio hang",
          screenDurationMs: duration * 1000,
          screenDurationSeconds: duration,
          buttonClickedAt: new Date(createdAt).toISOString(),
        },
        createdAt: Timestamp.fromMillis(createdAt),
        updatedAt: Timestamp.fromMillis(createdAt + 2400000),
      },
    });
  }

  const eventNames = ["screen_view", "button_clicked", "booking_created", "food_order_created"];
  for (let i = 0; i < eventCount; i++) {
    const id = `bulk-event-${String(i + 1).padStart(4, "0")}`;
    const service = i % 2 === 0 ? "ride" : "food";
    const duration = 10 + (i * 13) % 171;
    const createdAt = now - ((i % 90) * day) - ((i * 173) % day);
    writes.push({
      ref: db.collection("event_logs").doc(id),
      data: {
        eventName: sample(eventNames, i),
        screen: service === "ride" ? "booking_confirmation_screen" : "food_order_screen",
        device: sample(["android", "ios", "web"], i),
        time_step: createdAt,
        userId,
        bookingId: service === "ride"
          ? `bulk-booking-${String((i % bookingCount) + 1).padStart(4, "0")}`
          : `bulk-food-${String((i % foodOrderCount) + 1).padStart(4, "0")}`,
        location: null,
        metadata: {
          service,
          vehicleName: service === "ride" ? sample(vehicles, i) : null,
          restaurant: service === "food" ? sample(restaurants, i) : null,
          completionInteraction: {
            screenDurationSeconds: duration,
            completionButton: service === "ride" ? "Dat xe" : "Dat don",
          },
        },
        createdAt: Timestamp.fromMillis(createdAt),
      },
    });
  }

  await commitInChunks(writes);
  return writes.length;
}

async function getOrCreateUser() {
  try {
    return await auth.getUserByEmail(email);
  } catch (error) {
    if (error.code !== "auth/user-not-found") throw error;
    return auth.createUser({
      email,
      password,
      displayName: "Power BI Demo",
      emailVerified: true,
    });
  }
}

async function seed() {
  const user = await getOrCreateUser();
  const now = Date.now();

  await db.collection("users").doc(user.uid).set({
    email,
    name: "Power BI Demo",
    createdAt: Timestamp.fromMillis(now - 86400000 * 3),
    updatedAt: FieldValue.serverTimestamp(),
  }, {merge: true});

  await db.collection("bookings").doc("demo-booking-completed").set({
    bookingId: "demo-booking-completed",
    userId: user.uid,
    driverId: "demo-driver-01",
    vehicleType: "Green Car",
    pickup: {
      address: "TechnoPark Tower, Vinhomes Ocean Park",
      latitude: 20.9947,
      longitude: 105.9434,
    },
    destination: {
      address: "Times City, Hai Ba Trung, Ha Noi",
      latitude: 20.9959,
      longitude: 105.8681,
    },
    distance: 13.9,
    estimatedDuration: 23,
    estimatedPrice: 137000,
    voucherCode: "RIDE20",
    discountAmount: 20000,
    finalPrice: 117000,
    pickupNote: "Don tai cong chinh",
    status: "completed",
    completionInteraction: {
      screen: "booking_confirmation_screen",
      completionButton: "Dat xe",
      lastButtonBeforeCompletion: "Chon xe: Green Car",
      screenDurationMs: 42000,
      screenDurationSeconds: 42,
      buttonClickedAt: new Date(now - 86400000).toISOString(),
    },
    createdAt: Timestamp.fromMillis(now - 86400000),
    updatedAt: Timestamp.fromMillis(now - 82800000),
  });

  await db.collection("bookings").doc("demo-booking-requested").set({
    bookingId: "demo-booking-requested",
    userId: user.uid,
    driverId: null,
    vehicleType: "Green Bike",
    pickup: {
      address: "Dai hoc Khoa hoc Tu nhien, Ha Noi",
      latitude: 21.0378,
      longitude: 105.7812,
    },
    destination: {
      address: "Ho Guom, Hoan Kiem, Ha Noi",
      latitude: 21.0287,
      longitude: 105.8524,
    },
    distance: 8.4,
    estimatedDuration: 19,
    estimatedPrice: 35200,
    voucherCode: null,
    discountAmount: 0,
    finalPrice: 35200,
    status: "requested",
    completionInteraction: {
      screen: "booking_confirmation_screen",
      completionButton: "Dat xe",
      lastButtonBeforeCompletion: "Chon xe: Green Bike",
      screenDurationMs: 27000,
      screenDurationSeconds: 27,
      buttonClickedAt: new Date(now - 3600000).toISOString(),
    },
    createdAt: Timestamp.fromMillis(now - 3600000),
    updatedAt: Timestamp.fromMillis(now - 3600000),
  });

  await db.collection("food_orders").doc("demo-food-completed").set({
    orderId: "demo-food-completed",
    userId: user.uid,
    restaurant: "Bep Viet",
    deliveryAddress: "TechnoPark Tower, Vinhomes Ocean Park",
    items: [
      {
        id: "com-ga",
        name: "Com ga nuong",
        restaurant: "Bep Viet",
        category: "Com",
        price: 55000,
        quantity: 2,
      },
    ],
    subtotal: 110000,
    deliveryDistanceKm: 3.2,
    shippingFee: 16000,
    voucherCode: "FOOD15",
    discountAmount: 15000,
    totalPrice: 111000,
    estimatedTime: "30-35 phut",
    status: "completed",
    completionInteraction: {
      screen: "food_order_confirmation_screen",
      completionButton: "Dat don - 111.000d",
      lastButtonBeforeCompletion: "Chon voucher: FOOD15",
      screenDurationMs: 51000,
      screenDurationSeconds: 51,
      buttonClickedAt: new Date(now - 86400000 * 2).toISOString(),
    },
    createdAt: Timestamp.fromMillis(now - 86400000 * 2),
    updatedAt: Timestamp.fromMillis(now - 86400000 * 2 + 2400000),
  });

  const events = [
    ["demo-event-ride", "booking_created", "ride", "demo-booking-completed", 42],
    ["demo-event-bike", "booking_created", "ride", "demo-booking-requested", 27],
    ["demo-event-food", "food_order_created", "food", "demo-food-completed", 51],
  ];

  for (const [id, eventName, service, bookingId, duration] of events) {
    await db.collection("event_logs").doc(id).set({
      eventName,
      screen: service === "ride"
        ? "booking_confirmation_screen"
        : "food_order_screen",
      device: "web",
      time_step: now - duration * 1000,
      userId: user.uid,
      bookingId,
      location: null,
      metadata: {
        service,
        completionInteraction: {
          screenDurationSeconds: duration,
          completionButton: service === "ride" ? "Dat xe" : "Dat don",
        },
      },
      createdAt: Timestamp.fromMillis(now - duration * 1000),
    });
  }

  const analyticsCount = await seedAnalyticsData(user.uid, now);

  console.log(`Seeded emulator data for ${email} (${user.uid}).`);
  console.log(`Seeded ${analyticsCount} analytics documents.`);
  console.log(`Password: ${password}`);
}

seed().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
