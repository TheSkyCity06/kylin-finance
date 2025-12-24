package com.kylin.finance.service;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.IService;
import com.kylin.finance.dto.VoucherQueryDTO;
import com.kylin.finance.entity.FinTransaction;

import java.util.List;

/**
 * 凭证服务接口
 * 继承 IService<FinTransaction> 后，自动拥有基础的增删改查方法
 */
public interface IFinTransactionService extends IService<FinTransaction> {

    /**
     * 录入凭证（包含借贷平衡校验）
     * @param transaction 包含主表信息和 splits 分录列表
     */
    void saveVoucher(FinTransaction transaction);
    
    /**
     * 更新凭证
     * @param transaction 凭证信息
     */
    void updateVoucher(FinTransaction transaction);
    
    /**
     * 删除凭证
     * @param transId 凭证ID
     */
    void deleteVoucher(Long transId);
    
    /**
     * 审核凭证
     * @param transId 凭证ID
     */
    void auditVoucher(Long transId);
    
    /**
     * 查询凭证（分页）
     * @param queryDTO 查询条件
     */
    IPage<FinTransaction> queryVouchers(VoucherQueryDTO queryDTO);
    
    /**
     * 根据ID查询凭证（包含分录）
     * @param transId 凭证ID
     */
    FinTransaction getVoucherById(Long transId);
    
    /**
     * 生成凭证号
     */
    String generateVoucherNo();
}