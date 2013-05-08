load("~/36-462 Group Project/data/neighbor.Rdata")
missing = which(is.na(neighbor.dat[,1])) # newdata rows to predict
clean = na.omit(neighbor.dat)

# k-NN: 9 folds cross-validation, 5-nearest neighbors
n.folds = 9
k = 5
folds = sample(rep(1:n.folds,length.out=nrow(clean)))
errs = rep(NA,n.folds)
for(f in 1:n.folds)
{
    train = clean[f != folds,2:93]
    test = clean[f == folds,2:93]
    res = knn(train=train, test=test, cl=clean[f!=folds,1], k=k)
    errs[f] = sum(res != clean[f==folds,1])/length(res)
}
mean(errs)

crime.pred = predict(model, newdata=missing)
save(crime.pred, file="mypred.Rdata"))
