export function formatDate(value?: string | null): string {
  if (!value) return '-';
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return '-';
  return date.toLocaleDateString('zh-CN');
}

export function formatDateTime(value?: string | null): string {
  if (!value) return '-';
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return '-';
  return date.toLocaleString('zh-CN', { hour12: false });
}

export function asList<T>(payload: unknown): T[] {
  if (Array.isArray(payload)) return payload as T[];
  if (payload && typeof payload === 'object' && Array.isArray((payload as { data?: unknown }).data)) {
    return (payload as { data: T[] }).data;
  }
  return [];
}

export function readError(payload: unknown): string {
  if (!payload || typeof payload !== 'object' || Array.isArray(payload)) return '';
  const error = (payload as { error?: unknown }).error;
  if (error) return '数据暂时读不到，请稍后刷新。';
  return '';
}

/** 节气接口给的是每年重复的月-日，不补一个虚构年份。 */
export function formatMonthDay(value?: string | null): string {
  if (!value) return '';
  const match = /^(\d{1,2})-(\d{1,2})$/.exec(value);
  if (!match) return value;
  return `${Number(match[1])}月${Number(match[2])}日`;
}
