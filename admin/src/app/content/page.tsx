import { fetchAPI } from '../../lib/api';

interface Content {
  id: string;
  title?: string;
  category?: string;
  author?: string;
  status?: string;
  createdAt?: string;
  updatedAt?: string;
}

async function getContentList(): Promise<Content[]> {
  const res = await fetchAPI('/api/v1/cms/content');
  if ('error' in res && res.error) {
    return [
      { id: 'C-4001', title: '春季养生指南', category: '养生知识', author: '编辑-A', status: 'published', createdAt: '2026-03-01', updatedAt: '2026-03-15' },
      { id: 'C-4002', title: '二十四节气饮食建议', category: '饮食调理', author: '编辑-B', status: 'published', createdAt: '2026-03-05', updatedAt: '2026-03-14' },
      { id: 'C-4003', title: '春季经络穴位保健', category: '经络养生', author: '编辑-A', status: 'review', createdAt: '2026-03-10', updatedAt: '2026-03-16' },
      { id: 'C-4004', title: '情志调养与心理健康', category: '心理健康', author: '编辑-C', status: 'draft', createdAt: '2026-03-12', updatedAt: '2026-03-16' },
      { id: 'C-4005', title: '春季运动养生方法', category: '运动养生', author: '编辑-B', status: 'published', createdAt: '2026-03-14', updatedAt: '2026-03-17' },
      { id: 'C-4006', title: '中药茶饮推荐', category: '饮食调理', author: '编辑-A', status: 'review', createdAt: '2026-03-16', updatedAt: '2026-03-18' },
    ];
  }
  const data = (res as any).data || res;
  return Array.isArray(data) ? data : [];
}

const statusMap: Record<string, { label: string; style: string }> = {
  published: { label: '已发布', style: 'bg-green-100 text-green-700' },
  review: { label: '审核中', style: 'bg-orange-100 text-orange-700' },
  draft: { label: '草稿', style: 'bg-gray-100 text-gray-600' },
};

export default async function ContentPage() {
  const contents = await getContentList();

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h2 className="text-2xl font-bold">内容管理</h2>
        <span className="text-sm text-gray-500">共 {contents.length} 篇内容</span>
      </div>

      <div className="bg-white rounded-lg border border-gray-200 overflow-hidden">
        <table className="w-full text-sm">
          <thead>
            <tr className="bg-gray-50 border-b border-gray-200">
              <th className="text-left px-6 py-3 font-medium text-gray-500">内容ID</th>
              <th className="text-left px-6 py-3 font-medium text-gray-500">标题</th>
              <th className="text-left px-6 py-3 font-medium text-gray-500">分类</th>
              <th className="text-left px-6 py-3 font-medium text-gray-500">作者</th>
              <th className="text-left px-6 py-3 font-medium text-gray-500">状态</th>
              <th className="text-left px-6 py-3 font-medium text-gray-500">创建时间</th>
              <th className="text-left px-6 py-3 font-medium text-gray-500">更新时间</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {contents.map((item) => {
              const st = statusMap[item.status || ''] || { label: item.status || '未知', style: 'bg-gray-100 text-gray-600' };
              return (
                <tr key={item.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4 font-mono text-xs">{item.id}</td>
                  <td className="px-6 py-4 font-medium">{item.title || '-'}</td>
                  <td className="px-6 py-4 text-gray-500">{item.category || '-'}</td>
                  <td className="px-6 py-4 text-gray-500">{item.author || '-'}</td>
                  <td className="px-6 py-4">
                    <span className={`px-2 py-0.5 rounded text-xs ${st.style}`}>{st.label}</span>
                  </td>
                  <td className="px-6 py-4 text-gray-500">{item.createdAt || '-'}</td>
                  <td className="px-6 py-4 text-gray-500">{item.updatedAt || '-'}</td>
                </tr>
              );
            })}
          </tbody>
        </table>
        {contents.length === 0 && (
          <div className="text-center py-12 text-gray-400">暂无内容数据</div>
        )}
      </div>
    </div>
  );
}
