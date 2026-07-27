-- =====================================================================
-- 草稿：本年复产机型不考核规则
-- 【状态：✅ 已合入正式脚本  合入日期：2026-06-13】
-- 变更说明：在所有产品线的is_project判定中新增"本年复产不考核"逻辑
-- 适用范围：zhibiao_type='2'（低效型号数）和 zhibiao_type='4'（新品命中率）
-- 数据来源：dwd.dwd_ipd_ipm_hdrp_delisted_dd（formstatus='发布' AND formtype='再上市'）
-- 创建日期：2026-06-13
-- =====================================================================

-- =====================================================
-- 修改点总览（共12处）
-- =====================================================
-- 【产品型号口径】（masterDataType='productModel'，用masterDataName匹配PG00061）
-- 1. 冰箱/冷柜/洗衣机 zhibiao_type='2' （约第337行附近）
-- 2. 视像科技 zhibiao_type='2' （约第500行附近）
-- 3. 空气事业部 家用空调 zhibiao_type='2' （约第700行附近）
-- 4. 厨电 zhibiao_type='2' （约第1700行附近）
-- 5. 激光 zhibiao_type='2' （约第1900行附近）
-- 6. 冰箱/冷柜/洗衣机 zhibiao_type='4' （约第900行附近）
-- 7. 视像科技 zhibiao_type='4' （约第1100行附近）
-- 8. 空气事业部 家用空调 zhibiao_type='4' （约第1300行附近）
-- 9. 厨电 zhibiao_type='4' （约第2000行附近）
-- 10. 激光 zhibiao_type='4' （约第2100行附近）
--
-- 【销售型号编码口径】（masterDataType='salesModel'，用mdgno匹配PG00068）
-- 11. 中央空调日立 zhibiao_type='2' （约第800行附近）
-- 12. 中央空调日立 zhibiao_type='4' （约第1400行附近）


-- =====================================================
-- 一、产品型号口径：新增CTE模板
-- =====================================================
-- 在每个段落的最后一个CTE（通常是plan_sales）之后，最终SELECT之前，新增：

,fuchan_model as (
    --本年复产型号（产品型号口径）
    select distinct masterDataName
    from dwd.dwd_ipd_ipm_hdrp_delisted_dd
    where formstatus = '发布'
    and formtype = '再上市'
    and masterDataType = 'productModel'
    and substring(publishtime,1,4) = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y')
)

-- 在最终SELECT的FROM子句中新增LEFT JOIN：
-- left join fuchan_model t_fuchan on t1.PG00061 = t_fuchan.masterDataName
-- （注意：t1对应的别名根据段落而定，冰箱/厨电/激光=t1，空调=t1，视像=t1）


-- =====================================================
-- 二、销售型号编码口径（中央空调日立）：新增CTE模板
-- =====================================================

,fuchan_model as (
    --本年复产型号（销售型号编码口径）
    select distinct mdgno
    from dwd.dwd_ipd_ipm_hdrp_delisted_dd
    where formstatus = '发布'
    and formtype = '再上市'
    and masterDataType = 'salesModel'
    and substring(publishtime,1,4) = DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month) , '%Y')
)

-- 在最终SELECT的FROM子句中新增LEFT JOIN：
-- left join fuchan_model t_fuchan on t1.PG00068 = t_fuchan.mdgno


-- =====================================================
-- 三、各段落 is_project CASE WHEN 修改明细
-- =====================================================

-- -------------------------------------------------------
-- 修改点1：冰箱/冷柜/洗衣机 zhibiao_type='2'
-- -------------------------------------------------------
-- 原文（约第375-377行）：
-- ,case 
-- when t1.PG00025 >= STR_TO_DATE(CONCAT(DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month), '%Y-%m'), '-01'), '%Y-%m-%d') then 'Y'   --本月上市的为第0月  不纳入总数中
-- when t1.shangshi_m <= 3 then 'Y' --上市三个月以后再考核
-- else t1.is_project end as is_project  --是否保护期

-- 改为：
,case 
when t1.PG00025 >= STR_TO_DATE(CONCAT(DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month), '%Y-%m'), '-01'), '%Y-%m-%d') then 'Y'   --本月上市的为第0月  不纳入总数中
when t1.shangshi_m <= 3 then 'Y' --上市三个月以后再考核
when t_fuchan.masterDataName is not null then 'Y'  --本年复产不考核
else t1.is_project end as is_project  --是否保护期

-- LEFT JOIN追加位置（在 left join test.productmodel_xmndxf t4 之后）：
-- left join fuchan_model t_fuchan on t1.PG00061 = t_fuchan.masterDataName

-- CTE追加位置（在 plan_sales CTE的 ) 结束后，select语句之前）：
-- 即在 "group by coalesce (t1.prdct_model ,t2.prdct_model)" 后面的 ")" 之后


-- -------------------------------------------------------
-- 修改点2：视像科技 zhibiao_type='2'
-- -------------------------------------------------------
-- 原文（is_project判定）：
-- ,case 
-- when t1.his_actualtimetomarket >= STR_TO_DATE(CONCAT(DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month), '%Y-%m'), '-01'), '%Y-%m-%d') then 'Y'
-- when t1.title  in (select model_nengxiao from dim.dim_ipd_tv_model_nengxiao_nd) then 'Y'
-- when t1.shangshi_m <= 3 then 'Y'
-- when coalesce(t1.brand,'0')  = 'OEM品牌' then 'Y'
-- else 'N' end as is_project

-- 改为：
,case 
when t1.his_actualtimetomarket >= STR_TO_DATE(CONCAT(DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month), '%Y-%m'), '-01'), '%Y-%m-%d') then 'Y'
when t1.title  in (select model_nengxiao from dim.dim_ipd_tv_model_nengxiao_nd) then 'Y'
when t1.shangshi_m <= 3 then 'Y'
when coalesce(t1.brand,'0')  = 'OEM品牌' then 'Y'
when t_fuchan.masterDataName is not null then 'Y'  --本年复产不考核
else 'N' end as is_project

-- LEFT JOIN追加位置（在 left join 生产版本 t5 之后）：
-- left join fuchan_model t_fuchan on t1.title = t_fuchan.masterDataName

-- CTE追加位置（在 plan_sales CTE 结束后，最终select之前）


-- -------------------------------------------------------
-- 修改点3：空气事业部 家用空调 zhibiao_type='2'（产品型号口径）
-- -------------------------------------------------------
-- 原文（is_project判定）：
-- ,case 
-- when not(PG00025 is not null and HX00501 is null)  then 'Y'
-- when PG00005 = 'OEM品牌' then 'Y'
-- when t1.PG00025 >= STR_TO_DATE(...) then 'Y'
-- when t1.shangshi_m <= 3 then 'Y'
-- when t4.PG00061 is not null then 'Y'  --单元式内外机  有整机的不考核内外机
-- else 'N' end as is_project

-- 改为（在 "when t4.PG00061 is not null then 'Y'" 之后增加）：
-- when t_fuchan.masterDataName is not null then 'Y'  --本年复产不考核

-- LEFT JOIN追加位置（在 left join test.productmodel_xmndxf t5 之后）：
-- left join fuchan_model t_fuchan on t1.PG00061 = t_fuchan.masterDataName

-- CTE追加位置（在 plan_sales CTE 结束后，最终select之前）


-- -------------------------------------------------------
-- 修改点4：厨电 zhibiao_type='2'
-- -------------------------------------------------------
-- 原文（is_project判定）：
-- ,case 
-- when t1.PG00025 >= STR_TO_DATE(...) then 'Y'
-- when t1.shangshi_m <= 3 then 'Y'
-- else t1.is_project end as is_project

-- 改为：
,case 
when t1.PG00025 >= STR_TO_DATE(CONCAT(DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month), '%Y-%m'), '-01'), '%Y-%m-%d') then 'Y'
when t1.shangshi_m <= 3 then 'Y'
when t_fuchan.masterDataName is not null then 'Y'  --本年复产不考核
else t1.is_project end as is_project

-- LEFT JOIN追加位置（在 left join test.productmodel_xmndxf t4 之后）：
-- left join fuchan_model t_fuchan on t1.PG00061 = t_fuchan.masterDataName


-- -------------------------------------------------------
-- 修改点5：激光 zhibiao_type='2'
-- -------------------------------------------------------
-- 原文（is_project判定）：
-- ,case 
--     when t1.his_actualtimetomarket >= STR_TO_DATE(...) then 'Y'
--     when t1.title in (select model_nengxiao from dim.dim_ipd_tv_model_nengxiao_nd) then 'Y'
--     when t1.shangshi_m <= 3 then 'Y'
--     when coalesce(t1.brand,'0') = 'OEM品牌' then 'Y'
--     when t1.his_productsmallcategories = '商用投影' then 'Y'
--     else 'N' end as is_project

-- 改为（在 "when t1.his_productsmallcategories = '商用投影' then 'Y'" 之后增加）：
--     when t_fuchan.masterDataName is not null then 'Y'  --本年复产不考核

-- LEFT JOIN追加位置（在 left join 生产版本 t5 之后）：
-- left join fuchan_model t_fuchan on t1.title = t_fuchan.masterDataName


-- -------------------------------------------------------
-- 修改点6：冰箱/冷柜/洗衣机 zhibiao_type='4'
-- -------------------------------------------------------
-- 原文（is_project判定）：
-- ,case 
-- when t1.PG00025 >= STR_TO_DATE(...) then 'Y'
-- when t1.shangshi_m >= 13 then 'Y'  --去除新品期
-- when t1.shangshi_m <= 3 then 'Y'
-- else t1.is_project end as is_project

-- 改为：
,case 
when t1.PG00025 >= STR_TO_DATE(CONCAT(DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month), '%Y-%m'), '-01'), '%Y-%m-%d') then 'Y'
when t1.shangshi_m >= 13 then 'Y'  --去除新品期
when t1.shangshi_m <= 3 then 'Y'
when t_fuchan.masterDataName is not null then 'Y'  --本年复产不考核
else t1.is_project end as is_project

-- LEFT JOIN追加位置（在 left join test.productmodel_xmndxf t4 之后）：
-- left join fuchan_model t_fuchan on t1.PG00061 = t_fuchan.masterDataName


-- -------------------------------------------------------
-- 修改点7：视像科技 zhibiao_type='4'
-- -------------------------------------------------------
-- 原文（is_project判定）：
-- ,case 
-- when t1.his_actualtimetomarket >= STR_TO_DATE(...) then 'Y'
-- when t1.title  in (select model_nengxiao from dim.dim_ipd_tv_model_nengxiao_nd) then 'Y'
-- when t1.shangshi_m >= 13 then 'Y'  --去除新品期
-- when t1.shangshi_m <= 3 then 'Y'
-- when coalesce(t1.brand,'0')  = 'OEM品牌' then 'Y'
-- else 'N' end as is_project

-- 改为（在 "when coalesce(t1.brand,'0')  = 'OEM品牌' then 'Y'" 之后增加）：
-- when t_fuchan.masterDataName is not null then 'Y'  --本年复产不考核

-- LEFT JOIN追加位置（在 left join 生产版本 t5 之后）：
-- left join fuchan_model t_fuchan on t1.title = t_fuchan.masterDataName


-- -------------------------------------------------------
-- 修改点8：空气事业部 家用空调 zhibiao_type='4'（产品型号口径）
-- -------------------------------------------------------
-- 原文（is_project判定）：
-- ,case 
-- when not(PG00025 is not null and HX00501 is null)  then 'Y'
-- when PG00005 = 'OEM品牌' then 'Y'
-- when t1.PG00025 >= STR_TO_DATE(...) then 'Y'
-- when t1.shangshi_m >= 13 then 'Y'  --去除新品期
-- when t1.shangshi_m <= 3 then 'Y'
-- when t4.PG00061 is not null then 'Y'
-- else 'N' end as is_project

-- 改为（在 "when t4.PG00061 is not null then 'Y'" 之后增加）：
-- when t_fuchan.masterDataName is not null then 'Y'  --本年复产不考核

-- LEFT JOIN追加位置（在 left join test.productmodel_xmndxf t5 之后）：
-- left join fuchan_model t_fuchan on t1.PG00061 = t_fuchan.masterDataName


-- -------------------------------------------------------
-- 修改点9：厨电 zhibiao_type='4'
-- -------------------------------------------------------
-- 原文（is_project判定）：
-- ,case 
-- when t1.PG00025 >= STR_TO_DATE(...) then 'Y'
-- when t1.shangshi_m >= 13 then 'Y'  --超过12个月新品期的不纳入
-- when t1.shangshi_m <= 3 then 'Y'
-- else t1.is_project end as is_project

-- 改为：
,case 
when t1.PG00025 >= STR_TO_DATE(CONCAT(DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month), '%Y-%m'), '-01'), '%Y-%m-%d') then 'Y'
when t1.shangshi_m >= 13 then 'Y'  --超过12个月新品期的不纳入
when t1.shangshi_m <= 3 then 'Y'
when t_fuchan.masterDataName is not null then 'Y'  --本年复产不考核
else t1.is_project end as is_project

-- LEFT JOIN追加位置（在 left join test.productmodel_xmndxf t4 之后）：
-- left join fuchan_model t_fuchan on t1.PG00061 = t_fuchan.masterDataName


-- -------------------------------------------------------
-- 修改点10：激光 zhibiao_type='4'
-- -------------------------------------------------------
-- 原文（is_project判定）：
-- ,case 
--     when t1.his_actualtimetomarket >= STR_TO_DATE(...) then 'Y'
--     when t1.title in (select model_nengxiao from dim.dim_ipd_tv_model_nengxiao_nd) then 'Y'
--     when t1.shangshi_m >= 13 then 'Y'
--     when t1.shangshi_m <= 3 then 'Y'
--     when coalesce(t1.brand,'0') = 'OEM品牌' then 'Y'
--     when t1.his_productsmallcategories = '商用投影' then 'Y'
--     else 'N' end as is_project

-- 改为（在 "when t1.his_productsmallcategories = '商用投影' then 'Y'" 之后增加）：
--     when t_fuchan.masterDataName is not null then 'Y'  --本年复产不考核

-- LEFT JOIN追加位置（在 left join 生产版本 t5 之后）：
-- left join fuchan_model t_fuchan on t1.title = t_fuchan.masterDataName


-- -------------------------------------------------------
-- 修改点11：中央空调日立 zhibiao_type='2'（销售型号编码口径）
-- -------------------------------------------------------
-- 原文（is_project判定，集团逻辑）：
-- ,case 
-- when not(PG00025 is not null and coalesce (t1.HX00501,t1.PG00026) is null) then 'Y'
-- when t1.PG00025 >= STR_TO_DATE(...) then 'Y'
-- when t1.shangshi_m <= 3 then 'Y'
-- else t1.is_project end as is_project

-- 改为：
,case 
when not(PG00025 is not null and coalesce (t1.HX00501,t1.PG00026) is null) then 'Y'
when t1.PG00025 >= STR_TO_DATE(CONCAT(DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month), '%Y-%m'), '-01'), '%Y-%m-%d') then 'Y'
when t1.shangshi_m <= 3 then 'Y'
when t_fuchan.mdgno is not null then 'Y'  --本年复产不考核
else t1.is_project end as is_project

-- 同时修改 is_project_nk（内控口径）：
-- 原文：
-- ,case 
-- when not(PG00025 is not null and coalesce (t1.HX00501,t1.PG00026) is null) then 'Y'
-- when t1.PG00025 >= STR_TO_DATE(...) then 'Y'
-- when t1.shangshi_m <= 3 then 'Y'
-- else t1.is_project_nk end as is_project_nk

-- 改为：
,case 
when not(PG00025 is not null and coalesce (t1.HX00501,t1.PG00026) is null) then 'Y'
when t1.PG00025 >= STR_TO_DATE(CONCAT(DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month), '%Y-%m'), '-01'), '%Y-%m-%d') then 'Y'
when t1.shangshi_m <= 3 then 'Y'
when t_fuchan.mdgno is not null then 'Y'  --本年复产不考核
else t1.is_project_nk end as is_project_nk

-- LEFT JOIN追加位置（在 left join test.salesmodel_xmndxf t4 之后）：
-- left join fuchan_model t_fuchan on t1.PG00068 = t_fuchan.mdgno

-- CTE追加位置（在 plan_sales CTE 结束后，最终select之前）


-- -------------------------------------------------------
-- 修改点12：中央空调日立 zhibiao_type='4'（销售型号编码口径）
-- -------------------------------------------------------
-- 原文（is_project判定，集团逻辑，含新品期限制）：
-- ,case 
-- when not(PG00025 is not null and coalesce(t1.HX00501,t1.PG00026) is null) then 'Y'
-- when t1.PG00025 >= STR_TO_DATE(...) then 'Y'
-- when t1.shangshi_m >= 37 then 'Y'  --超过36个月不算新品
-- when t1.shangshi_m <= 3 then 'Y'
-- else t1.is_project end as is_project

-- 改为：
,case 
when not(PG00025 is not null and coalesce(t1.HX00501,t1.PG00026) is null) then 'Y'
when t1.PG00025 >= STR_TO_DATE(CONCAT(DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month), '%Y-%m'), '-01'), '%Y-%m-%d') then 'Y'
when t1.shangshi_m >= 37 then 'Y'  --超过36个月不算新品
when t1.shangshi_m <= 3 then 'Y'
when t_fuchan.mdgno is not null then 'Y'  --本年复产不考核
else t1.is_project end as is_project

-- 同时修改 is_project_nk（内控口径）：
,case 
when not(PG00025 is not null and coalesce(t1.HX00501,t1.PG00026) is null) then 'Y'
when t1.PG00025 >= STR_TO_DATE(CONCAT(DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month), '%Y-%m'), '-01'), '%Y-%m-%d') then 'Y'
when t1.shangshi_m >= 37 then 'Y'
when t1.shangshi_m <= 3 then 'Y'
when t_fuchan.mdgno is not null then 'Y'  --本年复产不考核
else t1.is_project_nk end as is_project_nk

-- LEFT JOIN追加位置（在 left join test.salesmodel_xmndxf t4 之后）：
-- left join fuchan_model t_fuchan on t1.PG00068 = t_fuchan.mdgno


-- =====================================================
-- 四、注意事项
-- =====================================================
-- 1. 项目口径段落（data_type='项目口径'）不需要修改：
--    它们是从型号口径（data_type='型号口径'）聚合而来，
--    型号口径中已经通过is_project='Y'排除了复产型号，
--    项目口径的WHERE条件包含 "and is_project = 'N'"，
--    所以复产型号自然不会被纳入项目口径统计。
--
-- 2. fuchan_model CTE 在每个独立的 INSERT 段落中都需要定义一次
--    （因为每个DELETE+INSERT是独立的SQL语句）
--
-- 3. 对于中央空调的is_project_nk（内控口径），同样需要加入复产排除逻辑
--
-- 4. publishtime字段：用substring(publishtime,1,4)取年份，
--    与统计年份 DATE_FORMAT(date_sub('${GP_START_DT}',interval 1 month),'%Y') 比对
