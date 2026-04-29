create view new_events as
select *,
case
	when promo_type in ('50% OFF','BOGOF') then base_price*50/100
	when promo_type='25% OFF' then base_price*75/100
	when promo_type='33% OFF' then base_price*67/100
	when promo_type='500 Cashback' then base_price-500
	else base_price
end as price_after_promo
from fact_events
--created a view for query convenience

--Products which has a base_price > 500 and promo type 'BOGOF'
select product_name
from fact_events e
left join dim_products p on p.product_code=e.product_code
where base_price>500 and promo_type='BOGOF'
group by product_name

--city wise store count in desc order
select city,count(store_id) as total_stores
from dim_stores
group by city
order by total_stores desc

--Calculate total revenue for all campaigns and display revenue in millions
select campaign_id,
sum(cast(base_price as bigint)*quantity_sold_before_promo)/1000000 as before,
sum(cast(price_after_promo as bigint)*quantity_sold_after_promo)/1000000 as after
from new_events
group by campaign_id

--find category-wise ISU% for Diwali campaign and rank desc
select category,(sum(quantity_sold_after_promo)-sum(quantity_sold_before_promo))*1.0/sum(quantity_sold_before_promo)*100 as ISU_percent
from fact_events e
left join dim_products p on p.product_code=e.product_code
where campaign_id='CAMP_DIW_01'
group by category
order by ISU_percent desc

--find the top 5 products in all campaign which has highest Incremental Revenue Percentage (IR%).
with cte as(
select campaign_id,product_name,
(sum(cast(price_after_promo as bigint)*quantity_sold_after_promo)-sum(cast(base_price as bigint)*quantity_sold_before_promo))*1.0/
sum(cast(base_price as bigint)*quantity_sold_before_promo)*100 as IR_percent
from new_events e
left join dim_products p on p.product_code=e.product_code
group by campaign_id,product_name 
),cte1 as(
select *, RANK() over(partition by campaign_id order by IR_percent desc) as IR_rank
from cte
)
select *
from cte1
where IR_rank<=5