let
    // --------------------------------------------------
    // 1. ORIGEN Y PREPARACIÓN BÁSICA
    // --------------------------------------------------
    Source =
        Csv.Document(
            File.Contents(DataPath & "HR_Employee_Attrition.csv"),
            [Delimiter=",", Columns=35, Encoding=65001, QuoteStyle=QuoteStyle.None]
        ),

    PromotedHeaders =
        Table.PromoteHeaders(Source, [PromoteAllScalars=true]),

    ChangedTypes =
        Table.TransformColumnTypes(
            PromotedHeaders,
            {
                {"Age", Int64.Type}, {"Attrition", type text}, {"BusinessTravel", type text},
                {"DailyRate", Int64.Type}, {"Department", type text}, {"DistanceFromHome", Int64.Type},
                {"Education", Int64.Type}, {"EducationField", type text}, {"EmployeeNumber", Int64.Type},
                {"EnvironmentSatisfaction", Int64.Type}, {"Gender", type text}, {"HourlyRate", Int64.Type},
                {"JobInvolvement", Int64.Type}, {"JobLevel", Int64.Type}, {"JobRole", type text},
                {"JobSatisfaction", Int64.Type}, {"MaritalStatus", type text}, {"MonthlyIncome", Int64.Type},
                {"MonthlyRate", Int64.Type}, {"NumCompaniesWorked", Int64.Type}, {"OverTime", type text},
                {"PercentSalaryHike", Int64.Type}, {"PerformanceRating", Int64.Type},
                {"RelationshipSatisfaction", Int64.Type}, {"StockOptionLevel", Int64.Type},
                {"TotalWorkingYears", Int64.Type}, {"TrainingTimesLastYear", Int64.Type},
                {"WorkLifeBalance", Int64.Type}, {"YearsAtCompany", Int64.Type},
                {"YearsInCurrentRole", Int64.Type}, {"YearsSinceLastPromotion", Int64.Type},
                {"YearsWithCurrManager", Int64.Type}
            }
        ),

    RemovedUnusedColumns =
        Table.RemoveColumns(ChangedTypes, {"EmployeeCount", "Over18", "StandardHours"}),

    RenamedColumns =
        Table.RenameColumns(
            RemovedUnusedColumns,
            {
                {"BusinessTravel", "Business_Travel"},
                {"DailyRate", "Daily_Rate"},
                {"DistanceFromHome", "Distance_From_Home"},
                {"EducationField", "Education_Field"},
                {"EmployeeNumber", "EmployeeID"},
                {"EnvironmentSatisfaction", "Environment_Satisfaction"},
                {"HourlyRate", "Hourly_Rate"},
                {"JobInvolvement", "Job_Involvement"},
                {"JobLevel", "Job_Level"},
                {"JobRole", "Job_Role"},
                {"JobSatisfaction", "Job_Satisfaction"},
                {"MaritalStatus", "Marital_Status"},
                {"MonthlyIncome", "Monthly_Income"},
                {"MonthlyRate", "Monthly_Rate"},
                {"NumCompaniesWorked", "Num_Companies_Worked"},
                {"OverTime", "Over_Time"},
                {"PercentSalaryHike", "Percent_Salary_Hike"},
                {"PerformanceRating", "Performance_Rating"},
                {"RelationshipSatisfaction", "Relationship_Satisfaction"},
                {"StockOptionLevel", "Stock_Option_Level"},
                {"TotalWorkingYears", "Total_Working_Years"},
                {"TrainingTimesLastYear", "Training_Times_Last_Year"},
                {"WorkLifeBalance", "Work_Life_Balance"},
                {"YearsAtCompany", "Years_At_Company"},
                {"YearsInCurrentRole", "Years_In_Current_Role"},
                {"YearsSinceLastPromotion", "Years_Since_Last_Promotion"},
                {"YearsWithCurrManager", "Years_With_Curr_Manager"}
            }
        ),

    // --------------------------------------------------
    // 2. COLUMNAS NUMÉRICAS DERIVADAS
    // --------------------------------------------------
    AddBinaryColumns =
        Table.AddColumn(
            Table.AddColumn(
                RenamedColumns,
                "Attrition_Numeric",
                each if [Attrition] = "Yes" then 1 else 0,
                Int64.Type
            ),
            "Over_Time_Numeric",
            each if [Over_Time] = "Yes" then 1 else 0,
            Int64.Type
        ),

    // --------------------------------------------------
    // 3. BINNING (AGRUPACIONES)
    // --------------------------------------------------
    AddBins =
        Table.AddColumn(
            Table.AddColumn(
                Table.AddColumn(
                    Table.AddColumn(
                        Table.AddColumn(
                            AddBinaryColumns,
                            "Total_Working_Years_Bin",
                            each if [Total_Working_Years] <= 5 then "<= 5"
                            else if [Total_Working_Years] <= 10 then "6 - 10"
                            else if [Total_Working_Years] <= 20 then "11 - 20"
                            else if [Total_Working_Years] <= 30 then "21 - 30"
                            else "> 30"
                        ),
                        "Age_Bin",
                        each if [Age] <= 25 then "18 - 25"
                        else if [Age] <= 35 then "26 - 35"
                        else if [Age] <= 45 then "36 - 45"
                        else if [Age] <= 55 then "46 - 55"
                        else "> 55"
                    ),
                    "Distance_From_Home_Bin",
                    each if [Distance_From_Home] <= 10 then "1 - 10"
                    else if [Distance_From_Home] <= 20 then "11 - 20"
                    else "> 20"
                ),
                "Monthly_Income_Bin",
                each if [Monthly_Income] <= 2000 then "< 2000"
                else if [Monthly_Income] <= 5000 then "2000 - 5000"
                else if [Monthly_Income] <= 12000 then "5000 - 12000"
                else "> 12000"
            ),
            "Years_At_Company_Bin",
            each if [Years_At_Company] <= 5 then "<= 5"
            else if [Years_At_Company] <= 10 then "6 - 10"
            else if [Years_At_Company] <= 20 then "11 - 20"
            else if [Years_At_Company] <= 30 then "21 - 30"
            else "> 30"
        ),

    // --------------------------------------------------
    // 4. DESCRIPCIONES DE ESCALAS (USANDO ITERACIÓN)
    // --------------------------------------------------
    ScaleMappings = {
        {"Education", "Education_Description",
            (x as number) =>
                if x = 1 then "Below College"
                else if x = 2 then "College"
                else if x = 3 then "Bachelor"
                else if x = 4 then "Master"
                else "Doctor"
        },
        {"Environment_Satisfaction", "Environment_Satisfaction_Description", each if _ = 1 then "Low" else if _ = 2 then "Medium" else if _ = 3 then "High" else "Very High"},
        {"Job_Involvement", "Job_Involvement_Description", each if _ = 1 then "Low" else if _ = 2 then "Medium" else if _ = 3 then "High" else "Very High"},
        {"Job_Satisfaction", "Job_Satisfaction_Description", each if _ = 1 then "Low" else if _ = 2 then "Medium" else if _ = 3 then "High" else "Very High"},
        {"Performance_Rating", "Performance_Rating_Description", each if _ = 1 then "Low" else if _ = 2 then "Good" else if _ = 3 then "Excellent" else "Outstanding"},
        {"Relationship_Satisfaction", "Relationship_Satisfaction_Description", each if _ = 1 then "Low" else if _ = 2 then "Medium" else if _ = 3 then "High" else "Very High"},
        {"Work_Life_Balance", "Work_Life_Balance_Description", each if _ = 1 then "Bad" else if _ = 2 then "Good" else if _ = 3 then "Better" else "Best"},
        {"Job_Level", "Job_Level_Description", each if _ = 1 then "Entry Level / Junior" else if _ = 2 then "Associate / Intermediate" else if _ = 3 then "Mid-Level / Partner" else if _ = 4 then "Senior / Lead" else "Director / Expert"},
        {"Stock_Option_Level", "Stock_Option_Level_Description", each if _ = 0 then "No Participation" else if _ = 1 then "Standard Grant" else if _ = 2 then "High Grant" else "Executive / Top Talent Grant"}
    },

    AddDescriptions =
        List.Accumulate(
            ScaleMappings,
            AddBins,
            (state, current) =>
                Table.AddColumn(
                    state,
                    current{1},
                    each current{2}(Record.Field(_, current{0})),
                    type text
                )
        ),

    // --------------------------------------------------
    // 5. AJUSTES FINALES
    // --------------------------------------------------
    CurrencyTypes =
        Table.TransformColumnTypes(
            AddDescriptions,
            {
                {"Daily_Rate", Currency.Type},
                {"Hourly_Rate", Currency.Type},
                {"Monthly_Income", Currency.Type},
                {"Monthly_Rate", Currency.Type}
            }
        )

in
    CurrencyTypes