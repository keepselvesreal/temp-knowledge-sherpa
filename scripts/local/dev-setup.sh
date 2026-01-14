#!/bin/bash

set -e

echo "=========================================="
echo "Docker User Permissions Sync"
echo "=========================================="

# .env 파일 존재 확인
if [ ! -f .env ]; then
    echo "❌ Error: .env file not found"
    echo "Please create .env file first"
    exit 1
fi

# 호스트 사용자 UID/GID 감지
HOST_UID=$(id -u)
HOST_GID=$(id -g)
HOST_USER=$(id -un)

echo "✓ Host user detected: $HOST_USER"
echo "  UID: $HOST_UID"
echo "  GID: $HOST_GID"

# .env 백업 생성
echo "✓ Creating backup: .env.bak"
cp .env .env.bak

# 기존 .env에서 UID/GID 제외한 내용 추출
echo "✓ Processing .env file..."
grep -v "^UID=" .env | grep -v "^GID=" > .env.tmp || true

# UID/GID 추가
{
    cat .env.tmp
    echo "UID=$HOST_UID"
    echo "GID=$HOST_GID"
} > .env.new

# .env 교체
mv .env.new .env
rm -f .env.tmp

echo "✓ Updated .env with UID=$HOST_UID, GID=$HOST_GID"
echo ""

# 현재 .env 내용 확인
echo "Current .env content:"
echo "---"
cat .env
echo "---"
echo ""

# Docker 이미지 빌드
echo "🔨 Building Docker image..."
docker compose build --build-arg UID=$HOST_UID --build-arg GID=$HOST_GID

if [ $? -eq 0 ]; then
    echo "✓ Build successful"
else
    echo "❌ Build failed"
    # 백업에서 복원
    echo "⚠ Restoring .env from backup..."
    cp .env.bak .env
    exit 1
fi

echo ""
echo "🚀 Starting containers..."
docker compose up -d

if [ $? -eq 0 ]; then
    echo "✓ Containers started successfully"
else
    echo "❌ Failed to start containers"
    exit 1
fi

echo ""
echo "=========================================="
echo "✅ Sync complete!"
echo "=========================================="
echo ""
echo "WordPress is running:"
echo "  URL: http://localhost:8080"
echo ""
echo "Backup saved as: .env.bak"
echo ""
