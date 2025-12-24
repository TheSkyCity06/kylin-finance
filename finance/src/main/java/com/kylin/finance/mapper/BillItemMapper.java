package com.kylin.finance.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.kylin.finance.entity.document.BillItem;
import org.apache.ibatis.annotations.Mapper;

/**
 * 账单条目表数据库访问层
 */
@Mapper
public interface BillItemMapper extends BaseMapper<BillItem> {
}
