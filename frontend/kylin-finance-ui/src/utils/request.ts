import axios from 'axios'
import type { AxiosResponse, InternalAxiosRequestConfig } from 'axios'
import { ElMessage } from 'element-plus'
import { useAuthStore } from '@/stores/authStore'

/**
 * 处理 401 未授权逻辑
 * 防止由于多个并发请求失败导致的多次跳转及登录页死循环
 */
const handleUnauthorized = () => {
  const authStore = useAuthStore()
  authStore.clearAuth()
  
  // 获取当前页面路径
  const currentPath = window.location.pathname
  
  // 只有在当前页面不是登录页时才触发跳转
  if (currentPath !== '/login' && currentPath !== '/login/index') {
    window.location.href = '/login'
  }
}

// 创建axios实例
const request = axios.create({
  baseURL: import.meta.env.VITE_APP_BASE_API || '/dev-api',
  timeout: 10000
})

// 请求拦截器
request.interceptors.request.use(
  (config: InternalAxiosRequestConfig) => {
    // 强制添加 X-Requested-With Header，声明这是 AJAX 请求
    config.headers['X-Requested-With'] = 'XMLHttpRequest'
    
    // 从 store 获取 token 并添加到请求头
    const authStore = useAuthStore()
    const token = authStore.token
    
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    
    // 处理 Content-Type
    if (config.data && typeof config.data === 'object' && 
        !(config.data instanceof FormData) && 
        !(config.data instanceof Blob) && 
        !(config.data instanceof ArrayBuffer)) {
      if (!config.headers['Content-Type'] && !config.headers['content-type']) {
        config.headers['Content-Type'] = 'application/json;charset=utf-8'
      }
    }
    
    return config
  },
  (error) => {
    return Promise.reject(error)
  }
)

// 响应拦截器
request.interceptors.response.use(
  (response: AxiosResponse) => {
    // 如果是 blob 响应（如 Excel 导出），直接返回
    if (response.config.responseType === 'blob' || response.data instanceof Blob) {
      return response
    }
    
    const res = response.data
    
    // 1. 处理业务状态码 401
    if (res.code === 401) {
      handleUnauthorized()
      return Promise.reject(new Error('登录状态已过期，请重新登录'))
    }

    // 2. 处理非 200 的其他业务逻辑错误
    if (res.code !== 200) {
      const errorMsg = res.msg || res.message || '请求失败'
      ElMessage.error(errorMsg)
      return Promise.reject(new Error(errorMsg))
    }

    return res
  },
  async (error) => {
    // 3. 处理 HTTP 状态码 401（后端网关或容器拦截）
    if (error.response?.status === 401) {
      handleUnauthorized()
      return Promise.reject(new Error('未授权，请重新登录'))
    }
    
    let errorMsg = '系统未知错误'
    
    if (error.response) {
      const responseData = error.response.data
      
      if (responseData instanceof Blob) {
        try {
          const text = await responseData.text()
          const jsonData = JSON.parse(text)
          errorMsg = jsonData.message || jsonData.msg || `请求失败 (${error.response.status})`
        } catch (e) {
          errorMsg = `请求失败 (${error.response.status})`
        }
      } else if (typeof responseData === 'object' && responseData !== null) {
        errorMsg = responseData.message || responseData.msg || `请求失败 (${error.response.status})`
      } else if (typeof responseData === 'string') {
        errorMsg = responseData
      } else {
        errorMsg = `请求失败 (${error.response.status})`
      }
    } else if (error.message) {
      errorMsg = error.message
    } else if (error.code === 'ERR_NETWORK') {
      errorMsg = '网络连接失败，请检查网络设置'
    } else if (error.code === 'ECONNABORTED') {
      errorMsg = '请求超时，请稍后重试'
    }
    
    // 过滤掉重复的 401 报错弹窗（可选）
    if (error.response?.status !== 401) {
      ElMessage.error(String(errorMsg))
    }
    
    return Promise.reject(error)
  }
)

export { request }
export default request