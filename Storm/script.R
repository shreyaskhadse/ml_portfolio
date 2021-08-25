setwd("A:/Project/Storm")
url <- "https://d396qusza40orc.cloudfront.net/repdata%2Fdata%2FStormData.csv.bz2"
file <- "StormData.csv.bz2"
if (!file.exists(file)) {
  download.file(url, file, mode = "wb")
}
raw_data <- read.csv(file = file, header=TRUE, sep=",", stringsAsFactors = FALSE)

str(raw_data)

data <- raw_data
data$BGN_DATE <- gsub(" 0:00:00", "", data$BGN_DATE)
data$BGN_DATE <- as.Date(data$BGN_DATE, format = "%m/%d/%Y")
data <- subset(data, data$BGN_DATE > as.Date(as.character("12/31/1995"), format = "%m/%d/%Y"))
data <- subset(data, select = c(BGN_DATE, EVTYPE, FATALITIES, INJURIES, 
                                          PROPDMG, PROPDMGEXP, CROPDMG, CROPDMGEXP))
data$EVTYPE <- toupper(data$EVTYPE)

data <- data[data$FATALITIES !=0 | 
                         data$INJURIES !=0 | 
                         data$PROPDMG !=0 | 
                         data$CROPDMG !=0,]
factorVars <- c('EVTYPE', 'PROPDMGEXP', 'CROPDMGEXP')
data[,factorVars] <- lapply(data[,factorVars], as.factor)

humanLoss <- aggregate(cbind(FATALITIES, INJURIES) ~ EVTYPE, data = data, FUN=sum)
humanLoss$PEOPLE_LOSS <- humanLoss$FATALITIES + humanLoss$INJURIES
humanLoss <- humanLoss[order(humanLoss$PEOPLE_LOSS, decreasing = TRUE), ]
Top10Eve <- humanLoss[1:10,]
Top10Eve

data$PROPDMGEXP <- gsub("K", "3", data$PROPDMGEXP)
data$PROPDMGEXP <- gsub("M", "6", data$PROPDMGEXP)
data$PROPDMGEXP <- gsub("B", "9", data$PROPDMGEXP)
data$PROPDMGEXP <- as.numeric(data$PROPDMGEXP)

data$CROPDMGEXP <- gsub("K", "3", data$CROPDMGEXP)
data$CROPDMGEXP <- gsub("M", "6", data$CROPDMGEXP)
data$CROPDMGEXP <- gsub("B", "9", data$CROPDMGEXP)
data$CROPDMGEXP <- as.numeric(data$CROPDMGEXP)

data$PROPDMGEXP[is.na(data$PROPDMGEXP)] <- 0
data$CROPDMGEXP[is.na(data$CROPDMGEXP)] <- 0

data$PROPDMGTOT <- (data$PROPDMG *(10 ^ data$PROPDMGEXP))
data$CROPDMGTOT <- (data$CROPDMG *(10 ^ data$CROPDMGEXP))

economicLoss <- aggregate(cbind(PROPDMGTOT, CROPDMGTOT) ~ EVTYPE, data = data, FUN=sum)
economicLoss$ECONOMIC_LOSS <- economicLoss$PROPDMGTOT + economicLoss$CROPDMGTOT
economicLoss <- economicLoss[order(economicLoss$ECONOMIC_LOSS, decreasing = TRUE), ]
Top10EveEco <- economicLoss[1:10,]
Top10EveEco

library(ggplot2)
ggplot(data = Top10Eve, aes(x = reorder(EVTYPE, PEOPLE_LOSS), y = PEOPLE_LOSS)) + 
  geom_bar(stat = "identity", fill = "steelblue") + 
  labs(title = "Total people loss in USA by weather events in 1996-2011")+ 
  theme(plot.title = element_text(hjust = 0.5))+ 
  labs(y = "Number of fatalities and injuries", x = "Event Type") + 
  coord_flip()

ggplot(data = Top10EveEco, aes(x = reorder(EVTYPE, ECONOMIC_LOSS), y = ECONOMIC_LOSS)) + 
  geom_bar(stat = "identity", fill = "steelblue") + 
  labs(title = "Total economic loss in USA by weather events in 1996-2011")+ 
  theme(plot.title = element_text(hjust = 0.5))+ 
  labs(y = "Size of property and crop loss", x = "Event Type") + 
  coord_flip()


