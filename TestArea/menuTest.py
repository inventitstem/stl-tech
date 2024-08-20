# Import module
import tkinter as tk
from tkinter import ttk
import pandas as pd
from functools import partial
import os.path

accountsTreeFilePath = r"C:\Users\RichardGray\OneDrive\Finance\GNU Cash\House Finance\Outputs\account_tree.csv"

accountsTreeUpdatedFilePath = r"account_tree_updated.csv"

#Load updated file if exists
if os.path.isfile(accountsTreeUpdatedFilePath):
    print("Using updated data")
    df_Acc = pd.read_csv(accountsTreeUpdatedFilePath)   #read the csv file (put 'r' before the path string to address any special characters in the path, such as '\'). Don't forget to put the file name at the end of the path + ".csv"
    #df_Acc = df_Acc.reset_index()  # make sure indexes pair with number of rows
else:
    print("Can't find updated data. Using raw data")
    df_Acc = pd.read_csv(accountsTreeFilePath)   #read the csv file (put 'r' before the path string to address any special characters in the path, such as '\'). Don't forget to put the file name at the end of the path + ".csv"
    df_Acc = df_Acc.reset_index()  # make sure indexes pair with number of rows 
    df_Acc['group'] = ''
    df_Acc['groupType'] = ''

#Populate dependencies
df_Acc['parent'] = ''
dataRange = len(df_Acc.index)

for i in range(dataRange):
    #print(df_Acc.iloc[i]['full_name'])
    account_names=df_Acc.iloc[i]['full_name'].split(':')
    if len(account_names) == 1:
        df_Acc.loc[i,'parent']=''
    else:
        df_Acc.loc[i,'parent']=account_names[len(account_names)-2]


# Create object
root = tk.Tk()

# Adjust size
frame = tk.Frame(width="600",height="800" )
frame.pack()

#Add scroll bar
#scrollbar = ttk.Scrollbar(root, orient='vertical',command=frame.yview)
#scrollbar.grid(row=0, column=1, sticky='ns')
#root['yscrollcommand'] = scrollbar.set
canvas=tk.Canvas(frame,bg='#FFFFFF',width=300,height=300,scrollregion=(0,0,500,500))
vbar=tk.Scrollbar(frame,orient='vertical')
vbar.grid(sticky='E')
vbar.config(command=canvas.yview)
canvas.config(width=300,height=300)
canvas.config(yscrollcommand=vbar.set)
canvas.grid(sticky='W')
	

# Dropdown menu options
options = [
	"Food",
        "Other"
]

types = [
    "None",
    "Current Account",
    "Savings Account",
    "Receivable",
    "Liability",
    "Regular Income",
    "Regular Expenses Commited",
    "Regular Expenses Non-Commited",
    "Non-Regular Income",
    "Non-regular Expenses"
    ]


SelectString = "Please Select"

def ok(value,index):
    print(index)
    group=value.get()
    print("Group is :" + group)# + " Index: " +index)
    df_Acc.loc[index,'group'] = group

def update(valuesOptions,valuesType):
    #print("Hello")
    for i in range(len(valuesOptions)):  
        group=valuesOptions[i].get()
        if df_Acc.loc[i,'group'] != group and group != SelectString:
            print("Updating: " + df_Acc.loc[i,'name'] + "-> Group:" + group)# + " Index: " +index)
            df_Acc.loc[i,'group'] = group
    for i in range(len(valuesType)):  
        groupType=valuesType[i].get()
        if df_Acc.loc[i,'groupType'] != groupType and groupType != SelectString:
            print("Updating: " + df_Acc.loc[i,'name'] + "-> Group Type:" + groupType)# + " Index: " +index)
            df_Acc.loc[i,'groupType'] = groupType


#clicked=[tk.StringVar()]*dataRange
label={}
clickedOptions={}
clickedType={}
dropGroup={}
dropType={}
button={}
           
exit_button = tk.Button(canvas, text="Exit", command=root.destroy)
exit_button.grid(row=0, column=5)

exit_button = tk.Button(canvas, text="Update", command=partial(update,clickedOptions,clickedType))
exit_button.grid(row=0, column=6)

for index in range(dataRange):

    #print(index)
    
    # datatype of menu text
    clickedOptions[index] = tk.StringVar()
    clickedType[index] = tk.StringVar()
    #print(clicked[index])

    # Create Label
    accountNameLabel=''
    for i in range(len(df_Acc.iloc[index]['full_name'].split(':'))):
        accountNameLabel = accountNameLabel + "->"
    accountNameLabel = accountNameLabel + df_Acc.iloc[index]['name']
    label[index] = tk.Label( frame , text = accountNameLabel)
    #label.pack(padx=5, pady=15, side=tk.LEFT)
    label[index].grid(sticky='W', row=(index+1), column=0)

    # initial menu text
    if df_Acc.iloc[index]['group'] not in options:
        clickedOptions[index].set( SelectString )
    else:
        clickedOptions[index].set( df_Acc.iloc[index]['group'])
        
    if df_Acc.iloc[index]['groupType'] not in types:
        clickedType[index].set( SelectString )
    else:
        clickedType[index].set( df_Acc.iloc[index]['groupType'])

    # Create Dropdown menu for Options
    dropGroup[index] = tk.OptionMenu( canvas , clickedOptions[index] , *options )
    #drop.pack(padx=5, pady=15, side=tk.LEFT)
    dropGroup[index].grid(row=(index+1), column=1)

    # Create Dropdown menu for Type
    dropType[index] = tk.OptionMenu( canvas , clickedType[index] , *types )
    #drop.pack(padx=5, pady=15, side=tk.LEFT)
    dropType[index].grid(row=(index+1), column=2)

    # Create button, it will change label text
    #button[index] = tk.Button( root , text = "Update")
    #button[index]["command"] = partial(ok,clickedOptions[index],index)
    #button.pack(padx=5, pady=15, side=tk.LEFT)
    #button[index].grid(row=(index+1), column=3)

# Execute tkinter
root.mainloop()

df_Acc.to_csv('account_tree_updated.csv')
