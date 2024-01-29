# Install and load necessary packages
if (!requireNamespace("BiocManager", quietly = TRUE)) {
  install.packages("BiocManager")
}
BiocManager::install("Rgraphviz")
install.packages("bnlearn")

library(bnlearn)
library(Rgraphviz)

# Define the data to work with
data.to.work <- dfcfair
data.to.work <- data.frame(lapply(dfcfair, as.numeric))

# Set the name of a text file to save the BN parameters
param.name <- "bnparams.txt"

# Learn a BN structure from data using Hill-Climb algorithm
bn.structure <- hc(data.to.work)

# Define variables
f1.vars <- c("forks", "stars", "mentions", "crit", "lastUpdated", "cmc", "geo", "commits", "prs", "comments", "auth")

# Define color groups
group1 <- c("forks", "stars", "mentions")
group2 <- c("crit", "lastUpdated", "cmc", "geo")
group3 <- c("commits", "prs", "comments", "auth")

# Set colors based on groups
colors <- rep("skyblue", length(f1.vars)) # default color for all nodes
names(colors) <- f1.vars
colors[group1] <- "#FF7F50" # Coral
colors[group2] <- "#ADFF2F" # GreenYellow
colors[group3] <- "#8A2BE2" # BlueViolet

# Create a graph object
graph <- bnlearn::as.graphNEL(bn.structure)

# Add node attributes
nAttrs <- list(shape = "ellipse", fillcolor = colors, fontsize = 10)
names(nAttrs$fillcolor) <- nodes(graph)

# Layout the graph
layoutGraph(graph, nodeAttrs = nAttrs)

# Render the graph
Rgraphviz::renderGraph(graph)

# Convert all columns to numeric
data.to.work.num <- data.frame(lapply(data.to.work, as.numeric))

# Calculate arc strengths
strengths <- arc.strength(bn.structure, data = data.to.work, criterion = "bic")
