path <- "A:/Project/Breast_Cancer"
setwd(path)
url <- "https://raw.githubusercontent.com/shreyaskhadse/data_files/master/wisc_bc_data.csv"
datafile <- "./wisc_bc_data.csv"
if (!file.exists(datafile)) {
    download.file(url, datafile ,method="auto") }
wbcd <- read.csv("./wisc_bc_data.csv")
str(wbcd)
wbcd <- wbcd[-1]
table(wbcd$diagnosis)
wbcd$diagnosis <- factor(wbcd$diagnosis, levels = c("B","M"), labels = c("Benign", "Malignant"))
slices <- c(((nrow(wbcd[wbcd$diagnosis == "Benign",]))/nrow(wbcd))*100, 
            ((nrow(wbcd[wbcd$diagnosis == "Malignant",]))/nrow(wbcd))*100)
labs<- c("Benign", "Malignant")
pie(slices, labels = labs, main = "Breast Cancer Type", col = c("Blue","Red"))
round(prop.table(table(wbcd$diagnosis))*100, digits = 2)
summary(wbcd[c("radius_mean", "area_mean", "smoothness_mean")])

normalize <- function(x){
    return((x-min(x))/(max(x)-min(x)))
}

wbcd_n <- as.data.frame(lapply(wbcd[2:31], normalize))
summary(wbcd_n[c("radius_mean", "area_mean", "smoothness_mean")])

wbcd_train <- wbcd_n[1:469,]
wbcd_test <- wbcd_n[470:569,]

wbcd_train_labels <- wbcd[1:469, 1]
wbcd_test_labels <- wbcd[470:569, 1]

install.packages("class")
library(class)

wbcd_test_pred <- knn(train = wbcd_train, test = wbcd_test, cl= wbcd_train_labels, k =21)
install.packages("gmodels")
library("gmodels")
CrossTable(x = wbcd_test_labels, y = wbcd_test_pred, prop.chisq = FALSE)

wbcd_z <- as.data.frame(scale(wbcd[-1]))
summary(wbcd_z[c("radius_mean", "area_mean", "smoothness_mean")])

wbcd_train_z <- wbcd_z[1:469,]
wbcd_test_z <- wbcd_n[470:569,]
wbcd_train_labels_z <- wbcd[1:469, 1]
wbcd_test_labels_z <- wbcd[470:569, 1]
wbcd_test_pred_z <- knn(train = wbcd_train_z, test = wbcd_test_z, cl= wbcd_train_labels_z, k =21)
CrossTable(x = wbcd_test_labels_z, y = wbcd_test_pred_z, prop.chisq = FALSE)



