<template>
  <div v-if="hasError" class="error-boundary">
    <el-result
      icon="error"
      title="页面加载出错"
      :sub-title="errorMessage"
    >
      <template #extra>
        <el-button type="primary" @click="handleReset">重试</el-button>
        <el-button @click="handleGoHome">返回首页</el-button>
      </template>
    </el-result>
  </div>
  <slot v-else />
</template>

<script setup lang="ts">
import { ref, onErrorCaptured, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'

const router = useRouter()
const hasError = ref(false)
const errorMessage = ref('')

// 捕获组件渲染错误
onErrorCaptured((err: Error, instance, info) => {
  console.error('ErrorBoundary 捕获到错误:', err, info)
  console.error('错误堆栈:', err.stack)
  console.error('组件实例:', instance)
  console.error('错误信息:', info)
  
  hasError.value = true
  errorMessage.value = err.message || '未知错误，请刷新页面重试'
  
  // 记录错误信息
  ElMessage.error('页面发生错误，请查看错误信息')
  
  // 返回 false 阻止错误继续传播
  return false
})

// 捕获全局未处理的错误
const handleGlobalError = (event: ErrorEvent) => {
  console.error('全局错误捕获:', event.error)
  if (!hasError.value) {
    hasError.value = true
    errorMessage.value = event.error?.message || event.message || '发生了未知错误'
    ElMessage.error('应用发生错误，请刷新页面重试')
  }
}

// 捕获未处理的Promise拒绝
const handleUnhandledRejection = (event: PromiseRejectionEvent) => {
  console.error('未处理的Promise拒绝:', event.reason)
  if (!hasError.value) {
    hasError.value = true
    errorMessage.value = event.reason?.message || String(event.reason) || '异步操作失败'
    ElMessage.error('异步操作失败，请刷新页面重试')
  }
}

onMounted(() => {
  // 监听全局错误
  window.addEventListener('error', handleGlobalError)
  window.addEventListener('unhandledrejection', handleUnhandledRejection)
})

onUnmounted(() => {
  // 清理事件监听
  window.removeEventListener('error', handleGlobalError)
  window.removeEventListener('unhandledrejection', handleUnhandledRejection)
})

const handleReset = () => {
  hasError.value = false
  errorMessage.value = ''
  // 刷新当前页面
  window.location.reload()
}

const handleGoHome = () => {
  router.push('/dashboard')
}
</script>

<style scoped>
.error-boundary {
  padding: 40px 20px;
  min-height: 400px;
  display: flex;
  align-items: center;
  justify-content: center;
}
</style>

