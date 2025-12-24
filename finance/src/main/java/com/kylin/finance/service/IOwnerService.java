package com.kylin.finance.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.kylin.finance.entity.business.Owner;

import java.util.List;

/**
 * 业务实体（客户/供应商/员工）服务接口
 */
public interface IOwnerService extends IService<Owner> {
    
    /**
     * 创建业务实体
     * @param owner 业务实体对象
     * @return 创建后的实体（包含生成的ID）
     */
    Owner createOwner(Owner owner);
    
    /**
     * 更新业务实体
     * @param owner 业务实体对象
     * @return 更新后的实体
     */
    Owner updateOwner(Owner owner);
    
    /**
     * 删除业务实体（逻辑删除）
     * @param ownerId 业务实体ID
     */
    void deleteOwner(Long ownerId);
    
    /**
     * 根据类型查询业务实体列表
     * @param ownerType 实体类型：CUSTOMER(客户), VENDOR(供应商), EMPLOYEE(员工)
     * @return 业务实体列表
     */
    List<Owner> getOwnersByType(String ownerType);
    
    /**
     * 根据ID查询业务实体（包含关联的科目名称）
     * @param ownerId 业务实体ID
     * @return 业务实体
     */
    Owner getOwnerById(Long ownerId);
}

