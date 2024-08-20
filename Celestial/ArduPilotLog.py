import pandas as pd
import os
import geopy.distance
import matplotlib.pyplot as plt
import math

def percentile_calc(dataList,percentile=50):
    dataList.sort()
    ep_index=math.ceil((len(dataList)-1)*(percentile/100))
    print(str(ep_index)+"/"+str(len(dataList))+":"+str(dataList[ep_index]))
    print(str(sum(i <= dataList[ep_index] for i in dataList))+"<=>"+str(sum(i > dataList[ep_index] for i in dataList)))
    ep = dataList[ep_index]
    return ep


def analyse_distance(df,timeStart,timeEnd,coords_0_in=None,height_0_in=None,gnssOutput=None):
    dfSub = df[(df["TimeUS"] > timeStart) & (df["TimeUS"] < timeEnd) & (df["Status"] == 3) ]
    print("Found " + str(len(dfSub)) + " values."+ str(timeStart) + "us to " + str(timeEnd) + "us")
    
    diff=[]
    ref=[]
    xdiff=[]
    ydiff=[]
    ref_height=[]
    
    coords_median = (dfSub['Lat'].median(),dfSub['Lng'].median()) #Mean reference point
    height_median = dfSub['Alt'].median()
    
    # Set reference lat, long , height
    if coords_0_in == None:    
        coords_0 = coords_median
        print("Using mean data point as horizontal reference point")
    else:
        coords_0 = coords_0_in
        print("Using input value as horizontal reference point")
        
    if height_0_in == None:    
        height_0 = height_median
        print("Using mean data point as vertical reference point")
    else:
        height_0 = height_0_in
        print("Using input value as vertical reference point")

    #print(coords_0)
    #print(dfSub['Lat'].min(),dfSub['Lng'].max())
        
    print("Analysing data points ...")
    for i in range(0, (dfSub.shape[0])):
    #for index, row in df.iterrows():
        #print(i,df.shape[0]-1)
        coords_1 = (dfSub.iloc[i]['Lat'],dfSub.iloc[i]['Lng'])
        #coords_1 = 1
        if i < (dfSub.shape[0]-1):
            coords_2 = (dfSub.iloc[i+1]["Lat"], dfSub.iloc[i+1]["Lng"])
            #coords_2 = 2
        else:
            coords_2 = coords_1
        diff.append(geopy.distance.geodesic(coords_1,coords_2).m) # Distance from one point to the next
        ref.append(geopy.distance.geodesic(coords_1,coords_0).m) # Total distance from reference point
        
        ref_height.append(abs(dfSub.iloc[i]['Alt'] - height_0)) # Height distance from reference point
        
        #Calculate hte X,Y distance to reference point
        coords_0x=(coords_0[0],coords_1[1])
        coords_0y=(coords_1[0],coords_0[1])
        if coords_0[0]<coords_1[0]:
            xsign=1
        else:
            xsign=-1
        #print("XDIFF: " + str(coords_1) + " to " + str(coords_0x))
        xdiff.append((geopy.distance.geodesic(coords_1,coords_0x).m)*xsign)
        if coords_0[1]<coords_1[1]:
            ysign=1
        else:
            ysign=-1
        #print("YDIFF: " + str(coords_1) + " to " + str(coords_0y))
        ydiff.append((geopy.distance.geodesic(coords_1,coords_0y).m)*ysign)
        #print (i,coords_1,coords_2,geopy.distance.geodesic(coords_1,coords_2).m)
        
    dfSub['diff'] = diff
    dfSub['ref'] = ref
    dfSub['xdiff'] = xdiff
    dfSub['ydiff'] = ydiff
    dfSub['ref_height'] = ref_height
    
    #Calculate the HEP and CEP values
    ep_percentiles=[50,90,99]
    hep=[]
    cep=[]
    for k in range(0, len(ep_percentiles)):
        print(k)
        hep.append((round((percentile_calc(ref_height,ep_percentiles[k])),2)))
        cep.append((round((percentile_calc(ref,ep_percentiles[k])),2)))
        
    fig, axs = plt.subplots(2, 3)
    #axs[0, 0].plot(dfSub['Lat'], dfSub['Lng'])
    #axs[0, 0].set_title('Latitude vs Longitude')
    #axs[0, 0].set(xlabel='Lat', ylabel='Lng')
    axs[0, 1].plot(dfSub['TimeUS'], dfSub['ref'], 'tab:orange')
    axs[0, 1].set_title('Distance from Ref')
    axs[0, 1].set(xlabel='Time (us)', ylabel='Distance (m)')
    
    axs[1, 1].plot(dfSub['TimeUS'], dfSub['diff'], 'tab:red')
    axs[1, 1].set_title('Difference between points vs time')
    axs[1, 1].set(xlabel='Time (us)', ylabel='Distance (m)')
    
    axs[1, 0].plot(dfSub['TimeUS'], dfSub['Alt']-height_0, 'tab:blue')
    axs[1, 0].plot([dfSub['TimeUS'].min(),dfSub['TimeUS'].max()], [0,0], 'tab:grey')
    for k in range(0,len(ep_percentiles)):
        axs[1, 0].plot([dfSub['TimeUS'].min(),dfSub['TimeUS'].max()], [hep[k],hep[k]], 'tab:red', label="HEP"+str(ep_percentiles[k])+"%="+str(hep[k])+"m")
        axs[1, 0].plot([dfSub['TimeUS'].min(),dfSub['TimeUS'].max()], [-hep[k],-hep[k]], 'tab:red')
    axs[1, 0].set_title('Height')
    axs[1, 0].set(xlabel='Time (us)', ylabel='Height (m)')
    axs[1, 0].legend(loc='upper left')
    
    axs[1, 2].plot(dfSub['TimeUS'], dfSub['NSats'], 'tab:red')
    axs[1, 2].set_title('Satelite Count')
    axs[1, 2].set(xlabel='Time (us)', ylabel='Height (m)')
    
    axs[0, 2].plot(dfSub['TimeUS'], dfSub['HDop'], 'tab:red')
    axs[0, 2].set_title('Horizontal DOP')
    axs[0, 2].set(xlabel='Time (us)', ylabel='DOP')
    
    axs[0, 0].plot(dfSub['xdiff'], dfSub['ydiff'], 'tab:red')
    axs[0, 0].set_title('Reference distance')
    axs[0, 0].set(xlabel='Distance (m)', ylabel='Distance (m)')
    for k in range(0,len(ep_percentiles)):
        circle=plt.Circle((0, 0),cep[k], color='b', fill=False, label="CEP"+str(ep_percentiles[k])+"%="+str(cep[k])+"m")
        axs[0, 0].add_patch(circle)
    axs[0, 0].legend(loc='upper left')
    
    #plt.title('Title of the plot')
    plt.subplots_adjust(left=0.1, bottom=0.1, right=0.9, 
                    top=0.9, wspace=0.4,hspace=0.4)
    
    
    #plt.text(10, 60, 'Parabola $Y = x^2$', fontsize = 22) 

    plt.show()
    #plt.savefig(gnssOutput)

    return None

#Main Script

logFilePath=r"C:\\Users\\RichardGray\\OneDrive - STL Tech Limited\\Documents\\Mission Planner\\logs\\QUADROTOR\\1\\"
logFile="2023-11-23 08-25-58.log"
logFileSplit=os.path.splitext(logFile)

#For GPS
logType=["GPS","IMU"]
logTypeHeaders=[["TimeUS","I","Status","GMS","GWk","NSats","HDop","Lat","Lng","Alt","Spd","GCrs","VZ","Yaw","U"],
                ["TimeUS","I","GyrX","GyrY","GyrZ","Accx","Accy","Accz","EG","EA","T","GH","AH","GHz","AHZ"]]

df={}
for i in range (0,len(logType)-1):
    logFileType=logFileSplit[0]+"_"+logType[i]+logFileSplit[1]
    gnssOutputFile=logFileSplit[0]+"_"+logType[i]+".png"
    print(logFileType)
    try:
        os.remove(logFileType)
        #print("Removed")
    except OSError:
        #print("Not found")
        pass

    with open ((logFilePath+logFile),'r') as firstfile, open(logFilePath+logFileType,'a') as secondfile:
        print(logFileType)
        #input()
        for line in firstfile:
            if line.startswith(logType[i]):
                secondfile.write(line)
                #print(line)
                

    df[i] = pd.read_csv((logFilePath+logFileType),names=logTypeHeaders[i], header=None)
    #print(1)

#For each section period analyse the file from the centre point
#Analyse Each segment
testTime=[(60000000,900000000),
          (1500000000,5079543272)]

for i in range(len(testTime)):
    analyse_distance(df=df[0],timeStart=testTime[i][0],timeEnd=testTime[i][1],gnssOutput=logFilePath+gnssOutputFile)
    #analyse_distance(df=df[0])


