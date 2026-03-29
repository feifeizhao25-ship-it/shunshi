export default function SafetyPage() {
  const auditLogs = [
    { id: 1, action: '内容审核', operator: '系统', detail: '自动审核内容 C-4521 通过', time: '2026-03-18 19:02', risk: '低' },
    { id: 2, action: '用户封禁', operator: 'Admin', detail: '封禁用户 U-1024（违规发布内容）', time: '2026-03-18 18:45', risk: '高' },
    { id: 3, action: '权限变更', operator: 'Admin', detail: '用户 U-2087 角色从 user 变更为 editor', time: '2026-03-18 17:30', risk: '中' },
    { id: 4, action: '批量注册拦截', operator: '系统', detail: '拦截来自 203.x.x.x 的批量注册请求（12次/分钟）', time: '2026-03-18 16:20', risk: '高' },
    { id: 5, action: 'Prompt审核', operator: '系统', detail: 'Prompt P-089 包含潜在注入风险，已自动标记', time: '2026-03-18 15:10', risk: '中' },
    { id: 6, action: '登录异常', operator: '系统', detail: '用户 U-3087 在非常用地区登录，已发送验证码', time: '2026-03-18 14:55', risk: '中' },
    { id: 7, action: '内容下架', operator: 'Admin', detail: '手动下架内容 C-3998（用户举报）', time: '2026-03-18 13:40', risk: '中' },
    { id: 8, action: '系统备份', operator: '系统', detail: '每日自动数据库备份完成', time: '2026-03-18 03:00', risk: '低' },
  ];

  const riskStyles: Record<string, string> = {
    '高': 'bg-red-100 text-red-700',
    '中': 'bg-orange-100 text-orange-700',
    '低': 'bg-green-100 text-green-700',
  };

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h2 className="text-2xl font-bold">安全审计</h2>
        <span className="text-sm text-gray-500">共 {auditLogs.length} 条记录</span>
      </div>

      <div className="bg-white rounded-lg border border-gray-200 overflow-hidden">
        <table className="w-full text-sm">
          <thead>
            <tr className="bg-gray-50 border-b border-gray-200">
              <th className="text-left px-6 py-3 font-medium text-gray-500">#</th>
              <th className="text-left px-6 py-3 font-medium text-gray-500">操作类型</th>
              <th className="text-left px-6 py-3 font-medium text-gray-500">执行者</th>
              <th className="text-left px-6 py-3 font-medium text-gray-500">详情</th>
              <th className="text-left px-6 py-3 font-medium text-gray-500">风险等级</th>
              <th className="text-left px-6 py-3 font-medium text-gray-500">时间</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {auditLogs.map((log) => (
              <tr key={log.id} className="hover:bg-gray-50">
                <td className="px-6 py-4 text-gray-400">{log.id}</td>
                <td className="px-6 py-4 font-medium">{log.action}</td>
                <td className="px-6 py-4 text-gray-500">{log.operator}</td>
                <td className="px-6 py-4 text-gray-600 max-w-xs truncate">{log.detail}</td>
                <td className="px-6 py-4">
                  <span className={`px-2 py-0.5 rounded text-xs ${riskStyles[log.risk]}`}>{log.risk}</span>
                </td>
                <td className="px-6 py-4 text-gray-400 text-xs whitespace-nowrap">{log.time}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
