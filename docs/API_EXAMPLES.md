# API使用示例

本文档提供了财务管理系统主要API的使用示例。

## 1. 凭证管理

### 1.1 录入凭证

**请求示例：**
```bash
curl -X POST http://localhost:8080/finance/voucher/add \
  -H "Content-Type: application/json" \
  -d '{
    "transDate": "2024-12-01",
    "description": "购买办公用品",
    "splits": [
      {
        "accountId": 1,
        "direction": "DEBIT",
        "amount": 1000.00,
        "memo": "管理费用-办公费"
      },
      {
        "accountId": 2,
        "direction": "CREDIT",
        "amount": 1000.00,
        "memo": "银行存款"
      }
    ]
  }'
```

**响应示例：**
```json
{
  "code": 200,
  "msg": "操作成功",
  "data": "凭证录入成功"
}
```

### 1.2 查询凭证列表

**请求示例：**
```bash
curl -X POST http://localhost:8080/finance/voucher/query \
  -H "Content-Type: application/json" \
  -d '{
    "startDate": "2024-12-01",
    "endDate": "2024-12-31",
    "status": 1,
    "pageNum": 1,
    "pageSize": 10
  }'
```

**响应示例：**
```json
{
  "code": 200,
  "msg": "操作成功",
  "data": {
    "records": [
      {
        "transId": 1,
        "voucherNo": "V20241201001",
        "transDate": "2024-12-01",
        "description": "购买办公用品",
        "status": 1,
        "splits": [
          {
            "splitId": 1,
            "accountId": 1,
            "direction": "DEBIT",
            "amount": 1000.00,
            "memo": "管理费用-办公费"
          },
          {
            "splitId": 2,
            "accountId": 2,
            "direction": "CREDIT",
            "amount": 1000.00,
            "memo": "银行存款"
          }
        ]
      }
    ],
    "total": 1,
    "size": 10,
    "current": 1,
    "pages": 1
  }
}
```

### 1.3 审核凭证

**请求示例：**
```bash
curl -X POST http://localhost:8080/finance/voucher/audit/1
```

## 2. 科目管理

### 2.1 获取科目树

**请求示例：**
```bash
curl -X GET http://localhost:8080/finance/account/tree
```

**响应示例：**
```json
{
  "code": 200,
  "msg": "操作成功",
  "data": [
    {
      "accountId": 1,
      "accountCode": "1001",
      "accountName": "库存现金",
      "accountType": "ASSET",
      "parentId": null,
      "children": []
    },
    {
      "accountId": 2,
      "accountCode": "1002",
      "accountName": "银行存款",
      "accountType": "ASSET",
      "parentId": null,
      "children": []
    }
  ]
}
```

### 2.2 添加科目

**请求示例：**
```bash
curl -X POST http://localhost:8080/finance/account/add \
  -H "Content-Type: application/json" \
  -d '{
    "accountCode": "100101",
    "accountName": "人民币",
    "accountType": "ASSET",
    "parentId": 1
  }'
```

## 3. 核算功能

### 3.1 计算科目余额

**请求示例：**
```bash
curl -X GET "http://localhost:8080/finance/accounting/balance/1?date=2024-12-31"
```

**响应示例：**
```json
{
  "code": 200,
  "msg": "操作成功",
  "data": {
    "accountId": 1,
    "accountCode": "1001",
    "accountName": "库存现金",
    "accountType": "ASSET",
    "debitBalance": 5000.00,
    "creditBalance": 2000.00,
    "balance": 3000.00
  }
}
```

### 3.2 生成试算平衡表

**请求示例：**
```bash
curl -X GET "http://localhost:8080/finance/accounting/trialBalance?startDate=2024-12-01&endDate=2024-12-31"
```

**响应示例：**
```json
{
  "code": 200,
  "msg": "操作成功",
  "data": [
    {
      "accountId": 1,
      "accountCode": "1001",
      "accountName": "库存现金",
      "accountType": "ASSET",
      "periodBeginDebit": 2000.00,
      "periodBeginCredit": 0.00,
      "periodDebit": 5000.00,
      "periodCredit": 2000.00,
      "periodEndDebit": 5000.00,
      "periodEndCredit": 0.00
    }
  ]
}
```

## 4. 财务报表

### 4.1 生成资产负债表

**请求示例：**
```bash
curl -X GET "http://localhost:8080/finance/report/balanceSheet?date=2024-12-31"
```

**响应示例：**
```json
{
  "code": 200,
  "msg": "操作成功",
  "data": {
    "reportDate": "2024-12-31",
    "assets": [
      {
        "accountCode": "1001",
        "accountName": "库存现金",
        "amount": 3000.00,
        "children": []
      }
    ],
    "totalAssets": 100000.00,
    "liabilities": [
      {
        "accountCode": "2001",
        "accountName": "短期借款",
        "amount": 50000.00,
        "children": []
      }
    ],
    "totalLiabilities": 50000.00,
    "equity": [
      {
        "accountCode": "4001",
        "accountName": "实收资本",
        "amount": 50000.00,
        "children": []
      }
    ],
    "totalEquity": 50000.00,
    "totalLiabilitiesAndEquity": 100000.00
  }
}
```

### 4.2 生成现金流量表

**请求示例：**
```bash
curl -X GET "http://localhost:8080/finance/report/cashFlow?startDate=2024-12-01&endDate=2024-12-31"
```

**响应示例：**
```json
{
  "code": 200,
  "msg": "操作成功",
  "data": {
    "reportDate": "2024-12-31",
    "operatingActivities": [
      {
        "itemName": "销售商品、提供劳务收到的现金",
        "amount": 100000.00,
        "description": "销售收入"
      }
    ],
    "netOperatingCashFlow": 80000.00,
    "investingActivities": [],
    "netInvestingCashFlow": 0.00,
    "financingActivities": [],
    "netFinancingCashFlow": 0.00,
    "netIncreaseInCash": 80000.00,
    "beginningCashBalance": 20000.00,
    "endingCashBalance": 100000.00
  }
}
```

## 5. 错误处理

当发生错误时，API会返回错误信息：

**错误响应示例：**
```json
{
  "code": 500,
  "msg": "借贷不平！借方：1000.00，贷方：800.00",
  "data": null
}
```

常见错误：
- `借贷不平！` - 凭证借贷金额不相等
- `凭证至少需要一借一贷两条分录` - 分录数量不足
- `科目代码已存在` - 科目代码重复
- `该科目下存在子科目，无法删除` - 删除科目前需先删除子科目
- `该科目已被使用，无法删除` - 科目已被凭证使用
- `已审核的凭证不能修改` - 凭证已审核，无法修改
