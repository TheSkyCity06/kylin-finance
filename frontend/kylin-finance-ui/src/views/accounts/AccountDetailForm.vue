<template>
  <div class="account-detail-form">
    <el-form
      ref="formRef"
      :model="form"
      :rules="formRules"
      label-width="120px"
      label-position="left"
    >
      <!-- 科目代码 -->
      <el-form-item label="科目代码" prop="accountCode">
        <el-input
          v-model="form.accountCode"
          :disabled="isCodeInherited"
          placeholder="科目代码"
        />
        <div v-if="isCodeInherited" class="form-tip">
          科目代码继承自父科目，不可修改
        </div>
      </el-form-item>

      <!-- 科目名称 -->
      <el-form-item label="科目名称" prop="accountName">
        <el-input
          v-model="form.accountName"
          placeholder="请输入科目名称"
          maxlength="100"
          show-word-limit
        />
      </el-form-item>

      <!-- 科目类型（只读，显示） -->
      <el-form-item label="科目类型">
        <el-input
          :value="getAccountTypeName(form.accountType)"
          disabled
        />
      </el-form-item>

      <!-- 余额方向 -->
      <el-form-item label="余额方向" prop="balanceDirection">
        <el-radio-group v-model="form.balanceDirection">
          <el-radio label="DEBIT">借方</el-radio>
          <el-radio label="CREDIT">贷方</el-radio>
        </el-radio-group>
        <div class="form-tip">
          {{ getBalanceDirectionTip() }}
        </div>
      </el-form-item>

      <!-- 辅助核算标签 -->
      <el-form-item label="辅助核算">
        <el-checkbox-group v-model="auxiliaryTags">
          <el-checkbox label="customer">客户</el-checkbox>
          <el-checkbox label="supplier">供应商</el-checkbox>
          <el-checkbox label="project">项目</el-checkbox>
        </el-checkbox-group>
        <div class="form-tip">
          勾选后，该科目将启用相应的辅助核算功能
        </div>
      </el-form-item>

      <!-- 科目信息 -->
      <el-divider content-position="left">科目信息</el-divider>

      <el-form-item label="科目ID">
        <el-input :value="account?.accountId" disabled />
      </el-form-item>

      <el-form-item label="上级科目">
        <el-input
          :value="getParentAccountName()"
          disabled
        />
      </el-form-item>

      <el-form-item label="是否末级">
        <el-tag :type="account?.isLeaf ? 'success' : 'info'">
          {{ account?.isLeaf ? '是' : '否' }}
        </el-tag>
      </el-form-item>

      <el-form-item label="科目路径" v-if="account?.path">
        <el-input :value="account.path" disabled />
      </el-form-item>

      <!-- 操作按钮 -->
      <el-form-item>
        <el-button type="primary" @click="handleSave" :loading="saving">
          保存
        </el-button>
        <el-button @click="handleCancel">取消</el-button>
      </el-form-item>
    </el-form>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, watch } from 'vue'
import { ElMessage, FormInstance, FormRules } from 'element-plus'
import type { AccountDTO, FinAccount } from '@/types/finance'

interface Props {
  account: AccountDTO | null
  accountTree?: AccountDTO[]
}

const props = withDefaults(defineProps<Props>(), {
  accountTree: () => []
})

const emit = defineEmits<{
  save: [data: FinAccount]
  cancel: []
}>()

const formRef = ref<FormInstance>()
const saving = ref(false)

// 表单数据
const form = reactive<FinAccount>({
  accountCode: '',
  accountName: '',
  accountType: '',
  balanceDirection: 'DEBIT',
  auxiliaryTags: {
    customer: false,
    supplier: false,
    project: false
  }
})

// 辅助核算标签（用于checkbox-group）
const auxiliaryTags = computed({
  get: () => {
    const tags: string[] = []
    if (form.auxiliaryTags?.customer) tags.push('customer')
    if (form.auxiliaryTags?.supplier) tags.push('supplier')
    if (form.auxiliaryTags?.project) tags.push('project')
    return tags
  },
  set: (value: string[]) => {
    form.auxiliaryTags = {
      customer: value.includes('customer'),
      supplier: value.includes('supplier'),
      project: value.includes('project')
    }
  }
})

// 判断科目代码是否继承自父科目
const isCodeInherited = computed(() => {
  return !!props.account?.parentId
})

// 表单验证规则
const formRules: FormRules = {
  accountCode: [
    { required: true, message: '请输入科目代码', trigger: 'blur' }
  ],
  accountName: [
    { required: true, message: '请输入科目名称', trigger: 'blur' },
    { max: 100, message: '科目名称不能超过100个字符', trigger: 'blur' }
  ],
  balanceDirection: [
    { required: true, message: '请选择余额方向', trigger: 'change' }
  ]
}

// 获取科目类型名称
const getAccountTypeName = (type: string | undefined | null): string => {
  if (!type) return '未知'
  const typeNames: Record<string, string> = {
    ASSET: '资产类',
    LIABILITY: '负债类',
    EQUITY: '所有者权益',
    INCOME: '收入类',
    EXPENSE: '支出类'
  }
  return typeNames[type] || type
}

// 获取余额方向提示
const getBalanceDirectionTip = (): string => {
  const type = form.accountType
  if (type === 'ASSET' || type === 'EXPENSE') {
    return '资产类和支出类科目通常余额在借方'
  } else if (type === 'LIABILITY' || type === 'EQUITY' || type === 'INCOME') {
    return '负债类、权益类和收入类科目通常余额在贷方'
  }
  return '请根据科目类型选择合适的余额方向'
}

// 获取父科目名称
const getParentAccountName = (): string => {
  if (!props.account?.parentId) return '无（顶级科目）'
  
  // 在树中查找父科目
  const findAccount = (accounts: AccountDTO[], id: number): AccountDTO | null => {
    if (!accounts?.length) return null
    
    for (const account of accounts) {
      if (!account) continue
      if (account.accountId === id) {
        return account
      }
      if (account.children?.length) {
        const found = findAccount(account.children, id)
        if (found) return found
      }
    }
    return null
  }
  
  const parent = findAccount(props.accountTree || [], props.account.parentId)
  if (parent) {
    return `${parent.accountCode} - ${parent.accountName}`
  }
  
  return `父科目ID: ${props.account.parentId}`
}

// 初始化表单数据
const initForm = () => {
  if (!props.account) {
    return
  }

  form.accountCode = props.account.accountCode || ''
  form.accountName = props.account.accountName || ''
  form.accountType = props.account.accountType || ''
  form.balanceDirection = props.account.balanceDirection || 'DEBIT'
  form.auxiliaryTags = {
    customer: props.account.auxiliaryTags?.customer || false,
    supplier: props.account.auxiliaryTags?.supplier || false,
    project: props.account.auxiliaryTags?.project || false
  }
}

// 监听account变化，重新初始化表单
watch(() => props.account, () => {
  initForm()
}, { immediate: true, deep: true })

// 保存
const handleSave = async () => {
  if (!formRef.value) {
    ElMessage.warning('表单引用无效')
    return
  }

  try {
    await formRef.value.validate()
    
    saving.value = true
    emit('save', { ...form })
  } catch (error: any) {
    console.error('表单验证失败:', error)
    ElMessage.error('请检查表单输入')
  } finally {
    saving.value = false
  }
}

// 取消
const handleCancel = () => {
  initForm()
  emit('cancel')
}
</script>

<style scoped lang="scss">
.account-detail-form {
  max-width: 600px;
}

.form-tip {
  font-size: 12px;
  color: #909399;
  margin-top: 4px;
  line-height: 1.5;
}

:deep(.el-form-item__label) {
  font-weight: 500;
}

:deep(.el-divider__text) {
  font-size: 14px;
  font-weight: 500;
  color: #606266;
}
</style>

