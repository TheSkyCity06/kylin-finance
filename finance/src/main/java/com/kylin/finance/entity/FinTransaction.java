package com.kylin.finance.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import lombok.EqualsAndHashCode;
import java.io.Serializable;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Data
@EqualsAndHashCode(callSuper = false)
@TableName("fin_transaction")
public class FinTransaction implements Serializable {

    private static final long serialVersionUID = 1L;
    @TableId(value = "trans_id", type = IdType.AUTO)
    private Long transId;
    private String voucherNo;
    private Long currencyId;
    private LocalDate transDate;
    private LocalDateTime enterDate;
    private String description;
    private Long creatorId;
    private Integer status;

    // 非数据库字段，用于接收前端传来的分录列表
    @TableField(exist = false)
    private List<FinSplit> splits;
}