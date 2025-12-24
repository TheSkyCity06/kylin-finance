<template>
  <div class="query-voucher">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>凭证查询</span>
          <el-button type="primary" @click="$router.push('/voucher/add')">
            <el-icon><Plus /></el-icon>
            录入凭证
          </el-button>
        </div>
      </template>

      <!-- 查询条件 -->
      <div class="query-form">
        <el-form :model="queryForm" label-width="100px">
          <el-row :gutter="20">
            <el-col :span="6">
              <el-form-item label="凭证号">
                <el-input
                  v-model="queryForm.voucherNo"
                  placeholder="输入凭证号"
                  clearable
                />
              </el-form-item>
            </el-col>
            <el-col :span="6">
              <el-form-item label="开始日期">
                <el-date-picker
                  v-model="queryForm.startDate"
                  type="date"
                  placeholder="选择开始日期"
                  format="YYYY-MM-DD"
                  value-format="YYYY-MM-DD"
                  style="width: 100%"
                />
              </el-form-item>
            </el-col>
            <el-col :span="6">
              <el-form-item label="结束日期">
                <el-date-picker
                  v-model="queryForm.endDate"
                  type="date"
                  placeholder="选择结束日期"
                  format="YYYY-MM-DD"
                  value-format="YYYY-MM-DD"
                  style="width: 100%"
                />
              </el-form-item>
            </el-col>
            <el-col :span="6">
              <el-form-item label="状态">
                <el-select v-model="queryForm.status" placeholder="选择状态" clearable style="width: 100%">
                  <el-option label="草稿" :value="0" />
                  <el-option label="已审核" :value="1" />
                </el-select>
              </el-form-item>
            </el-col>
          </el-row>

          <el-row>
            <el-col :span="24" class="text-center">
              <el-button type="primary" @click="handleQuery" :loading="loading">
                <el-icon><Search /></el-icon>
                查询
              </el-button>
              <el-button @click="resetQuery">
                <el-icon><Refresh /></el-icon>
                重置
              </el-button>
            </el-col>
          </el-row>
        </el-form>
      </div>

      <!-- 凭证列表 -->
      <div class="voucher-table">
        <el-table
          :data="voucherList"
          style="width: 100%"
          :border="true"
          v-loading="loading"
        >
          <el-table-column prop="voucherNo" label="凭证号" width="150" />
          <el-table-column prop="transDate" label="交易日期" width="120" />
          <el-table-column prop="description" label="摘要" min-width="200" />
          <el-table-column label="状态" width="100">
            <template #default="scope">
              <el-tag :type="scope.row.status === 1 ? 'success' : 'warning'">
                {{ scope.row.status === 1 ? '已审核' : '草稿' }}
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="enterDate" label="录入时间" width="160" />
          <el-table-column label="操作" width="250" fixed="right">
            <template #default="scope">
              <el-button
                type="primary"
                size="small"
                @click="viewVoucher(scope.row)"
              >
                <el-icon><View /></el-icon>
                查看
              </el-button>
              <el-button
                v-if="scope.row.status === 0"
                type="success"
                size="small"
                @click="editVoucher(scope.row)"
              >
                <el-icon><Edit /></el-icon>
                修改
              </el-button>
              <el-button
                v-if="scope.row.status === 0"
                type="danger"
                size="small"
                @click="deleteVoucher(scope.row)"
              >
                <el-icon><Delete /></el-icon>
                删除
              </el-button>
              <el-button
                v-if="scope.row.status === 0"
                type="warning"
                size="small"
                @click="auditVoucher(scope.row)"
              >
                <el-icon><Check /></el-icon>
                审核
              </el-button>
            </template>
          </el-table-column>
        </el-table>
      </div>

      <!-- 分页 -->
      <div class="pagination">
        <el-pagination
          v-model:current-page="currentPage"
          v-model:page-size="pageSize"
          :page-sizes="[10, 20, 50, 100]"
          :total="total"
          layout="total, sizes, prev, pager, next, jumper"
          @size-change="handleSizeChange"
          @current-change="handleCurrentChange"
        />
      </div>
    </el-card>

    <!-- 凭证详情对话框 -->
    <el-dialog
      v-model="detailDialogVisible"
      title="凭证详情"
      width="800px"
      :close-on-click-modal="false"
    >
      <div v-if="currentVoucher" class="voucher-detail">
        <el-descriptions :column="2" border>
          <el-descriptions-item label="凭证号">{{ currentVoucher.voucherNo }}</el-descriptions-item>
          <el-descriptions-item label="交易日期">{{ currentVoucher.transDate }}</el-descriptions-item>
          <el-descriptions-item label="摘要" :span="2">{{ currentVoucher.description }}</el-descriptions-item>
          <el-descriptions-item label="状态">
            <el-tag :type="currentVoucher.status === 1 ? 'success' : 'warning'">
              {{ currentVoucher.status === 1 ? '已审核' : '草稿' }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="录入时间">{{ currentVoucher.enterDate }}</el-descriptions-item>
        </el-descriptions>

        <div class="splits-section">
          <h4>分录明细</h4>
          <el-table :data="currentVoucher.splits" style="width: 100%" :border="true">
            <el-table-column prop="accountId" label="科目ID" width="100" />
            <el-table-column label="借贷" width="100">
              <template #default="scope">
                <el-tag :type="scope.row.direction === 'DEBIT' ? 'primary' : 'success'">
                  {{ scope.row.direction === 'DEBIT' ? '借方' : '贷方' }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="amount" label="金额" width="120">
              <template #default="scope">
                ¥{{ scope.row.amount.toFixed(2) }}
              </template>
            </el-table-column>
            <el-table-column prop="memo" label="摘要" />
          </el-table>
        </div>
      </div>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Search, Refresh, View, Edit, Delete, Check } from '@element-plus/icons-vue'
import { voucherApi } from '@/api/finance'
import type { VoucherQueryDTO, FinTransaction, PageResult } from '@/types/finance'

// 查询表单
const queryForm = reactive<VoucherQueryDTO>({
  voucherNo: '',
  startDate: '',
  endDate: '',
  status: undefined,
  pageNum: 1,
  pageSize: 10
})

// 列表数据
const voucherList = ref<FinTransaction[]>([])
const total = ref(0)
const currentPage = ref(1)
const pageSize = ref(10)
const loading = ref(false)

// 详情对话框
const detailDialogVisible = ref(false)
const currentVoucher = ref<FinTransaction | null>(null)

// 查询凭证
const handleQuery = async () => {
  loading.value = true
  try {
    const params = {
      ...queryForm,
      pageNum: currentPage.value,
      pageSize: pageSize.value
    }
    const res = await voucherApi.queryVouchers(params)
    // 使用可选链和默认值，确保数据安全
    // MyBatis-Plus IPage 结构: { records: [], total: 100, size: 10, current: 1, pages: 10 }
    voucherList.value = res.data?.records || []
    total.value = res.data?.total || 0
  } catch (error) {
    // 错误已在API层面处理
    voucherList.value = []
    total.value = 0
  } finally {
    loading.value = false
  }
}

// 重置查询
const resetQuery = () => {
  Object.assign(queryForm, {
    voucherNo: '',
    startDate: '',
    endDate: '',
    status: undefined,
    pageNum: 1,
    pageSize: 10
  })
  currentPage.value = 1
  handleQuery()
}

// 查看凭证详情
const viewVoucher = async (voucher: FinTransaction) => {
  try {
    const res = await voucherApi.getVoucherById(voucher.transId!)
    currentVoucher.value = res.data
    detailDialogVisible.value = true
  } catch (error) {
    ElMessage.error('获取凭证详情失败')
  }
}

// 编辑凭证
const editVoucher = (voucher: FinTransaction) => {
  // 这里可以跳转到编辑页面，或者在弹窗中编辑
  ElMessage.info('编辑功能开发中...')
}

// 删除凭证
const deleteVoucher = async (voucher: FinTransaction) => {
  try {
    await ElMessageBox.confirm(
      `确定要删除凭证 ${voucher.voucherNo} 吗？此操作不可恢复。`,
      '确认删除',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )

    await voucherApi.deleteVoucher(voucher.transId!)
    ElMessage.success('删除成功')
    handleQuery()
  } catch (error) {
    // 用户取消或API错误
  }
}

// 审核凭证
const auditVoucher = async (voucher: FinTransaction) => {
  try {
    await ElMessageBox.confirm(
      `确定要审核凭证 ${voucher.voucherNo} 吗？审核后将无法修改。`,
      '确认审核',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )

    await voucherApi.auditVoucher(voucher.transId!)
    ElMessage.success('审核成功')
    handleQuery()
  } catch (error) {
    // 用户取消或API错误
  }
}

// 分页大小变化
const handleSizeChange = (val: number) => {
  pageSize.value = val
  currentPage.value = 1
  handleQuery()
}

// 页码变化
const handleCurrentChange = (val: number) => {
  currentPage.value = val
  handleQuery()
}

onMounted(() => {
  handleQuery()
})
</script>

<style scoped>
.query-voucher {
  padding: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.query-form {
  margin-bottom: 30px;
  padding: 20px;
  background-color: #f8f9fa;
  border-radius: 6px;
}

.voucher-table {
  margin-bottom: 20px;
}

.pagination {
  text-align: center;
  margin-top: 20px;
}

.voucher-detail {
  max-height: 600px;
  overflow-y: auto;
}

.splits-section {
  margin-top: 20px;
}

.splits-section h4 {
  margin-bottom: 15px;
  color: #303133;
}

:deep(.el-table th) {
  background-color: #f5f7fa;
  color: #606266;
  font-weight: 600;
}

:deep(.el-descriptions) {
  margin-bottom: 20px;
}

.text-center {
  text-align: center;
}
</style>
