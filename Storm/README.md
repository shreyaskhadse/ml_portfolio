Introduction (Synopsis)
-----------------------

Storms and other severe weather events can cause both public health and
economic problems for communities and municipalities. Many severe events
can result in fatalities, injuries, and property damage, and preventing
such outcomes to the extent possible is a key concern.

This project involves exploring the U.S. National Oceanic and
Atmospheric Administration’s (NOAA) storm database. This database tracks
characteristics of major storms and weather events in the United States,
including when and where they occur, as well as estimates of any
fatalities, injuries, and property damage.

In this report,effect of weather events on personal as well as property
damages was studied. Barplots were plotted seperately for the top 8
weather events that causes highest fatalities and highest injuries.
Results indicate that most Fatalities and injuries were caused by
Tornados.Also, barplots were plotted for the top 8 weather events that
causes the highest property damage and crop damage.

Data
----

The data for this project comes in the form of a comma-separated-value
file compressed via the bzip2 algorithm to reduce its size. You can
download the file
[here](https://d396qusza40orc.cloudfront.net/repdata%2Fdata%2FStormData.csv.bz2).

There is also some documentation of the database available. Here you
will find how some of the variables are constructed/defined.

[National Weather Service Storm Data
Documentation](https://d396qusza40orc.cloudfront.net/repdata%2Fpeer2_doc%2Fpd01016005curr.pdf)

[National Climatic Data Centre Strom Events
FAQ](https://d396qusza40orc.cloudfront.net/repdata%2Fpeer2_doc%2FNCDC%20Storm%20Events-FAQ%20Page.pdf)

The events in the database start in the year 1950 and end in November
2011. In the earlier years of the database there are generally fewer
events recorded, most likely due to a lack of good records. More recent
years should be considered more complete.

Now, we proceed with the work environment setting and data loading which
is done as below:

    #setting working directory
    setwd("A:/Project/Storm")

    #setting url
    url <- "https://d396qusza40orc.cloudfront.net/repdata%2Fdata%2FStormData.csv.bz2"    

    #setting file name
    file <- "StormData.csv.bz2"   

    #downloading file if not downloaded
    if (!file.exists(file)) {
      download.file(url, file, mode = "wb")
    }

    #reading file
    raw_data <- read.csv(file = file, header=TRUE, sep=",", stringsAsFactors = FALSE)

`read.csv` convniently reads our data and stores it to `raw_data` which
we are going to process in the future steps. The file is comma seperated
hence we use `sep=","`. We dont want the text in columns to be read as
factors, so we use `stringsAsFactors = FALSE`, when necessary we will
typecast the variables we need as vectors.

We now take a look at the data:

    str(raw_data)

    ## 'data.frame':    902297 obs. of  37 variables:
    ##  $ STATE__   : num  1 1 1 1 1 1 1 1 1 1 ...
    ##  $ BGN_DATE  : chr  "4/18/1950 0:00:00" "4/18/1950 0:00:00" "2/20/1951 0:00:00" "6/8/1951 0:00:00" ...
    ##  $ BGN_TIME  : chr  "0130" "0145" "1600" "0900" ...
    ##  $ TIME_ZONE : chr  "CST" "CST" "CST" "CST" ...
    ##  $ COUNTY    : num  97 3 57 89 43 77 9 123 125 57 ...
    ##  $ COUNTYNAME: chr  "MOBILE" "BALDWIN" "FAYETTE" "MADISON" ...
    ##  $ STATE     : chr  "AL" "AL" "AL" "AL" ...
    ##  $ EVTYPE    : chr  "TORNADO" "TORNADO" "TORNADO" "TORNADO" ...
    ##  $ BGN_RANGE : num  0 0 0 0 0 0 0 0 0 0 ...
    ##  $ BGN_AZI   : chr  "" "" "" "" ...
    ##  $ BGN_LOCATI: chr  "" "" "" "" ...
    ##  $ END_DATE  : chr  "" "" "" "" ...
    ##  $ END_TIME  : chr  "" "" "" "" ...
    ##  $ COUNTY_END: num  0 0 0 0 0 0 0 0 0 0 ...
    ##  $ COUNTYENDN: logi  NA NA NA NA NA NA ...
    ##  $ END_RANGE : num  0 0 0 0 0 0 0 0 0 0 ...
    ##  $ END_AZI   : chr  "" "" "" "" ...
    ##  $ END_LOCATI: chr  "" "" "" "" ...
    ##  $ LENGTH    : num  14 2 0.1 0 0 1.5 1.5 0 3.3 2.3 ...
    ##  $ WIDTH     : num  100 150 123 100 150 177 33 33 100 100 ...
    ##  $ F         : int  3 2 2 2 2 2 2 1 3 3 ...
    ##  $ MAG       : num  0 0 0 0 0 0 0 0 0 0 ...
    ##  $ FATALITIES: num  0 0 0 0 0 0 0 0 1 0 ...
    ##  $ INJURIES  : num  15 0 2 2 2 6 1 0 14 0 ...
    ##  $ PROPDMG   : num  25 2.5 25 2.5 2.5 2.5 2.5 2.5 25 25 ...
    ##  $ PROPDMGEXP: chr  "K" "K" "K" "K" ...
    ##  $ CROPDMG   : num  0 0 0 0 0 0 0 0 0 0 ...
    ##  $ CROPDMGEXP: chr  "" "" "" "" ...
    ##  $ WFO       : chr  "" "" "" "" ...
    ##  $ STATEOFFIC: chr  "" "" "" "" ...
    ##  $ ZONENAMES : chr  "" "" "" "" ...
    ##  $ LATITUDE  : num  3040 3042 3340 3458 3412 ...
    ##  $ LONGITUDE : num  8812 8755 8742 8626 8642 ...
    ##  $ LATITUDE_E: num  3051 0 0 0 0 ...
    ##  $ LONGITUDE_: num  8806 0 0 0 0 ...
    ##  $ REMARKS   : chr  "" "" "" "" ...
    ##  $ REFNUM    : num  1 2 3 4 5 6 7 8 9 10 ...

As we can see that there are `902297 obs. of  37 variables`. Many of
these we dont need at this instance in our study hence we will now begin
to process the `raw_data`.

Data Processing
---------------

Now, since we are going to process we would not like to overwrite the
original dataset hence, `data <- raw_data` a new copy is made. We saw
above while using `str()` that the `BGN_DATE` also has time in it which
is `0:00:00` across all observations in that column. This creates extra
confusion and makes our data untidy, we would like to remove it. The we
can freely typecast this `BGN_DATE` column into a date format by using
`as.Date()`:

    #making a copy
    data <- raw_data    

    #removing " 0:00:00"
    data$BGN_DATE <- gsub(" 0:00:00", "", data$BGN_DATE)    

    #typecast to date format
    data$BGN_DATE <- as.Date(data$BGN_DATE, format = "%m/%d/%Y")    
    str(data$BGN_DATE)

    ##  Date[1:902297], format: "1950-04-18" "1950-04-18" "1951-02-20" "1951-06-08" "1951-11-15" ...

According to NOAA, the data recording start from Jan. 1950. At that
time, they recorded only one event type - tornado. They added more
events gradually, and only from Jan 1996 they started recording all
events type. Since our objective is comparing the effects of different
weather events, we need only to include events that started not earlier
than Jan 1996.

    #subsetting by date
    data <- subset(data, data$BGN_DATE > as.Date(as.character("12/31/1995"), format = "%m/%d/%Y"))

Based on the above mentioned documentation and preliminary exploration
of raw data with `str()` and other similar functions we can conclude
that there are 7 variables we are interested in this study.

Namely:
`EVTYPE, FATALITIES, INJURIES, PROPDMG, PROPDMGEXP, CROPDMG, CROPDMGEXP`.
Therefore, we can limit our data to these variables.

    #subsetting by variables
    data <- subset(data, select = c(BGN_DATE, EVTYPE, FATALITIES, INJURIES, 
                                              PROPDMG, PROPDMGEXP, CROPDMG, CROPDMGEXP))
    str(data)

    ## 'data.frame':    653530 obs. of  8 variables:
    ##  $ BGN_DATE  : Date, format: "1996-01-06" "1996-01-11" ...
    ##  $ EVTYPE    : chr  "WINTER STORM" "TORNADO" "TSTM WIND" "TSTM WIND" ...
    ##  $ FATALITIES: num  0 0 0 0 0 0 0 0 0 0 ...
    ##  $ INJURIES  : num  0 0 0 0 0 0 0 0 0 0 ...
    ##  $ PROPDMG   : num  380 100 3 5 2 0 400 12 8 12 ...
    ##  $ PROPDMGEXP: chr  "K" "K" "K" "K" ...
    ##  $ CROPDMG   : num  38 0 0 0 0 0 0 0 0 0 ...
    ##  $ CROPDMGEXP: chr  "K" "" "" "" ...

Contents of data now are as follows:

`EVTYPE` – type of event `FATALITIES` – number of fatalities `INJURIES`
– number of injuries `PROPDMG` – the size of property damage
`PROPDMGEXP` - the exponent values for ‘`PROPDMG`’ (property damage)
`CROPDMG` - the size of crop damage `CROPDMGEXP` - the exponent values
for ‘`CROPDMG`’ (crop damage)

There are almost 1000 unique event types in EVTYPE column. Therefore, it
is better to limit database to a reasonable number. We can make it by
capitalizing all letters in EVTYPE column as well as subsetting only
non-zero data regarding our target numbers.

    #cleaning event types names
    data$EVTYPE <- toupper(data$EVTYPE)

    #eliminating zero data
    data <- data[data$FATALITIES !=0 | 
                             data$INJURIES !=0 | 
                             data$PROPDMG !=0 | 
                             data$CROPDMG !=0,]

Now, we wish to have the `'EVTYPE', 'PROPDMGEXP', 'CROPDMGEXP'` as
factors. We can do this at once by using the `lapply` function as below:

    #typecasting variables
    factorVars <- c('EVTYPE', 'PROPDMGEXP', 'CROPDMGEXP')
    data[,factorVars] <- lapply(data[,factorVars], as.factor)
    str(data)

    ## 'data.frame':    201318 obs. of  8 variables:
    ##  $ BGN_DATE  : Date, format: "1996-01-06" "1996-01-11" ...
    ##  $ EVTYPE    : Factor w/ 186 levels "   HIGH SURF ADVISORY",..: 182 149 153 153 153 83 153 153 153 46 ...
    ##  $ FATALITIES: num  0 0 0 0 0 0 0 0 0 0 ...
    ##  $ INJURIES  : num  0 0 0 0 0 0 0 0 0 0 ...
    ##  $ PROPDMG   : num  380 100 3 5 2 400 12 8 12 75 ...
    ##  $ PROPDMGEXP: Factor w/ 4 levels "","B","K","M": 3 3 3 3 3 3 3 3 3 3 ...
    ##  $ CROPDMG   : num  38 0 0 0 0 0 0 0 0 0 ...
    ##  $ CROPDMGEXP: Factor w/ 4 levels "","B","K","M": 3 1 1 1 1 1 1 1 1 1 ...

Human life is greatly affected by natural disasters, whether it be
ecnomically or in terms of health. We now proceed our study with

Human Loss
----------

We aggregate fatalities and injuries numbers in order to identify TOP-10
events contributing the total people loss:

    #creating cumulative/aggregate column for humanLoss
    humanLoss <- aggregate(cbind(FATALITIES, INJURIES) ~ EVTYPE, data = data, FUN=sum)
    humanLoss$PEOPLE_LOSS <- humanLoss$FATALITIES + humanLoss$INJURIES
    humanLoss <- humanLoss[order(humanLoss$PEOPLE_LOSS, decreasing = TRUE), ]
    Top10Eve <- humanLoss[1:10,]
    Top10Eve

    ##                EVTYPE FATALITIES INJURIES PEOPLE_LOSS
    ## 149           TORNADO       1511    20667       22178
    ## 39     EXCESSIVE HEAT       1797     6391        8188
    ## 48              FLOOD        414     6758        7172
    ## 107         LIGHTNING        651     4141        4792
    ## 153         TSTM WIND        241     3629        3870
    ## 46        FLASH FLOOD        887     1674        2561
    ## 146 THUNDERSTORM WIND        130     1400        1530
    ## 182      WINTER STORM        191     1292        1483
    ## 69               HEAT        237     1222        1459
    ## 88  HURRICANE/TYPHOON         64     1275        1339

We can clearly see that the the event causing the most human loss is
`TORNADO`. To present this better and visualize the comparative scale,
we will now create a barplot. For this purpose we will use the \`GGPLO2
library and the process to create this is below:

    #loading ggplot2
    library(ggplot2)

    #creating plot
    ggplot(data = Top10Eve, aes(x = reorder(EVTYPE, PEOPLE_LOSS), y = PEOPLE_LOSS)) + 
      geom_bar(stat = "identity", fill = "#A752AD") + 
      labs(title = "Total people loss in USA by weather events in 1996-2011")+ 
      theme(plot.title = element_text(hjust = 0.5))+ 
      labs(y = "Number of fatalities and injuries", x = "Event Type") + 
      coord_flip()

![](stormMarkdown_files/figure-markdown_strict/unnamed-chunk-9-1.png)

Economic Loss
-------------

The number/letter in the exponent value columns (PROPDMGEXP and
CROPDMGEXP) represents the power of ten (10^The number). It means that
the total size of damage is the product of PROPDMG and CROPDMG and
figure 10 in the power corresponding to exponent value.

letters (`B` = Billion, `M` = Million, `K` = Thousand) We, will now
substitute them with the 10’s exponent value and then typecast them
`as.numeric()` since we need to compute the actual loss.

First we do this for `PROPDMGEXP`:

    #substituting values
    data$PROPDMGEXP <- gsub("K", "3", data$PROPDMGEXP)
    data$PROPDMGEXP <- gsub("M", "6", data$PROPDMGEXP)
    data$PROPDMGEXP <- gsub("B", "9", data$PROPDMGEXP)

    #typecasting
    data$PROPDMGEXP <- as.numeric(data$PROPDMGEXP)
    str(data$PROPDMGEXP)

    ##  num [1:201318] 3 3 3 3 3 3 3 3 3 3 ...

Then, the same for `CROPDMGEXP`

    #substituting values
    data$CROPDMGEXP <- gsub("K", "3", data$CROPDMGEXP)
    data$CROPDMGEXP <- gsub("M", "6", data$CROPDMGEXP)
    data$CROPDMGEXP <- gsub("B", "9", data$CROPDMGEXP)

    #typecasting
    data$CROPDMGEXP <- as.numeric(data$CROPDMGEXP)
    str(data$CROPDMGEXP)

    ##  num [1:201318] 3 NA NA NA NA NA NA NA NA NA ...

We, noticed that `PROPDMGEXP` and `CROPDMGEXP` had some `NA` values,
which means absence of exponent. So, we will need to substitute them
with `0`. We identify the `NA` values with `is.na()`.

    #replacing NA values with 0
    data$PROPDMGEXP[is.na(data$PROPDMGEXP)] <- 0
    data$CROPDMGEXP[is.na(data$CROPDMGEXP)] <- 0
    str(data$PROPDMGEXP)

    ##  num [1:201318] 3 3 3 3 3 3 3 3 3 3 ...

    str(data$CROPDMGEXP)

    ##  num [1:201318] 3 0 0 0 0 0 0 0 0 0 ...

Now, we compute the total loss by raising 10 to the damage exponent and
the multiplying it with the value.

    #computing final value
    data$PROPDMGTOT <- (data$PROPDMG *(10 ^ data$PROPDMGEXP))
    data$CROPDMGTOT <- (data$CROPDMG *(10 ^ data$CROPDMGEXP))

Now we aggregate property and crop damage numbers in order to identify
TOP-10 events contributing the total economic loss:

    economicLoss <- aggregate(cbind(PROPDMGTOT, CROPDMGTOT) ~ EVTYPE, data = data, FUN=sum)
    economicLoss$ECONOMIC_LOSS <- economicLoss$PROPDMGTOT + economicLoss$CROPDMGTOT
    economicLoss <- economicLoss[order(economicLoss$ECONOMIC_LOSS, decreasing = TRUE), ]
    Top10EveEco <- economicLoss[1:10,]
    Top10EveEco

    ##                EVTYPE   PROPDMGTOT  CROPDMGTOT ECONOMIC_LOSS
    ## 48              FLOOD 143944833550  4974778400  148919611950
    ## 88  HURRICANE/TYPHOON  69305840000  2607872800   71913712800
    ## 141       STORM SURGE  43193536000        5000   43193541000
    ## 149           TORNADO  24616945710   283425010   24900370720
    ## 66               HAIL  14595143420  2476029450   17071172870
    ## 46        FLASH FLOOD  15222203910  1334901700   16557105610
    ## 86          HURRICANE  11812819010  2741410000   14554229010
    ## 32            DROUGHT   1046101000 13367566000   14413667000
    ## 152    TROPICAL STORM   7642475550   677711000    8320186550
    ## 83          HIGH WIND   5247860360   633561300    5881421660

We can clearly see that the the event causing the most economic loss is
`FLOOD`. To present this better and visualize the comparative scale, we
will now create a barplot.

    ggplot(data = Top10EveEco, aes(x = reorder(EVTYPE, ECONOMIC_LOSS), y = ECONOMIC_LOSS)) +
      geom_bar(stat = "identity", fill = "#9664AC") +
      labs(title = "Total economic loss in USA by weather events in 1996-2011")+
      theme(plot.title = element_text(hjust = 0.5))+
      labs(y = "Size of property and crop loss", x = "Event Type") +
      coord_flip()

![](stormMarkdown_files/figure-markdown_strict/unnamed-chunk-15-1.png)

Just to extend our study let us also take a look at which year was the
most expensive in terms of `ECO_LOSS` and `HUMAN_LOSS`.

First we do this by creating the variables that we need: `ECO_LOSS` -
the sum of property and crop damage `HUMAN_LOSS` - the sum of fatalities
and injuries `YEAR` - striping the year from the `BGN_DATE` column.

Then we aggreage it as we did earlier to create a cumulattive column
where the sum is by the variable `YEAR`.

    #creating variables
    data$ECO_LOSS <- (data$PROPDMGTOT + data$CROPDMGTOT)
    data$HUMAN_LOSS <- (data$FATALITIES + data$INJURIES)
    data$YEAR <- as.factor(format(data$BGN_DATE,'%Y'))

    #creating cumulative column by year
    yearLoss <- aggregate(cbind(ECO_LOSS, HUMAN_LOSS) ~ YEAR , data = data, FUN=sum)
    yearLoss

    ##    YEAR     ECO_LOSS HUMAN_LOSS
    ## 1  1996   7975346190       3259
    ## 2  1997  10786139640       4401
    ## 3  1998  16111480980      11864
    ## 4  1999  12253510650       6056
    ## 5  2000   8950598650       3280
    ## 6  2001  11843771770       3190
    ## 7  2002   5511250590       3653
    ## 8  2003  11397618590       3374
    ## 9  2004  26798776720       2796
    ## 10 2005 100824993470       2303
    ## 11 2006 125471672890       3967
    ## 12 2007   7480086160       2612
    ## 13 2008  17778176080       3191
    ## 14 2009   5749424130       1687
    ## 15 2010  11031773640       2280
    ## 16 2011  21555723960       8794

Lets visualize our findings.

First we plot the economic loss, year wise:

    ggplot(data = yearLoss, aes(x = reorder(YEAR, ECO_LOSS), y = ECO_LOSS)) + 
      geom_bar(stat = "identity", fill = "#8576AC") + 
      labs(title = "Year wise economic loss by caused by storms")+ 
      theme(plot.title = element_text(hjust = 0.5))+ 
      labs(y = "Loss worth", x = "Year") + 
      coord_flip()

![](stormMarkdown_files/figure-markdown_strict/unnamed-chunk-17-1.png)

We can see that the year `2006` was the most expensive in terms of
economic loss with not so far behind the year `2005`.

Next we have human loss, year wise:

    ggplot(data = yearLoss, aes(x = reorder(YEAR, HUMAN_LOSS), y = HUMAN_LOSS)) + 
      geom_bar(stat = "identity", fill = "#7488AB") + 
      labs(title = "Year wise human loss by caused by storms")+ 
      theme(plot.title = element_text(hjust = 0.5))+ 
      labs(y = "Lives Affected", x = "Year") + 
      coord_flip()

![](stormMarkdown_files/figure-markdown_strict/unnamed-chunk-18-1.png)

The year `1998` was the most expensive in terms of human loss.

To explore the reason of our above exploration, let us see which year
had the most number of evnts recorded.

    noEve <- as.data.frame(table(data$YEAR))
    names(noEve) <- c("Year", "Number of Events")
    noEve

    ##    Year Number of Events
    ## 1  1996            10040
    ## 2  1997            10322
    ## 3  1998            14013
    ## 4  1999            10609
    ## 5  2000            11508
    ## 6  2001            10298
    ## 7  2002            10432
    ## 8  2003            11015
    ## 9  2004            10484
    ## 10 2005            10014
    ## 11 2006            11974
    ## 12 2007            11953
    ## 13 2008            17633
    ## 14 2009            14434
    ## 15 2010            16019
    ## 16 2011            20570

    ggplot(data = noEve, aes(x = Year, y = `Number of Events`)) +
      geom_bar(stat = "identity", fill = "#639AAA") +
      labs(title = "Number of events per year") +
      labs(y= "Number of events", x = "Year")

![](stormMarkdown_files/figure-markdown_strict/unnamed-chunk-20-1.png)

We can see that during the earlier times 1998 was the year with the most
number of events and at that time the health care system was not that
strong as compared to later times, this may be the reason for the
highest human loss in `1998`, followed by the year `2011` which had the
maximum number of events in our timeline.

Summary
-------

Tornados caused the maximum number of fatalities and injuries. It was
followed by Excessive Heat for fatalities and Thunderstorm wind for
injuries.

Floods caused the maximum property damage where as Drought caused the
maximum crop damage. Second major events that caused the maximum damage
was Hurricanes/Typhoos for property damage and Floods for crop damage.

`1998` was the year which marked the greatest human loss and `2006` was
the year with highest economic loss.
