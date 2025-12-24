import { defineStore } from 'pinia'
import { ref } from 'vue'

export const useAuthStore = defineStore('auth', () => {
  // Token
  const token = ref<string>('')
  
  // 权限列表
  const permissions = ref<string[]>([])

  /**
   * 初始化：从 localStorage 恢复 Token 和权限
   */
  const initAuth = () => {
    const storedToken = localStorage.getItem('token')
    const storedPermissions = localStorage.getItem('permissions')
    
    if (storedToken) {
      token.value = storedToken
    }
    
    if (storedPermissions) {
      try {
        permissions.value = JSON.parse(storedPermissions)
      } catch (e) {
        console.error('解析权限列表失败:', e)
        permissions.value = []
      }
    }
  }

  /**
   * 设置认证信息（登录成功后调用）
   */
  const setAuth = (newToken: string, newPermissions: string[]) => {
    token.value = newToken
    permissions.value = newPermissions
    
    // 存储到 localStorage
    localStorage.setItem('token', newToken)
    localStorage.setItem('permissions', JSON.stringify(newPermissions))
  }

  /**
   * 清除认证信息（退出登录时调用）
   */
  const clearAuth = () => {
    token.value = ''
    permissions.value = []
    localStorage.removeItem('token')
    localStorage.removeItem('permissions')
    // 同时清除记住的用户名
    localStorage.removeItem('rememberedUsername')
  }

  /**
   * 登出方法（完整的登出流程）
   * @param callApi 是否调用后端登出接口（默认 false，因为 JWT 是无状态的）
   */
  const logout = async (callApi: boolean = false) => {
    try {
      // 如果需要，调用后端登出接口（用于服务端黑名单机制等）
      if (callApi) {
        const { logoutApi } = await import('@/api/auth')
        await logoutApi().catch(() => {
          // 即使后端登出失败，也继续执行前端登出流程
          console.warn('后端登出接口调用失败，继续执行前端登出')
        })
      }
    } catch (error) {
      // 忽略错误，确保前端登出流程能正常执行
      console.warn('登出过程中发生错误:', error)
    } finally {
      // 无论后端是否成功，都清除前端认证信息
      clearAuth()
    }
  }

  /**
   * 检查是否有 Token（是否已登录）
   */
  const isAuthenticated = () => {
    return !!token.value
  }

  /**
   * 检查是否有某个权限
   */
  const hasPermission = (permission: string) => {
    return permissions.value.includes(permission)
  }

  /**
   * 检查是否有任意一个权限
   */
  const hasAnyPermission = (permissionList: string[]) => {
    return permissionList.some(permission => permissions.value.includes(permission))
  }

  // 初始化
  initAuth()

  return {
    token,
    permissions,
    setAuth,
    clearAuth,
    logout,
    isAuthenticated,
    hasPermission,
    hasAnyPermission
  }
})

