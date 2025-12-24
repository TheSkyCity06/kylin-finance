package com.kylin.finance.controller;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.kylin.common.R;
import com.kylin.finance.entity.business.Owner;
import com.kylin.finance.entity.document.Invoice;
import com.kylin.finance.common.DocumentStatus;
import com.kylin.finance.entity.FinAccount;
import com.kylin.finance.mapper.FinAccountMapper;
import com.kylin.finance.mapper.InvoiceMapper;
import com.kylin.finance.mapper.OwnerMapper;
import com.kylin.finance.service.IDocumentStatusService;
import com.kylin.finance.service.IOwnerService;
import com.kylin.finance.service.IPostService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

/**
 * 商业单据管理控制器
 */
@Slf4j
@RestController
@RequestMapping("/finance/document")
public class DocumentController {

    @Autowired
    private InvoiceMapper invoiceMapper;

    @Autowired
    private IPostService postService;

    @Autowired
    private OwnerMapper ownerMapper;
    
    @Autowired
    private IOwnerService ownerService;
    
    @Autowired
    private FinAccountMapper accountMapper;
    
    @Autowired
    private IDocumentStatusService documentStatusService;

    @Autowired
    private com.kylin.finance.mapper.BillMapper billMapper;
    
    @Autowired
    private com.kylin.finance.mapper.InvoiceItemMapper invoiceItemMapper;
    
    @Autowired
    private com.kylin.finance.mapper.BillItemMapper billItemMapper;
    
    // ==================== 业务实体（客户/供应商/员工）管理 ====================
    
    /**
     * 获取业务实体列表（根据类型过滤）
     */
    @GetMapping("/owner/list")
    public R<List<Owner>> getOwnerList(@RequestParam(required = false) String ownerType) {
        try {
            log.info("查询业务实体列表，类型：{}", ownerType);
            List<Owner> owners;
            if (ownerType != null && !ownerType.trim().isEmpty()) {
                owners = ownerService.getOwnersByType(ownerType);
            } else {
                // 查询所有类型，但需要填充科目名称
                owners = ownerService.list();
                // 批量查询科目信息并填充（优化性能）
                java.util.Set<Long> accountIds = owners.stream()
                    .map(Owner::getAccountId)
                    .filter(java.util.Objects::nonNull)
                    .collect(java.util.stream.Collectors.toSet());
                
                if (!accountIds.isEmpty()) {
                    java.util.Map<Long, FinAccount> accountMap = new java.util.HashMap<>();
                    for (Long accountId : accountIds) {
                        FinAccount account = accountMapper.selectById(accountId);
                        if (account != null) {
                            accountMap.put(accountId, account);
                        }
                    }
                    
                    // 填充科目名称
                    for (Owner owner : owners) {
                        if (owner.getAccountId() != null) {
                            FinAccount account = accountMap.get(owner.getAccountId());
                            if (account != null) {
                                owner.setAccountName(account.getAccountCode() + " " + account.getAccountName());
                            }
                        }
                    }
                }
            }
            return R.ok(owners);
        } catch (Exception e) {
            log.error("查询业务实体列表失败", e);
            return R.error("查询业务实体列表失败：" + e.getMessage());
        }
    }
    
    /**
     * 创建业务实体
     */
    @PostMapping("/owner/create")
    public R<Owner> createOwner(@RequestBody Owner owner) {
        try {
            log.info("创建业务实体，类型：{}，名称：{}", owner.getOwnerType(), owner.getName());
            Owner created = ownerService.createOwner(owner);
            return R.ok(created);
        } catch (Exception e) {
            log.error("创建业务实体失败", e);
            return R.error("创建业务实体失败：" + e.getMessage());
        }
    }
    
    /**
     * 更新业务实体
     */
    @PutMapping("/owner/update")
    public R<Owner> updateOwner(@RequestBody Owner owner) {
        try {
            log.info("更新业务实体，ID：{}", owner.getOwnerId());
            Owner updated = ownerService.updateOwner(owner);
            return R.ok(updated);
        } catch (Exception e) {
            log.error("更新业务实体失败", e);
            return R.error("更新业务实体失败：" + e.getMessage());
        }
    }
    
    /**
     * 删除业务实体
     */
    @DeleteMapping("/owner/delete/{ownerId}")
    public R<String> deleteOwner(@PathVariable Long ownerId) {
        try {
            log.info("删除业务实体，ID：{}", ownerId);
            ownerService.deleteOwner(ownerId);
            return R.ok("删除成功");
        } catch (Exception e) {
            log.error("删除业务实体失败", e);
            return R.error("删除业务实体失败：" + e.getMessage());
        }
    }
    
    /**
     * 根据ID查询业务实体
     */
    @GetMapping("/owner/{ownerId}")
    public R<Owner> getOwnerById(@PathVariable Long ownerId) {
        try {
            log.info("查询业务实体，ID：{}", ownerId);
            Owner owner = ownerService.getOwnerById(ownerId);
            return R.ok(owner);
        } catch (Exception e) {
            log.error("查询业务实体失败", e);
            return R.error("查询业务实体失败：" + e.getMessage());
        }
    }

    // ==================== 发票管理 ====================
    
    /**
     * 获取发票列表（分页）
     */
    @GetMapping("/invoice/list")
    public R<IPage<Invoice>> getInvoiceList(
            @RequestParam(defaultValue = "1") Integer pageNum,
            @RequestParam(defaultValue = "10") Integer pageSize) {
        try {
            log.info("查询发票列表，页码：{}，每页大小：{}", pageNum, pageSize);
            Page<Invoice> page = new Page<>(pageNum, pageSize);
            IPage<Invoice> result = invoiceMapper.selectPage(page, null);
            
            // 填充客户名称
            if (result.getRecords() != null && !result.getRecords().isEmpty()) {
                for (Invoice invoice : result.getRecords()) {
                    if (invoice.getCustomerId() != null) {
                        Owner owner = ownerMapper.selectById(invoice.getCustomerId());
                        if (owner != null) {
                            invoice.setCustomerName(owner.getName());
                        }
                    }
                }
            }
            
            return R.ok(result);
        } catch (Exception e) {
            log.error("查询发票列表失败", e);
            return R.error("查询发票列表失败：" + e.getMessage());
        }
    }
    
    /**
     * 创建发票
     */
    @PostMapping("/invoice/create")
    @Transactional(rollbackFor = Exception.class)
    public R<Invoice> createInvoice(@RequestBody Invoice invoice) {
        try {
            log.info("创建发票，编号：{}，客户ID：{}", invoice.getInvoiceNo(), invoice.getCustomerId());
            
            // 校验必填字段
            if (invoice.getInvoiceNo() == null || invoice.getInvoiceNo().trim().isEmpty()) {
                return R.error("发票编号不能为空");
            }
            if (invoice.getCustomerId() == null) {
                return R.error("客户ID不能为空");
            }
            if (invoice.getInvoiceDate() == null) {
                return R.error("发票日期不能为空");
            }
            if (invoice.getTotalAmount() == null) {
                return R.error("发票金额不能为空");
            }
            
            // 校验发票编号唯一性
            LambdaQueryWrapper<Invoice> wrapper = new LambdaQueryWrapper<>();
            wrapper.eq(Invoice::getInvoiceNo, invoice.getInvoiceNo());
            long count = invoiceMapper.selectCount(wrapper);
            if (count > 0) {
                return R.error("发票编号已存在：" + invoice.getInvoiceNo());
            }
            
            // 校验客户是否存在
            Owner customer = ownerMapper.selectById(invoice.getCustomerId());
            if (customer == null || !"CUSTOMER".equals(customer.getOwnerType())) {
                return R.error("客户不存在或类型不正确");
            }
            
            // 设置默认值
            if (invoice.getStatus() == null || invoice.getStatus().trim().isEmpty()) {
                invoice.setStatus(DocumentStatus.DRAFT.getCode());
            }
            if (invoice.getPosted() == null) {
                invoice.setPosted(false);
            }
            
            // 计算不含税金额和税额（如果未提供）
            if (invoice.getNetAmount() == null && invoice.getTaxAmount() == null) {
                invoice.setNetAmount(invoice.getTotalAmount());
                invoice.setTaxAmount(java.math.BigDecimal.ZERO);
            } else if (invoice.getNetAmount() == null) {
                invoice.setNetAmount(invoice.getTotalAmount().subtract(invoice.getTaxAmount()));
            } else if (invoice.getTaxAmount() == null) {
                invoice.setTaxAmount(invoice.getTotalAmount().subtract(invoice.getNetAmount()));
            }
            
            // 保存发票主表
            int result = invoiceMapper.insert(invoice);
            if (result > 0) {
                log.info("发票创建成功，ID：{}", invoice.getInvoiceId());
                
                // 保存发票明细项
                if (invoice.getItems() != null && !invoice.getItems().isEmpty()) {
                    for (com.kylin.finance.entity.document.InvoiceItem item : invoice.getItems()) {
                        item.setInvoiceId(invoice.getInvoiceId());
                        invoiceItemMapper.insert(item);
                    }
                    log.info("发票明细项保存成功，共{}条", invoice.getItems().size());
                }
                
                // 填充客户名称
                invoice.setCustomerName(customer.getName());
                return R.ok(invoice);
            } else {
                return R.error("创建发票失败");
            }
        } catch (Exception e) {
            log.error("创建发票失败", e);
            return R.error("创建发票失败：" + e.getMessage());
        }
    }
    
    /**
     * 更新发票
     */
    @PutMapping("/invoice/update")
    @Transactional(rollbackFor = Exception.class)
    public R<Invoice> updateInvoice(@RequestBody Invoice invoice) {
        try {
            log.info("更新发票，ID：{}", invoice.getInvoiceId());
            
            if (invoice.getInvoiceId() == null) {
                return R.error("发票ID不能为空");
            }
            
            // 检查发票是否存在
            Invoice existing = invoiceMapper.selectById(invoice.getInvoiceId());
            if (existing == null) {
                return R.error("发票不存在，ID：" + invoice.getInvoiceId());
            }
            
            // 状态校验：只有 DRAFT 状态允许更新
            try {
                documentStatusService.checkInvoiceCanUpdate(existing);
            } catch (com.kylin.common.BusinessException e) {
                return R.error(e.getMessage());
            }
            
            // 校验发票编号唯一性（如果修改了编号）
            if (invoice.getInvoiceNo() != null && !invoice.getInvoiceNo().equals(existing.getInvoiceNo())) {
                LambdaQueryWrapper<Invoice> wrapper = new LambdaQueryWrapper<>();
                wrapper.eq(Invoice::getInvoiceNo, invoice.getInvoiceNo());
                wrapper.ne(Invoice::getInvoiceId, invoice.getInvoiceId());
                long count = invoiceMapper.selectCount(wrapper);
                if (count > 0) {
                    return R.error("发票编号已存在：" + invoice.getInvoiceNo());
                }
            }
            
            // 更新主表
            int result = invoiceMapper.updateById(invoice);
            if (result > 0) {
                log.info("发票更新成功，ID：{}", invoice.getInvoiceId());
                
                // 更新明细项：先删除旧的，再插入新的
                if (invoice.getItems() != null) {
                    // 删除旧的明细项
                    com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<com.kylin.finance.entity.document.InvoiceItem> deleteWrapper = 
                        new com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<>();
                    deleteWrapper.eq(com.kylin.finance.entity.document.InvoiceItem::getInvoiceId, invoice.getInvoiceId());
                    invoiceItemMapper.delete(deleteWrapper);
                    
                    // 插入新的明细项
                    for (com.kylin.finance.entity.document.InvoiceItem item : invoice.getItems()) {
                        item.setInvoiceId(invoice.getInvoiceId());
                        invoiceItemMapper.insert(item);
                    }
                    log.info("发票明细项更新成功，共{}条", invoice.getItems().size());
                }
                
                Invoice updated = invoiceMapper.selectById(invoice.getInvoiceId());
                // 填充客户名称
                if (updated.getCustomerId() != null) {
                    Owner customer = ownerMapper.selectById(updated.getCustomerId());
                    if (customer != null) {
                        updated.setCustomerName(customer.getName());
                    }
                }
                
                // 填充明细项
                com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<com.kylin.finance.entity.document.InvoiceItem> itemWrapper = 
                    new com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<>();
                itemWrapper.eq(com.kylin.finance.entity.document.InvoiceItem::getInvoiceId, invoice.getInvoiceId());
                List<com.kylin.finance.entity.document.InvoiceItem> items = invoiceItemMapper.selectList(itemWrapper);
                updated.setItems(items);
                
                return R.ok(updated);
            } else {
                return R.error("更新发票失败");
            }
        } catch (Exception e) {
            log.error("更新发票失败", e);
            return R.error("更新发票失败：" + e.getMessage());
        }
    }
    
    /**
     * 删除发票
     */
    @DeleteMapping("/invoice/delete/{invoiceId}")
    public R<String> deleteInvoice(@PathVariable Long invoiceId) {
        try {
            log.info("删除发票，ID：{}", invoiceId);
            
            Invoice invoice = invoiceMapper.selectById(invoiceId);
            if (invoice == null) {
                return R.error("发票不存在，ID：" + invoiceId);
            }
            
            // 状态校验：只有 DRAFT 状态允许删除
            try {
                documentStatusService.checkInvoiceCanDelete(invoice);
            } catch (com.kylin.common.BusinessException e) {
                return R.error(e.getMessage());
            }
            
            // 逻辑删除（MyBatis-Plus 会自动处理 is_deleted 字段）
            int result = invoiceMapper.deleteById(invoiceId);
            if (result > 0) {
                log.info("发票删除成功，ID：{}", invoiceId);
                return R.ok("删除成功");
            } else {
                return R.error("删除发票失败");
            }
        } catch (Exception e) {
            log.error("删除发票失败", e);
            return R.error("删除发票失败：" + e.getMessage());
        }
    }
    
    /**
     * 根据ID查询发票
     */
    @GetMapping("/invoice/{invoiceId}")
    public R<Invoice> getInvoiceById(@PathVariable Long invoiceId) {
        try {
            log.info("查询发票，ID：{}", invoiceId);
            Invoice invoice = invoiceMapper.selectById(invoiceId);
            if (invoice == null) {
                return R.error("发票不存在，ID：" + invoiceId);
            }
            
            // 填充客户名称
            if (invoice.getCustomerId() != null) {
                Owner customer = ownerMapper.selectById(invoice.getCustomerId());
                if (customer != null) {
                    invoice.setCustomerName(customer.getName());
                }
            }
            
            // 查询发票明细项
            com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<com.kylin.finance.entity.document.InvoiceItem> itemWrapper = 
                new com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<>();
            itemWrapper.eq(com.kylin.finance.entity.document.InvoiceItem::getInvoiceId, invoiceId);
            List<com.kylin.finance.entity.document.InvoiceItem> items = invoiceItemMapper.selectList(itemWrapper);
            invoice.setItems(items);
            
            return R.ok(invoice);
        } catch (Exception e) {
            log.error("查询发票失败", e);
            return R.error("查询发票失败：" + e.getMessage());
        }
    }

    /**
     * 审核发票（DRAFT -> VALIDATED）
     */
    @PostMapping("/invoice/validate/{invoiceId}")
    public R<String> validateInvoice(@PathVariable Long invoiceId) {
        try {
            log.info("审核发票，ID：{}", invoiceId);
            Invoice invoice = invoiceMapper.selectById(invoiceId);
            if (invoice == null) {
                return R.error("发票不存在，ID：" + invoiceId);
            }
            
            documentStatusService.validateInvoice(invoice);
            return R.ok("审核成功");
        } catch (Exception e) {
            log.error("审核发票失败", e);
            return R.error("审核失败：" + e.getMessage());
        }
    }
    
    /**
     * 作废发票（任何状态 -> CANCELLED）
     * 如果已过账，需要生成红冲凭证
     */
    @PostMapping("/invoice/cancel/{invoiceId}")
    public R<String> cancelInvoice(@PathVariable Long invoiceId) {
        try {
            log.info("作废发票，ID：{}", invoiceId);
            Invoice invoice = invoiceMapper.selectById(invoiceId);
            if (invoice == null) {
                return R.error("发票不存在，ID：" + invoiceId);
            }
            
            DocumentStatus currentStatus = DocumentStatus.fromCode(invoice.getStatus());
            
            // 如果已过账，需要先生成红冲凭证
            if (currentStatus == DocumentStatus.POSTED && invoice.getPosted() != null && invoice.getPosted()) {
                log.info("发票已过账，生成红冲凭证，发票ID：{}", invoiceId);
                postService.reverseInvoicePosting(invoice);
            }
            
            documentStatusService.cancelInvoice(invoice);
            return R.ok("作废成功");
        } catch (Exception e) {
            log.error("作废发票失败", e);
            return R.error("作废失败：" + e.getMessage());
        }
    }
    
    /**
     * 过账发票（VALIDATED -> POSTED）
     */
    @PostMapping("/invoice/post/{invoiceId}")
    public R<String> postInvoice(@PathVariable Long invoiceId) {
        try {
            log.info("过账发票，ID：{}", invoiceId);
            Invoice invoice = invoiceMapper.selectById(invoiceId);
            if (invoice == null) {
                return R.error("发票不存在，ID：" + invoiceId);
            }

            postService.postInvoiceToLedger(invoice);
            log.info("发票过账成功，ID：{}", invoiceId);
            return R.ok("过账成功");
        } catch (Exception e) {
            log.error("过账发票失败", e);
            return R.error("过账失败：" + e.getMessage());
        }
    }

    /**
     * 获取客户的未结清发票列表
     */
    @GetMapping("/invoice/unpaid/{customerId}")
    public R<List<Invoice>> getUnpaidInvoices(@PathVariable Long customerId) {
        com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<Invoice> wrapper =
            new com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<>();
        wrapper.eq(Invoice::getCustomerId, customerId)
               .in(Invoice::getStatus, "OPEN", "PARTIAL")
               .orderByAsc(Invoice::getCreateTime);
        
        List<Invoice> invoices = invoiceMapper.selectList(wrapper);
        
        // 填充客户名称
        for (Invoice invoice : invoices) {
            if (invoice.getCustomerId() != null) {
                Owner owner = ownerMapper.selectById(invoice.getCustomerId());
                if (owner != null) {
                    invoice.setCustomerName(owner.getName());
                }
            }
        }
        
        return R.ok(invoices);
    }

    // ==================== 账单管理 ====================
    
    /**
     * 获取账单列表（分页）
     */
    @GetMapping("/bill/list")
    public R<IPage<com.kylin.finance.entity.document.Bill>> getBillList(
            @RequestParam(defaultValue = "1") Integer pageNum,
            @RequestParam(defaultValue = "10") Integer pageSize) {
        try {
            log.info("查询账单列表，页码：{}，每页大小：{}", pageNum, pageSize);
            Page<com.kylin.finance.entity.document.Bill> page = new Page<>(pageNum, pageSize);
            IPage<com.kylin.finance.entity.document.Bill> result = billMapper.selectPage(page, null);
            
            // 填充供应商名称
            if (result.getRecords() != null && !result.getRecords().isEmpty()) {
                for (com.kylin.finance.entity.document.Bill bill : result.getRecords()) {
                    if (bill.getVendorId() != null) {
                        Owner vendor = ownerMapper.selectById(bill.getVendorId());
                        if (vendor != null) {
                            bill.setVendorName(vendor.getName());
                        }
                    }
                }
            }
            
            return R.ok(result);
        } catch (Exception e) {
            log.error("查询账单列表失败", e);
            return R.error("查询账单列表失败：" + e.getMessage());
        }
    }
    
    /**
     * 创建账单
     */
    @PostMapping("/bill/create")
    @Transactional(rollbackFor = Exception.class)
    public R<com.kylin.finance.entity.document.Bill> createBill(@RequestBody com.kylin.finance.entity.document.Bill bill) {
        try {
            log.info("创建账单，编号：{}，供应商ID：{}", bill.getBillNo(), bill.getVendorId());
            
            // 校验必填字段
            if (bill.getBillNo() == null || bill.getBillNo().trim().isEmpty()) {
                return R.error("账单编号不能为空");
            }
            if (bill.getVendorId() == null) {
                return R.error("供应商ID不能为空");
            }
            if (bill.getBillDate() == null) {
                return R.error("账单日期不能为空");
            }
            if (bill.getTotalAmount() == null) {
                return R.error("账单金额不能为空");
            }
            
            // 校验账单编号唯一性
            LambdaQueryWrapper<com.kylin.finance.entity.document.Bill> wrapper = new LambdaQueryWrapper<>();
            wrapper.eq(com.kylin.finance.entity.document.Bill::getBillNo, bill.getBillNo());
            long count = billMapper.selectCount(wrapper);
            if (count > 0) {
                return R.error("账单编号已存在：" + bill.getBillNo());
            }
            
            // 校验供应商是否存在
            Owner vendor = ownerMapper.selectById(bill.getVendorId());
            if (vendor == null || !"VENDOR".equals(vendor.getOwnerType())) {
                return R.error("供应商不存在或类型不正确");
            }
            
            // 设置默认值
            if (bill.getStatus() == null || bill.getStatus().trim().isEmpty()) {
                bill.setStatus(DocumentStatus.DRAFT.getCode());
            }
            if (bill.getPosted() == null) {
                bill.setPosted(false);
            }
            
            // 计算不含税金额和税额（如果未提供）
            if (bill.getNetAmount() == null && bill.getTaxAmount() == null) {
                bill.setNetAmount(bill.getTotalAmount());
                bill.setTaxAmount(java.math.BigDecimal.ZERO);
            } else if (bill.getNetAmount() == null) {
                bill.setNetAmount(bill.getTotalAmount().subtract(bill.getTaxAmount()));
            } else if (bill.getTaxAmount() == null) {
                bill.setTaxAmount(bill.getTotalAmount().subtract(bill.getNetAmount()));
            }
            
            // 保存账单主表
            int result = billMapper.insert(bill);
            if (result > 0) {
                log.info("账单创建成功，ID：{}", bill.getBillId());
                
                // 保存账单明细项
                if (bill.getItems() != null && !bill.getItems().isEmpty()) {
                    for (com.kylin.finance.entity.document.BillItem item : bill.getItems()) {
                        item.setBillId(bill.getBillId());
                        billItemMapper.insert(item);
                    }
                    log.info("账单明细项保存成功，共{}条", bill.getItems().size());
                }
                
                // 填充供应商名称
                bill.setVendorName(vendor.getName());
                return R.ok(bill);
            } else {
                return R.error("创建账单失败");
            }
        } catch (Exception e) {
            log.error("创建账单失败", e);
            return R.error("创建账单失败：" + e.getMessage());
        }
    }
    
    /**
     * 更新账单
     */
    @PutMapping("/bill/update")
    @Transactional(rollbackFor = Exception.class)
    public R<com.kylin.finance.entity.document.Bill> updateBill(@RequestBody com.kylin.finance.entity.document.Bill bill) {
        try {
            log.info("更新账单，ID：{}", bill.getBillId());
            
            if (bill.getBillId() == null) {
                return R.error("账单ID不能为空");
            }
            
            // 检查账单是否存在
            com.kylin.finance.entity.document.Bill existing = billMapper.selectById(bill.getBillId());
            if (existing == null) {
                return R.error("账单不存在，ID：" + bill.getBillId());
            }
            
            // 状态校验：只有 DRAFT 状态允许更新
            try {
                documentStatusService.checkBillCanUpdate(existing);
            } catch (com.kylin.common.BusinessException e) {
                return R.error(e.getMessage());
            }
            
            // 校验账单编号唯一性（如果修改了编号）
            if (bill.getBillNo() != null && !bill.getBillNo().equals(existing.getBillNo())) {
                LambdaQueryWrapper<com.kylin.finance.entity.document.Bill> wrapper = new LambdaQueryWrapper<>();
                wrapper.eq(com.kylin.finance.entity.document.Bill::getBillNo, bill.getBillNo());
                wrapper.ne(com.kylin.finance.entity.document.Bill::getBillId, bill.getBillId());
                long count = billMapper.selectCount(wrapper);
                if (count > 0) {
                    return R.error("账单编号已存在：" + bill.getBillNo());
                }
            }
            
            // 更新主表
            int result = billMapper.updateById(bill);
            if (result > 0) {
                log.info("账单更新成功，ID：{}", bill.getBillId());
                
                // 更新明细项：先删除旧的，再插入新的
                if (bill.getItems() != null) {
                    // 删除旧的明细项
                    com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<com.kylin.finance.entity.document.BillItem> deleteWrapper = 
                        new com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<>();
                    deleteWrapper.eq(com.kylin.finance.entity.document.BillItem::getBillId, bill.getBillId());
                    billItemMapper.delete(deleteWrapper);
                    
                    // 插入新的明细项
                    for (com.kylin.finance.entity.document.BillItem item : bill.getItems()) {
                        item.setBillId(bill.getBillId());
                        billItemMapper.insert(item);
                    }
                    log.info("账单明细项更新成功，共{}条", bill.getItems().size());
                }
                
                com.kylin.finance.entity.document.Bill updated = billMapper.selectById(bill.getBillId());
                // 填充供应商名称
                if (updated.getVendorId() != null) {
                    Owner vendor = ownerMapper.selectById(updated.getVendorId());
                    if (vendor != null) {
                        updated.setVendorName(vendor.getName());
                    }
                }
                
                // 填充明细项
                com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<com.kylin.finance.entity.document.BillItem> itemWrapper = 
                    new com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<>();
                itemWrapper.eq(com.kylin.finance.entity.document.BillItem::getBillId, bill.getBillId());
                List<com.kylin.finance.entity.document.BillItem> items = billItemMapper.selectList(itemWrapper);
                updated.setItems(items);
                
                return R.ok(updated);
            } else {
                return R.error("更新账单失败");
            }
        } catch (Exception e) {
            log.error("更新账单失败", e);
            return R.error("更新账单失败：" + e.getMessage());
        }
    }
    
    /**
     * 删除账单
     */
    @DeleteMapping("/bill/delete/{billId}")
    public R<String> deleteBill(@PathVariable Long billId) {
        try {
            log.info("删除账单，ID：{}", billId);
            
            com.kylin.finance.entity.document.Bill bill = billMapper.selectById(billId);
            if (bill == null) {
                return R.error("账单不存在，ID：" + billId);
            }
            
            // 状态校验：只有 DRAFT 状态允许删除
            try {
                documentStatusService.checkBillCanDelete(bill);
            } catch (com.kylin.common.BusinessException e) {
                return R.error(e.getMessage());
            }
            
            // 逻辑删除（MyBatis-Plus 会自动处理 is_deleted 字段）
            int result = billMapper.deleteById(billId);
            if (result > 0) {
                log.info("账单删除成功，ID：{}", billId);
                return R.ok("删除成功");
            } else {
                return R.error("删除账单失败");
            }
        } catch (Exception e) {
            log.error("删除账单失败", e);
            return R.error("删除账单失败：" + e.getMessage());
        }
    }
    
    /**
     * 根据ID查询账单
     */
    @GetMapping("/bill/{billId}")
    public R<com.kylin.finance.entity.document.Bill> getBillById(@PathVariable Long billId) {
        try {
            log.info("查询账单，ID：{}", billId);
            com.kylin.finance.entity.document.Bill bill = billMapper.selectById(billId);
            if (bill == null) {
                return R.error("账单不存在，ID：" + billId);
            }
            
            // 填充供应商名称
            if (bill.getVendorId() != null) {
                Owner vendor = ownerMapper.selectById(bill.getVendorId());
                if (vendor != null) {
                    bill.setVendorName(vendor.getName());
                }
            }
            
            // 查询账单明细项
            com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<com.kylin.finance.entity.document.BillItem> itemWrapper = 
                new com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<>();
            itemWrapper.eq(com.kylin.finance.entity.document.BillItem::getBillId, billId);
            List<com.kylin.finance.entity.document.BillItem> items = billItemMapper.selectList(itemWrapper);
            bill.setItems(items);
            
            return R.ok(bill);
        } catch (Exception e) {
            log.error("查询账单失败", e);
            return R.error("查询账单失败：" + e.getMessage());
        }
    }
    
    /**
     * 审核账单（DRAFT -> VALIDATED）
     */
    @PostMapping("/bill/validate/{billId}")
    public R<String> validateBill(@PathVariable Long billId) {
        try {
            log.info("审核账单，ID：{}", billId);
            com.kylin.finance.entity.document.Bill bill = billMapper.selectById(billId);
            if (bill == null) {
                return R.error("账单不存在，ID：" + billId);
            }
            
            documentStatusService.validateBill(bill);
            return R.ok("审核成功");
        } catch (Exception e) {
            log.error("审核账单失败", e);
            return R.error("审核失败：" + e.getMessage());
        }
    }
    
    /**
     * 作废账单（任何状态 -> CANCELLED）
     * 如果已过账，需要生成红冲凭证
     */
    @PostMapping("/bill/cancel/{billId}")
    public R<String> cancelBill(@PathVariable Long billId) {
        try {
            log.info("作废账单，ID：{}", billId);
            com.kylin.finance.entity.document.Bill bill = billMapper.selectById(billId);
            if (bill == null) {
                return R.error("账单不存在，ID：" + billId);
            }
            
            DocumentStatus currentStatus = DocumentStatus.fromCode(bill.getStatus());
            
            // 如果已过账，需要先生成红冲凭证
            if (currentStatus == DocumentStatus.POSTED && bill.getPosted() != null && bill.getPosted()) {
                log.info("账单已过账，生成红冲凭证，账单ID：{}", billId);
                postService.reverseBillPosting(bill);
            }
            
            documentStatusService.cancelBill(bill);
            return R.ok("作废成功");
        } catch (Exception e) {
            log.error("作废账单失败", e);
            return R.error("作废失败：" + e.getMessage());
        }
    }
    
    /**
     * 过账账单（VALIDATED -> POSTED）
     */
    @PostMapping("/bill/post/{billId}")
    public R<String> postBill(@PathVariable Long billId) {
        try {
            log.info("过账账单，ID：{}", billId);
            com.kylin.finance.entity.document.Bill bill = billMapper.selectById(billId);
            if (bill == null) {
                return R.error("账单不存在，ID：" + billId);
            }

            postService.postBillToLedger(bill);
            log.info("账单过账成功，ID：{}", billId);
            return R.ok("过账成功");
        } catch (Exception e) {
            log.error("过账账单失败", e);
            return R.error("过账失败：" + e.getMessage());
        }
    }
    
    /**
     * 获取供应商的未结清账单列表
     */
    @GetMapping("/bill/unpaid/{vendorId}")
    public R<List<com.kylin.finance.entity.document.Bill>> getUnpaidBills(@PathVariable Long vendorId) {
        try {
            log.info("查询供应商未结清账单，供应商ID：{}", vendorId);
            LambdaQueryWrapper<com.kylin.finance.entity.document.Bill> wrapper = new LambdaQueryWrapper<>();
            wrapper.eq(com.kylin.finance.entity.document.Bill::getVendorId, vendorId)
                   .in(com.kylin.finance.entity.document.Bill::getStatus, 
                       DocumentStatus.VALIDATED.getCode(), DocumentStatus.POSTED.getCode())
                   .orderByAsc(com.kylin.finance.entity.document.Bill::getCreateTime);
            
            List<com.kylin.finance.entity.document.Bill> bills = billMapper.selectList(wrapper);
            
            // 填充供应商名称
            for (com.kylin.finance.entity.document.Bill bill : bills) {
                if (bill.getVendorId() != null) {
                    Owner vendor = ownerMapper.selectById(bill.getVendorId());
                    if (vendor != null) {
                        bill.setVendorName(vendor.getName());
                    }
                }
            }
            
            return R.ok(bills);
        } catch (Exception e) {
            log.error("查询供应商未结清账单失败", e);
            return R.error("查询供应商未结清账单失败：" + e.getMessage());
        }
    }
}
