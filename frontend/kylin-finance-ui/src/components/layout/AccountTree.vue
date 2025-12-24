<template>
  <div class="account-tree-panel">
    <div class="tree-header">
      <span class="tree-title">会计科目</span>
      <el-button
        :icon="isCollapsed ? ArrowRight : ArrowLeft"
        size="small"
        text
        @click="toggleCollapse"
      />
    </div>

    <div v-if="!isCollapsed" class="tree-content">
      <el-input
        v-model="searchText"
        placeholder="搜索科目..."
        size="small"
        clearable
        style="margin-bottom: 8px"
      >
        <template #prefix>
          <el-icon><Search /></el-icon>
        </template>
      </el-input>

      <el-tree
        ref="treeRef"
        :data="filteredTreeData"
        :props="treeProps"
        node-key="accountId"
        :default-expand-all="false"
        :expand-on-click-node="false"
        :highlight-current="true"
        @node-click="handleNodeClick"
        class="account-tree"
      >
        <template #default="{ node, data }">
          <div class="tree-node-content">
            <span class="account-code">{{ data.accountCode }}</span>
            <span class="account-name">{{ data.accountName }}</span>
            <span class="account-balance" :class="getBalanceClass(data)">
              {{ formatBalance(data.balance) }}
            </span>
          </div>
        </template>
      </el-tree>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { ArrowLeft, ArrowRight, Search } from '@element-plus/icons-vue'
import { accountApi, accountingApi } from '@/api/finance'
import { useTabStore } from '@/stores/tabStore'
import type { AccountDTO, AccountBalanceDTO } from '@/types/finance'

const isCollapsed = ref(false)
const searchText = ref('')
const accountTree = ref<AccountDTO[]>([])
const accountBalances = ref<Map<number, AccountBalanceDTO>>(new Map())
const treeRef = ref()

const tabStore = useTabStore()

const treeProps = {
  children: 'children',
  label: 'accountName'
}

// 过滤树数据
const filteredTreeData = computed(() => {
  if (!searchText.value) {
    return accountTree.value
  }

  const filterNode = (nodes: AccountDTO[]): AccountDTO[] => {
    return nodes.filter(node => {
      const match = node.accountName.toLowerCase().includes(searchText.value.toLowerCase()) ||
                   node.accountCode.toLowerCase().includes(searchText.value.toLowerCase())
      
      if (match) {
        return true
      }

      if (node.children && node.children.length > 0) {
        const filteredChildren = filterNode(node.children)
        if (filteredChildren.length > 0) {
          return {
            ...node,
            children: filteredChildren
          }
        }
      }

      return false
    }).map(node => {
      if (node.children && node.children.length > 0) {
        return {
          ...node,
          children: filterNode(node.children)
        }
      }
      return node
    })
  }

  return filterNode(accountTree.value)
})

// 加载科目树
const loadAccountTree = async () => {
  try {
    const response = await accountApi.getAccountTree()
    if (response.code === 200) {
      accountTree.value = response.data || []
      await loadAccountBalances()
    }
  } catch (error) {
    console.error('加载科目树失败:', error)
  }
}

// 加载科目余额
const loadAccountBalances = async () => {
  try {
    const response = await accountingApi.calculateAllAccountBalances()
    if (response.code === 200) {
      const balances = response.data || []
      accountBalances.value.clear()
      balances.forEach((balance: AccountBalanceDTO) => {
        accountBalances.value.set(balance.accountId, balance)
      })
      
      // 更新树数据中的余额
      updateTreeBalances(accountTree.value)
    }
  } catch (error) {
    console.error('加载科目余额失败:', error)
  }
}

// 更新树数据中的余额
const updateTreeBalances = (nodes: AccountDTO[]) => {
  nodes.forEach(node => {
    const balance = accountBalances.value.get(node.accountId!)
    if (balance) {
      node.balance = balance.balance
    }
    // 递归计算子节点余额总和（用于父节点显示）
    if (node.children && node.children.length > 0) {
      updateTreeBalances(node.children)
      // 如果当前节点没有余额，计算子节点余额总和
      if (!node.balance) {
        const childrenBalance = node.children.reduce((sum, child) => {
          return sum + (child.balance || 0)
        }, 0)
        node.balance = childrenBalance
      }
    }
  })
}

// 节点点击处理
const handleNodeClick = (data: AccountDTO) => {
  // 打开科目详情 Tab
  tabStore.addTab({
    id: `account-${data.accountId}`,
    title: `${data.accountCode} ${data.accountName}`,
    path: `/accounts/detail/${data.accountId}`,
    component: 'AccountDetail',
    closable: true
  })
}

// 切换折叠状态
const toggleCollapse = () => {
  isCollapsed.value = !isCollapsed.value
}

// 获取余额样式类
const getBalanceClass = (data: AccountDTO): string => {
  const balance = data.balance || 0
  if (balance > 0) return 'balance-positive'
  if (balance < 0) return 'balance-negative'
  return 'balance-zero'
}

// 格式化余额
const formatBalance = (balance: number | undefined): string => {
  if (balance === undefined || balance === null || balance === 0) {
    return '0.00'
  }
  const absBalance = Math.abs(balance)
  const sign = balance >= 0 ? '' : '-'
  return sign + absBalance.toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, ',')
}

onMounted(() => {
  loadAccountTree()
})
</script>

<style scoped lang="scss">
.account-tree-panel {
  height: 100%;
  display: flex;
  flex-direction: column;
  background-color: #f5f5f5;
  border-right: 1px solid #d0d0d0;

  .tree-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 6px 8px;
    background-color: #e8e8e8;
    border-bottom: 1px solid #d0d0d0;
    font-size: 12px;
    font-weight: 600;
    color: #333;

    .tree-title {
      flex: 1;
    }
  }

  .tree-content {
    flex: 1;
    overflow-y: auto;
    padding: 4px;
  }

  .account-tree {
    font-size: 11px;

    :deep(.el-tree-node__content) {
      height: 22px;
      padding: 0 4px;
    }

    .tree-node-content {
      display: flex;
      align-items: center;
      width: 100%;
      gap: 6px;

      .account-code {
        font-weight: 600;
        color: #409eff;
        min-width: 60px;
        font-size: 10px;
      }

      .account-name {
        flex: 1;
        color: #333;
        font-size: 11px;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
      }

      .account-balance {
        font-size: 10px;
        font-weight: 500;
        min-width: 70px;
        text-align: right;
        font-family: 'Courier New', monospace;

        &.balance-positive {
          color: #67c23a;
        }

        &.balance-negative {
          color: #f56c6c;
        }

        &.balance-zero {
          color: #909399;
        }
      }
    }
  }
}
</style>
