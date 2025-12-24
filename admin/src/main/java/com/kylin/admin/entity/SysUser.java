package com.kylin.admin.entity;

import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.kylin.common.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;
import com.baomidou.mybatisplus.annotation.IdType;
/**
 * 系统用户表
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("sys_user")
public class SysUser extends BaseEntity {

    @TableId(type = IdType.ASSIGN_ID)
    private Long id; // 在这里定义，SysUserService 就能找到 getId() 了
    private String username;     // 用户名

    private String password;     // 密码（加密存储）

    private String nickname;     // 昵称/真实姓名

    private String email;        // 邮箱

    private String phone;        // 手机号

    private Integer status;      // 状态：1正常 0停用

    // 注意：实际业务中用户和角色是多对多关系，
    // 但为了简化作业演示，这里可以假设主要角色ID，或者通过中间表查询
    // private Long roleId;
}