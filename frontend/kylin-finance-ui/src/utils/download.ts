import { ElMessage } from 'element-plus'
import type { AxiosResponse } from 'axios'

/**
 * 下载Excel文件的通用工具函数
 * @param response Axios响应对象（responseType为'blob'）
 * @param filename 下载的文件名（不含扩展名）
 * @returns Promise<void>
 */
export async function downloadExcel(response: AxiosResponse<Blob>, filename: string): Promise<void> {
  try {
    // 检查响应是否为 Blob
    let blob: Blob
    if (response.data instanceof Blob) {
      blob = response.data
    } else {
      // 如果不是 Blob，可能是错误响应，尝试解析
      blob = new Blob([response.data])
    }
    
    // 检查 blob 是否是 JSON 错误消息（通常错误响应的 Content-Type 是 application/json）
    // 通过检查 blob 的大小和类型来判断
    const contentType = response.headers['content-type'] || ''
    if (contentType.includes('application/json') || blob.size < 1000) {
      // 可能是 JSON 错误消息，尝试解析
      const text = await new Promise<string>((resolve, reject) => {
        const reader = new FileReader()
        reader.onload = () => resolve(reader.result as string)
        reader.onerror = reject
        reader.readAsText(blob)
      })
      
      try {
        const errorData = JSON.parse(text)
        const errorMessage = errorData.msg || errorData.message || '导出失败'
        ElMessage.error(errorMessage)
        return
      } catch (e) {
        // 如果不是 JSON，继续处理
      }
    }
    
    // 创建下载链接
    const url = window.URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = url
    link.download = `${filename}.xlsx`
    
    // 添加到 DOM，触发下载，然后移除
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
    
    // 清理 URL 对象
    window.URL.revokeObjectURL(url)
    
    ElMessage.success('Excel导出成功')
  } catch (error: any) {
    console.error('导出Excel失败:', error)
    
    // 尝试从错误响应中提取错误信息
    if (error.response?.data instanceof Blob) {
      try {
        const text = await new Promise<string>((resolve, reject) => {
          const reader = new FileReader()
          reader.onload = () => resolve(reader.result as string)
          reader.onerror = reject
          reader.readAsText(error.response.data)
        })
        
        const errorData = JSON.parse(text)
        const errorMessage = errorData.msg || errorData.message || '导出失败'
        ElMessage.error(errorMessage)
        return
      } catch (e) {
        // 解析失败，使用默认错误消息
      }
    }
    
    ElMessage.error(error.message || '导出Excel失败，请重试')
    throw error
  }
}

/**
 * 处理Excel导出错误的辅助函数
 * @param error 错误对象
 */
export async function handleExcelExportError(error: any): Promise<void> {
  console.error('导出Excel失败:', error)
  
  // 尝试从错误响应中提取错误信息
  if (error.response?.data instanceof Blob) {
    try {
      const text = await new Promise<string>((resolve, reject) => {
        const reader = new FileReader()
        reader.onload = () => resolve(reader.result as string)
        reader.onerror = reject
        reader.readAsText(error.response.data)
      })
      
      const errorData = JSON.parse(text)
      const errorMessage = errorData.msg || errorData.message || '导出失败'
      ElMessage.error(errorMessage)
      return
    } catch (e) {
      // 解析失败，使用默认错误消息
    }
  }
  
  ElMessage.error(error.message || '导出Excel失败，请重试')
}

