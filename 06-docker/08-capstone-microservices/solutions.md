# Solutions - Microservices Capstone

## Tier 1 - the two Dockerfiles
Both services are the same pattern (the provided `frontend/Dockerfile` is the model).

`users-service/Dockerfile` and `orders-service/Dockerfile` (identical):
```dockerfile
FROM python:3-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py .
CMD ["python", "app.py"]
```
Build them:
```bash
docker build -t users:1  ./sandbox/08-capstone-microservices/users-service
docker build -t orders:1 ./sandbox/08-capstone-microservices/orders-service
```

## Tier 2 - docker-compose.yml
Create `sandbox/08-capstone-microservices/docker-compose.yml`:
```yaml
services:
  users-db:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: users
      POSTGRES_USER: app
      POSTGRES_PASSWORD: secret
    volumes:
      - usersdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U app -d users"]
      interval: 3s
      timeout: 3s
      retries: 10

  orders-db:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: orders
      POSTGRES_USER: app
      POSTGRES_PASSWORD: secret
    volumes:
      - ordersdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U app -d orders"]
      interval: 3s
      timeout: 3s
      retries: 10

  users-service:
    build: ./users-service
    image: users:1
    environment:
      DB_HOST: users-db
      DB_NAME: users
      DB_USER: app
      DB_PASSWORD: secret
    depends_on:
      users-db:
        condition: service_healthy

  orders-service:
    build: ./orders-service
    image: orders:1
    environment:
      DB_HOST: orders-db
      DB_NAME: orders
      DB_USER: app
      DB_PASSWORD: secret
      USERS_URL: "http://users-service:5000"
    depends_on:
      orders-db:
        condition: service_healthy
      users-service:
        condition: service_started

  web:
    build: ./frontend
    ports:
      - "8080:80"
    depends_on:
      - users-service
      - orders-service

volumes:
  usersdata:
  ordersdata:
```
Bring it up (from the folder with the compose file):
```bash
cd sandbox/08-capstone-microservices
docker compose up -d --build
docker compose ps
```

## Tier 3 - prove it
```bash
curl localhost:8080/api/users     # [{"id":1,"name":"Alice"}, {"id":2,"name":"Bob"}]
curl localhost:8080/api/orders    # each order carries the buyer's "user_name"
curl localhost:8080               # the UI page showing both lists
```
If `/api/orders` shows real names (Alice/Bob) rather than "unknown", the
service-to-service call worked and the whole mesh is live.

### Answers
1. Database-per-service keeps services **independent**: each can be deployed, scaled,
   and schema-changed on its own, with no hidden coupling through a shared database.
2. `http://users-service:5000` resolves to the `users-service` container via Compose's
   built-in DNS on the project network - services find each other by **service name**.
3. Each Postgres runs in its own container with its own network namespace, so both can
   use 5432 internally without clashing. A published host port (`8080:80`) maps to a
   single host port, so that one must be unique on your machine.
4. `/api/orders` still returns, but names fall back to `"unknown"` - `user_name()`
   retries the call a few times and then degrades gracefully instead of crashing.
5. Add `docker compose up -d --scale orders-service=2`. It works because the service is
   stateless (its state lives in `orders-db`) and reached by service name, so Compose
   can run several interchangeable instances.
