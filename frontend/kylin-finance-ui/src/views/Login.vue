<template>
  <div class="login-container" :class="{ 'fade-in': mounted }">
    <!-- 左侧 Banner -->
    <div class="login-banner">
      <div class="banner-content">
        <div class="logo-section">
          <div class="logo-icon">
            <svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
              <!-- 麒麟图标 SVG -->
              <circle cx="60" cy="60" r="55" fill="none" stroke="rgba(255,255,255,0.3)" stroke-width="2"/>
              <path d="M 30 80 Q 60 40, 90 80" stroke="rgba(255,255,255,0.8)" stroke-width="3" fill="none"/>
              <path d="M 50 60 Q 60 50, 70 60" stroke="rgba(255,255,255,0.8)" stroke-width="2" fill="none"/>
              <circle cx="45" cy="55" r="3" fill="rgba(255,255,255,0.9)"/>
              <circle cx="75" cy="55" r="3" fill="rgba(255,255,255,0.9)"/>
            </svg>
          </div>
          <h1 class="system-name">麒麟财务</h1>
          <p class="system-slogan">专注个人与小微企业的财务智慧</p>
        </div>
        <div class="banner-illustration">
          <svg viewBox="0 0 400 300" xmlns="http://www.w3.org/2000/svg">
            <!-- 财务图表插画 -->
            <defs>
              <linearGradient id="grad1" x1="0%" y1="0%" x2="100%" y2="100%">
                <stop offset="0%" style="stop-color:rgba(255,255,255,0.2);stop-opacity:1" />
                <stop offset="100%" style="stop-color:rgba(255,255,255,0.05);stop-opacity:1" />
              </linearGradient>
            </defs>
            <!-- 柱状图 -->
            <rect x="50" y="200" width="40" height="80" fill="rgba(255,255,255,0.3)" rx="4"/>
            <rect x="110" y="150" width="40" height="130" fill="rgba(255,255,255,0.4)" rx="4"/>
            <rect x="170" y="180" width="40" height="100" fill="rgba(255,255,255,0.35)" rx="4"/>
            <rect x="230" y="120" width="40" height="160" fill="rgba(255,255,255,0.45)" rx="4"/>
            <rect x="290" y="160" width="40" height="120" fill="rgba(255,255,255,0.3)" rx="4"/>
            <!-- 趋势线 -->
            <path d="M 50 220 Q 150 180, 250 140 T 350 160" stroke="rgba(255,255,255,0.5)" stroke-width="3" fill="none"/>
            <!-- 装饰圆点 -->
            <circle cx="100" cy="100" r="8" fill="rgba(255,255,255,0.2)"/>
            <circle cx="300" cy="80" r="6" fill="rgba(255,255,255,0.25)"/>
            <circle cx="200" cy="60" r="10" fill="rgba(255,255,255,0.15)"/>
          </svg>
        </div>
      </div>
    </div>

    <!-- 右侧表单 -->
    <div class="login-form-wrapper">
      <div class="form-container">
        <h2 class="form-title">欢迎登录</h2>
        
        <el-form
          ref="loginFormRef"
          :model="loginForm"
          :rules="loginRules"
          class="login-form"
          @submit.prevent="handleLogin"
        >
          <el-form-item prop="username">
            <el-input
              v-model="loginForm.username"
              placeholder="请输入用户名"
              size="large"
              :prefix-icon="User"
              clearable
              @keyup.enter="handleLogin"
            />
          </el-form-item>
          
          <el-form-item prop="password">
            <el-input
              v-model="loginForm.password"
              type="password"
              placeholder="请输入密码"
              size="large"
              :prefix-icon="Lock"
              show-password
              clearable
              @keyup.enter="handleLogin"
            />
          </el-form-item>
          
          <!-- 验证码字段（临时不校验，后端暂时没有验证码接口） -->
          <el-form-item>
            <div class="captcha-container">
              <el-input
                v-model="loginForm.captcha"
                placeholder="请输入验证码"
                size="large"
                class="captcha-input"
                clearable
                @keyup.enter="handleLogin"
              />
              <!-- 只有当验证码图片存在时才显示，否则显示加载占位符 -->
              <div
                v-if="captchaImage"
                class="captcha-image-wrapper"
              >
                <img
                  :src="captchaImage"
                  alt="验证码"
                  class="captcha-image"
                  @click="refreshCaptcha"
                />
              </div>
              <div
                v-else
                class="captcha-placeholder"
                @click="refreshCaptcha"
              >
                <el-icon class="loading-icon"><Loading /></el-icon>
                <span>点击加载验证码</span>
              </div>
            </div>
          </el-form-item>
          
          <el-form-item class="form-options">
            <el-checkbox v-model="loginForm.rememberMe">记住我</el-checkbox>
            <el-link type="primary" :underline="false" class="forgot-password">忘记密码？</el-link>
          </el-form-item>
          
          <el-form-item>
            <el-button
              type="primary"
              size="large"
              class="login-button"
              :loading="loading"
              @click="handleLogin"
            >
              {{ loading ? '登录中...' : '登录' }}
            </el-button>
          </el-form-item>
        </el-form>

        <div class="form-footer">
          <p class="copyright">Copyright © 2024 Kylin Finance</p>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { ElMessage, type FormInstance, type FormRules } from 'element-plus'
import { User, Lock, Loading } from '@element-plus/icons-vue'
import { loginApi } from '@/api/auth'
import { useAuthStore } from '@/stores/authStore'

const router = useRouter()
const route = useRoute()
const authStore = useAuthStore()

// 表单引用
const loginFormRef = ref<FormInstance>()

// 加载状态
const loading = ref(false)

// 页面挂载状态（用于动画）
const mounted = ref(false)

// 验证码图片
const captchaImage = ref('')

// 存储生成的验证码（用于验证）
const captchaCode = ref('')

// 登录表单数据
const loginForm = reactive({
  username: '',
  password: '',
  captcha: '',
  rememberMe: false
})

// 表单验证规则（临时移除验证码校验）
const loginRules: FormRules = {
  username: [
    { required: true, message: '请输入用户名', trigger: 'blur' }
  ],
  password: [
    { required: true, message: '请输入密码', trigger: 'blur' },
    { min: 6, message: '密码长度不能少于6位', trigger: 'blur' }
  ]
  // 临时移除验证码校验规则
  // captcha: [
  //   { validator: validateCaptcha, trigger: 'blur' }
  // ]
}

/**
 * 生成验证码图片
 */
const generateCaptcha = (): string => {
  const canvas = document.createElement('canvas')
  const ctx = canvas.getContext('2d')
  
  if (!ctx) return ''
  
  canvas.width = 120
  canvas.height = 40
  
  // 背景色
  ctx.fillStyle = '#f5f7fa'
  ctx.fillRect(0, 0, canvas.width, canvas.height)
  
  // 生成4位随机字符
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'
  let code = ''
  for (let i = 0; i < 4; i++) {
    code += chars.charAt(Math.floor(Math.random() * chars.length))
  }
  
  // 绘制字符
  ctx.font = 'bold 20px Arial'
  ctx.textAlign = 'center'
  ctx.textBaseline = 'middle'
  
  for (let i = 0; i < code.length; i++) {
    ctx.fillStyle = `rgb(${Math.floor(Math.random() * 100)}, ${Math.floor(Math.random() * 100)}, ${Math.floor(Math.random() * 100)})`
    ctx.fillText(
      code[i],
      20 + i * 25 + Math.random() * 5,
      20 + Math.random() * 5
    )
  }
  
  // 绘制干扰线
  for (let i = 0; i < 3; i++) {
    ctx.strokeStyle = `rgba(${Math.floor(Math.random() * 200)}, ${Math.floor(Math.random() * 200)}, ${Math.floor(Math.random() * 200)}, 0.3)`
    ctx.beginPath()
    ctx.moveTo(Math.random() * canvas.width, Math.random() * canvas.height)
    ctx.lineTo(Math.random() * canvas.width, Math.random() * canvas.height)
    ctx.stroke()
  }
  
  // 绘制干扰点
  for (let i = 0; i < 30; i++) {
    ctx.fillStyle = `rgba(${Math.floor(Math.random() * 200)}, ${Math.floor(Math.random() * 200)}, ${Math.floor(Math.random() * 200)}, 0.5)`
    ctx.fillRect(Math.random() * canvas.width, Math.random() * canvas.height, 2, 2)
  }
  
  // 存储验证码（用于后续验证）
  captchaCode.value = code
  
  // 清空用户输入的验证码
  loginForm.captcha = ''
  
  return canvas.toDataURL('image/png')
}

/**
 * 刷新验证码
 */
const refreshCaptcha = () => {
  captchaImage.value = generateCaptcha()
}

/**
 * 处理登录
 */
const handleLogin = async () => {
  if (!loginFormRef.value) return

  // 表单验证（只验证用户名和密码）
  await loginFormRef.value.validate((valid) => {
    if (!valid) {
      return false
    }
  })

  // 临时处理：在调用 API 之前，强制给验证码赋值默认值
  // 因为后端暂时没有验证码接口，防止后端因为该字段为空而报错
  loginForm.captcha = '1234'

  loading.value = true

  try {
    // 调用登录接口
    const response = await loginApi({
      username: loginForm.username,
      password: loginForm.password
    })

    if (response.code === 200 && response.data) {
      const { token, permissions } = response.data
      
      // 存储 Token 和权限到 Pinia store
      authStore.setAuth(token, permissions || [])
      
      // 如果选择了记住我，可以存储用户名（实际项目中应该加密存储）
      if (loginForm.rememberMe) {
        localStorage.setItem('rememberedUsername', loginForm.username)
      } else {
        localStorage.removeItem('rememberedUsername')
      }
      
      ElMessage.success('登录成功')
      
      // 跳转到目标页面（如果有 redirect 参数则跳转到该页面，否则跳转到 Dashboard）
      const redirect = route.query.redirect as string || '/dashboard'
      router.push(redirect)
    } else {
      ElMessage.error(response.msg || '登录失败')
    }
  } catch (error: any) {
    console.error('登录失败:', error)
    ElMessage.error(error.message || '登录失败，请检查用户名和密码')
  } finally {
    loading.value = false
  }
}

// 页面挂载时初始化
onMounted(() => {
  // 如果已登录，直接跳转到首页
  if (authStore.isAuthenticated()) {
    const redirect = route.query.redirect as string || '/dashboard'
    router.push(redirect)
    return
  }
  
  // 触发淡入动画
  setTimeout(() => {
    mounted.value = true
  }, 50)
  
  // 加载记住的用户名
  const rememberedUsername = localStorage.getItem('rememberedUsername')
  if (rememberedUsername) {
    loginForm.username = rememberedUsername
    loginForm.rememberMe = true
  }
  
  // 页面加载时自动生成初始验证码
  refreshCaptcha()
})
</script>

<style scoped lang="scss">
.login-container {
  width: 100vw;
  height: 100vh;
  display: flex;
  overflow: hidden;
  opacity: 0;
  transition: opacity 0.6s ease-in-out;
  
  &.fade-in {
    opacity: 1;
  }
}

// 左侧 Banner
.login-banner {
  width: 55%;
  background: linear-gradient(135deg, #2d3a4b 0%, #1e2a3a 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
  overflow: hidden;
  
  &::before {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: radial-gradient(circle at 30% 50%, rgba(255, 255, 255, 0.05) 0%, transparent 50%);
    pointer-events: none;
  }
}

.banner-content {
  width: 100%;
  max-width: 500px;
  padding: 60px;
  z-index: 1;
  position: relative;
}

.logo-section {
  text-align: center;
  margin-bottom: 60px;
}

.logo-icon {
  width: 100px;
  height: 100px;
  margin: 0 auto 30px;
  animation: float 3s ease-in-out infinite;
}

@keyframes float {
  0%, 100% {
    transform: translateY(0px);
  }
  50% {
    transform: translateY(-10px);
  }
}

.system-name {
  font-size: 42px;
  font-weight: 700;
  color: #ffffff;
  margin: 0 0 16px 0;
  letter-spacing: 4px;
  text-shadow: 0 2px 10px rgba(0, 0, 0, 0.2);
}

.system-slogan {
  font-size: 16px;
  color: rgba(255, 255, 255, 0.8);
  margin: 0;
  letter-spacing: 1px;
}

.banner-illustration {
  width: 100%;
  opacity: 0.6;
  
  svg {
    width: 100%;
    height: auto;
  }
}

// 右侧表单区域
.login-form-wrapper {
  flex: 1;
  background: #ffffff;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 40px;
}

.form-container {
  width: 100%;
  max-width: 420px;
}

.form-title {
  font-size: 28px;
  font-weight: 700;
  color: #303133;
  margin: 0 0 50px 0;
  text-align: center;
  letter-spacing: 1px;
}

.login-form {
  :deep(.el-form-item) {
    margin-bottom: 28px;
  }
  
  :deep(.el-input__wrapper) {
    background-color: rgba(245, 247, 250, 0.5);
    border: 1px solid #e4e7ed;
    border-radius: 6px;
    box-shadow: none;
    transition: all 0.3s ease;
    
    &:hover {
      border-color: #c0c4cc;
    }
    
    &.is-focus {
      background-color: #ffffff;
      border-color: #409eff;
      box-shadow: 0 0 0 2px rgba(64, 158, 255, 0.1);
    }
  }
  
  :deep(.el-input__inner) {
    color: #303133;
    font-size: 15px;
    
    &::placeholder {
      color: #909399;
    }
  }
  
  :deep(.el-input__prefix) {
    color: #909399;
  }
}

.captcha-container {
  display: flex;
  gap: 12px;
  width: 100%;
  align-items: center;
}

.captcha-input {
  flex: 0 0 65%;
  
  :deep(.el-input__wrapper) {
    width: 100%;
  }
}

.captcha-image-wrapper {
  flex: 0 0 30%;
  height: 40px;
}

.captcha-image {
  width: 100%;
  height: 100%;
  border: 1px solid #e4e7ed;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.3s ease;
  background-color: #f5f7fa;
  object-fit: contain;
  
  &:hover {
    border-color: #409eff;
    box-shadow: 0 0 0 2px rgba(64, 158, 255, 0.1);
  }
  
  &:active {
    transform: scale(0.98);
  }
}

.captcha-placeholder {
  flex: 0 0 30%;
  height: 40px;
  border: 1px solid #e4e7ed;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.3s ease;
  background-color: #f5f7fa;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  font-size: 10px;
  color: #909399;
  
  &:hover {
    border-color: #409eff;
    box-shadow: 0 0 0 2px rgba(64, 158, 255, 0.1);
    color: #409eff;
  }
  
  &:active {
    transform: scale(0.98);
  }
  
  .loading-icon {
    font-size: 14px;
    margin-bottom: 2px;
    animation: rotate 1s linear infinite;
  }
  
  span {
    line-height: 1;
  }
}

@keyframes rotate {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}

.form-options {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 32px !important;
  
  :deep(.el-checkbox) {
    .el-checkbox__label {
      color: #606266;
      font-size: 14px;
    }
  }
}

.forgot-password {
  font-size: 14px;
  color: #409eff;
  
  &:hover {
    color: #66b1ff;
  }
}

.login-button {
  width: 100%;
  height: 48px;
  font-size: 16px;
  font-weight: 500;
  border-radius: 6px;
  background: linear-gradient(135deg, #409eff 0%, #337ecc 100%);
  border: none;
  transition: all 0.3s ease;
  
  &:hover {
    background: linear-gradient(135deg, #66b1ff 0%, #409eff 100%);
    transform: translateY(-1px);
    box-shadow: 0 4px 12px rgba(64, 158, 255, 0.3);
  }
  
  &:active {
    transform: translateY(0);
  }
}

.form-footer {
  margin-top: 40px;
  text-align: center;
}

.copyright {
  font-size: 12px;
  color: #909399;
  margin: 0;
}

// 响应式设计
@media (max-width: 1024px) {
  .login-banner {
    width: 50%;
  }
}

@media (max-width: 768px) {
  .login-container {
    flex-direction: column;
  }
  
  .login-banner {
    width: 100%;
    height: 200px;
    min-height: 200px;
  }
  
  .banner-content {
    padding: 30px;
  }
  
  .logo-section {
    margin-bottom: 20px;
  }
  
  .logo-icon {
    width: 60px;
    height: 60px;
    margin-bottom: 15px;
  }
  
  .system-name {
    font-size: 28px;
    margin-bottom: 8px;
  }
  
  .system-slogan {
    font-size: 14px;
  }
  
  .banner-illustration {
    display: none;
  }
  
  .login-form-wrapper {
    padding: 30px 20px;
  }
  
  .form-title {
    font-size: 24px;
    margin-bottom: 30px;
  }
}
</style>
