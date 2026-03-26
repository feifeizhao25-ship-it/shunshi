-- 顺时 ShunShi - PostgreSQL 初始化脚本
-- 由 docker-compose 自动执行
-- 实际表结构由 Alembic 管理，此处仅创建初始扩展

-- 启用必要扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";  -- 模糊搜索

-- 设置时区
SET timezone = 'Asia/Shanghai';
