---
  title: "Most Harzardous Driving Area of Canada?"
author: "CEDLucien"
subtitle: Ommited
output:
  ioslides_presentation: default
beamer_presentation: default
widescreen: yes
---
  
  ## Introduction
  
  Hundreds of thousands of Canadians get injured each year in car accidents, and thousands die each year from them. With this many accidents, it would be extremely beneficial to identify dangerous driving areas. Using the dataset "Hazardous Driving Areas" from GeoTab, we will investigate determine the most dangerous driving area in Canada, and more.

Geotab's "Hazardous Driving Areas" dataset publishes real-time and historical incident that captures both accident and near-miss events, for example, sudden braking. It provides measurements related to driving incidents, and generates a severity score to rank hazardous areas around the world.



## Objectives

- The purpose of this analysis is to determine the most hazardous driving areas in Canada.
- We define an area as a hazardous driving area if its severity score is larger than the average severity score and the number of incidents is higher than the average number of incidents.


## Data Summary

- **New Variables**
- Proportion of type of incidents to total incidents
- Total incidents of each type in each province
- Is an area hazardous
- **Modifications**
- Joined "Hazardous Driving Areas" dataset with a "Population of Canada" dataset 

## Population
```{r, echo=FALSE, message=FALSE, warning=FALSE}
library(tidyverse)
library(ggmap)
file_url <- "https://raw.githubusercontent.com/ntaback/UofT_STA130/master/project/hazardousdriving.csv"
hazarddat <- read.csv(file_url)
hazardousdriving_can <- hazarddat %>% filter(Country == "Canada")

# poluation data
can_pop <- read_csv("can_pop_2018.csv")
colnames(can_pop)[3] <- "State"
colnames(can_pop)[6] <- "Population"
can_pop <- can_pop[-c(3,12, 13, 14), ]
can_pop <- can_pop %>% select(State, Population)
can_pop
```

## Total Areas in Each Province

```{r, echo=FALSE, message=FALSE, warning=FALSE}
num_observation_each_state <- hazardousdriving_can %>% group_by(State)%>% summarize(total=n())
num_observation_each_state
```

## Total Number of Incidents

```{r, echo=FALSE, message=FALSE, warning=FALSE}
total_num_incident <- hazardousdriving_can %>% group_by(State)%>% summarize(total_inci=sum(NumberIncidents))
total_num_incident <- total_num_incident[-c(8), ]
total_num_incident
```

## Avgerage Severity Score and Average Number of Incidents

```{r, echo=FALSE, message=FALSE, warning=FALSE}
mean_ss <- hazardousdriving_can %>% group_by(State)%>% summarize(avg_severity_score = mean(SeverityScore))
mean_inci <- hazardousdriving_can %>% group_by(State)%>% summarize(avg_num_inci = mean(NumberIncidents))
Mean_total <- inner_join(mean_ss,mean_inci,by = "State")

c_inci <- hazardousdriving_can$NumberIncidents %>% mean()
c_ss <- hazardousdriving_can$SeverityScore %>% mean()

newRow <- data.frame(State="Canada",avg_severity_score=c_ss,avg_num_inci=c_inci) 

Mean_total<-rbind(Mean_total, newRow)
Mean_total<- Mean_total[-c(8), ]
Mean_total
```

## Proportion of Hazardous Area in Each Province

```{r, echo=FALSE, message=FALSE, warning=FALSE}
HDC_new <- hazardousdriving_can[hazardousdriving_can$State != "Prince Edward Island",]
HDC_new$H_driving <- ifelse(HDC_new$SeverityScore > c_ss | HDC_new$NumberIncidents > c_inci, 'Yes', 'No')
mean_hdt <- mean(HDC_new$HdtIncidents)
HDC_new$level_Hdt <- ifelse(HDC_new$HdtIncidents == 0, 'None', ifelse(HDC_new$HdtIncidents <= mean_hdt, "Some", "Many"))

yes_HDC <- HDC_new %>%
group_by(State) %>% 
filter(H_driving == "Yes") %>%
summarize(num_yes=n())

yes_HDC <- inner_join(yes_HDC,num_observation_each_state, by = "State") %>% mutate(proportion = (num_yes/total)*100) %>% arrange(desc(proportion))
yes_HDC
```

```{r, echo = FALSE, message = FALSE, warning = FALSE}
state_Hdt <- HDC_new %>% select(State, HdtIncidents) %>% group_by(State) %>% summarize(total_Hdt = sum(HdtIncidents))

state_Mdt <- HDC_new %>% select(State, MdtIncidents) %>% group_by(State) %>% summarize(total_Mdt =sum(MdtIncidents))

state_Ldt <- HDC_new %>% select(State, LdtIncidents) %>% group_by(State) %>% summarize(total_Ldt =sum(LdtIncidents))

state_Car <- HDC_new %>% select(State, CarIncidents) %>% group_by(State) %>% summarize(total_Car =sum(CarIncidents))

state_Mpv <- HDC_new %>% select(State, MpvIncidents) %>% group_by(State) %>% summarize(total_Mpv=sum(MpvIncidents))

total_incident <- inner_join(state_Hdt, state_Mdt, by = "State")
total_incident <- inner_join(total_incident, state_Ldt, by = "State")
total_incident <- inner_join(total_incident, state_Car, by = "State")
total_incident <- inner_join(total_incident, state_Mpv, by = "State")
can_pop <- can_pop %>% select(State, Population)
total_incident <- inner_join(total_incident, can_pop, by = "State")
total_incident<- total_incident %>% mutate(P_Hdt = (total_Hdt/Population)*100, P_Mdt = (total_Mdt/Population)*100, P_Ldt = (total_Ldt/Population)*100, P_Car = (total_Car/Population)*100, P_Mpv = (total_Mpv/Population)*100)
#total_incident <- inner_join(total_incident,total_num_incident, by = 'State')

#total_incident<- total_incident %>% mutate(P_H = (total_Hdt/total_inci)*100, P_M = (total_Mdt/total_inci)*100, P_L = (total_Ldt/total_inci)*100, P_C = (total_Car/total_inci)*100, P_M = (total_Mpv/total_inci)*100)
#total_incident
```

## Statistical Methods

- Binary: Using ifelse to mutate a new binary variable based on our definition for hazadous area.
- ggplot: Scatterplot, Barplot
- Classification Tree: Using HdtIncident and MdtIncidentt as variables and sets three level of HdtIncident (None, Some and Many) to predict the H_driving by classification tree.
- ROC: Using the ROCR to calculate each threshold value for our classification tree


## Average Sererity Score and Average Number of Incidents Scatterpolt

```{r, echo=FALSE, message=FALSE, warning=FALSE}
Mean_total_plot <- ggplot(data = Mean_total, aes(x = avg_severity_score, y = avg_num_inci, color = State,label=State)) + geom_text(size = 2) + geom_point() + geom_vline(xintercept = c_ss, color="red") + geom_hline(yintercept = c_inci, color = "red")  + ggtitle("Average of Severity Score vs Average of NumberIncident")
Mean_total_plot
```

---

```{r, echo = FALSE, message = FALSE, warning = FALSE}
quebec <- c(rep("other", 7), "Quebec", "other")
g1<-ggplot(total_incident, aes(y= P_Hdt, x= State, fill = quebec)) + geom_col() + coord_flip() + ylab("Probability of Heavy Duty Truck Incident to Population") + ggtitle("Probability of Heavy Duty Truck Incident to Population of each Province") + theme(plot.title = element_text(hjust = 0.5))
g1
```

---

```{r, echo=FALSE, message=FALSE, warning=FALSE}
g2<-ggplot(total_incident, aes(y= P_Mdt, x= State, fill = quebec)) + geom_col() + coord_flip()+ ylab("Probability of Medium Duty Truck Incident to Population")+ ggtitle("Probability of Medium Duty Truck Incident to Population of each Province") + theme(plot.title = element_text(hjust = 0.5))
g2
```

---

```{r, echo=FALSE, message=FALSE, warning=FALSE}
g3<-ggplot(total_incident, aes(y= P_Ldt, x= State, fill = quebec)) + geom_col() + coord_flip()+ ylab("Probability of Light Duty Truck Incident to Population") + ggtitle("Probability of Light Duty Truck Incident to Population of each Province") + theme(plot.title = element_text(hjust = 0.5))
g3
```

---

```{r, echo=FALSE, message=FALSE, warning=FALSE}
g4<-ggplot(total_incident, aes(y= P_Car, x= State, fill = quebec)) + geom_col() + coord_flip()+ ylab("Probability of Car Incident to Population") + ggtitle("Probability of Car Incident to Population of each Province") + theme(plot.title = element_text(hjust = 0.5))
g4
```

---

```{r, echo=FALSE, message=FALSE, warning=FALSE}
g5<-ggplot(total_incident, aes(y= P_Mpv, x= State, fill = quebec)) + geom_col() + coord_flip() + ylab("Probability of Multi-Passenger Vehicle Incident to Population")+ ggtitle("Probability of Multi-Passenger Vehicle Incident to Population of each Province")
g5
```

## Classification Tree

```{r, echo=FALSE, message=FALSE, warning=FALSE}
library(rpart)
library(partykit)
library(ggplot2)

set.seed(130)
n <- nrow(HDC_new)
test_idx <- sample.int(n, size = round(0.25 * n))
train <- HDC_new[-test_idx, ]
test_1 <- HDC_new[test_idx, ]

tree <- rpart(H_driving ~ MdtIncidents + level_Hdt, data = train, parms = list(split='gini'),  method = "class")
#tree <- rpart(H_driving ~ MpvIncidents+CarIncidents+LdtIncidents+MdtIncidents+HdtIncidents, data = train, method = "class")

plot(as.party(tree), type = 'simple')
predicted_tree <- predict(object = tree, newdata = test_1, type = "prob")
t <- table(predicted_tree[,2] >= 0.5, test_1$H_driving)
```

## ROC 

```{r, echo=FALSE, message=FALSE, warning=FALSE}
pred <- ROCR::prediction(predictions = predicted_tree[,2], test_1$H_driving)
perf <- ROCR::performance(pred, 'tpr', 'fpr')
perf_df <- data.frame(perf@x.values, perf@y.values)
names(perf_df) <- c("fpr", "tpr")
roc <- ggplot(data = perf_df, aes(x = fpr, y = tpr)) +
geom_line(color = "blue") + geom_abline(intercept = 0, slope = 1, lty = 3) + ylab(perf@y.name) + xlab(perf@x.name)

predicted_tree <- predict(object = tree, newdata = test_1, type = "prob")
m <- table(predicted_tree[,2] >= 0.50, test_1$H_driving)
row.names(m) <- c("Pred < 5.5","Pred >= 5.5")
tpr_50 <- m[4]/sum(m[,2])
fpr_50 <- m[2]/sum(m[,1])
overall_acc_50 <- (m[1] + m[4])/(m[1] + m[2] + m[3] + m[4])

predicted_tree <- predict(object = tree, newdata = test_1, type = "prob")
c <- table(predicted_tree[,2] >= 0.60, test_1$H_driving)
row.names(c) <- c("Pred < 5.5", "Pred >= 5.5")
tpr_60 <- c[4]/sum(c[,2])
fpr_60 <- c[2]/sum(c[,1])
overall_acc_60 <- (c[1] + c[4])/(c[1] + c[2] + c[3] + c[4])

roc<-roc + geom_point(x = fpr_50, y = tpr_50, size = 3, colour = "black") +
geom_point(x = fpr_60, y = tpr_60, size = 3, colour = "red")
roc

```

## Results
- Base on the data, we discovered that the Saskatchewan and the Newfoundland and Labrador are the most two hazardous driving area
- However, since they have the smallest dataset which their datasets are less than 50, so we cannot use them to satisfy our prediction. 
- As the results, we find Quebec is the most hazardous driving area.
- Classification Tree
- Two significant main effects -- the number of incidents involving a medium-duty truck and a heavy-duty truck in Quebec state (from the figure P_Hdt and P_Mdt).

## Proportion of Hazardous Area in Each Province

```{r, echo=FALSE, message=FALSE, warning=FALSE}
yes_HDC
```

---

```{r, echo=FALSE, message=FALSE, warning=FALSE}
g1
```

---

```{r, echo=FALSE, message=FALSE, warning=FALSE}
g2
```

## Conclusion
- **conclusion**: Quebec is the most Hazardous driving province
- -> Highest probability of Heavy and Medium Duty Truck Incidents
- **limitation** : may only work for this specific data set
- **error** : Newfoundland and Labrador has the highest proportion of hazardous driving area, it does not match our definition of hazardous driving area

## Reference
“Canadian Motor Vehicle Traffic Collision Statistics: 2015.” Goverment of Canada -Transport Canada, 26 May 2017, www.tc.gc.ca/eng/motorvehiclesafety/tp-tp3322-2015-1487.html.

“Hazardous Driving Areas.” Geotab Data, 13 Mar. 2018, data.geotab.com/urban-infrastructure/hazardous-driving.

Statistics Canada. “Population and Dwelling Count Highlight Tables, 2011 Census.”Government of Canada, Statistics Canada, 9 Aug. 2016, www12.statcan.ca/census-recensement/2011/dp-pd/hlt-fst/pd-pl/Table-Tableau.cfm?LANG=Eng&T=301&SR=1&S=3&O=D&RPP=25&PR=0&CMA=0.





