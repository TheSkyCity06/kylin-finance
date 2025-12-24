package com.kylin.finance.mapper;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.kylin.finance.entity.FinTransaction;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface FinTransactionMapper extends BaseMapper<FinTransaction> {}
