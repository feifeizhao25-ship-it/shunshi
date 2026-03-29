export default function DashboardPage() {
  const stats = [
    { label: '总用户数', value: '12,486', change: '+128 本月', color: 'bg-blue-500' },
    { label: '内容总数', value: '3,924', change: '+56 本周', color: 'bg-green-500' },
    { label: '安全事件', value: '7', change: '-3 较上周', color: 'bg-orange-500' },
    { label: '活跃告警', value: '3', change: '2 高优先级', color: 'bg-red-500' },
  ];

  const recentAlerts = [
    { id: 1, type: '高风险', message: '用户 U-1024 提交内容包含敏感词汇', time: '10 分钟前', level: 'red' },
    { id: 2, type: '中风险', message: 'Prompt模板 P-089 被频繁调用（异常流量）', time: '32 分钟前', level: 'orange' },
    { id: 3, type: '高风险', message: '检测到批量注册行为，IP: 203.x.x.x', time: '1 小时前', level: 'red' },
    { id: 4, type: '低风险', message: '用户 U-2087 连续3次登录失败', time: '2 小时前', level: 'yellow' },
    { id: 5, type: '中风险', message: '内容 C-4521 审核队列积压超过阈值', time: '3 小时前', level: 'orange' },
  ];

  const levelStyles: Record<string, string> = {
    red: 'bg-red-100 text-red-700',
    orange: 'bg-orange-100 text-orange-700',
    yellow: 'bg-yellow-100 text-yellow-700',
  };

  return (
    <div>
      <h2 className="text-2xl font-bold mb-6">仪表盘</h2>

      {/* Stats */}
      <div className="grid grid-cols-4 gap-6 mb-8">
        {stats.map((stat) => (
          <div key={stat.label} className="bg-white rounded-lg border border-gray-200 p-6">
            <div className="flex items-center gap-3 mb-3">
              <div className={`w-2 h-8 rounded ${stat.color}`} />
              <span className="text-sm text-gray-500">{stat.label}</span>
            </div>
            <div className="text-3xl font-bold">{stat.value}</div>
            <div className="text-sm text-gray-400 mt-1">{stat.change}</div>
          </div>
        ))}
      </div>

      {/* Recent Alerts */}
      <div className="bg-white rounded-lg border border-gray-200">
        <div className="px-6 py-4 border-b border-gray-200">
          <h3 className="font-semibold">最近告警</h3>
        </div>
        <div className="divide-y divide-gray-100">
          {recentAlerts.map((alert) => (
            <div key={alert.id} className="flex items-center justify-between px-6 py-4">
              <div className="flex items-center gap-4">
                <span className={`px-2.5 py-1 rounded text-xs font-medium ${levelStyles[alert.level]}`}>
                  {alert.type}
                </span>
                <span className="text-sm text-gray-700">{alert.message}</span>
              </div>
              <span className="text-xs text-gray-400 whitespace-nowrap ml-4">{alert.time}</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
