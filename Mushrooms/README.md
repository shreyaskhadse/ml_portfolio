Introduction
------------

Each year, many people fall ill and sometimes even die from ingesting
poisonous wild mushrooms. Since many mushrooms are very similar to each
other in appearance, occasionally even experienced mushroom gatherers
are poisoned.

Unlike the identification of harmful plants, such as a poison oak or
poison ivy, there are no clear rules like “leaves of three, let them be”
for identifying whether a wild mushroom is poisonous or edible.
Complicating matters, many traditional rules such as “poisonous
mushrooms are brightly colored” provide dangerous or misleading
information. If simple, clear, and consistent rules were available for
identifying poisonous mushrooms, they could save the lives of foragers.

As one of the strengths of rule learning algorithms is the fact that
they generate easy-to-understand rules, they seem like an appropriate
fit for this classification task. However, the rules will only be as
useful as they are accurate.

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

    path <- "A:/Project/Mushrooms"
    setwd(path)
    url <- "https://raw.githubusercontent.com/shreyaskhadse/data_files/master/mushrooms.csv"
    datafile <- "./mushrooms.csv"
    if (!file.exists(datafile)) {
        download.file(url, datafile ,method="auto") }
    mushrooms <- read.csv("mushrooms.csv", stringsAsFactors = TRUE)
    str(mushrooms)

    ## 'data.frame':    8124 obs. of  23 variables:
    ##  $ type                    : Factor w/ 2 levels "e","p": 2 1 1 2 1 1 1 1 2 1 ...
    ##  $ cap_shape               : Factor w/ 6 levels "b","c","f","k",..: 6 6 1 6 6 6 1 1 6 1 ...
    ##  $ cap_surface             : Factor w/ 4 levels "f","g","s","y": 3 3 3 4 3 4 3 4 4 3 ...
    ##  $ cap_color               : Factor w/ 10 levels "b","c","e","g",..: 5 10 9 9 4 10 9 9 9 10 ...
    ##  $ bruises                 : Factor w/ 2 levels "f","t": 2 2 2 2 1 2 2 2 2 2 ...
    ##  $ odor                    : Factor w/ 9 levels "a","c","f","l",..: 7 1 4 7 6 1 1 4 7 1 ...
    ##  $ gill_attachment         : Factor w/ 2 levels "a","f": 2 2 2 2 2 2 2 2 2 2 ...
    ##  $ gill_spacing            : Factor w/ 2 levels "c","w": 1 1 1 1 2 1 1 1 1 1 ...
    ##  $ gill_size               : Factor w/ 2 levels "b","n": 2 1 1 2 1 1 1 1 2 1 ...
    ##  $ gill_color              : Factor w/ 12 levels "b","e","g","h",..: 5 5 6 6 5 6 3 6 8 3 ...
    ##  $ stalk_shape             : Factor w/ 2 levels "e","t": 1 1 1 1 2 1 1 1 1 1 ...
    ##  $ stalk_root              : Factor w/ 5 levels "?","b","c","e",..: 4 3 3 4 4 3 3 3 4 3 ...
    ##  $ stalk_surface_above_ring: Factor w/ 4 levels "f","k","s","y": 3 3 3 3 3 3 3 3 3 3 ...
    ##  $ stalk_surface_below_ring: Factor w/ 4 levels "f","k","s","y": 3 3 3 3 3 3 3 3 3 3 ...
    ##  $ stalk_color_above_ring  : Factor w/ 9 levels "b","c","e","g",..: 8 8 8 8 8 8 8 8 8 8 ...
    ##  $ stalk_color_below_ring  : Factor w/ 9 levels "b","c","e","g",..: 8 8 8 8 8 8 8 8 8 8 ...
    ##  $ veil_type               : Factor w/ 1 level "p": 1 1 1 1 1 1 1 1 1 1 ...
    ##  $ veil_color              : Factor w/ 4 levels "n","o","w","y": 3 3 3 3 3 3 3 3 3 3 ...
    ##  $ ring_number             : Factor w/ 3 levels "n","o","t": 2 2 2 2 2 2 2 2 2 2 ...
    ##  $ ring_type               : Factor w/ 5 levels "e","f","l","n",..: 5 5 5 5 1 5 5 5 5 5 ...
    ##  $ spore_print_color       : Factor w/ 9 levels "b","h","k","n",..: 3 4 4 3 4 3 3 4 3 3 ...
    ##  $ population              : Factor w/ 6 levels "a","c","n","s",..: 4 3 3 4 1 3 3 4 5 4 ...
    ##  $ habitat                 : Factor w/ 7 levels "d","g","l","m",..: 6 2 4 6 2 2 4 4 2 4 ...

The dataset includes information on 8,124 mushroom samples from 23
species of gilled mushrooms listed in the Audubon Society Field Guide to
North American Mushrooms (1981). In the field guide, each of the
mushroom species is identified as “definitely edible,” “definitely
poisonous,” or “likely poisonous, and not recommended to be eaten.” For
the purposes of this dataset, the latter group was combined with the
“definitely poisonous” group to make two classes: poisonous and
non-poisonous. The data dictionary available on the UCI website
describes the 22 features of the mushroom samples, including
characteristics such as cap shape, cap color, odor, gill size and color,
stalk shape, and habitat.

the veil type does not vary across samples, it does not provide any
useful information for prediction since there is only one factor level.
We will drop this variable from our analysis.

    mushrooms$veil_type <- NULL

Observing the distribution of the mushroom type variable in our dataset

    levels(mushrooms$type) <- c('edible','poisonous')
    table(mushrooms$type)

    ## 
    ##    edible poisonous 
    ##      4208      3916

About 52 percent of the mushroom samples (N = 4,208) are edible, while
48 percent (N = 3,916) are poisonous.

For the purposes of this experiment, we will consider the 8,214 samples
in the mushroom data to be an exhaustive set of all the possible wild
mushrooms. This is an important assumption because it means that we do
not need to hold some samples out of the training data for testing
purposes. We are not trying to develop rules that cover unforeseen types
of mushrooms; we are merely trying to find rules that accurately depict
the complete set of known mushroom types. Therefore, we can build and
test the model on the same data.

Taining a model on the Data
---------------------------

We will use the 1R implementation found in the OneR package by Holger
von Jouanne-Diedrich at the Aschaffenburg University of Applied
Sciences. This is a relatively new package, which implements 1R in
native R code for speed and ease of use.

    #install.packages("OneR")
    library(OneR)

    ## Warning: package 'OneR' was built under R version 3.6.3

    mushroom_1R <- OneR(type ~ ., data = mushrooms)
    mushroom_1R

    ## 
    ## Call:
    ## OneR.formula(formula = type ~ ., data = mushrooms)
    ## 
    ## Rules:
    ## If odor = a then type = edible
    ## If odor = c then type = poisonous
    ## If odor = f then type = poisonous
    ## If odor = l then type = edible
    ## If odor = m then type = poisonous
    ## If odor = n then type = edible
    ## If odor = p then type = poisonous
    ## If odor = s then type = poisonous
    ## If odor = y then type = poisonous
    ## 
    ## Accuracy:
    ## 8004 of 8124 instances classified correctly (98.52%)

Examining the output, we see that the `odor` feature was selected for
rule generation. The categories of `odor`, such as `almond`, `anise`,
and so on, specify rules for whether the mushroom is likely to be
`edible` or `poisonous`. For instance, if the mushroom smells `fishy`,
`foul`, `musty`, `pungent`, `spicy`, or like `creosote`, the mushroom is
likely to be poisonous. On the other hand, mushrooms with more pleasant
smells, like `almond` and `anise`, and those with no smell at all, are
predicted to be edible.

Evaluating Model Performance
----------------------------

The last line of the output notes that the rules correctly predict the
edibility 8,004 of the 8,124 mushroom samples, or nearly 99 percent.
Anything short of perfection, however, runs the risk of poisoning
someone if the model were to classify a poisonous mushroom as edible.

    mushroom_1R_pred <- predict(mushroom_1R, mushrooms)
    table(actual = mushrooms$type, predicted = mushroom_1R_pred)

    ##            predicted
    ## actual      edible poisonous
    ##   edible      4208         0
    ##   poisonous    120      3796

Examining the table, we can see that although the 1R classifier did not
classify any edible mushrooms as poisonous, it did classify 120
poisonous mushrooms as edible— which makes for an incredibly dangerous
mistak.

Improving Model Performance
---------------------------

For a more sophisticated rule learner, we will use `JRip()`, a
Java-based implementation of the RIPPER algorithm. The `JRip()` function
is included in the `RWeka` package.

    #install.packages("RWeka")
    library(RWeka)

    ## Warning: package 'RWeka' was built under R version 3.6.3

    ## 
    ## Attaching package: 'RWeka'

    ## The following object is masked from 'package:OneR':
    ## 
    ##     OneR

    mushroom_JRip <- JRip(type ~ ., data = mushrooms)
    mushroom_JRip

    ## JRIP rules:
    ## ===========
    ## 
    ## (odor = f) => type=poisonous (2160.0/0.0)
    ## (gill_size = n) and (gill_color = b) => type=poisonous (1152.0/0.0)
    ## (gill_size = n) and (odor = p) => type=poisonous (256.0/0.0)
    ## (odor = c) => type=poisonous (192.0/0.0)
    ## (spore_print_color = r) => type=poisonous (72.0/0.0)
    ## (stalk_surface_below_ring = y) and (stalk_surface_above_ring = k) => type=poisonous (68.0/0.0)
    ## (habitat = l) and (cap_color = w) => type=poisonous (8.0/0.0)
    ## (stalk_color_above_ring = y) => type=poisonous (8.0/0.0)
    ##  => type=edible (4208.0/0.0)
    ## 
    ## Number of Rules : 9

The `JRip()` classifier learned a total of nine rules from the mushroom
data.

The numbers next to each rule indicate the number of instances covered
by the rule and a count of misclassified instances. Notably, there were
no misclassified mushroom samples using these nine rules. As a result,
the number of instances covered by the last rule is exactly equal to the
number of edible mushrooms in the data (N = 4,208).

![A sophisticated rule learning algorithm identified rulesto perfectly
cover all types of poisonous
mushrooms](A:\Project\Mushrooms\venn_diagram.PNG)
