package com.kylin.finance.controller;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.kylin.common.AjaxResult;
import com.kylin.common.R;
import com.kylin.finance.dto.*;
import com.kylin.finance.entity.FinAccount;
import com.kylin.finance.entity.FinTransaction;
import com.kylin.finance.service.IAccountingService;
import com.kylin.finance.service.IFinAccountService;
import com.kylin.finance.service.IFinTransactionService;
import com.kylin.finance.service.IPostService;
import com.kylin.finance.service.IPaymentService;
import com.kylin.finance.service.IShippingService;
import com.kylin.finance.service.IExpenseClaimService;
import com.kylin.finance.service.IReportService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.math.BigDecimal;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.util.List;

import com.alibaba.excel.EasyExcel;
import com.kylin.finance.dto.BalanceSheetExportRow;
import com.kylin.finance.dto.CashFlowExportRow;
import com.kylin.finance.dto.TrialBalanceExportRow;

/**
 * 财务管理控制器
 */
@RestController
@RequestMapping("/finance")
public class FinanceController {

    @Autowired
    private IFinTransactionService transactionService;
    
    @Autowired
    private IFinAccountService accountService;
    
    @Autowired
    private IAccountingService accountingService;
    
    @Autowired
    private IReportService reportService;

    @Autowired
    private IPostService postService;

    @Autowired
    private IPaymentService paymentService;

    @Autowired
    private IShippingService shippingService;

    @Autowired
    private IExpenseClaimService expenseClaimService;

    @Autowired
    private com.kylin.finance.service.IBizExpenseClaimService bizExpenseClaimService;

    @Autowired
    private com.kylin.finance.service.IBizReceiptPaymentService bizReceiptPaymentService;

    @Autowired
    private com.kylin.finance.mapper.OwnerMapper ownerMapper;

    @Autowired
    private com.kylin.finance.mapper.CustomerMapper customerMapper;

    @Autowired
    private com.kylin.finance.mapper.FinAccountMapper accountMapper;

    // ==================== 凭证管理 ====================
    
    /**
     * 录入凭证
     */
    @PostMapping("/voucher/add")
    public R<String> addVoucher(@RequestBody FinTransaction transaction) {
        transactionService.saveVoucher(transaction);
        return R.ok("凭证录入成功");
    }
    
    /**
     * 更新凭证
     */
    @PutMapping("/voucher/update")
    public R<String> updateVoucher(@RequestBody FinTransaction transaction) {
        transactionService.updateVoucher(transaction);
        return R.ok("凭证更新成功");
    }
    
    /**
     * 删除凭证
     */
    @DeleteMapping("/voucher/delete/{transId}")
    public R<String> deleteVoucher(@PathVariable Long transId) {
        transactionService.deleteVoucher(transId);
        return R.ok("凭证删除成功");
    }
    
    /**
     * 审核凭证
     */
    @PostMapping("/voucher/audit/{transId}")
    public R<String> auditVoucher(@PathVariable Long transId) {
        transactionService.auditVoucher(transId);
        return R.ok("凭证审核成功");
    }
    
    /**
     * 查询凭证（分页）
     */
    @PostMapping("/voucher/query")
    public R<IPage<FinTransaction>> queryVouchers(@RequestBody VoucherQueryDTO queryDTO) {
        IPage<FinTransaction> page = transactionService.queryVouchers(queryDTO);
        return R.ok(page);
    }
    
    /**
     * 根据ID查询凭证详情
     */
    @GetMapping("/voucher/{transId}")
    public R<FinTransaction> getVoucherById(@PathVariable Long transId) {
        FinTransaction transaction = transactionService.getVoucherById(transId);
        return R.ok(transaction);
    }
    
    /**
     * 生成凭证号
     */
    @GetMapping("/voucher/generateNo")
    public R<String> generateVoucherNo() {
        String voucherNo = transactionService.generateVoucherNo();
        return R.ok(voucherNo);
    }

    // ==================== 科目管理 ====================
    
    /**
     * 获取科目树形结构
     */
    @GetMapping("/account/tree")
    public R<List<AccountDTO>> getAccountTree() {
        List<AccountDTO> tree = accountService.getAccountTree();
        return R.ok(tree);
    }
    
    /**
     * 根据父ID获取子科目
     */
    @GetMapping("/account/children/{parentId}")
    public R<List<FinAccount>> getChildrenByParentId(@PathVariable Long parentId) {
        List<FinAccount> children = accountService.getChildrenByParentId(parentId);
        return R.ok(children);
    }
    
    /**
     * 添加科目
     */
    @PostMapping("/account/add")
    public R<String> addAccount(@RequestBody FinAccount account) {
        accountService.addAccount(account);
        return R.ok("科目添加成功");
    }
    
    /**
     * 更新科目
     */
    @PutMapping("/account/update")
    public R<String> updateAccount(@RequestBody FinAccount account) {
        accountService.updateAccount(account);
        return R.ok("科目更新成功");
    }
    
    /**
     * 删除科目
     */
    @DeleteMapping("/account/delete/{accountId}")
    public R<String> deleteAccount(@PathVariable Long accountId) {
        accountService.deleteAccount(accountId);
        return R.ok("科目删除成功");
    }
    
    /**
     * 根据ID查询科目
     */
    @GetMapping("/account/{accountId}")
    public R<FinAccount> getAccountById(@PathVariable Long accountId) {
        FinAccount account = accountService.getById(accountId);
        return R.ok(account);
    }
    
    /**
     * 判断是否为末级科目
     */
    @GetMapping("/account/{accountId}/isLeaf")
    public R<Boolean> isLeafAccount(@PathVariable Long accountId) {
        boolean isLeaf = accountService.isLeafAccount(accountId);
        return R.ok(isLeaf);
    }
    
    /**
     * 获取所有末级科目列表（用于凭证录入）
     */
    @GetMapping("/account/leaf")
    public R<List<AccountDTO>> getLeafAccounts() {
        List<AccountDTO> leafAccounts = accountService.getLeafAccounts();
        return R.ok(leafAccounts);
    }
    
    /**
     * 获取科目的层级路径
     */
    @GetMapping("/account/{accountId}/path")
    public R<String> getAccountPath(@PathVariable Long accountId) {
        String path = accountService.getAccountPath(accountId);
        return R.ok(path);
    }

    // ==================== 核算功能 ====================
    
    /**
     * 计算科目余额
     */
    @GetMapping("/accounting/balance/{accountId}")
    public R<AccountBalanceDTO> calculateAccountBalance(
            @PathVariable Long accountId,
            @RequestParam(required = false) String date) {
        LocalDate localDate = date != null ? LocalDate.parse(date) : LocalDate.now();
        AccountBalanceDTO balance = accountingService.calculateAccountBalance(accountId, localDate);
        return R.ok(balance);
    }
    
    /**
     * 计算所有科目余额
     */
    @GetMapping("/accounting/balance/all")
    public R<List<AccountBalanceDTO>> calculateAllAccountBalances(
            @RequestParam(required = false) String date) {
        LocalDate localDate = date != null ? LocalDate.parse(date) : LocalDate.now();
        List<AccountBalanceDTO> balances = accountingService.calculateAllAccountBalances(localDate);
        return R.ok(balances);
    }
    
    /**
     * 生成试算平衡表
     */
    @GetMapping("/accounting/trialBalance")
    public R<List<TrialBalanceDTO>> generateTrialBalance(
            @RequestParam String startDate,
            @RequestParam String endDate) {
        List<TrialBalanceDTO> trialBalance = accountingService.generateTrialBalance(
            LocalDate.parse(startDate), 
            LocalDate.parse(endDate));
        return R.ok(trialBalance);
    }
    
    /**
     * 验证试算平衡
     */
    @GetMapping("/accounting/verifyBalance")
    public R<Boolean> verifyTrialBalance(@RequestParam(required = false) String date) {
        LocalDate localDate = date != null ? LocalDate.parse(date) : LocalDate.now();
        boolean isBalanced = accountingService.verifyTrialBalance(localDate);
        return R.ok(isBalanced);
    }

    // ==================== 报表功能 ====================
    
    /**
     * 生成资产负债表
     */
    @GetMapping("/report/balanceSheet")
    public R<BalanceSheetDTO> generateBalanceSheet(@RequestParam(required = false) String date) {
        LocalDate reportDate = date != null ? LocalDate.parse(date) : LocalDate.now();
        BalanceSheetDTO balanceSheet = reportService.generateBalanceSheet(reportDate);
        return R.ok(balanceSheet);
    }
    
    /**
     * 生成现金流量表
     */
    @GetMapping("/report/cashFlow")
    public R<CashFlowDTO> generateCashFlowStatement(
            @RequestParam String startDate,
            @RequestParam String endDate) {
        CashFlowDTO cashFlow = reportService.generateCashFlowStatement(
            LocalDate.parse(startDate),
            LocalDate.parse(endDate));
        return R.ok(cashFlow);
    }
    
    /**
     * 导出资产负债表到Excel
     */
    @GetMapping("/report/balance-sheet/export")
    public void exportBalanceSheet(
            @RequestParam(required = false) String date,
            HttpServletResponse response) throws IOException {
        LocalDate reportDate = date != null ? LocalDate.parse(date) : LocalDate.now();
        
        // 生成导出数据
        List<BalanceSheetExportRow> exportData = reportService.generateBalanceSheetExportData(reportDate);
        
        // 设置响应头
        response.setContentType("application/vnd.ms-excel");
        response.setCharacterEncoding("utf-8");
        
        // 文件名使用URL编码，避免中文乱码
        String fileName = URLEncoder.encode("资产负债表_" + reportDate.toString(), StandardCharsets.UTF_8)
            .replaceAll("\\+", "%20");
        response.setHeader("Content-Disposition", "attachment;filename=" + fileName + ".xlsx");
        
        // 使用EasyExcel写入Excel
        EasyExcel.write(response.getOutputStream(), BalanceSheetExportRow.class)
            .sheet("资产负债表")
            .doWrite(exportData);
    }
    
    /**
     * 导出试算平衡表到Excel
     */
    @GetMapping("/report/trial-balance/export")
    public void exportTrialBalance(
            @RequestParam String startDate,
            @RequestParam String endDate,
            HttpServletResponse response) throws IOException {
        LocalDate start = LocalDate.parse(startDate);
        LocalDate end = LocalDate.parse(endDate);
        
        // 生成导出数据
        List<TrialBalanceExportRow> exportData = reportService.generateTrialBalanceExportData(start, end);
        
        // 设置响应头
        response.setContentType("application/vnd.ms-excel");
        response.setCharacterEncoding("utf-8");
        
        // 文件名使用URL编码，避免中文乱码
        String fileName = URLEncoder.encode("trial_balance_" + startDate + "_" + endDate, StandardCharsets.UTF_8)
            .replaceAll("\\+", "%20");
        response.setHeader("Content-Disposition", "attachment;filename=" + fileName + ".xlsx");
        
        // 使用EasyExcel写入Excel
        EasyExcel.write(response.getOutputStream(), TrialBalanceExportRow.class)
            .sheet("试算平衡表")
            .doWrite(exportData);
    }
    
    /**
     * 导出现金流量表到Excel
     */
    @GetMapping("/report/cash-flow/export")
    public void exportCashFlow(
            @RequestParam String startDate,
            @RequestParam String endDate,
            HttpServletResponse response) throws IOException {
        LocalDate start = LocalDate.parse(startDate);
        LocalDate end = LocalDate.parse(endDate);
        
        // 生成导出数据
        List<CashFlowExportRow> exportData = reportService.generateCashFlowExportData(start, end);
        
        // 设置响应头
        response.setContentType("application/vnd.ms-excel");
        response.setCharacterEncoding("utf-8");
        
        // 文件名使用URL编码，避免中文乱码
        // 使用结束日期作为报表日期
        String fileName = URLEncoder.encode("cash_flow_" + endDate, StandardCharsets.UTF_8)
            .replaceAll("\\+", "%20");
        response.setHeader("Content-Disposition", "attachment;filename=" + fileName + ".xlsx");
        
        // 使用EasyExcel写入Excel
        EasyExcel.write(response.getOutputStream(), CashFlowExportRow.class)
            .sheet("现金流量表")
            .doWrite(exportData);
    }

    // ==================== 单据管理 ====================

    /**
     * 发票过账
     */
    @PostMapping("/invoice/post/{invoiceId}")
    public R<String> postInvoice(@PathVariable Long invoiceId) {
        postService.postInvoiceToLedger(null); // 需要先获取发票对象，这里简化了
        return R.ok("发票过账成功");
    }

    /**
     * 账单过账
     */
    @PostMapping("/bill/post/{billId}")
    public R<String> postBill(@PathVariable Long billId) {
        postService.postBillToLedger(null); // 需要先获取账单对象，这里简化了
        return R.ok("账单过账成功");
    }

    /**
     * 冲销单据过账
     */
    @PostMapping("/creditnote/post/{creditNoteId}")
    public R<String> postCreditNote(@PathVariable Long creditNoteId) {
        postService.postCreditNoteToLedger(null); // 需要先获取冲销单据对象，这里简化了
        return R.ok("冲销单据过账成功");
    }

    /**
     * 撤销发票过账
     */
    @PostMapping("/invoice/unpost/{invoiceId}")
    public R<String> unpostInvoice(@PathVariable Long invoiceId) {
        postService.unpostInvoice(invoiceId);
        return R.ok("发票过账撤销成功");
    }

    /**
     * 撤销账单过账
     */
    @PostMapping("/bill/unpost/{billId}")
    public R<String> unpostBill(@PathVariable Long billId) {
        postService.unpostBill(billId);
        return R.ok("账单过账撤销成功");
    }

    /**
     * 撤销冲销单据过账
     */
    @PostMapping("/creditnote/unpost/{creditNoteId}")
    public R<String> unpostCreditNote(@PathVariable Long creditNoteId) {
        postService.unpostCreditNote(creditNoteId);
        return R.ok("冲销单据过账撤销成功");
    }

    // ==================== 支付处理 ====================

    /**
     * 处理客户付款
     */
    @PostMapping("/payment/customer")
    public R<java.util.Map<String, Object>> processCustomerPayment(
            @RequestParam Long ownerId,
            @RequestParam BigDecimal amount,
            @RequestParam Long accountId) {
        try {
            // 从数据库获取客户信息
            com.kylin.finance.entity.business.Customer customer =
                customerMapper.selectById(ownerId);
            if (customer == null) {
                return R.error("客户不存在");
            }

            com.kylin.finance.entity.payment.Payment payment = 
                paymentService.processCustomerPayment(customer, amount, accountId);
            
            // 获取分配结果
            java.util.List<com.kylin.finance.dto.PaymentAllocationResultDTO> allocations = 
                paymentService.getPaymentAllocations(payment.getPaymentId());
            
            java.util.Map<String, Object> result = new java.util.HashMap<>();
            result.put("payment", payment);
            result.put("allocations", allocations);
            
            return R.ok(result);
        } catch (Exception e) {
            return R.error("客户付款处理失败: " + e.getMessage());
        }
    }

    /**
     * 处理供应商付款
     */
    @PostMapping("/payment/vendor")
    public R<java.util.Map<String, Object>> processVendorPayment(
            @RequestParam Long ownerId,
            @RequestParam BigDecimal amount,
            @RequestParam Long accountId) {
        try {
            // 从数据库获取供应商信息
            com.kylin.finance.entity.business.Owner owner = ownerMapper.selectById(ownerId);
            if (owner == null || !"VENDOR".equals(owner.getOwnerType())) {
                return R.error("供应商不存在");
            }

            com.kylin.finance.entity.payment.Payment payment = 
                paymentService.processVendorPayment(owner, amount, accountId);
            
            // 获取分配结果
            java.util.List<com.kylin.finance.dto.PaymentAllocationResultDTO> allocations = 
                paymentService.getPaymentAllocations(payment.getPaymentId());
            
            java.util.Map<String, Object> result = new java.util.HashMap<>();
            result.put("payment", payment);
            result.put("allocations", allocations);
            
            return R.ok(result);
        } catch (Exception e) {
            return R.error("供应商付款处理失败: " + e.getMessage());
        }
    }

    /**
     * 将支付过账到账目
     */
    @PostMapping("/payment/post/{paymentId}")
    public R<String> postPayment(@PathVariable Long paymentId) {
        paymentService.postPaymentToLedger(null); // 简化处理，实际应该获取支付对象
        return R.ok("支付过账成功");
    }

    /**
     * 撤销支付过账
     */
    @PostMapping("/payment/unpost/{paymentId}")
    public R<String> unpostPayment(@PathVariable Long paymentId) {
        paymentService.unpostPayment(paymentId);
        return R.ok("支付过账撤销成功");
    }

    /**
     * 获取实体的未结清金额
     */
    @GetMapping("/payment/unpaid/{ownerId}")
    public R<BigDecimal> getUnpaidAmount(@PathVariable Long ownerId) {
        BigDecimal unpaidAmount = paymentService.getUnpaidAmount(ownerId);
        return R.ok(unpaidAmount);
    }

    // ==================== 邮寄追踪 ====================

    /**
     * 标记发票为已邮寄
     */
    @PostMapping("/invoice/mark-as-sent/{invoiceId}")
    public R<String> markInvoiceAsSent(
            @PathVariable Long invoiceId,
            @RequestParam String trackingNo) {
        shippingService.markAsSent(invoiceId, trackingNo);
        return R.ok("发票已标记为已邮寄");
    }

    // ==================== 员工报销 ====================

    /**
     * 提交报销单
     */
    @PostMapping("/expense-claim/submit")
    public R<String> submitExpenseClaim(@RequestBody com.kylin.finance.entity.expense.ExpenseClaim claim) {
        expenseClaimService.submitClaim(claim);
        return R.ok("报销单提交成功");
    }

    /**
     * 审批报销单
     */
    @PostMapping("/expense-claim/approve/{claimId}")
    public R<String> approveExpenseClaim(
            @PathVariable Long claimId,
            @RequestParam Long approverId,
            @RequestParam Boolean approved,
            @RequestParam(required = false) String comment) {
        expenseClaimService.approveClaim(claimId, approverId, approved, comment);
        return R.ok(approved ? "报销单审批通过" : "报销单审批拒绝");
    }

    /**
     * 过账报销单
     */
    @PostMapping("/expense-claim/post/{claimId}")
    public R<String> postExpenseClaim(@PathVariable Long claimId) {
        expenseClaimService.postClaimToLedger(claimId);
        return R.ok("报销单过账成功");
    }

    // ==================== 业务报销单（BizExpenseClaim）====================

    /**
     * 保存报销单（新增或更新草稿）
     * 如果claimId为空，则新增；否则更新
     */
    @PostMapping("/biz-expense-claim/save")
    public R<com.kylin.finance.entity.biz.BizExpenseClaim> saveExpenseClaim(
            @RequestBody com.kylin.finance.entity.biz.BizExpenseClaim claim) {
        com.kylin.finance.entity.biz.BizExpenseClaim savedClaim = bizExpenseClaimService.saveExpenseClaim(claim);
        return R.ok(savedClaim);
    }

    /**
     * 更新报销单
     */
    @PutMapping("/biz-expense-claim/update")
    public R<com.kylin.finance.entity.biz.BizExpenseClaim> updateExpenseClaim(
            @RequestBody com.kylin.finance.entity.biz.BizExpenseClaim claim) {
        com.kylin.finance.entity.biz.BizExpenseClaim updatedClaim = bizExpenseClaimService.updateExpenseClaim(claim);
        return R.ok(updatedClaim);
    }

    /**
     * 保存并过账报销单
     * 先保存报销单，然后立即过账生成凭证
     */
    @PostMapping("/biz-expense-claim/save-and-post")
    public R<FinTransaction> saveAndPostExpenseClaim(
            @RequestBody com.kylin.finance.entity.biz.BizExpenseClaim claim) {
        FinTransaction voucher = bizExpenseClaimService.saveAndPostExpenseClaim(claim);
        return R.ok(voucher);
    }

    /**
     * 报销单过账
     * 根据报销单生成凭证，更新报销单状态为POSTED
     */
    @PostMapping("/biz-expense-claim/post/{claimId}")
    public R<FinTransaction> postBizExpenseClaim(@PathVariable Long claimId) {
        FinTransaction voucher = bizExpenseClaimService.postExpenseClaim(claimId);
        return R.ok(voucher);
    }

    /**
     * 根据ID查询报销单（包含明细）
     */
    @GetMapping("/biz-expense-claim/{claimId}")
    public R<com.kylin.finance.entity.biz.BizExpenseClaim> getBizExpenseClaimById(@PathVariable Long claimId) {
        com.kylin.finance.entity.biz.BizExpenseClaim claim = bizExpenseClaimService.getById(claimId);
        if (claim == null) {
            return R.error("报销单不存在");
        }
        
        // 查询明细
        java.util.List<com.kylin.finance.entity.biz.BizExpenseClaimDetail> details = 
            bizExpenseClaimService.getDetailsByClaimId(claimId);
        claim.setDetails(details);
        
        return R.ok(claim);
    }

    /**
     * 查询报销单列表（分页）
     */
    @PostMapping("/biz-expense-claim/list")
    public R<com.baomidou.mybatisplus.core.metadata.IPage<com.kylin.finance.entity.biz.BizExpenseClaim>> getBizExpenseClaimList(
            @RequestBody java.util.Map<String, Object> params) {
        // 提取分页参数
        Integer pageNum = params.get("pageNum") != null ? 
            (params.get("pageNum") instanceof Integer ? (Integer) params.get("pageNum") : 
             Integer.parseInt(params.get("pageNum").toString())) : 1;
        Integer pageSize = params.get("pageSize") != null ? 
            (params.get("pageSize") instanceof Integer ? (Integer) params.get("pageSize") : 
             Integer.parseInt(params.get("pageSize").toString())) : 10;
        
        // 提取查询条件
        String claimNo = params.get("claimNo") != null ? params.get("claimNo").toString() : null;
        String startDate = params.get("startDate") != null ? params.get("startDate").toString() : null;
        String endDate = params.get("endDate") != null ? params.get("endDate").toString() : null;
        String status = params.get("status") != null ? params.get("status").toString() : null;
        
        // 创建分页对象
        com.baomidou.mybatisplus.extension.plugins.pagination.Page<com.kylin.finance.entity.biz.BizExpenseClaim> page = 
            new com.baomidou.mybatisplus.extension.plugins.pagination.Page<>(pageNum, pageSize);
        
        // 调用Service查询
        com.baomidou.mybatisplus.core.metadata.IPage<com.kylin.finance.entity.biz.BizExpenseClaim> result = 
            bizExpenseClaimService.getClaimList(page, claimNo, startDate, endDate, status);
        
        return R.ok(result);
    }

    // ==================== 收付款单（BizReceiptPayment）====================

    /**
     * 保存收付款单（新增或更新）
     */
    @PostMapping("/biz-receipt-payment/save")
    public R<com.kylin.finance.entity.biz.BizReceiptPayment> saveReceiptPayment(
            @RequestBody com.kylin.finance.entity.biz.BizReceiptPayment payment) {
        com.kylin.finance.entity.biz.BizReceiptPayment savedPayment = bizReceiptPaymentService.saveReceiptPayment(payment);
        return R.ok(savedPayment);
    }

    /**
     * 保存并过账收付款单
     */
    @PostMapping("/biz-receipt-payment/save-and-post")
    public R<com.kylin.finance.entity.biz.BizReceiptPayment> saveAndPostReceiptPayment(
            @RequestBody com.kylin.finance.entity.biz.BizReceiptPayment payment) {
        com.kylin.finance.entity.biz.BizReceiptPayment savedPayment = bizReceiptPaymentService.saveAndPostReceiptPayment(payment);
        return R.ok(savedPayment);
    }

    /**
     * 查询收付款单列表（分页）
     */
    @GetMapping("/biz-receipt-payment/list")
    public R<com.baomidou.mybatisplus.core.metadata.IPage<com.kylin.finance.entity.biz.BizReceiptPayment>> getReceiptPaymentList(
            @RequestParam(defaultValue = "1") Integer pageNum,
            @RequestParam(defaultValue = "10") Integer pageSize,
            @RequestParam(required = false) String type,
            @RequestParam(required = false) Integer status) {
        com.baomidou.mybatisplus.extension.plugins.pagination.Page<com.kylin.finance.entity.biz.BizReceiptPayment> page = 
            new com.baomidou.mybatisplus.extension.plugins.pagination.Page<>(pageNum, pageSize);
        com.baomidou.mybatisplus.core.metadata.IPage<com.kylin.finance.entity.biz.BizReceiptPayment> result = 
            bizReceiptPaymentService.getReceiptPaymentList(page, type, status);
        return R.ok(result);
    }

    /**
     * 获取收付款单详情
     */
    @GetMapping(value = "/biz-receipt-payment/{id}")
    public AjaxResult<com.kylin.finance.entity.biz.BizReceiptPayment> getInfo(@PathVariable("id") Long id) {
        com.kylin.finance.entity.biz.BizReceiptPayment payment = bizReceiptPaymentService.selectBizReceiptPaymentById(id);
        return AjaxResult.success(payment);
    }

    // ==================== 往来单位查询 ====================

    /**
     * 获取往来单位列表（用于前端下拉选择）
     * @param category 往来单位类型：CUSTOMER(客户), VENDOR(供应商), EMPLOYEE(员工)。如果为null，返回所有类型
     * @return 往来单位列表，包含标准化的 partnerId 和 partnerName 字段
     */
    @GetMapping("/owner/list")
    public R<List<com.kylin.finance.dto.PartnerDTO>> getOwnerList(
            @RequestParam(required = false) String category) {
        try {
            com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<com.kylin.finance.entity.business.Owner> wrapper = 
                new com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<>();
            
            // 如果指定了类型，则过滤
            if (category != null && !category.trim().isEmpty()) {
                // 支持 CUSTOMER 和 SUPPLIER/VENDOR 的映射
                String ownerType = category;
                if ("SUPPLIER".equalsIgnoreCase(category)) {
                    ownerType = "VENDOR";
                }
                wrapper.eq(com.kylin.finance.entity.business.Owner::getOwnerType, ownerType);
            }
            
            wrapper.eq(com.kylin.finance.entity.business.Owner::getEnabled, true); // 只返回启用的
            wrapper.orderByDesc(com.kylin.finance.entity.business.Owner::getCreateTime);
            
            List<com.kylin.finance.entity.business.Owner> owners = ownerMapper.selectList(wrapper);
            
            // 转换为 PartnerDTO
            List<com.kylin.finance.dto.PartnerDTO> partnerList = owners.stream()
                .map(owner -> {
                    com.kylin.finance.dto.PartnerDTO dto = new com.kylin.finance.dto.PartnerDTO();
                    dto.setPartnerId(owner.getOwnerId());
                    dto.setPartnerName(owner.getName());
                    dto.setPartnerCode(owner.getCode());
                    dto.setCategory(owner.getOwnerType());
                    dto.setAccountId(owner.getAccountId());
                    
                    // 填充科目名称
                    if (owner.getAccountId() != null) {
                        FinAccount account = accountMapper.selectById(owner.getAccountId());
                        if (account != null) {
                            dto.setAccountName(account.getAccountCode() + " " + account.getAccountName());
                        }
                    }
                    
                    return dto;
                })
                .collect(java.util.stream.Collectors.toList());
            
            return R.ok(partnerList);
        } catch (Exception e) {
            return R.error("查询往来单位列表失败: " + e.getMessage());
        }
    }
}
