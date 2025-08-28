# Repository Guidelines

## Project Structure & Modules
- `mindapax-backend/`: Spring Boot (Maven). Source in `src/main/java`, tests in `src/test/java`, config in `src/main/resources`.
- `mindapax-frontend/`: Angular app (Node). Source in `src/`, public assets in `public/`, builds to `dist/`.
- `mindapax-mobile/`: Flutter app. Dart sources in `lib/`.
- `terraform/`: IaC for AWS (S3, EC2, networking, CodeBuild). Uses remote/backend config.
- Root scripts: `deploy-backend.sh`, `deploy-frontend.sh`, `deploy.sh`. Local stack/dev: `docker-compose-test.yml`.

## Build, Test, and Development
- Backend:
  - Build: `cd mindapax-backend && mvn clean package`
  - Test: `mvn test` (JUnit) | Run: `java -jar target/*.jar`
- Frontend:
  - Dev: `cd mindapax-frontend && npm start` (Angular dev server)
  - Build: `npm run build` | Test: `npm test` (Karma/Jasmine)
- Mobile:
  - Run: `cd mindapax-mobile && flutter run`
  - Test: `flutter test`
- Infra:
  - `cd terraform && terraform init && terraform plan` then `terraform apply`
- Docker (local full stack): `docker compose -f docker-compose-test.yml up --build`

## Coding Style & Naming
- Java (backend): 4-space indent. Packages lowercase (e.g., `com.example.api`), classes `PascalCase`, methods/fields `camelCase`. Spring annotations and config under `...config`.
- TypeScript/Angular: 2-space indent, single quotes (see `.editorconfig`). Files: `*.component.ts`, `*.service.ts`. Use `rxjs` best practices and Angular CLI structure.
- Dart/Flutter: Follow `flutter_lints`; classes `PascalCase`, members `camelCase`, file names `snake_case.dart`.

## Testing Guidelines
- Backend: JUnit tests in `mindapax-backend/src/test/java`. Name tests `*Test.java`. Aim for coverage on services/controllers. Run `mvn test`.
- Frontend: Jasmine/Karma specs in `src/**/*.spec.ts`. Keep components shallow and mock services. Run `npm test`.
- Mobile: Widget/unit tests in `test/`. Prefer small, deterministic tests. Run `flutter test`.

## Commit & Pull Requests
- Commits: Use Conventional Commits (`feat:`, `fix:`, `chore:`, `refactor:`). Example: `feat(frontend): add meeting scheduler component`.
- PRs: Include scope/summary, linked issues (e.g., `Closes #123`), screenshots for UI, and steps to test. Keep PRs focused and small.

## Security & Configuration
- Do not commit secrets. Use `.env` (see `mindapax-backend/.env.example`) and CI/CD secrets/AWS Parameter Store.
- Before deploying, ensure AWS credentials are configured. Deploy with `./deploy.sh` (uses Terraform + S3).
