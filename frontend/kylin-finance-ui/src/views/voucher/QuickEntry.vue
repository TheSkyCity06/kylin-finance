<template>
  <div class="quick-entry">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>快捷录入（GnuCash 风格）</span>
          <div class="balance-info">
            <span :class="balanceClass">借贷差额：{{ balanceDifference }}</span>
          </div>
        </div>
      </template>

      <!-- 双行录入界面 -->
      <div class="dual-entry-form">
        <el-table
          :data="entryLines"
          border
          stripe
          style="width: 100%"
          @row-click="handleRowClick"
        >
          <el-table-column label="描述" width="300">
            <template #default="scope">
              <el-autocomplete
                v-model="scope.row.description"
                :fetch-suggestions="queryOwners"
                placeholder="输入描述或选择往来单位"
                style="width: 100%"
                @select="handleOwnerSelect(scope.$index, $event)"
                @input="handleDescriptionInput(scope.$index)"
              >
                <template #default="{ item }">
                  <div class="owner-suggestion">
                    <span class="owner-name">{{ item.name }}</span>
                    <span class="owner-code">{{ item.code }}</span>
                    <span class="owner-account">{{ item.accountName }}</span>
                  </div>
                </template>
              </el-autocomplete>
            </template>
          </el-table-column>

          <el-table-column label="科目" width="250">
            <template #default="scope">
              <el-select
                v-model="scope.row.accountId"
                placeholder="选择科目"
                filterable
                style="width: 100%"
                @change="updateBalance"
              >
                <el-option
                  v-for="account in leafAccounts"
                  :key="account.accountId"
                  :label="`${account.accountCode} ${account.accountName}`"
                  :value="account.accountId"
                >
                  <div class="account-option">
                    <span class="account-code">{{ account.accountCode }}</span>
                    <span class="account-name">{{ account.accountName }}</span>
                    <span v-if="account.path" class="account-path">{{ account.path }}</span>
                  </div>
                </el-option>
              </el-select>
            </template>
          </el-table-column>

          <el-table-column label="借方" width="150">
            <template #default="scope">
              <el-input-number
                v-model="scope.row.debitAmount"
                :precision="2"
                :min="0"
                :controls="false"
                style="width: 100%"
                placeholder="0.00"
                @change="updateBalance"
              />
            </template>
          </el-table-column>

          <el-table-column label="贷方" width="150">
            <template #default="scope">
              <el-input-number
                v-model="scope.row.creditAmount"
                :precision="2"
                :min="0"
                :controls="false"
                style="width: 100%"
                placeholder="0.00"
                @change="updateBalance"
              />
            </template>
          </el-table-column>

          <el-table-column label="操作" width="100" fixed="right">
            <template #default="scope">
              <el-button
                type="danger"
                size="small"
                :icon="Delete"
                @click="removeLine(scope.$index)"
                :disabled="entryLines.length <= 2"
              />
            </template>
          </el-table-column>
        </el-table>

        <div class="entry-actions">
          <el-button type="primary" :icon="Plus" @click="addLine">添加行</el-button>
          <el-button type="success" :icon="Check" @click="handleSave" :disabled="!isBalanceValid">
            保存凭证
          </el-button>
          <el-button :icon="Refresh" @click="resetForm">重置</el-button>
        </div>
      </div>

      <!-- 余额提示 -->
      <el-alert
        v-if="balanceDifference !== '0.00'"
        :type="balanceDifference.startsWith('-') ? 'warning' : 'error'"
        :title="`借贷不平衡！差额：${balanceDifference}`"
        :closable="false"
        show-icon
        style="margin-top: 20px"
      />
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Delete, Check, Refresh } from '@element-plus/icons-vue'
import { accountApi } from '@/api/finance'
import { request } from '@/utils/request'

interface EntryLine {
  description: string
  accountId: number | null
  debitAmount: number | null
  creditAmount: number | null
  ownerId?: number
  ownerType?: string
}

interface Owner {
  ownerId: number
  name: string
  code?: string
  accountId: number
  accountName: string
  ownerType: string
}

const entryLines = ref<EntryLine[]>([
  { description: '', accountId: null, debitAmount: null, creditAmount: null },
  { description: '', accountId: null, debitAmount: null, creditAmount: null }
])

const leafAccounts = ref<any[]>([])
const owners = ref<Owner[]>([])
const saving = ref(false)

// 计算借贷差额
const balanceDifference = computed(() => {
  const totalDebit = entryLines.value.reduce((sum, line) => {
    return sum + (line.debitAmount || 0)
  }, 0)

  const totalCredit = entryLines.value.reduce((sum, line) => {
    return sum + (line.creditAmount || 0)
  }, 0)

  const diff = totalDebit - totalCredit
  return diff.toFixed(2)
})

// 余额样式
const balanceClass = computed(() => {
  const diff = parseFloat(balanceDifference.value)
  if (diff === 0) return 'balance-balanced'
  if (diff > 0) return 'balance-debit'
  return 'balance-credit'
})

// 余额是否平衡
const isBalanceValid = computed(() => {
  return parseFloat(balanceDifference.value) === 0
})

// 加载末级科目
const loadLeafAccounts = async () => {
  try {
    const response = await accountApi.getLeafAccounts()
    if (response.code === 200) {
      leafAccounts.value = response.data || []
    }
  } catch (error) {
    console.error('加载科目失败:', error)
  }
}

// 加载往来单位
const loadOwners = async () => {
  try {
    // 这里需要调用获取所有往来单位的 API
    // 假设有一个 /finance/owner/list 接口
    const response = await request.get('/finance/owner/list')
    if (response.code === 200) {
      owners.value = response.data || []
    }
  } catch (error) {
    console.error('加载往来单位失败:', error)
  }
}

// 查询往来单位（自动联想）
const queryOwners = (queryString: string, cb: (suggestions: any[]) => void) => {
  if (!queryString) {
    cb([])
    return
  }

  const results = owners.value.filter(owner => {
    return owner.name.toLowerCase().includes(queryString.toLowerCase()) ||
           (owner.code && owner.code.toLowerCase().includes(queryString.toLowerCase()))
  }).map(owner => ({
    value: owner.name,
    name: owner.name,
    code: owner.code,
    ownerId: owner.ownerId,
    accountId: owner.accountId,
    accountName: owner.accountName,
    ownerType: owner.ownerType
  }))

  cb(results)
}

// 选择往来单位
const handleOwnerSelect = (index: number, item: any) => {
  const line = entryLines.value[index]
  line.description = item.name
  line.accountId = item.accountId
  line.ownerId = item.ownerId
  line.ownerType = item.ownerType

  // 自动填充对应的往来科目
  updateBalance()
}

// 描述输入
const handleDescriptionInput = (index: number) => {
  // 可以在这里实现更智能的联想逻辑
  updateBalance()
}

// 更新余额
const updateBalance = () => {
  // 触发计算，computed 会自动更新
}

// 添加行
const addLine = () => {
  entryLines.value.push({
    description: '',
    accountId: null,
    debitAmount: null,
    creditAmount: null
  })
}

// 删除行
const removeLine = (index: number) => {
  if (entryLines.value.length > 2) {
    entryLines.value.splice(index, 1)
    updateBalance()
  }
}

// 行点击
const handleRowClick = (row: EntryLine, column: any) => {
  // 可以在这里实现行选择逻辑
}

// 保存凭证
const handleSave = async () => {
  if (!isBalanceValid.value) {
    ElMessage.warning('借贷不平衡，无法保存')
    return
  }

  // 验证必填项
  const hasEmpty = entryLines.value.some(line => {
    return !line.description || !line.accountId ||
           (line.debitAmount === null && line.creditAmount === null)
  })

  if (hasEmpty) {
    ElMessage.warning('请填写完整的凭证信息')
    return
  }

  try {
    saving.value = true

    // 构建凭证数据
    const splits = entryLines.value.map(line => ({
      accountId: line.accountId,
      direction: line.debitAmount && line.debitAmount > 0 ? 'DEBIT' : 'CREDIT',
      amount: line.debitAmount || line.creditAmount || 0,
      memo: line.description,
      ownerId: line.ownerId,
      ownerType: line.ownerType
    }))

    const transaction = {
      transDate: new Date().toISOString().split('T')[0],
      description: entryLines.value[0]?.description || '快捷录入凭证',
      splits: splits
    }

    // 调用保存接口
    const response = await request.post('/finance/voucher/save', transaction)
    if (response.code === 200) {
      ElMessage.success('凭证保存成功')
      resetForm()
    } else {
      ElMessage.error(response.msg || '保存失败')
    }
  } catch (error: any) {
    ElMessage.error(error.message || '保存失败')
  } finally {
    saving.value = false
  }
}

// 重置表单
const resetForm = () => {
  entryLines.value = [
    { description: '', accountId: null, debitAmount: null, creditAmount: null },
    { description: '', accountId: null, debitAmount: null, creditAmount: null }
  ]
}

onMounted(() => {
  loadLeafAccounts()
  loadOwners()
})
</script>

<style scoped lang="scss">
.quick-entry {
  padding: 20px;

  .card-header {
    display: flex;
    justify-content: space-between;
    align-items: center;

    .balance-info {
      .balance-balanced {
        color: #67c23a;
        font-weight: bold;
      }

      .balance-debit {
        color: #409eff;
        font-weight: bold;
      }

      .balance-credit {
        color: #f56c6c;
        font-weight: bold;
      }
    }
  }

  .dual-entry-form {
    margin-top: 20px;

    .entry-actions {
      margin-top: 20px;
      display: flex;
      gap: 10px;
    }
  }

  .owner-suggestion {
    display: flex;
    flex-direction: column;
    gap: 4px;

    .owner-name {
      font-weight: bold;
    }

    .owner-code {
      font-size: 12px;
      color: #909399;
    }

    .owner-account {
      font-size: 12px;
      color: #409eff;
    }
  }

  .account-option {
    display: flex;
    flex-direction: column;
    gap: 4px;

    .account-code {
      font-weight: bold;
      color: #409eff;
    }

    .account-name {
      color: #606266;
    }

    .account-path {
      font-size: 12px;
      color: #909399;
    }
  }
}
</style>
