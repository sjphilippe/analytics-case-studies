# Reflections on the Maven Premium Coffee Pilot

Oct 5, 2026 

## Why I chose this project

I chose this project because I spent five plus years working in point-of-sale and am familiar with restaurant menus. This project allowed me to dive into the analytical side of the pricing vs. just programming the systems. Overall I enjoyed working on this dataset and creating my own story to go along with it. Working with Claude helped tremendously in some areas, but lagged in others. I would like to do another sales analysis project, but with more customer behavior data so that I can gain sights on both sales and marketing. I would have preferred to work with a strictly tea dataset as I don't drink coffee, but a coffee shop was close enough.


## Where the dataset fell short

Besides some mild cleanup upon loading into SQL server, the sales data is clean and complete for what it records. The biggest short fall of the data set was the lack of customer behavior.  After running the initial analysis I was wishing for more customer granularity to gain insight of behavior across the 3 stores. Additionally I would have loved if I sales data prior to the Jamaican pilot so that I could see its true popularity and how Jamaican coffee impacted sales of the other 3 coffees. The dataset lacking a 'cost of production' meant that it had to be estimated, and of course my assumptions could be wrong.  

Other things I noticed in the dataset were that each coffee sold within about 5% of the others' cup totals, and Jamaican's share barely moved from month to month. It seems unlikely in a real setting that sales over this period of time would skew toward such a clean average. That pattern suggests the data was generated rather than recorded.


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
