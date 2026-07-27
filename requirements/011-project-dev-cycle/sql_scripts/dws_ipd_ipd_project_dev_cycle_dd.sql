-- =====================================================================
-- 脚本名称：dws_ipd_ipd_project_dev_cycle_dd.sql
-- 目标表：dws.dws_ipd_ipd_project_dev_cycle_dd
-- 功能说明：应市项目开发周期明细表，计算每个项目的开发周期（扣除暂停时段），仅统计光模块和终端产品线
-- 数据来源：ods.odsplm_bm_hbmtprojectkpi + ods.odsplm_bm_hbmtprojectadjust
-- 更新策略：DELETE当月 + INSERT
-- 调度频率：月度
-- 三级域：管理集成产品开发/管理产品开发/整机产品开发
-- =====================================================================

DELETE FROM dws.dws_ipd_ipd_project_dev_cycle_dd
WHERE dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m');

INSERT INTO dws.dws_ipd_ipd_project_dev_cycle_dd (
    dt_month,                      -- 统计月份（项目完成所在月，YYYYMM）
    projectname,                   -- 项目名称
    hbmtpproductline,              -- 事业部（光模块/终端）
    hbmtpderivetype,               -- 项目分类原值（PA1/PB2/PC1等）
    derive_type_group,             -- 项目类型分组（PS/PA/PB/PC）
    projectcurrent,                -- 项目状态
    productcurrent,                -- 产品阶段
    productowner,                  -- 项目经理
    projectowner,                  -- 推进主管
    hbmtprddept,                   -- 在研部门
    hbmtprocessplant,              -- 生产工厂
    hbmtpprojectline,              -- 开发目的
    hbmtpprojecttype,              -- 项目类型
    hbmtprojectcreatedate,         -- 立项时间
    hbmtpdesignetime,              -- 开发计划完成时间（首次）
    hbmtpdesignestimatededate,     -- 开发计划完成时间（市场因素变更后）
    hbmtpdesignactualedate,        -- 开发实际完成时间
    hbmtpproductiontrialetime,     -- 鉴定计划完成时间（首次）
    hbmtpproductionestimatededate, -- 鉴定计划完成时间（市场因素变更后）
    hbmtpproductionactualedate,    -- 鉴定实际完成时间
    hold_days,                     -- 暂停总天数
    dev_cycle_days,                -- 开发周期（天）= 鉴定完成 - 立项 - 暂停天数
    load_dt                        -- 加载时间
)
WITH
-- CTE1: 筛选符合条件的已完成项目（当月鉴定实际完成）
project_base AS (
    SELECT
        DATE_FORMAT(hbmtpproductionactualedate, '%Y%m') AS dt_month,        -- 统计月份
        productname                   AS projectname,                        -- 项目名称
        CASE
            WHEN hbmtpproductline IN ('A1', 'A2', 'A3', 'A4', 'Coherent') THEN '光模块'
            WHEN hbmtpproductline IN ('BOX', 'Multimedia') THEN '终端'
            ELSE '其他'
        END                           AS hbmtpproductline,                   -- 事业部（光模块/终端）
        HBMTPDERIVETYPE               AS hbmtpderivetype,                   -- 项目分类原值
        CASE
            WHEN UPPER(HBMTPDERIVETYPE) LIKE 'PS%' THEN 'PS'
            WHEN UPPER(HBMTPDERIVETYPE) LIKE 'PA%' THEN 'PA'
            WHEN UPPER(HBMTPDERIVETYPE) LIKE 'PB%' THEN 'PB'
            WHEN UPPER(HBMTPDERIVETYPE) LIKE 'PC%' THEN 'PC'
            ELSE UPPER(HBMTPDERIVETYPE)
        END                           AS derive_type_group,                  -- 项目类型分组
        projectcurrent,                                                      -- 项目状态
        productcurrent,                                                      -- 产品阶段
        productowner,                                                        -- 项目经理
        projectowner,                                                        -- 推进主管
        hbmtprddept,                                                         -- 在研部门
        hbmtprocessplant,                                                    -- 生产工厂
        hbmtpprojectline,                                                    -- 开发目的
        hbmtpprojecttype,                                                    -- 项目类型
        hbmtprojectcreatedate,                                               -- 立项时间
        hbmtpdesignetime,                                                    -- 开发计划完成时间（首次）
        hbmtpdesignestimatededate,                                           -- 开发计划完成时间（变更后）
        hbmtpdesignactualedate,                                              -- 开发实际完成时间
        hbmtpproductiontrialetime,                                           -- 鉴定计划完成时间（首次）
        hbmtpproductionestimatededate,                                       -- 鉴定计划完成时间（变更后）
        hbmtpproductionactualedate                                           -- 鉴定实际完成时间
    FROM ods.odsplm_bm_hbmtprojectkpi
    WHERE projectcurrent IN ('Complete', 'Review', 'Archive')                -- 已完成/复核/归档
      AND (
          UPPER(HBMTPDERIVETYPE) LIKE 'PS%'
          OR UPPER(HBMTPDERIVETYPE) LIKE 'PA%'
          OR UPPER(HBMTPDERIVETYPE) LIKE 'PB%'
          OR UPPER(HBMTPDERIVETYPE) IN ('PC1', 'PC2')
      )
      AND hbmtpproductline IN ('A1', 'A2', 'A3', 'A4', 'Coherent', 'BOX', 'Multimedia')  -- 只统计光模块和终端
      AND DATE_FORMAT(hbmtpproductionactualedate, '%Y%m') = DATE_FORMAT('${GP_START_DT}', '%Y%m')
      AND hbmtpproductionactualedate IS NOT NULL
      AND hbmtprojectcreatedate IS NOT NULL
),

-- CTE2: 暂停/恢复单配对，计算每段暂停天数
hold_resume AS (
    SELECT
        projectname,
        releasedate                   AS hold_date,                          -- 暂停单发布日期
        LEAD(releasedate) OVER (
            PARTITION BY projectname 
            ORDER BY releasedate
        )                             AS resume_date                         -- 恢复单发布日期（下一条记录）
    FROM (
        SELECT
            projectname,
            releasedate,
            type
        FROM ods.odsplm_bm_hbmtprojectadjust
        WHERE type IN ('HBMTProjectHoldRequest', 'HBMTProjectResumeRequest')
          AND releasedate IS NOT NULL
    ) t
    WHERE type = 'HBMTProjectHoldRequest'                                    -- 只取暂停单行，恢复日期用LEAD获取
),

-- CTE3: 按项目汇总暂停总天数
hold_days_sum AS (
    SELECT
        projectname,
        SUM(
            CASE 
                WHEN resume_date IS NOT NULL 
                THEN DATEDIFF(resume_date, hold_date)
                ELSE 0                                                       -- 暂停后未恢复则不扣除
            END
        )                             AS hold_days                           -- 暂停总天数
    FROM hold_resume
    GROUP BY projectname
),

-- CTE4: LDAP用户表（项目经理/推进主管编码→中文姓名）
ldap_user AS (
    SELECT DISTINCT account, name
    FROM ods.odsdt_tm_ldap_user
)

-- 最终SELECT
SELECT
    pb.dt_month,                                                             -- 统计月份
    pb.projectname,                                                          -- 项目名称
    pb.hbmtpproductline,                                                     -- 事业部（光模块/终端）
    pb.hbmtpderivetype,                                                      -- 项目分类原值
    pb.derive_type_group,                                                    -- 项目类型分组
    CASE pb.projectcurrent
        WHEN 'Complete' THEN '完成'
        WHEN 'Review' THEN '复核'
        WHEN 'Archive' THEN '归档'
        WHEN 'Hold' THEN '暂停'
        WHEN 'Cancel' THEN '取消'
        WHEN 'Concept' THEN '概念'
        WHEN 'Create' THEN '项目立项'
        WHEN 'Assign' THEN '分配'
        WHEN 'Active' THEN '活动'
        ELSE pb.projectcurrent
    END                               AS projectcurrent,                     -- 项目状态（中文）
    pb.productcurrent,                                                       -- 产品阶段
    COALESCE(lu.name, pb.productowner)  AS productowner,                     -- 项目经理（中文姓名）
    COALESCE(lu2.name, pb.projectowner) AS projectowner,                     -- 推进主管（中文姓名）
    pb.hbmtprddept,                                                          -- 在研部门
    pb.hbmtprocessplant,                                                     -- 生产工厂
    pb.hbmtpprojectline,                                                     -- 开发目的
    pb.hbmtpprojecttype,                                                     -- 项目类型
    pb.hbmtprojectcreatedate,                                                -- 立项时间
    pb.hbmtpdesignetime,                                                     -- 开发计划完成时间（首次）
    pb.hbmtpdesignestimatededate,                                            -- 开发计划完成时间（变更后）
    pb.hbmtpdesignactualedate,                                               -- 开发实际完成时间
    pb.hbmtpproductiontrialetime,                                            -- 鉴定计划完成时间（首次）
    pb.hbmtpproductionestimatededate,                                        -- 鉴定计划完成时间（变更后）
    pb.hbmtpproductionactualedate,                                           -- 鉴定实际完成时间
    COALESCE(hd.hold_days, 0)         AS hold_days,                          -- 暂停总天数（无暂停则为0）
    DATEDIFF(pb.hbmtpproductionactualedate, pb.hbmtprojectcreatedate) 
        - COALESCE(hd.hold_days, 0)   AS dev_cycle_days,                     -- 开发周期（天）
    NOW()                             AS load_dt                             -- 加载时间
FROM project_base pb
LEFT JOIN hold_days_sum hd ON pb.projectname = hd.projectname
LEFT JOIN ldap_user lu ON pb.productowner = lu.account                       -- 关联LDAP（项目经理）
LEFT JOIN ldap_user lu2 ON pb.projectowner = lu2.account                     -- 关联LDAP（推进主管）
;
