#!/bin/sh
set -e

# 修复：放到 /tmp 目录，任何用户都能写，不会权限错误！
# 而且容器重启不会丢，build 也不会重复初始化！
INIT_FILE="/tmp/.supersync_initialized"

if [ ! -f "$INIT_FILE" ]; then
  echo "=== 首次启动：初始化数据库 ==="

  # 忽略权限警告，强制建表（--accept-data-loss 忽略警告）
  npx prisma db push --accept-data-loss

  # 自动标记所有迁移
  echo "=== 自动标记所有迁移 ==="
  for migration in $(ls -1 /app/prisma/migrations | grep -E '^[0-9]+' | sort); do
    npx prisma migrate resolve --applied "$migration" 2>/dev/null || true
  done

  # 修复：tmp 目录永远有权限
  touch "$INIT_FILE"
  echo "=== 初始化完成 ==="
fi

echo "=== 启动服务 ==="
npx prisma migrate deploy
node dist/src/index.js
