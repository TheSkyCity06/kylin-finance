package com.kylin.finance.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.kylin.finance.entity.business.Employee;
import org.apache.ibatis.annotations.Mapper;

/**
 * 员工表数据库访问层
 */
@Mapper
public interface EmployeeMapper extends BaseMapper<Employee> {
}

