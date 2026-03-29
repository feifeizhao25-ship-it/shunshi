export default function AlertsPage() {
  const alerts = [
    { id: 'A-001', title: '批量注册攻击', level: '高', status: '待处理', source: '认证系统', time: '2026-03-18 18:45', description: '检测到来自 IP 203.x.x.x 的异常注册行为，频率达到 12次/分钟。已自动启用验证码防护。' },
    { id: 'A-002', title: 'Prompt注入风险', level: '高', status: '待处理', source: 'AI引擎', time: '2026-03-18 18:20', description: 'Prompt模板 P-089 在过去1小时内被调用 847 次，检测到包含潜在注入指令的内容。建议立即审查。' },
    { id: 'A-003', title: '敏感内容发布', level: '中', status: '处理中', source: '内容审核', time: '2026-03-18 17:55', description: '用户 U-1024 发布内容包含未通过自动审核的敏感词汇，已自动下架并等待人工复审。' },
    { id: 'A-004', title: '审核队列积压', level: '中', status: '处理中', source: '内容管理', time: '2026-03-18 16:30', description: '内容审核队列积压 47 篇，超过 30 篇阈值。当前平均审核时长 2.3 小时。' },
    { id: 'A-005', title: '异常登录行为', level: '低', status: '已处理', source: '认证系统', time: '2026-03-18 14:55', description: '用户 U-3087 在非常用地区（美国-加州）登录，已发送手机验证码确认身份，用户已验证通过。' },
    { id: 'A-006', title: 'API响应超时', level: '低', status: '已处理', source: '监控系统', time: '2026-03-18 10:20', description: 'CMS API 平均响应时间在 09:00-09:30 期间超过 3s 阈值，最高达 5.2s。问题已自动恢复。' },
  ];

  const levelStyles: Record<string, string> = {
    '高': 'bg-red-100 text-red-700 border-red-200',
    '中': 'bg-orange-100 text-orange-700 border-orange-200',
    '低': 'bg-yellow-100 text-yellow-700 border-yellow-200',
  };

  const statusStyles: Record<string, string> = {
    '待处理': 'text-red-600',
    '处理中': 'text-orange-600',
    '已处理': 'text-green-600',
  };

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h2 className="text-2xl font-bold">告警中心</h2>
        <div className="flex items-center gap-4 text-sm text-gray-500">
          <span>待处理: <strong className="text-red-600">2</strong></span>
          <span>处理中: <strong className="text-orange-600">2</strong></span>
          <span>已处理: <strong className="text-green-600">2</strong></span>
        </div>
      </div>

      <div className="space-y-4">
        {alerts.map((alert) => (
          <div key={alert.id} className={`bg-white rounded-lg border p-6 ${levelStyles[alert.level]}`}>
            <div className="flex items-start justify-between mb-3">
              <div className="flex items-center gap-3">
                <span className="font-mono text-xs text-gray-400">{alert.id}</span>
                <h3 className="font-semibold">{alert.title}</h3>
                <span className={`px-2 py-0.5 rounded text-xs ${levelStyles[alert.level]}`}>{alert.level}</span>
                <span className={`text-xs font-medium ${statusStyles[alert.status]}`}>{alert.status}</span>
              </div>
              <div className="text-xs text-gray-400 whitespace-nowrap">{alert.time}</div>
            </div>
            <p className="text-sm text-gray-600 mb-2">{alert.description}</p>
            <div className="text-xs text-gray-400">来源: {alert.source}</div>
          </div>
        ))}
      </div>
    </div>
  );
}
