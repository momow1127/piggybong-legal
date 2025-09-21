# Supabase Security & Performance Guide for PiggyBong

## 🔒 风险与注意事项 (Risks & Precautions)

### 1. RLS (Row Level Security) 规则 ✅
**风险**: 没有正确的 RLS 可能导致用户越权访问其他用户数据

**已实施的安全措施**:
```sql
-- 核心规则: user_id = auth.uid()
-- 每个表都启用了 RLS
ALTER TABLE fan_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_priorities ENABLE ROW LEVEL SECURITY;
ALTER TABLE fan_artists ENABLE ROW LEVEL SECURITY;

-- 用户只能访问自己的数据
CREATE POLICY "Users can view own fan activities" ON fan_activities
    FOR SELECT USING (auth.uid() = user_id);
```

**最佳实践**:
- ✅ 所有表都必须启用 RLS
- ✅ 使用 `auth.uid()` 验证用户身份
- ✅ 每个操作 (SELECT/INSERT/UPDATE/DELETE) 都有独立的策略
- ✅ 使用 `WITH CHECK` 确保插入数据的安全性

### 2. 数据库索引优化 ✅
**风险**: 没有索引会导致首页聚合查询卡顿

**已创建的索引**:
```sql
-- 按 user_id 索引 - 快速过滤用户数据
CREATE INDEX idx_fan_activities_user_id ON fan_activities(user_id);

-- 按 created_at 索引 - 时间排序查询
CREATE INDEX idx_fan_activities_created_at ON fan_activities(created_at DESC);

-- 按 category_id 索引 - 分类聚合统计
CREATE INDEX idx_fan_activities_category_id ON fan_activities(category_id);
```

**性能监控 SQL**:
```sql
-- 检查索引使用情况
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan as index_scans,
    idx_tup_read as tuples_read,
    idx_tup_fetch as tuples_fetched
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY idx_scan DESC;

-- 查找慢查询
SELECT 
    query,
    calls,
    mean_exec_time,
    total_exec_time
FROM pg_stat_statements
WHERE mean_exec_time > 100
ORDER BY mean_exec_time DESC
LIMIT 10;
```

### 3. Edge Functions 冷启动优化 🚀
**风险**: 冷启动可能导致首次请求延迟

**优化策略**:
```typescript
// 1. 减少依赖包大小
// 避免导入整个库
import { createClient } from '@supabase/supabase-js' // ✅
// import * as supabase from '@supabase/supabase-js' // ❌

// 2. 使用全局变量缓存连接
let supabaseClient: SupabaseClient | null = null

export default async function handler(req: Request) {
  // 复用连接
  if (!supabaseClient) {
    supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!
    )
  }
  // ...
}

// 3. 预热策略
// 在 GitHub Actions 中定期调用
- name: Warm Edge Functions
  run: |
    curl -X POST https://YOUR-PROJECT-REF.functions.supabase.co/auth-apple \
      -H "Content-Type: application/json" \
      -d '{"warm": true}'
```

### 4. 配额管理 📊
**当前限制**:
- Edge Functions: 500,000 invocations/month (免费层)
- Database: 500 MB (免费层)
- Storage: 1 GB (免费层)

**监控脚本**:
```bash
#!/bin/bash
# monitor-usage.sh

# 检查数据库大小
psql $DATABASE_URL -c "
SELECT 
    pg_database.datname,
    pg_size_pretty(pg_database_size(pg_database.datname)) AS size
FROM pg_database
WHERE datname = 'postgres';
"

# 检查表大小
psql $DATABASE_URL -c "
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
"
```

### 5. 供应商锁定风险缓解 🔄
**风险**: 过度依赖 Supabase 特定功能

**迁移准备**:
1. **保持 SQL 标准化**:
   - 使用标准 PostgreSQL 语法
   - 避免 Supabase 专有函数
   - 文档化所有数据库结构

2. **备份策略**:
```bash
#!/bin/bash
# backup-schema.sh

# 导出完整架构
pg_dump $DATABASE_URL \
    --schema-only \
    --no-owner \
    --no-privileges \
    > backup/schema_$(date +%Y%m%d).sql

# 导出数据
pg_dump $DATABASE_URL \
    --data-only \
    --no-owner \
    --no-privileges \
    > backup/data_$(date +%Y%m%d).sql

# 导出 RLS 策略
psql $DATABASE_URL -c "
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE schemaname = 'public';
" > backup/policies_$(date +%Y%m%d).csv
```

3. **迁移到自建 PostgreSQL**:
```sql
-- 1. 创建数据库
CREATE DATABASE piggybong;

-- 2. 运行 schema.sql
\i backup/schema_YYYYMMDD.sql

-- 3. 导入数据
\i backup/data_YYYYMMDD.sql

-- 4. 创建用户认证表 (替代 auth.users)
CREATE TABLE app_users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE NOT NULL,
    encrypted_password TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. 更新 RLS 策略
-- 将 auth.uid() 替换为应用层验证
```

## 📈 性能优化建议

### 1. 查询优化
```sql
-- 使用 EXPLAIN ANALYZE 分析查询
EXPLAIN ANALYZE
SELECT 
    category_id,
    COUNT(*) as activity_count,
    SUM(amount) as total_amount
FROM fan_activities
WHERE user_id = 'user-uuid'
    AND created_at >= NOW() - INTERVAL '30 days'
GROUP BY category_id;

-- 创建复合索引
CREATE INDEX idx_fan_activities_user_created 
ON fan_activities(user_id, created_at DESC);
```

### 2. 连接池配置
```typescript
// supabase.config.ts
const supabaseClient = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_ANON_KEY!,
  {
    db: {
      schema: 'public',
    },
    auth: {
      persistSession: true,
      autoRefreshToken: true,
    },
    global: {
      headers: {
        'x-connection-pool': 'true'
      }
    }
  }
)
```

### 3. 缓存策略
```swift
// Swift 端缓存
class FanActivityCache {
    private let cacheExpiration: TimeInterval = 300 // 5 minutes
    private var cache: [String: (data: [FanActivity], timestamp: Date)] = [:]
    
    func getCachedActivities(for userId: String) -> [FanActivity]? {
        guard let cached = cache[userId],
              Date().timeIntervalSince(cached.timestamp) < cacheExpiration else {
            return nil
        }
        return cached.data
    }
    
    func setCachedActivities(_ activities: [FanActivity], for userId: String) {
        cache[userId] = (activities, Date())
    }
}
```

## 🔍 监控与告警

### 1. 设置 Supabase 监控
```javascript
// monitoring.js
const checkHealth = async () => {
  try {
    // 检查数据库连接
    const { error: dbError } = await supabase
      .from('fan_activities')
      .select('count')
      .limit(1)
    
    // 检查 Auth 服务
    const { error: authError } = await supabase.auth.getSession()
    
    // 检查 Edge Functions
    const response = await fetch(
      'https://YOUR-PROJECT-REF.functions.supabase.co/health'
    )
    
    if (dbError || authError || !response.ok) {
      // 发送告警
      await sendAlert({
        service: 'PiggyBong',
        status: 'unhealthy',
        errors: { dbError, authError, edgeStatus: response.status }
      })
    }
  } catch (error) {
    console.error('Health check failed:', error)
  }
}

// 每 5 分钟检查一次
setInterval(checkHealth, 5 * 60 * 1000)
```

### 2. 日志收集
```sql
-- 创建审计日志表
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID,
    action TEXT NOT NULL,
    table_name TEXT,
    record_id UUID,
    old_data JSONB,
    new_data JSONB,
    ip_address TEXT,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创建审计触发器
CREATE OR REPLACE FUNCTION audit_trigger_function()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO audit_logs(
        user_id,
        action,
        table_name,
        record_id,
        old_data,
        new_data
    ) VALUES (
        auth.uid(),
        TG_OP,
        TG_TABLE_NAME,
        COALESCE(NEW.id, OLD.id),
        to_jsonb(OLD),
        to_jsonb(NEW)
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 应用到关键表
CREATE TRIGGER audit_fan_activities
    AFTER INSERT OR UPDATE OR DELETE ON fan_activities
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();
```

## 📋 检查清单

- [x] RLS 已启用并配置正确
- [x] 数据库索引已创建
- [x] Schema 文档已维护
- [ ] Edge Functions 预热脚本
- [ ] 定期备份脚本
- [ ] 监控告警系统
- [ ] 负载测试完成
- [ ] 灾难恢复计划

## 🚨 紧急联系

- Supabase Status: https://status.supabase.com
- Project Dashboard: https://app.supabase.com/project/YOUR-PROJECT-REF
- GitHub Repo: https://github.com/momow1127/PiggyBong2

---
最后更新: 2025-08-28