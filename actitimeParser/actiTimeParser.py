import pandas as pd

pd=pd.read_csv("C:/Users/RichardGray/OneDrive - STL Tech Limited/Company Docs/Actitime Export and Catagorisation of tasks.csv")

count=0
new_data=[]
for i in range(len(pd)):
    if(pd.loc[i,'User'] == 'Parks, Peter'):
        print ("#############")
        #print (pd.loc[i,'Comments'])
        entries = str(pd.loc[i,'Comments']).split('\n')
        major_count=count
        for j in range(len(entries)):
            
            if entries[j] != '':
                row_data=pd.loc[i].to_dict()
                if len(entries) > 1:
                    
                    print (entries[j])
                   
                    new_comment = str(major_count) + " : " + entries[j] 
                    row_data['Comments'] = new_comment
                    
                    if j > 0:
                        row_data['Spent Time'] = ''
                           
                new_data.append(row_data)
                count=count+1
        

df = pd.from_dict(new_data)
df.head

df.to_csv("C:/Users/RichardGray/OneDrive - STL Tech Limited/Company Docs/test.csv")
