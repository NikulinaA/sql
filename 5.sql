select case when PAY_GROUP_CODE='2' then null else PAY_GROUP_CODE end PAY_GROUP_CODE,case when PAY_GROUP_CODE='2' then null else PAY_GROUP_NAME end PAY_GROUP_NAME
      ,LEVEL_1,NAME_1,LEVEL_2,NAME_2
      ,LEVEL_3 ,NAME_3
      ,org_id
      ,name
    --  ,sum("Сумма лимит на аванс") "Сумма лимит на аванс"
   ,case when  PAY_GROUP_CODE <>'2' and @prompt('5.Лимит на аванс:', 'A', {'Верхний уровень', 'В разрезе подстатей'},MONO,CONSTRAINED)='Верхний уровень'
   then null
   when  PAY_GROUP_CODE <>'2' and @prompt('5.Лимит на аванс:', 'A', {'Верхний уровень', 'В разрезе подстатей'},MONO,CONSTRAINED)='В разрезе подстатей'
   then  sum("Сумма лимит на аванс") 
    end  "Сумма лимит на аванс" 
  
    ,sum("Сумма лимит на аванс 1 уровень") "Сумма лимит на аванс 1 уровень"
   
    ,case when @prompt('5.Лимит на аванс:', 'A', {'Верхний уровень', 'В разрезе подстатей'},MONO,CONSTRAINED)='Верхний уровень'
   then sum("Сумма лимит на аванс 1 уровень")
     else sum("Сумма лимит на аванс без 1") 
   end  "Сумма лимит на аванс_об"
      ,"Месяц"  
 ,to_char(to_date("Месяц",'mon-yyyy'),'YYYY')GG
      ,to_char(to_date("Месяц",'mon-yyyy'),'mm')s
   --   ,case when @prompt('5.Лимит на аванс:', 'A', {'Верхний уровень', 'В разрезе подстатей'},MONO,CONSTRAINED)='Верхний уровень'
 --     then '1'
 --     else '2'
  --    end  status
 
from
(
select distinct PAY_GROUP_CODE,PAY_GROUP_NAME
      ,pp_1.LEVEL_1,pp_1.NAME_1,pp_2.LEVEL_2,pp_2.NAME_2
      ,NVL(pp_3.LEVEL_3,pp_2.LEVEL_2)LEVEL_3 ,nvl(pp_3.NAME_3,pp_2.NAME_2)NAME_3
      ,o.org_id
      ,o.name
      ,XXFIN.XXFIN_EQ_CARDS.CALCULATE_LIMIT_ADV_MONTH(o.org_id, 
                                   PAY_GROUP_CODE, 
                                   TRUNC(TO_DATE(LIMIT_PERIOD, 'MON-YYYY'), 'MONTH')  ) "Сумма лимит на аванс"

     ,case when PAY_GROUP_CODE=pp_1.LEVEL_1 then XXFIN.XXFIN_EQ_CARDS.CALCULATE_LIMIT_ADV_MONTH(o.org_id, 
                                   PAY_GROUP_CODE, 
                                   TRUNC(TO_DATE(LIMIT_PERIOD, 'MON-YYYY'), 'MONTH')  )   end "Сумма лимит на аванс 1 уровень"       
      ,case when PAY_GROUP_CODE<>pp_1.LEVEL_1 then XXFIN.XXFIN_EQ_CARDS.CALCULATE_LIMIT_ADV_MONTH(o.org_id, 
                                   PAY_GROUP_CODE, 
                                   TRUNC(TO_DATE(LIMIT_PERIOD, 'MON-YYYY'), 'MONTH')  )   end "Сумма лимит на аванс без 1"                                   
      ,LIMIT_PERIOD "Месяц"  
FROM   XXFIN.XXFIN_EQ_LIMIT_HEAD_ADVANCE H
           ,XXFIN.XXFIN_EQ_LIMIT_LINES_ADVANCE L
   , ( SELECT distinct PAY_GROUP_NAME NAME_2,pay_group_code LEVEL_2
      FROM (SELECT LEVEL level_mmk, pg.pay_group_id, pg.pay_group_code, pg.pay_group_name
             FROM xxfin.xxfin_eq_pay_groups pg
             WHERE NVL (pg.active_flag, 'Y') = 'Y'
             CONNECT BY PRIOR pg.pay_group_id = pg.parent_pay_group_id
             START WITH pg.parent_pay_group_id IS NULL
           ) pp,
     xxfin.xxfin_eq_orgs org
     WHERE NVL (org.active_flag, 'Y') = 'Y'
     and LEVEL_MMK=2
        )pp_2, 
      ( SELECT distinct PAY_GROUP_NAME NAME_3,pay_group_code LEVEL_3
      FROM (SELECT LEVEL level_mmk, pg.pay_group_id, pg.pay_group_code, pg.pay_group_name
             FROM xxfin.xxfin_eq_pay_groups pg
             WHERE NVL (pg.active_flag, 'Y') = 'Y'
             CONNECT BY PRIOR pg.pay_group_id = pg.parent_pay_group_id
             START WITH pg.parent_pay_group_id IS NULL
           ) pp,
     xxfin.xxfin_eq_orgs org
     WHERE NVL (org.active_flag, 'Y') = 'Y'
     and LEVEL_MMK=3
        )pp_3
,( SELECT distinct PAY_GROUP_NAME NAME_1,pay_group_code LEVEL_1
      FROM (SELECT LEVEL level_mmk, pg.pay_group_id, pg.pay_group_code, pg.pay_group_name
             FROM xxfin.xxfin_eq_pay_groups pg
             WHERE NVL (pg.active_flag, 'Y') = 'Y'
             CONNECT BY PRIOR pg.pay_group_id = pg.parent_pay_group_id
             START WITH pg.parent_pay_group_id IS NULL
           ) pp,
     xxfin.xxfin_eq_orgs org
     WHERE NVL (org.active_flag, 'Y') = 'Y'
     and LEVEL_MMK=1
        )pp_1
        ,xxfin.xxfin_eq_orgs o
        ,xxfin.xxfin_orgs org
       
      where  H.LIMIT_HEAD_ADVANCE_ID = L.LIMIT_HEAD_ADVANCE_ID
           AND H.STATUS = 'APPROVED'  
           AND pp_1.LEVEL_1(+)=SUBSTR(PAY_GROUP_CODE,1,1)
           AND pp_2.LEVEL_2(+)=SUBSTR(PAY_GROUP_CODE,1,3)
           AND pp_3.LEVEL_3(+)=SUBSTR(PAY_GROUP_CODE,1,5)
           AND org.org_id=o.org_id
           AND h.org_id=o.org_id
           AND org.KAZNA='Y'
           AND SUBSTR(PAY_GROUP_CODE,1,1)='2'
            and (
           (TO_DATE(LIMIT_PERIOD, 'MON-YYYY')  BETWEEN TO_DATE(@variable('1.2 Дата с:'),'dd.mm.yyyy') AND TO_DATE(@variable('1.3 Дата по:'),'dd.mm.yyyy') and @variable('1.3 Дата по:')<>'%' )
                       or @variable('1.3 Дата по:')='%'
                       )
           and (CASE WHEN ('Все' in @variable('2.Общество Группы ОАО ММК:')) THEN 'Все' ELSE  o.NAME END) IN @variable('2.Общество Группы ОАО ММК:')
         and xxfin.Xxfin_Do_Secure (@variable('BOUSER'),o.ORG_ID)=1 
          and @prompt('1.1 Дата сегодняшняя?:', 'A', {'Да','Нет'},MONO,CONSTRAINED)='Нет'    
         
      union all
      
  select distinct PAY_GROUP_CODE,PAY_GROUP_NAME
      ,pp_1.LEVEL_1,pp_1.NAME_1,pp_2.LEVEL_2,pp_2.NAME_2
      ,NVL(pp_3.LEVEL_3,pp_2.LEVEL_2)LEVEL_3 ,nvl(pp_3.NAME_3,pp_2.NAME_2)NAME_3
      ,o.org_id
      ,o.name
      ,XXFIN.XXFIN_EQ_CARDS.CALCULATE_LIMIT_ADV_MONTH(o.org_id, 
                                   PAY_GROUP_CODE, 
                                   trunc(sysdate) ) "Сумма лимит на аванс"
        ,case when PAY_GROUP_CODE=pp_1.LEVEL_1 then XXFIN.XXFIN_EQ_CARDS.CALCULATE_LIMIT_ADV_MONTH(o.org_id, 
                                   PAY_GROUP_CODE, 
                                   trunc(sysdate) )   end "Сумма лимит на аванс 1 уровень"       
        ,case when PAY_GROUP_CODE<>pp_1.LEVEL_1 then XXFIN.XXFIN_EQ_CARDS.CALCULATE_LIMIT_ADV_MONTH(o.org_id, 
                                   PAY_GROUP_CODE, 
                                   TRUNC(TO_DATE(LIMIT_PERIOD, 'MON-YYYY'), 'MONTH')  )   end "Сумма лимит на аванс без 1"                                 
       ,LIMIT_PERIOD "Месяц"  
FROM    XXFIN.XXFIN_EQ_LIMIT_HEAD_ADVANCE H
           ,XXFIN.XXFIN_EQ_LIMIT_LINES_ADVANCE L
,( SELECT distinct PAY_GROUP_NAME NAME_2,pay_group_code LEVEL_2
      FROM (SELECT LEVEL level_mmk, pg.pay_group_id, pg.pay_group_code, pg.pay_group_name
             FROM xxfin.xxfin_eq_pay_groups pg
             WHERE NVL (pg.active_flag, 'Y') = 'Y'
             CONNECT BY PRIOR pg.pay_group_id = pg.parent_pay_group_id
             START WITH pg.parent_pay_group_id IS NULL
           ) pp,
     xxfin.xxfin_eq_orgs org
     WHERE NVL (org.active_flag, 'Y') = 'Y'
     and LEVEL_MMK=2
        )pp_2, 
      ( SELECT distinct PAY_GROUP_NAME NAME_3,pay_group_code LEVEL_3
      FROM (SELECT LEVEL level_mmk, pg.pay_group_id, pg.pay_group_code, pg.pay_group_name
             FROM xxfin.xxfin_eq_pay_groups pg
             WHERE NVL (pg.active_flag, 'Y') = 'Y'
             CONNECT BY PRIOR pg.pay_group_id = pg.parent_pay_group_id
             START WITH pg.parent_pay_group_id IS NULL
           ) pp,
     xxfin.xxfin_eq_orgs org
     WHERE NVL (org.active_flag, 'Y') = 'Y'
     and LEVEL_MMK=3
        )pp_3
,( SELECT distinct PAY_GROUP_NAME NAME_1,pay_group_code LEVEL_1
      FROM (SELECT LEVEL level_mmk, pg.pay_group_id, pg.pay_group_code, pg.pay_group_name
             FROM xxfin.xxfin_eq_pay_groups pg
             WHERE NVL (pg.active_flag, 'Y') = 'Y'
             CONNECT BY PRIOR pg.pay_group_id = pg.parent_pay_group_id
             START WITH pg.parent_pay_group_id IS NULL
           ) pp,
     xxfin.xxfin_eq_orgs org
     WHERE NVL (org.active_flag, 'Y') = 'Y'
     and LEVEL_MMK=1
        )pp_1
       ,xxfin.xxfin_eq_orgs o
        ,xxfin.xxfin_orgs org
       
      where  H.LIMIT_HEAD_ADVANCE_ID = L.LIMIT_HEAD_ADVANCE_ID
           AND H.STATUS = 'APPROVED'    
           AND pp_1.LEVEL_1(+)=SUBSTR(PAY_GROUP_CODE,1,1)
           AND pp_2.LEVEL_2(+)=SUBSTR(PAY_GROUP_CODE,1,3)
           AND pp_3.LEVEL_3(+)=SUBSTR(PAY_GROUP_CODE,1,5)
           AND org.org_id=o.org_id
           AND h.org_id=o.org_id
           AND SUBSTR(PAY_GROUP_CODE,1,1)='2'
           AND org.KAZNA='Y'
           and to_char(to_date(h.LIMIT_PERIOD,'mon-yyyy'),'dd.mm.yyyy') =trunc(sysdate,'mm')
           and (CASE WHEN ('Все' in @variable('2.Общество Группы ОАО ММК:')) THEN 'Все' ELSE  o.NAME END) IN @variable('2.Общество Группы ОАО ММК:')
          and xxfin.Xxfin_Do_Secure (@variable('BOUSER'),o.ORG_ID)=1 
          and @prompt('1.1 Дата сегодняшняя?:', 'A', {'Да','Нет'},MONO,CONSTRAINED)='Да'      
          
          )
          group by PAY_GROUP_CODE,PAY_GROUP_NAME
                      ,LEVEL_1,NAME_1,LEVEL_2,NAME_2
                      ,LEVEL_3 ,NAME_3 ,org_id ,"Месяц"  
      ,name
          having case when @prompt('3. Показывать строки с нулевыми лимитами?:', 'A', {'Да','Нет'},MONO,CONSTRAINED)='Нет' then sum("Сумма лимит на аванс")   end     <> 0
          or case when @prompt('3. Показывать строки с нулевыми лимитами?:', 'A', {'Да','Нет'},MONO,CONSTRAINED)='Да' then sum("Сумма лимит на аванс")     end >= 0       
      
       
