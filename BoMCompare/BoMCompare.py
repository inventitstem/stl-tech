import os.path
import pandas as pd
#from pandas import read_excel
from os.path import exists

import tkinter
from tkinter import filedialog


def expandBom (filePath,bomid):
    df = pd.read_excel (filePath,sheet_name='STL BoM')   #read the csv file (put 'r' before the path string to address any special characters in the path, such as '\'). Don't forget to put the file name at the end of the path + ".csv"
    df = df.reset_index()  # make sure indexes pair with number of rows

    #Expand each Bom
    #Find the header column row
    headerSearchTerm="Designator"
    header_row = df.loc[df.isin([headerSearchTerm]).any(axis=1)].index.tolist()[0]
    #Assign names to columns
    columnList=[]
    for i in range(len(df.columns)):
        columnList.append(df.iloc[header_row,i])
    df.columns=columnList
    #df_bom1.loc[df_bom1.isin([headerSearchTerm]).any(axis=1)]

    data=[]
    dataRange = len(df.index)
    for i in range(header_row+1,dataRange):
        #print(i)
        #print(df.loc[i]['Designator'])
        if pd.isna(df.iloc[i]['Designator']) == False:
            designators = df.loc[i]['Designator'].split(',')
            #print(designators)
            for x in range(len(designators)):
                #if designators[x].strip() == "R1":
                    #print(designators[x].strip() + ":" + str(df.loc[i]['Manufacturer']) + ":" + str(df.loc[i]['Manufacturer PN']))
                dictionary = {"Designator":designators[x].strip(), 'Manufacturer_'+str(bomid): str(df.loc[i]['Manufacturer']),'Manufacturer PN_'+str(bomid):str(df.loc[i]['Manufacturer PN']),'Description PN_'+str(bomid):str(df.loc[i]['Description']).replace(",","")}
                data.append(dictionary)    

    df = pd.DataFrame(data)
    df = df.set_index('Designator')
    return df

#################
#   Main module #
#################


#tkinter.Tk().withdraw() # prevents an empty tkinter window from appearing

#bom1Path = filedialog.askopenfilename()
#bom1Path=bom1Path.replace('/','//')
#bom2Path = 'r'+ filedialog.askopenfilename()

#bom1Path = r'
bom1Path = r"C:\Users\RichardGray\OneDrive - STL Tech Limited\Documents\Scratch\Optics Board v6\QLM-4039-25000.B1.V5.0 Optics Board.xlsx"
bom2Path = r"C:\Users\RichardGray\OneDrive - STL Tech Limited\Documents\Scratch\Optics Board v6\QLM-4039-25000.B1.V6.0_BOM.xlsx"

df_bom1 = expandBom(bom1Path,1) # Get expanded BoM
df_bom2 = expandBom(bom2Path,2) #Get expanded BoM

#print(df_bom1)
#print(df_bom2)

df_combined = pd.concat([df_bom1,df_bom2], axis=1) # Combine BoMs based on index
df_combined = df_combined.reset_index() # Revert index

#print(df_combined)

dataRange = len(df_combined.index)
for i in range(dataRange):
    #print(i)
    if pd.isna(df_combined.loc[i]['Manufacturer_2']) and pd.isna(df_combined.loc[i]['Manufacturer PN_2']):
        print(df_combined.loc[i]['Designator'] + "\t,REMOVED,\tMfr: " + df_combined.loc[i]['Manufacturer_1'] + " Pn: " + str(df_combined.loc[i]['Manufacturer PN_1']))
    elif pd.isna(df_combined.loc[i]['Manufacturer_1']) and pd.isna(df_combined.loc[i]['Manufacturer PN_1']):
        print(df_combined.loc[i]['Designator'] + "\t,ADDED,\tMfr: " + df_combined.loc[i]['Manufacturer_2'] + " Pn: " + str(df_combined.loc[i]['Manufacturer PN_2']))
    else:
        if df_combined.loc[i]['Manufacturer_1'].strip() != df_combined.loc[i]['Manufacturer_2'].strip():
            print(df_combined.loc[i]['Designator'] + "\t,CHANGED_MAN,\t " + str(df_combined.loc[i]['Manufacturer_1']) + " > " + str(df_combined.loc[i]['Manufacturer_2']))
        if df_combined.loc[i]['Manufacturer PN_1'].strip() != df_combined.loc[i]['Manufacturer PN_2'].strip():
            print(df_combined.loc[i]['Designator'] + "\t,CHANGED_PN,\t " + str(df_combined.loc[i]['Manufacturer PN_1']) + " > " + str(df_combined.loc[i]['Manufacturer PN_2']))
        if df_combined.loc[i]['Description PN_1'].strip() != df_combined.loc[i]['Description PN_2'].strip():
            print(df_combined.loc[i]['Designator'] + "\t,CHANGED_DES,\t " + str(df_combined.loc[i]['Description PN_1']) + " > " + str(df_combined.loc[i]['Description PN_2']))
            #print("Hello")
        #else:
            #print(df_combined.loc[i]['Designator'] + "\t,UNCLASSIFED,\t" + str(df_combined.loc[i]['Manufacturer_1']) + ":" + str(df_combined.loc[i]['Manufacturer PN_1']) + str(df_combined.loc[i]['Manufacturer_2']) + ":" + str(df_combined.loc[i]['Manufacturer PN_2']))

