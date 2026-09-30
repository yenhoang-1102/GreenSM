# ride_booking_app

A new Flutter project.

## Map setup

The app uses `flutter_map` with OpenStreetMap tiles, Nominatim for address
search, and `geolocator` for the device location. These features do not need a
Google Maps API key.

Driving routes use openrouteservice. Create a free API key, then paste it into
the local `.env` file:

```dotenv
OPENROUTESERVICE_API_KEY=YOUR_KEY
```

The `.env` file is ignored by Git. Run the app normally with `flutter run` or
build it with `flutter build apk --debug`.

Without an openrouteservice key, the map and address search still work, and the
app draws a direct fallback line between pickup and destination.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
