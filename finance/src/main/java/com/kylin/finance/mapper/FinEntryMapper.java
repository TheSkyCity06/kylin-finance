package com.kylin.finance.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.kylin.finance.entity.FinEntry;
import org.apache.ibatis.annotations.Mapper;

/**
 * 分录表数据库访问层
 */
@Mapper
public interface FinEntryMapper extends BaseMapper<FinEntry> {
}

