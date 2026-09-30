# Firestore Schema

## users/{userId}

```text
name: string
phone: string
email: string
createdAt: timestamp
updatedAt: timestamp
rating: number
```

## drivers/{driverId}

```text
name: string
phone: string
vehicleType: string
vehicleNumber: string
latitude: number
longitude: number
status: available | busy | offline
rating: number
```

## bookings/{bookingId}

```text
userId: string
driverId: string | null
vehicleType: string
pickup: {
  address: string
  latitude: number
  longitude: number
}
destination: {
  address: string
  latitude: number
  longitude: number
}
distance: number | null
estimatedPrice: number
finalPrice: number | null
completionInteraction: {
  screen: string
  completionButton: string
  lastButtonBeforeCompletion: string | null
  screenDurationMs: number
  screenDurationSeconds: number
  buttonClickedAt: string
} | null
status: requested | accepted | driver_arriving | in_progress | completed | cancelled
createdAt: timestamp
updatedAt: timestamp
```

## food_orders/{orderId}

```text
userId: string | null
deliveryAddress: string
restaurant: string
items: array
subtotal: number
shippingFee: number
voucherCode: string | null
discountAmount: number
totalPrice: number
estimatedTime: string
completionInteraction: {
  screen: string
  completionButton: string
  lastButtonBeforeCompletion: string | null
  screenDurationMs: number
  screenDurationSeconds: number
  buttonClickedAt: string
} | null
status: requested | accepted | preparing | delivering | completed | cancelled
createdAt: timestamp
updatedAt: timestamp
```

## trips/{tripId}

```text
bookingId: string
startedAt: timestamp
completedAt: timestamp | null
distance: number
duration: number
price: number
```

## event_logs/{eventId}

Dung cho analytics chi tiet hon Firebase Analytics khi can debug hanh vi app.

```text
eventName: string
userId: string | null
bookingId: string | null
time_step: number
location: {
  address: string
  latitude: number
  longitude: number
} | null
device: string
screen: string
metadata: map
createdAt: timestamp
```

## Goi y collection co the them sau

```text
payments/{paymentId}
promotions/{promotionId}
support_tickets/{ticketId}
driver_locations/{driverId}/points/{pointId}
user_notifications/{notificationId}
```
