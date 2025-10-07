# Mindapax Backend

This is the backend service for the Mindapax application, built with Java and Spring Boot.

## AI Assistant (OpenAI)

Mindapax includes an AI assistant that personalizes responses and can suggest daily/weekly/monthly goals.

Environment variables (use `.env` or your deployment’s secret manager):
- `OPENAI_API_KEY` (required)
- `OPENAI_MODEL` (optional, defaults to `gpt-4o-mini`)

Endpoints (require Authorization bearer token):
- `POST /api/v1/assistant`
  - Body: `{ "message": string, "requestRecommendations": boolean, "contextOverride": string? }`
  - Response: `{ "reply": string, "suggestions": [ { "title": string, "frequency": "DAILY|WEEKLY|MONTHLY" } ] }`
  - Any suggestions returned are stored as `SUGGESTED` goals for the user.
- `GET /api/v1/assistant/context` → returns stored personalization context
- `POST /api/v1/assistant/context` → upserts context `{ preferencesJson, notes }`
- `GET /api/v1/assistant/goals` → lists user’s goals
- `POST /api/v1/assistant/goals/{goalId}/status?status=ACTIVE|COMPLETED|SKIPPED` → update a goal’s status

Data model:
- `AssistantContext` stores user-specific preferences/notes (freeform JSON and text)
- `AssistantGoal` stores goal suggestions and user-accepted goals with a frequency and status

## Prerequisites

- Java JDK (version specified in `pom.xml`, e.g., 17 or newer)
- Maven
- Database (e.g., PostgreSQL, MySQL - configure in `application.yml`)

## Setup

1.  **Clone the repository:**
    ```bash
    git clone <repository-url>
    cd mindapax-backend
    ```

2.  **Configure `application.yml`:**
    Copy `src/main/resources/application.yml.example` to `src/main/resources/application.yml` (if an example file exists) or ensure you have a valid `application.yml`.
    Update the following configurations as needed:
    -   `spring.datasource.url`
    -   `spring.datasource.username`
    -   `spring.datasource.password`
    -   Other service-specific configurations.

3.  **Build the project:**
    ```bash
    mvn clean install
    ```

4.  **Run the application:**
    ```bash
    mvn spring-boot:run
    ```
    Alternatively, you can run the packaged JAR file from the `target/` directory.

## Zoom Video Call Integration

This application integrates with Zoom to provide video call functionality for sessions between clients and professionals.

### Configuration

To enable Zoom video calls, you need to configure your Zoom SDK credentials in the `src/main/resources/application.yml` file.

Add the following properties:

```yaml
zoom:
  sdk_key: YOUR_ACTUAL_ZOOM_SDK_KEY
  sdk_secret: YOUR_ACTUAL_ZOOM_SDK_SECRET
```

**Important:**
-   The values `YOUR_ACTUAL_ZOOM_SDK_KEY` and `YOUR_ACTUAL_ZOOM_SDK_SECRET` are placeholders. You **must** replace them with your actual Zoom SDK Key and SDK Secret.
-   These credentials are used to generate signatures for the Zoom Web SDK, allowing clients to join meetings.

### Obtaining Zoom SDK Credentials

1.  Go to the [Zoom App Marketplace](https://marketplace.zoom.us/).
2.  Sign in with your Zoom account.
3.  Click on "Develop" in the top right corner and select "Build App".
4.  Choose "SDK" as the app type and click "Create".
5.  Fill out the app information.
6.  Once your SDK app is created, you will find your **SDK Key** and **SDK Secret** in the "App Credentials" section.
7.  Ensure your app is activated (if required by Zoom for SDK usage).

**Security Note:** Treat your SDK Secret like a password. Do not commit it directly to your version control system if the repository is public. Consider using environment variables or a secure secrets management system for production deployments. The `application.yml` file should be appropriately managed according to your security policies (e.g., gitignored if it contains sensitive production credentials).

---

For further details on specific APIs or modules, please refer to the source code and Javadoc comments.

## Payments (Phase 1 – CinetPay)

This backend integrates with CinetPay to accept payments in Côte d’Ivoire and Francophone West Africa, with support for Mobile Money (Orange/MTN/Moov/Wave) and cards via a hosted checkout page.

Endpoints (authenticated unless noted):
- `POST /api/v1/payments/checkout` → Creates a CinetPay checkout
  - Body: `{ amount: number, currency?: 'XOF'|'USD', paymentMethod?: 'MOBILE_MONEY'|'CARD', description?: string, returnUrl?: string }`
  - Response: `{ paymentId: number, checkoutUrl: string }`
- `POST /api/v1/payments/webhook/cinetpay` (public) → Webhook receiver; the backend verifies with CinetPay and updates payment status.
- `GET /api/v1/payments/user/{userId}` → List user payments (existing endpoint).

Configuration (set in `.env` or environment):
- `CINETPAY_API_KEY`
- `CINETPAY_SITE_ID`
- `CINETPAY_BASE_URL` (default `https://api-checkout.cinetpay.com`)
- `CINETPAY_NOTIFY_URL` (e.g., `https://yourdomain.com/api/v1/payments/webhook/cinetpay`)
- `CINETPAY_RETURN_URL` (e.g., `https://yourdomain.com/payments/return`)

Notes:
- We use CinetPay’s v2 API: `/v2/payment` to create checkout and `/v2/payment/check` to verify transactions.
- Webhook handler always verifies with CinetPay before marking a payment as `COMPLETED` or `FAILED`.
- The `Payment` entity now includes additional fields: `provider`, `currency`, `externalRef`, `checkoutUrl`, `description`, `metadataJson`.

## Packages & Subscriptions (Beta)

Plans let users subscribe to recurring packages (e.g., monthly session bundles). Initial implementation activates a subscription upon successful one‑time payment via CinetPay; auto‑renew can be added later with a scheduler or card tokenization.

Entities:
- `Plan`: name, price, currency, billingCycle, description, sessionAllowance, active
- `Subscription`: user, plan, status (PENDING|ACTIVE|CANCELED|EXPIRED), currentPeriodStart/End, remainingSessions, lastPayment

Endpoints:
- `GET /api/v1/packages` → list active plans (auth currently required)
- `POST /api/v1/packages/{planId}/subscribe` → creates a checkout for the plan and a pending subscription; returns `{ paymentId, checkoutUrl }`
- `GET /api/v1/packages/me` → current user’s subscriptions

Activation flow:
1) Client calls subscribe → backend creates CinetPay checkout and a pending `Subscription` linked to the new `Payment`.
2) CinetPay webhook received → backend verifies and marks `Payment` COMPLETED → subscription is activated and the period is set to now → now+1 month.

Notes:
- Seed `Plan` records via SQL or admin tooling.
- Extend later for auto‑renew (e.g., with Flutterwave card tokens) and session credit deduction.

Admin
- Manage plans: `GET/POST/PUT/DELETE /api/v1/admin/plans` (ADMIN role).
- On first run, three default plans are seeded (Basic/Standard/Premium) if no plans exist.

Credits & Booking Rules
- Booking enforcement: Professionals scheduling a session for a client requires the client to have an ACTIVE subscription with remainingSessions > 0 in the current period; otherwise returns HTTP 402 (payment required).
- Credit deduction: When a session moves to COMPLETED status, 1 session credit is deducted from the client’s active subscription.
