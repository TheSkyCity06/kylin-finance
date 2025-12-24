package com.kylin.finance.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.kylin.finance.entity.Commodity;
import org.apache.ibatis.annotations.Mapper;

/**
 * 币种表数据库访问层
 */
@Mapper
public interface CommodityMapper extends BaseMapper<Commodity> {
}

