#!/bin/bash
# scripts/vm/init.sh
# GCP VM에서 실행: WordPress Docker 초기화 및 설정
# 사용법: bash /opt/wordpress/scripts/vm/init.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# scripts/vm/init.sh → scripts → project root
PROJECT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

echo "🔧 Initializing WordPress on GCP VM"
echo "   Project: $PROJECT_DIR"
echo ""

cd "$PROJECT_DIR"

# ============================================
# Step 1: 환경변수 로드
# ============================================
echo "📋 Loading environment..."

if [ ! -f .env ]; then
    echo "❌ .env file not found"
    exit 1
fi

export $(cat .env | grep -v '^#' | xargs)
echo "✅ Environment loaded"
echo "   DB_NAME: $DB_NAME"
echo "   UID/GID: $UID:$GID"
echo ""

# ============================================
# Step 1-2: VM 사용자 UID/GID 자동 감지 및 .env 업데이트
# ============================================
echo "🔍 Detecting VM user UID/GID..."
VM_UID=$(id -u)
VM_GID=$(id -g)
VM_USER=$(id -un)

if [ "$VM_UID" != "$UID" ] || [ "$VM_GID" != "$GID" ]; then
    echo "⚠️  Detected different UID/GID"
    echo "   VM: $VM_UID:$VM_GID ($VM_USER)"
    echo "   .env: $UID:$GID"
    echo "📝 Updating .env with VM UID/GID..."

    # .env 백업
    cp .env .env.bak.$(date +%Y%m%d_%H%M%S)

    # sed로 UID/GID 업데이트
    sed -i "s/^UID=.*/UID=$VM_UID/" .env
    sed -i "s/^GID=.*/GID=$VM_GID/" .env

    # 환경변수 재로드
    export $(cat .env | grep -v '^#' | xargs)
    echo "✅ .env updated: UID=$VM_UID, GID=$VM_GID"
else
    echo "✅ UID/GID matches: $VM_UID:$VM_GID"
fi
echo ""

# ============================================
# Step 2: Docker 이미지 빌드 및 컨테이너 실행
# ============================================
echo "🐳 Building and starting Docker containers..."

# 기존 컨테이너 정리
docker compose down 2>/dev/null || true

# Docker Compose 실행
docker compose up -d --build

echo "✅ Docker containers started"
echo ""

# MySQL이 준비될 때까지 대기
echo "⏳ Waiting for MySQL to be ready..."
for i in {1..30}; do
    if docker compose exec -T db mysql -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" -e "SELECT 1" 2>/dev/null; then
        echo "✅ MySQL is ready"
        break
    fi
    echo "   Attempt $i/30..."
    sleep 2
done

echo ""

# ============================================
# Step 3: WordPress 초기화
# ============================================
echo "📝 Initializing WordPress..."

# WordPress 설치 여부 확인
if docker compose exec -T wordpress wp core is-installed 2>/dev/null; then
    echo "✅ WordPress already installed (skip)"
else
    echo "📥 Installing WordPress..."

    docker compose exec -T wordpress wp core install \
        --url="http://localhost" \
        --title="WordPress Prod (Test)" \
        --admin_user="admin" \
        --admin_password="AdminPassword123!" \
        --admin_email="admin@localhost"

    echo "✅ WordPress installed"
fi

echo ""

# ============================================
# Step 4: Safe Options 동기화 (있으면)
# ============================================
echo "⚙️  Syncing safe options..."

# 최신 safe-options export 파일 찾기
LATEST_EXPORT=$(ls -t src/wp-data/db-exports/safe-options_*.sql 2>/dev/null | head -1)

if [ -n "$LATEST_EXPORT" ]; then
    echo "📥 Importing: $LATEST_EXPORT"

    # SQL 파일을 컨테이너 내부로 복사
    docker compose cp "$LATEST_EXPORT" wordpress:/tmp/safe-options.sql

    # Import 실행
    docker compose exec -T wordpress wp db import /tmp/safe-options.sql

    # 정리
    docker compose exec -T wordpress rm /tmp/safe-options.sql

    echo "✅ Safe options imported"
    echo ""

    # 운영 환경에 맞게 값 조정 (필요시)
    echo "📝 Checking environment-specific values..."

    # siteurl, home은 운영 환경에서 수동 설정 권장
    echo "   ⚠️  siteurl, home 값 확인 후 수동 설정 권장"
else
    echo "⚠️  No safe-options export found (skip)"
fi

echo ""

# ============================================
# 초기화 완료
# ============================================
echo "✅ WordPress initialization complete!"
echo ""
echo "📊 Status:"
docker compose ps
echo ""
echo "🌐 WordPress Admin:"
echo "   User: admin"
echo "   Password: AdminPassword123!"
echo "   URL: http://localhost/wp-admin"
echo ""
echo "📝 Important:"
echo "1. Change WordPress admin password immediately"
echo "2. Configure siteurl and home for production domain"
echo "3. Run: docker compose exec wordpress wp option update siteurl 'https://yourdomain.com'"
echo "4. Run: docker compose exec wordpress wp option update home 'https://yourdomain.com'"
echo ""
