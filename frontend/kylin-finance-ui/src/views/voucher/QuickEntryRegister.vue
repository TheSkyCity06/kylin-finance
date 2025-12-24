<template>
  <div class="quick-entry-register">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>快捷录入（GnuCash 双行模式）</span>
          <div class="balance-info">
            <span :class="balanceClass">不平衡差额：{{ balanceDifference }}</span>
          </div>
        </div>
      </template>

      <!-- 双行录入表格 -->
      <div class="entry-table-container">
        <table class="entry-table" cellspacing="0" cellpadding="0">
          <thead>
            <tr>
              <th class="col-date">日期</th>
              <th class="col-description">摘要</th>
              <th class="col-account">科目</th>
              <th class="col-debit">借方</th>
              <th class="col-credit">贷方</th>
              <th class="col-action">操作</th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="(line, index) in entryLines"
              :key="index"
              :class="{ 'active-row': activeRowIndex === index }"
            >
              <!-- 日期列 -->
              <td class="col-date">
                <el-date-picker
                  v-model="line.date"
                  type="date"
                  format="YYYY-MM-DD"
                  value-format="YYYY-MM-DD"
                  placeholder="日期"
                  size="small"
                  style="width: 100%"
                  @focus="setActiveRow(index)"
                />
              </td>

              <!-- 摘要列（支持联想） -->
              <td class="col-description">
                <el-autocomplete
                  v-model="line.description"
                  :fetch-suggestions="queryOwners"
                  placeholder="输入摘要或选择往来单位"
                  size="small"
                  style="width: 100%"
                  @select="handleOwnerSelect(index, $event)"
                  @input="handleDescriptionInput(index)"
                  @focus="setActiveRow(index, 'description')"
                  @keydown="(e: KeyboardEvent) => handleKeyDown(e, index, 'description')"
                  :ref="(el: ComponentPublicInstance | null) => { if (el) descriptionInputs[index] = el }"
                >
                  <template #default="{ item }">
                    <div class="owner-suggestion">
                      <span class="owner-name">{{ item.name }}</span>
                      <span class="owner-code" v-if="item.code">({{ item.code }})</span>
                      <span class="owner-account">{{ item.accountName }}</span>
                    </div>
                  </template>
                </el-autocomplete>
              </td>

              <!-- 科目列 -->
              <td class="col-account">
                <el-select
                  v-model="line.accountId"
                  placeholder="选择科目"
                  filterable
                  size="small"
                  style="width: 100%"
                  @change="updateBalance"
                  @focus="setActiveRow(index, 'account')"
                  @keydown="(e: KeyboardEvent) => handleKeyDown(e, index, 'account')"
                  :ref="(el: ComponentPublicInstance | null) => { if (el) accountSelects[index] = el }"
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
              </td>

              <!-- 借方列 -->
              <td class="col-debit">
                <el-input-number
                  v-model="line.debitAmount"
                  :precision="2"
                  :min="0"
                  :controls="false"
                  size="small"
                  style="width: 100%"
                  placeholder="0.00"
                  @change="updateBalance"
                  @focus="setActiveRow(index, 'debit')"
                  @keydown="(e: KeyboardEvent) => handleKeyDown(e, index, 'debit')"
                  :ref="(el: ComponentPublicInstance | null) => { if (el) debitInputs[index] = el }"
                />
              </td>

              <!-- 贷方列 -->
              <td class="col-credit">
                <el-input-number
                  v-model="line.creditAmount"
                  :precision="2"
                  :min="0"
                  :controls="false"
                  size="small"
                  style="width: 100%"
                  placeholder="0.00"
                  @change="updateBalance"
                  @focus="setActiveRow(index, 'credit')"
                  @keydown="(e: KeyboardEvent) => handleKeyDown(e, index, 'credit')"
                  :ref="(el: ComponentPublicInstance | null) => { if (el) creditInputs[index] = el }"
                />
              </td>

              <!-- 操作列 -->
              <td class="col-action">
                <el-button
                  type="danger"
                  size="small"
                  :icon="Delete"
                  @click="removeLine(index)"
                  :disabled="entryLines.length <= 2"
                  circle
                />
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- 操作按钮 -->
      <div class="entry-actions">
        <el-button type="primary" :icon="Plus" @click="addLine">添加行</el-button>
        <el-button type="success" :icon="Check" @click="handleSave" :disabled="!isBalanceValid">
          保存凭证
        </el-button>
        <el-button :icon="Refresh" @click="resetForm">重置</el-button>
      </div>

      <!-- 实时统计 -->
      <div class="balance-summary">
        <el-card shadow="never">
          <div class="summary-content">
            <div class="summary-item">
              <span class="label">借方合计：</span>
              <span class="value debit-total">¥{{ formatAmount(totalDebit) }}</span>
            </div>
            <div class="summary-item">
              <span class="label">贷方合计：</span>
              <span class="value credit-total">¥{{ formatAmount(totalCredit) }}</span>
            </div>
            <div class="summary-item">
              <span class="label">不平衡差额：</span>
              <span :class="['value', 'difference', balanceClass]">
                {{ balanceDifference }}
              </span>
            </div>
          </div>
        </el-card>
      </div>

      <!-- 平衡提示 -->
      <el-alert
        v-if="!isBalanceValid"
        type="error"
        :title="`借贷不平衡！差额：${balanceDifference}`"
        :closable="false"
        show-icon
        style="margin-top: 15px"
      />
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted, nextTick } from 'vue'
import { ElMessage } from 'element-plus'
import { Plus, Delete, Check, Refresh } from '@element-plus/icons-vue'
import { accountApi, documentApi } from '@/api/finance'
import { request } from '@/utils/request'
import type { FinAccount } from '@/types/finance'

interface EntryLine {
  date: string
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
  { date: new Date().toISOString().split('T')[0], description: '', accountId: null, debitAmount: null, creditAmount: null },
  { date: new Date().toISOString().split('T')[0], description: '', accountId: null, debitAmount: null, creditAmount: null }
])

const leafAccounts = ref<FinAccount[]>([])
const owners = ref<Owner[]>([])
const activeRowIndex = ref(0)
import type { ComponentPublicInstance } from 'vue'

const descriptionInputs = ref<(ComponentPublicInstance | null)[]>([])
const accountSelects = ref<(ComponentPublicInstance | null)[]>([])
const debitInputs = ref<(ComponentPublicInstance | null)[]>([])
const creditInputs = ref<(ComponentPublicInstance | null)[]>([])

// 计算借贷合计
const totalDebit = computed(() => {
  return entryLines.value.reduce((sum, line) => {
    return sum + (line.debitAmount ?? 0)
  }, 0)
})

const totalCredit = computed(() => {
  return entryLines.value.reduce((sum, line) => {
    return sum + (line.creditAmount ?? 0)
  }, 0)
})

// 计算不平衡差额
const balanceDifference = computed(() => {
  const diff = totalDebit.value - totalCredit.value
  if (Math.abs(diff) < 0.01) {
    return '0.00'
  }
  const sign = diff > 0 ? '+' : ''
  return sign + diff.toFixed(2)
})

// 余额样式
const balanceClass = computed(() => {
  const diff = parseFloat(balanceDifference.value)
  if (Math.abs(diff) < 0.01) return 'balance-balanced'
  if (diff > 0) return 'balance-debit'
  return 'balance-credit'
})

// 余额是否平衡
const isBalanceValid = computed(() => {
  return Math.abs(parseFloat(balanceDifference.value)) < 0.01
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
    const response = await documentApi.getOwnerList()
    if (response.code === 200) {
      owners.value = response.data || []
    }
  } catch (error) {
    console.error('加载往来单位失败:', error)
  }
}

// 查询往来单位（自动联想）
const queryOwners = (queryString: string, cb: (suggestions: Owner[]) => void) => {
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
const handleOwnerSelect = (index: number, item: Owner) => {
  const line = entryLines.value[index]
  if (!line) return
  line.description = item.name
  line.accountId = item.accountId
  line.ownerId = item.ownerId
  line.ownerType = item.ownerType

  updateBalance()

  // 自动跳转到借方输入框
  nextTick(() => {
    focusField(index, 'debit')
  })
}

// 描述输入
const handleDescriptionInput = (index: number) => {
  updateBalance()
}

// 描述输入框失焦处理
const handleDescriptionBlur = (index: number) => {
  // 如果输入了描述但未选择科目，可以在这里添加自动填充逻辑
}

// 设置活动行
const setActiveRow = (index: number, field?: string) => {
  activeRowIndex.value = index
}

// 统一键盘事件处理
const handleKeyDown = (e: KeyboardEvent, index: number, currentField: string) => {
  if (e.key === 'Tab') {
    e.preventDefault()
    handleTabKey(index, currentField)
  } else if (e.key === 'Enter') {
    e.preventDefault()
    handleEnterKey(index, currentField)
  }
}

// Tab 键处理
const handleTabKey = (index: number, currentField: string) => {
  // Tab 键切换顺序：摘要 -> 科目 -> 借方 -> 贷方 -> 下一行的摘要
  if (currentField === 'description') {
    focusField(index, 'account')
  } else if (currentField === 'account') {
    focusField(index, 'debit')
  } else if (currentField === 'debit') {
    focusField(index, 'credit')
  } else if (currentField === 'credit') {
    // 跳转到下一行
    if (index < entryLines.value.length - 1) {
      focusField(index + 1, 'description')
    } else {
      addLine()
      nextTick(() => {
        focusField(entryLines.value.length - 1, 'description')
      })
    }
  }
}

// Enter 键处理
const handleEnterKey = (index: number, currentField: string) => {
  const line = entryLines.value[index]
  if (!line) return

  // Enter 键：如果当前行已填写完整，跳转到下一行
  if (line.description && line.accountId && (line.debitAmount ?? line.creditAmount)) {
    if (index < entryLines.value.length - 1) {
      focusField(index + 1, 'description')
    } else {
      addLine()
      nextTick(() => {
        focusField(entryLines.value.length - 1, 'description')
      })
    }
  } else {
    // 否则在当前行内切换字段
    handleTabKey(index, currentField)
  }
}

// 聚焦到指定字段
const focusField = (index: number, field: string) => {
  nextTick(() => {
    setActiveRow(index, field)
    
    try {
      if (field === 'description') {
        const input = descriptionInputs.value[index]
        if (input && '$el' in input) {
          // el-autocomplete 的焦点处理
          const inputEl = (input.$el as HTMLElement)?.querySelector('input') as HTMLInputElement || (input.$el as HTMLElement)
          if (inputEl && typeof inputEl.focus === 'function') {
            inputEl.focus()
          }
        }
      } else if (field === 'account') {
        const select = accountSelects.value[index]
        if (select && typeof (select as any).focus === 'function') {
          (select as any).focus()
        }
      } else if (field === 'debit') {
        const input = debitInputs.value[index]
        if (input && '$el' in input) {
          // el-input-number 的焦点处理
          const inputEl = (input.$el as HTMLElement)?.querySelector('input') as HTMLInputElement || (input.$el as HTMLElement)
          if (inputEl && typeof inputEl.focus === 'function') {
            inputEl.focus()
            if (typeof inputEl.select === 'function') {
              inputEl.select()
            }
          }
        }
      } else if (field === 'credit') {
        const input = creditInputs.value[index]
        if (input && '$el' in input) {
          // el-input-number 的焦点处理
          const inputEl = (input.$el as HTMLElement)?.querySelector('input') as HTMLInputElement || (input.$el as HTMLElement)
          if (inputEl && typeof inputEl.focus === 'function') {
            inputEl.focus()
            if (typeof inputEl.select === 'function') {
              inputEl.select()
            }
          }
        }
      }
    } catch (error) {
      console.error('Focus error:', error)
    }
  })
}

// 更新余额
const updateBalance = () => {
  // computed 会自动更新
}

// 添加行
const addLine = () => {
  entryLines.value.push({
    date: new Date().toISOString().split('T')[0],
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
    if (activeRowIndex.value >= entryLines.value.length) {
      activeRowIndex.value = entryLines.value.length - 1
    }
  }
}

// 保存凭证
const handleSave = async () => {
  if (!isBalanceValid.value) {
    ElMessage.warning('借贷不平衡，无法保存')
    return
  }

  // 验证必填项
  const hasEmpty = entryLines.value.some(line => {
    if (!line) return true
    return !line.description || !line.accountId ||
           ((line.debitAmount === null || line.debitAmount === undefined) && 
            (line.creditAmount === null || line.creditAmount === undefined))
  })

  if (hasEmpty) {
    ElMessage.warning('请填写完整的凭证信息')
    return
  }

  try {
    // 构建凭证数据
    const splits = entryLines.value
      .filter(line => line && line.accountId !== null && line.accountId !== undefined)
      .map(line => ({
        accountId: line.accountId!,
        direction: (line.debitAmount ?? 0) > 0 ? 'DEBIT' : 'CREDIT',
        amount: line.debitAmount ?? line.creditAmount ?? 0,
        memo: line.description || '',
        ownerId: line.ownerId,
        ownerType: line.ownerType
      }))

    const firstLine = entryLines.value[0]
    const transaction = {
      transDate: firstLine?.date || new Date().toISOString().split('T')[0],
      description: firstLine?.description || '快捷录入凭证',
      splits: splits
    }

    // 调用保存接口
    const response = await request.post('/finance/voucher/add', transaction)
    if (response.code === 200) {
      ElMessage.success('凭证保存成功')
      resetForm()
    } else {
      ElMessage.error(response.msg || '保存失败')
    }
  } catch (error: any) {
    ElMessage.error(error.message || '保存失败')
  }
}

// 重置表单
const resetForm = () => {
  entryLines.value = [
    { date: new Date().toISOString().split('T')[0], description: '', accountId: null, debitAmount: null, creditAmount: null },
    { date: new Date().toISOString().split('T')[0], description: '', accountId: null, debitAmount: null, creditAmount: null }
  ]
  activeRowIndex.value = 0
}

// 格式化金额
const formatAmount = (amount: number | undefined): string => {
  if (amount === undefined || amount === null) {
    return '0.00'
  }
  return amount.toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, ',')
}

onMounted(() => {
  loadLeafAccounts()
  loadOwners()
  
  // 默认聚焦第一行的摘要输入框
  nextTick(() => {
    focusField(0, 'description')
  })
})
</script>

<style scoped lang="scss">
.quick-entry-register {
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

  .entry-table-container {
    margin: 20px 0;
    border: 1px solid #dcdfe6;
    border-radius: 4px;
    overflow: hidden;

    .entry-table {
      width: 100%;
      border-collapse: collapse;

      thead {
        background-color: #f5f7fa;

        th {
          padding: 12px;
          text-align: left;
          font-weight: 600;
          color: #606266;
          border-bottom: 1px solid #dcdfe6;
        }
      }

      tbody {
        tr {
          transition: background-color 0.2s;

          &:hover {
            background-color: #f5f7fa;
          }

          &.active-row {
            background-color: #ecf5ff;
          }

          td {
            padding: 8px 12px;
            border-bottom: 1px solid #ebeef5;

            &:last-child {
              border-right: none;
            }
          }
        }
      }

      .col-date {
        width: 150px;
      }

      .col-description {
        width: 250px;
      }

      .col-account {
        width: 250px;
      }

      .col-debit {
        width: 150px;
      }

      .col-credit {
        width: 150px;
      }

      .col-action {
        width: 80px;
        text-align: center;
      }
    }
  }

  .entry-actions {
    margin-top: 20px;
    display: flex;
    gap: 10px;
  }

  .balance-summary {
    margin-top: 20px;

    .summary-content {
      display: flex;
      justify-content: space-around;
      padding: 15px 0;

      .summary-item {
        display: flex;
        flex-direction: column;
        align-items: center;
        gap: 8px;

        .label {
          font-size: 14px;
          color: #606266;
        }

        .value {
          font-size: 18px;
          font-weight: bold;

          &.debit-total {
            color: #409eff;
          }

          &.credit-total {
            color: #67c23a;
          }

          &.difference {
            font-size: 20px;

            &.balance-balanced {
              color: #67c23a;
            }

            &.balance-debit {
              color: #409eff;
            }

            &.balance-credit {
              color: #f56c6c;
            }
          }
        }
      }
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
