# 顺时数据库配置
# 阿里云 RDS MySQL

DB_HOST = "shunshi-db.mysql.rds.aliyuncs.com"
DB_PORT = 3306
DB_USER = "root"
DB_PASSWORD = "Shunshi2026!"
DB_NAME = "shunshi"

# 连接池配置
DB_POOL_SIZE = 5
DB_MAX_OVERFLOW = 10

# 构建连接 URL
DATABASE_URL = f"mysql+aiomysql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
DATABASE_URL_SYNC = f"mysql+pymysql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
