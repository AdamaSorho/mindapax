# Deploying with Docker

This document provides instructions on how to build and run the application using Docker and Docker Compose.

## Prerequisites

*   **Docker:** Ensure Docker is installed on your system. You can find installation instructions at [https://docs.docker.com/get-docker/](https://docs.docker.com/get-docker/).
*   **Docker Compose:** Ensure Docker Compose is installed. It's usually included with Docker Desktop, but if not, follow the instructions at [https://docs.docker.com/compose/install/](https://docs.docker.com/compose/install/).

## Running the Application

1.  **Clone the repository (if you haven't already):**
    ```bash
    git clone <your-repository-url>
    cd <your-repository-directory>
    ```

2.  **Build and run the application using Docker Compose:**
    From the root directory of the project (where the `docker-compose.yml` file is located), run the following command:
    ```bash
    docker-compose up -d --build
    ```
    *   `--build`: This flag forces Docker Compose to rebuild the images before starting the containers.
    *   `-d`: This flag runs the containers in detached mode (in the background).

3.  **Accessing the applications:**
    *   **Frontend:** Open your web browser and navigate to `http://localhost` (or `http://<your-vps-ip>`).
    *   **Backend:** The backend API will be accessible at `http://localhost:8080` (or `http://<your-vps-ip>:8080`). The frontend is already configured to communicate with the backend through the Docker network.

## MySQL Database Service

The `docker-compose.yml` includes a `mysql` service for the backend database:

*   **Image:** `mysql:8.0`
*   **Container Name:** `mindapax-mysql`
*   **Ports:** `3306` on the host is mapped to `3306` in the container (useful for connecting with an external SQL client for debugging).
*   **Data Persistence:** Database data is persisted in a Docker named volume called `mysql-data`. This means your data will remain even if you stop and remove the containers (but not if you explicitly delete the volume).
*   **Network:** Connected to the `mindapax-network` to allow the backend service to reach it via the hostname `mysql`.

### Configuration

The MySQL service is configured using environment variables in the `docker-compose.yml` file within the `mysql` service definition. **You MUST change the default placeholder passwords before running in a production-like environment.**

*   `MYSQL_ROOT_PASSWORD`: The root password for the MySQL instance. **(CHANGE THIS)**
*   `MYSQL_DATABASE`: The name of the database to be created automatically (e.g., `mindapax_db`). **(CHANGE THIS if needed)**
*   `MYSQL_USER`: The username for a new user to be created with privileges on `MYSQL_DATABASE`. **(CHANGE THIS if needed)**
*   `MYSQL_PASSWORD`: The password for `MYSQL_USER`. **(CHANGE THIS)**

The backend service is configured to connect to this MySQL instance using these credentials via its own environment variables (see `SPRING_DATASOURCE_*` in the `backend` service definition in `docker-compose.yml`). Ensure these match the MySQL service credentials.

## Stopping the Application

To stop the running containers, navigate to the project's root directory and run:
```bash
docker-compose down
```

## Notes

*   The frontend application is served by Nginx on port 80.
*   The backend Spring Boot application runs on port 8080 and connects to the MySQL database.
*   The MySQL database server runs on port 3306 (mapped to the host).
*   Database data for MySQL is persisted in the `mysql-data` Docker volume.
*   The `docker-compose.yml` file defines a network `mindapax-network` that allows the frontend, backend, and database services to communicate with each other using their service names as hostnames (e.g., backend connects to `mysql:3306`).
*   You might need to adjust firewall settings on your VPS to allow traffic on ports 80, 8080, and 3306 if accessed externally.
*   On the first run, the MySQL container might take a short while to initialize the database.
