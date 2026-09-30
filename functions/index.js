const {onRequest} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");

initializeApp();

const powerBiApiKey = defineSecret("POWER_BI_API_KEY");
const db = getFirestore();

const timestamp = (value) =>
  value && typeof value.toDate === "function"
    ? value.toDate().toISOString()
    : null;

exports.powerBiAnalytics = onRequest(
  {
    region: "asia-southeast1",
    secrets: [powerBiApiKey],
    maxInstances: 2,
  },
  async (request, response) => {
    if (request.method !== "GET") {
      response.status(405).json({error: "Method not allowed"});
      return;
    }

    if (request.query.api_key !== powerBiApiKey.value()) {
      response.status(401).json({error: "Unauthorized"});
      return;
    }

    try {
      const [bookingSnapshot, foodSnapshot, eventSnapshot] =
        await Promise.all([
          db.collection("bookings").limit(25000).get(),
          db.collection("food_orders").limit(25000).get(),
          db.collection("event_logs").limit(25000).get(),
        ]);

      const bookings = bookingSnapshot.docs.map((document) => {
        const data = document.data();
        return {
          bookingId: document.id,
          userId: data.userId ?? null,
          vehicleType: data.vehicleType ?? null,
          pickupAddress: data.pickup?.address ?? null,
          pickupLatitude: data.pickup?.latitude ?? null,
          pickupLongitude: data.pickup?.longitude ?? null,
          destinationAddress: data.destination?.address ?? null,
          distanceKm: data.distance ?? null,
          estimatedDuration: data.estimatedDuration ?? null,
          estimatedPrice: data.estimatedPrice ?? 0,
          discountAmount: data.discountAmount ?? 0,
          finalPrice: data.finalPrice ?? 0,
          voucherCode: data.voucherCode ?? null,
          status: data.status ?? null,
          completionButton:
              data.completionInteraction?.completionButton ?? null,
          lastButtonBeforeCompletion:
              data.completionInteraction?.lastButtonBeforeCompletion ?? null,
          screenDurationSeconds:
              data.completionInteraction?.screenDurationSeconds ?? null,
          createdAt: timestamp(data.createdAt),
        };
      });

      const foodOrders = foodSnapshot.docs.map((document) => {
        const data = document.data();
        return {
          orderId: document.id,
          userId: data.userId ?? null,
          restaurant: data.restaurant ?? null,
          deliveryAddress: data.deliveryAddress ?? null,
          subtotal: data.subtotal ?? 0,
          shippingFee: data.shippingFee ?? 0,
          discountAmount: data.discountAmount ?? 0,
          totalPrice: data.totalPrice ?? 0,
          voucherCode: data.voucherCode ?? null,
          status: data.status ?? null,
          screenDurationSeconds:
              data.completionInteraction?.screenDurationSeconds ?? null,
          createdAt: timestamp(data.createdAt),
        };
      });

      const eventLogs = eventSnapshot.docs.map((document) => {
        const data = document.data();
        const metadata = data.metadata ?? {};
        const completion = metadata.completionInteraction ?? {};

        return {
          eventId: document.id,
          eventName: data.eventName ?? null,
          userId: data.userId ?? null,
          bookingId: data.bookingId ?? null,
          screen: data.screen ?? null,
          device: data.device ?? null,
          timeStep: data.time_step ?? data.timeStep ?? null,
          createdAt: timestamp(data.createdAt),
          locationAddress: data.location?.address ?? null,
          locationLatitude: data.location?.latitude ?? null,
          locationLongitude: data.location?.longitude ?? null,
          service: metadata.service ?? null,
          vehicleName: metadata.vehicleName ?? null,
          vehiclePrice: metadata.vehiclePrice ?? null,
          voucherCode: metadata.voucherCode ?? null,
          discountAmount: metadata.discountAmount ?? null,
          finalPrice: metadata.finalPrice ?? null,
          restaurant: metadata.restaurant ?? null,
          itemName: metadata.itemName ?? null,
          category: metadata.category ?? null,
          quantity: metadata.quantity ?? null,
          totalPrice: metadata.totalPrice ?? null,
          rating: metadata.rating ?? null,
          completionButton: completion.completionButton ?? null,
          lastButtonBeforeCompletion:
              completion.lastButtonBeforeCompletion ?? null,
          screenDurationSeconds: completion.screenDurationSeconds ?? null,
        };
      });

      response.set("Cache-Control", "private, max-age=300");
      response.json({bookings, foodOrders, eventLogs});
    } catch (error) {
      console.error(error);
      response.status(500).json({error: "Cannot load analytics data"});
    }
  },
);
