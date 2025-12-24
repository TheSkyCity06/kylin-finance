package com.kylin.finance.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.kylin.common.BusinessException;
import com.kylin.finance.entity.FinAccount;
import com.kylin.finance.entity.business.Owner;
import com.kylin.finance.mapper.FinAccountMapper;
import com.kylin.finance.mapper.OwnerMapper;
import com.kylin.finance.service.IOwnerService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * 业务实体（客户/供应商/员工）服务实现类
 */
@Slf4j
@Service
public class OwnerServiceImpl extends ServiceImpl<OwnerMapper, Owner> implements IOwnerService {
    
    @Autowired
    private FinAccountMapper accountMapper;
    
    @Override
    @Transactional(rollbackFor = Exception.class)
    public Owner createOwner(Owner owner) {
        try {
            log.info("创建业务实体，类型：{}，名称：{}", owner.getOwnerType(), owner.getName());
            
            // 校验必填字段
            if (owner.getName() == null || owner.getName().trim().isEmpty()) {
                throw new BusinessException("业务实体名称不能为空");
            }
            if (owner.getOwnerType() == null || owner.getOwnerType().trim().isEmpty()) {
                throw new BusinessException("业务实体类型不能为空");
            }
            
            // 校验代码唯一性（如果提供了代码）
            if (owner.getCode() != null && !owner.getCode().trim().isEmpty()) {
                LambdaQueryWrapper<Owner> wrapper = new LambdaQueryWrapper<>();
                wrapper.eq(Owner::getCode, owner.getCode());
                wrapper.eq(Owner::getOwnerType, owner.getOwnerType());
                long count = this.count(wrapper);
                if (count > 0) {
                    throw new BusinessException("该类型下已存在相同代码的业务实体：" + owner.getCode());
                }
            }
            
            // 校验关联科目是否存在（如果提供了科目ID）
            if (owner.getAccountId() != null) {
                FinAccount account = accountMapper.selectById(owner.getAccountId());
                if (account == null) {
                    throw new BusinessException("关联的科目不存在，科目ID：" + owner.getAccountId());
                }
            }
            
            // 设置默认值
            if (owner.getEnabled() == null) {
                owner.setEnabled(true);
            }
            
            // 保存
            boolean success = this.save(owner);
            if (!success) {
                throw new BusinessException("创建业务实体失败");
            }
            
            log.info("业务实体创建成功，ID：{}", owner.getOwnerId());
            
            // 返回包含关联科目名称的实体
            return getOwnerById(owner.getOwnerId());
            
        } catch (BusinessException e) {
            log.error("创建业务实体失败：{}", e.getMessage());
            throw e;
        } catch (Exception e) {
            log.error("创建业务实体异常", e);
            throw new BusinessException("创建业务实体失败：" + e.getMessage());
        }
    }
    
    @Override
    @Transactional(rollbackFor = Exception.class)
    public Owner updateOwner(Owner owner) {
        try {
            log.info("更新业务实体，ID：{}，类型：{}，名称：{}", owner.getOwnerId(), owner.getOwnerType(), owner.getName());
            
            if (owner.getOwnerId() == null) {
                throw new BusinessException("业务实体ID不能为空");
            }
            
            // 检查实体是否存在
            Owner existing = this.getById(owner.getOwnerId());
            if (existing == null) {
                throw new BusinessException("业务实体不存在，ID：" + owner.getOwnerId());
            }
            
            // 校验必填字段
            if (owner.getName() != null && owner.getName().trim().isEmpty()) {
                throw new BusinessException("业务实体名称不能为空");
            }
            
            // 校验代码唯一性（如果修改了代码）
            if (owner.getCode() != null && !owner.getCode().trim().isEmpty()) {
                LambdaQueryWrapper<Owner> wrapper = new LambdaQueryWrapper<>();
                wrapper.eq(Owner::getCode, owner.getCode());
                wrapper.eq(Owner::getOwnerType, owner.getOwnerType());
                wrapper.ne(Owner::getOwnerId, owner.getOwnerId());
                long count = this.count(wrapper);
                if (count > 0) {
                    throw new BusinessException("该类型下已存在相同代码的业务实体：" + owner.getCode());
                }
            }
            
            // 校验关联科目是否存在（如果提供了科目ID）
            if (owner.getAccountId() != null) {
                FinAccount account = accountMapper.selectById(owner.getAccountId());
                if (account == null) {
                    throw new BusinessException("关联的科目不存在，科目ID：" + owner.getAccountId());
                }
            }
            
            // 更新
            boolean success = this.updateById(owner);
            if (!success) {
                throw new BusinessException("更新业务实体失败");
            }
            
            log.info("业务实体更新成功，ID：{}", owner.getOwnerId());
            
            // 返回包含关联科目名称的实体
            return getOwnerById(owner.getOwnerId());
            
        } catch (BusinessException e) {
            log.error("更新业务实体失败：{}", e.getMessage());
            throw e;
        } catch (Exception e) {
            log.error("更新业务实体异常", e);
            throw new BusinessException("更新业务实体失败：" + e.getMessage());
        }
    }
    
    @Override
    @Transactional(rollbackFor = Exception.class)
    public void deleteOwner(Long ownerId) {
        try {
            log.info("删除业务实体，ID：{}", ownerId);
            
            if (ownerId == null) {
                throw new BusinessException("业务实体ID不能为空");
            }
            
            // 检查实体是否存在
            Owner owner = this.getById(ownerId);
            if (owner == null) {
                throw new BusinessException("业务实体不存在，ID：" + ownerId);
            }
            
            // 逻辑删除（MyBatis-Plus 会自动处理 is_deleted 字段）
            boolean success = this.removeById(ownerId);
            if (!success) {
                throw new BusinessException("删除业务实体失败");
            }
            
            log.info("业务实体删除成功，ID：{}", ownerId);
            
        } catch (BusinessException e) {
            log.error("删除业务实体失败：{}", e.getMessage());
            throw e;
        } catch (Exception e) {
            log.error("删除业务实体异常", e);
            throw new BusinessException("删除业务实体失败：" + e.getMessage());
        }
    }
    
    @Override
    public List<Owner> getOwnersByType(String ownerType) {
        try {
            log.debug("查询业务实体列表，类型：{}", ownerType);
            
            LambdaQueryWrapper<Owner> wrapper = new LambdaQueryWrapper<>();
            wrapper.eq(Owner::getOwnerType, ownerType);
            wrapper.orderByDesc(Owner::getCreateTime);
            
            List<Owner> owners = this.list(wrapper);
            
            // 填充关联的科目名称
            for (Owner owner : owners) {
                if (owner.getAccountId() != null) {
                    FinAccount account = accountMapper.selectById(owner.getAccountId());
                    if (account != null) {
                        owner.setAccountName(account.getAccountCode() + " " + account.getAccountName());
                    }
                }
            }
            
            log.debug("查询到 {} 条业务实体记录", owners.size());
            return owners;
            
        } catch (Exception e) {
            log.error("查询业务实体列表异常", e);
            throw new BusinessException("查询业务实体列表失败：" + e.getMessage());
        }
    }
    
    @Override
    public Owner getOwnerById(Long ownerId) {
        try {
            log.debug("查询业务实体，ID：{}", ownerId);
            
            Owner owner = this.getById(ownerId);
            if (owner == null) {
                throw new BusinessException("业务实体不存在，ID：" + ownerId);
            }
            
            // 填充关联的科目名称
            if (owner.getAccountId() != null) {
                FinAccount account = accountMapper.selectById(owner.getAccountId());
                if (account != null) {
                    owner.setAccountName(account.getAccountCode() + " " + account.getAccountName());
                }
            }
            
            return owner;
            
        } catch (BusinessException e) {
            log.error("查询业务实体失败：{}", e.getMessage());
            throw e;
        } catch (Exception e) {
            log.error("查询业务实体异常", e);
            throw new BusinessException("查询业务实体失败：" + e.getMessage());
        }
    }
}

