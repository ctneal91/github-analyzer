# GitHub Event Analyzer

A Rails 8 API service that ingests public GitHub events, persists them to PostgreSQL, and enriches Push events with actor and repository metadata.

## Requirements

- Ruby 3.2+
- PostgreSQL 14+
- Node.js 18+ (for git hooks)
- Docker & Docker Compose (optional)

## Quick Start with Docker

```bash
# Start all services
docker-compose up -d

# Create and migrate database
docker-compose exec api bin/rails db:create db:migrate

# Run tests
docker-compose exec api bundle exec rspec

# Ingest events
docker-compose exec api bin/rails github:ingest

# Enrich events
docker-compose exec api bin/rails github:enrich
```

## Local Development Setup

```bash
# Install dependencies
bundle install
npm install

# Setup database
bin/rails db:create db:migrate

# Run tests
bundle exec rspec

# Start server
bin/rails server
```

## Running Tests

```bash
# Run all tests with coverage
bundle exec rspec

# Run specific test file
bundle exec rspec spec/services/event_ingestion_service_spec.rb

# Run with documentation format
bundle exec rspec --format documentation
```

Coverage reports are generated in `coverage/index.html`. Minimum 90% line coverage is enforced by pre-commit hooks.

## Rake Tasks

### Ingest Events

Fetches push events from GitHub's public events API:

```bash
bin/rails github:ingest
```

Output:
```
Ingesting GitHub events...
Processed: 5, Skipped: 2, Errors: 0
```

### Enrich Events

Enriches unenriched events with actor and repository data:

```bash
bin/rails github:enrich
```

Output:
```
Enriching GitHub events...
Processed: 5, Skipped: 0, Errors: 0
```

### Check Rate Limit

Shows current GitHub API rate limit status:

```bash
bin/rails github:rate_limit
```

Output:
```
GitHub API Rate Limit Status
  Remaining: 45 requests
  Resets at: 2025-01-15 22:30:00 UTC
  Can make requests: Yes
```

### Show Statistics

Displays database statistics:

```bash
bin/rails github:stats
```

Output:
```
GitHub Analyzer Statistics
  Total events: 100
  Enriched events: 85
  Unenriched events: 15
  Actors: 42
  Repositories: 23
```

## Project Structure

```
app/
├── models/
│   ├── concerns/
│   │   └── storable_payload.rb # S3 payload storage concern
│   ├── actor.rb              # GitHub users
│   ├── push_event.rb         # Push events with metadata
│   ├── rate_limit_state.rb   # API rate limit tracking
│   └── repository.rb         # GitHub repositories
└── services/
    ├── actor_fetcher.rb           # Find/fetch actor data
    ├── event_enrichment_service.rb # Orchestrates enrichment
    ├── event_ingestion_service.rb  # Fetches and stores events
    ├── github_client.rb           # HTTP client with rate limiting
    ├── ingestion_result.rb        # Result tracking value object
    ├── payload_storage_service.rb # S3 object storage operations
    └── repository_fetcher.rb      # Find/fetch repo data
```

## Rate Limiting

The service handles GitHub's unauthenticated rate limit (60 requests/hour):

- Tracks remaining requests in database
- Stops processing before limit is hit
- Logs warnings when rate limit is low
- Resumes automatically after reset window

## Linting

```bash
# Run RuboCop
bundle exec rubocop

# Auto-fix issues
bundle exec rubocop --autocorrect
```

## Git Hooks

Pre-commit hooks (via Husky) enforce:
- RuboCop linting passes
- RSpec tests pass
- 90%+ line coverage maintained

## Object Storage (Optional)

Large raw payloads can be stored in S3-compatible object storage (MinIO) instead of PostgreSQL:

```bash
# With Docker (MinIO is pre-configured)
docker-compose exec -e PAYLOAD_STORAGE_ENABLED=true api bin/rails github:ingest

# Local development (requires MinIO running on localhost:9000)
PAYLOAD_STORAGE_ENABLED=true \
  AWS_ACCESS_KEY_ID=minioadmin \
  AWS_SECRET_ACCESS_KEY=minioadmin \
  S3_ENDPOINT=http://localhost:9000 \
  S3_BUCKET=github-analyzer-development \
  bin/rails github:ingest
```

When enabled:
- Raw JSON payloads are stored in MinIO/S3
- Database stores only a reference key (`payload_key`)
- Payloads are automatically retrieved when accessing `raw_payload`
- Failed storage operations fall back to database storage

Access MinIO console at http://localhost:9001 (minioadmin/minioadmin).

## Docker Services

| Service | Port | Description |
|---------|------|-------------|
| db | 5432 | PostgreSQL database |
| minio | 9000/9001 | S3-compatible object storage |
| api | 3000 | Rails API server |
| test | - | Test runner container |

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| DATABASE_URL | - | PostgreSQL connection string |
| POSTGRES_HOST | localhost | Database host |
| POSTGRES_USER | postgres | Database user |
| POSTGRES_PASSWORD | postgres | Database password |
| RAILS_ENV | development | Rails environment |
| PAYLOAD_STORAGE_ENABLED | false | Enable S3 payload storage |
| AWS_ACCESS_KEY_ID | minioadmin | S3 access key |
| AWS_SECRET_ACCESS_KEY | minioadmin | S3 secret key |
| AWS_REGION | us-east-1 | S3 region |
| S3_ENDPOINT | - | S3 endpoint (for MinIO) |
| S3_BUCKET | github-analyzer-{env} | S3 bucket name |
