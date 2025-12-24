import { createApp } from 'vue'
import { createPinia } from 'pinia'
import ElementPlus from 'element-plus'
import 'element-plus/dist/index.css'
import router from './router'
import App from './App.vue'
import { ElMessage } from 'element-plus'

const app = createApp(App)

app.use(createPinia())
app.use(router)
app.use(ElementPlus)

// 全局错误处理配置
app.config.errorHandler = (err: unknown, instance, info) => {
  console.error('Vue全局错误处理器捕获到错误:', err)
  console.error('组件实例:', instance)
  console.error('错误信息:', info)
  
  // 显示用户友好的错误提示
  const errorMessage = err instanceof Error ? err.message : String(err)
  ElMessage.error({
    message: '应用发生错误：' + errorMessage,
    duration: 5000,
    showClose: true
  })
  
  // 在生产环境中，可以将错误发送到错误追踪服务
  // if (import.meta.env.PROD) {
  //   // 发送错误到错误追踪服务（如Sentry）
  // }
}

// 捕获全局未处理的错误
window.addEventListener('error', (event) => {
  console.error('全局错误事件:', event.error)
  if (event.error) {
    ElMessage.error({
      message: '发生未处理的错误：' + (event.error.message || '未知错误'),
      duration: 5000,
      showClose: true
    })
  }
})

// 捕获未处理的Promise拒绝
window.addEventListener('unhandledrejection', (event) => {
  console.error('未处理的Promise拒绝:', event.reason)
  ElMessage.error({
    message: '异步操作失败：' + (event.reason?.message || String(event.reason) || '未知错误'),
    duration: 5000,
    showClose: true
  })
  // 阻止默认的错误处理行为（在控制台显示）
  event.preventDefault()
})

app.mount('#app')
