Introduction
------------

In the field of engineering, it is crucial to have accurate estimates of
the performance of building materials. These estimates are required in
order to develop safety guidelines governing the materials used in the
construction of buildings, bridges, and roadways.

Estimating the strength of concrete is a challenge of particular
interest. Although it is used in nearly every construction project,
concrete performance varies greatly due to a wide variety of ingredients
that interact in complex ways. As a result, it is difficult to
accurately predict the strength of the final product. A model that could
reliably predict concrete strength given a listing of the composition of
the input materials could result in safer construction practices.

Collecting the data
-------------------

For this analysis, we will utilize data on the compressive strength of
concrete donated to the UCI Machine Learning Repository
(<a href="http://archive.ics.uci.edu/ml" class="uri">http://archive.ics.uci.edu/ml</a>)
by I-Cheng Yeh. As he found success using neural networks to model these
data, we will attempt to replicate Yeh’s work using a simple neural
network model in R.

The dataset contains 1,030 examples of concrete, with eight features
describing the components used in the mixture. These features are
thought to be related to the final compressive strength, and include the
amount (in kilograms per cubic meter) of cement, slag, ash, water,
superplasticizer, coarse aggregate, and fine aggregate used in the
product, in addition to the aging time (measured in days).

For ease to acces the dataset I have hosted a public repository and
included the code that directly downloads the data from the repo and
loads the data. The path can be canged to anythig according to your
preference of the working directory.

    set.seed(1)
    path <- "A:/Project/Strength_Concrete"
    setwd(path)
    url <- "https://raw.githubusercontent.com/shreyaskhadse/data_files/master/concrete.csv"
    datafile <- "./concrete.csv"
    if (!file.exists(datafile)) {
        download.file(url, datafile ,method="auto") }
    concrete <- read.csv("concrete.csv")
    str(concrete)

    ## 'data.frame':    1030 obs. of  9 variables:
    ##  $ cement      : num  540 540 332 332 199 ...
    ##  $ slag        : num  0 0 142 142 132 ...
    ##  $ ash         : num  0 0 0 0 0 0 0 0 0 0 ...
    ##  $ water       : num  162 162 228 228 192 228 228 228 228 228 ...
    ##  $ superplastic: num  2.5 2.5 0 0 0 0 0 0 0 0 ...
    ##  $ coarseagg   : num  1040 1055 932 932 978 ...
    ##  $ fineagg     : num  676 676 594 594 826 ...
    ##  $ age         : int  28 28 270 365 360 90 365 28 28 28 ...
    ##  $ strength    : num  80 61.9 40.3 41 44.3 ...

Exploring and preparing data
----------------------------

The nine variables in the data frame correspond to the eight features
and one outcome we expected, although a problem has become apparent.
Neural networks work best when the input data are scaled to a narrow
range around zero, and here we see values ranging anywhere from zero to
over a thousand.

Typically, the solution to this problem is to rescale the data with a
normalizing or standardization function.

    normalize <- function(x) {return((x - min(x)) / (max(x) - min(x)))}
    concrete_norm <- as.data.frame(lapply(concrete, normalize))
    #Summary of normalized data
    "Normalized Data"

    ## [1] "Normalized Data"

    summary(concrete_norm$strength)

    ##    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
    ##  0.0000  0.2664  0.4001  0.4172  0.5457  1.0000

    #Summary of original data
    "Original Data"

    ## [1] "Original Data"

    summary(concrete$strength)

    ##    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
    ##    2.33   23.71   34.45   35.82   46.13   82.60

As we can see from the above output, our data is now normalized in the
ranege 0-1.

The data collected is fairly random, so to split the data into testing
and training data, we will partition the data into a training set with
75 percent of the examples and a testing set with 25 percent.

    concrete_train <- concrete_norm[1:ceiling(0.75*1030), ]
    concrete_test <- concrete_norm[(ceiling(0.75*1030)+1):1030, ]

Training a model on the data
----------------------------

To model the relationship between the ingredients used in concrete and
the strength of the finished product, we will use a multilayer
feedforward neural network. The `neuralnet` package by Stefan Fritsch
and Frauke Guenther provides a standard and easy-to-use implementation
of such networks. It also offers a function to plot the network
topology.

    #install.packages("neuralnet")
    library(neuralnet)

    ## Warning: package 'neuralnet' was built under R version 3.6.3

    concrete_model <- neuralnet(strength ~ cement + slag + ash + water + 
                                  superplastic + coarseagg + fineagg + age, 
                                data = concrete_train)

We can then visualize the network topology using the plot() function on
the resulting model object:

    plot(concrete_model, fill = "steelblue",
         radius = 0.1,
         col.entry.synapse = "#00C6CF",
         col.out.synapse = "#7FD1AE")

![](A:/Project/Strength_Concrete/Rplot1.PNG)

In this simple model, there is one input node for each of the eight
features, followed by a single hidden node and a single output node that
predicts the concrete strength. The weights for each of the connections
are also depicted, as are the bias terms indicated by the nodes labeled
with the number 1. The bias terms are numeric constants that allow the
value at the indicated nodes to be shifted upward or downward, much like
the intercept in a linear equation.

Evaluating model performance
----------------------------

To generate predictions on the test dataset, we can use the `compute()`
function as follows:

    model_results <- compute(concrete_model, concrete_test[1:8])

The compute() function returns a list with two components: $neurons,
which stores the neurons for each layer in the network, and $net.result,
which stores the predicted values. We’ll want the latter:

    predicted_strength <- model_results$net.result

Because this is a numeric prediction problem rather than a
classification problem, we cannot use a confusion matrix to examine
model accuracy. Instead, we’ll measure the correlation between our
predicted concrete strength and the true value. If the predicted and
actual values are highly correlated, the model is likely to be a useful
gauge of concrete strength.

    cor(predicted_strength, concrete_test$strength)

    ##           [,1]
    ## [1,] 0.7225218

Correlations close to one indicate strong linear relationships between
two variables. Therefore, the correlation here of about 0.722 indicates
a fairly strong relationship. This implies that our model is doing a
fairly good job, even with only a single hidden node.

Improving model performance
---------------------------

As networks with more complex topologies are capable of learning more
difficult concepts, we increase the number of hidden nodes to five. We
use the neuralnet() function as before, but add the parameter hidden =
5:

    set.seed(6799)
    concrete_model2 <- neuralnet(strength ~ cement + slag +
                                   ash + water + superplastic +
                                   coarseagg + fineagg + age,
                                 data = concrete_train, hidden = 5)
    plot(concrete_model2, fill = "steelblue",
         radius = 0.1,
         col.entry.synapse = "#00C6CF",
         col.out.synapse = "#7FD1AE")

![](A:/Project/Strength_Concrete/Rplot2.PNG)

The reported error (measured again by SSE) has been reduced from 5.66 in
the previous model to 1.64 here. Additionally, the number of training
steps rose from 2227 to 47156, which should come as no surprise given
how much more complex the model has become. More complex networks take
many more iterations to find the optimal weights.

    model_results2 <- compute(concrete_model2, concrete_test[1:8])
    predicted_strength2 <- model_results2$net.result
    cor(predicted_strength2, concrete_test$strength)

    ##           [,1]
    ## [1,] 0.7304948

Applying the same steps to compare the predicted values to the true
values, we now obtain a correlation around 0.73, which is not a
considerable improvement over the previous result of 0.72 with a single
hidden node

Recently, an activation function known as a rectifier has become
extremely popular due to its success on complex tasks such as image
recognition. A node in a neural network that uses the rectifier
activation function is known as a rectified linear unit (ReLU). As
depicted in the following figure, the rectifier activation function is
defined such that it returns x if x is at least zero, and zero
otherwise. The significance of this function is due to the fact that it
is nonlinear yet has simple mathematical properties that make it both
computationally inexpensive and highly efficient for gradient descent.
Unfortunately, its derivative is undefined at x = 0 and therefore cannot
be used with the `neuralnet()` function.

Instead, we can use a smooth approximation of the ReLU known as softplus
or SmoothReLU, an activation function defined as `log(1 + e^x)`. As
shown in the following figure, the softplus function is nearly zero for
x less than zero and approximately x when x is greater than zero:

![The softplus activation function provides a smooth, differentiable
approximation of ReLU](A:/Project/Strength_Concrete/1.PNG)

This activation function can be provided to `neuralnet()` using the
`act.fct` parameter. Additionally, we will add a second hidden layer of
five nodes by supplying the hidden parameter the integer vector
`c(5, 5)`. This creates a twolayer network, each having five nodes, all
using the softplus activation function:

    start.time <- Sys.time()
    softplus <- function(x) { log(1 + exp(x)) }
    set.seed(12345)
    concrete_model3 <- neuralnet(strength ~ cement + slag + ash + water + superplastic + coarseagg + fineagg + age,  data = concrete_train, hidden = c(5, 5), act.fct = softplus, threshold = 0.05)
    end.time <- Sys.time()
    paste("The program took,", round(end.time - start.time,2),"seconds to complete")

    ## [1] "The program took, 13.54 seconds to complete"

    plot(concrete_model3, 
         fill = "steelblue",
         radius = 0.1,
         col.entry.synapse = "#00C6CF",
         col.out.synapse = "#7FD1AE")

![](A:/Project/Strength_Concrete/Rplot3.PNG)

    model_results3 <- compute(concrete_model3, concrete_test[1:8])
    predicted_strength3 <- model_results3$net.result
    cor(predicted_strength3, concrete_test$strength)

    ##           [,1]
    ## [1,] 0.8004582

The correlation between the predicted and actual strength was 0.800,
which is our best performance yet.
