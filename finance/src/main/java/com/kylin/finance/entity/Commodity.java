package com.kylin.finance.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.kylin.common.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 币种实体（参考 GnuCash）
 * 支持多种货币和商品类型
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("fin_commodity")
public class Commodity extends BaseEntity {
    
    @TableId(type = IdType.AUTO)
    private Long commodityId;
    
    /**
     * 币种代码（如：CNY, USD, EUR）
     */
    private String commodityCode;
    
    /**
     * 币种名称（如：人民币、美元、欧元）
     */
    private String commodityName;
    
    /**
     * 币种类型：CURRENCY(货币), STOCK(股票), MUTUAL(基金) 等
     */
    private String commodityType;
    
    /**
     * 小数位数（默认2位）
     */
    private Integer fraction;
    
    /**
     * 是否启用
     */
    private Boolean enabled;
}

