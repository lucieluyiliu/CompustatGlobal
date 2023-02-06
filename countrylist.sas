/*This script generates a table of country information for all countries in the FTSE All world indices*/


proc sql;
create table ctry
(ctry char(32),
 iso char(2),
 iso3 char(3),
region char(32),
isem char(2));

 proc sql;
create table common_law
(ctry char(32),
 iso char(2),
 common_law num);


proc sql;
insert into ctry
values('ARGENTINA','AR','ARG','Latin America','EM')
values('AUSTRALIA','AU','AUS','Developed Asia Pacific','DM')
values('AUSTRIA','AT','AUT','Developed Europe','DM')
values('BELGIUM','BE','BEL','Developed Europe','DM')
values('BRAZIL','BR','BRA','Latin America','EM')
values('CANADA','CA','CAN','North America','DM')
values('CHILE','CL','CHL','Latin America','EM')
values('CHINA','CN','CHN','Emerging Asia','EM')
values('COLOMBIA','CO','COL','Latin America','EM')
values('CZECH REPUBLIC','CZ','CZE','Emerging EMEA','EM')
values('DENMARK','DK','DNK','Developed Europe','DM')
values('EGYPT','EG','EGY','Emerging EMEA','EM')
values('FINLAND','FI','FIN','Developed Europe','DM')
values('FRANCE','FR','FRA','Developed Europe','DM')
values('GERMANY','DE','DEU','Developed Europe','DM')
values('GREECE','GR','GRC','Emerging EMEA','EM')
values('HONG KONG','HK','HKG','Developed Asia Pacific','DM')
values('HUNGARY','HU','HUN','Emerging EMEA','EM')
values('INDIA','IN','IND','Emerging Asia','EM')
values('INDONESIA','ID','IDN','Emerging Asia','EM')
values('IRELAND','IE','IRL','Developed Europe','DM')
values('ISRAEL','IL','ISR','Emerging EMEA','DM')
values('ITALY','IT','ITA','Developed Europe','DM')
values('JAPAN','JP','JPN','Developed Asia Pacific','DM')
values('KUWAIT','KW','KWT','Emerging EMEA','EM')
values('LUXEMBOURG','LU','LUX','Developed Europe','DM')
values('MALAYSIA','MY','MYS','Emerging Asia','EM')
values('MEXICO','MX','MEX','Latin America','EM')
values('MOROCCO','MA','MAR','Emerging EMEA','FM')
values('NETHERLANDS','NL','NLD','Developed Europe','DM')
values('NEW ZEALAND','NZ','NZL','Developed Asia Pacific','DM')
values('NORWAY','NO','NOR','Developed Europe','DM')
values('PAKISTAN','PK','PAK','Emerging Asia','EM')
values('PERU','PE','PER','Latin America','FM')
values('PHILIPPINES','PH','PHL','Emerging Asia','EM')
values('POLAND','PL','POL','Emerging EMEA','EM')
values('PORTUGAL','PT','PRT','Developed Europe','DM')
values('QATAR','QA','QAT','Emerging EMEA','EM')
values('ROMANIA','RO','ROU','Emerging EMEA','EM')
values('RUSSIA','RU','RUS','Emerging EMEA','EM')
values('SAUDI ARABIA','SA','SAU','Emerging EMEA','EM')
values('SINGAPORE','SG','SGP','Developed Asia Pacific','DM')
values('SOUTH AFRICA','ZA','ZAF','Emerging EMEA','EM')
values('SOUTH KOREA','KR','KOR','Emerging Asia','EM')
values('SPAIN','ES','ESP','Developed Europe','DM')
values('SWEDEN','SE','SWE','Developed Europe','DM')
values('SWITZERLAND','CH','CHE','Developed Europe','DM')
values('TAIWAN','TW','TWN','Emerging Asia','EM')
values('THAILAND','TH','THA','Emerging Asia','EM')
values('TURKEY','TR','TUR','Emerging EMEA','EM')
values('UNITED ARAB EMIRATES','AE','ARE','Emerging EMEA','EM')
values('UNITED KINGDOM','GB','GBR','Developed Europe','DM')
values('USA','US','USA','North America','DM')
;


proc sql;
insert into common_law
values('AUSTRALIA','AU',1)
values('CANADA','CA',1)
values('HONG KONG','HK',1)
values('INDIA','IN',1)
values('IRELAND','IE',1)
values('ISRAEL','IL',1)
values('KENYA','KE',1)
values('MALAYSIA','MY',1)
values('NEW ZEALAND','NZ',1)
values('NIGERIA','NG',1)
values('PAKISTAN','PK',1)
values('SINGAPORE','SG',1)
values('SOUTH AFRICA','ZA',1)
values('SRI LANKA','LK',1)
values('THAILAND','TH',1)
values('UNITED KINGDOM','GB',1)
values('USA','US',1)
values('ZIMBABWE','ZW',1);




