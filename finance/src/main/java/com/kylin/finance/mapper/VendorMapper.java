package com.kylin.finance.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.kylin.finance.entity.business.Vendor;
import org.apache.ibatis.annotations.Mapper;

/**
 * 供应商表数据库访问层
 */
@Mapper
public interface VendorMapper extends BaseMapper<Vendor> {
}

