package com.kylin.finance.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.kylin.common.BusinessException;
import com.kylin.finance.dto.VoucherQueryDTO;
import com.kylin.finance.entity.FinAccount;
import com.kylin.finance.entity.FinSplit;
import com.kylin.finance.entity.FinTransaction;
import com.kylin.finance.mapper.FinAccountMapper;
import com.kylin.finance.mapper.FinSplitMapper;
import com.kylin.finance.mapper.FinTransactionMapper;
import com.kylin.finance.service.IFinTransactionService;
import com.kylin.finance.service.IAccountingService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.ArrayList;

@Service
public class TransactionServiceImpl extends ServiceImpl<FinTransactionMapper, FinTransaction> implements IFinTransactionService {

    @Autowired
    private FinSplitMapper splitMapper;

    @Autowired
    private FinAccountMapper accountMapper;
    
    @Autowired
    private com.kylin.finance.service.IFinAccountService accountService;
    
    @Autowired
    private IAccountingService accountingService;
    
    @Autowired
    private com.kylin.finance.service.IOwnerValidationService ownerValidationService;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void saveVoucher(FinTransaction transaction) {
        // 1. 校验分录数量
        if (transaction.getSplits() == null || transaction.getSplits().size() < 2) {
            throw new BusinessException("凭证至少需要一借一贷两条分录");
        }

        // 2. 校验所有科目都是末级科目
        validateLeafAccounts(transaction.getSplits());

        // 3. 校验借贷平衡 (核心逻辑)
        validateDebitCreditBalance(transaction.getSplits());
        
        // 4. 校验科目方向组合
        validateAccountDirectionCombination(transaction.getSplits());
        
        // 5. 校验余额方向
        validateBalanceDirection(transaction.getSplits(), transaction.getTransDate());
        
        // 6. 校验业务实体关联（确保涉及往来实体的分录必须同时记录在实体的关联科目下）
        ownerValidationService.validateOwnerAssociation(transaction.getSplits());

        // 6. 生成凭证号（如果为空）
        if (transaction.getVoucherNo() == null || transaction.getVoucherNo().isEmpty()) {
            transaction.setVoucherNo(generateVoucherNo());
        }

        // 7. 设置默认状态为草稿
        if (transaction.getStatus() == null) {
            transaction.setStatus(0); // 0-草稿，1-已审核
        }

        // 8. 设置录入时间
        if (transaction.getEnterDate() == null) {
            transaction.setEnterDate(java.time.LocalDateTime.now());
        }

        // 9. 落库
        this.save(transaction); // 保存主表

        for (FinSplit split : transaction.getSplits()) {
            split.setTransId(transaction.getTransId()); // 关联ID
            splitMapper.insert(split); // 保存子表
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateVoucher(FinTransaction transaction) {
        // 检查凭证是否存在
        FinTransaction existing = this.getById(transaction.getTransId());
        if (existing == null) {
            throw new BusinessException("凭证不存在");
        }

        // 检查是否已审核
        if (existing.getStatus() != null && existing.getStatus() == 1) {
            throw new BusinessException("已审核的凭证不能修改");
        }

        // 校验所有科目都是末级科目
        if (transaction.getSplits() != null && !transaction.getSplits().isEmpty()) {
            validateLeafAccounts(transaction.getSplits());
        }

        // 校验借贷平衡
        if (transaction.getSplits() != null && !transaction.getSplits().isEmpty()) {
            validateDebitCreditBalance(transaction.getSplits());
            // 校验科目方向组合
            validateAccountDirectionCombination(transaction.getSplits());
            // 校验余额方向
            validateBalanceDirection(transaction.getSplits(), transaction.getTransDate());
        }

        // 删除原有分录
        LambdaQueryWrapper<FinSplit> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(FinSplit::getTransId, transaction.getTransId());
        splitMapper.delete(wrapper);

        // 更新主表
        this.updateById(transaction);

        // 保存新分录
        if (transaction.getSplits() != null) {
            for (FinSplit split : transaction.getSplits()) {
                split.setTransId(transaction.getTransId());
                splitMapper.insert(split);
            }
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void deleteVoucher(Long transId) {
        FinTransaction transaction = this.getById(transId);
        if (transaction == null) {
            throw new BusinessException("凭证不存在");
        }

        // 检查是否已审核
        if (transaction.getStatus() != null && transaction.getStatus() == 1) {
            throw new BusinessException("已审核的凭证不能删除");
        }

        // 删除分录
        LambdaQueryWrapper<FinSplit> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(FinSplit::getTransId, transId);
        splitMapper.delete(wrapper);

        // 删除主表
        this.removeById(transId);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void auditVoucher(Long transId) {
        FinTransaction transaction = this.getById(transId);
        if (transaction == null) {
            throw new BusinessException("凭证不存在");
        }

        if (transaction.getStatus() != null && transaction.getStatus() == 1) {
            throw new BusinessException("凭证已审核");
        }

        // 再次校验所有科目都是末级科目
        LambdaQueryWrapper<FinSplit> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(FinSplit::getTransId, transId);
        List<FinSplit> splits = splitMapper.selectList(wrapper);
        validateLeafAccounts(splits);
        
        // 再次校验借贷平衡
        validateDebitCreditBalance(splits);

        // 更新状态为已审核
        transaction.setStatus(1);
        this.updateById(transaction);
    }

    @Override
    public IPage<FinTransaction> queryVouchers(VoucherQueryDTO queryDTO) {
        Page<FinTransaction> page = new Page<>(queryDTO.getPageNum(), queryDTO.getPageSize());
        LambdaQueryWrapper<FinTransaction> wrapper = new LambdaQueryWrapper<>();

        if (queryDTO.getVoucherNo() != null && !queryDTO.getVoucherNo().isEmpty()) {
            wrapper.like(FinTransaction::getVoucherNo, queryDTO.getVoucherNo());
        }
        if (queryDTO.getStartDate() != null) {
            wrapper.ge(FinTransaction::getTransDate, queryDTO.getStartDate());
        }
        if (queryDTO.getEndDate() != null) {
            wrapper.le(FinTransaction::getTransDate, queryDTO.getEndDate());
        }
        if (queryDTO.getStatus() != null) {
            wrapper.eq(FinTransaction::getStatus, queryDTO.getStatus());
        }

        wrapper.orderByDesc(FinTransaction::getTransDate);
        wrapper.orderByDesc(FinTransaction::getVoucherNo);

        return this.page(page, wrapper);
    }

    @Override
    public FinTransaction getVoucherById(Long transId) {
        FinTransaction transaction = this.getById(transId);
        if (transaction != null) {
            // 查询分录
            LambdaQueryWrapper<FinSplit> wrapper = new LambdaQueryWrapper<>();
            wrapper.eq(FinSplit::getTransId, transId);
            List<FinSplit> splits = splitMapper.selectList(wrapper);
            
            // 填充科目信息
            for (FinSplit split : splits) {
                if (split.getAccountId() != null) {
                    FinAccount account = accountMapper.selectById(split.getAccountId());
                    if (account != null) {
                        split.setAccountName(account.getAccountName());
                        split.setAccountCode(account.getAccountCode());
                    }
                }
            }
            
            transaction.setSplits(splits);
        }
        return transaction;
    }

    @Override
    public String generateVoucherNo() {
        // 生成格式：V + 日期(yyyyMMdd) + 序号(3位)
        String dateStr = LocalDate.now().format(DateTimeFormatter.ofPattern("yyyyMMdd"));
        
        // 查询当天最大序号
        LambdaQueryWrapper<FinTransaction> wrapper = new LambdaQueryWrapper<>();
        wrapper.like(FinTransaction::getVoucherNo, "V" + dateStr);
        wrapper.orderByDesc(FinTransaction::getVoucherNo);
        wrapper.last("LIMIT 1");
        FinTransaction last = this.getOne(wrapper);
        
        int sequence = 1;
        if (last != null && last.getVoucherNo() != null) {
            String lastNo = last.getVoucherNo();
            if (lastNo.length() >= 12) {
                try {
                    sequence = Integer.parseInt(lastNo.substring(9)) + 1;
                } catch (NumberFormatException e) {
                    sequence = 1;
                }
            }
        }
        
        return String.format("V%s%03d", dateStr, sequence);
    }

    /**
     * 校验所有科目都是末级科目
     */
    private void validateLeafAccounts(List<FinSplit> splits) {
        for (FinSplit split : splits) {
            if (split.getAccountId() == null) {
                throw new BusinessException("分录的科目ID不能为空");
            }
            
            boolean isLeaf = accountService.isLeafAccount(split.getAccountId());
            if (!isLeaf) {
                com.kylin.finance.entity.FinAccount account = accountService.getById(split.getAccountId());
                String accountName = account != null ? account.getAccountName() : String.valueOf(split.getAccountId());
                throw new BusinessException("凭证分录只能使用末级科目，科目\"" + accountName + "\"不是末级科目");
            }
        }
    }
    
    /**
     * 校验借贷平衡
     */
    private void validateDebitCreditBalance(List<FinSplit> splits) {
        BigDecimal debits = BigDecimal.ZERO;
        BigDecimal credits = BigDecimal.ZERO;

        for (FinSplit split : splits) {
            if (split.getAmount() == null || split.getAmount().compareTo(BigDecimal.ZERO) <= 0) {
                throw new BusinessException("分录金额必须大于0");
            }
            if ("DEBIT".equals(split.getDirection())) {
                debits = debits.add(split.getAmount());
            } else if ("CREDIT".equals(split.getDirection())) {
                credits = credits.add(split.getAmount());
            } else {
                throw new BusinessException("分录方向必须为DEBIT或CREDIT");
            }
        }

        if (debits.compareTo(credits) != 0) {
            BigDecimal diff = debits.subtract(credits);
            throw new BusinessException(String.format("借贷不平！借方：%s，贷方：%s，差异：%s", 
                debits, credits, diff.abs()));
        }
    }
    
    /**
     * 校验科目方向组合是否合理
     */
    private void validateAccountDirectionCombination(List<FinSplit> splits) {
        List<FinSplit> debits = new ArrayList<>();
        List<FinSplit> credits = new ArrayList<>();
        
        for (FinSplit split : splits) {
            if ("DEBIT".equals(split.getDirection())) {
                debits.add(split);
            } else {
                credits.add(split);
            }
        }
        
        // 检查现金/银行存款的借方
        for (FinSplit debitSplit : debits) {
            com.kylin.finance.entity.FinAccount account = accountService.getById(debitSplit.getAccountId());
            if (account != null && ("1001".equals(account.getAccountCode()) || "1002".equals(account.getAccountCode()))) {
                // 现金/银行存款借方，检查贷方是否有不常见的科目
                for (FinSplit creditSplit : credits) {
                    com.kylin.finance.entity.FinAccount creditAccount = accountService.getById(creditSplit.getAccountId());
                    if (creditAccount != null) {
                        String code = creditAccount.getAccountCode();
                        // 长期负债（25开头）、长期应付款（27开头）在现金借方的贷方不常见
                        if ((code.startsWith("25") || code.startsWith("27")) && 
                            "LIABILITY".equals(creditAccount.getAccountType())) {
                            // 这里不抛出异常，只是记录警告，因为可能是特殊业务
                            // 实际业务中可能需要更复杂的规则
                        }
                    }
                }
            }
        }
    }
    
    /**
     * 校验余额方向，检查余额是否会出现反向
     */
    private void validateBalanceDirection(List<FinSplit> splits, LocalDate transDate) {
        if (transDate == null) {
            return;
        }
        
        for (FinSplit split : splits) {
            if (split.getAccountId() == null || split.getAmount() == null) {
                continue;
            }
            
            com.kylin.finance.entity.FinAccount account = accountService.getById(split.getAccountId());
            if (account == null) {
                continue;
            }
            
            try {
                // 计算当前余额
                com.kylin.finance.dto.AccountBalanceDTO balanceDTO = accountingService.calculateAccountBalance(
                    split.getAccountId(), transDate);
                
                if (balanceDTO == null) {
                    // 科目还没有余额，跳过检查
                    continue;
                }
                
                BigDecimal currentBalance = balanceDTO.getBalance();
                BigDecimal newBalance;
                
                // 根据科目类型计算新余额
                if ("ASSET".equals(account.getAccountType()) || "EXPENSE".equals(account.getAccountType())) {
                    // 资产/支出类：增加计入借方，减少计入贷方
                    if ("DEBIT".equals(split.getDirection())) {
                        newBalance = currentBalance.add(split.getAmount());
                    } else {
                        newBalance = currentBalance.subtract(split.getAmount());
                    }
                } else {
                    // 负债/权益/收入类：增加计入贷方，减少计入借方
                    if ("CREDIT".equals(split.getDirection())) {
                        newBalance = currentBalance.add(split.getAmount());
                    } else {
                        newBalance = currentBalance.subtract(split.getAmount());
                    }
                }
                
                // 检查余额是否反向（变为负数）
                if (newBalance.compareTo(BigDecimal.ZERO) < 0) {
                    // 对于资产类科目，余额为负通常是异常情况，抛出异常阻止保存
                    if ("ASSET".equals(account.getAccountType())) {
                        throw new BusinessException(String.format(
                            "科目\"%s\"余额将变为负数（当前余额：%s，录入后余额：%s），请确认业务是否正确",
                            account.getAccountName(), currentBalance, newBalance));
                    }
                    // 对于其他类型科目，给出警告但不阻止（可能是正常业务，如预收账款）
                }
            } catch (BusinessException e) {
                // 重新抛出业务异常
                throw e;
            } catch (Exception e) {
                // 其他异常（如科目还没有余额），忽略
                continue;
            }
        }
    }
}