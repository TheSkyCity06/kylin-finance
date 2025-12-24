package com.kylin.finance.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.kylin.common.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

@Data
@EqualsAndHashCode(callSuper = true)
@TableName("fin_account")
public class FinAccount extends BaseEntity {
    @TableId(type = IdType.AUTO) // 必须与数据库 AUTO_INCREMENT 对应
    private Long accountId;
    private String accountCode; // 科目代码，如 1001
    private String accountName; // 科目名称，如 库存现金
    private String accountType; // 类型：ASSET(资产), LIABILITY(负债)等
    private Long parentId;      // 父科目ID，构建树形结构
    private Long commodityId;   // 币种ID（参考 GnuCash），关联 fin_commodity 表
}
