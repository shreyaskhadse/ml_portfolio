Introduction
------------

The global financial crisis of 2007-2008 highlighted the importance of
transparency and rigor in banking practices. As the availability of
credit was limited, banks tightened their lending systems and turned to
machine learning to more accurately identify risky loans.

Decision trees are widely used in the banking industry due to their high
accuracy and ability to formulate a statistical model in plain language.
Since governments in many countries carefully monitor the fairness of
lending practices, executives must be able to explain why one applicant
was rejected for a loan while another was approved. This information is
also useful for customers hoping to determine why their credit rating is
unsatisfactory.

It is likely that automated credit scoring models are used for credit
card mailings and instant online approval processes. In this section, we
will develop a simple credit approval model using C5.0 decision trees.
We will also see how the model results can be tuned to minimize errors
that result in a financial loss.

Collecting, Exploring and Preparing the data
--------------------------------------------

We will be using a dataset donated to the [UCI Machine Learning
Repository](http://archive.ics.uci.edu/ml) by Hans Hofmann of the
University of Hamburg. The dataset contains information on loans
obtained from a credit agency in Germany.

For ease to acces the dataset I have hosted a public repository and
included the code that directly downloads the data from the repo and
loads the data. The path can be canged to anythig according to your
preference of the working directory.

    path <- "A:/Project/Risky_Loans"
    setwd(path)
    url <- "https://raw.githubusercontent.com/shreyaskhadse/data_files/master/credit.csv"
    datafile <- "./credit.csv"
    if (!file.exists(datafile)) {
        download.file(url, datafile ,method="auto") }
    credit <- read.csv("credit.csv")
    credit$default <- as.factor(credit$default)
    levels(credit$default) <- c('no','yes')
    str(credit)

    ## 'data.frame':    1000 obs. of  21 variables:
    ##  $ checking_balance    : Factor w/ 4 levels "< 0 DM","> 200 DM",..: 1 3 4 1 1 4 4 3 4 3 ...
    ##  $ months_loan_duration: int  6 48 12 42 24 36 24 36 12 30 ...
    ##  $ credit_history      : Factor w/ 5 levels "critical","delayed",..: 1 5 1 5 2 5 5 5 5 1 ...
    ##  $ purpose             : Factor w/ 10 levels "business","car (new)",..: 8 8 5 6 2 5 6 3 8 2 ...
    ##  $ amount              : int  1169 5951 2096 7882 4870 9055 2835 6948 3059 5234 ...
    ##  $ savings_balance     : Factor w/ 5 levels "< 100 DM","> 1000 DM",..: 5 1 1 1 1 5 4 1 2 1 ...
    ##  $ employment_length   : Factor w/ 5 levels "> 7 yrs","0 - 1 yrs",..: 1 3 4 4 3 3 1 3 4 5 ...
    ##  $ installment_rate    : int  4 2 2 2 3 2 3 2 2 4 ...
    ##  $ personal_status     : Factor w/ 4 levels "divorced male",..: 4 2 4 4 4 4 4 4 1 3 ...
    ##  $ other_debtors       : Factor w/ 3 levels "co-applicant",..: 3 3 3 2 3 3 3 3 3 3 ...
    ##  $ residence_history   : int  4 2 3 4 4 4 4 2 4 2 ...
    ##  $ property            : Factor w/ 4 levels "building society savings",..: 3 3 3 1 4 4 1 2 3 2 ...
    ##  $ age                 : int  67 22 49 45 53 35 53 35 61 28 ...
    ##  $ installment_plan    : Factor w/ 3 levels "bank","none",..: 2 2 2 2 2 2 2 2 2 2 ...
    ##  $ housing             : Factor w/ 3 levels "for free","own",..: 2 2 2 1 1 1 2 3 2 2 ...
    ##  $ existing_credits    : int  2 1 1 1 2 1 1 1 1 2 ...
    ##  $ default             : Factor w/ 2 levels "no","yes": 1 2 1 1 2 1 1 1 1 2 ...
    ##  $ dependents          : int  1 1 2 2 2 2 1 1 1 1 ...
    ##  $ telephone           : Factor w/ 2 levels "none","yes": 2 1 1 1 1 2 1 2 1 1 ...
    ##  $ foreign_worker      : Factor w/ 2 levels "no","yes": 2 2 2 2 2 2 2 2 2 2 ...
    ##  $ job                 : Factor w/ 4 levels "mangement self-employed",..: 2 2 4 2 2 4 2 1 4 1 ...

We see the expected 1,000 observations and 21 features, which are a
combination of factor and integer data types.

Let’s take a look at the `table()` output for a couple of loan features
that seem likely to predict a default. The applicant’s checking and
savings account balance are recorded as categorical variables:

    table(credit$checking_balance)

    ## 
    ##     < 0 DM   > 200 DM 1 - 200 DM    unknown 
    ##        274         63        269        394

    table(credit$savings_balance)

    ## 
    ##      < 100 DM     > 1000 DM  101 - 500 DM 501 - 1000 DM       unknown 
    ##           603            48           103            63           183

The checking and savings account balance may prove to be important
predictors of loan default status. Note that since the loan data was
obtained from Germany, the values use the Deutsche Mark (DM), which was
the currency used in Germany prior to the adoption of the Euro.

Some of the loan’s features are numeric, such as its duration and the
amount of credit requested:

    summary(credit$months_loan_duration)

    ##    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
    ##     4.0    12.0    18.0    20.9    24.0    72.0

    summary(credit$amount)

    ##    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
    ##     250    1366    2320    3271    3972   18424

The loan amounts ranged from 250 DM to 18,424 DM across terms of four to
72 months. They had a median amount of 2,320 DM and median duration of
18 months.

The `default` vector indicates whether the loan applicant was able to
meet the agreed payment terms or if they went into default. A total of
30 percent of the loans in this dataset went into default:

    table(credit$default)

    ## 
    ##  no yes 
    ## 700 300

A high rate of default is undesirable for a bank because it means that
the bank is unlikely to fully recover its investment. If this model is
successful, we will identify applicants who are at high risk of default,
allowing the bank to refuse the credit request before the money is
given.

Data preparation – creating random training and test datasets
-------------------------------------------------------------

We will split our data into two portions: a training dataset to build
the decision tree and a test dataset to evaluate its performance on new
data. We will use 90 percent of the data for training and 10 percent for
testing, which will provide us with 100 records to simulate new
applicants.

The data is not random in this dataset so we need to make a random
sample of the data.

The following commands use `sample()` with a seed value. Note that the
`set.seed()` function uses the arbitrary value 123. Omitting this seed
will cause your training and testing splits to differ from those shown
in the remainder of this chapter. We are using R version 3.6.0 or
greater, we will need to request the random number generator from R
version 3.5.2 using the `RNGversion("3.5.2")` command. The following
commands select 900 values at random out of the sequence of integers
from 1 to 1,000:

    RNGversion("3.5.2"); set.seed(123)

    ## Warning in RNGkind("Mersenne-Twister", "Inversion", "Rounding"): non-uniform
    ## 'Rounding' sampler used

    train_sample <- sample(1000, 900)
    str(train_sample)

    ##  int [1:900] 288 788 409 881 937 46 525 887 548 453 ...

As expected, the resulting `train_sample object` is a vector of 900
random integers.

By using this vector to select rows from the credit data, we can split
it into the 90 percent training and 10 percent test datasets we desired.

    credit_train <- credit[train_sample, ]
    credit_test <- credit[-train_sample, ]

If randomization was done correctly, we should have about 30 percent of
loans with default in each of the datasets:

    prop.table(table(credit_train$default))

    ## 
    ##        no       yes 
    ## 0.7033333 0.2966667

    prop.table(table(credit_test$default))

    ## 
    ##   no  yes 
    ## 0.67 0.33

Both the training and test datasets had similar distributions of loan
defaults, so we can now build our decision tree.

Training a model on the data
----------------------------

We will use the C5.0 algorithm in the C50 package for training our
decision tree model.Install the package with `install.packages("C50")`
and load it to your R session using `library(C50)`.

    #install.packages("C50")
    library(C50)

    ## Warning: package 'C50' was built under R version 3.6.3

    #?C5.0Control

Column 17 in `credit_train` is the class variable, `default`, so we need
to exclude it from the training data frame and supply it as the target
factor vector for classification:

    credit_model <- C5.0(credit_train[-17], credit_train$default)
    credit_model

    ## 
    ## Call:
    ## C5.0.default(x = credit_train[-17], y = credit_train$default)
    ## 
    ## Classification Tree
    ## Number of samples: 900 
    ## Number of predictors: 20 
    ## 
    ## Tree size: 54 
    ## 
    ## Non-standard options: attempt to group attributes

the tree size of 54, which indicates that the tree is 54 decisions
deep—quite a bit larger than we expected.

    summary(credit_model)

    ## 
    ## Call:
    ## C5.0.default(x = credit_train[-17], y = credit_train$default)
    ## 
    ## 
    ## C5.0 [Release 2.07 GPL Edition]      Wed Aug 25 10:34:13 2021
    ## -------------------------------
    ## 
    ## Class specified by attribute `outcome'
    ## 
    ## Read 900 cases (21 attributes) from undefined.data
    ## 
    ## Decision tree:
    ## 
    ## checking_balance in {> 200 DM,unknown}: no (412/50)
    ## checking_balance in {< 0 DM,1 - 200 DM}:
    ## :...other_debtors = guarantor:
    ##     :...months_loan_duration > 36: yes (4/1)
    ##     :   months_loan_duration <= 36:
    ##     :   :...installment_plan in {none,stores}: no (24)
    ##     :       installment_plan = bank:
    ##     :       :...purpose = car (new): yes (3)
    ##     :           purpose in {business,car (used),domestic appliances,education,
    ##     :                       furniture,others,radio/tv,repairs,
    ##     :                       retraining}: no (7/1)
    ##     other_debtors in {co-applicant,none}:
    ##     :...credit_history = critical: no (102/30)
    ##         credit_history = fully repaid: yes (27/6)
    ##         credit_history = fully repaid this bank:
    ##         :...other_debtors = co-applicant: no (2)
    ##         :   other_debtors = none: yes (26/8)
    ##         credit_history in {delayed,repaid}:
    ##         :...savings_balance in {> 1000 DM,501 - 1000 DM}: no (19/3)
    ##             savings_balance = 101 - 500 DM:
    ##             :...other_debtors = co-applicant: yes (3)
    ##             :   other_debtors = none:
    ##             :   :...personal_status in {divorced male,
    ##             :       :                   married male}: yes (6/1)
    ##             :       personal_status = female:
    ##             :       :...installment_rate <= 3: no (4/1)
    ##             :       :   installment_rate > 3: yes (4)
    ##             :       personal_status = single male:
    ##             :       :...age <= 41: no (15/2)
    ##             :           age > 41: yes (2)
    ##             savings_balance = unknown:
    ##             :...credit_history = delayed: no (8)
    ##             :   credit_history = repaid:
    ##             :   :...foreign_worker = no: no (2)
    ##             :       foreign_worker = yes:
    ##             :       :...checking_balance = < 0 DM:
    ##             :           :...telephone = none: yes (11/2)
    ##             :           :   telephone = yes:
    ##             :           :   :...amount <= 5045: no (5/1)
    ##             :           :       amount > 5045: yes (2)
    ##             :           checking_balance = 1 - 200 DM:
    ##             :           :...residence_history > 3: no (9)
    ##             :               residence_history <= 3: [S1]
    ##             savings_balance = < 100 DM:
    ##             :...months_loan_duration > 39:
    ##                 :...residence_history <= 1: no (2)
    ##                 :   residence_history > 1: yes (19/1)
    ##                 months_loan_duration <= 39:
    ##                 :...purpose in {car (new),retraining}: yes (47/16)
    ##                     purpose in {domestic appliances,others}: no (3)
    ##                     purpose = car (used):
    ##                     :...amount <= 8086: no (9/1)
    ##                     :   amount > 8086: yes (5)
    ##                     purpose = education:
    ##                     :...checking_balance = < 0 DM: yes (5)
    ##                     :   checking_balance = 1 - 200 DM: no (2)
    ##                     purpose = repairs:
    ##                     :...residence_history <= 3: yes (4/1)
    ##                     :   residence_history > 3: no (3)
    ##                     purpose = business:
    ##                     :...credit_history = delayed: yes (2)
    ##                     :   credit_history = repaid:
    ##                     :   :...age <= 34: no (5)
    ##                     :       age > 34: yes (2)
    ##                     purpose = radio/tv:
    ##                     :...employment_length in {0 - 1 yrs,
    ##                     :   :                     unemployed}: yes (14/5)
    ##                     :   employment_length = 4 - 7 yrs: no (3)
    ##                     :   employment_length = > 7 yrs:
    ##                     :   :...amount <= 932: yes (2)
    ##                     :   :   amount > 932: no (7)
    ##                     :   employment_length = 1 - 4 yrs:
    ##                     :   :...months_loan_duration <= 15: no (6)
    ##                     :       months_loan_duration > 15:
    ##                     :       :...amount <= 3275: yes (7)
    ##                     :           amount > 3275: no (2)
    ##                     purpose = furniture:
    ##                     :...residence_history <= 1: no (8/1)
    ##                         residence_history > 1:
    ##                         :...installment_plan in {bank,stores}: no (3/1)
    ##                             installment_plan = none:
    ##                             :...telephone = yes: yes (7/1)
    ##                                 telephone = none:
    ##                                 :...months_loan_duration > 27: yes (3)
    ##                                     months_loan_duration <= 27: [S2]
    ## 
    ## SubTree [S1]
    ## 
    ## property in {building society savings,unknown/none}: yes (4)
    ## property = other: no (6)
    ## property = real estate:
    ## :...job = skilled employee: yes (2)
    ##     job in {mangement self-employed,unemployed non-resident,
    ##             unskilled resident}: no (2)
    ## 
    ## SubTree [S2]
    ## 
    ## checking_balance = 1 - 200 DM: yes (5/2)
    ## checking_balance = < 0 DM:
    ## :...property in {building society savings,real estate,unknown/none}: no (8)
    ##     property = other:
    ##     :...installment_rate <= 1: no (2)
    ##         installment_rate > 1: yes (4)
    ## 
    ## 
    ## Evaluation on training data (900 cases):
    ## 
    ##      Decision Tree   
    ##    ----------------  
    ##    Size      Errors  
    ## 
    ##      54  135(15.0%)   <<
    ## 
    ## 
    ##     (a)   (b)    <-classified as
    ##    ----  ----
    ##     589    44    (a): class no
    ##      91   176    (b): class yes
    ## 
    ## 
    ##  Attribute usage:
    ## 
    ##  100.00% checking_balance
    ##   54.22% other_debtors
    ##   50.00% credit_history
    ##   32.56% savings_balance
    ##   25.22% months_loan_duration
    ##   19.78% purpose
    ##   10.11% residence_history
    ##    7.33% installment_plan
    ##    5.22% telephone
    ##    4.78% foreign_worker
    ##    4.56% employment_length
    ##    4.33% amount
    ##    3.44% personal_status
    ##    3.11% property
    ##    2.67% age
    ##    1.56% installment_rate
    ##    0.44% job
    ## 
    ## 
    ## Time: 0.0 secs

The `Errors` heading shows that the model correctly classified all but
135 of the 900 training instances for an error rate of 15 percent. A
total of 44 actual `no` values were incorrectly classified as `yes`
(false positives), while 91 `yes` values were misclassified as `no`
(false negatives).

Given the tendency of decision trees to overfit to the training data,
the error rate reported here, which is based on training data
performance, may be overly optimistic. Therefore, it is especially
important to continue our evaluation by applying our decision tree to a
test dataset.

Evaluating model performance
----------------------------

To apply our decision tree to the test dataset, we use the `predict()`
function as shown in the following line of code. We can compare to the
actual class values using the `CrossTable()` function in the `gmodels`
package. Setting the `prop.c` and `prop.r` parameters to `FALSE` removes
the column and row percentages from the table. The remaining percentage
(`prop.t`) indicates the proportion of records in the cell out of the
total number of records:

    credit_pred <- predict(credit_model, credit_test)
    #install.packages("gmodels")
    library(gmodels)

    ## Warning: package 'gmodels' was built under R version 3.6.3

    CrossTable(credit_test$default, credit_pred,
               prop.chisq = FALSE, prop.c = FALSE, prop.r = FALSE,
               dnn = c('actual default', 'predicted default'))

    ## 
    ##  
    ##    Cell Contents
    ## |-------------------------|
    ## |                       N |
    ## |         N / Table Total |
    ## |-------------------------|
    ## 
    ##  
    ## Total Observations in Table:  100 
    ## 
    ##  
    ##                | predicted default 
    ## actual default |        no |       yes | Row Total | 
    ## ---------------|-----------|-----------|-----------|
    ##             no |        60 |         7 |        67 | 
    ##                |     0.600 |     0.070 |           | 
    ## ---------------|-----------|-----------|-----------|
    ##            yes |        19 |        14 |        33 | 
    ##                |     0.190 |     0.140 |           | 
    ## ---------------|-----------|-----------|-----------|
    ##   Column Total |        79 |        21 |       100 | 
    ## ---------------|-----------|-----------|-----------|
    ## 
    ## 

Out of the 100 loan applications in the test set, our model correctly
predicted that 60 did not default and 14 did default, resulting in an
accuracy of 74 percent and an error rate of 26 percent. This is somewhat
worse than its performance on the training data, but not unexpected,
given that a model’s performance is often worse on unseen data. Also
note that the model only correctly predicted 14 of the 33 actual loan
defaults in the test data, or 42 percent. Unfortunately, this type of
error is potentially a very costly mistake, as the bank loses money on
each default. Let’s see if we can improve the result with a bit more
effort.

Improving model performance
---------------------------

Our model’s error rate is likely to be too high to deploy it in a
real-time credit scoring application. In fact, if the model had
predicted “no default” for every test case, it would have been correct
67 percent of the time—a result not much worse than our model but
requiring much less effort! Predicting loan defaults from 900 examples
seems to be a challenging problem.

Making matters even worse, our model performed especially poorly at
identifying applicants who do default on their loans. Luckily, there are
a couple of simple ways to adjust the C5.0 algorithm that may help to
improve the performance of the model, both overall and for the costlier
type of mistakes.

The `C5.0()` function makes it easy to add boosting to our decision
tree. We simply need to add an additional `trials` parameter indicating
the number of separate decision trees to use in the boosted team. The
`trials` parameter sets an upper limit; the algorithm will stop adding
trees if it recognizes that additional `trials` do not seem to be
improving the accuracy. We’ll start with `10` `trials`, a number that
has become the de facto standard, as research suggests that this reduces
error rates on test data by about 25 percent. Aside from the new
parameter, the command is similar to before:

    credit_boost10 <- C5.0(credit_train[-17], credit_train$default, trials = 10)
    credit_boost10

    ## 
    ## Call:
    ## C5.0.default(x = credit_train[-17], y = credit_train$default, trials = 10)
    ## 
    ## Classification Tree
    ## Number of samples: 900 
    ## Number of predictors: 20 
    ## 
    ## Number of boosting iterations: 10 
    ## Average tree size: 49.7 
    ## 
    ## Non-standard options: attempt to group attributes

    summary(credit_boost10)

    ## 
    ## Call:
    ## C5.0.default(x = credit_train[-17], y = credit_train$default, trials = 10)
    ## 
    ## 
    ## C5.0 [Release 2.07 GPL Edition]      Wed Aug 25 10:34:13 2021
    ## -------------------------------
    ## 
    ## Class specified by attribute `outcome'
    ## 
    ## Read 900 cases (21 attributes) from undefined.data
    ## 
    ## -----  Trial 0:  -----
    ## 
    ## Decision tree:
    ## 
    ## checking_balance in {> 200 DM,unknown}: no (412/50)
    ## checking_balance in {< 0 DM,1 - 200 DM}:
    ## :...other_debtors = guarantor:
    ##     :...months_loan_duration > 36: yes (4/1)
    ##     :   months_loan_duration <= 36:
    ##     :   :...installment_plan in {none,stores}: no (24)
    ##     :       installment_plan = bank:
    ##     :       :...purpose = car (new): yes (3)
    ##     :           purpose in {business,car (used),domestic appliances,education,
    ##     :                       furniture,others,radio/tv,repairs,
    ##     :                       retraining}: no (7/1)
    ##     other_debtors in {co-applicant,none}:
    ##     :...credit_history = critical: no (102/30)
    ##         credit_history = fully repaid: yes (27/6)
    ##         credit_history = fully repaid this bank:
    ##         :...other_debtors = co-applicant: no (2)
    ##         :   other_debtors = none: yes (26/8)
    ##         credit_history in {delayed,repaid}:
    ##         :...savings_balance in {> 1000 DM,501 - 1000 DM}: no (19/3)
    ##             savings_balance = 101 - 500 DM:
    ##             :...other_debtors = co-applicant: yes (3)
    ##             :   other_debtors = none:
    ##             :   :...personal_status in {divorced male,
    ##             :       :                   married male}: yes (6/1)
    ##             :       personal_status = female:
    ##             :       :...installment_rate <= 3: no (4/1)
    ##             :       :   installment_rate > 3: yes (4)
    ##             :       personal_status = single male:
    ##             :       :...age <= 41: no (15/2)
    ##             :           age > 41: yes (2)
    ##             savings_balance = unknown:
    ##             :...credit_history = delayed: no (8)
    ##             :   credit_history = repaid:
    ##             :   :...foreign_worker = no: no (2)
    ##             :       foreign_worker = yes:
    ##             :       :...checking_balance = < 0 DM:
    ##             :           :...telephone = none: yes (11/2)
    ##             :           :   telephone = yes:
    ##             :           :   :...amount <= 5045: no (5/1)
    ##             :           :       amount > 5045: yes (2)
    ##             :           checking_balance = 1 - 200 DM:
    ##             :           :...residence_history > 3: no (9)
    ##             :               residence_history <= 3: [S1]
    ##             savings_balance = < 100 DM:
    ##             :...months_loan_duration > 39:
    ##                 :...residence_history <= 1: no (2)
    ##                 :   residence_history > 1: yes (19/1)
    ##                 months_loan_duration <= 39:
    ##                 :...purpose in {car (new),retraining}: yes (47/16)
    ##                     purpose in {domestic appliances,others}: no (3)
    ##                     purpose = car (used):
    ##                     :...amount <= 8086: no (9/1)
    ##                     :   amount > 8086: yes (5)
    ##                     purpose = education:
    ##                     :...checking_balance = < 0 DM: yes (5)
    ##                     :   checking_balance = 1 - 200 DM: no (2)
    ##                     purpose = repairs:
    ##                     :...residence_history <= 3: yes (4/1)
    ##                     :   residence_history > 3: no (3)
    ##                     purpose = business:
    ##                     :...credit_history = delayed: yes (2)
    ##                     :   credit_history = repaid:
    ##                     :   :...age <= 34: no (5)
    ##                     :       age > 34: yes (2)
    ##                     purpose = radio/tv:
    ##                     :...employment_length in {0 - 1 yrs,
    ##                     :   :                     unemployed}: yes (14/5)
    ##                     :   employment_length = 4 - 7 yrs: no (3)
    ##                     :   employment_length = > 7 yrs:
    ##                     :   :...amount <= 932: yes (2)
    ##                     :   :   amount > 932: no (7)
    ##                     :   employment_length = 1 - 4 yrs:
    ##                     :   :...months_loan_duration <= 15: no (6)
    ##                     :       months_loan_duration > 15:
    ##                     :       :...amount <= 3275: yes (7)
    ##                     :           amount > 3275: no (2)
    ##                     purpose = furniture:
    ##                     :...residence_history <= 1: no (8/1)
    ##                         residence_history > 1:
    ##                         :...installment_plan in {bank,stores}: no (3/1)
    ##                             installment_plan = none:
    ##                             :...telephone = yes: yes (7/1)
    ##                                 telephone = none:
    ##                                 :...months_loan_duration > 27: yes (3)
    ##                                     months_loan_duration <= 27: [S2]
    ## 
    ## SubTree [S1]
    ## 
    ## property in {building society savings,unknown/none}: yes (4)
    ## property = other: no (6)
    ## property = real estate:
    ## :...job = skilled employee: yes (2)
    ##     job in {mangement self-employed,unemployed non-resident,
    ##             unskilled resident}: no (2)
    ## 
    ## SubTree [S2]
    ## 
    ## checking_balance = 1 - 200 DM: yes (5/2)
    ## checking_balance = < 0 DM:
    ## :...property in {building society savings,real estate,unknown/none}: no (8)
    ##     property = other:
    ##     :...installment_rate <= 1: no (2)
    ##         installment_rate > 1: yes (4)
    ## 
    ## -----  Trial 1:  -----
    ## 
    ## Decision tree:
    ## 
    ## foreign_worker = no: no (28.4/2.4)
    ## foreign_worker = yes:
    ## :...checking_balance = unknown:
    ##     :...installment_plan in {bank,stores}:
    ##     :   :...other_debtors in {co-applicant,guarantor}: no (2.4)
    ##     :   :   other_debtors = none:
    ##     :   :   :...employment_length in {> 7 yrs,0 - 1 yrs,
    ##     :   :       :                     4 - 7 yrs}: no (32.3/10.8)
    ##     :   :       employment_length in {1 - 4 yrs,unemployed}: yes (31/7.1)
    ##     :   installment_plan = none:
    ##     :   :...credit_history in {critical,fully repaid,fully repaid this bank,
    ##     :       :                  repaid}: no (224.7/32.5)
    ##     :       credit_history = delayed:
    ##     :       :...residence_history <= 1: yes (4.3)
    ##     :           residence_history > 1:
    ##     :           :...installment_rate <= 3: no (11.9)
    ##     :               installment_rate > 3: yes (14.2/5.6)
    ##     checking_balance in {< 0 DM,> 200 DM,1 - 200 DM}:
    ##     :...other_debtors = co-applicant: yes (24.3/7.9)
    ##         other_debtors = guarantor:
    ##         :...property in {building society savings,real estate,
    ##         :   :            unknown/none}: no (27.6/4)
    ##         :   property = other: yes (3)
    ##         other_debtors = none:
    ##         :...installment_rate <= 2:
    ##             :...purpose in {business,car (new),car (used),domestic appliances,
    ##             :   :           others,radio/tv,retraining}: no (125.5/34.3)
    ##             :   purpose in {education,repairs}: yes (13.6/4.8)
    ##             :   purpose = furniture:
    ##             :   :...job in {mangement self-employed,
    ##             :       :       unemployed non-resident}: yes (4.3)
    ##             :       job in {skilled employee,unskilled resident}:
    ##             :       :...dependents > 1: yes (2.2)
    ##             :           dependents <= 1:
    ##             :           :...checking_balance = > 200 DM: no (4)
    ##             :               checking_balance in {< 0 DM,1 - 200 DM}:
    ##             :               :...telephone = none: yes (24.9/10.1)
    ##             :                   telephone = yes: no (10.1/2.4)
    ##             installment_rate > 2:
    ##             :...residence_history <= 1: no (39/8.5)
    ##                 residence_history > 1:
    ##                 :...credit_history = fully repaid: yes (11.7)
    ##                     credit_history in {critical,delayed,fully repaid this bank,
    ##                     :                  repaid}:
    ##                     :...months_loan_duration <= 11:
    ##                         :...purpose in {business,car (new),car (used),
    ##                         :   :           domestic appliances,furniture,others,
    ##                         :   :           radio/tv,repairs,
    ##                         :   :           retraining}: no (35.2/6.9)
    ##                         :   purpose = education: yes (5.3/0.8)
    ##                         months_loan_duration > 11:
    ##                         :...savings_balance = > 1000 DM: no (9.1/2.2)
    ##                             savings_balance = 501 - 1000 DM: yes (15.4/5.9)
    ##                             savings_balance = 101 - 500 DM:
    ##                             :...installment_plan in {bank,
    ##                             :   :                    stores}: yes (8.3/0.8)
    ##                             :   installment_plan = none: no (16.2/4.5)
    ##                             savings_balance = unknown:
    ##                             :...checking_balance in {< 0 DM,
    ##                             :   :                    > 200 DM}: yes (20.8/5.6)
    ##                             :   checking_balance = 1 - 200 DM: no (12.7/1.6)
    ##                             savings_balance = < 100 DM:
    ##                             :...installment_plan in {bank,
    ##                                 :                    stores}: yes (25.3/3.2)
    ##                                 installment_plan = none:
    ##                                 :...dependents > 1: no (14.4/5.6)
    ##                                     dependents <= 1:
    ##                                     :...months_loan_duration > 42: yes (11.5)
    ##                                         months_loan_duration <= 42: [S1]
    ## 
    ## SubTree [S1]
    ## 
    ## credit_history in {delayed,fully repaid this bank}: yes (5.3)
    ## credit_history = repaid:
    ## :...job in {mangement self-employed,unskilled resident}: no (23.2/8.7)
    ## :   job in {skilled employee,unemployed non-resident}: yes (24.2/7.1)
    ## credit_history = critical:
    ## :...existing_credits <= 1: no (6.9/2.2)
    ##     existing_credits > 1:
    ##     :...purpose in {business,car (new),domestic appliances,education,furniture,
    ##         :           others,repairs,retraining}: yes (22.7/3.2)
    ##         purpose in {car (used),radio/tv}: no (4)
    ## 
    ## -----  Trial 2:  -----
    ## 
    ## Decision tree:
    ## 
    ## checking_balance = unknown:
    ## :...installment_plan = bank:
    ## :   :...other_debtors = guarantor: yes (0)
    ## :   :   other_debtors = co-applicant: no (1.3)
    ## :   :   other_debtors = none:
    ## :   :   :...months_loan_duration <= 8: no (3.4)
    ## :   :       months_loan_duration > 8: yes (44.9/16.4)
    ## :   installment_plan in {none,stores}:
    ## :   :...employment_length in {> 7 yrs,1 - 4 yrs,4 - 7 yrs}:
    ## :       :...installment_rate <= 3: no (91.9/5.8)
    ## :       :   installment_rate > 3:
    ## :       :   :...age > 30: no (70.1/5.3)
    ## :       :       age <= 30:
    ## :       :       :...other_debtors = co-applicant: no (0.6)
    ## :       :           other_debtors = guarantor: yes (3.5/0.6)
    ## :       :           other_debtors = none:
    ## :       :           :...housing = for free: no (0.6)
    ## :       :               housing = rent: yes (4.8/1.9)
    ## :       :               housing = own:
    ## :       :               :...amount <= 1445: no (8)
    ## :       :                   amount > 1445: yes (23.7/8)
    ## :       employment_length in {0 - 1 yrs,unemployed}:
    ## :       :...other_debtors = guarantor: no (0)
    ## :           other_debtors = co-applicant: yes (8.6)
    ## :           other_debtors = none:
    ## :           :...months_loan_duration > 30: yes (7.5)
    ## :               months_loan_duration <= 30:
    ## :               :...housing in {for free,rent}: no (5.8)
    ## :                   housing = own:
    ## :                   :...amount > 4594: yes (5.8)
    ## :                       amount <= 4594:
    ## :                       :...purpose in {business,repairs}: yes (4.6)
    ## :                           purpose in {car (new),car (used),
    ## :                                       domestic appliances,education,
    ## :                                       furniture,others,radio/tv,
    ## :                                       retraining}: no (20.7)
    ## checking_balance in {< 0 DM,> 200 DM,1 - 200 DM}:
    ## :...months_loan_duration > 42:
    ##     :...savings_balance in {< 100 DM,> 1000 DM,101 - 500 DM}: yes (42.1/6.1)
    ##     :   savings_balance in {501 - 1000 DM,unknown}: no (7.2)
    ##     months_loan_duration <= 42:
    ##     :...foreign_worker = no: no (15.8/3)
    ##         foreign_worker = yes:
    ##         :...other_debtors = co-applicant: no (26.3/12.7)
    ##             other_debtors = guarantor:
    ##             :...installment_plan = bank: yes (9.5/3.2)
    ##             :   installment_plan in {none,stores}: no (17.5/1.5)
    ##             other_debtors = none:
    ##             :...purpose in {domestic appliances,others,
    ##                 :           retraining}: no (10/1.9)
    ##                 purpose = repairs: yes (14.2/6.1)
    ##                 purpose = education:
    ##                 :...checking_balance = < 0 DM: yes (10.1)
    ##                 :   checking_balance in {> 200 DM,1 - 200 DM}: no (18.2/7.3)
    ##                 purpose = business:
    ##                 :...months_loan_duration <= 18: no (11.3)
    ##                 :   months_loan_duration > 18:
    ##                 :   :...telephone = none: no (10.4/2.8)
    ##                 :       telephone = yes: yes (19.9/6)
    ##                 purpose = car (used):
    ##                 :...credit_history in {critical,delayed,
    ##                 :   :                  fully repaid}: no (7.8)
    ##                 :   credit_history in {fully repaid this bank,repaid}:
    ##                 :   :...amount <= 3161: no (6.5)
    ##                 :       amount > 3161: yes (20.4/5.7)
    ##                 purpose = car (new):
    ##                 :...credit_history = delayed: no (14.6/6.7)
    ##                 :   credit_history in {fully repaid,
    ##                 :   :                  fully repaid this bank}: yes (11/1.8)
    ##                 :   credit_history = critical:
    ##                 :   :...installment_rate <= 3: no (9.3)
    ##                 :   :   installment_rate > 3: yes (21/6.9)
    ##                 :   credit_history = repaid:
    ##                 :   :...personal_status = divorced male: yes (3)
    ##                 :       personal_status = married male: no (6.3/2.2)
    ##                 :       personal_status = female:
    ##                 :       :...job in {mangement self-employed,
    ##                 :       :   :       unemployed non-resident}: no (2.6)
    ##                 :       :   job in {skilled employee,
    ##                 :       :           unskilled resident}: yes (27.2/3.5)
    ##                 :       personal_status = single male:
    ##                 :       :...amount <= 8229: no (29.5/9.1)
    ##                 :           amount > 8229: yes (6)
    ##                 purpose = radio/tv:
    ##                 :...employment_length in {> 7 yrs,4 - 7 yrs}: no (34.3/5)
    ##                 :   employment_length in {0 - 1 yrs,1 - 4 yrs,unemployed}:
    ##                 :   :...existing_credits > 1: yes (13.6/2.2)
    ##                 :       existing_credits <= 1:
    ##                 :       :...savings_balance in {> 1000 DM,101 - 500 DM,
    ##                 :           :                   unknown}: yes (7.3/1.3)
    ##                 :           savings_balance = 501 - 1000 DM: no (6.5/1.8)
    ##                 :           savings_balance = < 100 DM:
    ##                 :           :...amount > 4473: no (4.2)
    ##                 :               amount <= 4473:
    ##                 :               :...months_loan_duration <= 7: no (2.4)
    ##                 :                   months_loan_duration > 7: yes (40.6/11.5)
    ##                 purpose = furniture:
    ##                 :...installment_plan = stores: no (11.2)
    ##                     installment_plan in {bank,none}:
    ##                     :...dependents > 1: yes (5.2/0.6)
    ##                         dependents <= 1:
    ##                         :...checking_balance = > 200 DM: no (6.9)
    ##                             checking_balance in {< 0 DM,1 - 200 DM}:
    ##                             :...savings_balance in {> 1000 DM,
    ##                                 :                   unknown}: no (14/4.3)
    ##                                 savings_balance in {101 - 500 DM,
    ##                                 :                   501 - 1000 DM}: yes (3.7/0.6)
    ##                                 savings_balance = < 100 DM: [S1]
    ## 
    ## SubTree [S1]
    ## 
    ## job in {mangement self-employed,unemployed non-resident,
    ## :       unskilled resident}: yes (24.6/9.1)
    ## job = skilled employee:
    ## :...credit_history in {critical,delayed,fully repaid,repaid}: no (38.6/13.8)
    ##     credit_history = fully repaid this bank: yes (2.8)
    ## 
    ## -----  Trial 3:  -----
    ## 
    ## Decision tree:
    ## 
    ## checking_balance = unknown:
    ## :...employment_length in {> 7 yrs,1 - 4 yrs,4 - 7 yrs}: no (235.6/50.4)
    ## :   employment_length in {0 - 1 yrs,unemployed}:
    ## :   :...other_debtors = guarantor: no (0)
    ## :       other_debtors = co-applicant: yes (7.5/0.5)
    ## :       other_debtors = none:
    ## :       :...purpose = others: no (0)
    ## :           purpose in {business,repairs}: yes (9)
    ## :           purpose in {car (new),car (used),domestic appliances,education,
    ## :           :           furniture,radio/tv,retraining}:
    ## :           :...amount <= 4594: no (23.4)
    ## :               amount > 4594: yes (11.8/1.1)
    ## checking_balance in {< 0 DM,> 200 DM,1 - 200 DM}:
    ## :...other_debtors = guarantor: no (31.5/9.1)
    ##     other_debtors = co-applicant:
    ##     :...savings_balance in {> 1000 DM,501 - 1000 DM}: yes (0)
    ##     :   savings_balance = unknown: no (3.5)
    ##     :   savings_balance in {< 100 DM,101 - 500 DM}:
    ##     :   :...amount <= 2022: no (5.4)
    ##     :       amount > 2022:
    ##     :       :...employment_length in {> 7 yrs,0 - 1 yrs,1 - 4 yrs,
    ##     :           :                     4 - 7 yrs}: yes (24.5/2.4)
    ##     :           employment_length = unemployed: no (2.4)
    ##     other_debtors = none:
    ##     :...purpose in {domestic appliances,others}: yes (9.8/4.6)
    ##         purpose in {repairs,retraining}: no (22/8)
    ##         purpose = car (used):
    ##         :...personal_status in {divorced male,single male}: no (29.7/6.9)
    ##         :   personal_status in {female,married male}: yes (13/4.1)
    ##         purpose = education:
    ##         :...employment_length in {> 7 yrs,0 - 1 yrs,1 - 4 yrs,
    ##         :   :                     unemployed}: yes (25.7/5.9)
    ##         :   employment_length = 4 - 7 yrs: no (5.9/1.4)
    ##         purpose = business:
    ##         :...age > 46: yes (5.2)
    ##         :   age <= 46:
    ##         :   :...amount <= 10722: no (43.7/12.9)
    ##         :       amount > 10722: yes (3.7)
    ##         purpose = car (new):
    ##         :...credit_history = critical:
    ##         :   :...personal_status in {divorced male,female,
    ##         :   :   :                   single male}: no (31.7/7.2)
    ##         :   :   personal_status = married male: yes (4.3)
    ##         :   credit_history in {delayed,fully repaid,fully repaid this bank,
    ##         :   :                  repaid}:
    ##         :   :...installment_rate > 2: yes (63.2/15.8)
    ##         :       installment_rate <= 2:
    ##         :       :...employment_length = > 7 yrs: yes (9.4)
    ##         :           employment_length in {0 - 1 yrs,1 - 4 yrs,4 - 7 yrs,
    ##         :           :                     unemployed}:
    ##         :           :...amount <= 1386: yes (7.7/0.5)
    ##         :               amount > 1386: no (31.5/7.2)
    ##         purpose = radio/tv:
    ##         :...dependents > 1: yes (8.5/1.6)
    ##         :   dependents <= 1:
    ##         :   :...employment_length = > 7 yrs: no (15.9/1.4)
    ##         :       employment_length in {0 - 1 yrs,1 - 4 yrs,4 - 7 yrs,unemployed}:
    ##         :       :...housing = for free: yes (4.2/0.5)
    ##         :           housing = rent: no (15.2/5.8)
    ##         :           housing = own:
    ##         :           :...months_loan_duration <= 39: no (68/30)
    ##         :               months_loan_duration > 39: yes (7.4/0.5)
    ##         purpose = furniture:
    ##         :...installment_plan = stores: no (9.1)
    ##             installment_plan in {bank,none}:
    ##             :...amount > 4281: yes (15.8/2.8)
    ##                 amount <= 4281:
    ##                 :...housing = for free: no (6.6/0.5)
    ##                     housing in {own,rent}:
    ##                     :...amount > 3573: no (17/3.4)
    ##                         amount <= 3573:
    ##                         :...personal_status = divorced male: no (7.5/2)
    ##                             personal_status in {married male,
    ##                             :                   single male}: yes (25.6/10.2)
    ##                             personal_status = female:
    ##                             :...residence_history <= 1: no (4.1)
    ##                                 residence_history > 1:
    ##                                 :...age <= 37: yes (30/6.1)
    ##                                     age > 37: no (4.1)
    ## 
    ## -----  Trial 4:  -----
    ## 
    ## Decision tree:
    ## 
    ## months_loan_duration <= 7:
    ## :...amount <= 3380: no (48.6/5)
    ## :   amount > 3380: yes (9.2/2.2)
    ## months_loan_duration > 7:
    ## :...savings_balance in {> 1000 DM,unknown}:
    ##     :...other_debtors = co-applicant: no (3.7)
    ##     :   other_debtors = guarantor: yes (4.7/1.6)
    ##     :   other_debtors = none:
    ##     :   :...property in {building society savings,unknown/none}:
    ##     :       :...foreign_worker = no: no (2.5)
    ##     :       :   foreign_worker = yes:
    ##     :       :   :...savings_balance = > 1000 DM: yes (15.8/3)
    ##     :       :       savings_balance = unknown:
    ##     :       :       :...installment_rate <= 1: yes (7.2/1.2)
    ##     :       :           installment_rate > 1: no (42.5/12.1)
    ##     :       property in {other,real estate}:
    ##     :       :...savings_balance = > 1000 DM: no (19.3)
    ##     :           savings_balance = unknown:
    ##     :           :...residence_history > 3: no (25/1.6)
    ##     :               residence_history <= 3:
    ##     :               :...property = real estate: yes (14.8/5.5)
    ##     :                   property = other:
    ##     :                   :...checking_balance = < 0 DM: yes (6.4/1.2)
    ##     :                       checking_balance in {> 200 DM,1 - 200 DM,
    ##     :                                            unknown}: no (20.8/1.9)
    ##     savings_balance in {< 100 DM,101 - 500 DM,501 - 1000 DM}:
    ##     :...checking_balance in {> 200 DM,unknown}:
    ##         :...other_debtors = co-applicant: yes (12.1/4.3)
    ##         :   other_debtors = guarantor: no (2.9)
    ##         :   other_debtors = none:
    ##         :   :...age > 48: no (17.2/1.2)
    ##         :       age <= 48:
    ##         :       :...purpose in {business,education,repairs}: yes (36.9/15.9)
    ##         :           purpose in {car (used),domestic appliances,others,
    ##         :           :           retraining}: no (17.1/2.1)
    ##         :           purpose = car (new):
    ##         :           :...installment_plan in {bank,stores}: yes (12.5/0.9)
    ##         :           :   installment_plan = none: no (21.1/6.4)
    ##         :           purpose = furniture:
    ##         :           :...months_loan_duration <= 30: no (31.8/8.5)
    ##         :           :   months_loan_duration > 30: yes (7.7/0.9)
    ##         :           purpose = radio/tv:
    ##         :           :...months_loan_duration <= 9: yes (8.7/0.4)
    ##         :               months_loan_duration > 9:
    ##         :               :...amount <= 2323: no (24.6)
    ##         :                   amount > 2323: [S1]
    ##         checking_balance in {< 0 DM,1 - 200 DM}:
    ##         :...months_loan_duration <= 22:
    ##             :...job = mangement self-employed: no (22.6/9.3)
    ##             :   job = unemployed non-resident: yes (6.9/0.9)
    ##             :   job = unskilled resident:
    ##             :   :...age <= 54: no (58.5/14.7)
    ##             :   :   age > 54: yes (7.5/0.9)
    ##             :   job = skilled employee:
    ##             :   :...credit_history = delayed: no (4.3/0.4)
    ##             :       credit_history = fully repaid this bank: yes (4.8)
    ##             :       credit_history in {critical,fully repaid,repaid}:
    ##             :       :...amount <= 1381:
    ##             :           :...property in {other,unknown/none}: yes (18.7/0.4)
    ##             :           :   property in {building society savings,real estate}:
    ##             :           :   :...foreign_worker = no: no (2)
    ##             :           :       foreign_worker = yes:
    ##             :           :       :...amount <= 662: no (5)
    ##             :           :           amount > 662: yes (25.4/5.4)
    ##             :           amount > 1381:
    ##             :           :...employment_length in {4 - 7 yrs,
    ##             :               :                     unemployed}: no (13.3)
    ##             :               employment_length in {> 7 yrs,0 - 1 yrs,1 - 4 yrs}:
    ##             :               :...housing = for free: yes (2.6)
    ##             :                   housing = own: no (37.8/12.6)
    ##             :                   housing = rent:
    ##             :                   :...amount <= 1480: no (4)
    ##             :                       amount > 1480: yes (22.5/4.4)
    ##             months_loan_duration > 22:
    ##             :...job = unemployed non-resident: no (1.4)
    ##                 job = unskilled resident: yes (38.6/5.5)
    ##                 job in {mangement self-employed,skilled employee}:
    ##                 :...existing_credits > 1: yes (63.2/17.9)
    ##                     existing_credits <= 1:
    ##                     :...personal_status in {divorced male,
    ##                         :                   married male}: yes (17.1/4.4)
    ##                         personal_status = female:
    ##                         :...age <= 52: yes (25.8/5)
    ##                         :   age > 52: no (2.2)
    ##                         personal_status = single male:
    ##                         :...other_debtors = co-applicant: yes (4)
    ##                             other_debtors = guarantor: no (3.2)
    ##                             other_debtors = none:
    ##                             :...amount > 7596: yes (14.2/3.1)
    ##                                 amount <= 7596:
    ##                                 :...installment_rate <= 2: no (11.6)
    ##                                     installment_rate > 2:
    ##                                     :...age <= 32: no (29.3/8.5)
    ##                                         age > 32: yes (9.9/2.8)
    ## 
    ## SubTree [S1]
    ## 
    ## credit_history in {critical,fully repaid,fully repaid this bank}: no (6.7)
    ## credit_history in {delayed,repaid}:
    ## :...existing_credits <= 1: no (12.6/5.2)
    ##     existing_credits > 1: yes (11/1.4)
    ## 
    ## -----  Trial 5:  -----
    ## 
    ## Decision tree:
    ## 
    ## checking_balance = unknown:
    ## :...installment_plan = stores: no (14.6/5.4)
    ## :   installment_plan = bank:
    ## :   :...other_debtors in {co-applicant,guarantor}: no (3.1)
    ## :   :   other_debtors = none:
    ## :   :   :...existing_credits > 2: no (3.8)
    ## :   :       existing_credits <= 2:
    ## :   :       :...housing = for free: no (8.2/1.7)
    ## :   :           housing = rent: yes (7/0.4)
    ## :   :           housing = own:
    ## :   :           :...telephone = yes: yes (8.7/1.9)
    ## :   :               telephone = none:
    ## :   :               :...age <= 30: no (6)
    ## :   :                   age > 30: yes (19.2/7)
    ## :   installment_plan = none:
    ## :   :...credit_history in {critical,fully repaid,
    ## :       :                  fully repaid this bank}: no (63.7/4)
    ## :       credit_history in {delayed,repaid}:
    ## :       :...existing_credits <= 1:
    ## :           :...purpose in {business,car (new),car (used),domestic appliances,
    ## :           :   :           education,others,radio/tv,
    ## :           :   :           retraining}: no (62.4/8.2)
    ## :           :   purpose in {furniture,repairs}: yes (20/6.2)
    ## :           existing_credits > 1:
    ## :           :...employment_length = 4 - 7 yrs: no (7.6)
    ## :               employment_length in {> 7 yrs,0 - 1 yrs,1 - 4 yrs,unemployed}:
    ## :               :...job in {mangement self-employed,
    ## :                   :       unemployed non-resident}: yes (6.9)
    ## :                   job in {skilled employee,unskilled resident}:
    ## :                   :...employment_length in {> 7 yrs,0 - 1 yrs}: yes (19.8/4.4)
    ## :                       employment_length in {1 - 4 yrs,
    ## :                                             unemployed}: no (7.2)
    ## checking_balance in {< 0 DM,> 200 DM,1 - 200 DM}:
    ## :...property = unknown/none:
    ##     :...job = unskilled resident: yes (10.7)
    ##     :   job in {mangement self-employed,skilled employee,
    ##     :   :       unemployed non-resident}:
    ##     :   :...installment_rate <= 2: no (31.5/11)
    ##     :       installment_rate > 2:
    ##     :       :...job = skilled employee: yes (40.9/10.1)
    ##     :           job = unemployed non-resident: no (1)
    ##     :           job = mangement self-employed:
    ##     :           :...dependents > 1: no (2.2)
    ##     :               dependents <= 1:
    ##     :               :...residence_history <= 1: no (4.8/1)
    ##     :                   residence_history > 1: yes (19.4/4.5)
    ##     property in {building society savings,other,real estate}:
    ##     :...purpose in {domestic appliances,others,repairs,
    ##         :           retraining}: no (28.8/11.1)
    ##         purpose = education: yes (21.7/9.7)
    ##         purpose = car (used):
    ##         :...amount <= 7253: no (20.5/1)
    ##         :   amount > 7253: yes (6.7/1.9)
    ##         purpose = business:
    ##         :...months_loan_duration <= 18: no (10.1)
    ##         :   months_loan_duration > 18:
    ##         :   :...housing = for free: no (0)
    ##         :       housing = rent: yes (9.4/1.9)
    ##         :       housing = own:
    ##         :       :...savings_balance in {> 1000 DM,101 - 500 DM,501 - 1000 DM,
    ##         :           :                   unknown}: no (11.1)
    ##         :           savings_balance = < 100 DM:
    ##         :           :...amount <= 2292: yes (7.7)
    ##         :               amount > 2292: no (17.4/7.2)
    ##         purpose = radio/tv:
    ##         :...months_loan_duration <= 8: no (6.8)
    ##         :   months_loan_duration > 8:
    ##         :   :...savings_balance = > 1000 DM: yes (0)
    ##         :       savings_balance = unknown: no (15.1/2.5)
    ##         :       savings_balance in {< 100 DM,101 - 500 DM,501 - 1000 DM}:
    ##         :       :...months_loan_duration > 36: yes (8.6)
    ##         :           months_loan_duration <= 36:
    ##         :           :...other_debtors = co-applicant: yes (2.5/0.8)
    ##         :               other_debtors = guarantor: no (9.1/1.7)
    ##         :               other_debtors = none:
    ##         :               :...employment_length in {0 - 1 yrs,
    ##         :                   :                     unemployed}: yes (25.9/5.8)
    ##         :                   employment_length in {> 7 yrs,
    ##         :                   :                     4 - 7 yrs}: no (22.2/5.7)
    ##         :                   employment_length = 1 - 4 yrs:
    ##         :                   :...months_loan_duration <= 15: no (21.4/8.1)
    ##         :                       months_loan_duration > 15: yes (23.7/5)
    ##         purpose = furniture:
    ##         :...installment_plan = stores: no (6.1)
    ##         :   installment_plan in {bank,none}:
    ##         :   :...other_debtors = guarantor: no (4.3)
    ##         :       other_debtors in {co-applicant,none}:
    ##         :       :...savings_balance = > 1000 DM: no (5.1)
    ##         :           savings_balance in {101 - 500 DM,
    ##         :           :                   501 - 1000 DM}: yes (4.1)
    ##         :           savings_balance in {< 100 DM,unknown}:
    ##         :           :...telephone = yes: no (30.4/9.6)
    ##         :               telephone = none:
    ##         :               :...personal_status = divorced male: no (4.3)
    ##         :                   personal_status in {married male,
    ##         :                   :                   single male}: yes (33.4/9.9)
    ##         :                   personal_status = female:
    ##         :                   :...installment_plan = bank: yes (2.7)
    ##         :                       installment_plan = none:
    ##         :                       :...months_loan_duration <= 9: yes (3.1)
    ##         :                           months_loan_duration > 9: no (26.5/8.1)
    ##         purpose = car (new):
    ##         :...other_debtors in {co-applicant,guarantor}: yes (12.4/2.8)
    ##             other_debtors = none:
    ##             :...property = real estate:
    ##                 :...installment_plan in {bank,stores}: yes (2.7)
    ##                 :   installment_plan = none:
    ##                 :   :...amount > 4380: no (6)
    ##                 :       amount <= 4380:
    ##                 :       :...personal_status in {divorced male,
    ##                 :           :                   female}: yes (7.3/0.4)
    ##                 :           personal_status in {married male,
    ##                 :                               single male}: no (29.7/6.1)
    ##                 property in {building society savings,other}:
    ##                 :...checking_balance = > 200 DM: no (3.7)
    ##                     checking_balance in {< 0 DM,1 - 200 DM}:
    ##                     :...amount <= 1126: yes (19.7/0.4)
    ##                         amount > 1126:
    ##                         :...installment_plan = stores: yes (0)
    ##                             installment_plan = bank: no (3.2)
    ##                             installment_plan = none:
    ##                             :...dependents > 1: no (5.9/1.2)
    ##                                 dependents <= 1: [S1]
    ## 
    ## SubTree [S1]
    ## 
    ## job in {mangement self-employed,unemployed non-resident,
    ## :       unskilled resident}: yes (19/3)
    ## job = skilled employee:
    ## :...installment_rate <= 1: no (4.9)
    ##     installment_rate > 1:
    ##     :...age <= 36: yes (23.5/7.3)
    ##         age > 36: no (4.8)
    ## 
    ## -----  Trial 6:  -----
    ## 
    ## Decision tree:
    ## 
    ## checking_balance in {> 200 DM,unknown}:
    ## :...foreign_worker = no: no (6.9)
    ## :   foreign_worker = yes:
    ## :   :...months_loan_duration <= 8: no (23.8/1.3)
    ## :       months_loan_duration > 8:
    ## :       :...job in {mangement self-employed,skilled employee,
    ## :           :       unemployed non-resident}:
    ## :           :...employment_length = > 7 yrs: no (67.6/8.6)
    ## :           :   employment_length in {0 - 1 yrs,1 - 4 yrs,4 - 7 yrs,unemployed}:
    ## :           :   :...purpose in {car (used),domestic appliances,others,repairs,
    ## :           :       :           retraining}: no (21.8/2)
    ## :           :       purpose = education: yes (16.3/8.1)
    ## :           :       purpose = business:
    ## :           :       :...existing_credits <= 2: no (23.5/8.6)
    ## :           :       :   existing_credits > 2: yes (2.9)
    ## :           :       purpose = car (new):
    ## :           :       :...property in {building society savings,real estate,
    ## :           :       :   :            unknown/none}: yes (20.1/5.9)
    ## :           :       :   property = other: no (4.1)
    ## :           :       purpose = furniture:
    ## :           :       :...months_loan_duration > 30: yes (7.5/1.9)
    ## :           :       :   months_loan_duration <= 30:
    ## :           :       :   :...age <= 22: yes (4.8/1.2)
    ## :           :       :       age > 22: no (18.5)
    ## :           :       purpose = radio/tv:
    ## :           :       :...dependents > 1: no (4.3)
    ## :           :           dependents <= 1:
    ## :           :           :...months_loan_duration <= 9: yes (4.7)
    ## :           :               months_loan_duration > 9:
    ## :           :               :...installment_rate <= 1: yes (2.1)
    ## :           :                   installment_rate > 1: no (38.2/9.1)
    ## :           job = unskilled resident:
    ## :           :...age > 48: no (6.3)
    ## :               age <= 48:
    ## :               :...purpose in {domestic appliances,others,
    ## :                   :           repairs}: yes (0)
    ## :                   purpose in {business,retraining}: no (5.2)
    ## :                   purpose in {car (new),car (used),education,furniture,
    ## :                   :           radio/tv}:
    ## :                   :...installment_plan = bank: yes (13.7/2.6)
    ## :                       installment_plan = stores: no (1.5)
    ## :                       installment_plan = none: [S1]
    ## checking_balance in {< 0 DM,1 - 200 DM}:
    ## :...credit_history in {fully repaid,fully repaid this bank}:
    ##     :...other_debtors = co-applicant: no (3.3)
    ##     :   other_debtors in {guarantor,none}:
    ##     :   :...property in {building society savings,unknown/none}: yes (36/3.1)
    ##     :       property in {other,real estate}:
    ##     :       :...housing in {for free,rent}: yes (8/0.9)
    ##     :           housing = own:
    ##     :           :...age <= 35: no (23.4/8.2)
    ##     :               age > 35: yes (7.1/0.8)
    ##     credit_history in {critical,delayed,repaid}:
    ##     :...other_debtors = guarantor: no (24.3/7.1)
    ##         other_debtors = co-applicant:
    ##         :...foreign_worker = no: no (3.5)
    ##         :   foreign_worker = yes:
    ##         :   :...installment_plan = stores: yes (0)
    ##         :       installment_plan = bank: no (1.3)
    ##         :       installment_plan = none:
    ##         :       :...amount <= 1961: no (4.9)
    ##         :           amount > 1961: yes (18.9/4.5)
    ##         other_debtors = none:
    ##         :...credit_history = delayed:
    ##             :...savings_balance in {101 - 500 DM,501 - 1000 DM,
    ##             :   :                   unknown}: no (22.9/2.7)
    ##             :   savings_balance in {< 100 DM,> 1000 DM}:
    ##             :   :...installment_rate <= 1: no (4.8)
    ##             :       installment_rate > 1:
    ##             :       :...job in {mangement self-employed,skilled employee,
    ##             :           :       unemployed non-resident}: yes (21.6/1.9)
    ##             :           job = unskilled resident: no (3.5/0.8)
    ##             credit_history = critical:
    ##             :...residence_history <= 1: no (7.4)
    ##             :   residence_history > 1:
    ##             :   :...savings_balance in {> 1000 DM,101 - 500 DM,
    ##             :       :                   unknown}: no (16.4/2.2)
    ##             :       savings_balance = 501 - 1000 DM: yes (5.1/2.2)
    ##             :       savings_balance = < 100 DM:
    ##             :       :...months_loan_duration > 36: yes (6.3)
    ##             :           months_loan_duration <= 36:
    ##             :           :...personal_status in {divorced male,
    ##             :               :                   married male}: yes (13.5/4.5)
    ##             :               personal_status in {female,
    ##             :                                   single male}: no (54.8/18.5)
    ##             credit_history = repaid:
    ##             :...savings_balance = > 1000 DM: no (6.2)
    ##                 savings_balance in {< 100 DM,101 - 500 DM,501 - 1000 DM,
    ##                 :                   unknown}:
    ##                 :...amount > 8086: yes (22.1/1.8)
    ##                     amount <= 8086:
    ##                     :...purpose in {business,domestic appliances,
    ##                         :           retraining}: yes (16.6/5)
    ##                         purpose in {car (used),education,others,
    ##                         :           repairs}: no (43.7/12.1)
    ##                         purpose = car (new):
    ##                         :...employment_length in {> 7 yrs,0 - 1 yrs,1 - 4 yrs,
    ##                         :   :                     4 - 7 yrs}: yes (56.2/20.9)
    ##                         :   employment_length = unemployed: no (5.7)
    ##                         purpose = furniture:
    ##                         :...residence_history <= 1: no (9.3/2.1)
    ##                         :   residence_history > 1:
    ##                         :   :...telephone = yes: yes (16.5/6.8)
    ##                         :       telephone = none:
    ##                         :       :...months_loan_duration > 27: yes (5.6)
    ##                         :           months_loan_duration <= 27:
    ##                         :           :...amount <= 2520: yes (20.1/6.9)
    ##                         :               amount > 2520: no (11.4/1.6)
    ##                         purpose = radio/tv:
    ##                         :...amount > 5324: yes (6.9)
    ##                             amount <= 5324:
    ##                             :...amount > 3190: no (9.8/0.3)
    ##                                 amount <= 3190: [S2]
    ## 
    ## SubTree [S1]
    ## 
    ## credit_history = fully repaid this bank: yes (0)
    ## credit_history in {critical,fully repaid}: no (3.1)
    ## credit_history in {delayed,repaid}:
    ## :...amount <= 3229: yes (25.1/4.1)
    ##     amount > 3229: no (3.5)
    ## 
    ## SubTree [S2]
    ## 
    ## property in {building society savings,unknown/none}: yes (8.1/1.1)
    ## property = other:
    ## :...dependents <= 1: no (20.1/7.6)
    ## :   dependents > 1: yes (4.1/0.8)
    ## property = real estate:
    ## :...months_loan_duration <= 11: no (4.7)
    ##     months_loan_duration > 11: yes (20.4/4.3)
    ## 
    ## -----  Trial 7:  -----
    ## 
    ## Decision tree:
    ## 
    ## checking_balance in {< 0 DM,1 - 200 DM}:
    ## :...credit_history in {fully repaid,fully repaid this bank}:
    ## :   :...other_debtors = co-applicant: no (2.7)
    ## :   :   other_debtors in {guarantor,none}:
    ## :   :   :...age <= 22: no (3.8)
    ## :   :       age > 22: yes (66.8/16.7)
    ## :   credit_history in {critical,delayed,repaid}:
    ## :   :...purpose in {car (used),others}: no (47.7/16.6)
    ## :       purpose in {domestic appliances,repairs,retraining}: yes (26.3/10.1)
    ## :       purpose = business:
    ## :       :...personal_status = divorced male: yes (4.4/0.6)
    ## :       :   personal_status in {female,married male,single male}: no (34.1/7.1)
    ## :       purpose = education:
    ## :       :...employment_length in {> 7 yrs,0 - 1 yrs,1 - 4 yrs,
    ## :       :   :                     unemployed}: yes (25.4/5.2)
    ## :       :   employment_length = 4 - 7 yrs: no (5.4)
    ## :       purpose = furniture:
    ## :       :...dependents > 1: no (6.1/0.5)
    ## :       :   dependents <= 1:
    ## :       :   :...savings_balance in {> 1000 DM,unknown}: no (21.7/7.5)
    ## :       :       savings_balance in {101 - 500 DM,
    ## :       :       :                   501 - 1000 DM}: yes (6.6/1.5)
    ## :       :       savings_balance = < 100 DM:
    ## :       :       :...personal_status = married male: no (5.1)
    ## :       :           personal_status in {divorced male,female,single male}:
    ## :       :           :...amount <= 1893: no (25.1/5)
    ## :       :               amount > 1893: yes (54.1/17.9)
    ## :       purpose = car (new):
    ## :       :...installment_plan in {bank,stores}: yes (19.7/4.3)
    ## :       :   installment_plan = none:
    ## :       :   :...job = mangement self-employed: yes (15.8/5.9)
    ## :       :       job in {skilled employee,unemployed non-resident,
    ## :       :       :       unskilled resident}:
    ## :       :       :...checking_balance = 1 - 200 DM: no (40.4/8.8)
    ## :       :           checking_balance = < 0 DM:
    ## :       :           :...installment_rate <= 2: no (17.7/3.3)
    ## :       :               installment_rate > 2:
    ## :       :               :...telephone = none: yes (30.3/8)
    ## :       :                   telephone = yes: no (10.1/2.1)
    ## :       purpose = radio/tv:
    ## :       :...foreign_worker = no: no (3.1)
    ## :           foreign_worker = yes:
    ## :           :...months_loan_duration <= 8: no (6.8)
    ## :               months_loan_duration > 8:
    ## :               :...employment_length = > 7 yrs: no (15/4.1)
    ## :                   employment_length in {4 - 7 yrs,
    ## :                   :                     unemployed}: yes (20.6/7)
    ## :                   employment_length = 1 - 4 yrs:
    ## :                   :...credit_history in {critical,repaid}: yes (33.8/13.6)
    ## :                   :   credit_history = delayed: no (3.3)
    ## :                   employment_length = 0 - 1 yrs:
    ## :                   :...other_debtors = co-applicant: yes (0)
    ## :                       other_debtors = guarantor: no (1.6)
    ## :                       other_debtors = none:
    ## :                       :...amount <= 2214: yes (14.4)
    ## :                           amount > 2214: no (12.4/4.6)
    ## checking_balance in {> 200 DM,unknown}:
    ## :...foreign_worker = no: no (5.6)
    ##     foreign_worker = yes:
    ##     :...installment_plan = stores: yes (17.4/7.6)
    ##         installment_plan = bank:
    ##         :...housing in {for free,own}: no (55/21.3)
    ##         :   housing = rent: yes (5.4)
    ##         installment_plan = none:
    ##         :...credit_history in {critical,fully repaid,
    ##             :                  fully repaid this bank}: no (69.3/11.6)
    ##             credit_history = delayed:
    ##             :...residence_history <= 1: yes (3.5)
    ##             :   residence_history > 1:
    ##             :   :...installment_rate <= 3: no (9.2)
    ##             :       installment_rate > 3: yes (21.3/7.6)
    ##             credit_history = repaid:
    ##             :...telephone = yes: no (49.7/6.8)
    ##                 telephone = none:
    ##                 :...other_debtors in {co-applicant,guarantor}: yes (11.3/3.3)
    ##                     other_debtors = none:
    ##                     :...savings_balance in {> 1000 DM,unknown}: no (11.2)
    ##                         savings_balance in {< 100 DM,101 - 500 DM,
    ##                         :                   501 - 1000 DM}:
    ##                         :...personal_status in {divorced male,
    ##                             :                   married male}: no (7.8)
    ##                             personal_status in {female,single male}:
    ##                             :...housing = for free: yes (2.2/0.5)
    ##                                 housing = rent: no (10/2.5)
    ##                                 housing = own:
    ##                                 :...age <= 34: yes (32.8/12.5)
    ##                                     age > 34: no (8)
    ## 
    ## -----  Trial 8:  -----
    ## 
    ## Decision tree:
    ## 
    ## checking_balance in {> 200 DM,unknown}:
    ## :...installment_plan = bank:
    ## :   :...other_debtors = guarantor: yes (0)
    ## :   :   other_debtors = co-applicant: no (1.7)
    ## :   :   other_debtors = none:
    ## :   :   :...existing_credits > 2: no (3.1)
    ## :   :       existing_credits <= 2:
    ## :   :       :...savings_balance in {< 100 DM,501 - 1000 DM,
    ## :   :           :                   unknown}: yes (47.7/16.8)
    ## :   :           savings_balance in {> 1000 DM,101 - 500 DM}: no (9/1.6)
    ## :   installment_plan in {none,stores}:
    ## :   :...purpose in {car (used),domestic appliances,education,others,
    ## :       :           retraining}: no (39.1/4.1)
    ## :       purpose = repairs: yes (7.8/3.5)
    ## :       purpose = business:
    ## :       :...job = mangement self-employed: yes (7.9/0.7)
    ## :       :   job in {skilled employee,unemployed non-resident,
    ## :       :           unskilled resident}: no (18.7/4.2)
    ## :       purpose = car (new):
    ## :       :...existing_credits <= 2: no (50/7.7)
    ## :       :   existing_credits > 2: yes (3.4/0.6)
    ## :       purpose = furniture:
    ## :       :...job in {mangement self-employed,
    ## :       :   :       unemployed non-resident}: yes (5.7/1.9)
    ## :       :   job in {skilled employee,unskilled resident}: no (49.3/11.7)
    ## :       purpose = radio/tv:
    ## :       :...checking_balance = > 200 DM:
    ## :           :...age <= 41: yes (19.4/5.9)
    ## :           :   age > 41: no (4.8)
    ## :           checking_balance = unknown:
    ## :           :...age <= 23: yes (6.6/1.7)
    ## :               age > 23: no (38.6/4.2)
    ## checking_balance in {< 0 DM,1 - 200 DM}:
    ## :...employment_length = unemployed:
    ##     :...residence_history <= 1: yes (5.5)
    ##     :   residence_history > 1:
    ##     :   :...dependents <= 1: no (39.3/9.7)
    ##     :       dependents > 1: yes (6.6/1.5)
    ##     employment_length = 4 - 7 yrs:
    ##     :...age > 29: no (61.5/13.3)
    ##     :   age <= 29:
    ##     :   :...installment_rate <= 1: no (3.6)
    ##     :       installment_rate > 1:
    ##     :       :...savings_balance in {< 100 DM,> 1000 DM,101 - 500 DM,
    ##     :           :                   501 - 1000 DM}: yes (32.7/8.8)
    ##     :           savings_balance = unknown: no (2.5)
    ##     employment_length = 0 - 1 yrs:
    ##     :...foreign_worker = no: no (5.5)
    ##     :   foreign_worker = yes:
    ##     :   :...housing = for free: no (7.5/2.5)
    ##     :       housing = rent: yes (32.9/7.3)
    ##     :       housing = own:
    ##     :       :...savings_balance in {> 1000 DM,501 - 1000 DM,
    ##     :           :                   unknown}: no (7.9)
    ##     :           savings_balance in {< 100 DM,101 - 500 DM}:
    ##     :           :...residence_history <= 1: no (29/9.7)
    ##     :               residence_history > 1: yes (33.5/8.4)
    ##     employment_length = 1 - 4 yrs:
    ##     :...amount > 7721: yes (13.6/0.6)
    ##     :   amount <= 7721:
    ##     :   :...housing = for free: yes (6.7/2.9)
    ##     :       housing = rent:
    ##     :       :...residence_history <= 3: no (10.3/4)
    ##     :       :   residence_history > 3: yes (26/7.9)
    ##     :       housing = own:
    ##     :       :...personal_status = divorced male: no (10.7/1.6)
    ##     :           personal_status = married male:
    ##     :           :...job = skilled employee: yes (16.5/6.7)
    ##     :           :   job in {mangement self-employed,unemployed non-resident,
    ##     :           :           unskilled resident}: no (7.3)
    ##     :           personal_status = single male:
    ##     :           :...amount <= 902: yes (7.5/1.4)
    ##     :           :   amount > 902: no (59.1/13.3)
    ##     :           personal_status = female:
    ##     :           :...residence_history <= 1: no (7.4/0.9)
    ##     :               residence_history > 1:
    ##     :               :...age <= 37: yes (29.9/8.7)
    ##     :                   age > 37: no (5.4)
    ##     employment_length = > 7 yrs:
    ##     :...personal_status = married male: no (4.8)
    ##         personal_status in {divorced male,female,single male}:
    ##         :...months_loan_duration > 40: yes (6)
    ##             months_loan_duration <= 40:
    ##             :...residence_history <= 3:
    ##                 :...savings_balance in {< 100 DM,> 1000 DM,501 - 1000 DM,
    ##                 :   :                   unknown}: yes (27.3/3.9)
    ##                 :   savings_balance = 101 - 500 DM: no (3.9/0.5)
    ##                 residence_history > 3:
    ##                 :...age <= 30: no (13.7/0.6)
    ##                     age > 30:
    ##                     :...existing_credits <= 1: yes (36.3/9.5)
    ##                         existing_credits > 1: [S1]
    ## 
    ## SubTree [S1]
    ## 
    ## credit_history in {critical,fully repaid this bank,repaid}: no (20.9/4.5)
    ## credit_history in {delayed,fully repaid}: yes (3.9)
    ## 
    ## -----  Trial 9:  -----
    ## 
    ## Decision tree:
    ## 
    ## checking_balance in {> 200 DM,unknown}:
    ## :...checking_balance = > 200 DM:
    ## :   :...dependents <= 1: no (60.2/17.5)
    ## :   :   dependents > 1: yes (9.4/2.7)
    ## :   checking_balance = unknown:
    ## :   :...amount <= 4455: no (163.6/30.7)
    ## :       amount > 4455:
    ## :       :...employment_length in {> 7 yrs,4 - 7 yrs}: no (20.2)
    ## :           employment_length in {0 - 1 yrs,1 - 4 yrs,
    ## :                                 unemployed}: yes (44.6/13.8)
    ## checking_balance in {< 0 DM,1 - 200 DM}:
    ## :...foreign_worker = no: no (14.6/3.4)
    ##     foreign_worker = yes:
    ##     :...credit_history in {fully repaid,
    ##         :                  fully repaid this bank}: yes (71.9/23.9)
    ##         credit_history in {critical,delayed,repaid}:
    ##         :...amount > 7966:
    ##             :...credit_history in {critical,repaid}: yes (31.9/5.2)
    ##             :   credit_history = delayed: no (4.4/1.4)
    ##             amount <= 7966:
    ##             :...installment_plan = stores: yes (20.7/6.4)
    ##                 installment_plan in {bank,none}:
    ##                 :...months_loan_duration > 36:
    ##                     :...dependents > 1: no (6.3/1.6)
    ##                     :   dependents <= 1:
    ##                     :   :...employment_length in {> 7 yrs,0 - 1 yrs,1 - 4 yrs,
    ##                     :       :                     4 - 7 yrs}: yes (24/2.3)
    ##                     :       employment_length = unemployed: no (3.4)
    ##                     months_loan_duration <= 36:
    ##                     :...other_debtors = co-applicant: yes (17.9/8.4)
    ##                         other_debtors = guarantor: no (22.1/4.4)
    ##                         other_debtors = none:
    ##                         :...employment_length = 4 - 7 yrs:
    ##                             :...personal_status in {divorced male,
    ##                             :   :                   married male}: yes (13.8/5)
    ##                             :   personal_status in {female,
    ##                             :                       single male}: no (41.6/4.7)
    ##                             employment_length = unemployed:
    ##                             :...residence_history <= 2: yes (14.9/2.1)
    ##                             :   residence_history > 2: no (19.1/4.6)
    ##                             employment_length = 1 - 4 yrs:
    ##                             :...housing in {for free,own}: no (95.8/31.1)
    ##                             :   housing = rent: [S1]
    ##                             employment_length = > 7 yrs:
    ##                             :...months_loan_duration <= 8: no (7.3)
    ##                             :   months_loan_duration > 8:
    ##                             :   :...residence_history <= 3:
    ##                             :       :...amount <= 5129: yes (21.1/4.9)
    ##                             :       :   amount > 5129: no (3.3)
    ##                             :       residence_history > 3:
    ##                             :       :...amount <= 6948: no (46.9/14.4)
    ##                             :           amount > 6948: yes (3.9/0.9)
    ##                             employment_length = 0 - 1 yrs:
    ##                             :...job in {mangement self-employed,
    ##                                 :       unemployed non-resident}: no (7.9/2.2)
    ##                                 job = unskilled resident: yes (21.3/7.4)
    ##                                 job = skilled employee:
    ##                                 :...amount > 4870: no (6.5)
    ##                                     amount <= 4870:
    ##                                     :...existing_credits > 1: yes (4.6/0.5)
    ##                                         existing_credits <= 1: [S2]
    ## 
    ## SubTree [S1]
    ## 
    ## purpose in {car (new),car (used)}: no (14.8/3.2)
    ## purpose in {business,domestic appliances,education,furniture,others,radio/tv,
    ##             repairs,retraining}: yes (13.6/1.2)
    ## 
    ## SubTree [S2]
    ## 
    ## personal_status in {divorced male,single male}: no (10.5)
    ## personal_status in {female,married male}:
    ## :...credit_history = delayed: yes (0)
    ##     credit_history = critical: no (1.8)
    ##     credit_history = repaid:
    ##     :...months_loan_duration <= 24: yes (25.9/8.1)
    ##         months_loan_duration > 24: no (3.1)
    ## 
    ## 
    ## Evaluation on training data (900 cases):
    ## 
    ## Trial        Decision Tree   
    ## -----      ----------------  
    ##    Size      Errors  
    ## 
    ##    0     54  135(15.0%)
    ##    1     37  184(20.4%)
    ##    2     58  172(19.1%)
    ##    3     40  173(19.2%)
    ##    4     54  188(20.9%)
    ##    5     63  162(18.0%)
    ##    6     61  158(17.6%)
    ##    7     46  209(23.2%)
    ##    8     49  186(20.7%)
    ##    9     35  178(19.8%)
    ## boost             29( 3.2%)   <<
    ## 
    ## 
    ##     (a)   (b)    <-classified as
    ##    ----  ----
    ##     630     3    (a): class no
    ##      26   241    (b): class yes
    ## 
    ## 
    ##  Attribute usage:
    ## 
    ##  100.00% checking_balance
    ##  100.00% months_loan_duration
    ##  100.00% foreign_worker
    ##   99.00% employment_length
    ##   98.67% purpose
    ##   98.00% other_debtors
    ##   96.67% amount
    ##   96.44% savings_balance
    ##   95.22% installment_plan
    ##   93.67% credit_history
    ##   90.00% job
    ##   87.11% installment_rate
    ##   74.44% age
    ##   74.33% property
    ##   59.33% existing_credits
    ##   58.56% residence_history
    ##   55.33% personal_status
    ##   54.89% housing
    ##   46.00% dependents
    ##   37.44% telephone
    ## 
    ## 
    ## Time: 0.1 secs

The classifier made 29 mistakes on 900 training examples for an error
rate of 3.22 percent. This is quite an improvement over the 13.9 percent
training error rate we noted before adding boosting! However, it remains
to be seen whether we see a similar improvement on the test data.

    credit_boost_pred10 <- predict(credit_boost10, credit_test)
    CrossTable(credit_test$default, credit_boost_pred10,
               prop.chisq = FALSE, prop.c = FALSE, prop.r = FALSE,
               dnn = c('actual default', 'predicted default'))

    ## 
    ##  
    ##    Cell Contents
    ## |-------------------------|
    ## |                       N |
    ## |         N / Table Total |
    ## |-------------------------|
    ## 
    ##  
    ## Total Observations in Table:  100 
    ## 
    ##  
    ##                | predicted default 
    ## actual default |        no |       yes | Row Total | 
    ## ---------------|-----------|-----------|-----------|
    ##             no |        60 |         7 |        67 | 
    ##                |     0.600 |     0.070 |           | 
    ## ---------------|-----------|-----------|-----------|
    ##            yes |        17 |        16 |        33 | 
    ##                |     0.170 |     0.160 |           | 
    ## ---------------|-----------|-----------|-----------|
    ##   Column Total |        77 |        23 |       100 | 
    ## ---------------|-----------|-----------|-----------|
    ## 
    ## 

Here, we reduced the total error rate from 26 percent prior to boosting
to 24 percent in the boosted model. This may not seem like a large gain,
but it is in fact greater than the 25 percent reduction we expected. On
the other hand, the model is still not doing well at predicting
defaults, predicting only 16 / 33 = 48.5% correctly. The lack of an even
greater improvement may be a function of our relatively small training
dataset, or it may just be a very difficult problem to solve.

**Making some mistakes cost more than others**

Giving a loan to an applicant who is likely to default can be an
expensive mistake.One solution to reduce the number of false negatives
may be to reject a larger number of borderline applicants under the
assumption that the interest that the bank would earn from a risky loan
is far outweighed by the massive loss it would incur if the money is not
paid back at all.

The C5.0 algorithm allows us to assign a penalty to different types of
errors in order to discourage a tree from making more costly mistakes.
The penalties are designated in a cost matrix, which specifies how many
times more costly each error is relative to any other.

To begin constructing the cost matrix, we need to start by specifying
the dimensions. Since the predicted and actual values can both take two
values, `yes` or `no`, we need to describe a 2x2 matrix using a list of
two vectors, each with two values. At the same time, we’ll also name the
matrix dimensions to avoid confusion later on:

    matrix_dimensions <- list(c("no", "yes"), c("no", "yes"))
    names(matrix_dimensions) <- c("predicted", "actual")
    matrix_dimensions

    ## $predicted
    ## [1] "no"  "yes"
    ## 
    ## $actual
    ## [1] "no"  "yes"

Next, we need to assign the penalty for the various types of errors by
supplying four values to fill the matrix. Since R fills a matrix by
filling columns one by one from top to bottom, we need to supply the
values in a specific order: 1. Predicted no, actual no 2. Predicted yes,
actual no 3. Predicted no, actual yes 4. Predicted yes, actual yes

Suppose we believe that a loan default costs the bank four times as much
as a missed opportunity. Our penalty values then could be defined as:

    error_cost <- matrix(c(0, 1, 4, 0), nrow = 2,
                         dimnames = matrix_dimensions)
    error_cost

    ##          actual
    ## predicted no yes
    ##       no   0   4
    ##       yes  1   0

As defined by this matrix, there is no cost assigned when the algorithm
classifies a `no` or `yes` correctly, but a false negative has a cost of
4 versus a false positive’s cost of 1. To see how this impacts
classification, let’s apply it to our decision tree using the `costs`
parameter of the `C5.0()` function. We’ll otherwise use the same steps
as before:

    credit_cost <- C5.0(credit_train[-17], credit_train$default,
                        costs = error_cost)
    credit_cost_pred <- predict(credit_cost, credit_test)
    CrossTable(credit_test$default, credit_cost_pred,
               prop.chisq = FALSE, prop.c = FALSE, prop.r = FALSE,
               dnn = c('actual default', 'predicted default'))

    ## 
    ##  
    ##    Cell Contents
    ## |-------------------------|
    ## |                       N |
    ## |         N / Table Total |
    ## |-------------------------|
    ## 
    ##  
    ## Total Observations in Table:  100 
    ## 
    ##  
    ##                | predicted default 
    ## actual default |        no |       yes | Row Total | 
    ## ---------------|-----------|-----------|-----------|
    ##             no |        33 |        34 |        67 | 
    ##                |     0.330 |     0.340 |           | 
    ## ---------------|-----------|-----------|-----------|
    ##            yes |         7 |        26 |        33 | 
    ##                |     0.070 |     0.260 |           | 
    ## ---------------|-----------|-----------|-----------|
    ##   Column Total |        40 |        60 |       100 | 
    ## ---------------|-----------|-----------|-----------|
    ## 
    ## 

Compared to our boosted model, this version makes more mistakes
overall.However, the types of mistakes are very different.This trade-off
resulting in a reduction of false negatives at the expense of increasing
false positives may be acceptable if our cost estimates were accurate.
