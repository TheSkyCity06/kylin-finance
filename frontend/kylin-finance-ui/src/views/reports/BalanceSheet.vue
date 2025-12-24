<template>
  <div class="balance-sheet">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>资产负债表</span>
          <div class="header-actions">
            <el-date-picker
              v-model="reportDate"
              type="date"
              placeholder="选择报表日期"
              format="YYYY-MM-DD"
              value-format="YYYY-MM-DD"
              @change="loadBalanceSheet"
              style="width: 150px; margin-right: 10px"
            />
            <el-button type="primary" @click="loadBalanceSheet" :loading="loading">
              <el-icon><Refresh /></el-icon>
              生成报表
            </el-button>
            <el-button type="success" @click="exportExcel">
              <el-icon><Download /></el-icon>
              导出Excel
            </el-button>
            <el-button type="info" @click="printReport">
              <el-icon><Printer /></el-icon>
              打印
            </el-button>
          </div>
        </div>
      </template>

      <!-- 报表信息 -->
      <div class="report-info">
        <div class="company-info">
          <h2>麒麟财务管理系统</h2>
          <h3>资产负债表</h3>
          <p>报表日期：{{ reportDate || '未选择' }}</p>
          <p>编制单位：人民币元</p>
        </div>
      </div>

      <!-- 资产负债表主体 -->
      <div class="balance-sheet-content" v-if="balanceSheetData">
        <el-row :gutter="20">
          <!-- 资产部分 -->
          <el-col :span="12">
            <div class="assets-section">
              <h4>资产</h4>
              <el-table
                :data="balanceSheetData.assets"
                style="width: 100%"
                :border="true"
                :show-header="false"
                :summary-method="getAssetsSummary"
                show-summary
              >
                <el-table-column prop="accountName" label="项目" min-width="150" />
                <el-table-column prop="amount" label="金额" width="180" align="right" class-name="amount-column">
                  <template #default="scope">
                    <span class="amount-cell">{{ formatAmount(scope.row.amount) }}</span>
                  </template>
                </el-table-column>
                <el-table-column width="180" class-name="summary-amount-column">
                  <template #default>
                    <!-- 数据行此列为空 -->
                  </template>
                </el-table-column>
              </el-table>
            </div>
          </el-col>

          <!-- 负债和所有者权益部分 -->
          <el-col :span="12">
            <div class="liabilities-section">
              <h4>负债</h4>
              <el-table
                :data="balanceSheetData.liabilities"
                style="width: 100%"
                :border="true"
                :show-header="false"
                :summary-method="getLiabilitiesSummary"
                show-summary
              >
                <el-table-column prop="accountName" label="项目" min-width="150" />
                <el-table-column prop="amount" label="金额" width="180" align="right" class-name="amount-column">
                  <template #default="scope">
                    <span class="amount-cell">{{ formatAmount(scope.row.amount) }}</span>
                  </template>
                </el-table-column>
                <el-table-column width="180" class-name="summary-amount-column">
                  <template #default>
                    <!-- 数据行此列为空 -->
                  </template>
                </el-table-column>
              </el-table>

              <h4 style="margin-top: 30px">所有者权益</h4>
              <el-table
                :data="balanceSheetData.equity"
                style="width: 100%"
                :border="true"
                :show-header="false"
                :summary-method="getEquitySummary"
                show-summary
              >
                <el-table-column prop="accountName" label="项目" min-width="150" />
                <el-table-column prop="amount" label="金额" width="180" align="right" class-name="amount-column">
                  <template #default="scope">
                    <span class="amount-cell">{{ formatAmount(scope.row.amount) }}</span>
                  </template>
                </el-table-column>
                <el-table-column width="180" class-name="summary-amount-column">
                  <template #default>
                    <!-- 数据行此列为空 -->
                  </template>
                </el-table-column>
              </el-table>
            </div>
          </el-col>
        </el-row>

        <!-- 平衡检查 -->
        <div class="balance-verification">
          <el-alert
            :type="isBalanced ? 'success' : 'error'"
            :title="isBalanced ? '资产负债平衡' : '资产负债不平衡'"
            :description="`资产合计: ¥${formatNumber(balanceSheetData.totalAssets)} | 负债及权益合计: ¥${formatNumber(balanceSheetData.totalLiabilitiesAndEquity)}`"
            show-icon
            :closable="false"
          />
        </div>
      </div>

      <!-- 空状态 -->
      <div v-else class="empty-state">
        <el-empty description="请选择报表日期并点击生成报表" />
      </div>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { Refresh, Download, Printer } from '@element-plus/icons-vue'
import { reportApi } from '@/api/finance'
import type { BalanceSheetDTO, BalanceSheetItemDTO } from '@/types/finance'
import { downloadExcel, handleExcelExportError } from '@/utils/download'

// 报表参数
const reportDate = ref<string>('')
const loading = ref(false)

// 资产负债表数据
const balanceSheetData = ref<BalanceSheetDTO | null>(null)

// 检查资产负债是否平衡
const isBalanced = computed(() => {
  if (!balanceSheetData.value) return false
  return Math.abs(balanceSheetData.value.totalAssets - balanceSheetData.value.totalLiabilitiesAndEquity) < 0.01
})

// 格式化金额
const formatAmount = (amount: number): string => {
  return amount > 0 ? formatNumber(amount) : ''
}

const formatNumber = (num: number): string => {
  return num.toLocaleString('zh-CN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
}

// 资产部分合计
const getAssetsSummary = (param: any) => {
  const sums = ['', '资产总计', formatAmount(balanceSheetData.value?.totalAssets || 0)]
  return sums
}

// 负债部分合计
const getLiabilitiesSummary = (param: any) => {
  const sums = ['', '负债合计', formatAmount(balanceSheetData.value?.totalLiabilities || 0)]
  return sums
}

// 所有者权益部分合计
const getEquitySummary = (param: any) => {
  const sums = ['', '所有者权益合计', formatAmount(balanceSheetData.value?.totalEquity || 0)]
  return sums
}

// 加载资产负债表
const loadBalanceSheet = async () => {
  if (!reportDate.value) {
    ElMessage.warning('请选择报表日期')
    return
  }

  loading.value = true
  try {
    const res = await reportApi.generateBalanceSheet(reportDate.value)
    balanceSheetData.value = res.data
  } catch (error) {
    ElMessage.error('生成资产负债表失败')
  } finally {
    loading.value = false
  }
}

// 导出Excel
const exportExcel = async () => {
  if (!reportDate.value) {
    ElMessage.warning('请先选择报表日期')
    return
  }

  try {
    loading.value = true
    
    // 发起请求，responseType 已在 API 中设置为 'blob'
    const response = await reportApi.exportBalanceSheet(reportDate.value)
    
    // 使用工具函数下载Excel
    await downloadExcel(response, `资产负债表_${reportDate.value}`)
  } catch (error: any) {
    // 使用工具函数处理错误
    await handleExcelExportError(error)
  } finally {
    loading.value = false
  }
}

// 打印报表
const printReport = () => {
  window.print()
}

onMounted(() => {
  // 默认选择今天
  reportDate.value = new Date().toISOString().split('T')[0]
})
</script>

<style scoped>
.balance-sheet {
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

.balance-sheet-content {
  margin-top: 20px;
}

.assets-section,
.liabilities-section {
  margin-bottom: 20px;
}

.assets-section h4,
.liabilities-section h4 {
  margin: 0 0 15px 0;
  color: #303133;
  font-size: 16px;
  font-weight: 600;
  border-bottom: 2px solid #409EFF;
  padding-bottom: 5px;
}

.liabilities-section h4 {
  border-bottom-color: #67C23A;
}

.balance-verification {
  margin-top: 30px;
  padding: 20px;
  background-color: #f8f9fa;
  border-radius: 6px;
}

.empty-state {
  text-align: center;
  padding: 60px 0;
}

:deep(.el-table) {
  margin-bottom: 0;
}

:deep(.el-table th),
:deep(.el-table td) {
  border-right: 1px solid #ebeef5;
}

:deep(.el-table .el-table__footer) {
  background-color: #fafafa;
  table-layout: fixed !important;
}

:deep(.el-table .el-table__footer .cell) {
  font-weight: 600;
  color: #303133;
}

/* 强制表格使用固定布局，确保列宽一致 */
:deep(.el-table) {
  table-layout: fixed !important;
}

:deep(.el-table__header-wrapper table),
:deep(.el-table__body-wrapper table),
:deep(.el-table__footer-wrapper table) {
  table-layout: fixed !important;
  width: 100% !important;
}

/* 修复总计行金额单元格的换行和挤压问题 - 使用更通用的选择器 */
:deep(.el-table .el-table__footer-wrapper .el-table__footer tbody tr td) {
  white-space: nowrap !important;
  overflow: visible !important;
  word-break: keep-all !important;
}

/* 确保总计行的所有单元格都不换行 */
:deep(.el-table .el-table__footer-wrapper .el-table__footer tbody tr td .cell) {
  white-space: nowrap !important;
  overflow: visible !important;
  word-break: keep-all !important;
  text-overflow: clip !important;
}

/* 特别针对金额列（第3列，summary-method返回数组的第3个元素对应第3列金额） */
/* 根据实际HTML：第1列：空，第2列：'资产总计'，第3列：金额 */
/* 所以金额在第3列（nth-child(3)），但第3列宽度只有50px，需要增加到180px */
:deep(.el-table .el-table__footer-wrapper .el-table__footer tbody tr td:nth-child(3)) {
  white-space: nowrap !important;
  min-width: 180px !important;
  width: 180px !important;
  max-width: none !important;
  flex-shrink: 0 !important;
  flex-grow: 0 !important;
  text-align: right !important;
  overflow: visible !important;
}

/* 针对总计行金额列的单元格内容（第3列） */
:deep(.el-table .el-table__footer-wrapper .el-table__footer tbody tr td:nth-child(3) .cell) {
  white-space: nowrap !important;
  text-align: right !important;
  overflow: visible !important;
  word-break: keep-all !important;
  text-overflow: clip !important;
  display: flex !important;
  justify-content: flex-end !important;
  align-items: center !important;
}

/* 确保第3列（summary-amount-column）有足够的宽度 */
:deep(.el-table .summary-amount-column) {
  min-width: 180px !important;
  width: 180px !important;
}

:deep(.el-table .summary-amount-column .cell) {
  white-space: nowrap !important;
  text-align: right !important;
}

/* 确保金额列本身有足够的宽度 */
:deep(.el-table .amount-column) {
  min-width: 180px !important;
  width: 180px !important;
}

:deep(.el-table .amount-column .cell) {
  white-space: nowrap !important;
  text-align: right !important;
}

/* 确保footer的列宽与body列宽一致 */
:deep(.el-table .el-table__footer-wrapper colgroup col:nth-child(2)) {
  width: 180px !important;
  min-width: 180px !important;
}

:deep(.el-table .el-table__body-wrapper colgroup col:nth-child(2)) {
  width: 180px !important;
  min-width: 180px !important;
}

/* 确保第3列（金额列）的宽度为180px */
:deep(.el-table .el-table__footer-wrapper colgroup col:nth-child(3)) {
  width: 180px !important;
  min-width: 180px !important;
}

:deep(.el-table .el-table__body-wrapper colgroup col:nth-child(3)) {
  width: 180px !important;
  min-width: 180px !important;
}

/* 确保普通数据行的金额列也不换行 */
:deep(.el-table .el-table__body-wrapper .el-table__body tbody tr td:nth-child(2) .cell) {
  white-space: nowrap !important;
  text-align: right !important;
}

.amount-cell {
  white-space: nowrap !important;
  display: inline-block;
}

@media print {
  .card-header,
  .header-actions,
  .balance-verification {
    display: none !important;
  }

  .balance-sheet {
    padding: 0;
  }

  .el-card {
    box-shadow: none !important;
  }
}
</style>
