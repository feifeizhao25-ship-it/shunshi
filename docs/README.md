# ShunShi AI Router
FastAPI-based AI orchestration layer for 顺时 (ShunShi) wellness companion.

## Quick Start

```bash
# Install dependencies
pip install -r requirements.txt

# Run server
uvicorn app.main:app --reload --port 4001
```

## Project Structure

```
shunshi-ai-router/
├── app/
│   ├── main.py              # FastAPI app entry
│   ├── config.py            # Configuration
│   ├── dependencies.py      # Dependency injection
│   ├── api/                 # API routes
│   ├── core/                # Core AI logic
│   ├── models/              # Pydantic models
│   ├── providers/           # LLM providers
│   ├── repositories/        # Data access
│   ├── services/            # Business logic
│   ├── skills/              # Skill implementations
│   ├── utils/               # Utilities
│   └── db/                  # Database
├── tests/                   # Test suite
└── scripts/                 # Seed scripts
```

## API Endpoints

- `POST /chat/send` - Send chat message
- `POST /daily-plan/generate` - Generate daily plan
- `POST /skill/run` - Run a skill
- `GET /health` - Health check
