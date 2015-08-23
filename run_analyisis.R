#libraries required and file download
require(data.table)
require(reshape2)

url <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
f <- "Dataset.zip"
if (!file.exists(path)) {dir.create(path)}
download.file(url, file.path(path, f))
rm(url, f)

#the file is extracted manually using winRar therefore we have "UCI HAR Dataset" dir in our wd
#path is created in order to load files correctly
path <- getwd()
path <- file.path(path, "UCI HAR Dataset")

#files load
dt_SubjectTrain <- fread(file.path(path, "train", "subject_train.txt"))
dt_SubjectTest  <- fread(file.path(path, "test" , "subject_test.txt" ))

dt_ActivityTrain <- fread(file.path(path, "train", "Y_train.txt"))
dt_ActivityTest  <- fread(file.path(path, "test" , "Y_test.txt" ))

#fread() throws error, using slower read functiong
dt_Train <- data.table(read.table(file.path(path, "train", "X_train.txt")))
dt_Test  <- data.table(read.table(file.path(path, "test" , "X_test.txt" )))

dt_Features <- fread(file.path(path, "features.txt"))
setnames(dt_Features, names(dt_Features), c("featureNum", "featureName"))
##only those with sd and mean
dt_Features <- dt_Features[grepl("mean\\(\\)|std\\(\\)", featureName)]

#merging rows
dt_Subject <- rbind(dt_SubjectTrain, dt_SubjectTest)
setnames(dt_Subject, "V1", "subject")
dt_Activity <- rbind(dt_ActivityTrain, dt_ActivityTest)
setnames(dt_Activity, "V1", "activityNum")
dt <- rbind(dt_Train, dt_Test)

#merging columns
dt_Subject <- cbind(dt_Subject, dt_Activity)
dt <- cbind(dt_Subject, dt)
#key set for memory efficiency
setkey(dt, subject, activityNum)

#number vectors into to variables names matching in dt
dt_Features$featureCode <- dt_Features[, paste0("V", featureNum)]
select <- c(key(dt), dt_Features$featureCode)
dt <- dt[, select, with=FALSE]

#descriptive names reading and setting
dt_ActivityNames <- fread(file.path(path, "activity_labels.txt"))
setnames(dt_ActivityNames, names(dt_ActivityNames), c("activityNum", "activityName"))

#labeling with descriptive names
##merging
dt <- merge(dt, dt_ActivityNames, by="activityNum", all.x=TRUE)
setkey(dt, subject, activityNum, activityName)
##melting and reashaping
dt <- data.table(melt(dt, key(dt), variable.name="featureCode"))
dt <- merge(dt, dt_Features[, list(featureNum, featureCode, featureName)], by="featureCode", all.x=TRUE)

#tidy data
dt_Tidy <- dt[, list(count = .N, average = mean(value)), by=key(dt)]

#exporting tidy data
write.table(dt_Tidy, 'tidy.txt', row.names = F)

