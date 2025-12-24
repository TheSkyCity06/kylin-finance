package com.kylin.admin.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.kylin.admin.entity.SysUser;
import org.apache.ibatis.annotations.Mapper;

/**
 * 用户表 数据层
 */
@Mapper
public interface SysUserMapper extends BaseMapper<SysUser> {
    // MyBatis-Plus 已内置 selectById, insert, update, delete 等方法
    // 登录时的 username 查询可以通过 Service 层的 lambdaQuery 实现，无需手写 SQL
}
