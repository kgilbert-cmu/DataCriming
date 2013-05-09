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
# glm.dat<-glmnet(data.full[,-1], data.full[,1], family="multinomial", lambda=lambda.min)
n.folds = 4
folds = sample(rep(1:n.folds,length.out=nrow(clean)))
errs = rep(NA, n.folds)
for(f in 1:n.folds)
{
    train = clean[f != folds,2:93]
    test = clean[f == folds,2:93]
    model = randomForest(train,y=as.factor(clean[f!= folds, 1]))
    res = predict(model, newdata=test)
    probs = predict(model, newdata=test, type = "prob")
    conf = apply(probs,1,sort)
    recalc = which(conf[3,] - conf[2,] < .2)
    
    # begin glm
    cv<-cv.glmnet(train, clean[f!= folds, 1], alpha=1)
    glm.train<-glmnet(train, clean[f!= folds, 1], family="multinomial", lambda=cv$lambda.min)
    new.pred<-predict(glm.train, test[recalc,], s=lambda.min, type="response")
    pred.recalc<-rep(NA, length(recalc))
    for (j in 1:nrow(new.pred)) {
        pred.recalc[j]<-which.max(new.pred[j,,1])
    }
    
    res[recalc] = pred.recalc
    errs[f] = sum(res != clean[f==folds,1])/length(res)
}

model = randomForest(clean[,2:93], y = as.factor(clean[,1]))
crime.pred = predict(model, newdata=neighbor.dat[missing,2:93])
probs = predict(model, newdata=neighbor.dat[missing,2:93], type = "prob")
conf = apply(probs,1,sort)
recalc = which(conf[3,] - conf[2,] < .2)
save(crime.pred, recalc, file="randomForest.Rdata")


# whole data set
cv.glm.dat<-cv.glmnet(data.full[,-1], data.full[,1])
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

pred.recalc<-predict(glm.dat, data.na[recalc,-1], s=lambda.min, type="response")