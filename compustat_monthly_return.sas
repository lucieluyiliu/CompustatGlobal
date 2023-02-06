libname home '/scratch/mcgill/yiliulu/jmp/'; /*User-specified folder for temporary data  */
%include '/home/mcgill/yiliulu/countrylist.sas';  /*Auxiliary file that contains country information*/
%let bdate=input('01/01/1994', mmddyy10.);
%let edate=input('12/31/2021', mmddyy10.);
%let exportfolder=/scratch/mcgill/yiliulu/jmp/;  /*macro for exporting location*/

/*This script calculated monthly USD return, book-to-market ratio and dividend yield for the Compustat Global universe*/
/*Lucie Lu: yiliu.lu@mail.mcgill.ca */
/*Last update: 2023-02-06*/


/*retrieval of compustat universe*/

/*name filter a la Griffin(2010), Lee (2011)*/
data namefilter;
	infile '/home/mcgill/yiliulu/IO-CELu/namefilter.csv' delimiter=',' missover 
		DSD lrecl=32767 firstobs=2;
	informat keyword $32.;
	format keyword $32.;
	INPUT keyword$;
run;

/*import exchange information*/
data exchangemap;
	infile '/home/mcgill/yiliulu/exchangemap.csv' delimiter=',' missover DSD 
		lrecl=32767 firstobs=2;
	informat exchgcd best32.;
	informat iso $2.;
	informat excntry $3.;
	informat exchgdesc $40.;
	informat ismajor best12.;
	format exchgcd best12.;
	format iso$2.;
	format excntry $3.;
	format exchgdesc $40.;
	format ismajor best12.;
	INPUT exchgcd$
iso$
excntry$
exchgdesc$ 
ismajor;
run;

proc sql;
	create table compustat_selected as select a.gvkey, a.iid, d.sic, d.fic, d.loc, 
		a.sedol, a.isin, cusip, a.dsci, conml, a.excntry, exchg, a.tic format=$8., 
		case when a.dsci contains b.keyword then 1 else 0 end as namefilter 
		from (select * from compd.g_security a1 union select * from compd.security 
		a2) a, namefilter b, exchangemap c, (select d1.gvkey, d1.sic, d1.loc, d1.fic, 
		conml from compd.company d1 union select d2.gvkey, d2.sic, d2.loc, d2.fic, 
		d2.conml from compd.g_company d2) d where a.exchg=c.exchgcd and c.ismajor=1 
		and tpci in ('0', 'F') /*common share or depository recript*/
		and a.gvkey=d.gvkey;

	/*and (input(sic,16.) >6999 or input(sic,16.) <6000); */
	/*optional exclude financial firms*/
quit;

/*temporary for name filter*/
proc sql;
	create table tmp as select gvkey, iid, sic, fic, loc, sedol, isin, cusip, 
		dsci, conml, excntry, exchg, tic, sum(namefilter) as namesum
		from 
		compustat_selected group by gvkey, iid, sic, fic, loc, sedol, isin, cusip, 
		dsci, conml, excntry, exchg having calculated namesum=0;
quit;

/* proc sql; */
/* 	create table compustat_selected as select gvkey, iid, sic, fic, loc, sedol,  */
/* 		isin, cusip, dsci, conml, ctry, tic, case when loc=excntry then 1 else 0 end  */
/* 		as islocal, exchg, excntry from tmp a, ctry b where a.excntry=b.iso3; */
		
proc sql;
	create table compustat_selected as select gvkey, iid, sic, fic, loc, sedol, iso,
		isin, cusip, dsci, conml, ctry, tic, case when loc=excntry then 1 else 0 end 
		as islocal, exchg, excntry from tmp a, ctry b where a.loc=b.iso3;

proc sort data=compustat_selected nodupkeys;
	by gvkey iid;
run;

proc sql;
	create table home.compustat_selected as select * from compustat_selected;

proc export data=home.compustat_selected 
		outfile="&exportfolder.compustat_securities.csv" replace;
run;

proc sql;
create table home.firmctry as 
select distinct gvkey, ctry, iso from home.compustat_selected ;

proc sql;
create table nb_firms_ctry as 
select count(distinct gvkey) as nfirms, ctry from home.compustat_selected
group by ctry;

/*return data*/
/*North American stocks*/
/*NA stocks use report number of shares outstanding*/
proc sql;
	create table cshoi as select a.gvkey, a.iid, a.datadate, b.cshoi, b.datadate 
		as choidate from compd.secd a, compd.sec_afnd b, (select c.gvkey, c.iid, 
		c.datadate, max(d.datadate) as maxdate from compd.secd c, compd.sec_afnd d 
		where c.datadate >d.datadate and c.iid=d.iid and c.gvkey=d.gvkey group by 
		c.gvkey, c.iid, c.datadate) m where a.gvkey=b.gvkey and a.iid=b.iid and 
		b.datadate=m.maxdate and a.datadate=m.datadate and a.iid=m.iid and 
		a.gvkey=m.gvkey;

/*ajexdi is adjustment for splits, trfd adjusts for dividend, when its missing you can either substitue 1 or remove the observation*/
proc sql;
	create table totalreturnd as select a.gvkey, a.iid, a.datadate, a.curcdd, 
		a.prccd/(case when a.ajexdi is null or ajexdi=0 then . else a.ajexdi 
		end)*(case when trfd is not null then trfd else 1 end) /b.exratd*c.exratd as 
		riusd, a.prccd*d.cshoi*1000000/b.exratd*c.exratd as issuemvusd from 
		compd.secd a, compd.exrt_dly b, compd.exrt_dly c, cshoi d where prcstd in (3, 
		10, 4) and a.datadate=b.datadate and a.curcdd=b.tocurd and 
		a.datadate=c.datadate and c.tocurd='USD' and a.datadate=d.datadate and 
		a.gvkey=d.gvkey and a.iid=d.iid
		/*market capitalization do not divide by ajexdi!*/
		union all select a1.gvkey, a1.iid, a1.datadate, a1.curcdd, 
		a1.prccd/a1.qunit/(case when a1.ajexdi is null or ajexdi=0 then 1 else 
		a1.ajexdi end)*case when trfd is not null then trfd else 1 end 
		/b1.exratd*c1.exratd/a1.qunit as riusd, 
		a1.prccd*a1.cshoc/b1.exratd*c1.exratd/a1.qunit as issuemvusd from 
		compd.g_secd a1, compd.exrt_dly b1, compd.exrt_dly c1 where prcstd in (3, 10) 
		and a1.datadate=b1.datadate and a1.curcdd=b1.tocurd and 
		a1.datadate=c1.datadate and c1.tocurd='USD';
quit;

proc sql; create table home.totalreturnd as select * from totalreturnd;

/*keep one security using sec_history primary security information*/

proc sql;
	create table security as select * from compd.security union all select * from 
		compd.g_security;
quit;


		
/*select primary security*/		
proc sql;
create table sec_history as
select * from compd.sec_history 
union all
select * from compd.g_sec_history;



proc sql;
create table returnd_selected as
select a.gvkey,a.iid,
datadate, 
riusd,
issuemvusd 
/* case when loc in ("CAN", "USA") then cat("PRIHIST",loc) else "PRIHISTROW" end as majorflag */
from totalreturnd a , compustat_selected b 
where a.gvkey=b.gvkey
and a.iid=b.iid;

proc sql; select count(*) from returnd_selected;


/*keep major security*/
proc sql;
create table returnd_selected as
select a.gvkey,a.iid,
datadate, 
riusd,
issuemvusd,
case when b.itemvalue =a.iid then 1 else 0 end as ismajor
from returnd_selected a left join sec_history b 
on (a.gvkey=b.gvkey
and a.iid=b.iid
and a.datadate between b.effdate and case when b.thrudate is not null then b.thrudate else input('01/01/3000',mmddyy10.) end
and substr(b.item,1,7)='PRIHIST')
where calculated ismajor=1;

/* proc sql; */
/* select count(*) from returnd_selected0 where gvkey not in (select gvkey from sec_history); */

/*number of nonmajor securities*/
/*  proc sql; select count(*) from returnd_selected a left join sec_history b  */
/*  on (a.gvkey=b.gvkey and a.iid=b.iid */
/*  and substr(b.item,1,7)='PRIHIST')  */
/*  where b.gvkey is null;  */
 
/*  proc sql; */
/*  select * from sec_history where gvkey='025365' and substr(item,1,7)='PRIHIST'; */
/*   */
/*  proc sql; */
/*  create table return025365 as select *  */
/*  from returnd_selected  */
/*  where gvkey='025365' */
/*  order by datadate, iid; */
/*   */
/*  proc sql; select * from home.compustat_selected where gvkey='025365'; */


proc sort data=returnd_selected;
by gvkey iid datadate;
run;

proc sql; create table home.returnd_selected as select * from returnd_selected;


/*in the case of multiple major securities, only keep one*/		
/* proc sort data=returnd_selected nodupkey; */
/* 	by gvkey datadate; */
/* run; */

/*adjust for delisting return*/
data returnd_selected;
	set returnd_selected;
	by gvkey;
	rank+1;

	if first.gvkey or first.iid then
		rank=1;
run;

proc sql;
	create table home.returndusd as 
(select b.gvkey, b.iid, riusd, issuemvusd, datadate from returnd_selected b 
		left join security c on(b.gvkey=c.gvkey and b.iid=c.iid and dlrsni in ('02', 
		'03') and b.datadate=c.dldtei) where c.gvkey is null)/*no delist*/
		union 
(select a.gvkey, a.iid, b.riusd*0.7 as riusd, a.issuemvusd, a.datadate from 
		returnd_selected a, returnd_selected b, security c where a.gvkey=b.gvkey and 
		a.iid=b.iid and b.gvkey=c.gvkey and b.iid=c.iid and a.datadate=c.dldtei and 
		c.dlrsni in ('02', '03') and b.rank=a.rank-1);
quit;

/*book to market*/
data comp_extract;
	set comp.funda 
   (where=(fyr>0 and at>0 and consol='C' and indfmt='INDL' and datafmt='STD' 
		and popsrc='D'));

	if missing(SEQ)=0 then
		she=SEQ;
	else if missing(CEQ)=0 and missing(PSTK)=0 then
		she=CEQ+PSTK;
	else if missing(AT)=0 and missing(LT)=0 and missing(MIB)=0 then
		she=AT-(LT+MIB);
	else
		she=.;

	if missing(PSTKR)=0 then
		BE0=she-PSTKR;
	else if missing(PSTKL)=0 then
		BE0=she-PSTKL;
	else if missing(PSTK)=0 then
		BE0=she-PSTK;
	else
		BE0=.;
	* Converts fiscal year into calendar year data;

	if (1<=fyr<=5) then
		date_fyend=intnx('month', mdy(fyr, 1, fyear+1), 0, 'end');

	/*if fisical year ends in the first half end of year is end of year fyear+1*/
	else if (6<=fyr<=12) then
		date_fyend=intnx('month', mdy(fyr, 1, fyear), 0, 'end');

	/*if fisical year ends in the second half, end of year is end of fisical year*/
	calyear=year(date_fyend);

	/*end of calendar year*/
	format date_fyend date9.;
	* Accounting data since calendar year bdate-1 to year edate-1;

	if (year(date_fyend) >=year(&bdate) - 1) and (year(date_fyend) <=year(&edate) 
		+ 1);
	keep gvkey calyear fyr BE0 date_fyend indfmt consol datafmt popsrc datadate 
		TXDITC curcd;
run;
/*some companies have duplicate because they report twice each year*/
/* proc sql; create table duplicate as  */
/* select count(*) as n,  */
/* gvkey, calyear */
/* from comp_extract  */
/* group by gvkey, calyear */
/* order by n desc; */
/*  */
/* proc sql; */
/* create table test as  */
/* select * */
/* from comp_extract where gvkey="176975"; */


proc sort data=comp_extract nodupkey; by gvkey calyear; run;


proc sql;
	create table comp_extract as select a.gvkey, a.calyear, a.fyr, a.date_fyend, 
		curcd, case when missing(TXDITC)=0 and missing(PRBA)=0 then BE0+TXDITC-PRBA 
		else BE0 end as BE from comp_extract as a left join 
		comp.aco_pnfnda (keep=gvkey indfmt consol datafmt popsrc datadate prba) as b 
		on a.gvkey=b.gvkey and a.indfmt=b.indfmt and a.consol=b.consol and 
		a.datafmt=b.datafmt and a.popsrc=b.popsrc and a.datadate=b.datadate;
quit;

proc sql;
	create table bookvalue_usd as select gvkey, BE/b.exratd*c.exratd as BEusd, 
		date_fyend, a.calyear from comp_extract a, compd.exrt_dly b, compd.exrt_dly c 
		where a.date_fyend=b.datadate and a.curcd=b.tocurd and b.datadate=c.datadate 
		and c.tocurd='USD';

data g_comp_extract;
	set comp.g_funda 
   (where=(fyr>0 and at>0 and consol='C' and indfmt='INDL' and 
		datafmt='HIST_STD'));

	if missing(SEQ)=0 then
		she=SEQ;
	else if missing(CEQ)=0 and missing(PSTK)=0 then
		she=CEQ+PSTK;
	else if missing(AT)=0 and missing(LT)=0 and missing(MIB)=0 then
		she=AT-(LT+MIB);
	else
		she=.;

	if missing(PSTKR)=0 then
		BE0=she-PSTKR;
	else if missing(PSTK)=0 then
		BE0=she-PSTK;
	else
		BE0=.;
	* Converts fiscal year into calendar year data;

	if (1<=fyr<=5) then
		date_fyend=intnx('month', mdy(fyr, 1, fyear+1), 0, 'end');
	else if (6<=fyr<=12) then
		date_fyend=intnx('month', mdy(fyr, 1, fyear), 0, 'end');
	calyear=year(date_fyend);
	format date_fyend date9.;
	* Accounting data since calendar year 't-1';

	if (year(date_fyend) >=year(&bdate) - 1) and (year(date_fyend) <=year(&edate) 
		+ 1);
	keep gvkey calyear fyr BE0 date_fyend indfmt consol datafmt popsrc datadate 
		TXDITC curcd;
run;

proc sort data=g_comp_extract nodupkey; by gvkey calyear; run;


proc sql;
	create table g_comp_extract as select a.gvkey, a.calyear, a.fyr, a.date_fyend, 
		curcd, case when missing(TXDITC)=0 and missing(PRBA)=0 then BE0+TXDITC-PRBA 
		else BE0 end as BE 
		from g_comp_extract as a left join 
		comp.aco_pnfnda (keep=gvkey indfmt consol datafmt popsrc datadate prba) as b 
		on a.gvkey=b.gvkey and a.indfmt=b.indfmt and a.consol=b.consol and 
		a.datafmt=b.datafmt and a.popsrc=b.popsrc and a.datadate=b.datadate;
quit;

proc sql;
	create table g_bookvalue_usd as select gvkey, BE/b.exratd*c.exratd as BEusd, 
		date_fyend, a.calyear from g_comp_extract a, compd.exrt_dly b, compd.exrt_dly 
		c where a.date_fyend=b.datadate and a.curcd=b.tocurd and 
		b.datadate=c.datadate and c.tocurd='USD';

proc sql;
	create table home.bookvalue_usd as select * from bookvalue_usd union all corr 
		select * from g_bookvalue_usd;

proc sort data=home.bookvalue_usd nodupkey; by gvkey calyear; run;

/* proc sql; */
/* create table duplicate as  */
/* select gvkey, calyear, count(*) as n  */
/* from home.bookvalue_usd  */
/* group by gvkey, calyear  */
/* order by n desc; */
/*  */
/* proc sql; */
/* create table test as */
/* select SEQ, CEQ,PSTK,AT,LT, MIB, 'NA' as source,  fyear from comp.funda */
/* where gvkey="325211" */
/* and ceq is not null */
/* union all corr */
/* select SEQ, CEQ,PSTK,AT,LT, MIB, 'global' as source, fyear from comp.g_funda  */
/* where gvkey="325211" */
/* and ceq is not null */
/* order by fyear, source; */


proc sql;
	/*create bm ratio at december each year*/
	create table BM0	(where=(BM>0)) as select a.gvkey, a.calyear, 
		a.BEusd*1000000/issuemvusd as BM, b.datadate as decdate, BEusd, issuemvusd 
		from home.bookvalue_usd as a, home.returndusd as b, (select max(datadate) as maxdate, 
		year(datadate) as year, gvkey from home.returndusd group by gvkey, calculated 
		year) c
		/*last market value at december*/
		where a.gvkey=b.gvkey and b.gvkey=c.gvkey and a.calyear=c.year and 
		issuemvusd>0 and b.datadate=maxdate;
quit;

proc sort data=bm0 nodupkey;
	by gvkey calyear;
run;

proc sql;
create table junedates as 
select 
		gvkey, max(datadate) format yymmdd. as maxdate, month(datadate) as month, year(datadate) as 
		year from home.returndusd where calculated month=6 group by calculated year, 
		gvkey, month;


proc sql;
	create table BM as select a.gvkey, a.calyear, a.BM, decdate, b.datadate as 
		date, b.issuemvusd as size, d.iso from BM0 a, home.returndusd as b, junedates c, 
		home.firmctry d
		where a.gvkey=b.gvkey and 
		b.gvkey=c.gvkey and b.datadate=c.maxdate and a.calyear=c.year-1 and 
		b.issuemvusd>0 and d.gvkey=a.gvkey;



proc sort data=bm nodupkey;
	by gvkey calyear;
run;

proc sql;
	create table home.BM as select * from BM;

proc univariate data=home.bm noprint;
	var bm;
	output out=bmcutoff pctlpts=99 pctlpre=pctl;
run;

proc univariate data=home.bm;
	var bm;
	histogram bm;
run;

proc sql;
	update home.bm set bm=. where bm>(select pctl99 from bmcutoff);
	
/*monthly bm and monthlydy*/

/*monthly returns*/

/*monthly dividend yield*/
proc sql;
create table home.annual_dividend as 
select gvkey, iid, year(datadate) as year, sum(div) as div
from comp.g_secd 

group by gvkey, iid, calculated year
union all 
select gvkey, iid, year(datadate) as year, sum(div) as div
from comp.secd
group by gvkey, iid, calculated year;

/*if dividend is null over the year set it to 0*/
proc sql;
update home.annual_dividend 
set div=0
where div is null;


proc sql; 
create table home.endofmonth
as select gvkey,iid, year(datadate)*100+month(datadate) as yyyymm,
max(datadate)  format=mmddyy10. as maxdate
from comp.secd
group by gvkey,iid, calculated yyyymm
union all 
select gvkey,iid, year(datadate)*100+month(datadate) as yyyymm,
max(datadate)  format=mmddyy10. as maxdate
from comp.g_secd
group by gvkey, iid, calculated yyyymm;


proc sort data=home.endofmonth nodupkey; by gvkey iid yyyymm;run;
 
proc sql;
create table test as
select * 
from home.endofmonth where gvkey='001076';

proc sql;
create table monthlyprice as 
select a.gvkey,a.iid, prccd as price, yyyymm
from comp.secd a, home.endofmonth b
where a.gvkey=b.gvkey
and a.iid=b.iid
and a.datadate=b.maxdate
and year(a.datadate) ge 1995

union all

select c.gvkey,c.iid, prccd as price,
yyyymm
from comp.g_secd c, home.endofmonth d
where c.gvkey=d.gvkey
and c.iid=d.iid
and c.datadate=d.maxdate
and year(c.datadate) ge 1995;

/* proc sql; */
/* create table monthlyprice as  */
/* select a.gvkey, prccd as price, yyyymm, datadate, maxdate */
/* from comp.secd a, endofmonth b */
/* where a.gvkey=b.gvkey */
/* and c.iid=d.iid */
/* and a.datadate=b.maxdate; */


/*iid level*/
proc sql;
create table home.monthlydy as 
select a.gvkey, a.iid, yyyymm, div/price as dy
from monthlyprice a, home.annual_dividend b 
where a.gvkey=b.gvkey 
and a.iid=b.iid
and floor(yyyymm/100)=year;

proc sort data=home.monthlydy nodupkey; by gvkey iid yyyymm; run;


proc sql;
create table home.totalreturnm as 
select riusd,issuemvusd,gvkey,iid,
datadate, month(datadate)+year(datadate)*100 as yyyymm, max(datadate) format mmddyy10. as maxdate
from home.returndusd
group by gvkey,calculated yyyymm
having datadate=calculated maxdate
order by datadate,gvkey;
quit;

proc sql;
create table home.monthlyreturn as 
select /*count(*) as nweeklyobs,*/
a.gvkey,
a.iid,
a.riusd/b.riusd-1-rf as ret,
b.issuemvusd as mv,
a.datadate as datadate,
a.yyyymm,
b.datadate as lastdate,   /*realized return at time t-1*/
d.iso
from home.totalreturnm a, home.totalreturnm b, ff.factors_monthly c, home.firmctry d

where intck('month',b.datadate,a.datadate)=1
and year(b.datadate)=year(c.date)
and year(a.datadate) ge 1994
and month(b.datadate)=month(c.date)
and a.gvkey=b.gvkey
and a.gvkey=d.gvkey
and a.iid=b.iid
and a.riusd is not null 
and b.riusd is not null
and b.issuemvusd is not null
and calculated ret is not null
order by a.gvkey,a.datadate;


/*check what has been eliminated due to cross-listing*/
/* proc sql; */
/* create table test as select * from home.totalreturnm */
/* where gvkey='001441'; */
/*  */
/* proc sql; */
/* create table test as select * from home.monthlyreturn */
/* where gvkey='001441'; */

/* proc sql; select * from sec_history where gvkey='001076'; */


proc sort data=home.monthlyreturn nodupkey; by gvkey yyyymm; run;


/*apply filter to remove extreme returns*/
data home.monthlyreturn;
	set home.monthlyreturn;

	if abs(ret) ge 2 then
		ret=.;
		
    if ret le -1 then
		ret=.;

	if (abs(lag(ret))>1 or abs(ret)>1 and 
		abs((1+lag(ret))*(1+ret)-1)<0.2) then
			ret=.;
run;

proc sort data=home.monthlyreturn; by yyyymm iso; run;


proc sql; select max(ret) from home.monthlyreturn;

/*winsorize monthly return no?*/
proc univariate data=home.monthlyreturn noprint;
 var ret;
 by yyyymm iso;
 output out=monthlyreturn_cutoff pctlpts=1 99 pctlpre=pctl;
run;

proc sql;
select * from monthlyreturn_cutoff where iso='US'
order by pctl99 desc;

proc sql;
create table winsorize as
select max(pctl99) as maxcutoff , iso 
from monthlyreturn_cutoff
group by iso;

proc sql;
create table home.monthlyreturn as 
select
a.gvkey, iid, mv, a.yyyymm, datadate, a.iso,
 case when a.ret ge pctl1 and a.ret le pctl99 then a.ret 
when a.ret < pctl1 then pctl1 
when a.ret >pctl99 then pctl99 end as ret
from home.monthlyreturn a, monthlyreturn_cutoff b
where a.yyyymm=b.yyyymm
and a.iso=b.iso;

/* proc sql; */
/* create table maxret as select max(ret) as maxret from home.monthlyreturn; */
/*  */
/* proc sql; */
/* create table abnormalreturn as  */
/* select * */
/* from home.monthlyreturn a, maxret b, monthlyreturn_cutoff c */
/* where ret=maxret */
/* and a.iso=c.iso */
/* and a.yyyymm=c.yyyymm; */


proc sql;
create table home.monthlybm as 
select a.gvkey, yyyymm, BEusd*1000000/mv as BM

from home.bookvalue_usd a, home.monthlyreturn b
where a.gvkey=b.gvkey 
and a.calyear=floor(b.yyyymm/100)-1
and BEusd>0; /*previous year book value monthly bm ratio*/


/*winsorize bm*/
proc univariate data=home.monthlybm noprint;
	var bm;
	output out=bmcutoff pctlpts=1 99 pctlpre=pctl;
run;

proc sql;
	update home.monthlybm set bm=. where bm>(select pctl99 from bmcutoff);
/* 	proc sql; */
/* 	update home.monthlybm set bm=. where bm<(select pctl1 from bmcutoff); */

proc univariate data=home.monthlybm;
var bm;
histogram;
run;	


/*winsorize dy*/
proc univariate data=home.monthlydy noprint;
	var dy;
	output out=dycutoff pctlpts=1 99 pctlpre=pctl;
run;

proc sql;
	update home.monthlydy set dy=. where dy>(select pctl99 from dycutoff);
/* 	proc sql; */
/* 	update home.monthlybm set bm=. where bm<(select pctl1 from bmcutoff); */

proc univariate data=home.monthlybm;
var bm;
histogram;
run;	


proc univariate data=home.monthlydy;
var dy;
histogram;
run;	




