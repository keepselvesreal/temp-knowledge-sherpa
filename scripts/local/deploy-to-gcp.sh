#!/bin/bash
# scripts/local/deploy-to-gcp.sh
# 로컬에서 실행: GCP VM에 WordPress 배포
# 사용법: ./scripts/local/deploy-to-gcp.sh [gcp-host] [deploy-path]

set -e

# ============================================
# 설정
# ============================================
GCP_HOST="${1:-gcp-wp}"
DEPLOY_PATH="${2:-/opt/wordpress}"
REPO_URL="https://github.com/YOUR-USERNAME/playground.git"

echo "🚀 Deploying to GCP VM"
echo "   Host: $GCP_HOST"
echo "   Deploy path: $DEPLOY_PATH"
echo ""

# ============================================
# Step 1: SSH 연결 테스트
# ============================================
echo "📡 Testing SSH connection..."
if ! ssh -o ConnectTimeout=5 "$GCP_HOST" "echo '✅ SSH OK'" 2>/dev/null; then
    echo "❌ SSH connection failed"
    echo "   Check host: $GCP_HOST"
    exit 1
fi

# ============================================
# Step 2: 원격 디렉토리 준비
# ============================================
echo "📁 Preparing remote directory..."
ssh "$GCP_HOST" bash -s "$DEPLOY_PATH" << 'REMOTE_PREP'
    set -e
    DEPLOY_PATH=$1

    if [ ! -d "$DEPLOY_PATH" ]; then
        sudo mkdir -p "$DEPLOY_PATH"
        sudo chown -R $(id -u):$(id -g) "$DEPLOY_PATH"
        echo "✅ Created $DEPLOY_PATH"
    else
        echo "✅ $DEPLOY_PATH already exists"
    fi

    # 필요한 서브디렉토리
    mkdir -p "$DEPLOY_PATH/src/wp-data/{uploads,cache,db-exports}"
    mkdir -p "$DEPLOY_PATH/src/logs"
    mkdir -p "$DEPLOY_PATH/scripts"
    mkdir -p "$DEPLOY_PATH/config"

    echo "✅ Subdirectories ready"
REMOTE_PREP

# ============================================
# Step 3: Git 동기화 (clone 또는 pull)
# ============================================
echo "📥 Syncing repository..."
ssh "$GCP_HOST" bash -s "$DEPLOY_PATH" "$REPO_URL" << 'REMOTE_GIT'
    set -e
    DEPLOY_PATH=$1
    REPO_URL=$2
    cd "$DEPLOY_PATH"

    if [ -d .git ]; then
        echo "📤 Pulling latest code..."
        git pull origin main
    else
        echo "📥 Cloning repository..."
        git clone "$REPO_URL" .
    fi

    echo "✅ Git sync complete"
REMOTE_GIT

# ============================================
# Step 4: 환경설정 파일 생성
# ============================================
echo "⚙️  Creating .env file..."
ssh "$GCP_HOST" bash -s "$DEPLOY_PATH" << 'REMOTE_ENV'
    set -e
    DEPLOY_PATH=$1
    cd "$DEPLOY_PATH"

    if [ -f .env ]; then
        echo "✅ .env already exists (skipped)"
    else
        cat > .env << 'ENVFILE'
# GCP VM 운영 환경 설정 (테스트용)

# 📦 Database Configuration
DB_NAME=wordpress_prod
DB_USER=wp_user
DB_PASSWORD=Prod@Secure_Pass_2026_QwErTy
DB_ROOT_PASSWORD=Root@Prod_2026_AsdfGhJk

# 🔧 WordPress Debug Mode
DEBUG_MODE=false

# 🐳 Docker User Permission
UID=1000
GID=1000
ENVFILE
        echo "✅ .env created"
    fi
REMOTE_ENV

# ============================================
# Step 5: 원격 초기화 스크립트 실행
# ============================================
echo "🔧 Running remote initialization..."
ssh "$GCP_HOST" bash -s "$DEPLOY_PATH" << 'REMOTE_INIT'
    set -e
    DEPLOY_PATH=$1
    cd "$DEPLOY_PATH"

    # 초기화 스크립트 실행
    if [ -f scripts/vm/init.sh ]; then
        bash scripts/vm/init.sh
    else
        echo "❌ scripts/vm/init.sh not found"
        exit 1
    fi
REMOTE_INIT

# ============================================
# 배포 완료
# ============================================
echo ""
echo "✅ Deployment complete!"
echo ""
echo "🌐 Access WordPress:"
echo "   URL: http://$(ssh $GCP_HOST hostname -I | awk '{print $1}') or your domain"
echo ""
echo "📝 Next steps:"
echo "1. SSH into VM: ssh $GCP_HOST"
echo "2. Check status: cd $DEPLOY_PATH && docker compose ps"
echo "3. View logs: docker compose logs -f wordpress"
echo ""
