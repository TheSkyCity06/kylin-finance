package com.kylin.finance.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.kylin.finance.entity.document.Invoice;
import org.apache.ibatis.annotations.Mapper;

/**
 * 发票表数据库访问层
 */
@Mapper
public interface InvoiceMapper extends BaseMapper<Invoice> {
}
