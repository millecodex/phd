# -----------------------------------------------
# SEM
# -----------------------------------------------
# load data
# -----------------------------------------------
f <- file.choose()
efa2data <- read.csv(f)
# -----------------------------------------------
# build dataframe
# -----------------------------------------------
dfcfa <- data.frame(efa2data$forks,
                   efa2data$stars,
                   efa2data$mentions,
                   efa2data$criticality,
                   efa2data$lastUpdated,
                   efa2data$cmc,
                   efa2data$geo,
                   efa2data$commits,
                   efa2data$PR_open,
                   efa2data$comments,
                   efa2data$authors
)

dfcfa = rename(dfcfa, 
              forks       = efa2data.forks,
              stars       = efa2data.stars,
              mentions    = efa2data.mentions,
              criticality = efa2data.criticality,
              lastUpdated = efa2data.lastUpdated,
              cmc         = efa2data.cmc,
              geo         = efa2data.geo,
              authors     = efa2data.authors,
              commits     = efa2data.commits,
              prs         = efa2data.PR_open,
              comments    = efa2data.comments,
)
# check status of the data for NA values and counts
names(dfcfa)
colSums(is.na(dfcfa))
sapply(dfcfa, length)
# -----------------------------------------------
# impute missing data
# -----------------------------------------------
# Define imputation method
require(mice)
impMethod <- make.method(dfcfa)
impMethod[sapply(dfcfa, is.numeric)] <- "mean"

# Use mice() function with mean substitution
imp <- mice(dfcfa, m=5, method=impMethod, seed = 500)

# m is the number of multiple imputations (m=5 is generally a good start)
# method=impMethod specifies to use mean substitution for numerical columns
# Use complete() function to get the completed data
# 1 means that you want the first imputed dataset
dfcfai <- complete(imp,1) 
# -----------------------------------------------
# get descriptive stats
# -----------------------------------------------
mydata <- summarytools::descr(dfcfai,round.digits = 3,stats = c("mean", "sd", "min", "med", "max"),transpose=T)
mydata <- summarytools::descr(dfcfai,round.digits = 2,transpose=T)
# -----------------------------------------------
# rescore negatively valenced data
# recode the Inactive Since (days) column to have the high metric
# representative as positive and the lower as negative
# -----------------------------------------------
require(epmr)
dfcfair <- dfcfai
upd_updated <- rescore(dfcfai$lastUpdated)
upd_cmc     <- rescore(dfcfai$cmc)
upd_geo     <- rescore(dfcfai$geo)

# change df['updated'] to updated_r and redo results
dfcfair$lastUpdated <- upd_updated
dfcfair$cmc     <- upd_cmc 
dfcfair$geo     <- upd_geo 

# -----------------------------------------------
# correlation matrix plot
# -----------------------------------------------
# https://cran.r-project.org/web/packages/corrplot/vignettes/corrplot-intro.html 
# Pearson is the default correlation method in cor(df)
corrplot(cor(dfcfair),
         method="shade", 
         tl.col="black", 
         addCoef.col = 'black', 
         diag=F, 
         type='lower')

corrplot(cor(dfcfair, use = "complete.obs"), method = "circle")

# -----------------------------------------------
# scree plot shows number of factors
# -----------------------------------------------
scree(dfcfair,factors=TRUE,pc=TRUE,main="Scree plot",hline=NULL,add=FALSE) 
VSS.scree(dfcfair, main = "scree plot")
# see the eigenvalues
print(scree(dfcfair))
fa.parallel(dfcfair)

# -----------------------------------------------
# Parallel Analysis
# -----------------------------------------------
# test for the number of factors in your data using parallel analysis
# fa.parallel(dfcfair,fa="fa",ylabel="eigen values of factors",show.legend=F)
PAout<-fa.parallel(dfcfair,fa="fa")

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
plot(1:11, pa_sim, col=palette.col[2],type="b", 
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

# -----------------------------------------------
# CFA model definition
# -----------------------------------------------
# Model specification (using lavaan syntax)
# baseline
cfa1 <- '
# measurement model latent factors
  interest =~ forks + stars + mentions
  robustness =~ criticality + lastUpdated + cmc + geo
  engagement =~ authors + prs + comments + commits 
'
#redefined
cfa2 <- '
# measurement model latent factors
  interest =~ forks + stars + mentions
  robustness =~ criticality + lastUpdated + cmc + geo
  engagement =~ authors + prs + comments + commits 

# correlations 
  forks ~~ stars
'
# -----------------------------------------------
# scaling
# -----------------------------------------------
dfcfairs <- apply(dfcfair, 2, scale)
describe(dfcfairs)
# -----------------------------------------------
# CFA with Lavaan
# -----------------------------------------------
# MLR estimator uses robust standard errors to mitigate non-normality
# ML is the default and assumes normality
require(lavaan)
cfafit1 <- cfa(cfa1, data = dfcfairs, estimator = "MLR")
summary(cfafit1,
        standardized = TRUE,
        fit.measures = T)
fitMeasures(cfafit1, c("tli", "cfi", "rmsea", "srmr", "chisq", "df"))
# -----------------------------------------------
# construct reliability
# -----------------------------------------------
# Get the standardized parameter estimates
estimates <- parameterEstimates(fit1, standardized=TRUE)

# Define your factors
factors <- c("interest", "robustness", "engagement")

# Loop over each factor to calculate composite reliability
for(factor in factors){
  
  # Get factor loadings and error variances for the factor
  lambda_sq <- estimates[estimates$lhs == factor & estimates$op == "=~", "std.all"]^2
  theta <- estimates[estimates$lhs == factor & estimates$op == "~~" & estimates$rhs == factor, "std.all"]
  
  # Calculate composite reliability
  composite_reliability <- sum(lambda_sq) / (sum(lambda_sq) + theta)
  # Calculate average variance extracted
  average_variance_extracted <- mean(lambda_sq)
  print(paste("Composite reliability for", factor, ":", composite_reliability))
  print(paste("Average variance extracted for", factor, ":", average_variance_extracted))
}

# -----------------------------------------------
# SEM model definition
# -----------------------------------------------
# from health literature
# regression robustness ~ interest + engagement
sem1 <- '
# measurement model latent factors
  interest =~ forks + stars + mentions
  robustness =~  criticality + lastUpdated + geo + cmc
  engagement =~ authors + prs + commits + comments
  
# structure  
  robustness ~ engagement + interest

# correlations  
  forks ~~ stars
'

# add eng~int correlation
sem2 <- '
# measurement model latent factors
  interest =~ forks + stars + mentions
  robustness =~  criticality + lastUpdated + geo + cmc
  engagement =~ authors + prs + commits + comments
  
# structure  
  robustness ~ engagement + interest
  engagement ~ interest
  
# correlations  
  forks ~~ stars
'

# remove rob<-int path (-0.06)
# results in Heywood negative variance of -0.009
sem3 <- '
# measurement model latent factors
  interest =~ forks + stars + mentions
  robustness =~  criticality + lastUpdated + geo + cmc
  engagement =~ authors + prs + commits + comments

# structure    
  robustness ~ engagement 
  engagement ~ interest
 
# correlations   
  forks ~~ stars
'

# fix crit & lastUpdated together
sem4 <- '
# measurement model latent factors
  interest =~ forks + stars + mentions
  robustness =~  0.9*criticality + 0.7*lastUpdated + geo + cmc
  engagement =~ authors + prs + commits + comments
  
# structure  
  robustness ~ engagement
  engagement ~ interest
  
# correlations 
  forks ~~ stars
'
options(max.print = 1000)  # Increase max.print to 10000

# -----------------------------------------------
# SEM with Lavaan
# -----------------------------------------------
semfit1 <- sem(sem1, data = dfcfairs, estimator = "MLR")
semfit2 <- sem(sem2, data = dfcfairs, estimator = "MLR")
semfit3 <- sem(sem3, data = dfcfairs, estimator = "MLR")
semfit4 <- sem(sem4, data = dfcfairs, estimator = "MLR")

# this form does 1000 sample, regular, not bollen.stine
semfit4b <- sem(sem4, data = dfcfairs, estimator = "ML", 
                se="bootstrap", test = "Bollen.Stine", bootstrap = 5000,  
                parallel ="snow", ncpus = 4)


summary(semfit4b,
        standardized = TRUE,
        fit.measures = T)
parameterEstimates(semfit4b, boot.ci.type = "norm", standardized = TRUE)
parameterEstimates(semfit4,standardized = T)

semfit4b <- bootstrapLavaan(semfit4, 
                            R=5, 
                            type = "bollen.stine", 
                            FUN = "coef")
summary(semfit4b)
semfit4
semfit4b <- bootstrapLavaan(semfit4, 
                            R=100L, 
                            type = "bollen.stine", 
                            parallel = "snow", ncpus = 4, FUN=fitMeasures, 
                            fit.measures=c("chisq"))

# Make sure semfit4b is a vector for hist() function
semfit4b_vector <- as.vector(semfit4b)

# Create histogram
hist(semfit4b_vector, 
     main = "Histogram of semfit4b", 
     xlab = "Values", 
     col = "lightblue", 
     border = "black")

# compute a bootstrap based p-value
pvalue.boot <- length(which(semfit4b_vector > semfit4))/length(semfit4b)
semfit4b$coef

summary(semfit4b,
        standardized = TRUE,
        fit.measures = T)

fitMeasures(semfit4, c("tli", "cfi", "rmsea", "srmr", "chisq", "df"))
semPaths(object = semfit3,
         layout = "tree",
         rotation = 1,
         whatLabels = "std",
         edge.label.cex = 0.75,
         #what = "std",
         edge.color = "black",
         residuals = T)
# -----------------------------------------------
# Cronbach's alpha (1951) estimates the internal consistency reliability of a set
# -----------------------------------------------
# >0.9 suggest multi collinearity
# used rule of thumb is that a Cronbach's alpha coefficient 
# of 0.70 or higher indicates acceptable internal consistency reliability, 
# while a coefficient of 0.80 or higher indicates good reliability
alpha(dfcfair)$total$std.alpha
alpha(dfcfairs)$total$std.alpha
#
alpha(dfcfair, check.keys=T)$total$std.alpha

# -----------------------------------------------
# reliability -> alpha (cronbach) and omega
# -----------------------------------------------
require(semTools)
reliability(fit1)

# MLR estimator uses robust standard errors to mitigate non-normality
# ML is the default and assumes normality
fit1 <- cfa(cfa1, data = dfcfa_scaled, estimator = "MLR")
fit2 <- cfa(cfa2, data = dfcfa_scaled, estimator = "MLR")
semfit1 <- sem(sem1, data = dfcfa_scaled, estimator = "MLR")
semfit2 <- sem(sem2, data = dfcfa_scaled, estimator = "MLR")
semfit3 <- sem(sem3, data = dfcfa_scaled, estimator = "MLR")
semfit4 <- sem(sem4, data = dfcfa_scaled, estimator = "MLR")

summary(semfit2,
        standardized = TRUE,
        fit.measures = T)
fitMeasures(fit2, c("tli", "cfi", "rmsea", "srmr", "chisq", "df"))

# residuals to check the discrepancy between the two covariance matrices
# residuals of zero show the model is perfectly identified
std.resid <- lavaan::resid(fit2, type = "standardized")
std.resid
# Convert to a data frame
std.resid_df <- as.data.frame(std.resid)
std.resid_df
# Create scatterplot matrix
pairs(std.resid$cov, pch = 16, cex = 1.5, main = "Standardized Residuals Scatterplot Matrix")

# Create color plot of standardized residuals
library(ggplot2)
ggplot(data = reshape2::melt(std.resid$cov), aes(x = Var1, y = Var2, fill = value)) + 
  geom_tile(color = "white") + 
  scale_fill_gradient2(low = "blue", mid = "white", high = "red", midpoint = 0) + 
  theme(axis.text.x = element_text(angle = 90, hjust = 1))

resid(fit,type = "cor")
corPlot(resDat, scale=F, upper=FALSE, diag=T, main="Residuals Data")

resDat <- lavResiduals(fit, add.class = TRUE, type = "cor")
resDat

reliability(semfit3)
reliability(fit1)
?reliability

semPaths(object = semfit1,
         layout = "tree",
         rotation = 1,
         whatLabels = "std",
         edge.label.cex = 0.75,
         #what = "std",
         edge.color = "black",
         residuals = T)

anova(fit2, fit3)
?fitMeasures
# dfl_scaled is an atomic vector; turn into a dataframe
dfl_scaled_df <- data.frame(dfl_scaled)
describe(dfl_scaled)
# calculate variance
var(dfl_scaled_df$long)

semPaths(fit, whatLabels = "std", edge.label.cex = .5, layout = "tree2", 
         rotation = 2, style = "lisrel", intercepts = FALSE, residuals = T, 
         curve = 1, curvature = 3, nCharNodes = 8, sizeMan = 6, sizeMan2 = 3, 
         optimizeLatRes = TRUE, edge.color = "#000000")
semPaths(fit2.a, what = "est", layout = "tree", title = TRUE, style = "LISREL")

# -----------------------------------------------
# have a peek at modification indices
# -----------------------------------------------
modificationindices(semfit1, sort = TRUE)