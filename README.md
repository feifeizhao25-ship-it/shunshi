# 顺时 ShunShi / SEASONS

AI-driven wellness companion based on Traditional Chinese Medicine (TCM) 24 solar terms + 9 body constitutions.

## Products

| Project | Platform | Language | Market |
|---------|----------|----------|--------|
| `android-cn` | Android | Chinese | China |
| `ios-cn` | iOS | Chinese | China |
| `android-global` | Android | English | Global |
| `ios-global` | iOS | English | Global |
| `admin` | Web | Chinese/English | Admin Panel |
| `backend` | API | Chinese/English | All |

## Tech Stack

- **Mobile**: Flutter 3.x + GoRouter + Riverpod
- **Backend**: Python FastAPI + SQLAlchemy + PostgreSQL + Redis
- **Admin**: Next.js + TypeScript + TailwindCSS
- **AI**: SiliconFlow API + Multi-model routing
- **Infra**: Docker + Kubernetes + Nginx + Prometheus

## Quick Start

### Backend
```bash
cd backend
cp .env.example .env  # Edit with your settings
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 4000
```

### Mobile
```bash
cd android-cn  # or ios-cn, android-global, ios-global
flutter pub get
flutter run
```

### Admin
```bash
cd admin
npm install
npm run dev
```

### Docker Compose
```bash
cp backend/.env.example backend/.env  # Configure first
docker compose up -d
```

## Project Structure

```
.
├── android-cn/       # 顺时 Android (Chinese)
├── ios-cn/           # 顺时 iOS (Chinese)
├── android-global/   # SEASONS Android (Global)
├── ios-global/       # SEASONS iOS (Global)
├── backend/          # FastAPI backend
├── admin/            # Next.js admin panel
├── k8s/              # Kubernetes manifests
├── docker/           # Docker configurations
├── docs/             # Documentation
└── build-all-apps.sh # Build script for all variants
```

## Environment Variables

Key variables (see `backend/.env.example` for full list):
- `DATABASE_URL` - PostgreSQL connection string
- `REDIS_URL` - Redis connection string
- `SILICONFLOW_API_KEY` - AI API key
- `JWT_SECRET` - Auth token secret
- `STRIPE_SECRET_KEY` - Payment (global)

## Deployment

See [docs/DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md) for detailed deployment instructions.

## License

Proprietary - All rights reserved.
