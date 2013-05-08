load("~/36-462 Group Project/data/neighbor.Rdata")
missing = which(is.na(neighbor.dat[,1])) # newdata rows to predict

model = # pick a model

crime.pred = predict(model, newdata=missing)
save(crime.pred, file="mypred.Rdata"))
