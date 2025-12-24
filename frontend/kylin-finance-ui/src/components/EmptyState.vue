<template>
  <div class="empty-state">
    <div class="empty-content">
      <el-icon :size="64" class="empty-icon">
        <component :is="props.icon" />
      </el-icon>
      <h3 class="empty-title">{{ title }}</h3>
      <p class="empty-description">{{ description }}</p>
      <slot name="action">
        <el-button v-if="showAction" type="primary" @click="$emit('action')">
          {{ actionText }}
        </el-button>
      </slot>
    </div>
  </div>
</template>

<script setup lang="ts">
import { Document } from '@element-plus/icons-vue'
import type { Component } from 'vue'

interface Props {
  icon?: Component | string
  title?: string
  description?: string
  showAction?: boolean
  actionText?: string
}

const props = withDefaults(defineProps<Props>(), {
  icon: Document,
  title: '暂无数据',
  description: '请选择一项以查看详细信息',
  showAction: false,
  actionText: '创建'
})

defineEmits<{
  action: []
}>()
</script>

<style scoped lang="scss">
.empty-state {
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 400px;
  width: 100%;
  padding: 40px 20px;
}

.empty-content {
  text-align: center;
  max-width: 400px;
}

.empty-icon {
  color: #c0c4cc;
  margin-bottom: 16px;
}

.empty-title {
  font-size: 16px;
  color: #606266;
  margin: 0 0 8px 0;
  font-weight: 500;
}

.empty-description {
  font-size: 14px;
  color: #909399;
  margin: 0 0 24px 0;
  line-height: 1.5;
}
</style>

