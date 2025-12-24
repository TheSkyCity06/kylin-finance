package com.kylin.finance.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.kylin.finance.entity.document.InvoiceItem;
import org.apache.ibatis.annotations.Mapper;

/**
 * 发票条目表数据库访问层
 */
@Mapper
public interface InvoiceItemMapper extends BaseMapper<InvoiceItem> {
}
