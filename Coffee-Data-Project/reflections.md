# Reflections on the Maven Premium Coffee Pilot

Oct 5, 2026 

## Why I chose this project

I chose this project because I spent five plus years working in point-of-sale analyzing gross profit, margins, and financial forecasts via different suppliers and price point. Overall I enjoyed working on this dataset and creating my own story to go along with it. Working with Claude helped tremendously in some areas, but lagged in others. I would like to do another sales analysis project, but with more customer behavior data so that I can gain sights on both sales and marketing. 

## Where the dataset fell short

Besides some mild cleanup upon loading into SQL server, the sales data is clean and complete for what it records. The biggest short fall of the data set was the lack of customer behavior.  I wanted more customer granularity to gain insight of behavior across the 3 stores. Additionally I'd like if I sales data prior to the Jamaican Coffee pilot to gain insight into its true popularity and menu performance. The dataset lacking a 'cost of production' meant that it had to be estimated.  

Other things I noticed in the dataset were that each coffee sold within about 5% of the others' cup totals, and Jamaican's share barely moved from month to month. Testing sales per day across the three stores showed that sales rose and fell on specific dates each month. Even worse, each location had a consistent drop in sales during lunch hour and on weekends. It is highly unlikely in a real setting that sales over this period of time would skew toward such clean averages.

## How I worked with Claude

I used Claude as a coding and documentation assistant. The split of work looked like this:

| Me                                                        | Claude                                                         |
| --------------------------------------------------------- | -------------------------------------------------------------- |
| The business question and the overall plan                | SQL scripts for setup, validation, analysis and scenarios      |
| Choosing the data sources and the cost approach           | Outline drafts of the brief, mapping, dictionary, and findings |
| Running every query in SQL Server and checking the output | Placeholder charts and calculations to check results against   |
| The final recommendation                                  |                                                                |

Claude was fastest at the most tedious parts of the project: writing long SQL scripts, cross-checking numbers between documents, and keeping the issues log in sync.  Most of my issues with Claude fell into a handful of patterns that I had to repeatedly adjust for such as over-engineering, scope creep, various inconsistencies and queries that were hard for a person to read. Next time I would put stricter rules in the project instructions and ask Claude to check its own work against those rules before handing anything over.

Thanks for reading!
