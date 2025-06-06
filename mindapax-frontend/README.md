# MindapaxFrontend

This project was generated using [Angular CLI](https://github.com/angular/angular-cli) version 19.2.0.

## Development server

To start a local development server, run:

```bash
ng serve
```

Once the server is running, open your browser and navigate to `http://localhost:4200/`. The application will automatically reload whenever you modify any of the source files.

## Code scaffolding

Angular CLI includes powerful code scaffolding tools. To generate a new component, run:

```bash
ng generate component component-name
```

For a complete list of available schematics (such as `components`, `directives`, or `pipes`), run:

```bash
ng generate --help
```

## Building

To build the project run:

```bash
ng build
```

This will compile your project and store the build artifacts in the `dist/` directory. By default, the production build optimizes your application for performance and speed.

## Running unit tests

To execute unit tests with the [Karma](https://karma-runner.github.io) test runner, use the following command:

```bash
ng test
```

## Running end-to-end tests

For end-to-end (e2e) testing, run:

```bash
ng e2e
```

Angular CLI does not come with an end-to-end testing framework by default. You can choose one that suits your needs.

## Zoom Web SDK Integration

This application integrates the Zoom Web SDK to enable video call functionality. To ensure this feature works correctly in your local development environment, you need to manually download and place the Zoom Web SDK files into the project.

### Zoom SDK Setup Steps:

1.  **Download the Zoom Web SDK:**
    *   Go to the [Zoom App Marketplace](https://marketplace.zoom.us/).
    *   Sign in and navigate to "Develop" > "Build App".
    *   If you haven't already, create an **SDK App** to get your SDK Key and Secret (which are used by the backend).
    *   From the same SDK App page on the Marketplace, or from Zoom's developer documentation, find the download link for the **Web SDK** itself (it's usually a zip file). Download the latest version compatible with your integration (e.g., version 2.18.x or as specified in documentation).

2.  **Extract and Place SDK Files:**
    *   Extract the downloaded Zoom Web SDK zip file.
    *   You will find a `dist` (or similarly named) folder containing the necessary SDK files.
    *   Create the following directory structure within the frontend project if it doesn't exist:
        ```
        mindapax-frontend/
        └── src/
            └── assets/
                └── zoom-sdk/
                    ├── css/
                    └── lib/
        ```
    *   Copy the CSS files (e.g., `bootstrap.css`, `react-select.css`) from the SDK's `dist/css/` directory into `mindapax-frontend/src/assets/zoom-sdk/css/`.
    *   Copy the JavaScript library files (e.g., `zoom-mlib.min.js`, `webim.min.js`, and other files from the `lib` or `av` subdirectories of the SDK's `dist` folder) into `mindapax-frontend/src/assets/zoom-sdk/lib/`.
    *   Copy the main Zoom Web SDK JavaScript file (e.g., `zoomus-websdk.umd.min.js` or `zoom-meeting-VERSION.min.js`) from the SDK's `dist/` directory into `mindapax-frontend/src/assets/zoom-sdk/`.

    **Note:** The exact file names and required files might vary slightly depending on the Zoom Web SDK version. Refer to the `angular.json` file in this project (under `projects.mindapax-frontend.architect.build.options.styles` and `projects.mindapax-frontend.architect.build.options.scripts`) for the specific file paths that the application expects to find within `src/assets/zoom-sdk/`. You must ensure the files you place match these expected paths and names.

3.  **Verify Configuration:**
    *   The `angular.json` file is already configured to include these local SDK files in the build.
    *   Once the files are correctly placed, the Zoom video call feature should be able to load the SDK.

This setup is necessary because the Zoom Web SDK has components that are not directly consumable as standard npm packages in a way that Angular CLI can automatically manage for all its parts (especially the binary WebAssembly and worker files).

## Additional Resources

For more information on using the Angular CLI, including detailed command references, visit the [Angular CLI Overview and Command Reference](https://angular.dev/tools/cli) page.
