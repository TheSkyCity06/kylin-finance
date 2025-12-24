package com.kylin.finance.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.kylin.finance.entity.business.Owner;
import org.apache.ibatis.annotations.Mapper;

/**
 * 业务实体表数据库访问层
 */
@Mapper
public interface OwnerMapper extends BaseMapper<Owner> {
}
