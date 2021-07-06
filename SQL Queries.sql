Final Sqls

————USERS————
copy users_json from '/home/datafiles/users.json';

create table users_json(values text);    

drop table users;
create table users as (
select  userid,active,to_timestamp(createdDate::numeric/1000) createdDate,
to_timestamp(lastLogin::numeric/1000)  lastLogin,userRole,signUpSource,state
from ( select
    values::json -> '_id'->> '$oid' userId,
    values::json -> 'active' active,
       values::json ->'createdDate' ->>'$date' createdDate,
 values::json ->'lastLogin' ->>'$date' lastLogin,
 values::json ->>'role' userRole,
  values::json ->>'signUpSource'  signUpSource,
  values::json ->>'state' state
  from users_json ) a);
  
ALTER TABLE public.users ALTER COLUMN userid SET NOT NULL;

select * from users;

————BRANDS————

 create table brands_json(values text);    
copy brands_json from '/home/datafiles/brands.json';

create table brands as (
select  brandId,barcode,category,categoryCode,cpgId,cpgRef,brandName,topBrand
from ( select
    values::json -> '_id'->> '$oid' brandId,
    values::json ->> 'barcode' barcode,
values::json ->>'category' category,
 values::json ->>'categoryCode' categoryCode,
  values::json ->'cpg'->'$id' ->>'$oid' cpgId,
    values::json ->'cpg' ->>'$ref' cpgRef,
  values::json ->>'name'  brandName,
  values::json ->'topBrand' topBrand
  from brands_json ) a);
 

ALTER TABLE public.brands ALTER COLUMN brandid SET NOT NULL;
ALTER TABLE public.brands ALTER COLUMN barcode SET NOT NULL;
ALTER TABLE public.users ALTER COLUMN createddate SET NOT NULL;
ALTER TABLE public.users ALTER COLUMN userrole SET NOT NULL;


—————RECEIPTS————

create table receipts_json(values text); 

copy receipts_json from '/home/datafiles/receipts.json';



create table receipts_transactions as (
select  receiptId,bonusPointsEarned,bonusPointsEarnedReason
,to_timestamp(createdate::numeric/1000) createdate ,to_timestamp(dateScanned::numeric/1000) dateScanned,to_timestamp(finishedDate::numeric/1000) finishedDate,to_timestamp(modifyDate::numeric/1000)  modifyDate,
to_timestamp(pointsAwardedDate::numeric/1000)  pointsAwardedDate
,pointsEarned,to_timestamp(purchaseDate::numeric/1000)  purchaseDate,purchasedItemCount,rewardsReceiptStatus,totalSpent,userId from ( select
    values::json -> '_id'->> '$oid' receiptId,
    values::json ->'bonusPointsEarned' bonusPointsEarned,
    values::json ->>'bonusPointsEarnedReason' bonusPointsEarnedReason,
    values::json ->'createDate' ->>'$date' createDate,
    values::json ->'dateScanned' ->>'$date' dateScanned,
    values::json ->'finishedDate' ->>'$date' finishedDate,
    values::json ->'modifyDate' ->>'$date' modifyDate,
    values::json ->'pointsAwardedDate' ->>'$date' pointsAwardedDate,
    values::json ->> 'pointsEarned' pointsEarned,
    values::json ->'purchaseDate' ->>'$date' purchaseDate,
    values::json -> 'purchasedItemCount' purchasedItemCount,
    values::json ->> 'rewardsReceiptStatus' rewardsReceiptStatus,
    values::json ->> 'totalSpent' totalSpent,
    values::json ->> 'userId' userId
from receipts_json ) a);


ALTER TABLE public.receipts_transactions ALTER COLUMN receiptid SET NOT NULL;
ALTER TABLE public.receipts_transactions ALTER COLUMN createdate SET NOT NULL;
ALTER TABLE public.receipts_transactions ALTER COLUMN datescanned SET NOT NULL;
ALTER TABLE public.receipts_transactions ALTER COLUMN userid SET NOT NULL;


create table items_purchased as (
 select  receiptId,json_array_elements(items::json)::json ->>'barcode' barcode,
    json_array_elements(items::json)::json ->>'description' description,
    json_array_elements(items::json)::json ->>'finalPrice' finalPrice,
    json_array_elements(items::json)::json ->>'itemPrice' itemPrice,
    json_array_elements(items::json)::json ->>'needsFetchReview' needsFetchReview,
    json_array_elements(items::json)::json  ->>'preventTargetGapPoints' preventTargetGapPoints,
    json_array_elements(items::json)::json  ->>'quantityPurchased' quantityPurchased,
    json_array_elements(items::json)::json  ->>'userFlaggedBarcode' userFlaggedBarcode,
    json_array_elements(items::json)::json  ->>'userFlaggedNewItem' userFlaggedNewItem,
    json_array_elements(items::json)::json  ->>'userFlaggedPrice' userFlaggedPrice,
    json_array_elements(items::json)::json  ->>'userFlaggedQuantity' userFlaggedQuantity from ( select
    replace(values,'\','\\')::json -> '_id'->> '$oid' receiptId,
   replace(values,'\','\\')::json ->> 'rewardsReceiptItemList' items
from receipts_json ) a );
ALTER TABLE public.items_purchased ALTER COLUMN receiptid SET NOT NULL;




—————SQL ANSWERS———
--What are the top 5 brands by receipts scanned for most recent month?
select count(*),b.brandname from 
items_purchased i 
join brands b on (i.barcode = b.barcode)
join receipts_transactions r on (i.receiptid = r.receiptid)
where r.createdate>='2021-01-01 00:00:00'
group by b.brandname 
order by count(*) desc limit 5;



--When considering average spend from receipts with 'rewardsReceiptStatus’ of ‘Accepted’ or ‘Rejected’, which is greater?
SELECT 
   AVG (CAST (totalspent AS FLOAT)),rewardsreceiptstatus
FROM receipts_transactions
where LOWER(rewardsreceiptstatus) in ('accepted','finished','rejected')
group by rewardsreceiptstatus;




