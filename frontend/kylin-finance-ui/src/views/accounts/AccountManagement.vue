<template>
  <ErrorBoundary>
    <div class="account-management">
      <!-- Master-Detail 布局 -->
      <div class="master-detail-layout">
        <!-- 左侧：科目树（Master） -->
        <div class="master-panel">
          <el-card class="tree-card">
            <template #header>
              <div class="card-header">
                <span>科目列表</span>
                <el-button type="primary" size="small" @click="showAddDialog">
                  <el-icon><Plus /></el-icon>
                  新增科目
                </el-button>
              </div>
            </template>

            <div class="account-tree">
              <el-empty v-if="!accountTree || accountTree.length === 0" description="暂无科目数据" />
              <el-tree
                v-else
                :data="accountTree"
                :props="treeProps"
                node-key="accountId"
                :default-expand-all="false"
                :expand-on-click-node="false"
                :highlight-current="true"
                :current-node-key="selectedAccountId"
                @node-click="handleNodeClick"
              >
                <template #default="{ node, data }">
                  <div class="tree-node" v-if="data?.accountId">
                    <span class="account-code">{{ data.accountCode || '' }}</span>
                    <span class="account-name">{{ data.accountName || '' }}</span>
                    <span class="account-type">{{ getAccountTypeName(data.accountType) }}</span>
                    <span v-if="data.isLeaf" class="leaf-badge">末级</span>
                  </div>
                  <div v-else class="tree-node-error">
                    <span style="color: #f56c6c;">数据加载异常</span>
                  </div>
                </template>
              </el-tree>
            </div>
          </el-card>
        </div>

        <!-- 右侧：详细表单（Detail） -->
        <div class="detail-panel">
          <el-card class="detail-card">
            <template #header>
              <div class="card-header">
                <span>科目详情</span>
                <div class="header-actions" v-if="selectedAccount">
                  <el-button type="danger" size="small" @click="handleDelete" :disabled="!selectedAccount?.isLeaf">
                    删除
                  </el-button>
                </div>
              </div>
            </template>

            <!-- 空状态 -->
            <EmptyState
              v-if="!selectedAccount"
              icon="Document"
              title="请选择科目"
              description="从左侧列表中选择一个科目以查看和编辑详细信息"
            />

            <!-- 详细表单 -->
            <AccountDetailForm
              v-else
              :account="selectedAccount"
              :account-tree="accountTree"
              @save="handleSave"
              @cancel="handleCancel"
            />
          </el-card>
        </div>
      </div>

      <!-- 新增科目对话框 -->
      <el-dialog
        v-model="dialogVisible"
        title="新增科目"
        width="600px"
        :close-on-click-modal="false"
      >
        <el-form
          ref="dialogFormRef"
          :model="dialogForm"
          :rules="formRules"
          label-width="100px"
        >
          <el-form-item label="科目代码" prop="accountCode">
            <el-input
              v-model="dialogForm.accountCode"
              placeholder="请输入科目代码"
            />
          </el-form-item>

          <el-form-item label="科目名称" prop="accountName">
            <el-input
              v-model="dialogForm.accountName"
              placeholder="请输入科目名称"
            />
          </el-form-item>

          <el-form-item label="科目类型" prop="accountType">
            <el-select 
              v-model="dialogForm.accountType" 
              placeholder="请选择科目类型" 
              style="width: 100%"
              :disabled="!!dialogForm.parentId"
            >
              <el-option label="资产类" value="ASSET" />
              <el-option label="负债类" value="LIABILITY" />
              <el-option label="所有者权益" value="EQUITY" />
              <el-option label="收入类" value="INCOME" />
              <el-option label="支出类" value="EXPENSE" />
            </el-select>
            <div v-if="dialogForm.parentId" class="form-tip">
              子科目的类型继承自父科目
            </div>
          </el-form-item>

          <el-form-item label="上级科目">
            <el-tree-select
              v-model="dialogForm.parentId"
              :data="accountTree || []"
              :props="treeSelectProps"
              node-key="accountId"
              placeholder="请选择上级科目（可选，选择后自动继承类型）"
              style="width: 100%"
              clearable
              check-strictly
              @change="onParentChange"
            />
          </el-form-item>
        </el-form>

        <template #footer>
          <span class="dialog-footer">
            <el-button @click="dialogVisible = false">取消</el-button>
            <el-button type="primary" @click="handleDialogSubmit" :loading="submitting">
              创建
            </el-button>
          </span>
        </template>
      </el-dialog>
    </div>
  </ErrorBoundary>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted, computed } from 'vue'
import { ElMessage, ElMessageBox, FormInstance, FormRules } from 'element-plus'
import { Plus } from '@element-plus/icons-vue'
import { accountApi } from '@/api/finance'
import type { FinAccount, AccountDTO } from '@/types/finance'
import ErrorBoundary from '@/components/ErrorBoundary.vue'
import EmptyState from '@/components/EmptyState.vue'
import AccountDetailForm from './AccountDetailForm.vue'

// 科目树数据
const accountTree = ref<AccountDTO[]>([])

// 选中的科目
const selectedAccount = ref<AccountDTO | null>(null)
const selectedAccountId = computed(() => selectedAccount.value?.accountId || null)

// 树形组件配置
const treeProps = {
  children: 'children',
  label: 'accountName'
}

const treeSelectProps = {
  children: 'children',
  label: (data: AccountDTO) => {
    if (!data) return '未知科目'
    const code = data.accountCode || ''
    const name = data.accountName || ''
    return `${code} ${name}`.trim() || '未知科目'
  }
}

// 对话框状态
const dialogVisible = ref(false)
const submitting = ref(false)

// 对话框表单数据
const dialogForm = reactive<FinAccount>({
  accountCode: '',
  accountName: '',
  accountType: '',
  parentId: undefined
})

const dialogFormRef = ref<FormInstance>()

// 获取科目类型名称
const getAccountTypeName = (type: string | undefined | null): string => {
  if (!type) return '未知'
  const typeNames: Record<string, string> = {
    ASSET: '资产',
    LIABILITY: '负债',
    EQUITY: '权益',
    INCOME: '收入',
    EXPENSE: '支出'
  }
  return typeNames[type] || type
}

// 验证科目编码规则（层级编码）
const validateAccountCode = (rule: any, value: string, callback: any) => {
  if (!value) {
    callback()
    return
  }
  
  // 如果选择了父科目，验证编码是否符合层级规则
  if (dialogForm.parentId && accountTree.value && accountTree.value.length > 0) {
    const findParent = (accounts: AccountDTO[], parentId: number): AccountDTO | null => {
      if (!accounts || accounts.length === 0) return null
      
      for (const account of accounts) {
        if (!account) continue
        if (account.accountId === parentId) {
          return account
        }
        if (account.children && Array.isArray(account.children) && account.children.length > 0) {
          const found = findParent(account.children, parentId)
          if (found) return found
        }
      }
      return null
    }
    
    const parent = findParent(accountTree.value, dialogForm.parentId)
    if (parent?.accountCode) {
      if (!value.startsWith(parent.accountCode)) {
        callback(new Error(`子科目编码应以父科目编码"${parent.accountCode}"开头`))
        return
      }
      if (value.length <= parent.accountCode.length) {
        callback(new Error(`子科目编码长度应大于父科目编码"${parent.accountCode}"`))
        return
      }
    }
  }
  
  callback()
}

// 表单验证规则
const formRules: FormRules = {
  accountCode: [
    { required: true, message: '请输入科目代码', trigger: 'blur' },
    { pattern: /^[0-9]+$/, message: '科目代码只能包含数字', trigger: 'blur' },
    { validator: validateAccountCode, trigger: 'blur' }
  ],
  accountName: [
    { required: true, message: '请输入科目名称', trigger: 'blur' }
  ],
  accountType: [
    { required: true, message: '请选择科目类型', trigger: 'change' }
  ]
}

// 加载科目树
const loadAccountTree = async () => {
  try {
    const res = await accountApi.getAccountTree()
    if (res?.data && Array.isArray(res.data)) {
      accountTree.value = res.data
      // 如果之前选中的科目还存在，重新选中它
      if (selectedAccountId.value) {
        const findAccount = (accounts: AccountDTO[], id: number): AccountDTO | null => {
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
        const account = findAccount(accountTree.value, selectedAccountId.value)
        if (account) {
          selectedAccount.value = account
        } else {
          selectedAccount.value = null
        }
      }
    } else {
      accountTree.value = []
      ElMessage.warning('科目数据格式异常，已重置为空列表')
    }
  } catch (error: any) {
    console.error('加载科目数据失败:', error)
    accountTree.value = []
    ElMessage.error('加载科目数据失败：' + (error?.message || '未知错误'))
  }
}

// 节点点击处理 - 选中科目并显示在右侧
const handleNodeClick = (data: AccountDTO | null | undefined) => {
  if (!data?.accountId) return
  selectedAccount.value = { ...data } // 创建副本以避免响应式问题
}

// 显示新增对话框
const showAddDialog = (parentAccount?: AccountDTO) => {
  Object.assign(dialogForm, {
    accountCode: '',
    accountName: '',
    accountType: parentAccount?.accountType || '',
    parentId: parentAccount?.accountId
  })
  dialogVisible.value = true
}

// 父科目变化时，自动设置科目类型
const onParentChange = (parentId: number | undefined) => {
  if (parentId && accountTree.value?.length) {
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
    
    const parent = findAccount(accountTree.value, parentId)
    if (parent?.accountType) {
      dialogForm.accountType = parent.accountType
    }
  }
}

// 提交对话框表单
const handleDialogSubmit = async () => {
  if (!dialogFormRef.value) {
    ElMessage.warning('表单引用无效，请刷新页面重试')
    return
  }

  try {
    await dialogFormRef.value.validate(async (valid) => {
      if (!valid) return

      try {
        submitting.value = true
        await accountApi.addAccount(dialogForm)
        ElMessage.success('创建成功')
        dialogVisible.value = false
        await loadAccountTree()
      } catch (error: any) {
        console.error('提交表单失败:', error)
        ElMessage.error('操作失败：' + (error?.message || '未知错误'))
      } finally {
        submitting.value = false
      }
    })
  } catch (error: any) {
    console.error('表单验证失败:', error)
    ElMessage.error('表单验证失败：' + (error?.message || '未知错误'))
    submitting.value = false
  }
}

// 保存右侧表单
const handleSave = async (formData: FinAccount) => {
  if (!selectedAccount.value?.accountId) {
    ElMessage.error('无法保存：科目信息无效')
    return
  }

  try {
    submitting.value = true
    await accountApi.updateAccount({
      ...formData,
      accountId: selectedAccount.value.accountId
    })
    ElMessage.success('更新成功')
    await loadAccountTree()
  } catch (error: any) {
    console.error('保存失败:', error)
    ElMessage.error('保存失败：' + (error?.message || '未知错误'))
  } finally {
    submitting.value = false
  }
}

// 取消编辑
const handleCancel = () => {
  // 重新加载选中科目的数据
  if (selectedAccountId.value) {
    const findAccount = (accounts: AccountDTO[], id: number): AccountDTO | null => {
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
    const account = findAccount(accountTree.value, selectedAccountId.value)
    if (account) {
      selectedAccount.value = { ...account }
    }
  }
}

// 删除科目
const handleDelete = async () => {
  if (!selectedAccount.value?.accountId) {
    ElMessage.warning('无法删除：科目信息无效')
    return
  }

  if (!selectedAccount.value.isLeaf) {
    ElMessage.warning('只能删除末级科目')
    return
  }

  try {
    await ElMessageBox.confirm(
      `确定要删除科目 "${selectedAccount.value.accountName || '未知科目'}" 吗？删除后无法恢复。`,
      '确认删除',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )

    await accountApi.deleteAccount(selectedAccount.value.accountId)
    ElMessage.success('删除成功')
    selectedAccount.value = null
    await loadAccountTree()
  } catch (error: any) {
    if (error !== 'cancel') {
      console.error('删除科目失败:', error)
      ElMessage.error('删除失败：' + (error?.message || '未知错误'))
    }
  }
}

onMounted(() => {
  try {
    loadAccountTree()
  } catch (error: any) {
    console.error('组件挂载时发生错误:', error)
    ElMessage.error('页面初始化失败：' + (error?.message || '未知错误'))
  }
})
</script>

<style scoped lang="scss">
.account-management {
  height: 100%;
  display: flex;
  flex-direction: column;
  padding: 0;
}

.master-detail-layout {
  display: flex;
  height: 100%;
  gap: 0;
  overflow: hidden;
}

.master-panel {
  width: 400px;
  min-width: 300px;
  max-width: 500px;
  flex-shrink: 0;
  border-right: 1px solid #e4e7ed;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.tree-card {
  height: 100%;
  display: flex;
  flex-direction: column;
  border: none;
  border-radius: 0;
  
  :deep(.el-card__body) {
    flex: 1;
    overflow: auto;
    padding: 12px;
  }
}

.detail-panel {
  flex: 1;
  display: flex;
  flex-direction: column;
  overflow: hidden;
  min-width: 0;
}

.detail-card {
  height: 100%;
  display: flex;
  flex-direction: column;
  border: none;
  border-radius: 0;
  
  :deep(.el-card__body) {
    flex: 1;
    overflow: auto;
    padding: 20px;
  }
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.header-actions {
  display: flex;
  gap: 8px;
}

.account-tree {
  height: 100%;
}

.tree-node {
  display: flex;
  align-items: center;
  gap: 10px;
  width: 100%;
  padding: 4px 0;
  flex-wrap: wrap;
}

.account-code {
  font-weight: 600;
  color: #409eff;
  min-width: 80px;
  font-size: 12px;
}

.account-name {
  flex: 1;
  color: #303133;
  font-size: 12px;
  min-width: 0;
}

.account-type {
  background-color: #f0f9ff;
  color: #67c23a;
  padding: 2px 6px;
  border-radius: 3px;
  font-size: 11px;
  white-space: nowrap;
}

.leaf-badge {
  background-color: #e6f7ff;
  color: #1890ff;
  padding: 2px 6px;
  border-radius: 3px;
  font-size: 11px;
  white-space: nowrap;
}

.tree-node-error {
  padding: 5px 0;
  color: #f56c6c;
  font-size: 12px;
}

.form-tip {
  font-size: 12px;
  color: #909399;
  margin-top: 4px;
}

:deep(.el-tree-node__content) {
  height: auto;
  padding: 6px 0;
}

:deep(.el-tree-node__content:hover) {
  background-color: #f5f7fa;
}

:deep(.el-tree-node.is-current > .el-tree-node__content) {
  background-color: #ecf5ff;
  color: #409eff;
}

.dialog-footer {
  text-align: right;
}
</style>
