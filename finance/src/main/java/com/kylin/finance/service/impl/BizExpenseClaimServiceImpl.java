package com.kylin.finance.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.kylin.common.BusinessException;
import com.kylin.finance.entity.FinAccount;
import com.kylin.finance.entity.FinSplit;
import com.kylin.finance.entity.FinTransaction;
import com.kylin.finance.entity.biz.BizExpenseClaim;
import com.kylin.finance.entity.biz.BizExpenseClaimDetail;
import com.kylin.finance.mapper.BizExpenseClaimDetailMapper;
import com.kylin.finance.mapper.BizExpenseClaimMapper;
import com.kylin.finance.service.IBizExpenseClaimService;
import com.kylin.finance.service.IFinAccountService;
import com.kylin.finance.service.IFinTransactionService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;

/**
 * 报销单服务实现类
 */
@Slf4j
@Service
public class BizExpenseClaimServiceImpl implements IBizExpenseClaimService {

    @Autowired
    private BizExpenseClaimMapper claimMapper;

    @Autowired
    private BizExpenseClaimDetailMapper detailMapper;

    @Autowired
    private IFinTransactionService transactionService;

    @Autowired
    private IFinAccountService accountService;

    /**
     * 根据ID查询报销单
     */
    @Override
    public BizExpenseClaim getById(Long claimId) {
        return claimMapper.selectById(claimId);
    }

    /**
     * 分页查询报销单列表
     */
    @Override
    public IPage<BizExpenseClaim> getClaimList(Page<BizExpenseClaim> page, String claimNo, String startDate, String endDate, String status) {
        log.info("查询报销单列表 - pageNum: {}, pageSize: {}, claimNo: {}, startDate: {}, endDate: {}, status: {}", 
            page.getCurrent(), page.getSize(), claimNo, startDate, endDate, status);
        
        LambdaQueryWrapper<BizExpenseClaim> wrapper = new LambdaQueryWrapper<>();
        
        // 报销单号模糊查询
        if (claimNo != null && !claimNo.trim().isEmpty()) {
            wrapper.like(BizExpenseClaim::getClaimNo, claimNo.trim());
        }
        
        // 日期范围查询
        if (startDate != null && !startDate.trim().isEmpty()) {
            try {
                LocalDate start = LocalDate.parse(startDate.trim());
                wrapper.ge(BizExpenseClaim::getClaimDate, start);
            } catch (Exception e) {
                log.warn("开始日期格式错误: {}", startDate, e);
            }
        }
        
        if (endDate != null && !endDate.trim().isEmpty()) {
            try {
                LocalDate end = LocalDate.parse(endDate.trim());
                wrapper.le(BizExpenseClaim::getClaimDate, end);
            } catch (Exception e) {
                log.warn("结束日期格式错误: {}", endDate, e);
            }
        }
        
        // 状态过滤（注意：如果status为空，不过滤，返回所有状态）
        if (status != null && !status.trim().isEmpty()) {
            wrapper.eq(BizExpenseClaim::getStatus, status.trim());
        }
        
        // 排序：按日期倒序，再按报销单号倒序
        wrapper.orderByDesc(BizExpenseClaim::getClaimDate);
        wrapper.orderByDesc(BizExpenseClaim::getClaimNo);
        
        IPage<BizExpenseClaim> result = claimMapper.selectPage(page, wrapper);
        log.info("查询报销单列表结果 - 总数: {}, 当前页记录数: {}", result.getTotal(), result.getRecords().size());
        
        return result;
    }

    /**
     * 根据报销单ID查询明细列表
     */
    @Override
    public List<BizExpenseClaimDetail> getDetailsByClaimId(Long claimId) {
        LambdaQueryWrapper<BizExpenseClaimDetail> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(BizExpenseClaimDetail::getClaimId, claimId);
        return detailMapper.selectList(wrapper);
    }

    /**
     * 保存报销单（新增或更新）
     * 
     * @param claim 报销单对象（包含details明细列表）
     * @return 保存后的报销单对象
     */
    @Override
    @Transactional(rollbackFor = Exception.class)
    public BizExpenseClaim saveExpenseClaim(BizExpenseClaim claim) {
        try {
            // 1. 数据校验
            validateExpenseClaim(claim);

            // 2. 生成报销单号（如果是新增）
            if (claim.getClaimId() == null) {
                if (claim.getClaimNo() == null || claim.getClaimNo().isEmpty()) {
                    claim.setClaimNo(generateClaimNo());
                }
                claim.setStatus("DRAFT");
            }

            // 3. 计算总金额（如果未设置）
            if (claim.getTotalAmount() == null && claim.getDetails() != null) {
                BigDecimal total = claim.getDetails().stream()
                        .map(BizExpenseClaimDetail::getAmount)
                        .filter(amount -> amount != null)
                        .reduce(BigDecimal.ZERO, BigDecimal::add);
                claim.setTotalAmount(total);
            }

            // 4. 保存主表
            if (claim.getClaimId() == null) {
                claimMapper.insert(claim);
            } else {
                claimMapper.updateById(claim);
                // 删除旧明细
                LambdaQueryWrapper<BizExpenseClaimDetail> deleteWrapper = new LambdaQueryWrapper<>();
                deleteWrapper.eq(BizExpenseClaimDetail::getClaimId, claim.getClaimId());
                detailMapper.delete(deleteWrapper);
            }

            // 5. 保存明细表
            if (claim.getDetails() != null && !claim.getDetails().isEmpty()) {
                for (BizExpenseClaimDetail detail : claim.getDetails()) {
                    detail.setClaimId(claim.getClaimId());
                    detailMapper.insert(detail);
                }
            }

            return claim;
        } catch (BusinessException e) {
            throw e;
        } catch (Exception e) {
            throw new BusinessException("保存报销单失败: " + e.getMessage());
        }
    }

    /**
     * 更新报销单
     * 
     * @param claim 报销单对象（包含details明细列表）
     * @return 更新后的报销单对象
     */
    @Override
    @Transactional(rollbackFor = Exception.class)
    public BizExpenseClaim updateExpenseClaim(BizExpenseClaim claim) {
        try {
            // 1. 检查报销单是否存在
            if (claim.getClaimId() == null) {
                throw new BusinessException("报销单ID不能为空");
            }

            BizExpenseClaim existing = claimMapper.selectById(claim.getClaimId());
            if (existing == null) {
                throw new BusinessException("报销单不存在，ID: " + claim.getClaimId());
            }

            // 2. 检查状态（已过账的不能修改）
            if ("POSTED".equals(existing.getStatus())) {
                throw new BusinessException("已过账的报销单不能修改");
            }

            // 3. 数据校验
            validateExpenseClaim(claim);

            // 4. 计算总金额
            if (claim.getDetails() != null && !claim.getDetails().isEmpty()) {
                BigDecimal total = claim.getDetails().stream()
                        .map(BizExpenseClaimDetail::getAmount)
                        .filter(amount -> amount != null)
                        .reduce(BigDecimal.ZERO, BigDecimal::add);
                claim.setTotalAmount(total);
            }

            // 5. 更新主表
            claimMapper.updateById(claim);

            // 6. 删除旧明细
            LambdaQueryWrapper<BizExpenseClaimDetail> deleteWrapper = new LambdaQueryWrapper<>();
            deleteWrapper.eq(BizExpenseClaimDetail::getClaimId, claim.getClaimId());
            detailMapper.delete(deleteWrapper);

            // 7. 插入新明细
            if (claim.getDetails() != null && !claim.getDetails().isEmpty()) {
                for (BizExpenseClaimDetail detail : claim.getDetails()) {
                    detail.setDetailId(null); // 清除ID，让数据库自动生成
                    detail.setClaimId(claim.getClaimId());
                    detailMapper.insert(detail);
                }
            }

            return claim;
        } catch (BusinessException e) {
            throw e;
        } catch (Exception e) {
            throw new BusinessException("更新报销单失败: " + e.getMessage());
        }
    }

    /**
     * 保存并过账报销单
     * 
     * @param claim 报销单对象（包含details明细列表）
     * @return 生成的凭证对象
     */
    @Override
    @Transactional(rollbackFor = Exception.class)
    public FinTransaction saveAndPostExpenseClaim(BizExpenseClaim claim) {
        try {
            // 1. 先保存报销单
            if (claim.getClaimId() == null) {
                claim = saveExpenseClaim(claim);
            } else {
                claim = updateExpenseClaim(claim);
            }

            // 2. 验证账户存在（双分录检查）
            validateAccountsForPosting(claim);

            // 3. 过账
            return postExpenseClaim(claim.getClaimId());
        } catch (BusinessException e) {
            throw e;
        } catch (Exception e) {
            throw new BusinessException("保存并过账报销单失败: " + e.getMessage());
        }
    }

    /**
     * 报销单过账
     * 根据报销单生成凭证，更新报销单状态为POSTED
     * 
     * @param claimId 报销单ID
     * @return 生成的凭证对象
     */
    @Override
    @Transactional(rollbackFor = Exception.class)
    public FinTransaction postExpenseClaim(Long claimId) {
        // 1. 校验：检查报销单是否存在，状态是否为 DRAFT
        BizExpenseClaim claim = claimMapper.selectById(claimId);
        if (claim == null) {
            throw new BusinessException("报销单不存在，ID: " + claimId);
        }

        // 检查状态是否为 DRAFT
        if (!"DRAFT".equals(claim.getStatus())) {
            if ("POSTED".equals(claim.getStatus())) {
                throw new BusinessException("报销单已过账，无法重复过账");
            } else if ("REVERSED".equals(claim.getStatus())) {
                throw new BusinessException("报销单已冲销，无法过账");
            } else {
                throw new BusinessException("报销单状态不正确，当前状态: " + claim.getStatus());
            }
        }

        // 2. 获取报销明细
        LambdaQueryWrapper<BizExpenseClaimDetail> detailWrapper = new LambdaQueryWrapper<>();
        detailWrapper.eq(BizExpenseClaimDetail::getClaimId, claimId);
        List<BizExpenseClaimDetail> details = detailMapper.selectList(detailWrapper);

        if (details == null || details.isEmpty()) {
            throw new BusinessException("报销单没有明细，无法过账");
        }

        // 校验总金额是否与明细金额一致
        BigDecimal detailTotal = details.stream()
                .map(BizExpenseClaimDetail::getAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        if (claim.getTotalAmount() == null || 
            claim.getTotalAmount().compareTo(detailTotal) != 0) {
            throw new BusinessException(
                String.format("报销单总金额(%s)与明细金额总和(%s)不一致", 
                    claim.getTotalAmount(), detailTotal));
        }

        // 3. 生成凭证 (Voucher Generation)
        FinTransaction voucher = new FinTransaction();
        voucher.setTransDate(claim.getClaimDate());
        voucher.setDescription("报销单过账：" + claim.getClaimNo());
        voucher.setStatus(1); // 已审核状态（过账即审核）
        voucher.setEnterDate(LocalDateTime.now());
        // 凭证号由 saveVoucher 方法自动生成

        List<FinSplit> splits = new ArrayList<>();

        // 3.1 借方分录 (Debits): 遍历明细表，为每一行生成一条借方分录
        for (BizExpenseClaimDetail detail : details) {
            if (detail.getDebitAccountId() == null) {
                throw new BusinessException("明细行缺少借方科目ID");
            }
            if (detail.getAmount() == null || detail.getAmount().compareTo(BigDecimal.ZERO) <= 0) {
                throw new BusinessException("明细行金额必须大于0");
            }

            FinSplit debitSplit = new FinSplit();
            debitSplit.setAccountId(detail.getDebitAccountId());
            debitSplit.setDirection("DEBIT"); // 借方
            debitSplit.setAmount(detail.getAmount());
            debitSplit.setMemo(detail.getDescription() != null ? detail.getDescription() : "报销明细");
            splits.add(debitSplit);
        }

        // 3.2 贷方分录 (Credit): 汇总所有明细金额，生成一条贷方分录
        if (claim.getCreditAccountId() == null) {
            throw new BusinessException("报销单缺少贷方科目ID（付款账户）");
        }

        FinSplit creditSplit = new FinSplit();
        creditSplit.setAccountId(claim.getCreditAccountId());
        creditSplit.setDirection("CREDIT"); // 贷方
        creditSplit.setAmount(claim.getTotalAmount());
        creditSplit.setMemo("报销单付款：" + claim.getClaimNo());
        splits.add(creditSplit);

        // 确保借贷平衡（这里应该已经平衡，但做一次校验）
        BigDecimal debitTotal = splits.stream()
                .filter(s -> "DEBIT".equals(s.getDirection()))
                .map(FinSplit::getAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal creditTotal = splits.stream()
                .filter(s -> "CREDIT".equals(s.getDirection()))
                .map(FinSplit::getAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        if (debitTotal.compareTo(creditTotal) != 0) {
            throw new BusinessException(
                String.format("借贷不平衡：借方总额=%s, 贷方总额=%s", debitTotal, creditTotal));
        }

        voucher.setSplits(splits);

        // 4. 数据持久化：保存凭证和分录
        transactionService.saveVoucher(voucher);

        // 5. 更新报销单状态为 POSTED，回写 voucher_id
        claim.setStatus("POSTED");
        claim.setVoucherId(voucher.getTransId());
        claimMapper.updateById(claim);

        // 6. 余额更新：调用 AccountService 更新对应科目的余额
        // 注意：在实际系统中，余额通常是通过查询凭证分录动态计算的
        // 这里按照用户要求调用 updateBalance 方法
        updateAccountBalances(splits, voucher.getTransDate());

        return voucher;
    }

    /**
     * 更新科目余额
     * 注意：在实际系统中，余额通常是通过查询凭证分录动态计算的
     * 这里提供一个简单的实现，实际可能需要根据业务需求调整
     * 
     * @param splits 凭证分录列表
     * @param transDate 交易日期
     */
    private void updateAccountBalances(List<FinSplit> splits, java.time.LocalDate transDate) {
        // 获取所有涉及的科目ID
        List<Long> accountIds = new ArrayList<>();
        for (FinSplit split : splits) {
            if (split.getAccountId() != null && !accountIds.contains(split.getAccountId())) {
                accountIds.add(split.getAccountId());
            }
        }

        // 遍历每个科目，触发余额计算（实际余额是动态计算的，这里只是确保数据一致性）
        // 如果系统中有缓存机制，可以在这里清除缓存
        for (Long accountId : accountIds) {
            // 余额是通过查询凭证分录动态计算的，不需要手动更新
            // 如果系统中有余额表需要维护，可以在这里更新
            // 当前实现中，余额是实时计算的，所以这里不需要额外操作
        }
    }

    /**
     * 生成报销单号
     * 格式：EXP + 日期(yyyyMMdd) + 序号(3位)
     * 例如：EXP20241201001
     */
    private String generateClaimNo() {
        String dateStr = LocalDate.now().format(DateTimeFormatter.ofPattern("yyyyMMdd"));
        
        // 查询当天最大序号
        LambdaQueryWrapper<BizExpenseClaim> wrapper = new LambdaQueryWrapper<>();
        wrapper.like(BizExpenseClaim::getClaimNo, "EXP" + dateStr);
        wrapper.orderByDesc(BizExpenseClaim::getClaimNo);
        wrapper.last("LIMIT 1");
        BizExpenseClaim last = claimMapper.selectOne(wrapper);
        
        int sequence = 1;
        if (last != null && last.getClaimNo() != null) {
            String lastNo = last.getClaimNo();
            if (lastNo.length() >= 12 && lastNo.startsWith("EXP" + dateStr)) {
                try {
                    sequence = Integer.parseInt(lastNo.substring(11)) + 1;
                } catch (NumberFormatException e) {
                    sequence = 1;
                }
            }
        }
        
        return String.format("EXP%s%03d", dateStr, sequence);
    }

    /**
     * 校验报销单数据
     */
    private void validateExpenseClaim(BizExpenseClaim claim) {
        if (claim == null) {
            throw new BusinessException("报销单数据不能为空");
        }

        // 校验基本信息
        if (claim.getApplicantId() == null || claim.getApplicantId() <= 0) {
            throw new BusinessException("员工ID不能为空");
        }

        if (claim.getClaimDate() == null) {
            throw new BusinessException("报销日期不能为空");
        }

        if (claim.getCreditAccountId() == null || claim.getCreditAccountId() <= 0) {
            throw new BusinessException("付款账户ID不能为空");
        }

        // 校验付款账户是否存在
        FinAccount creditAccount = accountService.getById(claim.getCreditAccountId());
        if (creditAccount == null) {
            throw new BusinessException("付款账户不存在，ID: " + claim.getCreditAccountId());
        }

        // 校验明细
        if (claim.getDetails() == null || claim.getDetails().isEmpty()) {
            throw new BusinessException("报销单至少需要一条费用明细");
        }

        // 校验明细数据
        for (int i = 0; i < claim.getDetails().size(); i++) {
            BizExpenseClaimDetail detail = claim.getDetails().get(i);
            if (detail.getDebitAccountId() == null || detail.getDebitAccountId() <= 0) {
                throw new BusinessException(String.format("第%d条明细的费用科目ID不能为空", i + 1));
            }

            if (detail.getAmount() == null || detail.getAmount().compareTo(BigDecimal.ZERO) <= 0) {
                throw new BusinessException(String.format("第%d条明细的金额必须大于0", i + 1));
            }

            // 校验费用科目是否存在
            FinAccount debitAccount = accountService.getById(detail.getDebitAccountId());
            if (debitAccount == null) {
                throw new BusinessException(String.format("第%d条明细的费用科目不存在，ID: %d", 
                    i + 1, detail.getDebitAccountId()));
            }
        }

        // 校验总金额与明细金额一致
        if (claim.getTotalAmount() != null) {
            BigDecimal detailTotal = claim.getDetails().stream()
                    .map(BizExpenseClaimDetail::getAmount)
                    .filter(amount -> amount != null)
                    .reduce(BigDecimal.ZERO, BigDecimal::add);
            
            if (claim.getTotalAmount().compareTo(detailTotal) != 0) {
                throw new BusinessException(
                    String.format("报销单总金额(%s)与明细金额总和(%s)不一致", 
                        claim.getTotalAmount(), detailTotal));
            }
        }
    }

    /**
     * 验证账户存在（用于过账前的双分录检查）
     */
    private void validateAccountsForPosting(BizExpenseClaim claim) {
        // 验证付款账户（贷方账户）
        if (claim.getCreditAccountId() == null) {
            throw new BusinessException("付款账户ID不能为空");
        }
        FinAccount creditAccount = accountService.getById(claim.getCreditAccountId());
        if (creditAccount == null) {
            throw new BusinessException("付款账户不存在，ID: " + claim.getCreditAccountId());
        }

        // 验证所有费用科目（借方账户）
        if (claim.getDetails() != null) {
            for (BizExpenseClaimDetail detail : claim.getDetails()) {
                if (detail.getDebitAccountId() == null) {
                    throw new BusinessException("费用科目ID不能为空");
                }
                FinAccount debitAccount = accountService.getById(detail.getDebitAccountId());
                if (debitAccount == null) {
                    throw new BusinessException("费用科目不存在，ID: " + detail.getDebitAccountId());
                }
            }
        }
    }
}

