import axios from 'axios'
import type { AxiosResponse, InternalAxiosRequestConfig } from 'axios'
import { ElMessage } from 'element-plus'
import { useAuthStore } from '@/stores/authStore'

// 创建axios实例
const request = axios.create({
  baseURL: import.meta.env.VITE_APP_BASE_API || '/dev-api',
  timeout: 10000
})

// 请求拦截器
request.interceptors.request.use(
  (config: InternalAxiosRequestConfig) => {
    // 强制添加 X-Requested-With Header，声明这是 AJAX 请求
    // 防止后端安全框架误以为是浏览器页面请求而进行重定向
    config.headers['X-Requested-With'] = 'XMLHttpRequest'
    
    // 从 store 获取 token 并添加到请求头
    const authStore = useAuthStore()
    const token = authStore.token
    
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    
    // 处理 Content-Type
    // 只有当请求体存在且是普通对象时，才设置 Content-Type
    // 排除 FormData、Blob、ArrayBuffer 等特殊类型
    if (config.data && typeof config.data === 'object' && 
        !(config.data instanceof FormData) && 
        !(config.data instanceof Blob) && 
        !(config.data instanceof ArrayBuffer)) {
      // 如果还没有设置 Content-Type，则设置为 application/json
      if (!config.headers['Content-Type'] && !config.headers['content-type']) {
        config.headers['Content-Type'] = 'application/json;charset=utf-8'
      }
    }
    
    // 如果是报销单相关的请求，打印请求数据用于调试
    if (config.url?.includes('biz-expense-claim')) {
      console.log('=== Axios 请求拦截器 - 报销单请求 ===')
      console.log('请求URL:', config.method?.toUpperCase(), config.url)
      console.log('请求数据 (data):', config.data)
      if (config.data) {
        try {
          const dataObj = typeof config.data === 'string' ? JSON.parse(config.data) : config.data
          console.log('解析后的数据对象:', JSON.stringify(dataObj, null, 2))
          if (dataObj.claimDate) {
            console.log('  claimDate:', dataObj.claimDate, '类型:', typeof dataObj.claimDate)
          }
          if (dataObj.applicantId !== undefined) {
            console.log('  applicantId:', dataObj.applicantId, '类型:', typeof dataObj.applicantId)
          }
          if (dataObj.creditAccountId !== undefined) {
            console.log('  creditAccountId:', dataObj.creditAccountId, '类型:', typeof dataObj.creditAccountId)
          }
          if (dataObj.details && Array.isArray(dataObj.details)) {
            console.log('  details数组长度:', dataObj.details.length)
            dataObj.details.forEach((detail: any, index: number) => {
              console.log(`    details[${index}]:`, {
                debitAccountId: detail.debitAccountId,
                debitAccountId类型: typeof detail.debitAccountId,
                amount: detail.amount,
                amount类型: typeof detail.amount
              })
            })
          }
        } catch (e) {
          console.log('解析请求数据失败:', e)
        }
      }
      console.log('请求头 (headers):', config.headers)
      console.log('=====================================')
    }
    
    return config
  },
  (error) => {
    return Promise.reject(error)
  }
)

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

// 响应拦截器
request.interceptors.response.use(
  (response: AxiosResponse) => {
    // 如果是 blob 响应（如 Excel 导出），直接返回完整的 response 对象
    // 这样调用方可以访问 response.data (Blob) 和 response.headers
    if (response.config.responseType === 'blob' || response.data instanceof Blob) {
      return response
    }
    
    const res = response.data
    
    // 处理业务状态码 401（后端返回的业务错误码）
    if (res.code === 401) {
      handleUnauthorized()
      return Promise.reject(new Error('登录状态已过期，请重新登录'))
    }
    
    if (res.code !== 200) {
      // 只有在非404错误时才显示错误消息
      if (response.status !== 404) {
        ElMessage.error(res.msg || '请求失败')
      }
      return Promise.reject(new Error(res.msg || '请求失败'))
    }
    return res
  },
  async (error) => {
    // 处理 HTTP 状态码 401（后端网关或容器拦截）
    if (error.response?.status === 401) {
      handleUnauthorized()
      return Promise.reject(new Error('未授权，请重新登录'))
    }
    
    // 404错误不显示通用错误消息，由具体业务处理
    if (error.response?.status === 404) {
      return Promise.reject(error)
    }
    // 网络错误也不显示，由业务层处理
    if (error.code === 'ERR_NETWORK') {
      return Promise.reject(error)
    }
    
    let errorMsg = '系统未知错误'
    
    // 优先判断 error.response 是否存在
    if (error.response) {
      const responseData = error.response.data
      
      // 如果后端返回的是 Blob（文件流）报错，需要将其转为 JSON 读取
      if (responseData instanceof Blob) {
        try {
          const text = await responseData.text()
          const jsonData = JSON.parse(text)
          errorMsg = jsonData.message || jsonData.msg || `请求失败 (${error.response.status})`
        } catch (e) {
          // 如果解析失败，使用默认错误信息
          errorMsg = `请求失败 (${error.response.status})`
        }
      } else if (typeof responseData === 'object' && responseData !== null) {
        // 尝试提取 error.response.data.message 或 error.response.data.msg
        errorMsg = responseData.message || responseData.msg || `请求失败 (${error.response.status})`
      } else if (typeof responseData === 'string') {
        errorMsg = responseData
      } else {
        errorMsg = `请求失败 (${error.response.status})`
      }
    } else if (error.message) {
      // 如果没有 response，使用 error.message
      errorMsg = error.message
    } else if (error.code === 'ECONNABORTED') {
      errorMsg = '请求超时，请稍后重试'
    }
    
    // 确保 errorMsg 是字符串类型
    if (typeof errorMsg !== 'string') {
      errorMsg = String(errorMsg)
    }
    
    // 其他错误才显示
    ElMessage.error(errorMsg)
    return Promise.reject(error)
  }
)

export default request
