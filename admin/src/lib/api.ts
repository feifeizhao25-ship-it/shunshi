const API_BASE = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

export interface ApiResponse<T = any> {
  success?: boolean;
  data?: T;
  error?: string;
  total?: number;
  page?: number;
  page_size?: number;
}

/**
 * 获取存储的 Admin Token
 * 优先从 localStorage 读取，回退到环境变量（兼容旧版本）
 */
function getAdminToken(): string {
  if (typeof window !== 'undefined') {
    const stored = localStorage.getItem('admin_token');
    if (stored) return stored;
  }
  return process.env.NEXT_PUBLIC_ADMIN_TOKEN || '';
}

/**
 * 设置 Admin Token
 */
export function setAdminToken(token: string): void {
  if (typeof window !== 'undefined') {
    localStorage.setItem('admin_token', token);
  }
}

/**
 * 清除 Admin Token
 */
export function clearAdminToken(): void {
  if (typeof window !== 'undefined') {
    localStorage.removeItem('admin_token');
  }
}

/**
 * 检查是否已登录
 */
export function isLoggedIn(): boolean {
  return !!getAdminToken();
}

export async function fetchAPI<T = any>(path: string, options?: RequestInit): Promise<T> {
  const token = getAdminToken();
  
  try {
    const res = await fetch(`${API_BASE}${path}`, {
      ...options,
      headers: {
        'X-Admin-Token': token,
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
        ...options?.headers,
      },
      cache: 'no-store',
    });
    
    if (res.status === 401) {
      // Token 过期，清除并提示
      clearAdminToken();
      if (typeof window !== 'undefined') {
        window.location.href = '/login';
      }
      return { data: [], error: 'Unauthorized' } as any;
    }
    
    if (!res.ok) {
      console.error('API Error:', res.status, res.statusText, path);
      const errorData = await res.json().catch(() => ({}));
      return { data: [], error: errorData.detail || res.statusText } as any;
    }
    
    return res.json();
  } catch (err) {
    console.error('API fetch failed for', path, err);
    return { data: [], error: 'Network error' } as any;
  }
}

export async function postAPI<T = any>(path: string, body: any): Promise<T> {
  return fetchAPI<T>(path, {
    method: 'POST',
    body: JSON.stringify(body),
  });
}

export async function putAPI<T = any>(path: string, body: any): Promise<T> {
  return fetchAPI<T>(path, {
    method: 'PUT',
    body: JSON.stringify(body),
  });
}

export async function deleteAPI<T = any>(path: string): Promise<T> {
  return fetchAPI<T>(path, { method: 'DELETE' });
}

export async function patchAPI<T = any>(path: string, body: any): Promise<T> {
  return fetchAPI<T>(path, {
    method: 'PATCH',
    body: JSON.stringify(body),
  });
}

export default API_BASE;
