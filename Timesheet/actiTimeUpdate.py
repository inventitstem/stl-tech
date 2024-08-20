import requests
import json
import pandas as pd
import math
import os
from datetime import datetime, timedelta

base_url = "https://eu.actitime.com/stl-tech/api/v1/"

headers = {
    'accept': 'application/json; charset=UTF-8',
    #'authorization': 'Basic cmdyYXk6dTYhUzZhcVdEUmE5NGNz',
    # Already added when you pass json= but not when you pass data=
    'Content-Type': 'application/json',
}


def get_tasks(user, password):
    api_url = base_url + "tasks?offset=0&limit=1000"
    #print(api_url)
    #print(headers)
    response = requests.get(api_url, headers=headers, auth=(user, password))
    #print(response)
    #print(response.json())
    #decoded_response = json.loads(response.json())
    #print(decoded_response)
    df = pd.DataFrame.from_dict(response.json())
    df_data_temp = pd.concat([df.drop(['items'], axis=1), df['items'].apply(pd.Series)], axis=1)
    df_data = pd.concat([df_data_temp.drop(['allowedActions'], axis=1), df_data_temp['allowedActions'].apply(pd.Series)], axis=1)
    df_data.to_csv('actiTimeTasks.csv')
    
    return df_data
    
def get_uid(user, password):
    api_url = base_url + "users/me"
    response = requests.get(api_url, headers=headers, auth=(user, password))
    #print(response)
    #print(response.json())
    #decoded_response = json.loads(response.json())
    #print(decoded_response)
    user_id=52#my id
    
    return user_id


def update_day(user, password, timesheet, date, user_id):#Update time value
    
    date_string_api = date.strftime('%Y-%m-%d')
    date_string_column = date.strftime('%d/%m/%Y')
    #print(timesheet.to_string())
    for i in range(len(timesheet)):
        time= timesheet.iloc[i][date_string_column]
        #comment = str(timesheet.iloc[i][date_string_column+"-Description"])
        comment = str(timesheet.iloc[i][date_string_column+"-WUDescription"])
        
        if math.isnan(time):
            time=0
            comment = ""
            
        task_id = timesheet.index.tolist()[i]
        api_url = base_url + "timetrack/" +str(user_id) + "/" + date_string_api + "/" + str(task_id)
        json_data = {
            'time': str(round(time)),
            'comment': comment ,
        }
        print(api_url + '->' + str(round(time)))


        response = requests.patch(api_url, headers=headers, json=json_data, auth=(user, password))
        #print(response)
        print(response.json())
 
def read_workingHours(path):#Update time value
    df = pd.read_csv(path)
    df["Duration"] = df["Duration"].astype(str) + ":00"# Add seconds so that data can be converted
    df["Duration"] = pd.to_timedelta(df["Duration"]) # convert data

    return df
    
def convert_delta_time(delta_time):
    delta_day_split = delta_time.split(' ')
    delta_time_split = delta_day_split[2].split(':')
    
    hours =  int(delta_day_split[0]*24) + int(delta_time_split[0])
    minutes = int(delta_time_split[1])
    
    if hours<10:
        hours_pad=str('0')
    else:
        hours_pad=str('')
        
    if minutes<10:
        minutes_pad=str('0')
    else:
        minutes_pad=str('')
    
    hours_string = hours_pad + str(hours) + ':' + minutes_pad + str(minutes)
    minutes_total = hours*60 + minutes
    
    return {'hours_string' : hours_string, 'total_minutes' : minutes_total}
    
def analyse_day(df,day,taskList,df_tasks):
    df_day_temp = df.loc[df['Day'] == day]

    #Capture teams meetings so that they can be tagged but also the details field that is automatically populated reduced.
    df_day_temp.loc[df_day_temp['Work unit details'].str.contains('Microsoft Teams meeting', na=False),'Work unit details'] = 'Teams Meeting'

    #Add task id header if no entries for the day. Not the best way to do it but works
    if len(df_day_temp) == 0:
        df_day_temp['TaskID'] = ''
        df_day_temp['JiraID'] = ''
    
    print(df_day_temp.to_string())
    print("There are " + str(len(df_day_temp)) + "entries")

    ids=[]
    jiras=[]

    for x in range(len(df_day_temp)):
        #Get task IDs
        tag = str(((df_day_temp.iloc[x])['Tags'])).split(':')
        task_id = tag[len(tag)-1]
        #print(task_id)
        
        #Get Jira tickets
        jira = str(((df_day_temp.iloc[x])['Work unit description'])).split(':')[0].split('-')
        jira_id=""
        print(type(jira))
        if(type(jira) == list and len(jira) == 2):
            if(jira[1].isdigit()):
                print("Jira detected")
                jira_id = jira[0] +'-'+jira[1]
                #Re-type the works unot to allows for better representation
                print(str(((df_day_temp.iloc[x])['Work unit description'])))
                df_day_temp.iloc[x,df_day_temp.columns.get_loc('Work unit description')]=jira_id + "~" + str((df_day_temp.iloc[x])['Work unit details'])
                #print(str(((df_day_temp.iloc[x])['Work unit description'])))
        jiras.append({'JiraID' : jira_id})
        
        #if((df_day_temp.iloc[x])['Task'] == 'Without task'):
            #print('Without task')
            #break

        if task_id in taskList:
            #print('Valid ID')
            ids.append({'TaskID' : task_id})
            # Check to see if actiTime task is openand bookable
            if(df_tasks.query('id == ' + task_id)['status'].values[0] == 'completed'):
                print(str(task_id) +" = Complete Use another bookign code!")
                input()
        else:
            #print('Invalid ID')
            ids.append({'TaskID' : ""})
            
    #Create ID column
    df_id = pd.DataFrame(ids)
    df_id.index=df_day_temp.index
    df_day_temp2 = pd.concat([df_day_temp, df_id], axis=1)
    
    print(jiras)
    df_jira = pd.DataFrame(jiras)
    df_jira.index=df_day_temp2.index

    df_day = pd.concat([df_day_temp2, df_jira], axis=1)
    
    #Add 'TaskID' column if it does not exist already
    
    df_day_notask = df_day.loc[df_day['Task'] == 'Without task']
    df_day_tag = df_day.loc[df_day['TaskID'] != '']
    df_day_notag = df_day.loc[df_day['TaskID'] == '']
    
    print('Found ' + str(len(df_day)) + ' entries.')
        
    if(len(df_day_notask) > 0):
        print('Found ' + str(len(df_day_notask)) + ' entries without task.')
        print(df_day_notask.to_string())
        input()

    if(len(df_day_notag) > 0):
        print(len(df_day_notag))
        print('Found ' + str(len(df_day) - len(df_day_tag)) + ' entries without valid TaskID.')
        print(df_day_notag.to_string())
        input()
        
    
    #Create timesheet
    
    day_total = convert_delta_time(str(df_day_tag['Duration'].sum()))

    print("Day hours are: " + day_total['hours_string'] )
    print("Day minutes are: " + str(day_total['total_minutes']))
    
    #Get Unique TaskIDs
    taskIDs = df_day_tag.TaskID.unique().tolist()
    print("Unique taskIDs are:")
    print(taskIDs)
    descriptions=[]
    works_descriptions=[]
    minutes=[]
    #Iterate through task IDs to collate data
    for i in taskIDs:
        # For each task
        print("\n---------------------------------\n")
        print('Processing for task id ' + i)
        df_day_tag_sum = df_day_tag.loc[df_day_tag['TaskID'] == i]
        #print(df_day_tag_sum)
        taskIDs_tasks = df_day_tag_sum.Task.unique().tolist() #List of unique "Working Hours Software" Tasks
        taskIDs_works = df_day_tag_sum['Work unit description'].unique().tolist() #List of unique "Working Hours Software" Description
        #print(taskIDs_work)
        description=""
        works_description=""
        for j in taskIDs_tasks: # This collates the total time for each Task
            print('\tProcessing for task "' + str(j) +'"' )
            df_day_tag_sum_tasks = df_day_tag_sum.loc[df_day_tag_sum['Task'] == j]
            
            title = j
            #Determine if task if Jira or not
            if(len(j.split(':')[0].split('-')) == 2):
               if((j.split(':')[0].split('-'))[1].isdigit()):
                    title = j.split(':')[0]

            
            task_total = convert_delta_time(str(df_day_tag_sum_tasks['Duration'].sum()))
            description = description + title + '[' + str(task_total['hours_string']) + ']' + "\n"
            
        for j in taskIDs_works:
            print('\tProcessing work task" ' + str(j) +'"' )
            df_day_tag_sum_works = df_day_tag_sum.loc[df_day_tag_sum['Work unit description'] == j]

            title = j
            #Determine if task if Jira or not
            if(len(j.split(':')[0].split('-')) == 2):
               if((j.split(':')[0].split('-'))[1].isdigit()):
                    print("Jira detected")
                    title = j.split(':')[0]
            
            
            works_total = convert_delta_time(str(df_day_tag_sum_works['Duration'].sum()))
            works_description = works_description + str(title) + '[' + str(works_total['hours_string']) + ']' + "\n"
            
           
        descriptions.append(description)
        print("Descriptions for "+ i +":")
        print(descriptions)
        works_descriptions.append(works_description)
        print("Work Descriptions for "+ i +":")
        print(works_descriptions)
        taskid_total = convert_delta_time(str(df_day_tag_sum['Duration'].sum()))
        minutes.append(taskid_total['total_minutes'])
    
    df_timesheet = pd.DataFrame(list(zip(descriptions,minutes,works_descriptions)),index = taskIDs, columns =['Description','Duration','Work unit description'])
    print(df_day_tag.to_string())
    print(df_timesheet.to_string())
    
    #Get Unique JiraIDs
    jiraIDs = df_day_tag.JiraID.unique().tolist()
    if("" in jiraIDs):
        jiraIDs.remove("")
        
    print("Unique jiraIDs are:")
    print(jiraIDs)
    descriptions=[]
    works_descriptions=[]
    minutes=[]
    #Iterate through task IDs to collate data
    for i in jiraIDs:
        # For each task
        print("\n---------------------------------\n")
        print('Processing for task id ' + i)
        df_day_tag_sum = df_day_tag.loc[df_day_tag['JiraID'] == i]
        #print(df_day_tag_sum)
        jiraIDs_details = df_day_tag_sum['Work unit details'].unique().tolist() #List of unique "Working Hours Software" Description
        #print(taskIDs_work)
        description=""
        works_description=""
        for j in jiraIDs_details:
            print('\tProcessing jira task" ' + str(j) +'"' )
            df_day_tag_sum_works = df_day_tag_sum.loc[df_day_tag_sum['Work unit details'] == j]

            title = j
            
            works_total = convert_delta_time(str(df_day_tag_sum_works['Duration'].sum()))
            works_description = works_description + str(title) + '[' + str(works_total['hours_string']) + ']' + "\n"
            
        works_descriptions.append(works_description)
        print("Work Descriptions for "+ i +":")
        print(works_descriptions)
        jiraid_total = convert_delta_time(str(df_day_tag_sum['Duration'].sum()))
        minutes.append(jiraid_total['total_minutes'])
        
    df_timesheet_jira = pd.DataFrame(list(zip(minutes,works_descriptions)),index = jiraIDs, columns =['Duration','Details'])
    print(df_timesheet_jira.to_string())
        
    return df_timesheet,df_timesheet_jira
    
def convert_mins_to_hour_string(total):
    hours = math.floor(total/60)
    minutes = math.floor(total - hours * 60)
    return str(str(hours) + ":" + str(minutes))
    
def print_menu(date,week_num,start,end):       ## Your menu design here
 
    # Get week Number
    #year, week_num, day_of_week = date.isocalendar()
    #start = date - timedelta(days=date.weekday())
    #end = start + timedelta(days=6)
    print (30 * "-" , "MENU" , 30 * "-")
    #Determine Weeke number
    print (24 * "-" , "Date: " + date.strftime('%d/%m/%Y'), 24 * "-")
    print (10 * "-" , "Week Number is: " + str(week_num) , "-", start.strftime('%d/%m/%Y') , "-" , end.strftime('%d/%m/%Y') , 10 * "-")
    print ("1. Get task list")
    print ("2. Parse working hours")
    print ("3. Analyse Day Data")
    print ("4. Update actiTime")
    print ("5. Print week timesheet")
    print ("6. Set day")
    print ("7. Analyse Week Data")
    print ("8. Georgie")
    print ("x. Exit")
    print (67 * "-")
 

#################
#   Main Script #
#################



loop=True
start_up_tasks = True
start_up_hours = False

#Get the UID of the current user
uid = get_uid(user='rgray', password ='u6!S6aqWDRa94cs')

# Set date to be yesterday
date = datetime.now()
#date = (date -timedelta(1))


print("Hello")

while loop:          ## While loop which will keep going until loop = False
    #Get Week number
    year, week_num, day_of_week = date.isocalendar()
    start = date - timedelta(days=date.weekday())
    end = start + timedelta(days=6)
    
    date_list = []
    for i in range(7):
        date_list.append((start + timedelta(days=i)).strftime('%d/%m/%Y'))

    print_menu(date, week_num, start, end)    ## Displays menu
    
    if start_up_tasks == False or start_up_hours == False:
        choice = 99
    else:
        #choice = 3
        #loop = False
        choice = input("Enter your choice [1-8]: ")
    
    if choice=='1' or start_up_tasks == False:     
        print ("Getting tasks from server")
        ## You can add your code or functions here
        # Get a list of all tasks from server
        df_tasks = get_tasks(user='rgray', password ='u6!S6aqWDRa94cs')
        task_list_int = df_tasks['id'].tolist()
        task_list = [str(x) for x in task_list_int] # Convert to string
        print(df_tasks)
        start_up_tasks = True

    elif choice=='2' or start_up_hours ==False:
        print ("Reading tasks from working hours")
        #Read in time track data
        df_wh = read_workingHours('Timesheets/WorkingHours.csv')
        start_up_hours = True
    elif choice=='3':
        print ("Analyse day data")
        # Analyse the time track data
        df_day_timesheet = analyse_day(df=df_wh,day=date.strftime('%d/%m/%Y'),taskList=list(task_list),df_tasks=df_tasks)
        
    elif choice=='4':
        print ("Update actiTime")
        #Update actiTime with the data
        for i in range(7):
            analyse_date = start + timedelta(days=i)
            print("Processing " + analyse_date.strftime('%d/%m/%Y'))
            update_day(user = 'rgray', password = 'u6!S6aqWDRa94cs',timesheet = df_week_timesheet,user_id = uid, date = analyse_date)
    elif choice=='5':
        print ("Print timesheet")
        #Print timesheet
        print(df_day_timesheet.to_string())
        
    elif choice=='6':
        # Set date
        choice = input("Enter date (dd/mm/YYYY): ")
        try:
            date = datetime.strptime(choice, '%d/%m/%Y')
        except:
            print ("Date string '" + choice + "' is not in the valid format")
            
    elif choice=='7':
        print ("Analyse Week data")

        
        df_week_timesheet = None # Initialise the timesheet data frame
        df_week_timesheet_jira = None # Initialise the timesheet data frame
        
        #Get all Actitime data for the week.
        for i in range(7):
            #i=5
            analyse_date = start + timedelta(days=i)
            print("\n##################\nProcessing " + analyse_date.strftime('%d/%m/%Y'))
            df_day_timesheet_all = analyse_day(df=df_wh,day=analyse_date.strftime('%d/%m/%Y'),taskList=list(task_list),df_tasks=df_tasks)
            df_day_timesheet=df_day_timesheet_all[0]
            df_day_timesheet_jira=df_day_timesheet_all[1]
            
            column_name = analyse_date.strftime('%d/%m/%Y')
            #Calculate actiTime tasks
            print(df_day_timesheet.to_string())
            column_name = analyse_date.strftime('%d/%m/%Y')
            df_day_timesheet.rename(columns={'Duration': column_name, 'Description': column_name+"-Description",'Work unit description': column_name+"-WUDescription"}, inplace=True)
            
            #Add to weekly timesheet. Initialise variable if not.
            if df_week_timesheet is not None:
                df_week_timesheet=pd.concat([df_week_timesheet, df_day_timesheet], axis=1)
            else:
                df_week_timesheet=df_day_timesheet
                
            #Calculate Jira tasks
            print(df_day_timesheet_jira.to_string())
            df_day_timesheet_jira.rename(columns={'Duration': column_name, 'Details': column_name+"-Details"}, inplace=True)
            
            #Add to weekly timesheet. Initialise variable if not.
            if df_week_timesheet_jira is not None:
                df_week_timesheet_jira=pd.concat([df_week_timesheet_jira, df_day_timesheet_jira], axis=1)
            else:
                df_week_timesheet_jira=df_day_timesheet_jira
        
        #Calculate total hours
        df_week_mins = df_week_timesheet[date_list].sum()
        #print(str(convert_mins_to_hour_string(df_week_mins)))
        df_total_week_mins = df_week_mins.sum()
        
        #Calcualte summary column
        date_list.append("Total")
        df_week_timesheet.loc[:,'Total'] = df_week_timesheet.sum(numeric_only=True, axis=1)
        print(df_week_timesheet[date_list].to_string())
        df_week_timesheet_jira.loc[:,'Total'] = df_week_timesheet_jira.sum(numeric_only=True, axis=1)
        print(df_week_timesheet_jira[date_list].to_string())
        
        #Export
        df_week_timesheet_jira.to_csv('jira_timesheet.csv')

        print("Total week hours are "+ convert_mins_to_hour_string(df_total_week_mins))       
        
    elif choice=='8':
        gInt = int(input("Please enter your age:"))
        print ("Georgie is " + str(gInt) + "years old")
        ## You can add your code or functions here
        loop=False # This will make the while loop to end as not value of loop is set to False
        
    elif choice=='x':
        print ("Exit")
        ## You can add your code or functions here
        loop=False # This will make the while loop to end as not value of loop is set to False
        
    else:
        # Any integer inputs other than values 1-5 we print an error message
        print ("Wrong option selection.")
        
    start_up=False
        
