package com.kylin.common;

import com.baomidou.mybatisplus.annotation.*;
import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.Data;

import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 实体基类
 * 包含：ID, 创建时间, 更新时间, 逻辑删除
 */
@Data
public class BaseEntity implements Serializable {
    // 移除这里的 @TableId，让子类去定义，除非所有表主键名都叫 id
    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createTime;

    @TableField(fill = FieldFill.INSERT_UPDATE)
    private LocalDateTime updateTime;

    @TableLogic
    private Integer isDeleted;
}