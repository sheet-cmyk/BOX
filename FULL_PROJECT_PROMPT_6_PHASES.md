# MASTER PROMPT — Build "Junior Boy Boxing" Complete Production System
# Website + Android App + Admin Dashboard + Backend — 6 Phases

---

> **IMPORTANT**: I am building a REAL production application for a boxing gym called "Junior Boy Boxing" located at 3200 Naglee Rd, Tracy, CA. This is NOT a prototype — it must be production-ready, secure, scalable, and professional. I have UI mockup screenshots that I will attach showing exactly how the app should look. Replicate the design PIXEL-PERFECT.

---

# ══════════════════════════════════════════════════════════
# PHASE 1 OF 6 — BACKEND & DATABASE (Firebase)
# ══════════════════════════════════════════════════════════

## Objective
Set up the complete Firebase backend that powers both the Android app AND the website. Everything starts here — no frontend without a solid backend.

## Tech Stack
- **Firebase Authentication** (Email/Password + Google Sign-In + Phone OTP)
- **Cloud Firestore** (main database)
- **Firebase Cloud Functions** (Node.js / TypeScript)
- **Firebase Cloud Messaging** (push notifications)
- **Firebase Storage** (profile images, gym photos)
- **Firebase Hosting** (for the website later)

## Firestore Database Schema

Design and create these collections with proper security rules:

### Collection: `users`
```
users/{userId}
├── fullName: string
├── email: string
├── phone: string
├── role: string           // "member" | "admin" | "coach"
├── childName: string      // (for parents registering kids)
├── childAge: number
├── avatarUrl: string
├── membershipPlanId: string | null
├── sessionsRemaining: number
├── memberSince: timestamp
├── isActive: boolean
├── fcmToken: string       // for push notifications
├── createdAt: timestamp
└── updatedAt: timestamp
```

### Collection: `classes`
```
classes/{classId}
├── className: string           // "Junior Boxing", "Group Training"
├── description: string
├── ageGroup: string            // "Ages 8-14", "Ages 14+"
├── coachName: string           // "Coach Sharif"
├── maxSpots: number
├── durationMinutes: number     // 60
├── location: string            // "Junior Boy Boxing"
├── address: string             // "3200 Naglee Rd, Tracy, CA"
├── imageUrl: string
├── isActive: boolean
└── createdAt: timestamp
```

### Collection: `schedule`
```
schedule/{scheduleId}
├── classId: string (ref → classes)
├── date: timestamp             // specific date
├── dayOfWeek: string           // "monday", "tuesday"...
├── startTime: string           // "16:00"
├── endTime: string             // "17:00"
├── maxSpots: number
├── bookedSpots: number
├── isRecurring: boolean        // weekly repeat
├── recurringDayOfWeek: number  // 0=Sun, 1=Mon...
├── isCancelled: boolean
└── createdAt: timestamp
```

### Collection: `bookings`
```
bookings/{bookingId}
├── userId: string (ref → users)
├── scheduleId: string (ref → schedule)
├── classId: string (ref → classes)
├── className: string          // denormalized for quick reads
├── date: timestamp
├── startTime: string
├── endTime: string
├── status: string             // "confirmed" | "cancelled" | "completed" | "no-show"
├── bookedAt: timestamp
├── cancelledAt: timestamp | null
└── cancelReason: string | null
```

### Collection: `membershipPlans`
```
membershipPlans/{planId}
├── name: string               // "Single Session", "5 Session Pack"...
├── description: string
├── price: number              // in cents: 8000 = $80.00
├── priceLabel: string         // "$80"
├── perSessionLabel: string    // "$70 / session"
├── sessionCount: number | null // null for hourly plans
├── planType: string           // "package" | "hourly"
├── isRecommended: boolean
├── sortOrder: number
├── isActive: boolean
└── createdAt: timestamp
```

### Collection: `payments`
```
payments/{paymentId}
├── userId: string
├── membershipPlanId: string
├── amount: number             // in cents
├── currency: string           // "usd"
├── status: string             // "pending" | "completed" | "failed" | "refunded"
├── paymentMethod: string      // "stripe" | "cash" | "manual"
├── stripePaymentIntentId: string | null
├── receiptUrl: string | null
├── createdAt: timestamp
└── updatedAt: timestamp
```

### Collection: `notifications`
```
notifications/{notifId}
├── userId: string
├── title: string
├── body: string
├── type: string               // "booking_confirmed" | "class_reminder" | "membership_expiring" | "announcement"
├── data: map                  // additional payload
├── isRead: boolean
├── createdAt: timestamp
```

### Collection: `gymSettings` (single document)
```
gymSettings/config
├── gymName: string
├── address: string
├── phone: string
├── email: string
├── coachName: string
├── operatingHours: map
├── socialLinks: map { instagram, facebook, tiktok }
├── aboutText: string
├── cancellationPolicyHours: number  // e.g. 24 = cancel up to 24h before
└── updatedAt: timestamp
```

## Firestore Security Rules
Write COMPLETE security rules:
- Members can read their own data, read schedule/classes (public), create bookings, read their own bookings/payments
- Admins can read/write everything
- No unauthenticated access except reading `gymSettings` and `membershipPlans` (for the public website)
- Users cannot modify other users' data
- Booking creation must validate: user is authenticated, class has available spots, no double-booking same time slot

## Cloud Functions to Build

### Auth Triggers
1. `onUserCreated` — When a new user signs up: create their Firestore user doc, send welcome email
2. `onUserDeleted` — Clean up user data

### Booking Functions
3. `createBooking` (callable) — Validates spots available (ATOMIC transaction to prevent overbooking), decrements available spots, creates booking doc, sends confirmation push notification
4. `cancelBooking` (callable) — Validates cancellation policy (24h before), increments available spots, updates booking status, sends cancellation confirmation
5. `markBookingCompleted` (callable, admin only) — Mark attendance after class

### Schedule Functions
6. `generateWeeklySchedule` (scheduled, runs every Sunday) — Auto-generates next week's schedule from recurring class templates
7. `sendClassReminders` (scheduled, runs hourly) — Send push notifications 1 hour before class to booked users

### Membership Functions
8. `purchaseMembership` (callable) — Process payment (Stripe integration placeholder), assign plan to user, set session count
9. `deductSession` (trigger on booking completion) — Decrement user's remaining sessions

### Admin Functions
10. `getDashboardStats` (callable, admin only) — Return: total members, bookings today, revenue this month, popular classes
11. `exportBookingsCSV` (callable, admin only) — Export bookings data

## Deliverables for Phase 1
- [ ] Firebase project configuration files
- [ ] Complete `firestore.rules`
- [ ] Complete `firestore.indexes.json`
- [ ] All Cloud Functions in TypeScript (`functions/src/index.ts` + organized modules)
- [ ] Seed script to populate initial data (classes, schedule, membership plans, gym settings)
- [ ] `firebase.json` configuration
- [ ] README with setup instructions

**Generate every file completely. Do not skip any function. Do not leave TODO comments.**

---

# ══════════════════════════════════════════════════════════
# PHASE 2 OF 6 — ANDROID APP (Flutter)
# ══════════════════════════════════════════════════════════

## Objective
Build the complete Android app in Flutter, connected to the Firebase backend from Phase 1. The app must look EXACTLY like the attached UI mockup screenshots.

## Tech Stack
- **Flutter** (latest stable)
- **State Management**: Riverpod
- **Navigation**: GoRouter with ShellRoute for bottom nav
- **Firebase**: firebase_core, firebase_auth, cloud_firestore, firebase_messaging, firebase_storage
- **Payments**: stripe_sdk (or flutter_stripe)
- **Local Cache**: Hive (offline support)
- **Other**: google_fonts (Oswald + Roboto), cached_network_image, shimmer, flutter_svg, intl (date formatting), url_launcher

## Architecture
```
lib/
├── core/
│   ├── theme/
│   │   ├── app_colors.dart
│   │   ├── app_text_styles.dart
│   │   └── app_theme.dart
│   ├── router/
│   │   └── app_router.dart
│   ├── constants/
│   │   ├── app_strings.dart
│   │   └── app_assets.dart
│   ├── utils/
│   │   ├── date_utils.dart
│   │   ├── validators.dart
│   │   └── snackbar_utils.dart
│   └── widgets/
│       ├── jbb_bottom_nav.dart
│       ├── jbb_button.dart
│       ├── jbb_card.dart
│       ├── jbb_loading.dart
│       ├── jbb_empty_state.dart
│       └── jbb_class_card.dart
├── features/
│   ├── auth/
│   │   ├── screens/
│   │   │   ├── welcome_screen.dart
│   │   │   ├── sign_in_screen.dart
│   │   │   └── sign_up_screen.dart
│   │   ├── providers/
│   │   │   └── auth_provider.dart
│   │   └── widgets/
│   ├── home/
│   │   ├── screens/
│   │   │   └── home_screen.dart
│   │   ├── providers/
│   │   │   └── home_provider.dart
│   │   └── widgets/
│   │       ├── welcome_header.dart
│   │       ├── next_session_card.dart
│   │       ├── quick_actions_grid.dart
│   │       └── programs_section.dart
│   ├── schedule/
│   │   ├── screens/
│   │   │   └── schedule_screen.dart
│   │   ├── providers/
│   │   │   └── schedule_provider.dart
│   │   └── widgets/
│   │       ├── month_navigator.dart
│   │       ├── day_selector.dart
│   │       └── class_list_card.dart
│   ├── booking/
│   │   ├── screens/
│   │   │   ├── book_class_screen.dart
│   │   │   └── booking_confirmation_screen.dart
│   │   ├── providers/
│   │   │   └── booking_provider.dart
│   │   └── widgets/
│   ├── membership/
│   │   ├── screens/
│   │   │   └── membership_screen.dart
│   │   ├── providers/
│   │   │   └── membership_provider.dart
│   │   └── widgets/
│   │       └── plan_card.dart
│   └── profile/
│       ├── screens/
│       │   ├── more_screen.dart
│       │   ├── edit_profile_screen.dart
│       │   ├── my_bookings_screen.dart
│       │   ├── notifications_screen.dart
│       │   └── contact_screen.dart
│       ├── providers/
│       │   └── profile_provider.dart
│       └── widgets/
├── data/
│   ├── models/
│   │   ├── user_model.dart
│   │   ├── class_model.dart
│   │   ├── schedule_model.dart
│   │   ├── booking_model.dart
│   │   ├── membership_plan_model.dart
│   │   ├── payment_model.dart
│   │   └── notification_model.dart
│   ├── repositories/
│   │   ├── auth_repository.dart
│   │   ├── schedule_repository.dart
│   │   ├── booking_repository.dart
│   │   ├── membership_repository.dart
│   │   ├── notification_repository.dart
│   │   └── user_repository.dart
│   └── services/
│       ├── firebase_service.dart
│       ├── notification_service.dart
│       └── stripe_service.dart
└── main.dart
```

## DESIGN SYSTEM — Replicate Exactly from Mockups

### Colors
```dart
static const Color crimsonRed       = Color(0xFFE50914);
static const Color crimsonRedDark   = Color(0xFFD32F2F);
static const Color crimsonRedLight  = Color(0xFFFF1744);
static const Color bgPrimary        = Color(0xFF0D0D0D);
static const Color bgSecondary      = Color(0xFF1A1A1A);
static const Color bgCard           = Color(0xFF181818);
static const Color bgCardBorder     = Color(0xFF2A2A2A);
static const Color bgElevated       = Color(0xFF222222);
static const Color textWhite        = Color(0xFFFFFFFF);
static const Color textLightGray    = Color(0xFFA0A0A0);
static const Color textMediumGray   = Color(0xFF808080);
static const Color textGreen        = Color(0xFF4CAF50);
```

### Typography
```
Brand Title "JUNIOR BOY BOXING":    Oswald Bold 36px, letterSpacing 2.0, white + "BOXING" red italic
Page Title:                          Oswald Bold 28px, letterSpacing 1.0
Section Title:                       Oswald SemiBold 22px, letterSpacing 0.5
Card Title:                          Roboto Bold 18px
Subtitle:                            Roboto Regular 14px, lightGray
Label (DATE/TIME/LOCATION):          Roboto Medium 11px, uppercase, letterSpacing 1.5, red
Price:                               Roboto Bold 22px
Button:                              Roboto Bold 16px, letterSpacing 1.0
```

### Components
- Cards: `borderRadius: 12`, `border: 1px #2A2A2A`, `background: #181818`
- Selected cards: `border: 2px #E50914`
- Primary button: full-width, `#E50914`, borderRadius 30, height 56
- Outline button: full-width, white border, transparent bg, borderRadius 30
- Bottom nav: 5 items, height 64, dark bg `#0D0D0D`, active = red, inactive = gray
- DARK THEME ONLY — no light mode

## SCREENS — Build ALL of These (Match mockups exactly)

### 1. Welcome Screen
- Full-screen dark background with boxing imagery
- "JUNIOR BOY BOXING" branding (white + red italic)
- "DISCIPLINE BUILDS CHAMPIONS" tagline
- Three icons in a row: 🥊 TRAIN | 📖 LEARN | 📊 GROW
- Red "Get Started >" button → Sign Up
- White outlined "Sign In" button → Sign In
- Footer: "Stronger Kids • Brighter Futures"

### 2. Sign Up Screen
- Fields: Full Name, Email, Phone, Password, Child's Name, Child's Age
- Form validation (real-time)
- Red "Create Account" button → Firebase Auth + Firestore user doc
- "Already have an account? Sign In" link
- Loading state while creating account

### 3. Sign In Screen
- Fields: Email, Password
- "Forgot Password?" link → Firebase password reset email
- Red "Sign In" button
- "Don't have an account? Get Started" link
- Google Sign-In button option

### 4. Home Dashboard
- Branding header with boxing gloves decoration
- "Welcome Back, {Name}!" with red name
- "Keep training. Keep improving." subtitle
- **Next Session Card** (if upcoming booking exists):
  - Date, time, location
  - "View Booking >" button
  - Motivational side text
- **Quick Action Grid** (2×2):
  - Book Class, Class Schedule, Membership, Contact
- **Our Programs Section**:
  - Junior Boxing card (Kids & Teens)
  - Group Training card (3-4 People)
- Pull-to-refresh updates data from Firestore

### 5. Class Schedule
- Month/year header with navigation arrows
- Horizontal scrollable day selector (MON-SUN with dates)
- Today auto-selected with red highlight
- Class list for selected day — each card shows:
  - Thumbnail, time, class name, age group
  - Available spots in green
  - "Book" button
- Tapping "Book" → navigate to Book Class screen
- Empty state for days with no classes: "No classes scheduled"
- Data from Firestore `schedule` collection, real-time listener

### 6. Book Class Detail
- Back arrow + "Book Class" header
- Hero image area with motivational overlay text
- Class details card:
  - Class name + age badge
  - Date, Time, Location, Availability (each with red label + icon)
- "Confirm Booking >" button
- On confirm: call `createBooking` Cloud Function, show success, navigate home
- If no sessions remaining: prompt to purchase membership first

### 7. Membership Plans
- Header with branding
- "Choose Your Plan" title
- Benefit pills: Build Confidence, Get Stronger, Real Progress
- 5 plan cards (selectable):
  - Single Session — $80
  - 5 Session Pack — $350 ($70/session)
  - 10 Session Pack — $600 ($60/session) — RECOMMENDED (pre-selected, red border)
  - Small Group Training — $35/hr per person
  - Partner Training — $60/hr per person
- "Continue →" button → payment flow (Stripe or placeholder)

### 8. More / Profile Screen
- Header with branding
- Profile card: avatar, name, member since, "Edit Profile" button
- Settings menu (each row navigates to sub-screen):
  - My Bookings → list of user's bookings with status
  - Membership → current plan details + sessions remaining
  - Payments → payment history
  - Notifications → list + mark as read
  - Contact Us → Coach Sharif's phone + email + map link
  - Location → map embed or link to Google Maps
  - About Us → gym description
  - Privacy Policy → scrollable text
  - Terms of Service → scrollable text
- Red "Sign Out" button → clear auth, navigate to Welcome

### 9. My Bookings Sub-Screen
- Tabs: "Upcoming" | "Past"
- Each booking card: class name, date, time, status badge
- Swipe to cancel (upcoming only, respects 24h policy)
- Empty state if no bookings

### 10. Edit Profile Sub-Screen
- Avatar with camera icon to change photo (Firebase Storage)
- Editable fields: name, email, phone, child name, child age
- "Save Changes" button

## Technical Requirements
- **Offline support**: Cache schedule and user data in Hive. Show cached data when offline with "offline" banner
- **Push notifications**: Register FCM token on login, handle foreground/background/terminated notifications
- **Real-time updates**: Use Firestore snapshots for schedule (spots update live when others book)
- **Animations**: Hero transition to booking detail, shimmer loading, subtle card scale on tap
- **Error handling**: Try/catch everywhere, user-friendly error messages, retry buttons
- **Form validation**: Email format, password min 8 chars, required fields, phone format
- **Cancellation policy**: Cannot cancel within 24 hours of class start time

## Deliverables for Phase 2
- [ ] Complete `pubspec.yaml`
- [ ] Every `.dart` file fully written — NO skipped files, NO TODO comments
- [ ] Firebase configuration files (google-services.json placeholder instructions)
- [ ] AndroidManifest.xml with required permissions
- [ ] App icon configuration (red boxing glove on dark bg)
- [ ] Splash screen (dark bg + logo)

**Write every file. If response is too long, stop and tell me where you stopped — I will say "continue".**

---

# ══════════════════════════════════════════════════════════
# PHASE 3 OF 6 — WEBSITE (Next.js)
# ══════════════════════════════════════════════════════════

## Objective
Build a professional public-facing website AND member portal that connects to the same Firebase backend. The website serves two purposes: (1) marketing/landing page for new customers, and (2) logged-in booking portal for existing members.

## Tech Stack
- **Next.js 14** (App Router)
- **TypeScript**
- **Tailwind CSS** (dark theme matching the app)
- **Firebase JS SDK** (Auth + Firestore + Hosting)
- **Framer Motion** (animations)
- **Stripe.js** (payments)
- **Deployed on**: Firebase Hosting

## Website Pages

### Public Pages (no login required)

#### 1. Landing / Home Page (`/`)
- **Hero Section**: Full-width dark background, boxing imagery, "JUNIOR BOY BOXING" branding, "Discipline Builds Champions" tagline, CTA buttons: "Get Started" + "View Schedule"
- **About Section**: Gym story, Coach Sharif intro, location, mission statement
- **Programs Section**: Junior Boxing + Group Training cards with descriptions
- **Pricing Section**: All 5 membership plans displayed as cards (matching app design)
- **Schedule Preview**: Interactive weekly schedule showing available classes
- **Testimonials Section**: Parent reviews (placeholder content)
- **Location Section**: Embedded Google Map + address + contact info
- **CTA Section**: "Ready to Train?" + Sign Up button
- **Footer**: Links, social media (Instagram, Facebook, TikTok), contact info, copyright

#### 2. Schedule Page (`/schedule`)
- Full interactive weekly schedule (same as app but web-optimized)
- Day selector, class cards with available spots
- "Book Now" button → redirects to sign in if not logged in

#### 3. Pricing Page (`/pricing`)
- All membership plans with comparison
- FAQ accordion (cancellation policy, age requirements, what to bring, etc.)
- "Get Started" CTA

#### 4. About Page (`/about`)
- Coach bio, gym history, values
- Photo gallery
- "More Than Boxing" philosophy section

#### 5. Contact Page (`/contact`)
- Contact form (name, email, message → sends to gym email via Cloud Function)
- Phone number, email, address
- Operating hours
- Embedded Google Map

### Member Portal Pages (login required)

#### 6. Sign In Page (`/signin`)
- Email + Password login form
- Google Sign-In
- "Forgot Password?" flow
- "New here? Create Account" link

#### 7. Sign Up Page (`/signup`)
- Registration form matching app fields
- Creates Firebase Auth + Firestore user

#### 8. Dashboard (`/dashboard`)
- Welcome message
- Next upcoming session card
- Quick stats: sessions remaining, membership status
- Quick book button
- Recent bookings list

#### 9. Book a Class (`/book`)
- Full schedule view
- Click class → booking detail modal
- Confirm booking → calls same Cloud Function as app
- Success confirmation

#### 10. My Bookings (`/bookings`)
- Table/list of all bookings
- Filter: upcoming / past / cancelled
- Cancel button (respects 24h policy)

#### 11. My Membership (`/membership`)
- Current plan details
- Sessions remaining counter
- Upgrade/change plan option
- Payment history

#### 12. Profile Settings (`/settings`)
- Edit profile info
- Change password
- Notification preferences
- Sign out

## Design Requirements
- **Same dark theme** as the app: `#0D0D0D` background, `#E50914` red accents, `#181818` cards
- **Same fonts**: Oswald for headings, Roboto for body (via Google Fonts or next/font)
- **Fully responsive**: Mobile-first, looks perfect on phone, tablet, desktop
- **SEO optimized**: Meta tags, Open Graph, structured data for local business
- **Fast**: Score 90+ on Lighthouse (performance, accessibility, best practices, SEO)
- **Animations**: Subtle scroll animations with Framer Motion, hover effects on cards

## Deliverables for Phase 3
- [ ] Complete Next.js project with all pages
- [ ] Tailwind config with custom theme
- [ ] All components fully built
- [ ] Firebase integration (same project as app)
- [ ] `firebase.json` updated for hosting
- [ ] SEO: sitemap.xml, robots.txt, meta tags
- [ ] README with setup + deployment instructions

---

# ══════════════════════════════════════════════════════════
# PHASE 4 OF 6 — ADMIN DASHBOARD
# ══════════════════════════════════════════════════════════

## Objective
Build a web-based admin dashboard for Coach Sharif (gym owner) to manage the entire business — classes, bookings, members, payments, and content.

## Tech Stack
- **Next.js 14** (same project as website, under `/admin` route group)
- **Or** separate React + Vite app if preferred
- Protected by Firebase Auth (role === "admin")

## Admin Dashboard Pages

### 1. Overview / Home (`/admin`)
- **Stats Cards**: Total Members, Bookings Today, Revenue This Month, Active Plans
- **Today's Schedule**: List of today's classes with enrollment count
- **Recent Bookings**: Latest 10 bookings
- **Revenue Chart**: Line chart — last 30 days revenue
- **Popular Classes Chart**: Bar chart — bookings per class type

### 2. Schedule Management (`/admin/schedule`)
- **Calendar View**: Monthly calendar showing all classes
- **Add Class**: Form to create new class session (recurring or one-time)
- **Edit/Cancel Class**: Modify time, spots; cancel with notification to booked members
- **Recurring Templates**: Set up weekly recurring schedule (auto-generates via Cloud Function)

### 3. Bookings Management (`/admin/bookings`)
- **Table**: All bookings with filters (date range, status, class type, member)
- **Search**: By member name or email
- **Mark Attendance**: Check off who showed up after class
- **Cancel Booking**: Admin can cancel and refund session credit
- **Export CSV**: Download bookings data

### 4. Member Management (`/admin/members`)
- **Table**: All members with search, filter by plan, sort by join date
- **Member Detail**: Click to see profile, booking history, payment history, sessions remaining
- **Add Member**: Manually add (for walk-ins or phone registrations)
- **Edit Member**: Update info, assign plan, add session credits manually
- **Deactivate Member**: Soft-delete

### 5. Membership Plans (`/admin/plans`)
- **List**: All plans with edit/deactivate
- **Create Plan**: Form for new plan (name, price, sessions, type)
- **Edit Plan**: Modify pricing, description
- **Reorder**: Drag to reorder display order

### 6. Payments (`/admin/payments`)
- **Table**: All payments with filters (date, status, amount, method)
- **Record Cash Payment**: Manually log cash payments
- **Refund**: Process refund (Stripe or manual)
- **Revenue Reports**: Monthly/weekly/daily breakdown
- **Export**: CSV download

### 7. Notifications / Announcements (`/admin/notifications`)
- **Send Announcement**: Push notification to all members or specific members
- **Notification History**: List of sent notifications
- **Auto Reminders Settings**: Toggle class reminders, membership expiry alerts

### 8. Gym Settings (`/admin/settings`)
- **Business Info**: Edit name, address, phone, email
- **Operating Hours**: Set hours per day
- **Cancellation Policy**: Set hours before class for free cancellation
- **Social Links**: Instagram, Facebook, TikTok URLs
- **About Text**: Edit gym description
- **Admins**: Manage admin accounts

## Design
- Clean, modern admin UI (can use **shadcn/ui** components)
- Dark theme matching the brand, OR professional light admin theme — your choice
- Responsive (works on tablet for Coach to use during classes)
- Data tables with pagination, sorting, filtering
- Charts using **Recharts** or **Chart.js**

## Deliverables for Phase 4
- [ ] Complete admin dashboard — all pages fully functional
- [ ] Role-based access control (only admin role can access)
- [ ] All CRUD operations connected to Firestore
- [ ] Charts and analytics working
- [ ] Export functionality
- [ ] Mobile-responsive for tablet use

---

# ══════════════════════════════════════════════════════════
# PHASE 5 OF 6 — PAYMENTS & NOTIFICATIONS
# ══════════════════════════════════════════════════════════

## Objective
Integrate real payment processing and a complete notification system.

## Stripe Integration

### Setup
- Stripe account connected
- Products & Prices created in Stripe matching the 5 membership plans
- Stripe webhook endpoint (Cloud Function) to handle payment events

### Payment Flow (App + Website)
1. User selects membership plan
2. App/website creates a Stripe PaymentIntent via Cloud Function
3. User enters card details in Stripe's secure payment sheet
4. On success: Cloud Function webhook receives `payment_intent.succeeded`
5. Webhook updates: user's membership, session count, creates payment record
6. User sees confirmation + sessions updated

### Cloud Functions for Payments
```
createPaymentIntent(planId, userId) → returns clientSecret
handleStripeWebhook(event) → processes payment_intent.succeeded, payment_intent.failed
createRefund(paymentId) → admin refund
getPaymentHistory(userId) → user's payments
```

### What to Build
- [ ] Stripe setup instructions
- [ ] Cloud Functions for payment flow
- [ ] Flutter: Stripe payment sheet integration in membership screen
- [ ] Website: Stripe Elements integration in pricing/checkout page
- [ ] Admin: Record manual/cash payments
- [ ] Webhook handler for all payment events
- [ ] Receipt generation (email receipt via Stripe)

## Push Notifications System

### Notification Types
1. **Booking Confirmed** — Sent immediately when booking is created
2. **Class Reminder** — Sent 1 hour before class start
3. **Booking Cancelled** — When user or admin cancels
4. **Class Cancelled by Gym** — Admin cancels a class, notify all booked members
5. **Membership Purchased** — Payment confirmation
6. **Sessions Running Low** — When user has ≤ 2 sessions remaining
7. **Membership Expired** — Sessions hit 0
8. **General Announcement** — Admin broadcasts to all members
9. **Welcome** — Sent on first sign-up

### Implementation
- [ ] FCM setup for Android app
- [ ] Cloud Function: `sendNotification(userId, title, body, data)`
- [ ] Scheduled function: hourly check for upcoming class reminders
- [ ] Scheduled function: daily check for low sessions / expiring memberships
- [ ] In-app notification center (already built in Phase 2, connect it)
- [ ] Admin UI to send custom announcements (built in Phase 4, connect it)
- [ ] Email notifications as backup (via Firebase Extensions or SendGrid)

## Deliverables for Phase 5
- [ ] Complete Stripe integration (app + website + admin + webhooks)
- [ ] Complete notification system (push + in-app + email)
- [ ] Test payment flow end-to-end
- [ ] Error handling for failed payments

---

# ══════════════════════════════════════════════════════════
# PHASE 6 OF 6 — DEPLOYMENT & GO-LIVE
# ══════════════════════════════════════════════════════════

## Objective
Deploy everything to production, optimize performance, and prepare for real users.

## Android App Deployment

### Google Play Store Preparation
- [ ] App signing key generated
- [ ] `android/app/build.gradle` — production configuration:
  - applicationId: `com.juniorboyboxing.app`
  - versionCode / versionName management
  - ProGuard / R8 minification enabled
  - Signing config for release
- [ ] App icon: red boxing glove on dark background (adaptive icon for Android 8+)
- [ ] Splash screen: dark background + "JUNIOR BOY BOXING" logo
- [ ] Generate signed APK and App Bundle (.aab)
- [ ] Play Store listing:
  - Title: "Junior Boy Boxing"
  - Short description: "Book boxing classes for kids & teens. Train. Learn. Grow."
  - Full description: comprehensive with keywords
  - Screenshots: 5-8 screenshots from all main screens
  - Feature graphic: 1024x500 banner
  - Category: Health & Fitness
  - Content rating: Everyone
  - Privacy policy URL (hosted on website)

### App Optimizations
- [ ] Remove all debug code and print statements
- [ ] Enable Flutter release mode optimizations
- [ ] Test on multiple Android versions (API 24+)
- [ ] Test on different screen sizes
- [ ] Crash reporting: Firebase Crashlytics integration
- [ ] Analytics: Firebase Analytics events for key actions (sign up, book class, purchase plan)

## Website Deployment

### Firebase Hosting
- [ ] Build Next.js for production
- [ ] Configure Firebase Hosting with Next.js SSR (or static export)
- [ ] Custom domain setup: `www.juniorboyboxing.com` (or similar)
- [ ] SSL certificate (automatic with Firebase Hosting)
- [ ] CDN caching configuration
- [ ] Redirect rules (www → non-www or vice versa)

### SEO & Marketing
- [ ] Google Search Console verification
- [ ] Google My Business listing connected
- [ ] Social media Open Graph meta tags on every page
- [ ] Schema.org structured data (LocalBusiness, SportsActivityLocation)
- [ ] XML sitemap generated
- [ ] robots.txt configured
- [ ] Google Analytics 4 integrated

## Firebase Production Configuration
- [ ] Firestore production security rules (tighten everything)
- [ ] Cloud Functions: increase memory/timeout for critical functions
- [ ] Enable Firestore backups (scheduled export)
- [ ] Set up Firebase Alerts for errors
- [ ] Rate limiting on Cloud Functions (prevent abuse)
- [ ] Firebase App Check enabled (prevent unauthorized API usage)

## Monitoring & Maintenance
- [ ] Firebase Crashlytics (app crash reporting)
- [ ] Firebase Performance Monitoring
- [ ] Cloud Functions error logging
- [ ] Uptime monitoring for website
- [ ] Set up alerts for: function errors, high latency, auth failures

## Deliverables for Phase 6
- [ ] Signed release APK + AAB for Play Store
- [ ] Play Store listing materials (screenshots, descriptions, graphics)
- [ ] Website deployed to Firebase Hosting
- [ ] Custom domain configured
- [ ] All monitoring and analytics active
- [ ] Security audit checklist completed
- [ ] Complete deployment documentation
- [ ] Handoff document: how to update content, manage classes, handle common issues

---

# ══════════════════════════════════════════════════════════
# HOW TO USE THIS PROMPT
# ══════════════════════════════════════════════════════════

## Instructions for ChatGPT

**Send this prompt ONE PHASE AT A TIME:**

1. Copy **Phase 1** + the Design System section → paste in ChatGPT → let it generate all backend files
2. When Phase 1 is complete, copy **Phase 2** → paste with "Continue building the Junior Boy Boxing app. Here is Phase 2:" → let it generate all Flutter files
3. Repeat for Phases 3-6

**After each phase, if ChatGPT stops mid-file, just type: "continue"**

**Attach the UI mockup screenshots when sending Phase 2 and Phase 3** so ChatGPT can see the exact design.

**Important tips:**
- If ChatGPT tries to skip files or write "// TODO", tell it: "Do not skip any file. Write the complete implementation."
- If it gives you summarized code, tell it: "Write the full file, not a summary."
- After each phase, test the code before moving to the next phase.
- Keep all phases in the same ChatGPT conversation for context continuity.

---

# FINAL NOTE
This system, when complete, will include:
- ✅ Real Firebase backend with authentication, database, and cloud functions
- ✅ Android app (Flutter) — pixel-perfect match to the UI mockups
- ✅ Professional website with landing page + member portal
- ✅ Admin dashboard for gym management
- ✅ Stripe payment processing
- ✅ Push notification system
- ✅ Deployed to Google Play Store + Firebase Hosting
- ✅ Production-ready, secure, and scalable
