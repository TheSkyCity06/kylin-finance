<template>
  <div class="trial-balance">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>试算平衡表</span>
          <div class="header-actions">
            <el-date-picker
              v-model="queryDate"
              type="month"
              placeholder="选择月份"
              format="YYYY-MM"
              value-format="YYYY-MM"
              @change="loadTrialBalance"
              style="width: 150px; margin-right: 10px"
            />
            <el-button type="primary" @click="loadTrialBalance" :loading="loading">
              <el-icon><Refresh /></el-icon>
              刷新
            </el-button>
            <el-button type="success" @click="exportExcel">
              <el-icon><Download /></el-icon>
              导出Excel
            </el-button>
          </div>
        </div>
      </template>

      <!-- 试算平衡表 -->
      <div class="balance-table">
        <el-table
          :data="trialBalanceData"
          style="width: 100%"
          :border="true"
          v-loading="loading"
          :summary-method="getSummaries"
          show-summary
        >
          <el-table-column prop="accountCode" label="科目代码" width="120" />
          <el-table-column prop="accountName" label="科目名称" min-width="150" />
          <el-table-column prop="accountType" label="科目类型" width="100">
            <template #default="scope">
              <el-tag :type="getAccountTypeColor(scope.row.accountType)">
                {{ getAccountTypeName(scope.row.accountType) }}
              </el-tag>
            </template>
          </el-table-column>

          <el-table-column label="期初余额" align="right">
            <el-table-column prop="periodBeginDebit" label="借方" width="120" align="right">
              <template #default="scope">
                {{ formatAmount(scope.row.periodBeginDebit) }}
              </template>
            </el-table-column>
            <el-table-column prop="periodBeginCredit" label="贷方" width="120" align="right">
              <template #default="scope">
                {{ formatAmount(scope.row.periodBeginCredit) }}
              </template>
            </el-table-column>
          </el-table-column>

          <el-table-column label="本期发生额" align="right">
            <el-table-column prop="periodDebit" label="借方" width="120" align="right">
              <template #default="scope">
                {{ formatAmount(scope.row.periodDebit) }}
              </template>
            </el-table-column>
            <el-table-column prop="periodCredit" label="贷方" width="120" align="right">
              <template #default="scope">
                {{ formatAmount(scope.row.periodCredit) }}
              </template>
            </el-table-column>
          </el-table-column>

          <el-table-column label="期末余额" align="right">
            <el-table-column prop="periodEndDebit" label="借方" width="120" align="right">
              <template #default="scope">
                {{ formatAmount(scope.row.periodEndDebit) }}
              </template>
            </el-table-column>
            <el-table-column prop="periodEndCredit" label="贷方" width="120" align="right">
              <template #default="scope">
                {{ formatAmount(scope.row.periodEndCredit) }}
              </template>
            </el-table-column>
          </el-table-column>
        </el-table>
      </div>

      <!-- 平衡检查 -->
      <div class="balance-check" v-if="trialBalanceData.length > 0">
        <el-alert
          :type="isBalanced ? 'success' : 'error'"
          :title="isBalanced ? '试算平衡正确' : '试算平衡错误'"
          :description="`借方合计: ¥${totalDebit.toFixed(2)} | 贷方合计: ¥${totalCredit.toFixed(2)}`"
          show-icon
          :closable="false"
        />

        <div class="balance-details" v-if="!isBalanced">
          <p>差额: ¥{{ Math.abs(totalDebit - totalCredit).toFixed(2) }}</p>
          <p>建议检查：科目余额计算是否正确，是否存在数据异常</p>
        </div>
      </div>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { Refresh, Download } from '@element-plus/icons-vue'
import { accountingApi, reportApi } from '@/api/finance'
import type { TrialBalanceDTO } from '@/types/finance'
import { downloadExcel, handleExcelExportError } from '@/utils/download'

// 查询参数
const queryDate = ref<string>('')
const loading = ref(false)

// 试算平衡表数据
const trialBalanceData = ref<TrialBalanceDTO[]>([])

// 计算合计
const totalDebit = computed(() => {
  return trialBalanceData.value.reduce((sum, item) => sum + item.periodEndDebit, 0)
})

const totalCredit = computed(() => {
  return trialBalanceData.value.reduce((sum, item) => sum + item.periodEndCredit, 0)
})

// 检查是否平衡
const isBalanced = computed(() => {
  return Math.abs(totalDebit.value - totalCredit.value) < 0.01
})

// 获取科目类型名称
const getAccountTypeName = (type: string): string => {
  const typeNames: Record<string, string> = {
    ASSET: '资产',
    LIABILITY: '负债',
    EQUITY: '权益',
    INCOME: '收入',
    EXPENSE: '支出'
  }
  return typeNames[type] || type
}

// 获取科目类型颜色
const getAccountTypeColor = (type: string): string => {
  const colors: Record<string, string> = {
    ASSET: 'primary',
    LIABILITY: 'success',
    EQUITY: 'warning',
    INCOME: 'danger',
    EXPENSE: 'info'
  }
  return colors[type] || ''
}

// 格式化金额
const formatAmount = (amount: number): string => {
  return amount > 0 ? `¥${amount.toFixed(2)}` : ''
}

// 加载试算平衡表
const loadTrialBalance = async () => {
  if (!queryDate.value) {
    ElMessage.warning('请选择查询月份')
    return
  }

  loading.value = true
  try {
    // 构造开始和结束日期
    const year = queryDate.value.split('-')[0]
    const month = queryDate.value.split('-')[1]
    const startDate = `${year}-${month}-01`
    const endDate = new Date(parseInt(year), parseInt(month), 0).toISOString().split('T')[0]

    const res = await accountingApi.generateTrialBalance(startDate, endDate)
    trialBalanceData.value = res.data
  } catch (error) {
    ElMessage.error('加载试算平衡表失败')
  } finally {
    loading.value = false
  }
}

// 表格合计行
const getSummaries = (param: any) => {
  const { columns, data } = param
  const sums: string[] = []

  columns.forEach((column: any, index: number) => {
    if (index === 0) {
      sums[index] = '合计'
    } else if (index === 1) {
      sums[index] = ''
    } else if (index === 2) {
      sums[index] = ''
    } else if (index >= 3 && index <= 8) {
      // 计算各列的合计
      const values = data.map((item: TrialBalanceDTO) => {
        switch (index) {
          case 3: return item.periodBeginDebit
          case 4: return item.periodBeginCredit
          case 5: return item.periodDebit
          case 6: return item.periodCredit
          case 7: return item.periodEndDebit
          case 8: return item.periodEndCredit
          default: return 0
        }
      })
      const sum = values.reduce((prev: number, curr: number) => prev + curr, 0)
      sums[index] = sum > 0 ? `¥${sum.toFixed(2)}` : ''
    } else {
      sums[index] = ''
    }
  })

  return sums
}

// 导出Excel
const exportExcel = async () => {
  if (!queryDate.value) {
    ElMessage.warning('请先选择查询月份')
    return
  }

  try {
    loading.value = true
    
    // 构造开始和结束日期（与loadTrialBalance中的逻辑一致）
    const year = queryDate.value.split('-')[0]
    const month = queryDate.value.split('-')[1]
    const startDate = `${year}-${month}-01`
    const endDate = new Date(parseInt(year), parseInt(month), 0).toISOString().split('T')[0]
    
    // 发起请求，responseType 已在 API 中设置为 'blob'
    const response = await reportApi.exportTrialBalance(startDate, endDate)
    
    // 使用工具函数下载Excel
    await downloadExcel(response, `trial_balance_${startDate}_${endDate}`)
  } catch (error: any) {
    // 使用工具函数处理错误
    await handleExcelExportError(error)
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  // 默认选择当前月份
  const now = new Date()
  queryDate.value = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`
  loadTrialBalance()
})
</script>

<style scoped>
.trial-balance {
  padding: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.header-actions {
  display: flex;
  align-items: center;
  gap: 10px;
}

.balance-table {
  margin: 20px 0;
}

.balance-check {
  margin-top: 20px;
}

.balance-details {
  margin-top: 15px;
  padding: 15px;
  background-color: #fdf6ec;
  border: 1px solid #f5dab1;
  border-radius: 4px;
}

.balance-details p {
  margin: 5px 0;
  color: #e6a23c;
}

:deep(.el-table th) {
  background-color: #f5f7fa;
  color: #606266;
  font-weight: 600;
}

:deep(.el-table th .cell) {
  text-align: center;
}

:deep(.el-table .el-table__footer) {
  background-color: #fafafa;
}

:deep(.el-table .el-table__footer .cell) {
  font-weight: 600;
  color: #303133;
}
</style>
