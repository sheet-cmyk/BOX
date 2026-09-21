# Junior Boy Boxing

Production-oriented Firebase backend, Flutter Android app, Next.js public website/member portal, and Coach Sharif admin dashboard for Junior Boy Boxing in Tracy, California.

## Local verification

1. Install Node.js 22 and Java 17 or newer.
2. Run `npm install` in the root and `npm install` in `functions` and `web`.
3. Run `npm run test:emulators` from the root. This builds the functions and runs the Firestore/Storage security and concurrency tests against Firebase emulators.
4. Run `npm --prefix web run typecheck` and `npm --prefix web run build`.
5. From `mobile`, run `flutter pub get`, `flutter analyze`, and `flutter test`.

The local Firebase project is intentionally `demo-jbb`. It never contacts a real project. Seed local data with `npm run seed` while the Firestore emulator is running.

## Configure your project

Copy `mobile/config.example.json` into your own secure build configuration and add Firebase web/mobile settings through your normal CI secret store. Do not commit `google-services.json`, signing keys, Stripe secret keys, SendGrid keys, or service-account files.

For Functions, configure `GYM_TIMEZONE`, `EMAIL_FROM`, and the Firebase secrets `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, and optionally `SENDGRID_API_KEY`. Deploy the functions, rules, indexes, and hosting only after reviewing the generated configuration against your Firebase project.

Use `npm --prefix functions run admin -- coach@example.com` with authenticated application-default credentials to grant the first administrator. Add Stripe prices in Stripe separately; the Firestore plan price is checked against the PaymentIntent amount before credits are granted.

## External checks still required

Real Firebase Authentication providers, App Check attestation, Stripe webhook delivery, FCM delivery, SendGrid delivery, Google OAuth client IDs, Android release signing, Play Console review, a custom domain, and production monitoring require your accounts and secrets. The code has local validation for these paths but they cannot be honestly marked production-verified without your credentials and deployment environment.

## Structure

- `functions/`: callable functions, scheduled jobs, payment webhook, notification outbox, seed script, and tests.
- `mobile/`: Flutter app with Riverpod, GoRouter, Firebase services, Hive cache, FCM, Stripe PaymentSheet, and the dark red boxing design.
- `web/`: Next.js 14 static export with public marketing pages, member portal, Stripe Elements checkout, and responsive admin dashboard.
- `assets/`: provided Junior Boy Boxing visual assets and icons.
- `PROJECT_PROGRESS.md`: phase status and evidence log.
