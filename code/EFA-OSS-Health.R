# -----------------------------------------------
# EFA
# -----------------------------------------------
# sessionInfo()
# 
# R version 4.0.2 (2020-06-22)
# Platform: x86_64-w64-mingw32/x64 (64-bit)
# Running under: Windows 10 x64 (build 19041)
# 
# other attached packages:
# [1] semPlot_1.1.2        lavaan_0.6-8         forcats_0.5.1        stringr_1.4.0        purrr_0.3.4         
# [6] readr_2.1.2          tidyr_1.2.0          tibble_3.1.6         ggplot2_3.3.5        tidyverse_1.3.1     
#[11] GPArotation_2022.4-1 psych_2.2.3          dplyr_1.0.8     
# Load the packages
# package installation
install.packages(c("summarytools","ggplot2"))
install.packages("fitdistrplus")
library(mice)
library(epmr)
library(purrr)
library(readr)
library(tidyr)
library(psych)
library(dplyr)
library(scales)
library(tibble)
library(lavaan)
library(ggplot2)
library(stringr)
library(forcats)
library(semPlot)
library(caTools)
library(semTools)
library(corrplot)
library(gridExtra)
library(tidyverse)
library(GPArotation)
library(summarytools)
packages <- c("mice","bnlearn", "epmr", "purrr", "readr", "tidyr", "psych", "dplyr", 
              "scales", "tibble", "lavaan", "ggplot2", "stringr", "forcats",
              "semPlot", "caTools", "semTools", "corrplot", "gridExtra",
              "tidyverse", "GPArotation", "summarytools")
lapply(packages, require, character.only = TRUE)

# -----------------------------------------------
# load data (after cleaning)
# -----------------------------------------------
f <- file.choose()
efa2data <- read.csv(f)
print(efa2data)
write.csv(efadata, "df_test_393.csv")

# -----------------------------------------------
# build dataframe
# -----------------------------------------------
df <- data.frame(efa2data$forks,
                 efa2data$stars,
                 efa2data$mentions,
                 efa2data$criticality,
                 efa2data$lastUpdated,
                 efa2data$cmc,
                 efa2data$geo,
                 efa2data$avg_longevity_days,
                 efa2data$alexa,
                 efa2data$med_resp,
                 efa2data$avg_resp
)          
df = rename(df, 
            forks  = efa2data.forks,
            stars = efa2data.stars,
            mentions      = efa2data.mentions,
            criticality  = efa2data.criticality,
            lastUpdated  = efa2data.lastUpdated,
            cmc    = efa2data.cmc,
            geo    = efa2data.geo,
            longevity = efa2data.avg_longevity_days,
            alexa = efa2data.alexa,
            medResp = efa2data.med_resp,
            avgResp = efa2data.avg_resp
            )

# -----------------------------------------------
# impute missing data
# -----------------------------------------------
# Define imputation method
impMethod <- make.method(df)
impMethod[sapply(df, is.numeric)] <- "mean"

# Use mice() function with mean substitution
imp <- mice(df, m=5, method=impMethod, seed = 500)

# m is the number of multiple imputations (m=5 is generally a good start)
# method=impMethod specifies to use mean substitution for numerical columns
# Use complete() function to get the completed data
# 1 means that you want the first imputed dataset
dfi <- complete(imp,1)

# -----------------------------------------------
# adjust med and avg response time
# -----------------------------------------------
# 0's are bad; 0.01's are good
require(epmr)
# Separate 0's from non-zero values for medResp and avgResp
medResp_nonzero <- dfi[dfi$medResp != 0, "medResp"]
avgResp_nonzero <- dfi[dfi$avgResp != 0, "avgResp"]

# Apply rescore function
medResp_rescored <- rescore(medResp_nonzero)
avgResp_rescored <- rescore(avgResp_nonzero)

# Replace the non-zero values in the original dataset with the rescored values
dfi[dfi$medResp != 0, "medResp"] <- medResp_rescored
dfi[dfi$avgResp != 0, "avgResp"] <- avgResp_rescored

# now 0 is bad, high is good, want to rescore back to original meaning 
# of low time in days is good
upd_med     <- rescore(dfi$medResp)
upd_avg     <- rescore(dfi$avgResp)
# change df['updated'] to updated_r and redo results
dfi$medResp <- upd_med 
dfi$avgResp <- upd_avg 
# now high (75) is bad, indicating greater than 75 days to respond to issues

# -----------------------------------------------
# get descriptive stats
# -----------------------------------------------
# see link for summaryTools options
# https://mran.microsoft.com/snapshot/2018-06-19/web/packages/summarytools/vignettes/Introduction.html 
mydata <- summarytools::descr(dfi,round.digits = 3,stats = c("mean", "sd", "min", "med", "max"),transpose=T)
mydata <- summarytools::descr(efadata,round.digits = 2,transpose=T)

# -----------------------------------------------
# plot the distributions of the data
# -----------------------------------------------
# Create a new data frame for efa2 analysis wihtout stars and forks
dfefa2 <- select(dfi, -c(stars, forks))
names(dfefa2)
# Custom x-axis titles for dfefa2
custom_titles2 <- c("mentions (millions)",
                    "criticality score",
                    "months since update",
                    "CMC rank",
                    "geographic distribution",
                    "longevity (days)",
                    "Alexa rank (millions)",
                    "med.resp time (days)",
                    "avg.resp time (days)"
                    )

# create an empty list to store plots
plots <- list()  
# iterate over each variable 
require(ggplot2)
require(gridExtra)
require(scales)  # Load the scales package for number formatting

for (i in 1:ncol(dfefa2)) {
  p <- ggplot(dfefa2, aes_string(names(dfefa2)[i])) +
    geom_histogram(aes(y = ..density..), bins = 30, colour = "black", fill = "lightblue", size = 0.4) + 
    theme_minimal() +
    labs(x = paste(custom_titles2[i], sep=""), y = "")
  
  # Conditional formatting for specific axes
  if (names(dfefa2)[i] == "mentions") {
    # For 'mentions', scale up to 0.5 million
    p <- p + scale_x_continuous(breaks = seq(0, 0.5e6, by = 0.1e6),
                                labels = function(x) scales::number(x / 1e6, accuracy = 0.1))
  } else if (names(dfefa2)[i] == "alexa") {
    # For 'Alexa rank', scale up to 5 million
    p <- p + scale_x_continuous(breaks = seq(0, 5e6, by = 1e6),
                                labels = function(x) scales::number(x / 1e6, accuracy = 1))
  }
  
  plots[[i]] <- p  # Add the plot to the list
}

# arrange in a grid
grid.arrange(grobs = plots, ncol = 3)

#try log plots
# iterate over each variable
# new dataframes created
for (i in 1:ncol(dfefa2)) {
  df_log2 <- log1p(dfefa2[[i]])  # apply the log transformation
  df_data2 <- data.frame(df_log2)  # create a new data frame for each variable
  p <- ggplot(df_data2, aes(df_log2)) +  # use the transformed data
    geom_histogram(aes(y = ..density..), bins = 30, colour = "black", fill = "lightblue", linewidth = 0.4) + 
    geom_density(alpha = .2, fill="#FF6666", linewidth = 0.4) +  
    theme_minimal() + 
    labs(x = paste("log(", custom_titles2[i], ")", sep=""), y = "")  # add custom x-axis title
  plots[[i]] <- p  # add the plot to the list
}

# arrange in a grid
grid.arrange(grobs = plots, ncol = 3)

# -----------------------------------------------
# rescore negatively valenced data
# recode the Inactive Since (days) column to have the high metric
# representative as positive and the lower as negative
# -----------------------------------------------
dfir <- dfi
upd_updated <- rescore(dfi$lastUpdated)
upd_cmc     <- rescore(dfi$cmc)
upd_geo     <- rescore(dfi$geo)
upd_alexa   <- rescore(dfi$alexa)
upd_med     <- rescore(dfi$medResp)
upd_avg     <- rescore(dfi$avgResp)

dfir$lastUpdated <- upd_updated
dfir$cmc     <- upd_cmc 
dfir$geo     <- upd_geo 
dfir$alexa   <- upd_alexa 
dfir$medResp <- upd_med 
dfir$avgResp <- upd_avg 

# -----------------------------------------------
# correlation matrix plot
# -----------------------------------------------
# https://cran.r-project.org/web/packages/corrplot/vignettes/corrplot-intro.html 
# Pearson is the default correlation method in cor(df)
require(corrplot)
corrplot(cor(dfir),
         method="shade", 
         tl.col="black", 
         addCoef.col = 'black', 
         diag=F, 
         type='lower')

corrplot(cor(dfi, use = "complete.obs"), method = "circle")

# corr matrix with histogram, scatter, etc.
pairs.panels(dfi,
             smooth = TRUE,      # If TRUE, draws loess smooths
             scale = F,      # If TRUE, scales the correlation text font
             density = TRUE,     # If TRUE, adds density plots and histograms
             ellipses = TRUE,    # If TRUE, draws ellipses
             method = "pearson", # Correlation method (also "spearman" or "kendall")
             pch = 21,           # pch symbol
             bg=c("yellow"),
             lm = T,         # If TRUE, plots linear fit rather than the LOESS (smoothed) fit
             cor = TRUE,         # If TRUE, reports correlations
             jiggle = FALSE,     # If TRUE, data points are jittered
             factor = 2,         # Jittering factor
             hist.col = 4,       # Histograms color
             stars = TRUE,       # If TRUE, adds significance level with stars
             ci = TRUE)          # If TRUE, adds confidence intervals


# -----------------------------------------------
# Cullen and Frey
# -----------------------------------------------
# What dist does my data follow?
# https://stats.stackexchange.com/questions/58220/what-distribution-does-my-data-follow
#
library(fitdistrplus)
descdist(efadata$PR_open_ma3, discrete=FALSE,boot=1000, print = FALSE)
descdist(efadata$PR_open_ma3, discrete=FALSE,boot=1000, print = TRUE)
f1 <- fitdist(efadata$PR_open_ma3,"beta",method="mme")

# Create the descdist plot and store it
desc_plot <- descdist(efadata$PR_open_ma3, discrete = FALSE, boot = 1000)

# Modify axis scales
desc_plot <- desc_plot + 
  scale_x_continuous(name = "New X-axis Label", limits = c(0, 175)) +
  scale_y_continuous(name = "New Y-axis Label", limits = c(0, 175))

print(desc_plot)
# -----------------------------------------------
# Bartlett's test
# -----------------------------------------------
# https://personality-project.org/r/html/cortest.bartlett.html
# https://www.statology.org/bartletts-test-of-sphericity/
# -----------------------------------------------
dfa_complete <- na.omit(dfa)#not necessary with full data (imputed)
cortest.bartlett(cor(dfir), nrow(dfir), diag=TRUE)

# -----------------------------------------------
# MSO (KMO) Test Measure of Sampling Adequacy (MSA) 
# of factor analytic data matrices
# https://www.personality-project.org/r/html/KMO.html
#-----------------------------------------------
KMO(cor(dfir))

# -----------------------------------------------
# scree plot shows two factors for this dataset
# -----------------------------------------------
scree(dfir,factors=TRUE,pc=TRUE,main="Scree plot",hline=NULL,add=FALSE) 
VSS.scree(dfir, main = "scree plot")
# see the eigenvalues
print(scree(df))

# -----------------------------------------------
# Parallel Analysis
# -----------------------------------------------
# test for the number of factors 
fa.parallel(dfir2,fa="fa",ylabel="eigen values of factors",show.legend=F)
plot.new()
PAout<-fa.parallel(dfir2,fa="fa", plot=F)

# store the parallel analysis values
pa_actual<-PAout[["fa.values"]]
pa_sim<-PAout[["fa.sim"]]
pa_resample<-PAout[["fa.simr"]]

# plot the PA values
# but first, some colors
# color palette as a vector:
palette.col <- c(
  rgb(55, 131, 187, maxColorValue = 255),    # blue
  rgb(196, 60, 60, maxColorValue = 255),    # maroon
  rgb(127, 127, 127, maxColorValue = 255))    # grey

plot(1:9, pa_sim, col=palette.col[2],type="b", 
     pch=19, lty=2, cex.axis=0.9,
     xlab = "",
     ylab = "",
     ylim=c(-0.6,5))
title(xlab = "number of factors", mgp=c(2,1,0), cex.lab=0.9)
title(ylab = "eigen values of factors", mgp=c(2,1,0), cex.lab=0.9)
title("Parallel Analysis of Scree Plots", cex.main=0.9, line=0.5)
lines(pa_actual,col=palette.col[1],type="b",pch=15)
abline(h=1, 
       col=palette.col[3], 
       lty="dashed", 
       lwd=2.0)
legend("topright",
       inset=0.02,
       legend = c("actual","simulated"),
       col = palette.col[c(1,2)],
       pch = c(15, 19), 
       cex=1,
       text.font=3,
       box.lty = 0)

library(ggplot2)
library(dplyr)

# Combine the values into a data frame
plotdf <- data.frame(Factors = 1:9, Actual = pa_actual, Simulated = pa_sim)

# Create the plot
my_plot <- ggplot(plotdf) +
  geom_line(aes(x = Factors, y = Simulated, color = "Simulated"), linetype = "dashed", linewidth = 1) +
  geom_point(aes(x = Factors, y = Simulated, color = "Simulated")) +
  geom_line(aes(x = Factors, y = Actual, color = "Actual"), linewidth = 1) +
  geom_point(aes(x = Factors, y = Actual, color = "Actual")) +
  geom_hline(yintercept = 1, color = "grey", linetype = "dashed", linewidth = 1) +
  labs(title = "Parallel Analysis of Scree Plots",
       x = "Number of Factors",
       y = "Eigen Values of Factors",
       color = "") +
  scale_color_manual(values = c("Simulated" = rgb(196, 60, 60, maxColorValue = 255),
                                "Actual" = rgb(55, 131, 187, maxColorValue = 255))) +
  theme_minimal()

# Print the plot
print(my_plot)


# -----------------------------------------------
# Factor analysis with PSYCH
# documentation: https://cran.r-project.org/web/packages/psychTools/vignettes/factor.pdf
# p.18 for factor methods
# -----------------------------------------------

# -----------------------------------------------
# EFA Part 1 \\Chapter 6 & HICSS Conference
# -----------------------------------------------
fa_model1 = fa(df,2,fm="ml",rotate="none")
fa_model2 = fa(df,2,fm="pa",rotate="none")
fa_model3 = fa(df,2,fm="ml",rotate="varimax")
fa_model4 = fa(df,2,fm="ml",rotate="quartimax")
fa_model5 = fa(df,1,fm="ml",rotate="quartimax")
fa_model6 = fa(df,3,fm="ml",rotate="quartimax")

#6 variables; remove stars and forks for Model B comparison (HICSS)
#6 variables, ML, quartimax, 2 factors
# modify the dataframe
#dataframe without stars and forks;
# dataframe is named efadata (393 of 9 variables includes ID)
# rescore days_inactive
df_model4B <- data.frame(efadata)
upd_days   <- rescore(df_model4B$days_inactive)
# change df['updated'] to updated_r and redo results
df_model4B$days_inactive <- upd_days 
summarytools::descr(df_model4B,round.digits = 3,transpose=T)
df_model4B <- df_model4B %>%
  select(-c("ID", "stars_tot", "forks_tot"))
library(psych)
fa_model4B = fa(df_model4B, 2, fm="ml", rotate="varimax")
print(fa_model4B,digits=3)

# -----------------------------------------------
# EFA Part 2 \\Chapter 7
# -----------------------------------------------
# dataframe is dfir: inputed&rescored (n = 384); 
# start with 11 variables, inc. AVG & MED resp. time
fa_model7 = fa(dfir, 2, fm="ml", rotate="varimax")
print(fa_model7,cut=0,digits=3)
fa_model8 = fa(dfir, 2, fm="ml", rotate="quartimax")
print(fa_model8,cut=0,digits=3)
#
# try 3 factors
fa_model9 = fa(dfir, 3, fm="ml", rotate="varimax")
print(fa_model9,cut=0,digits=3)
fa_model10 = fa(dfir, 3, fm="ml", rotate="quartimax")
print(fa_model10,cut=0,digits=3)
#
# remove response time
names(dfir)
dfir2 <- select(dfir, -c(medResp, avgResp))
fa_model11 = fa(dfir2, 2, fm="ml", rotate="varimax")
print(fa_model11,cut=0,digits=3)

# -----------------------------------------------
# EFA validation for Part 2
# -----------------------------------------------
# split the dataset for cross validation
# -----------------------------------------------
dfir2b <- dfir2[, c("cmc", setdiff(names(dfir2), "cmc"))]
set.seed(3.14) 
sample = sample.split(dfir2b, SplitRatio = 0.65)
train = subset(dfir2b, sample == TRUE)
test  = subset(dfir2b, sample == FALSE)
names(dfir2b)
# -----------------------------------------------
# FA on train for cross validation
# -----------------------------------------------
fa11_train = fa(train,2,fm="ml",rotate="varimax")
fa11_test = fa(test,2,fm="ml",rotate="varimax")
# -----------------------------------------------
# compare to FA on test for cross validation
# -----------------------------------------------
fa.diagram(fa11_train, digits=3)
fa.diagram(fa11_test, digits=3)
print(fa11_train,cut=0,digits=3)
print(fa11_test,cut=0,digits=3)
# -----------------------------------------------
# END EFA Part II