/// <reference types="vite/client" />

declare module '*.vue' {
  import type { DefineComponent } from 'vue'
  const component: DefineComponent<{}, {}, any>
  export default component
}

interface ImportMetaEnv {
  readonly BASE_URL: string
  readonly VITE_APP_TITLE?: string
  readonly VITE_API_BASE_URL?: string
  // 添加其他环境变量类型定义
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}