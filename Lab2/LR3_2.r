if (!require("BiocManager", quietly = TRUE))
  install.packages("BiocManager")
BiocManager::install("mixOmics")
library(mixOmics)
set.seed(5249)
library(plsgenomics)
data(Colon)
X <- Colon$X
Y <- Colon$Y
dim(X)
summary(Y)
pca.Colon = pca(X, ncomp = 10, center = TRUE, scale = TRUE) 
plot(pca.Colon)
plotIndiv(pca.Colon, group = Colon$Y, ind.names = FALSE, # plot the samples projected
          legend = TRUE, title = 'PCA on Colon, comp 1 - 2')
Colon.splsda <- splsda(X, Y, ncomp = 10)
plotIndiv(Colon.splsda , comp = 1:2, 
          group = Colon$Y, ind.names = FALSE,  # colour points by class
          ellipse = TRUE, # include 95% confidence ellipse for each class
          legend = TRUE, title = '(a) Colon with confidence ellipses')
background = background.predict(Colon.splsda, comp.predicted=2, dist = "max.dist")
plotIndiv(Colon.splsda, comp = 1:2,
          group = Colon$Y, ind.names = FALSE, # colour points by class
          background = background, # include prediction background for each class
          legend = TRUE, title = " (b) Colon with prediction background")
perf.splsda.Colon <- perf(Colon.splsda, validation = "Mfold", 
                          folds = 5, nrepeat = 10, # use repeated cross-validation
                          progressBar = FALSE, auc = TRUE) # include AUC values
plot(perf.splsda.Colon, col = color.mixo(5:7), sd = TRUE,
     legend.position = "horizontal")
perf.splsda.Colon$choice.ncomp 
list.keepX <- c(1:10,  seq(20, 300, 10))
tune.splsda.Colon <- tune.splsda(X, Y, ncomp = 4, # calculate for first 4 components
                                 validation = 'Mfold',
                                 folds = 5, nrepeat = 10, # use repeated cross-validation
                                 dist = 'max.dist', # use max.dist measure
                                 measure = "BER", # use balanced error rate of dist measure
                                 test.keepX = list.keepX,
                                 cpus = 2) # allow for paralleliation to decrease runtime
plot(tune.splsda.Colon, col = color.jet(4)) 
tune.splsda.Colon$choice.ncomp$ncomp
tune.splsda.Colon$choice.keepX 
optimal.ncomp <- tune.splsda.Colon$choice.ncomp$ncomp
optimal.keepX <- tune.splsda.Colon$choice.keepX[1:optimal.ncomp]
final.splsda <- splsda(X, Y, 
                       ncomp = optimal.ncomp, 
                       keepX = optimal.keepX)
plotIndiv(final.splsda, comp = c(1,2), # plot samples from final model
          group = Colon$Y, ind.names = FALSE, # colour by class label
          ellipse = TRUE, legend = TRUE, # include 95% confidence ellipse
          title = ' (a) sPLS-DA on Colon, comp 1 & 2')
# set the styling of the legend to be homogeneous with previous plots
legend=list(legend = levels(Y), # set of classes
            col = unique(color.mixo(Y)), # set of colours
            title = "Tumour Type", # legend title
            cex = 0.7) # legend size

# generate the CIM, using the legend and colouring rows by each sample's class
cim <- cim(final.splsda, row.sideColors = color.mixo(Y), 
           legend = legend)
# form new perf() object which utilises the final model
perf.splsda.Colon <- perf(final.splsda, 
                          folds = 5, nrepeat = 10, # use repeated cross-validation
                          validation = "Mfold", dist = "max.dist",  # use max.dist measure
                          progressBar = FALSE)

# plot the stability of each feature for the first three components, 'h' type refers to histogram
par(mfrow=c(1,3))
plot(perf.splsda.Colon$features$stable[[1]], type = 'h', 
     ylab = 'Stability', 
     xlab = 'Features', 
     main = '(a) Comp 1', las =2)
plot(perf.splsda.Colon$features$stable[[2]], type = 'h', 
     ylab = 'Stability', 
     xlab = 'Features', 
     main = '(b) Comp 2', las =2)
var.name.short <- Colon$gene.names # form simplified gene names

plotVar(final.splsda, comp = c(1,2), var.names = list(var.name.short), cex = 3) # generate correlation circle plot
train <- sample(1:nrow(X), 50) # randomly select 50 samples in training
test <- setdiff(1:nrow(X), train) # rest is part of the test set

# store matrices into training and test set:
X.train <- X[train, ]
X.test <- X[test,]
Y.train <- Y[train]
Y.test <- Y[test]
train.splsda.Colon <- splsda(X.train, Y.train, ncomp = optimal.ncomp, keepX = optimal.keepX)
predict.splsda.Colon <- predict(train.splsda.Colon, X.test, 
                                dist = "mahalanobis.dist")
predict.comp2 <- predict.splsda.Colon$Y$mahalanobis.dist[,2]
table(factor(predict.comp2, levels = levels(Y)), Y.test)
auc.splsda = auroc(final.splsda, roc.comp = 1, print = FALSE) # AUROC for the first component
auc.splsda = auroc(final.splsda, roc.comp = 2, print = FALSE) # AUROC for all three components
