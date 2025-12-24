package com.kylin.finance.seeder;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.kylin.finance.entity.FinAccount;
import com.kylin.finance.entity.FinSplit;
import com.kylin.finance.entity.FinTransaction;
import com.kylin.finance.mapper.FinAccountMapper;
import com.kylin.finance.mapper.FinSplitMapper;
import com.kylin.finance.mapper.FinTransactionMapper;
import com.kylin.finance.service.IFinTransactionService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Random;

/**
 * 凭证数据生成器
 * 用于生成测试数据，覆盖过去3个月，包含三种业务场景
 * 
 * 使用方式：
 * 1. 确保数据库已初始化（执行 database/init.sql）
 * 2. 启动应用，此组件会自动运行
 * 3. 如需重新生成，先清空 fin_transaction 和 fin_split 表
 */
@Slf4j
@Component
public class VoucherDataSeeder implements CommandLineRunner {

    @Autowired
    private FinAccountMapper accountMapper;

    @Autowired
    private FinTransactionMapper transactionMapper;

    @Autowired
    private FinSplitMapper splitMapper;

    @Autowired
    private IFinTransactionService transactionService;

    private final Random random = new Random();
    
    // 用于跟踪每天生成的凭证序号
    private final Map<String, Integer> dailySequenceMap = new HashMap<>();

    // 科目代码常量
    private static final String ACCOUNT_CODE_BANK = "1002"; // 银行存款
    private static final String ACCOUNT_CODE_REVENUE = "6001"; // 主营业务收入
    private static final String ACCOUNT_CODE_ADMIN_EXPENSE = "6602"; // 管理费用
    private static final String ACCOUNT_CODE_SALARY_EXPENSE = "6601"; // 销售费用（用于工资）
    private static final String ACCOUNT_CODE_SALARY_PAYABLE = "2211"; // 应付职工薪酬

    // 场景描述
    private static final String[] REVENUE_DESCRIPTIONS = {
        "收到客户货款",
        "收到销售回款",
        "收到项目款",
        "收到服务费",
        "收到预收款"
    };

    private static final String[] EXPENSE_DESCRIPTIONS = {
        "支付办公用品费",
        "支付水电费",
        "支付差旅费",
        "支付通讯费",
        "支付租赁费",
        "支付维修费",
        "支付咨询费"
    };

    private static final String[] SALARY_DESCRIPTIONS = {
        "计提员工工资",
        "计提管理人员工资",
        "计提销售人员工资",
        "计提技术人员工资"
    };

    @Override
    public void run(String... args) {
        // 检查是否已有数据，避免重复生成
        long existingCount = transactionMapper.selectCount(null);
        if (existingCount > 0) {
            log.info("检测到已有凭证数据 {} 条，跳过数据生成。如需重新生成，请先清空 fin_transaction 和 fin_split 表。", existingCount);
            return;
        }

        log.info("开始生成凭证测试数据...");

        try {
            // 获取科目ID
            Long bankAccountId = getAccountIdByCode(ACCOUNT_CODE_BANK);
            Long revenueAccountId = getAccountIdByCode(ACCOUNT_CODE_REVENUE);
            Long adminExpenseAccountId = getAccountIdByCode(ACCOUNT_CODE_ADMIN_EXPENSE);
            Long salaryExpenseAccountId = getAccountIdByCode(ACCOUNT_CODE_SALARY_EXPENSE);
            Long salaryPayableAccountId = getAccountIdByCode(ACCOUNT_CODE_SALARY_PAYABLE);

            // 验证科目是否存在
            if (bankAccountId == null || revenueAccountId == null || adminExpenseAccountId == null 
                || salaryExpenseAccountId == null || salaryPayableAccountId == null) {
                log.error("无法找到必要的科目，请确保已执行 database/init.sql 初始化科目数据");
                log.error("缺失的科目：银行={}, 收入={}, 管理费={}, 工资费={}, 应付工资={}", 
                    bankAccountId, revenueAccountId, adminExpenseAccountId, salaryExpenseAccountId, salaryPayableAccountId);
                return;
            }

            // 生成20个凭证
            int revenueCount = 8;  // 收入场景
            int expenseCount = 7;  // 费用场景
            int salaryCount = 5;   // 工资场景

            LocalDate endDate = LocalDate.now();
            LocalDate startDate = endDate.minusDays(90); // 过去90天

            int voucherIndex = 1;

            // 生成收入凭证
            for (int i = 0; i < revenueCount; i++) {
                LocalDate transDate = generateRandomDate(startDate, endDate);
                BigDecimal amount = generateRandomAmount(5000, 50000);
                String description = REVENUE_DESCRIPTIONS[random.nextInt(REVENUE_DESCRIPTIONS.length)];
                
                createRevenueVoucher(voucherIndex++, transDate, bankAccountId, revenueAccountId, amount, description);
            }

            // 生成费用凭证
            for (int i = 0; i < expenseCount; i++) {
                LocalDate transDate = generateRandomDate(startDate, endDate);
                BigDecimal amount = generateRandomAmount(100, 2000);
                String description = EXPENSE_DESCRIPTIONS[random.nextInt(EXPENSE_DESCRIPTIONS.length)];
                
                createExpenseVoucher(voucherIndex++, transDate, adminExpenseAccountId, bankAccountId, amount, description);
            }

            // 生成工资凭证
            for (int i = 0; i < salaryCount; i++) {
                LocalDate transDate = generateRandomDate(startDate, endDate);
                BigDecimal amount = generateRandomAmount(10000, 50000);
                String description = SALARY_DESCRIPTIONS[random.nextInt(SALARY_DESCRIPTIONS.length)];
                
                createSalaryVoucher(voucherIndex++, transDate, salaryExpenseAccountId, salaryPayableAccountId, amount, description);
            }

            log.info("成功生成 {} 个凭证测试数据", voucherIndex - 1);

        } catch (Exception e) {
            log.error("生成凭证数据时发生错误", e);
        }
    }

    /**
     * 创建收入凭证（场景A）
     * 借：银行存款 贷：主营业务收入
     */
    private void createRevenueVoucher(int index, LocalDate transDate, Long bankAccountId, 
                                     Long revenueAccountId, BigDecimal amount, String description) {
        FinTransaction transaction = new FinTransaction();
        transaction.setVoucherNo(generateVoucherNo(transDate, index));
        transaction.setTransDate(transDate);
        transaction.setEnterDate(LocalDateTime.now());
        transaction.setDescription(description);
        transaction.setStatus(1); // 已审核
        transaction.setCurrencyId(1L); // 假设币种ID为1（人民币）

        List<FinSplit> splits = new ArrayList<>();
        
        // 借方：银行存款
        FinSplit debitSplit = new FinSplit();
        debitSplit.setAccountId(bankAccountId);
        debitSplit.setDirection("DEBIT");
        debitSplit.setAmount(amount);
        debitSplit.setMemo(description);
        splits.add(debitSplit);

        // 贷方：主营业务收入
        FinSplit creditSplit = new FinSplit();
        creditSplit.setAccountId(revenueAccountId);
        creditSplit.setDirection("CREDIT");
        creditSplit.setAmount(amount);
        creditSplit.setMemo(description);
        splits.add(creditSplit);

        transaction.setSplits(splits);
        
        // 使用服务保存，会自动校验借贷平衡
        transactionService.saveVoucher(transaction);
        log.debug("创建收入凭证: {} - {} - {}", transaction.getVoucherNo(), description, amount);
    }

    /**
     * 创建费用凭证（场景B）
     * 借：管理费用 贷：银行存款
     */
    private void createExpenseVoucher(int index, LocalDate transDate, Long expenseAccountId,
                                     Long bankAccountId, BigDecimal amount, String description) {
        FinTransaction transaction = new FinTransaction();
        transaction.setVoucherNo(generateVoucherNo(transDate, index));
        transaction.setTransDate(transDate);
        transaction.setEnterDate(LocalDateTime.now());
        transaction.setDescription(description);
        transaction.setStatus(1); // 已审核
        transaction.setCurrencyId(1L);

        List<FinSplit> splits = new ArrayList<>();
        
        // 借方：管理费用
        FinSplit debitSplit = new FinSplit();
        debitSplit.setAccountId(expenseAccountId);
        debitSplit.setDirection("DEBIT");
        debitSplit.setAmount(amount);
        debitSplit.setMemo(description);
        splits.add(debitSplit);

        // 贷方：银行存款
        FinSplit creditSplit = new FinSplit();
        creditSplit.setAccountId(bankAccountId);
        creditSplit.setDirection("CREDIT");
        creditSplit.setAmount(amount);
        creditSplit.setMemo(description);
        splits.add(creditSplit);

        transaction.setSplits(splits);
        
        transactionService.saveVoucher(transaction);
        log.debug("创建费用凭证: {} - {} - {}", transaction.getVoucherNo(), description, amount);
    }

    /**
     * 创建工资凭证（场景C）
     * 借：销售费用（工资） 贷：应付职工薪酬
     */
    private void createSalaryVoucher(int index, LocalDate transDate, Long salaryExpenseAccountId,
                                    Long salaryPayableAccountId, BigDecimal amount, String description) {
        FinTransaction transaction = new FinTransaction();
        transaction.setVoucherNo(generateVoucherNo(transDate, index));
        transaction.setTransDate(transDate);
        transaction.setEnterDate(LocalDateTime.now());
        transaction.setDescription(description);
        transaction.setStatus(1); // 已审核
        transaction.setCurrencyId(1L);

        List<FinSplit> splits = new ArrayList<>();
        
        // 借方：销售费用（工资）
        FinSplit debitSplit = new FinSplit();
        debitSplit.setAccountId(salaryExpenseAccountId);
        debitSplit.setDirection("DEBIT");
        debitSplit.setAmount(amount);
        debitSplit.setMemo(description);
        splits.add(debitSplit);

        // 贷方：应付职工薪酬
        FinSplit creditSplit = new FinSplit();
        creditSplit.setAccountId(salaryPayableAccountId);
        creditSplit.setDirection("CREDIT");
        creditSplit.setAmount(amount);
        creditSplit.setMemo(description);
        splits.add(creditSplit);

        transaction.setSplits(splits);
        
        transactionService.saveVoucher(transaction);
        log.debug("创建工资凭证: {} - {} - {}", transaction.getVoucherNo(), description, amount);
    }

    /**
     * 根据科目代码获取科目ID
     */
    private Long getAccountIdByCode(String accountCode) {
        LambdaQueryWrapper<FinAccount> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(FinAccount::getAccountCode, accountCode);
        wrapper.last("LIMIT 1");
        FinAccount account = accountMapper.selectOne(wrapper);
        return account != null ? account.getAccountId() : null;
    }

    /**
     * 生成凭证号
     * 格式：V + yyyyMMdd + 3位序号（同一天自动递增）
     */
    private String generateVoucherNo(LocalDate date, int baseSequence) {
        String dateStr = date.format(DateTimeFormatter.ofPattern("yyyyMMdd"));
        
        // 获取当天已生成的序号
        int sequence = dailySequenceMap.getOrDefault(dateStr, 0) + 1;
        dailySequenceMap.put(dateStr, sequence);
        
        return String.format("V%s%03d", dateStr, sequence);
    }

    /**
     * 生成随机日期（在过去90天内）
     */
    private LocalDate generateRandomDate(LocalDate startDate, LocalDate endDate) {
        long startEpochDay = startDate.toEpochDay();
        long endEpochDay = endDate.toEpochDay();
        long randomEpochDay = startEpochDay + random.nextInt((int) (endEpochDay - startEpochDay + 1));
        return LocalDate.ofEpochDay(randomEpochDay);
    }

    /**
     * 生成随机金额（指定范围）
     */
    private BigDecimal generateRandomAmount(int min, int max) {
        int amount = min + random.nextInt(max - min + 1);
        return BigDecimal.valueOf(amount).setScale(2, RoundingMode.HALF_UP);
    }
}

