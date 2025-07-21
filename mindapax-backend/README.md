# Mindapax Backend

This is the backend service for the Mindapax application, built with Java and Spring Boot.

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
