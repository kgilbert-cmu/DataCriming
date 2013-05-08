load("neighbor.Rdata")
library(glmnet)
library(tree)
library(gbm)

data.clean<-neighbor.dat
ind.na<-which(is.na(neighbor.dat))
data.na<-neighbor.dat[ind.na,]
data.full<-neighbor.dat[-ind.na,]

#Unsupervised
pca<-prcomp(data.clean[,-1])
pv<-cumsum(pca$sdev^2)/sum(pca$sdev^2)
pv.sig<-min(which(pv>=.99))

sc.sig<-pca$x[,1:pv.sig]

plot(sc.sig[-ind.na,1], sc.sig[-ind.na,2], col="blue",
     xlim=c(min(sc.sig[,1]), max(sc.sig[,2])), ylim=c(min(sc.sig[,2]), max(sc.sig[,2])))
points(sc.sig[ind.na,1], sc.sig[ind.na,2], col="red")


#Supervised

#glmnet lasso
cv.glm.dat<-cv.glmnet(data.full[,-1], data.full[,1], alpha=1)
lambda.min<-cv.glm.dat$lambda.min
glm.dat<-glmnet(data.full[,-1], data.full[,1], family="multinomial", lambda=lambda.min)
pred.glm.na<-predict(glm.dat, newx=data.na[,-1], s=lambda.min, type="response")
pred.glm.full<-predict(glm.dat, newx=data.full[,-1], s=lambda.min, type="response")
crime.glm.na<-rep(NA, nrow(data.na))
crime.glm.full<-rep(NA, nrow(data.full))

for (i in 1:nrow(data.na)) {
  crime.glm.na[i]<-which.max(pred.glm.na[i,,1])
}

for ( i in 1:nrow(data.full)){
  crime.glm.full[i]<-which.max(pred.glm.full[i,,1])
}

length(which(crime.glm.full!=data.full[,1]))

case<-rep(1:10, length.out=nrow(data.full))
case<-sample(case)

#cv
misclass<-rep(10, 0)
for (i in 1:5) {
  train<-data.full[-which(case==i),]
  test<-data.full[which(case==i),]
  cv<-cv.glmnet(train[,-1], train[,1], alpha=1)
  glm.train<-glmnet(train[,-1], train[,1], family="multinomial", lambda=cv$lambda.min)
  pred.test<-predict(glm.train, newx=test[,-1], s=cv$lambda.min, type="response")
  a<-rep(nrow(pred.test), 0)
  for (j in 1:nrow(pred.test)) {
    a[j]<-which.max(pred.test[j,,1])
  }
  misclass[i]<-length(which(a!=test[,1]))/length(a)
}


#trying glm with significant pca dims
#not useful
cv.glm.pca<-cv.glmnet(sc.sig[-ind.na,], data.full[,1], alpha=1)
lambda.min.pca<-cv.glm.pca$lambda.min
glm.pca<-glmnet(sc.sig[-ind.na,], data.full[,1], family="multinomial", lambda=lambda.min)
pred.glm.na.pca<-predict(glm.pca, newx=sc.sig[ind.na,], s=lambda.min, type="response")
pred.glm.full.pca<-predict(glm.pca, newx=sc.sig[-ind.na,], s=lambda.min, type="response")

crime.glm.na.pca<-rep(NA, nrow(data.na))
crime.glm.full.pca<-rep(NA, nrow(data.full))

for (i in 1:nrow(data.na)) {
  crime.glm.na.pca[i]<-which.max(pred.glm.na.pca[i,,1])
}

for ( i in 1:nrow(data.full)){
  crime.glm.full.pca[i]<-which.max(pred.glm.full.pca[i,,1])
}

length(which(crime.glm.full.pca!=data.full[,1]))

#tree
tree.full<-tree(factor(Crime)~., data=data.frame(data.full))
crime.tree.full<-predict(tree.full, newdata=data.frame(data.full), type="class")
length(which(crime.tree.full!=data.full[,1]))

#boost (incomplete)
boost<-gbm(factor(Crime)~., distribution="multinomial", data=data.frame(data.full),
           verbose=F, n.trees=1000)


pred.boost.na<-predict(boost, newdata=data.frame(data.na), n.trees=1000)
pred.boost.full<-predict(boost, newdata=data.frame(data.full), n.trees=1000)

crime.boost.na<-rep(NA, nrow(data.na))
crime.boost.full<-rep(NA, nrow(data.full))

for (i in 1:nrow(data.full)) {
  crime.boost.full[i]<-which.max(pred.boost.full[(3*i-2):(3*i)])
}


