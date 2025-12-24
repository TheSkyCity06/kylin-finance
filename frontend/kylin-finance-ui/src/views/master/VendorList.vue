<template>
  <div class="vendor-list">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>供应商列表</span>
          <el-button type="primary" :icon="Plus" @click="handleAdd">新增供应商</el-button>
        </div>
      </template>

      <el-table :data="vendorList" border stripe v-loading="loading" style="width: 100%">
        <el-table-column prop="name" label="供应商名称" width="200" />
        <el-table-column prop="code" label="供应商代码" width="150" />
        <el-table-column prop="contactName" label="联系人" width="120" />
        <el-table-column prop="contactPhone" label="联系电话" width="150" />
        <el-table-column prop="contactEmail" label="邮箱" width="200" />
        <el-table-column prop="address" label="地址" min-width="200" />
        <el-table-column label="关联科目" width="150">
          <template #default="scope">
            <span v-if="scope.row.accountName">{{ scope.row.accountName }}</span>
            <el-tag v-else type="warning" size="small">未关联</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="150" fixed="right">
          <template #default="scope">
            <el-button type="primary" size="small" @click="handleEdit(scope.row)">编辑</el-button>
            <el-button type="danger" size="small" @click="handleDelete(scope.row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>

      <!-- 新增/编辑对话框 -->
      <el-dialog
        v-model="dialogVisible"
        :title="dialogTitle"
        width="600px"
        :close-on-click-modal="false"
      >
        <el-form :model="formData" :rules="rules" ref="formRef" label-width="100px">
          <el-form-item label="供应商名称" prop="name">
            <el-input v-model="formData.name" placeholder="请输入供应商名称" />
          </el-form-item>
          <el-form-item label="供应商代码" prop="code">
            <el-input v-model="formData.code" placeholder="请输入供应商代码" />
          </el-form-item>
          <el-form-item label="联系人" prop="contactName">
            <el-input v-model="formData.contactName" placeholder="请输入联系人" />
          </el-form-item>
          <el-form-item label="联系电话" prop="contactPhone">
            <el-input v-model="formData.contactPhone" placeholder="请输入联系电话" />
          </el-form-item>
          <el-form-item label="邮箱" prop="contactEmail">
            <el-input v-model="formData.contactEmail" placeholder="请输入邮箱" />
          </el-form-item>
          <el-form-item label="地址" prop="address">
            <el-input v-model="formData.address" type="textarea" :rows="2" placeholder="请输入地址" />
          </el-form-item>
          <el-form-item label="关联科目" prop="accountId">
            <el-select
              v-model="formData.accountId"
              placeholder="选择关联的应付账款科目"
              filterable
              style="width: 100%"
            >
              <el-option
                v-for="account in payableAccounts"
                :key="account.accountId"
                :label="`${account.accountCode} ${account.accountName}`"
                :value="account.accountId"
              />
            </el-select>
          </el-form-item>
        </el-form>
        <template #footer>
          <el-button @click="dialogVisible = false">取消</el-button>
          <el-button type="primary" @click="handleSubmit">确定</el-button>
        </template>
      </el-dialog>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus } from '@element-plus/icons-vue'
import { documentApi, accountApi } from '@/api/finance'
import type { Owner, AccountDTO } from '@/types/finance'

const loading = ref(false)
const vendorList = ref<Owner[]>([])
const payableAccounts = ref<AccountDTO[]>([])
const dialogVisible = ref(false)
const dialogTitle = ref('新增供应商')
const formRef = ref()
const formData = ref<Partial<Owner>>({
  ownerType: 'VENDOR'
})

const rules = {
  name: [{ required: true, message: '请输入供应商名称', trigger: 'blur' }],
  code: [{ required: true, message: '请输入供应商代码', trigger: 'blur' }]
}

// 加载供应商列表
const loadVendorList = async () => {
  loading.value = true
  try {
    const response = await documentApi.getOwnerList()
    if (response.code === 200) {
      vendorList.value = (response.data || []).filter((owner: Owner) => owner.ownerType === 'VENDOR')
    }
  } catch (error) {
    ElMessage.error('加载供应商列表失败')
  } finally {
    loading.value = false
  }
}

// 加载应付账款科目
const loadPayableAccounts = async () => {
  try {
    const response = await accountApi.getAccountTree()
    if (response.code === 200) {
      const allAccounts = response.data || []
      // 查找应付账款相关科目（通常代码以220开头）
      payableAccounts.value = flattenAccounts(allAccounts).filter(
        account => account.accountCode.startsWith('220') || account.accountName.includes('应付')
      )
    }
  } catch (error) {
    console.error('加载科目失败:', error)
  }
}

const flattenAccounts = (accounts: AccountDTO[]): AccountDTO[] => {
  const result: AccountDTO[] = []
  accounts.forEach(account => {
    result.push(account)
    if (account.children && account.children.length > 0) {
      result.push(...flattenAccounts(account.children))
    }
  })
  return result
}

// 新增
const handleAdd = () => {
  dialogTitle.value = '新增供应商'
  formData.value = { ownerType: 'VENDOR' }
  dialogVisible.value = true
}

// 编辑
const handleEdit = (row: Owner) => {
  dialogTitle.value = '编辑供应商'
  formData.value = { ...row }
  dialogVisible.value = true
}

// 删除
const handleDelete = async (row: Owner) => {
  try {
    await ElMessageBox.confirm('确定要删除该供应商吗？', '提示', {
      type: 'warning'
    })
    const response = await documentApi.deleteOwner(row.ownerId!)
    if (response.code === 200) {
      ElMessage.success('删除成功')
      loadVendorList()
    } else {
      ElMessage.error(response.msg || '删除失败')
    }
  } catch (error: any) {
    if (error.toString().includes('cancel')) {
      // 用户取消
      return
    }
    console.error('删除供应商失败:', error)
    ElMessage.error(error.response?.data?.msg || error.message || '删除失败')
  }
}

// 提交
const handleSubmit = async () => {
  if (!formRef.value) return
  await formRef.value.validate()
  
  try {
    const isEdit = !!formData.value.ownerId
    let response
    if (isEdit) {
      response = await documentApi.updateOwner(formData.value)
    } else {
      response = await documentApi.createOwner(formData.value)
    }
    
    if (response.code === 200) {
      ElMessage.success(dialogTitle.value === '新增供应商' ? '新增成功' : '更新成功')
      dialogVisible.value = false
      loadVendorList()
    } else {
      ElMessage.error(response.msg || '操作失败')
    }
  } catch (error: any) {
    console.error('保存供应商失败:', error)
    ElMessage.error(error.response?.data?.msg || error.message || '操作失败')
  }
}

onMounted(() => {
  loadVendorList()
  loadPayableAccounts()
})
</script>

<style scoped lang="scss">
.vendor-list {
  .card-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
  }
}
</style>
