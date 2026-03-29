const API_BASE = 'http://localhost:4000';
const ADMIN_TOKEN = 'dev-admin-token';

export async function fetchAPI<T = any>(path: string): Promise<T | { data: []; error: number }> {
  try {
    const res = await fetch(`${API_BASE}${path}`, {
      headers: {
        'X-Admin-Token': ADMIN_TOKEN,
        'Content-Type': 'application/json',
      },
      cache: 'no-store',
    });
    if (!res.ok) return { data: [], error: res.status } as any;
    return res.json();
  } catch {
    return { data: [], error: -1 } as any;
  }
}
