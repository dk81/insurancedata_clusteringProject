# K-Means Clustering On Insurance Customers Data
# By David Ku
# On December 18, 2019

# This is an R Version of the Python project on Clustering on Insurance Customers Data

# Brief: An insurance company would like to know some information on its existing customers. 
# The company would like to know who to try to upsell to.

#------------------------------

#------------------------------

# Load R Libraries

library(ggplot2)
library(tidyverse)

# 1) Load Data and Basic Exploratory Data Analysis (EDA):

# Load .csv (Remember to set working directory of where the .csv file is):

insurance_data <- read.csv('insurance_customers.csv', header = TRUE)

# Check head of data:
head(insurance_data)

# Check dimensions of data:

dim(insurance_data)

# Check data type for each variable with str():

str(insurance_data)

# Remove Customer column full of Customer IDs:

insurance_data$Customer <- NULL

# Check data type for each variable with str():

str(insurance_data)

# Check for any NULL:

sum(is.na(insurance_data))

# Pairplots

library(GGally)

# Obtain numerical columns except for number of open complaints and 
# number of policies:

numerical_cols <- c('Customer_Lifetime_Value', 'Income', 'Monthly_Premium_Auto', 
                    'Months_Since_Last_Claim', 'Months_Since_Policy_Inception',
                    'Total_Claim_Amount')

# Pairplots (does take time):
ggpairs(insurance_data, columns = numerical_cols)

#----------------------------
# 2) Principal Component Analysis (PCA) On Insurance Data
#----------------------------

# Perform PCA

pca_data <- prcomp(insurance_data[c(numerical_cols, 'Number_of_Open_Complaints',
                                    'Number_of_Policies')], 
                   scale. = T, center = T)

# Matrix of variable loadings
pca_data$rotation 

# Standard deviations of principal components
pca_data$sdev 

# Proportions for each principal components
pca_data$sdev / sum(pca_data$sdev)

### Making a scree plot:

scree_data <- data.frame('PC' = 1:8, 'Proportion' = pca_data$sdev / sum(pca_data$sdev))

scree_data

scree_data['Total_Var'] = cumsum(scree_data$Proportion)

## Plot scree plot in ggplot2:

plot <- ggplot(scree_data, aes(x = PC, y = Total_Var)) 

plot + geom_point(color = 'blue') + geom_line() +
  labs(x = "\n Principal Component \n", y = "Total Variance \n", 
       title = "Scree Plot From PCA \n") + 
  theme(plot.title = element_text(hjust = 0.5, colour = "darkgreen"), 
        axis.title.x = element_text(face="bold", size = 8),
        axis.title.y = element_text(face="bold", size = 8),
        axis.text.x = element_text(vjust = 0.2),
        legend.title = element_text(face="bold", size = 10)) 

# Go for 7 PCs it seems.

# Look at variable loadings again and then pick out top features

pca_rotations <- pca_data$rotation 

pca_rotations

# Top features:

# In PC1 it's Monthly Premium Auto, Total Claim Amount and then Customer Lifetime Value (CLV)
# In PC2 it's Income, CLV, Monthly Premium Auto
# In PC3 it's Months_Since_Last_Claim, Months_Since_Policy_Inception

# From the Python findings, Income and Monthly Auto Premiums is one pair to look at.
# Scatterplot Between Income and Monthly Premiums:

ggplot(insurance_data, aes(x = Income, y = Monthly_Premium_Auto)) +
  geom_point(color = 'red', alpha = 0.5)+
  labs(x = "\n Income", y = "Monthly Auto Premiums \n", 
       title = "Income Vs Monthly Auto Premiums \n") + 
  theme(plot.title = element_text(hjust = 0.5), 
        axis.title.x = element_text(face="bold", colour = "darkgreen", size = 12),
        axis.title.y = element_text(face="bold", colour = "darkgreen", size = 12),
        legend.title = element_text(face="bold", size = 10))

# Note the unemployed part of the scatterplot where Income = 0. It is best not to upsell to 
# this group as they have no money (presumably).


# Number of unemployed

num_unemp <- sum(insurance_data$Income == 0)

num_unemp

# Insurance data without unemployed:

insurance_data2 <- insurance_data[insurance_data$Income != 0, ]

insurance_data2 

dim(insurance_data2)

# Check that dimensions are correct. 
# That is num rows in original data - num_unemp = num rows in insurance_data2

(dim(insurance_data)[1] - num_unemp) == dim(insurance_data2)[1]

#----------------------------
# 3) K-Means Clustering - Finding "Optimal" k Clusters
#----------------------------

# Python code explored DBSCAN, Gaussian Mixture Models and K-Means
# In here I just do K-Means Clustering.


# Producing A Scree Plot For Determining Optimal k Clusters in K-Means:
# Income Vs Monthly Premiums

total_within_sumsq <- rep(NA, 8) #Initialize

for (k in 1:8){
  insur_kmeans <- kmeans(insurance_data2[c('Income', 'Monthly_Premium_Auto')], 
                         centers = k)
  
  # Scree Plot: use total within cluster sum of squares
  
  total_within_sumsq[k] <- insur_kmeans$tot.withinss 
}

total_within_sumsq

## ggplot2 Version Of Scree Plot:

# Create table

scree_table <- data.frame(cbind(1:8, total_within_sumsq))

scree_table 

# Change column names:

colnames(scree_table) <- c("k", "TWSS")

# Scree ggplot plot:
ggplot(scree_table, aes(x = k, y = TWSS)) + geom_point() + geom_line() +
  labs(x = "\n Number Of Clusters (k)", y = "Total Within Sum Of Squares \n", 
       title = "Scree Plot - Income Vs Monthly Premiums \n") + 
  theme(plot.title = element_text(hjust = 0.5), 
        axis.title.x = element_text(face="bold", colour = "darkgreen", size = 12),
        axis.title.y = element_text(face="bold", colour = "darkgreen", size = 12),
        legend.title = element_text(face="bold", size = 10))

# Choose 3 clusters which is the elbow of the scree plot

#-----------------------------------
# 4) Plots With Labelled Clusters
#-----------------------------------

kmeans_model <- kmeans(insurance_data2[c('Income', 'Monthly_Premium_Auto')],
                       centers = 3)

# Total Sum Of Squares:

kmeans_model$totss

# Cluster centres (Cluster 1, 2, 3)

kmeans_model$centers

# Size for each cluster / Number Of Points in each cluster

kmeans_model$size

# Cluster labels:

kmeans_model$cluster

### Plotting clusters with labels:

# Create new copy on second insurance data (without unemployed)

insur_cluster <- insurance_data2

# Add star_km3 cluster component as new column to star_km3:

insur_cluster$clusterType <- as.factor(kmeans_model$cluster)

# Plot with Clusters Indicated By Colours:

ggplot(insur_cluster, aes(x = Income, y = Monthly_Premium_Auto, color = clusterType)) + 
  geom_point() + 
  labs(x = "\n Income", y = "Monthly Auto Premiums \n", 
       title = "Auto Insurance Customer Groups \n",
       colour = "Cluster Group") + 
  theme(plot.title = element_text(hjust = 0.5), 
        axis.title.x = element_text(face="bold", colour = "darkgreen", size = 12),
        axis.title.y = element_text(face="bold", colour = "darkgreen", size = 12),
        legend.title = element_text(face="bold", size = 10))

# The clusters are clustered by Income groups. This result is different
# than the one from the Python code findings.

# The green cluster (cluster 2) is the largest income group but many of them are paying
# less than 150 / month on premiums. Can try to upsell to some in this cluster as they have
# more money.

high_income_group <- insur_cluster[insur_cluster$clusterType == 2, ]

high_income_group

# Check those above 150 monthly auto premiums:
# Using dplyr functions:

# Counts For each vehicle class, monthly premiums at least 150:

high_income_group %>%
  filter(Monthly_Premium_Auto >= 150) %>%
  group_by(Vehicle_Class) %>%
  summarise(count = n())

# Average Income By Vehicle Class, monthly premiums at least 150:

high_income_group %>%
  filter(Monthly_Premium_Auto >= 150) %>%
  group_by(Vehicle_Class) %>%
  summarise(avg = mean(Income))


## Check those below 150 monthly auto premiums:

# Counts For each vehicle class, monthly premiums below 150:

high_income_group %>%
  filter(Monthly_Premium_Auto < 150) %>%
  group_by(Vehicle_Class) %>%
  summarise(count = n())

# Average income by vehicle class, monthly premiums below 150

high_income_group %>%
  filter(Monthly_Premium_Auto < 150) %>%
  group_by(Vehicle_Class) %>%
  summarise(avg = mean(Income))

# From high income group, thosewith luxury vehicles are paying above 150/mth
# Could try to upsell to sports car and SUV owners who are paying less than 150 / mth,
# try to upsell to them to the above 150 /mth part of the cluster.
