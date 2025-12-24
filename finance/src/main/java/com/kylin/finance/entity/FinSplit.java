package com.kylin.finance.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.kylin.common.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;
import java.math.BigDecimal;

/**
 * 凭证分录实体
 * 对应数据库表：fin_split
 */
@Data
@EqualsAndHashCode(callSuper = true) // 包含父类 BaseEntity 的字段参与比较
@TableName("fin_split")
public class FinSplit extends BaseEntity {

    private static final long serialVersionUID = 1L;

    /**
     * 分录ID (主键)
     */
    @TableId(value = "split_id", type = IdType.AUTO)
    private Long splitId;

    /**
     * 关联的凭证ID (外键 -> fin_transaction.trans_id)
     */
    @TableField("trans_id") // 显式指定数据库列名
    private Long transId;

    /**
     * 关联的科目ID (外键 -> fin_account.account_id)
     */
    private Long accountId;

    /**
     * 借贷方向
     * 枚举值通常为：DEBIT (借), CREDIT (贷)
     */
    private String direction;

    /**
     * 金额
     * 使用 BigDecimal 保证财务计算精度
     */
    private BigDecimal amount;

    /**
     * 分录备注/摘要 (可选)
     */
    private String memo;
    
    /**
     * 关联的业务实体ID（可选，如果涉及客户/供应商/员工）
     */
    private Long ownerId;
    
    /**
     * 业务实体类型：CUSTOMER(客户), VENDOR(供应商), EMPLOYEE(员工)
     */
    private String ownerType;

    /**
     * 科目名称（非数据库字段，用于前端显示）
     */
    @TableField(exist = false)
    private String accountName;

    /**
     * 科目代码（非数据库字段，用于前端显示）
     */
    @TableField(exist = false)
    private String accountCode;
}