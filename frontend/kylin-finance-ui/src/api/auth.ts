import request from '@/utils/request'
import type { AxiosResponse } from 'axios'

/**
 * 登录请求参数
 */
export interface LoginParams {
  username: string
  password: string
}

/**
 * 登录响应数据
 */
export interface LoginResponse {
  token: string
  permissions: string[]
}

/**
 * API 响应包装类型
 */
interface ApiResponse<T> {
  code: number
  msg: string
  data: T
}

/**
 * 登录接口
 */
export const loginApi = (params: LoginParams): Promise<ApiResponse<LoginResponse>> => {
  return request({
    url: '/admin/auth/login',
    method: 'post',
    data: params
  })
}

/**
 * 获取用户信息接口
 */
export const getUserInfoApi = (): Promise<ApiResponse<any>> => {
  return request({
    url: '/admin/auth/info',
    method: 'get'
  })
}

/**
 * 登出接口（可选，JWT 无状态，主要用于服务端黑名单机制）
 */
export const logoutApi = (): Promise<ApiResponse<void>> => {
  return request({
    url: '/admin/auth/logout',
    method: 'post'
  })
}

