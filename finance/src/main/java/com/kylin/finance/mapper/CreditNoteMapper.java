package com.kylin.finance.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.kylin.finance.entity.document.CreditNote;
import org.apache.ibatis.annotations.Mapper;

/**
 * 冲销单据表数据库访问层
 */
@Mapper
public interface CreditNoteMapper extends BaseMapper<CreditNote> {
}
