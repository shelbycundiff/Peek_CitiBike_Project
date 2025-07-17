# Peek_CitiBike_Project

##### Approach & Methods

1. Understand the two data sets presented via exploratory analysis queries
2. Work through key questions to help understand the environment CitiBike operates in

   *Analysis done outside of SQL (via Google Sheets) is stored in separate tabs in the Peek Assignment Spreadsheet

   *Work to identify which Lat/Long pairs coordinate with each NYC Borough was done using Geocodio (free online tool)
3. Build out a forcast based on learnings in #2.
4. Apply forcast and analysis findings to a pricing strategy ideation session



##### Tools and Resources

https://dash.geocod.io/
https://www.reddit.com/r/SQL/comments/1etv7z2/need_help_calculating_user_streaks/
Google BigQuery for editing queries
Google Sheets for additional analysis
Google Slides for presentation
Text Files for Pre-building the table used to map Lat/Long -> NYC Boroughs, called "citibike_additional_data.nyc_borough_mapping" 


### Key Findings Summary

*CitiBike traffic is highly seasonal, with peaks matching up to good weather and daily commute behaviors.
*There is ample room for growth with flexible pricing and promotions to incentivize additional rides. Bikes are available 24/7, so there is often more supply than demand during off-peak times.
*To forecast, we should start with historical data patterns split by weekday vs. weekend, then build in additional factors like user traits as forcast accuracy improves. 
*As a first effort to apply dynamic pricing, we should implement custom discounting based on relative traffic patterns. High traffic times receive no discount, but low traffic times receive a proportional discount to the traffic they generate vs. the peak time. 

### Details (Based on Task Numbers)

**Task # 1:**

     1.For each bike ID, compute the longest streak of consecutive days it was used.

          See spreadsheet for full output, but the top bike streak was **Bike #17333 with 131 days.**


     2. Which stations show the biggest difference between weekday and weekend usage?

          See spreadsheet for full output, but the biggest percent difference was **E 47 St & Park Ave. **


     3. How has the average trip duration changed month-over-month for the 20 busiest stations?

             On average the percent change month over month has changed very little (0.13% across the dataset in monthly change), but it does show strong seasonal behavior with peaks in spring and fall - presumably when good weather is present in NYC. 

     4.Classify each station-day into “Low”, “Medium”, or “High” demand based on trip volume percentiles. Then, analyze demand category distribution by borough.

          See spreadsheet for more details, but Manhattan is the only borough with a sizeable amount of 'high' demand days. The other boroughs are often majority "Low" demand centric. 


     5.On high-volume days (>90th percentile), do users ride longer or shorter trips? Does this differ by rider type?

               Generally speaking, high volume days typically have shorter trip duration than low volume days. Riders with subscriptions are less volatile in their trip duration, but do also exhibit a trend with busier days equating to shorter rides. Customers with no subscription have a wide             difference between low and high traffic days - potentially suggesting that high traffic is more impactful toward lower-intent riders.


**Task #2**
See slide deck for details (all visuals were generated via the Peek Assignment Spreadsheet)

**Task #3**
* Market CitiBikes to non-subscribers to boost weekend activity and activities outside of commuting. Potential marketing could present CitiBike as more of an 'activity' than a 'transportation' which may incentivize more activity outside of general work days and times. Non-subscribed customers make up a very small component of overall riders (<20% on average), and could be a good way to bring in new riders.
* Lower pricing or provide promotions to increase traffic during non-peak hours. CitiBike traffic is strongest at 8 AM and 5 PM, but can be improved at other hours of the day. Potential ideas include partnerships with restaurants to encourage post-work use of CitiBikes, coupons for cheaper rides to the gym before work, or adjusted pricing based on availability on a given day.
* Repair bikes and docks to improve the user experience, as in our top stations, not all bikes or docks are functioning. Although demand is steadily increasing in most areas, ensuring a good experience will likely improve repeat customer appeal. Fixing bikes may provide enough supply during surge times to adequately serve the population, and will be a better optic for passerbys who may not consider CitiBikes normally.

**Task #4**

Utilize different factors to build out a discount system for pricing based on comparing low vs. high traffic splits.
As an example, if each CitiBike costs $5 to ride, we could discount the least popular 12 hours of the day by the ratio of traffic they have in comparison to the top most popular hours. 

i.e. if 5 PM is most popular, and it generates 150 rides, but 6AM is very unpopular at 50 rides, we could discount the 6 AM Group by looking at the ratio of 6 AM rides vs. 5 PM rides (i.e. 50/150 = 30%). A 30% discount would make rides at 6 AM $3.50 vs. $5 rides at 5 PM.

To start, I would suggest first looking at **hours of the day** that are least popular, **days of the week** that are least popular, then **lower traffic stations**. If all of these options are working well, user attributes could be the next logical step to test. 
