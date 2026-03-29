export default function PromptsPage() {
  const prompts = [
    { id: 'P-001', name: '养生问答助手', version: 'v2.3', category: '养生咨询', status: 'active', calls: '12,847', lastUsed: '2026-03-18 19:00', description: '通用养生知识问答，涵盖饮食、运动、情志调养等领域' },
    { id: 'P-002', name: '节气饮食推荐', version: 'v1.8', category: '饮食调理', status: 'active', calls: '8,234', lastUsed: '2026-03-18 18:55', description: '基于当前节气推荐时令食材和食疗方案' },
    { id: 'P-003', name: '经络穴位查询', version: 'v1.2', category: '经络养生', status: 'active', calls: '5,621', lastUsed: '2026-03-18 18:40', description: '根据症状推荐相关经络和穴位保健方法' },
    { id: 'P-004', name: '体质辨识评估', version: 'v3.0', category: '体质分析', status: 'active', calls: '3,456', lastUsed: '2026-03-18 18:30', description: '基于用户问卷进行中医体质辨识和个性化建议' },
    { id: 'P-005', name: '运动养生规划', version: 'v1.0', category: '运动养生', status: 'draft', calls: '0', lastUsed: '从未使用', description: '根据用户体质和季节推荐合适的运动方案' },
    { id: 'P-006', name: '心理健康评估', version: 'v2.1', category: '心理健康', status: 'review', calls: '1,890', lastUsed: '2026-03-18 17:20', description: '基于情绪量表评估用户心理健康状态，提供调养建议' },
    { id: 'P-089', name: '通用对话模板', version: 'v1.5', category: '通用', status: 'flagged', calls: '42,100', lastUsed: '2026-03-18 18:20', description: '通用对话 Prompt 模板，近期检测到异常调用模式' },
  ];

  const statusMap: Record<string, { label: string; style: string }> = {
    active: { label: '已启用', style: 'bg-green-100 text-green-700' },
    draft: { label: '草稿', style: 'bg-gray-100 text-gray-600' },
    review: { label: '审核中', style: 'bg-orange-100 text-orange-700' },
    flagged: { label: '已标记', style: 'bg-red-100 text-red-700' },
  };

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h2 className="text-2xl font-bold">Prompt管理</h2>
        <span className="text-sm text-gray-500">共 {prompts.length} 个模板</span>
      </div>

      <div className="space-y-4">
        {prompts.map((prompt) => {
          const st = statusMap[prompt.status] || { label: prompt.status, style: 'bg-gray-100 text-gray-600' };
          return (
            <div key={prompt.id} className="bg-white rounded-lg border border-gray-200 p-6 hover:shadow-sm transition-shadow">
              <div className="flex items-start justify-between mb-2">
                <div className="flex items-center gap-3">
                  <span className="font-mono text-xs text-gray-400">{prompt.id}</span>
                  <h3 className="font-semibold text-base">{prompt.name}</h3>
                  <span className="text-xs text-gray-400">{prompt.version}</span>
                  <span className={`px-2 py-0.5 rounded text-xs ${st.style}`}>{st.label}</span>
                </div>
                <div className="text-right text-sm text-gray-500">
                  调用量: <span className="font-mono">{prompt.calls}</span>
                </div>
              </div>
              <p className="text-sm text-gray-500 mb-3">{prompt.description}</p>
              <div className="flex items-center gap-6 text-xs text-gray-400">
                <span>分类: {prompt.category}</span>
                <span>最近使用: {prompt.lastUsed}</span>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
