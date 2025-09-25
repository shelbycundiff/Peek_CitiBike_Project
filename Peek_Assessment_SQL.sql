###############################################
--testing out edits of this file 
--Exploratory Queries to Understand Data

--is the station table distinct or does it update each station frequently?

select distinct station_id, name, count(distinct last_reported) as report_days from `bigquery-public-data.new_york_citibike.citibike_stations`
group by 1,2
order by 2 desc;

--what are the different region_ids?

select distinct name, region_id from `bigquery-public-data.new_york_citibike.citibike_stations`
;


--what are the rental_methods?
select distinct rental_methods from `bigquery-public-data.new_york_citibike.citibike_stations`
;

--how many stations?
select count(distinct station_id) as count_of_stations  from `bigquery-public-data.new_york_citibike.citibike_stations`
;

--what are the different user types?
select distinct usertype, customer_plan from `bigquery-public-data.new_york_citibike.citibike_trips`
;

--sample of one trip:

select * from `bigquery-public-data.new_york_citibike.citibike_trips`
where tripduration is not null limit 1;



###############################################

--STEP 1 SQL QUESTIONS TO ANSWER:
--For each bike ID, compute the longest streak of consecutive days it was used.
 

with distinct_daily_rides AS ( select distinct
  bikeid, date(date_trunc(starttime, day)) as ride_Day,
 from `bigquery-public-data.new_york_citibike.citibike_trips` ),

streak_groups AS (
    SELECT
        bikeid,
        ride_day,
        extract(dayofyear from ride_Day) - ROW_NUMBER() OVER (PARTITION BY bikeid ORDER BY ride_Day) AS streak_group
    FROM distinct_daily_rides
)
select distinct bikeid, max(count(*)) over (partition by bikeid) as longest_Streak from streak_groups 
where bikeid is not null
group by bikeid, streak_group 
order by longest_streak desc
limit 50;








--Which stations show the biggest difference between weekday and weekend usage?

with summed_trip_table as (
 select distinct stations.name,
 case when extract( dayofweek from (date_trunc(trips.starttime, day))) in (1,7) then 'weekend' else 'weekday' end as date_category,
  count(bikeid) as trip_count from `bigquery-public-data.new_york_citibike.citibike_stations` stations
  left join `bigquery-public-data.new_york_citibike.citibike_trips` trips 
  on stations.name = trips.start_station_name  or stations.name = trips.end_Station_name--trip counts as outbound or inbound for any given station
  group by 1,2

)
,trip_count_by_station as(
select distinct name, 
sum(case when date_category = 'weekday' then (trip_count) else null  end)/5 as average_weekday_daily_trips,
sum(case when date_category = 'weekend' then (trip_count) else null end)/2 as  avg_weekend_daily_trips
from summed_trip_table
group by 1)

select *, abs( (average_weekday_daily_trips- avg_weekend_daily_trips)/(avg_weekend_daily_trips)) as normalized_percent_diff --using absolute value to weight places where weekend traffic is stronger similarly to those with higher weekday traffic
 from trip_count_by_station
order by 4 desc
limit 50;

--How has the average trip duration changed month-over-month for the 20 busiest stations?
with busiest_Stations as (
  select distinct stations.name, count(bikeid) as total_trip_count, case when max(starttime) is not null then (count(bikeid)/count(distinct date(date_trunc(starttime, day)))) else 0 end as avg_trips_per_Day from `bigquery-public-data.new_york_citibike.citibike_stations` stations
  left join `bigquery-public-data.new_york_citibike.citibike_trips` trips 
  on stations.name = trips.start_station_name  or stations.name = trips.end_Station_name--trip counts as outbound or inbound for any given station
  group by 1
  order by 3 desc
  limit 20
),
monthly_trip_duration as (
  select date(date_trunc(starttime, month)) as trip_month,
  avg(tripduration) as avg_duration from `bigquery-public-data.new_york_citibike.citibike_trips` trips 
  inner join busiest_Stations on busiest_Stations.name = trips.start_station_name or busiest_Stations.name = trips.end_station_name
  group by 1
)

select * from monthly_trip_duration
order by trip_month 
;

--Classify each station-day into “Low”, “Medium”, or “High” demand based on trip volume percentiles. Then, analyze demand category distribution by borough.
--overall average 
with station_info as (

 select distinct stations.name,stations.latitude, stations.longitude, count(bikeid) as total_trip_count, case when max(starttime) is not null then (count(bikeid)/count(distinct date(date_trunc(starttime, day)))) else 0 end as avg_trips_per_Day from `bigquery-public-data.new_york_citibike.citibike_stations` stations
  left join `bigquery-public-data.new_york_citibike.citibike_trips` trips 
  on stations.name = trips.start_station_name  or stations.name = trips.end_Station_name--trip counts as outbound or inbound for any given station
  
  group by 1,2,3

)
,percentile_info as (
select percentile_cont(station_info.avg_trips_per_Day, .30) over ()  as low_cutoff,
percentile_cont(station_info.avg_trips_per_Day, .60) over ()  as med_cutoff,
percentile_cont(station_info.avg_trips_per_Day, .90) over ()  as high_cutoff


from station_info
where station_info.total_trip_count>0)

select distinct name,
latitude,
longitude,
case when avg_trips_per_Day between 0 and (select max(low_cutoff) from percentile_info)  then 'low'
when avg_trips_per_day between (select max(low_cutoff) from percentile_info) and (select max(high_cutoff) from percentile_info) then 'med'
when avg_trips_per_day>(select max(high_cutoff) from percentile_info)  then 'high' else null end as traffic_class from station_info 
;
--station-day pairs:

with station_info as (

 select distinct concat(date(date_trunc(starttime, day)),stations.name) as station_day, stations.name,stations.latitude, stations.longitude, count(bikeid) as total_trip_count from `bigquery-public-data.new_york_citibike.citibike_stations` stations
  left join `bigquery-public-data.new_york_citibike.citibike_trips` trips 
  on stations.name = trips.start_station_name  or stations.name = trips.end_Station_name--trip counts as outbound or inbound for any given station
  
  group by 1,2,3,4

),
nyc_mapping_info as (
  select string_Field_0 as name, string_field_1 as borough from citibike_additional_data.nyc_borough_mapping
)
,percentile_info as (
select percentile_cont(station_info.total_trip_count, .30) over ()  as low_cutoff,
percentile_cont(station_info.total_trip_count, .60) over ()  as med_cutoff,
percentile_cont(station_info.total_trip_count, .90) over ()  as high_cutoff


from station_info
where station_info.total_trip_count>0)
,per_Station_day as (
select distinct station_day, name, borough,
latitude,
longitude,
case when total_trip_count between 0 and (select max(low_cutoff) from percentile_info)  then 'low'
when total_trip_count between (select max(low_cutoff) from percentile_info) and (select max(high_cutoff) from percentile_info) then 'med'
when total_trip_count>(select max(high_cutoff) from percentile_info)  then 'high' else null end as traffic_class from station_info 
left join nyc_mapping_info map using(name)
)

select distinct borough, traffic_class, count(distinct station_day) as station_days from per_Station_day
group by 1,2
;
--On high-volume days (>90th percentile), do users ride longer or shorter trips? Does this differ by rider type?

with station_info as (

 select distinct concat(date(date_trunc(starttime, day)),stations.name) as station_day, stations.name, date(date_trunc(starttime, day)) as ride_Day, stations.latitude, stations.longitude, count(bikeid) as total_trip_count from `bigquery-public-data.new_york_citibike.citibike_stations` stations
  left join `bigquery-public-data.new_york_citibike.citibike_trips` trips 
  on stations.name = trips.start_station_name  or stations.name = trips.end_Station_name--trip counts as outbound or inbound for any given station
  
  group by 1,2,3,4,5

),
nyc_mapping_info as (
  select string_Field_0 as name, string_field_1 as borough from citibike_additional_data.nyc_borough_mapping
)
,percentile_info as (
select percentile_cont(station_info.total_trip_count, .30) over ()  as low_cutoff,
percentile_cont(station_info.total_trip_count, .60) over ()  as med_cutoff,
percentile_cont(station_info.total_trip_count, .90) over ()  as high_cutoff


from station_info
where station_info.total_trip_count>0)

,per_Station_day as (
select distinct station_day, name, ride_day, borough,
latitude,
longitude,
case when total_trip_count between 0 and (select max(low_cutoff) from percentile_info)  then 'low'
when total_trip_count between (select max(low_cutoff) from percentile_info) and (select max(high_cutoff) from percentile_info) then 'med'
when total_trip_count>(select max(high_cutoff) from percentile_info)  then 'high' else null end as traffic_class from station_info 
left join nyc_mapping_info map using(name)
)

select distinct borough,  
avg(case when traffic_class = 'low' then tripduration else null end) as low_traffic_trip_duration,
avg(case when traffic_class = 'med' then tripduration else null end) as med_traffic_trip_duration,

avg(case when traffic_class = 'high' then tripduration else null end) as high_traffic_trip_duration





 from per_Station_day 
  left join `bigquery-public-data.new_york_citibike.citibike_trips` trips 
on (
per_Station_day.name = trips.start_station_name  or  
per_Station_day.name = trips.end_Station_name ) and date(date_trunc(starttime, day)) = per_Station_day.ride_Day
group by 1

;



--how does it differ by rider type?


with station_info as (

 select distinct concat(date(date_trunc(starttime, day)),stations.name) as station_day, stations.name, date(date_trunc(starttime, day)) as ride_Day, stations.latitude, stations.longitude, count(bikeid) as total_trip_count from `bigquery-public-data.new_york_citibike.citibike_stations` stations
  left join `bigquery-public-data.new_york_citibike.citibike_trips` trips 
  on stations.name = trips.start_station_name  or stations.name = trips.end_Station_name--trip counts as outbound or inbound for any given station
  
  group by 1,2,3,4,5

),
nyc_mapping_info as (
  select string_Field_0 as name, string_field_1 as borough from citibike_additional_data.nyc_borough_mapping
)
,percentile_info as (
select percentile_cont(station_info.total_trip_count, .30) over ()  as low_cutoff,
percentile_cont(station_info.total_trip_count, .60) over ()  as med_cutoff,
percentile_cont(station_info.total_trip_count, .90) over ()  as high_cutoff


from station_info
where station_info.total_trip_count>0)

,per_Station_day as (
select distinct station_day, name, ride_day, borough,
latitude,
longitude,
case when total_trip_count between 0 and (select max(low_cutoff) from percentile_info)  then 'low'
when total_trip_count between (select max(low_cutoff) from percentile_info) and (select max(high_cutoff) from percentile_info) then 'med'
when total_trip_count>(select max(high_cutoff) from percentile_info)  then 'high' else null end as traffic_class from station_info 
left join nyc_mapping_info map using(name)
)

select distinct usertype,  
avg(case when traffic_class = 'low' then tripduration else null end) as low_traffic_trip_duration,
avg(case when traffic_class = 'med' then tripduration else null end) as med_traffic_trip_duration,

avg(case when traffic_class = 'high' then tripduration else null end) as high_traffic_trip_duration





 from per_Station_day 
  left join `bigquery-public-data.new_york_citibike.citibike_trips` trips 
on (
per_Station_day.name = trips.start_station_name  or  
per_Station_day.name = trips.end_Station_name ) and date(date_trunc(starttime, day)) = per_Station_day.ride_Day
group by 1


;
--what is the busiest month?
select distinct extract(month from starttime), count(bikeid) as trip_count from `bigquery-public-data.new_york_citibike.citibike_trips` trips 
group by 1;


--what is the busiest time of the day to ride?
select distinct extract(hour from starttime), count(bikeid) as trip_count from `bigquery-public-data.new_york_citibike.citibike_trips` trips 
group by 1;



--do users behave differently?

select distinct usertype, extract(hour from starttime), avg(tripduration) from `bigquery-public-data.new_york_citibike.citibike_trips` trips 

group by 1,2;

select distinct usertype, extract(month from starttime) as month_number, avg(tripduration) as trip_duration,count(bikeid) as trip_count from `bigquery-public-data.new_york_citibike.citibike_trips` trips 

group by 1,2;


--what about by gender?
select distinct gender, avg(tripduration), count(bikeid) from `bigquery-public-data.new_york_citibike.citibike_trips` trips 
group by 1;

--TASK 2:
--Demand Modeling Portion



--idea : model based on monthly weekday vs. weekend averages for the top 10 stations


with summed_trip_table as (
 select distinct stations.name,
 date_trunc(starttime, month) as ride_month,
 case when extract( dayofweek from (date_trunc(trips.starttime, day))) in (1,7) then 'weekend' else 'weekday' end as date_category,
  count(bikeid) as trip_count from `bigquery-public-data.new_york_citibike.citibike_stations` stations
  left join `bigquery-public-data.new_york_citibike.citibike_trips` trips 
  on stations.name = trips.start_station_name  or stations.name = trips.end_Station_name--trip counts as outbound or inbound for any given station
  group by 1,2,3

)
,trip_count_by_station as(
select distinct ride_month,
sum(case when date_category = 'weekday' then (trip_count) else null  end)/5 as average_weekday_daily_trips,
sum(case when date_category = 'weekend' then (trip_count) else null end)/2 as  avg_weekend_daily_trips
from summed_trip_table
inner join (select distinct name, sum(trip_count) from summed_trip_table  group by 1 order by 2 desc limit 10) top10 using(name)
group by 1)

select * from trip_count_by_station
;


--do we have enough bikes?



with summed_trip_table as (
 select distinct stations.name,
 date_trunc(starttime, month) as ride_month,
 case when extract( dayofweek from (date_trunc(trips.starttime, day))) in (1,7) then 'weekend' else 'weekday' end as date_category,
  count(bikeid) as trip_count from `bigquery-public-data.new_york_citibike.citibike_stations` stations
  left join `bigquery-public-data.new_york_citibike.citibike_trips` trips 
  on stations.name = trips.start_station_name  or stations.name = trips.end_Station_name--trip counts as outbound or inbound for any given station
  group by 1,2,3

)
,station_supply as(
select sum(num_bikes_available) as total_available,
sum(num_bikes_disabled) as total_disabled,
sum(num_docks_available) as docks_available,
sum(num_docks_disabled) as docks_disabled,
from `bigquery-public-data.new_york_citibike.citibike_stations` stations
inner join (select distinct name, sum(trip_count) from summed_trip_table  group by 1 order by 2 desc limit 10) top10 using(name)
)

select * from station_supply
;
