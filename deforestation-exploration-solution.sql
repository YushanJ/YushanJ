 /* create forestation view */
DROP VIEW IF EXISTS forestation;
CREATE VIEW forestation AS
SELECT F.country_name, F.country_code, 
	   F.year, F.forest_area_sqkm FAKM,
       L.total_area_sq_mi Total_mi, 
       R.region, R.income_group,
       (F.forest_area_sqkm/(L.total_area_sq_mi * 2.59)) * 100
                            as Percent_KM
FROM forest_area F
Join land_area L
On F.country_code = L.country_code and 
   F.country_name = L.country_name and 
   F.year = L.year
left Join regions R
On R.country_name = F.country_name and
   R.country_code = F.country_code;

select *
from forestation
order by country_name;

/* 1. Global Situation */

select *
from forest_area
Where country_name = 'World' 
      and (year = '2016' or year = '1990');
/* 2016: 39958245.9   
   1990: 41282694.9 */
                            
with Y1 as (select *
            from forest_area
            where year = '2016' and country_name = 'World'),
     Y2 as (select *
            from forest_area
            where year = '1990' and country_name = 'World')
select (Y2.forest_area_sqkm-Y1.forest_area_sqkm) as difference,       ((Y2.forest_area_sqkm- Y1.forest_area_sqkm)/
        Y2.forest_area_sqkm)*100 as Per_loss
from Y1
join Y2
on Y1.country_name = Y2.country_name;
/* difference = 1324449
	Percentage = 3.20824258980244_% */

select country_name, year,
	   (total_area_sq_mi * 2.59) as Total_km
from land_area
where year = '2016' and (total_area_sq_mi * 2.59) > 1000000
order by 3;
/* 1279999.9891 - Peru*/

/* 2. REGIONAL OUTLOOK */

select country_name, region, year, percent_km
from forestation
where (year = '2016' or year = '1990')
		and country_name = 'World'
order by percent_km desc;
/* world: 2016: 31.38% 
		  1990: 32.42%*/
         
select country_name, region, year, percent_km
from forestation
where year = '2016'
order by percent_km desc;                             
	               
select region, year, 
	   round(cast((forest/land)*100 AS NUMERIC),2) as per_for
from
(
select region, year, sum(fakm)Forest, sum(total_mi*2.59)Land
from forestation
group by 1,2) sub

where (year = '2016' or year = '1990')
group by 1,2,3
order by 2,3 desc;

/* Region					1990 Percent	2016 Percent
Latin America & Caribbean	51.03			46.16
Europe & Central Asia		41.17			38.04
North America 				37.29			36.04
Sub-Suharan Africa			30.65			28.72
East Asia & Pacific			25.57			26.29
South Asia					16.51			17.51
Middle East & North Africa	1.78			2.07  */

/* 3. COUNTRY-LEVEL DETAIL */

select f1.country_name, r.region,
	   (f1.forest_area_sqkm - f2.forest_area_sqkm) as Decrease,
       round(cast(((f1.forest_area_sqkm - f2.forest_area_sqkm) 				/f1.forest_area_sqkm)*100 As Numeric),2) as Decrease_Percentage
from forest_area f1
join forest_area f2
on f1.year = '1990' and f2.year = '2016'
	and f1.country_name = f2.country_name
join regions r
on r.country_name = f1.country_name
order by 3, 4 desc; 
/* Top 5 decrease 
Country			Region				Absolute Forest Area Change
Brazil		Latin America & Caribbean	541510
Indonesia	East Asia & Pacific			282193.9844
Myanmar		East Asia & Pacific			107234.0039
Nigeria		Sub-Saharan Africa			106506.00098
Tanzania	Sub-Saharan Africa			102320
	Top 5 pct decrease
Country			Region				Pct Forest Area Change
Togo		Sub-Saharan Africa			75.45%
Nigeria		Sub-Saharan Africa			61.80%
Uganda		Sub-Saharan Africa			59.13%
Mauritania	Sub-Saharan Africa			46.75%
Honduras	Latin America & Caribbean	45.03%	*/

select quartiles, count(quartiles)
from (
select country_name, year, percent_km,
	case when percent_km >= 75 then '75-100'
    	 when percent_km between 50 and 75 then '50-75'
         when percent_km between 25 and 50 then '25-50'
         else '0-25' end as quartiles
from forestation ) sub
where percent_km IS NOT NULL and year = '2016'
group by 1
order by 2;

/* Quartile		Number of Countries
	0-25			85
	25-50			73
	50-75			38
	75-100			9     	*/
    
select percent_km, region, country_name
from forestation
where percent_km IS NOT NULL and year = '2016'
		and percent_km >= 75
order by 1 desc;

/* 	Country			Region					Pct Designated as Forest
	Suriname	Latin America & Caribbean		98.26
	Micronesia	East Asia & Pacific				91.85
	Gabon		Sub-Saharan Africa				90.04
	Seychelles	Sub-Saharan Africa				88.41
	Palau		East Asia & Pacific				87.61
American Samoa		East Asia & Pacific			87.50
	Guyana		Latin America & Caribbean		83.91
	Lao PDR		East Asia & Pacific				82.11
Solomon Islands		East Asia & Pacific			77.86		*/

/* How many countries had a percent forestation higher than the United States in 2016? */

select count(country_name)
from forestation
where year = '2016' and 
	percent_km > (
                  select percent_km
                  from forestation
                  where year = '2016' and 
                  country_name = 'United States'
    			  and percent_km is not null) 
 
 /* there are 94 countries that had a percent forestation higher than the United States in 2016 */ 
