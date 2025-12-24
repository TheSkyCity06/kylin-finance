package com.kylin.finance.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.kylin.finance.entity.FinAccount;
import org.apache.ibatis.annotations.Mapper;

/**
 * 会计科目表数据库访问层
 * 负责 fin_account 表的 CRUD
 */
@Mapper
public interface FinAccountMapper extends BaseMapper<FinAccount> {
    // 同样继承了基础的 CRUD 能力
}