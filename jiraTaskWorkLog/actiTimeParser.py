import pandas as pd

pd=pd.read_csv("STL Tech Jira Cloud (1).csv")

# Variables
start_date='17/04/2023'
end_date='21/04/2023'

# Exract all entries that have work logged between dat range
# Dates will have the notation of ;18/Apr/23 4:42 PM;
# Generate list of possible dates
date_list='

# Extract all entries that match specific user id
# Search each panda row, log work column for date_list. Need to use the full text row for the filter
# FUnction: INPUT = pandas data frame of tasks, UID,DATE_RANGE, OUTPUT: pandas data frame

# Create timesheet for that user id with summary of time worked
# For each task, consolidate the time spent per day into a single entry. Sum the time, append the notes with [time] for each entry
# Function: INPUT=pandas of Jira Tasks OUTPUT: pandas data frame timesheet of Jira tasks

# Consolidate that timesheet into actitime tasks
# For each task lookup the associated actitime ID
# Consolidate each task in the actitimes IDs. SUm the time, append each Jira Task in the notes with [time]
# Function: INPUT=timesheet of Jira Tasks OUTPUT: pandas data frame timesheet of actitime tasks

# Update actiTime
# Update actitime user
# Function: check to make sure that the actiTime task is open and valid. Overwrite date already present.

# count=0
# new_data=[]
# for i in range(len(pd)):
#     if(pd.loc[i,'User'] == 'Parks, Peter'):
#         print ("#############")
#         #print (pd.loc[i,'Comments'])
#         entries = str(pd.loc[i,'Comments']).split('\n')
#         major_count=count
#         for j in range(len(entries)):
#             
#             if entries[j] != '':
#                 row_data=pd.loc[i].to_dict()
#                 if len(entries) > 1:
#                     
#                     print (entries[j])
#                    
#                     new_comment = str(major_count) + " : " + entries[j] 
#                     row_data['Comments'] = new_comment
#                     
#                     if j > 0:
#                         row_data['Spent Time'] = ''
#                            
#                 new_data.append(row_data)
#                 count=count+1
#         
# 
# df = pd.from_dict(new_data)
# df.head
# 
# df.to_csv("C:/Users/RichardGray/OneDrive - STL Tech Limited/Company Docs/test.csv")
