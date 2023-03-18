
select * from information_schema.columns where table_name = 'payment_scenario';
select * from information_schema.columns where table_name = 'payment_status';
select * from information_schema.columns where table_name = 'payment_trans';
--MỤC TIÊU PHÂN TÍCH CỦA BÀI TOÁN
--Phân khúc khách hàng active trong hệ thống, đưa ra tên phân khúc và số lượng khách hàng tương ứng
--Phương pháp luận để phân khúc khách hàng: recency, frequency, monetary

--KHẢO SÁT DỮ LIỆU
select count (*) from payment_scenario;-- có tất cả 348 trường hợp giao dịch
select count (distinct scenario_id) from payment_scenario;
select * from payment_scenario
where sub_category = 'not payment';
select count (*) from payment_scenario
where sub_category = 'not payment';
select * from payment_scenario
where not transaction_type = 'payment';


select sub_category, count (scenario_id) slgd
from payment_scenario
group by sub_category
order by slgd desc;
--
select * from payment_status;
select count (*) from payment_status;-- có tất cả 15 trạng thái giao dịch
select count (distinct status_id) from payment_status;
--
select top 100* from payment_trans;
select max (transaction_time) from payment_trans;
select distinct transaction_time
from payment_trans
order by transaction_time;-- bảng chi tiết giao dịch từ ngày 1/1/2019 - 25/2/2019
select count (*) from payment_trans;-- có tất cả 39755 giao dịch
select count (distinct customer_id) from payment_trans;-- có 9567 khách hàng thực hiện giao dịch

----  Lấy các khách hàng có giao dịch thành công và thực sự thực hiện giao dịch mua hàng hóa
select * from payment_trans
where scenario_id = 'S1_12';
select * from payment_trans
where customer_id = 23844;
select * from payment_scenario
where scenario_id = 'S1_13';
----
with retail_active as
	(Select customer_id, a.scenario_id, a.status_id, charged_amount, status_description, transaction_type, sub_category, category, SUBSTRING(transaction_time,1,10) as tran_time
	from
	(select customer_id, scenario_id, status_id, charged_amount, transaction_time from payment_trans ) a
	left join
	(select* from payment_status) b
	on a.status_id = b.status_id
	inner join 
	(select * from payment_scenario) c
	on c.scenario_id = a.scenario_id
	where not sub_category = 'not payment' and a.status_id = 1)
,rfm as-- tính chỉ số rfm cho từng khách hàng
	(select customer_id,
	datediff(day, max(tran_time),'2019-04-30') recency,
	count (distinct tran_time) frequency,
	sum (charged_amount) monetary
	from retail_active
	group by customer_id)
, rfm_percent_rank as--quy gia tri rfm thanh dai gia tri [0;1] 
	(select *,
	percent_rank() over (order by recency desc) r_percent_rank,
	percent_rank() over (order by frequency ) f_percent_rank,
	percent_rank() over (order by monetary ) m_percent_rank
	from rfm )
,rfm_group as--chia nhom r,f,m_percent theo tu phan vi
(select customer_id, r_percent_rank, f_percent_rank, m_percent_rank,
case when r_percent_rank >=0.75 then 1
	when r_percent_rank >=0.5 then 2
	when r_percent_rank >=0.25 then 3
	else 4
	end r_group,
case when f_percent_rank >=0.75 then 1
	when f_percent_rank >=0.5 then 2
	when f_percent_rank >=0.25 then 3
	else 4
	end f_group,
case when m_percent_rank >=0.75 then 1
	when m_percent_rank >=0.5 then 2
	when m_percent_rank >=0.25 then 3
	else 4
	end m_group
from rfm_percent_rank)
,rfm_score as--concat nhom r,f,m
(select customer_id, r_group, f_group, m_group,
concat (r_group, f_group, m_group) as rfm_score from rfm_group)
,rfm_segment as--đặt tên cho từng phân khúc khách hàng
(select customer_id, rfm_score,
case when rfm_score = 111 then 'khach hang tot nhat'
	when rfm_score like '[1-3][1-3]1' then 'khach hang chi tieu lon'
	when rfm_score like '1[1-2][2-4]'then 'khach hang than thiet'
	when rfm_score like '[1-2]4[1-4]' then 'khach hang moi'
	when rfm_score like '3[1-2][1-2]' then 'nguy co mat khach hang'
	when rfm_score like '4[1-2][1-2]'  then 'khach hang da mat'
	when rfm_score like '[3-4][3-4][3-4]' then 'khach hang khong tiem nang' 
	else 'khach hang trung thanh tiem nang'
        end customer_segment
from rfm_score)
select  customer_segment, count (customer_id) slkh from rfm_segment
group by customer_segment
order by count (customer_id) desc;







