package com.kylin.finance.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.kylin.finance.dto.AccountBalanceSummary;
import com.kylin.finance.entity.FinSplit;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.time.LocalDate;
import java.util.List;

/**
 * 分录表数据库访问层
 * 负责 fin_split 表的 CRUD
 */
@Mapper
public interface FinSplitMapper extends BaseMapper<FinSplit> {
    
    /**
     * 批量查询科目余额（指定日期之前）
     * 使用 SQL 聚合，一次性查询所有科目的借方和贷方合计
     * 
     * @param accountIds 科目ID列表（可为空，为空则查询所有科目）
     * @param endDate 截止日期（包含该日期）
     * @return 科目余额汇总列表
     */
    List<AccountBalanceSummary> selectBalanceByAccountIds(
        @Param("accountIds") List<Long> accountIds,
        @Param("endDate") LocalDate endDate
    );
    
    /**
     * 批量查询科目期间发生额（指定日期范围内）
     * 
     * @param accountIds 科目ID列表（可为空，为空则查询所有科目）
     * @param startDate 开始日期（包含）
     * @param endDate 结束日期（包含）
     * @return 科目发生额汇总列表
     */
    List<AccountBalanceSummary> selectPeriodAmountByAccountIds(
        @Param("accountIds") List<Long> accountIds,
        @Param("startDate") LocalDate startDate,
        @Param("endDate") LocalDate endDate
    );
}