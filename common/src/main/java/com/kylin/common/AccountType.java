package com.kylin.common;

import com.baomidou.mybatisplus.annotation.EnumValue;
import com.fasterxml.jackson.annotation.JsonValue;
import lombok.Getter;

/**
 * 账户类型枚举 (参考 GnuCash 定义)
 * 核心会计恒等式: 资产 + 费用 = 负债 + 所有者权益 + 收入
 */
@Getter
public enum AccountType {

    // --- 资产类 (Assets) ---
    CASH(101, "现金", "ASSET"),
    BANK(102, "银行存款", "ASSET"),
    ASSET(100, "一般资产", "ASSET"), // 如：应收账款

    // --- 负债类 (Liabilities) ---
    CREDIT_CARD(201, "信用卡", "LIABILITY"),
    LIABILITY(200, "一般负债", "LIABILITY"), // 如：应付账款

    // --- 所有者权益 (Equity) ---
    EQUITY(300, "所有者权益", "EQUITY"), // 初始余额通常记在这里

    // --- 收入 (Income) ---
    INCOME(400, "收入", "INCOME"), // 如：工资、奖金

    // --- 支出 (Expense) ---
    EXPENSE(500, "支出", "EXPENSE"); // 如：餐饮、交通

    @EnumValue // 存入数据库的值
    private final int code;

    @JsonValue // 返回给前端的描述
    private final String description;

    // 大类: 用于计算借贷方向
    private final String category;

    AccountType(int code, String description, String category) {
        this.code = code;
        this.description = description;
        this.category = category;
    }
}