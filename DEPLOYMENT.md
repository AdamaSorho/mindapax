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

## Stopping the Application

To stop the running containers, navigate to the project's root directory and run:
```bash
docker-compose down
```

## Notes

*   The frontend application is served by Nginx on port 80.
*   The backend Spring Boot application runs on port 8080.
*   The `docker-compose.yml` file defines a network `mindapax-network` that allows the frontend and backend services to communicate with each other. The frontend can reach the backend using the service name `backend` (e.g., `http://backend:8080`).
*   You might need to adjust firewall settings on your VPS to allow traffic on ports 80 and 8080.
