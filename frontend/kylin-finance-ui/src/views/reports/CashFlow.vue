<template>
  <div class="cash-flow">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>现金流量表</span>
          <div class="header-actions">
            <el-date-picker
              v-model="startDate"
              type="date"
              placeholder="开始日期"
              format="YYYY-MM-DD"
              value-format="YYYY-MM-DD"
              style="width: 130px; margin-right: 10px"
            />
            <span style="margin-right: 10px">至</span>
            <el-date-picker
              v-model="endDate"
              type="date"
              placeholder="结束日期"
              format="YYYY-MM-DD"
              value-format="YYYY-MM-DD"
              @change="loadCashFlow"
              style="width: 130px; margin-right: 10px"
            />
            <el-button type="primary" @click="loadCashFlow" :loading="loading">
              <el-icon><Refresh /></el-icon>
              生成报表
            </el-button>
            <el-button type="success" @click="exportExcel" :loading="exportLoading">
              <el-icon><Download /></el-icon>
              导出Excel
            </el-button>
          </div>
        </div>
      </template>

      <!-- 报表信息 -->
      <div class="report-info">
        <div class="company-info">
          <h2>麒麟财务管理系统</h2>
          <h3>现金流量表</h3>
          <p>报表期间：{{ startDate || '未选择' }} 至 {{ endDate || '未选择' }}</p>
          <p>编制单位：人民币元</p>
        </div>
      </div>

      <!-- 现金流量表主体 -->
      <div class="cash-flow-content" v-if="cashFlowData">
        <div class="cash-flow-section">
          <!-- 经营活动产生的现金流量 -->
          <div class="section-block">
            <h4>一、经营活动产生的现金流量</h4>
            <el-table
              :data="cashFlowData.operatingActivities"
              style="width: 100%"
              :border="true"
              :show-header="false"
            >
              <el-table-column prop="itemName" label="项目" min-width="200" />
              <el-table-column width="50" />
              <el-table-column prop="amount" label="金额" width="150" align="right">
                <template #default="scope">
                  {{ formatAmount(scope.row.amount) }}
                </template>
              </el-table-column>
            </el-table>
            <div class="section-total">
              <strong>经营活动产生的现金流量净额</strong>
              <strong>{{ formatAmount(cashFlowData.netOperatingCashFlow) }}</strong>
            </div>
          </div>

          <!-- 投资活动产生的现金流量 -->
          <div class="section-block">
            <h4>二、投资活动产生的现金流量</h4>
            <el-table
              :data="cashFlowData.investingActivities"
              style="width: 100%"
              :border="true"
              :show-header="false"
            >
              <el-table-column prop="itemName" label="项目" min-width="200" />
              <el-table-column width="50" />
              <el-table-column prop="amount" label="金额" width="150" align="right">
                <template #default="scope">
                  {{ formatAmount(scope.row.amount) }}
                </template>
              </el-table-column>
            </el-table>
            <div class="section-total">
              <strong>投资活动产生的现金流量净额</strong>
              <strong>{{ formatAmount(cashFlowData.netInvestingCashFlow) }}</strong>
            </div>
          </div>

          <!-- 筹资活动产生的现金流量 -->
          <div class="section-block">
            <h4>三、筹资活动产生的现金流量</h4>
            <el-table
              :data="cashFlowData.financingActivities"
              style="width: 100%"
              :border="true"
              :show-header="false"
            >
              <el-table-column prop="itemName" label="项目" min-width="200" />
              <el-table-column width="50" />
              <el-table-column prop="amount" label="金额" width="150" align="right">
                <template #default="scope">
                  {{ formatAmount(scope.row.amount) }}
                </template>
              </el-table-column>
            </el-table>
            <div class="section-total">
              <strong>筹资活动产生的现金流量净额</strong>
              <strong>{{ formatAmount(cashFlowData.netFinancingCashFlow) }}</strong>
            </div>
          </div>

          <!-- 现金净增加额 -->
          <div class="net-increase">
            <h4>四、现金及现金等价物净增加额</h4>
            <div class="net-amount">
              <span>现金及现金等价物净增加额</span>
              <span class="amount">{{ formatAmount(cashFlowData.netIncreaseInCash) }}</span>
            </div>
          </div>

          <!-- 期初和期末余额 -->
          <div class="balance-info">
            <div class="balance-row">
              <span>加：期初现金及现金等价物余额</span>
              <span>{{ formatAmount(cashFlowData.beginningCashBalance) }}</span>
            </div>
            <div class="balance-row final">
              <span><strong>期末现金及现金等价物余额</strong></span>
              <span><strong>{{ formatAmount(cashFlowData.endingCashBalance) }}</strong></span>
            </div>
          </div>
        </div>
      </div>

      <!-- 空状态 -->
      <div v-else class="empty-state">
        <el-empty description="请选择报表期间并点击生成报表" />
      </div>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { Refresh, Download } from '@element-plus/icons-vue'
import { reportApi } from '@/api/finance'
import type { CashFlowDTO } from '@/types/finance'
import { downloadExcel, handleExcelExportError } from '@/utils/download'

// 报表参数
const startDate = ref<string>('')
const endDate = ref<string>('')
const loading = ref(false)
const exportLoading = ref(false)

// 现金流量表数据
const cashFlowData = ref<CashFlowDTO | null>(null)

// 格式化金额
const formatAmount = (amount: number): string => {
  return amount.toLocaleString('zh-CN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
}

// 加载现金流量表
const loadCashFlow = async () => {
  if (!startDate.value || !endDate.value) {
    ElMessage.warning('请选择完整的报表期间')
    return
  }

  if (startDate.value > endDate.value) {
    ElMessage.warning('开始日期不能晚于结束日期')
    return
  }

  loading.value = true
  try {
    const res = await reportApi.generateCashFlowStatement(startDate.value, endDate.value)
    cashFlowData.value = res.data
  } catch (error) {
    ElMessage.error('生成现金流量表失败')
  } finally {
    loading.value = false
  }
}

// 导出Excel
const exportExcel = async () => {
  if (!startDate.value || !endDate.value) {
    ElMessage.warning('请先选择完整的报表期间')
    return
  }

  if (startDate.value > endDate.value) {
    ElMessage.warning('开始日期不能晚于结束日期')
    return
  }

  try {
    exportLoading.value = true
    
    // 发起请求，responseType 已在 API 中设置为 'blob'
    const response = await reportApi.exportCashFlow(startDate.value, endDate.value)
    
    // 使用工具函数下载Excel，文件名：cash_flow.xlsx
    await downloadExcel(response, 'cash_flow')
  } catch (error: any) {
    // 使用工具函数处理错误
    await handleExcelExportError(error)
  } finally {
    exportLoading.value = false
  }
}

onMounted(() => {
  // 默认选择本月
  const now = new Date()
  const year = now.getFullYear()
  const month = now.getMonth() + 1

  startDate.value = `${year}-${String(month).padStart(2, '0')}-01`
  endDate.value = new Date(year, month, 0).toISOString().split('T')[0]
})
</script>

<style scoped>
.cash-flow {
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

.report-info {
  text-align: center;
  margin-bottom: 30px;
  padding: 20px;
  background-color: #f8f9fa;
  border-radius: 6px;
}

.company-info h2 {
  margin: 0 0 10px 0;
  color: #409EFF;
  font-size: 24px;
}

.company-info h3 {
  margin: 0 0 15px 0;
  color: #303133;
  font-size: 18px;
}

.company-info p {
  margin: 5px 0;
  color: #606266;
  font-size: 14px;
}

.cash-flow-content {
  margin-top: 20px;
}

.section-block {
  margin-bottom: 30px;
}

.section-block h4 {
  margin: 0 0 15px 0;
  color: #303133;
  font-size: 16px;
  font-weight: 600;
  border-bottom: 2px solid #409EFF;
  padding-bottom: 5px;
}

.section-total {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 10px 20px;
  background-color: #f5f7fa;
  border: 1px solid #ebeef5;
  border-radius: 4px;
  margin-top: 10px;
}

.net-increase {
  margin-bottom: 20px;
}

.net-increase h4 {
  margin: 0 0 15px 0;
  color: #303133;
  font-size: 16px;
  font-weight: 600;
  border-bottom: 2px solid #E6A23C;
  padding-bottom: 5px;
}

.net-amount {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 15px 20px;
  background-color: #fdf6ec;
  border: 1px solid #f5dab1;
  border-radius: 4px;
  font-size: 16px;
}

.balance-info {
  margin-top: 30px;
  padding: 20px;
  background-color: #f0f9ff;
  border: 1px solid #b3e5fc;
  border-radius: 6px;
}

.balance-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 8px 0;
  font-size: 14px;
}

.balance-row.final {
  margin-top: 15px;
  padding-top: 15px;
  border-top: 2px solid #409EFF;
  font-size: 16px;
}

.empty-state {
  text-align: center;
  padding: 60px 0;
}

:deep(.el-table td),
:deep(.el-table th) {
  border-right: 1px solid #ebeef5;
}

@media print {
  .card-header,
  .header-actions {
    display: none !important;
  }

  .cash-flow {
    padding: 0;
  }

  .el-card {
    box-shadow: none !important;
  }
}
</style>
