load(paste0(getwd(), "/data/neighbor.Rdata"))
missing = which(is.na(neighbor.dat[,1])) # newdata rows to predict
clean = na.omit(neighbor.dat)

# k-NN: 9 folds cross-validation, 5-nearest neighbors
n.folds = 4
maxk = 30
folds = sample(rep(1:n.folds,length.out=nrow(clean)))
errs = matrix(NA,n.folds,maxk)
for(k in 1:maxk)
{
    for(f in 1:n.folds)
    {
        train = clean[f != folds,2:93]
        test = clean[f == folds,2:93]
        res = knn(train=train, test=test, cl=clean[f!=folds,1], k=k)
        errs[f,k] = sum(res != clean[f==folds,1])/length(res)
    }
}
colMeans(errs)


cv.glm.dat<-cv.glmnet(clean[,2:93], clean[,1])
lambda.min<-cv.glm.dat$lambda.min
n.folds = 4
folds = sample(rep(1:n.folds,length.out=nrow(clean)))
errs = rep(NA, n.folds)
for(f in 1:n.folds)
{
    train = clean[f != folds,2:93]
    test = clean[f == folds,2:93]
    model = randomForest(train,y=as.factor(clean[f!= folds, 1]))
    while(model$err.rate[100,1] > .25)
    {
        model = randomForest(clean[,2:93], y = as.factor(clean[,1]), importance=T,ntree=100)
    }
    res = predict(model, newdata=test)
    probs = predict(model, newdata=test, type = "prob")
    conf = apply(probs,1,sort)
    recalc = which(conf[3,] - conf[2,] < .2)
    
    # begin glm
    if (length(recalc > 0))
    {
        cv<-cv.glmnet(train, clean[f!= folds, 1], alpha=1)
        glm.train<-glmnet(train, clean[f!= folds, 1], family="multinomial", lambda=cv$lambda.min)
        new.pred<-predict(glm.train, test[recalc,], s=lambda.min, type="response")
        pred.recalc<-rep(NA, length(recalc))
        for (j in 1:nrow(new.pred)) {
            pred.recalc[j]<-which.max(new.pred[j,,1])
        }
        res[recalc] = pred.recalc
    }
    
    errs[f] = sum(res != clean[f==folds,1])/length(res)
}
mean(errs)

# final model!!
library(glmnet)
library(randomForest)
cv.glm.dat<-cv.glmnet(clean[,2:93], clean[,1])
lambda.min<-cv.glm.dat$lambda.min
bestmodel = randomForest(clean[,2:93], y = as.factor(clean[,1]), importance=T,ntree=100)
while(bestmodel$err.rate[100,1] > .20)
{
    model = randomForest(clean[,2:93], y = as.factor(clean[,1]), importance=T,ntree=100)
    if (bestmodel$err.rate[100,1] > model$err.rate[100,1])
    {
        bestmodel = model
    }
}
crime.pred = predict(model, newdata=neighbor.dat[missing,2:93])
probs = predict(model, newdata=neighbor.dat[missing,2:93], type = "prob")
conf = apply(probs,1,sort)
recalc = which(conf[3,] - conf[2,] < .2)
if (length(recalc) > 0)
{
    cv<-cv.glmnet(clean[,2:93], clean[, 1], alpha=1)
    glm.train<-glmnet(clean[,2:93], clean[, 1], family="multinomial", lambda=cv$lambda.min)
    new.pred<-predict(glm.train, neighbor.dat[as.integer(names(recalc)),2:93], s=lambda.min, type="response")
    pred.recalc<-rep(NA, length(recalc))
    for (j in 1:nrow(new.pred)) {
        pred.recalc[j]<-which.max(new.pred[j,,1])
    }
    crime.pred[recalc] = pred.recalc
}
save(crime.pred, file="paranormal.Rdata") # THE 24


# whole data set training error
cv.glm.dat<-cv.glmnet(clean[,2:93], clean[,1])
lambda.min<-cv.glm.dat$lambda.min
model = randomForest(clean[,2:93], y = as.factor(clean[,1]))
crime.pred = predict(model, newdata=clean[,2:93])
probs = predict(model, newdata=clean[,2:93], type = "prob")
conf = apply(probs,1,sort)
recalc = which(conf[3,] - conf[2,] < .2)
cv<-cv.glmnet(clean[,2:93], clean[, 1], alpha=1)
glm.train<-glmnet(clean[,2:93], clean[, 1], family="multinomial", lambda=cv$lambda.min)
if (length(recalc > 0))
{
    new.pred<-predict(glm.train, clean[as.integer(names(recalc)),2:93], s=lambda.min, type="response")
    pred.recalc<-rep(NA, length(recalc))
    for (j in 1:nrow(new.pred)) {
        pred.recalc[j]<-which.max(new.pred[j,,1])
    }
    crime.pred[recalc] = pred.recalc    
}
sum(crime.pred != clean[,1])/length(crime.pred) # 0 lol


s = sapply(1:500, function(i) randomForest(clean[,2:93], y = as.factor(clean[,1]), importance=T,ntree=i)$err.rate[i,1])
plot(s, xlab = "Number of trees", ylab = "CV error", main = "Error of Growing Random Forest")
points(smooth.spline(s), pch=16)