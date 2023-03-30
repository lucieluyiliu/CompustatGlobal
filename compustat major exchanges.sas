/*This SAS script finds the major exchange of each country */
/*Manually corrected some countries with multiple major exchanges, see Chaieb Langlois and Scaillet (2021, JFE)*/

/*major exchange is defined as the stock exchange with the higest number of stocks listed.*/

/* proc contents data=compd.r_ex_codes; run; */

/*can one exchange be in different countries?*/
/*exchg 150: Spanish Fixed Income Market*/
/* proc sql; */
/* create table exchangecountries as  */
/* select count(distinct excntry) as nctry, exchg */
/* from home.compustat_selected  */
/* group by exchg */
/* order by calculated nctry desc; */
/*  */
/*  */
/* proc sql; create table AIAF as select * from home.compustat_selected where exchg=150; */
/*  */
/* proc sql; select * from compd.r_ex_codes where exchgcd=150; */
/*  */
/* proc sql; select * from compd.r_ex_codes where exchgcd=19; */

proc sql;
create table home.majorexchange as 
select count(*) as nstocks, a.exchg,excntry, exchgdesc
from
(
select distinct gvkey,iid, exchg,excntry from home.compustat_selected) a, compd.r_ex_codes b 
where exchg not in (150, 19) /*remove 	ESDAQ LISTING*/
and a.exchg=b.exchgcd
and exchgdesc not contain "OTC"
group by  excntry,exchg, exchgdesc
order by excntry,calculated nstocks desc;


proc sql;
create table home.exchangemap as 
select a.exchgcd,b.excntry,
a.exchgdesc, c.iso,
case when b.nstocks eq nmax then 1 else 0 end as ismajor
from compd.r_ex_codes a, (select *, max(nstocks) as nmax from home.majorexchange group by excntry)  b ,ctry c
where a.exchgcd=b.exchg
and b.excntry=c.iso3
order by iso; 
quit;

/*update dual major exchanges*/
proc sql;
update home.exchangemap
set ismajor=1 
where exchgdesc="Rio de Janeiro";
proc sql;
update home.exchangemap
set ismajor=1
where exchgdesc="TSX Venture Exchange";
proc sql;
update home.exchangemap
set ismajor=1
where exchgdesc="Shanghai Stock Exchange";
proc sql;
update home.exchangemap
set ismajor=1
where exchgdesc="Paris";
proc sql;
update home.exchangemap
set ismajor=1
where exchgdesc="National Stock Exchange of India";
proc sql;
update home.exchangemap
set ismajor=1
where exchgdesc="Osaka Securities Exchange";
proc sql;
update home.exchangemap
set ismajor=1
where exchgdesc="MICEX Stock Exchange";
proc sql;
update home.exchangemap
set ismajor=1
where exchgdesc="Korea Exchange Stock Market";
proc sql;
update home.exchangemap
set ismajor=1
where exchgdesc="Zurich";
proc sql;
update home.exchangemap
set ismajor=1
where exchgdesc="Dubai Financial Market";
proc sql;
update home.exchangemap
set ismajor=1
where exchgdesc="NYSEArca";
proc sql;
update home.exchangemap
set ismajor=1
where exchgdesc="New York Stock Exchange";
proc sql;
update home.exchangemap
set ismajor=1
where exchgdesc="Nasdaq Stock Market";
proc sql;
update home.exchangemap
set ismajor=1
where exchgdesc="NYSE American";








