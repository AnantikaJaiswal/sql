--1. write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends

select top 5 city,sum(amount) as spend ,round((sum(amount)/(select sum(amount) from credit_card_transcations))*100,2) as contribution  
from credit_card_transcations
group by city
order by spend desc

--2.write a query to print highest spend month and amount spent in that month for each card type

with cte as(
select DATEPART(YEAR,transaction_date) as Max_Spend_year,DATEPART(MONTH,transaction_date) as Max_Spend_Month ,card_type,sum(amount) as spend
from credit_card_transcations
group by  DATEPART(YEAR,transaction_date),DATEPART(MONTH,transaction_date),card_type
), cte2 as (
select *,
rank() over(partition by card_type order by spend desc) as rnk
from cte)select * from cte2 where rnk=1 

--3 write a query to print the transaction details(all columns from the table) for each card type when
--it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)
with cte as (select *,
sum(amount) over (partition by card_type order by transaction_date,transaction_id) as rolling_total
from credit_card_transcations)
,cte2 as (
select *,
rank() over (partition by card_type order by rolling_total ) as rank
from cte where rolling_total>=1000000  
 )select * from cte2 where rank=1

 --4 write a query to find city which had lowest percentage spend for gold card type
 with cte as (
 select city,card_type,sum(amount) crd_spend from credit_card_transcations
 group by city,card_type
 ),
 cte2 as(
 select city, sum(amount) as total_spend 
 from credit_card_transcations 
 group by city
 )
 select top 1 cte.city,card_type,round((crd_spend/total_spend)*100,2)  as per
 from cte inner join  cte2 on cte.city=cte2.city
 where card_type='Gold' 
 order by per asc
 

 --5 write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)
 with cte as (
 select city city,exp_type exp_type,sum(amount) amt,
 rank() over (partition by city order by sum(amount) desc) as hrnk ,
 rank() over (partition by city order by sum(amount) asc) as lrnk 
 from credit_card_transcations
 group by city,exp_type
 )select
city , max(case when hrnk=1 then exp_type end) as highest_exp_type
, min(case when lrnk=1 then exp_type end) as lowest_exp_type
from cte 
group by city;

--6  write a query to find percentage contribution of spends by females for each expense type

select exp_type,(sum(amount)/sum(case when gender='F' then amount end))*100 as female_spends
from credit_card_transcations
group by exp_type;
 
 --7 which card and expense type combination saw highest month over month growth in Jan-2014
 with cte as (
 select DATEPART(year,transaction_date) as year,DATEPART(month,transaction_date) as month,card_type,exp_type, sum(amount) amt
 from credit_card_transcations
 group by card_type,exp_type,DATEPART(year,transaction_date),DATEPART(month,transaction_date)
 ), cte2 as(
 select * ,
 lag(amt) over (partition by card_type,exp_type order by year,month) as prev_amt
 from cte 
 )select top 1 *, amt-prev_amt as month_on_mnth_growth from cte2
 where month='1' and year='2014'
 order by month_on_mnth_growth desc

 --8 during weekends which city has highest total spend to total no of transcations ratio 
select top 1 city,sum(amount)/count(transaction_id) as ratio 
from credit_card_transcations
where DATEPART(WEEKDAY,transaction_date) in ('1','7')
group by city
order by ratio desc
 ;


 --9 which city took least number of days to reach its 500th transaction after the first transaction in that city
 with cte as(
 select  city,transaction_date ,
 ROW_NUMBER() over (partition by city order by transaction_id,transaction_date ) as rn
 from credit_card_transcations
 )
 select top 1 city,datediff(day,min(transaction_date),max(transaction_date)) as daydiff
 from cte 
 where rn=1 or rn=500
 group by city
 having count(1)=2
 order by daydiff