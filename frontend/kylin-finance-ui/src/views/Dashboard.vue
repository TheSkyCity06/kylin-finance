<template>
  <div class="dashboard">
    <div class="stats-cards">
      <el-row :gutter="20">
        <el-col :span="6">
          <el-card class="stat-card">
            <div class="stat-content">
              <div class="stat-icon">
                <el-icon size="32" color="#409EFF"><Document /></el-icon>
              </div>
              <div class="stat-info">
                <div class="stat-number">{{ stats.totalVouchers }}</div>
                <div class="stat-label">总凭证数</div>
              </div>
            </div>
          </el-card>
        </el-col>

        <el-col :span="6">
          <el-card class="stat-card">
            <div class="stat-content">
              <div class="stat-icon">
                <el-icon size="32" color="#67C23A"><List /></el-icon>
              </div>
              <div class="stat-info">
                <div class="stat-number">{{ stats.totalAccounts }}</div>
                <div class="stat-label">科目总数</div>
              </div>
            </div>
          </el-card>
        </el-col>

        <el-col :span="6">
          <el-card class="stat-card">
            <div class="stat-content">
              <div class="stat-icon">
                <el-icon size="32" color="#E6A23C"><TrendCharts /></el-icon>
              </div>
              <div class="stat-info">
                <div class="stat-number">¥{{ formatNumber(stats.totalAssets) }}</div>
                <div class="stat-label">总资产</div>
              </div>
            </div>
          </el-card>
        </el-col>

        <el-col :span="6">
          <el-card class="stat-card">
            <div class="stat-content">
              <div class="stat-icon">
                <el-icon size="32" color="#F56C6C"><Money /></el-icon>
              </div>
              <div class="stat-info">
                <div class="stat-number">¥{{ formatNumber(stats.netProfit) }}</div>
                <div class="stat-label">净利润</div>
              </div>
            </div>
          </el-card>
        </el-col>
      </el-row>
    </div>

    <div class="recent-activities">
      <el-row :gutter="20">
        <el-col :span="12">
          <el-card>
            <template #header>
              <div class="card-header">
                <span>最近凭证</span>
                <el-button text type="primary" @click="$router.push('/voucher/query')">
                  查看全部
                </el-button>
              </div>
            </template>
            <div v-if="recentVouchers.length === 0" class="no-data">
              <el-empty description="暂无凭证数据" />
            </div>
            <div v-else class="voucher-list">
              <div
                v-for="voucher in recentVouchers"
                :key="voucher.transId"
                class="voucher-item"
              >
                <div class="voucher-info">
                  <div class="voucher-no">{{ voucher.voucherNo }}</div>
                  <div class="voucher-desc">{{ voucher.description }}</div>
                </div>
                <div class="voucher-meta">
                  <span class="voucher-date">{{ voucher.transDate }}</span>
                  <el-tag
                    :type="voucher.status === 1 ? 'success' : 'warning'"
                    size="small"
                  >
                    {{ voucher.status === 1 ? '已审核' : '草稿' }}
                  </el-tag>
                </div>
              </div>
            </div>
          </el-card>
        </el-col>

        <el-col :span="12">
          <el-card>
            <template #header>
              <div class="card-header">
                <span>快速操作</span>
              </div>
            </template>
            <div class="quick-actions">
              <el-row :gutter="10">
                <el-col :span="12">
                  <el-button
                    type="primary"
                    class="action-btn"
                    @click="$router.push('/voucher/add')"
                  >
                    <el-icon><Plus /></el-icon>
                    <div>录入凭证</div>
                  </el-button>
                </el-col>
                <el-col :span="12">
                  <el-button
                    type="success"
                    class="action-btn"
                    @click="$router.push('/reports/balance-sheet')"
                  >
                    <el-icon><TrendCharts /></el-icon>
                    <div>资产负债表</div>
                  </el-button>
                </el-col>
                <el-col :span="12">
                  <el-button
                    type="info"
                    class="action-btn"
                    @click="$router.push('/accounts')"
                  >
                    <el-icon><List /></el-icon>
                    <div>科目管理</div>
                  </el-button>
                </el-col>
                <el-col :span="12">
                  <el-button
                    type="warning"
                    class="action-btn"
                    @click="$router.push('/reports/trial-balance')"
                  >
                    <el-icon><DataAnalysis /></el-icon>
                    <div>试算平衡</div>
                  </el-button>
                </el-col>
              </el-row>
            </div>
          </el-card>
        </el-col>
      </el-row>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import {
  Document,
  List,
  TrendCharts,
  Money,
  Plus,
  DataAnalysis
} from '@element-plus/icons-vue'
import { accountingApi, reportApi, voucherApi, accountApi } from '@/api/finance'
import type { AccountDTO } from '@/types/finance'

interface Stats {
  totalVouchers: number
  totalAccounts: number
  totalAssets: number
  netProfit: number
}

interface RecentVoucher {
  transId: number
  voucherNo: string
  description: string
  transDate: string
  status: number
}

const stats = ref<Stats>({
  totalVouchers: 0,
  totalAccounts: 0,
  totalAssets: 0,
  netProfit: 0
})

const recentVouchers = ref<RecentVoucher[]>([])

const formatNumber = (num: number): string => {
  if (num >= 10000) {
    return (num / 10000).toFixed(1) + '万'
  }
  return num.toLocaleString()
}

// 递归统计科目树中的所有科目数量
const countAccounts = (accounts: AccountDTO[]): number => {
  let count = 0
  for (const account of accounts) {
    count++
    if (account.children && account.children.length > 0) {
      count += countAccounts(account.children)
    }
  }
  return count
}

const loadDashboardData = async () => {
  try {
    // 并行获取所有数据
    const [balanceSheetRes, voucherCountRes, accountTreeRes, recentVoucherRes] = await Promise.all([
      // 获取资产负债表数据
      reportApi.generateBalanceSheet().catch(() => ({ data: null })),
      // 获取凭证总数（只查询总数，不返回数据）
      voucherApi.queryVouchers({ pageNum: 1, pageSize: 1 }).catch(() => ({ data: { total: 0 } })),
      // 获取科目树
      accountApi.getAccountTree().catch(() => ({ data: [] })),
      // 获取最近凭证（按日期倒序，取前5条）
      voucherApi.queryVouchers({ pageNum: 1, pageSize: 5 }).catch(() => ({ data: { records: [] } }))
    ])
    
    // 处理资产负债表数据
    if (balanceSheetRes && balanceSheetRes.data) {
      stats.value.totalAssets = balanceSheetRes.data.totalAssets || 0
      stats.value.netProfit = balanceSheetRes.data.totalEquity || 0
    } else {
      stats.value.totalAssets = 0
      stats.value.netProfit = 0
    }

    // 获取凭证总数
    stats.value.totalVouchers = voucherCountRes.data?.total || 0

    // 统计科目总数
    const accountTree = accountTreeRes.data || []
    stats.value.totalAccounts = countAccounts(accountTree)

    // 获取最近凭证数据
    recentVouchers.value = (recentVoucherRes.data?.records || [])
      .filter((voucher: any) => voucher.transId) // 过滤掉没有transId的记录
      .map((voucher: any) => ({
        transId: voucher.transId!,
        voucherNo: voucher.voucherNo || '',
        description: voucher.description || '',
        transDate: voucher.transDate || '',
        status: voucher.status || 0
      }))
  } catch (error: any) {
    console.error('加载仪表板数据失败:', error)
    const errorMsg = error?.message || error?.response?.data?.msg || '加载仪表板数据失败'
    ElMessage.error(errorMsg)
  }
}

onMounted(() => {
  loadDashboardData()
})
</script>

<style scoped>
.dashboard {
  padding: 20px;
}

.stats-cards {
  margin-bottom: 30px;
}

.stat-card {
  transition: all 0.3s ease;
}

.stat-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.stat-content {
  display: flex;
  align-items: center;
  gap: 15px;
}

.stat-icon {
  flex-shrink: 0;
}

.stat-info {
  flex: 1;
}

.stat-number {
  font-size: 24px;
  font-weight: bold;
  color: #303133;
  margin-bottom: 4px;
}

.stat-label {
  font-size: 14px;
  color: #909399;
}

.recent-activities {
  margin-top: 30px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.voucher-list {
  max-height: 300px;
  overflow-y: auto;
}

.voucher-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px 0;
  border-bottom: 1px solid #f0f0f0;
}

.voucher-item:last-child {
  border-bottom: none;
}

.voucher-info {
  flex: 1;
}

.voucher-no {
  font-weight: 500;
  color: #303133;
  margin-bottom: 4px;
}

.voucher-desc {
  font-size: 12px;
  color: #909399;
}

.voucher-meta {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 4px;
}

.voucher-date {
  font-size: 12px;
  color: #909399;
}

.quick-actions {
  padding: 10px 0;
}

.action-btn {
  width: 100%;
  height: 80px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 8px;
  margin-bottom: 10px;
}

.action-btn .el-icon {
  font-size: 20px;
}

.no-data {
  text-align: center;
  padding: 40px 0;
}
</style>
