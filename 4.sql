select /* EQ177.Контроль договоров  Сагдеев 244182*/ 
        kaz.org_id,
        kaz.name,

        kaz.contract_id,
        kaz.contract_num,
        kaz.DEPARTMENT,
        kaz.RESPONSIBLE,

        kaz.contract_num            kaz_contract_num,
        kaz.STATUS_CONTRAGENT       kaz_STATUS_CONTRAGENT,
        kaz.START_DATE              kaz_START_DATE,
        kaz.END_DATE                kaz_END_DATE,
        kaz.inn                     kaz_inn,
        kaz.kpp                     kaz_kpp,
        kaz.CNAME                   kaz_CNAME,
        kaz.CURRENCY_CODE           kaz_CURRENCY_CODE,
        kaz.FORMULA_DATE_LIABILITY  kaz_FORMULA_DATE_LIABILITY,
        kaz.bank                    kaz_bank,
        kaz.BANK_ACCOUNT_NUM        kaz_BANK_ACCOUNT_NUM,
        kaz.INN_OTHER               kaz_INN_OTHER,
        kaz.KPP_OTHER               kaz_KPP_OTHER,
        kaz.bank_other              kaz_bank_other,
        kaz.BANK_ACCOUNT_NUM_OTHER  kaz_BANK_ACCOUNT_NUM_OTHER,
        kaz.NAME_OTHER              kaz_NAME_OTHER,

        kis.kis_contract_num        kis_CONTRACT_NUM,
        kis.STS_CODE                kis_STATUS_CONTRAGENT,
        kis.START_DATE              kis_START_DATE,
        kis.END_DATE                kis_END_DATE,
        kis.INN                     kis_inn,
        kis.kpp                     kis_kpp,
        kis.PARTY_NAME_KA           kis_CNAME,
        kis.CURRENCY_CODE           kis_CURRENCY_CODE,
        kis.USL_OPLAT               kis_FORMULA_DATE_LIABILITY,
        kis.BANK_NAME               kis_bank,
        kis.BANK_ACCOUNT_NUM        kis_BANK_ACCOUNT_NUM,
        kis.PAYEE_INN               kis_INN_OTHER,
        kis.PAYEE_kpp               kis_KPP_OTHER,
        kis.PAYEE_BANK_NAME         kis_bank_other,
        kis.PAYEE_BANK_ACCOUNT_NUM  kis_BANK_ACCOUNT_NUM_OTHER,

        kaz.KIND_CONTRACT           kaz_KIND_CONTRACT,

        CASE WHEN nvl(kis.sts_code,'%') in ('Активно', 'Просрочено')
              AND nvl(kaz.START_DATE,'01.01.1900')   = nvl(kis.START_DATE,'01.01.1900')
              AND nvl(kaz.END_DATE,'01.01.1900')     = nvl(kis.END_DATE,'01.01.1900')
              AND nvl(kaz.inn,'%')                   = nvl(kis.inn,'%')
              AND nvl(kaz.kpp,'%')                   = nvl(kis.kpp,'%')
              AND nvl(kaz.CURRENCY_CODE,'%')         = nvl(kis.CURRENCY_CODE,'%')
              AND nvl(kaz.FORMULA_DATE_LIABILITY,'%')= nvl(kis.USL_OPLAT,'%')
              AND nvl(kaz.bank,'%')                  = nvl(kis.BANK_NAME,'%')
              AND nvl(kaz.BANK_ACCOUNT_NUM,'%')      = nvl(kis.BANK_ACCOUNT_NUM,'%')
              AND nvl(kaz.INN_OTHER,'%')             = nvl(kis.PAYEE_INN,'%')
              AND nvl(kaz.KPP_OTHER,'%')             = nvl(kis.PAYEE_kpp,'%')
              AND nvl(kaz.bank_other,'%')            = nvl(kis.PAYEE_BANK_NAME,'%')
              AND nvl(kaz.BANK_ACCOUNT_NUM_OTHER,'%')= nvl(kis.PAYEE_BANK_ACCOUNT_NUM,'%')
             THEN 0 ELSE 1 END ERR_FLAG,

            kaz.TYPE_CONTRAGENT kaz_TYPE_CONTRAGENT

  from (select cg.CNAME,
               ct.CURRENCY_CODE,             
               cgo.CNAME NAME_OTHER,
               ct.contract_id,
               ct.contract_num,
               cg.inn, 
               cg.kpp,
               ct.BANK_ACCOUNT_NUM,
               CT.INN_OTHER,
               CGO.KPP KPP_OTHER,
               CT.BANK_ACCOUNT_NUM_OTHER,
               ct.FORMULA_DATE_LIABILITY,
               cg.org_id,
               O.NAME,
               CT.START_DATE,
               CT.END_DATE,
               DEPARTMENT,
               RESPONSIBLE,
               decode(cg.STATUS_CONTRAGENT,
                      null, 'ПУСТО',
                     'HOLD','Заблокировано',
                     'CANCELLED','Отменено',
                     'TERMINATED','Прекращено',
                     'ACTIVE','Активно',
                     cg.STATUS_CONTRAGENT) STATUS_CONTRAGENT,
             --  (select B.BANK_NAME from AP.AP_BANK_BRANCHES b where B.BANK_BRANCH_ID = CT.BANK_BRANCH_ID) bank,
             --  (select B.BANK_NAME from AP.AP_BANK_BRANCHES b where B.BANK_BRANCH_ID = CT.BANK_BRANCH_ID_OTHER) bank_other,
                 (select B.BANK_BRANCH_NAME from  apps.ce_bank_branches_v b where  B.BRANCH_PARTY_ID = CT.BANK_BRANCH_ID ) bank,
                  (select B.BANK_BRANCH_NAME from  apps.ce_bank_branches_v b where  B.BRANCH_PARTY_ID = CT.BANK_BRANCH_ID_OTHER) bank_other, 

  decode (ct.KIND_CONTRACT, 'IN', 'Входящий',
                                         'IN_NO_CONTRACT', 'Вх.Без договора',
                                         'OUT', 'Исходящий',
                                         'OUT_NO_CONTRACT', 'Исх.Без договора',
                                         ct.KIND_CONTRACT) KIND_CONTRACT,
               cg.TYPE_CONTRAGENT
          from xxfin.xxfin_do_contragents cg,
               xxfin.xxfin_do_contragents cgo,
               xxfin.xxfin_do_contracts ct,
               xxfin.xxfin_eq_orgs o
         where cg.contragent_id = CT.CONTRAGENT_ID
           and o.org_id = cg.org_id
           and CGO.CONTRAGENT_ID (+) = CT.ID_CONTRAGENT_OTHER 
           
       ) kaz,
         (select dog.org_id, dog.kis_contract_num, dog.contract_number, st.meaning sts_code, dog.start_date, dog.end_date, dog.currency_code, dog.USL_OPLAT,
               dog.partner_party_name PARTY_NAME_KA, dog.partner_inn inn, dog.partner_kpp kpp,
               --cgn.BANK_NAME, cgn.BANK_ACCOUNT_NUM,
               (select max(BANK_NAME) from xxokc.xxokc_do_bank_partner_v where dnz_chr_id = dog.id ) BANK_NAME, --03062022 max   select * from xxokc.xxokc_do_bank_payee_v where dnz_chr_id = 1645188
               (select max(BANK_ACCOUNT_NUM) from xxokc.xxokc_do_bank_partner_v where dnz_chr_id = dog.id ) BANK_ACCOUNT_NUM, --03062022 max   select * from xxokc.xxokc_do_bank_payee_v where dnz_chr_id = 1645188
               dog.payee_party_name, dog.payee_inn, dog.payee_kpp, 
               --oth.PAYEE_BANK_NAME, oth.PAYEE_BANK_ACCOUNT_NUM
               (select max(PAYEE_BANK_NAME) from xxokc.xxokc_do_bank_payee_v where dnz_chr_id = dog.id) PAYEE_BANK_NAME , --03062022 max   select * from xxokc.xxokc_do_bank_payee_v where dnz_chr_id = 1645188
               (select max(PAYEE_BANK_ACCOUNT_NUM) from xxokc.xxokc_do_bank_payee_v where dnz_chr_id = dog.id) PAYEE_BANK_ACCOUNT_NUM --03062022 max   select * from xxokc.xxokc_do_bank_payee_v where dnz_chr_id = 1645188
          from (SELECT org_id, contract_number kis_contract_num, contract_number, sts_code, start_date, end_date, currency_code, USL_OPLAT, id
                      ,partner_party_name, partner_inn, partner_kpp, payee_party_name, payee_inn, payee_kpp
                 FROM xxokc.xxokc_do_contract_status_v
               union all
               (SELECT org_id, contract_number kis_contract_num, old_contract_number, sts_code, start_date, end_date, currency_code, USL_OPLAT, id
                      ,partner_party_name, partner_inn, partner_kpp, payee_party_name, payee_inn, payee_kpp
                 FROM xxokc.xxokc_do_contract_status_v dcs
                where old_contract_number is not null
               MINUS
               SELECT org_id, contract_number kis_contract_num, contract_number, sts_code, start_date, end_date, currency_code, USL_OPLAT, id
                      ,partner_party_name, partner_inn, partner_kpp, payee_party_name, payee_inn, payee_kpp
                 FROM xxokc.xxokc_do_contract_status_v)              
               ) dog,
               apps.fnd_lookup_values_vl st, --#R12 --apps.okc_statuses_tl st,
               --xxokc.xxokc_do_bank_partner_v cgn,
               --xxokc.xxokc_do_bank_payee_v oth,
               xxfin.xxfin_eq_orgs o
        where 1=1
          and st.lookup_code = dog.sts_code --#R12 --dog.sts_code=st.code(+)      
          and st.lookup_type = 'OKC_REP_CONTRACT_STATUSES' --#R12 --st.language = 'RU'
          --and cgn.dnz_chr_id (+) = dog.id ------------------------------- привязка контрагента
          --and oth.dnz_chr_id (+) = dog.id
          
          and o.org_id = dog.org_id
          
          and contract_number like @variable('3. Договор:')
          and contract_number not like @variable('3. Исключая Договоры: (маска)')

          and (CASE WHEN ('Все' = @variable('2. Общество:')) THEN 'Все' ELSE o.NAME end) = @variable('2. Общество:')
          and dog.partner_inn like @variable( '7. ИНН (% все):')
          and dog.partner_party_name not like @variable( '8. Исключая контрагентов (маска)')         
       )kis
where kaz.org_id = kis.org_id (+)
  and kaz.contract_num = kis.contract_number (+) 
  and xxfin.Xxfin_Do_Secure (@variable('BOUSER'),kaz.ORG_ID)=1 
  and 1 = apps.xxmmk_set_bo_param(@variable('BOUSER'), 'EQ177.Контроль договоров')     
--  @prompt( '3. Только не прошедшие контроль', 'A',{'Да','Нет, все'}, mono, constrained ) -- фильтрами в отчете  

UNION ALL

select /* EQ177.Контроль договоров  Сагдеев 244182*/ 
        null org_id,
        null name,
        null contract_id,
        null contract_num,
        null DEPARTMENT,
        null RESPONSIBLE,
        null kaz_contract_num,
        null kaz_STATUS_CONTRAGENT,
        null kaz_START_DATE,
        null kaz_END_DATE,
        null kaz_inn,
        null kaz_kpp,
        null kaz_CNAME,
        null kaz_CURRENCY_CODE,
        null kaz_FORMULA_DATE_LIABILITY,
        null kaz_bank,
        null kaz_BANK_ACCOUNT_NUM,
        null kaz_INN_OTHER,
        null kaz_KPP_OTHER,
        null kaz_bank_other,
        null kaz_BANK_ACCOUNT_NUM_OTHER,
        null kaz_NAME_OTHER,
        null kis_CONTRACT_NUM,
        null kis_STATUS_CONTRAGENT,
        null kis_START_DATE,
        null kis_END_DATE,
        null kis_inn,
        null kis_kpp,
        null kis_CNAME,
        null kis_CURRENCY_CODE,
        null kis_FORMULA_DATE_LIABILITY,
        null kis_bank,
        null kis_BANK_ACCOUNT_NUM,
        null kis_INN_OTHER,
        null kis_KPP_OTHER,
        null kis_bank_other,
        null kis_BANK_ACCOUNT_NUM_OTHER,
        null kaz_KIND_CONTRACT,
        null ERR_FLAG,
        null kaz_TYPE_CONTRAGENT
from dual

