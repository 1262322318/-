-- DORIS sql 
-- ******************************************************************** --
-- author: lvxuebin.ex
-- create time: 2026/07/09 16:40:37 GMT+08:00
-- ******************************************************************** --

-- =====================================================================
-- 脚本名称：dws_ipd_ipd_project_impl_rate_dd.sql
-- 目标表：dws.dws_ipd_ipd_project_impl_rate_dd
-- 功能说明：应市项目按计划实施率明细表，判定每个项目的情况（结题/延期/暂停/终止/正常）
-- 数据来源：ods.odsplm_bm_hbmtprojectkpi + ods.odsplm_bm_hbmtprojectadjust + ods.odsrdm_holiday
-- 更新策略：DELETE当月 + INSERT
-- 调度频率：月度
-- 判定优先级：结题 > 延期 > 暂停 > 终止 > 正常
-- 合计分母：正常 + 延期 + 暂停 + 结题（终止不纳入）
-- =====================================================================

DELETE FROM dws.dws_ipd_ipd_project_impl_rate_dd
WHERE dt_month = DATE_FORMAT('${GP_START_DT}', '%Y%m');

INSERT INTO dws.dws_ipd_ipd_project_impl_rate_dd (
    dt_month,                          -- 统计月份（YYYYMM）
    projectname,                       -- 项目名称
    hbmtpproductline,                  -- 产品线原值（A1/BOX等）
    business_division,                 -- 事业部（光模块/终端）
    product_line_display,              -- 产品线展示名（TELECOM/BOX等）
    hbmtpderivetype,                   -- 项目分类原值（PS1/PA2等）
    derive_type_group,                 -- 项目分类分组（PS/PA/PB/PC1/PC2/HW/FH）
    projectcurrent,                    -- 项目状态原值（Active/Hold/Cancel等）
    hbmtpprojecttype,                  -- 项目类型
    productowner,                      -- 项目经理
    hbmtpdesignestimatededate,         -- 开发计划完成时间（市场因素变更后）
    hbmtpdesignactualedate,            -- 开发实际完成时间
    hbmtpproductionestimatededate,     -- 鉴定计划完成时间（市场因素变更后）
    hbmtpproductionactualedate,        -- 鉴定实际完成时间
    is_design_delay,                   -- 开发阶段延期标记（Y/N）
    design_deadline_date,              -- 开发计划+3工作日截止日期
    is_production_delay,               -- 鉴定阶段延期标记（Y/N）
    production_deadline_date,          -- 鉴定计划+3工作日截止日期
    project_situation,                 -- 项目情况（结题/延期/暂停/终止/正常）
    in_total_flag,                     -- 是否纳入合计分母（Y/N，终止为N）
    load_dt                            -- 加载时间
)
WITH
-- CTE1: 筛选符合条件的项目（产品线+分类+活跃判定）
project_base AS (
    SELECT
        DATE_FORMAT('${GP_START_DT}', '%Y%m')   AS dt_month,             -- 统计月份
        productname                              AS projectname,          -- 项目名称
        hbmtpproductline,                                                 -- 产品线原值
        CASE
            WHEN hbmtpproductline IN ('A1', 'A2', 'A3', 'A4', 'Coherent') THEN '光模块'
            WHEN hbmtpproductline IN ('BOX', 'Multimedia') THEN '终端'
            ELSE '其他'
        END                                      AS business_division,    -- 事业部映射
        CASE hbmtpproductline
            WHEN 'A1' THEN 'TELECOM'
            WHEN 'A2' THEN '数通DATACOM'
            WHEN 'A3' THEN 'FTTx'
            WHEN 'A4' THEN '无线'
            WHEN 'Coherent' THEN '相干产品线'
            WHEN 'BOX' THEN 'BOX'
            WHEN 'Multimedia' THEN '多媒体'
            ELSE hbmtpproductline
        END                                      AS product_line_display, -- 产品线展示名
        HBMTPDERIVETYPE                          AS hbmtpderivetype,      -- 项目分类原值
        CASE
            WHEN UPPER(HBMTPDERIVETYPE) LIKE 'PS%' THEN 'PS'
            WHEN UPPER(HBMTPDERIVETYPE) LIKE 'PA%' THEN 'PA'
            WHEN UPPER(HBMTPDERIVETYPE) LIKE 'PB%' THEN 'PB'
            WHEN UPPER(HBMTPDERIVETYPE) LIKE 'PC1%' THEN 'PC1'
            WHEN UPPER(HBMTPDERIVETYPE) LIKE 'PC2%' THEN 'PC2'
            WHEN UPPER(HBMTPDERIVETYPE) LIKE 'HW%' THEN 'HW'
            WHEN UPPER(HBMTPDERIVETYPE) LIKE 'FH%' THEN 'FH'
            ELSE UPPER(HBMTPDERIVETYPE)
        END                                      AS derive_type_group,    -- 项目分类分组
        projectcurrent,                                                   -- 项目状态原值
        hbmtpprojecttype,                                                 -- 项目类型
        productowner,                                                     -- 项目经理
        hbmtpdesignestimatededate,                                        -- 开发计划完成时间（变更后）
        hbmtpdesignactualedate,                                           -- 开发实际完成时间
        hbmtpproductionestimatededate,                                    -- 鉴定计划完成时间（变更后）
        hbmtpproductionactualedate                                        -- 鉴定实际完成时间
    FROM ods.odsplm_bm_hbmtprojectkpi
    WHERE hbmtpproductline IN ('A1', 'A2', 'A3', 'A4', 'Coherent', 'BOX', 'Multimedia')  -- 只统计光模块和终端
      AND (
          UPPER(HBMTPDERIVETYPE) LIKE 'PS%'                               -- PS类（全部子类）
          OR UPPER(HBMTPDERIVETYPE) LIKE 'PA%'                            -- PA类（全部子类）
          OR UPPER(HBMTPDERIVETYPE) LIKE 'PB%'                            -- PB类（全部子类）
          OR UPPER(HBMTPDERIVETYPE) LIKE 'PC1%'                           -- PC1
          OR UPPER(HBMTPDERIVETYPE) LIKE 'PC2%'                           -- PC2
          OR UPPER(HBMTPDERIVETYPE) LIKE 'HW%'                            -- HW
          OR UPPER(HBMTPDERIVETYPE) LIKE 'FH%'                            -- FH
      )
      -- TODO: 项目类型筛选，待确认精确存储值后启用
      -- AND hbmtpprojecttype = '应市类'
      AND (
          -- 条件A：鉴定未完成 且 状态为活跃（正常/延期候选）
          (hbmtpproductionactualedate IS NULL AND projectcurrent IN ('Assign', 'Active', 'Create'))
          OR
          -- 条件B：鉴定完成时间在当月（结题候选，不限状态）
          (DATE_FORMAT(hbmtpproductionactualedate, '%Y%m') = DATE_FORMAT('${GP_START_DT}', '%Y%m'))
          OR
          -- 条件C：暂停状态（累计展示）
          (projectcurrent = 'Hold')
          OR
          -- 条件D：取消状态 且 当月有取消单（终止候选，历史取消不纳入）
          (projectcurrent = 'Cancel' AND productname IN (
              SELECT DISTINCT projectname
              FROM ods.odsplm_bm_hbmtprojectadjust
              WHERE type = 'HBMTProjectCancleRequest'
                AND DATE_FORMAT(releasedate, '%Y%m') = DATE_FORMAT('${GP_START_DT}', '%Y%m')
          ))
      )
),

-- CTE2: 当月取消且无恢复的项目（终止判定）
cancel_info AS (
    SELECT DISTINCT adj_cancel.projectname                                -- 当月终止的项目名称
    FROM ods.odsplm_bm_hbmtprojectadjust adj_cancel
    WHERE adj_cancel.type = 'HBMTProjectCancleRequest'                    -- 取消单
      AND DATE_FORMAT(adj_cancel.releasedate, '%Y%m') = DATE_FORMAT('${GP_START_DT}', '%Y%m')  -- 发布日期在当月
      AND NOT EXISTS (
          -- 同一项目当月内无恢复单
          SELECT 1
          FROM ods.odsplm_bm_hbmtprojectadjust adj_resume
          WHERE adj_resume.projectname = adj_cancel.projectname
            AND adj_resume.type = 'HBMTProjectResumeRequest'              -- 恢复单
            AND DATE_FORMAT(adj_resume.releasedate, '%Y%m') = DATE_FORMAT('${GP_START_DT}', '%Y%m')
      )
),

-- CTE3: 延期判定（Doris兼容：通过JOIN工作日表计算+3工作日，无关联子查询）
-- 步骤：计划时间 → 找到>=计划时间的最小工作日id → id+3 → 取截止日期 → 与实际时间比较
design_deadline AS (
    SELECT
        pb.projectname,                                                   -- 项目名称
        MIN(h.id) AS design_base_id                                       -- 开发计划时间对应的最小工作日id
    FROM project_base pb
    INNER JOIN ods.odsrdm_holiday h
        ON CAST(h.date_time AS DATE) >= CAST(pb.hbmtpdesignestimatededate AS DATE)  -- 日期比较去掉时分秒
    WHERE pb.hbmtpdesignestimatededate IS NOT NULL
    GROUP BY pb.projectname
),

production_deadline AS (
    SELECT
        pb.projectname,                                                   -- 项目名称
        MIN(h.id) AS production_base_id                                   -- 鉴定计划时间对应的最小工作日id
    FROM project_base pb
    INNER JOIN ods.odsrdm_holiday h
        ON CAST(h.date_time AS DATE) >= CAST(pb.hbmtpproductionestimatededate AS DATE)  -- 日期比较去掉时分秒
    WHERE pb.hbmtpproductionestimatededate IS NOT NULL
    GROUP BY pb.projectname
),

delay_calc AS (
    SELECT
        pb.projectname,                                                   -- 项目名称
        -- 开发阶段延期判定：实际完成日期 > 计划+3工作日截止日期
        CASE
            WHEN pb.hbmtpdesignestimatededate IS NOT NULL
                 AND pb.hbmtpdesignactualedate IS NOT NULL
                 AND pb.hbmtpproductionactualedate IS NULL                -- 排除结题项目（鉴定实际完成为空才参与延期）
                 AND CAST(pb.hbmtpdesignactualedate AS DATE) > CAST(h_design.date_time AS DATE)
            THEN 'Y'
            ELSE 'N'
        END AS is_design_delay,                                           -- 开发延期标记
        h_design.date_time AS design_deadline_date,                       -- 开发计划+3工作日截止日期
        -- 鉴定阶段延期判定：实际完成日期 > 计划+3工作日截止日期
        CASE
            WHEN pb.hbmtpproductionestimatededate IS NOT NULL
                 AND pb.hbmtpproductionactualedate IS NOT NULL
                 AND DATE_FORMAT(pb.hbmtpproductionactualedate, '%Y%m') != DATE_FORMAT('${GP_START_DT}', '%Y%m')  -- 排除结题项目（当月完成的不算延期）
                 AND CAST(pb.hbmtpproductionactualedate AS DATE) > CAST(h_production.date_time AS DATE)
            THEN 'Y'
            ELSE 'N'
        END AS is_production_delay,                                       -- 鉴定延期标记
        h_production.date_time AS production_deadline_date                 -- 鉴定计划+3工作日截止日期
    FROM project_base pb
    LEFT JOIN design_deadline dd ON pb.projectname = dd.projectname
    LEFT JOIN ods.odsrdm_holiday h_design ON h_design.id = dd.design_base_id + 3          -- id+3对应截止日
    LEFT JOIN production_deadline pd ON pb.projectname = pd.projectname
    LEFT JOIN ods.odsrdm_holiday h_production ON h_production.id = pd.production_base_id + 3  -- id+3对应截止日
),

-- CTE5: LDAP用户表（项目经理编码→中文姓名）
ldap_user AS (
    SELECT DISTINCT account, name
    FROM ods.odsdt_tm_ldap_user
)

-- 最终SELECT：合并判定项目情况（优先级：结题>延期>暂停>终止>正常）
SELECT
    pb.dt_month,                                                          -- 统计月份
    pb.projectname,                                                       -- 项目名称
    pb.hbmtpproductline,                                                  -- 产品线原值
    pb.business_division,                                                 -- 事业部
    pb.product_line_display,                                              -- 产品线展示名
    pb.hbmtpderivetype,                                                   -- 项目分类原值
    pb.derive_type_group,                                                 -- 项目分类分组
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
    END                                      AS projectcurrent,           -- 项目状态（中文）
    pb.hbmtpprojecttype,                                                  -- 项目类型
    COALESCE(lu.name, pb.productowner)           AS productowner,          -- 项目经理（中文姓名）
    pb.hbmtpdesignestimatededate,                                         -- 开发计划完成时间（变更后）
    pb.hbmtpdesignactualedate,                                            -- 开发实际完成时间
    pb.hbmtpproductionestimatededate,                                     -- 鉴定计划完成时间（变更后）
    pb.hbmtpproductionactualedate,                                        -- 鉴定实际完成时间
    COALESCE(dc.is_design_delay, 'N')       AS is_design_delay,           -- 开发阶段延期标记
    dc.design_deadline_date,                                              -- 开发计划+3工作日截止日期
    COALESCE(dc.is_production_delay, 'N')   AS is_production_delay,       -- 鉴定阶段延期标记
    dc.production_deadline_date,                                          -- 鉴定计划+3工作日截止日期
    -- 项目情况判定（优先级：结题>延期>暂停>终止>正常）
    CASE
        WHEN DATE_FORMAT(pb.hbmtpproductionactualedate, '%Y%m') = DATE_FORMAT('${GP_START_DT}', '%Y%m')
            THEN '结题'                                                   -- 当月鉴定完成 → 结题
        WHEN (COALESCE(dc.is_design_delay, 'N') = 'Y' OR COALESCE(dc.is_production_delay, 'N') = 'Y')
            THEN '延期'                                                   -- 开发或鉴定超期 → 延期
        WHEN pb.projectcurrent = 'Hold'
            THEN '暂停'                                                   -- Hold状态 → 暂停
        WHEN pb.projectcurrent = 'Cancel' AND ci.projectname IS NOT NULL
            THEN '终止'                                                   -- 当月取消且无恢复 → 终止
        WHEN pb.projectcurrent IN ('Create', 'Active', 'Assign')
            THEN '正常'                                                   -- 状态为立项/活动/分配 且无超期 → 正常
        ELSE '其他'                                                       -- 防御性兜底，正常情况不应触发
    END                                      AS project_situation,         -- 项目情况
    -- 是否纳入合计分母（终止不纳入）
    CASE
        WHEN pb.projectcurrent = 'Cancel' AND ci.projectname IS NOT NULL
            THEN 'N'                                                      -- 终止项目不进分母
        ELSE 'Y'                                                          -- 其余纳入分母
    END                                      AS in_total_flag,            -- 合计分母标记
    NOW()                                    AS load_dt                   -- 加载时间
FROM project_base pb
LEFT JOIN cancel_info ci ON pb.projectname = ci.projectname               -- 关联终止判定
LEFT JOIN delay_calc dc ON pb.projectname = dc.projectname                -- 关联延期判定
LEFT JOIN ldap_user lu ON pb.productowner = lu.account                    -- 关联LDAP用户（编码→姓名）
;
