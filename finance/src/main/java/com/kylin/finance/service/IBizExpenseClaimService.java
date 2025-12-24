package com.kylin.finance.service;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.kylin.finance.entity.FinTransaction;
import com.kylin.finance.entity.biz.BizExpenseClaim;
import com.kylin.finance.entity.biz.BizExpenseClaimDetail;

import java.util.List;

/**
 * 报销单服务接口
 */
public interface IBizExpenseClaimService {

    /**
     * 根据ID查询报销单
     * 
     * @param claimId 报销单ID
     * @return 报销单对象
     */
    BizExpenseClaim getById(Long claimId);

    /**
     * 分页查询报销单列表
     * 
     * @param page 分页对象
     * @param claimNo 报销单号（可选）
     * @param startDate 开始日期（可选）
     * @param endDate 结束日期（可选）
     * @param status 状态（可选）
     * @return 分页结果
     */
    IPage<BizExpenseClaim> getClaimList(Page<BizExpenseClaim> page, String claimNo, String startDate, String endDate, String status);

    /**
     * 根据报销单ID查询明细列表
     * 
     * @param claimId 报销单ID
     * @return 明细列表
     */
    List<BizExpenseClaimDetail> getDetailsByClaimId(Long claimId);

    /**
     * 保存报销单（新增或更新）
     * 保存主表和明细表，状态为DRAFT
     * 
     * @param claim 报销单对象（包含details明细列表）
     * @return 保存后的报销单对象（包含生成的ID）
     */
    BizExpenseClaim saveExpenseClaim(BizExpenseClaim claim);

    /**
     * 更新报销单
     * 更新主表和明细表（先删除旧明细，再插入新明细）
     * 
     * @param claim 报销单对象（包含details明细列表）
     * @return 更新后的报销单对象
     */
    BizExpenseClaim updateExpenseClaim(BizExpenseClaim claim);

    /**
     * 保存并过账报销单
     * 先保存报销单，然后立即过账生成凭证
     * 
     * @param claim 报销单对象（包含details明细列表）
     * @return 生成的凭证对象
     */
    FinTransaction saveAndPostExpenseClaim(BizExpenseClaim claim);

    /**
     * 报销单过账
     * 根据报销单生成凭证，更新报销单状态为POSTED
     * 
     * @param claimId 报销单ID
     * @return 生成的凭证对象
     */
    FinTransaction postExpenseClaim(Long claimId);
}

