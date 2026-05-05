#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later

//Initialize MC procedures & functions

Function MC_init()
	SetDataFolder root:
	NewDataFolder/O/S MassClosure
	NewDataFolder/O input_data
	NewDataFolder/O data2use
	NewDataFolder/O results
	NewDataFolder/O/S variables
	
	//String/G PathToConcData="root:ExtData:PM:"//root:MassClosure:input_data:
	String/G PathToConcData="root:MassClosure:ExtData:PM:"//root:MassClosure:input_data:
	String/G PathToBCData="root:MassClosure:ExtData:BC:"
	String/G PathToBCData="root:MassClosure:ExtData:BC:"
	String/G Concinput_list="select"
	String/G BCConcinput_list="select"
	String/G NameOfPMConcWave="select"
	String/G NameOfPMDateWave="select"
	String/G NameOfBCConcWave="select"
	String/G NameOfBCDateWave="select"
	String/G ExtDataType_Str="select"
//	String/G Season2Use="all"
	String/G NameOfExtVar="select"
//	String/G ListOfGraph="select"
	String/G CBName="Spectral (default)"
	String/G CB_List="Spectral (default); Rainbow;SeaLandAndFire"
	String/G NameOfWave2Load=""
	String/G NameOfResFolder="Run"
	String/G ListOfGraph="select"
	String/G Graph2beControlled=""
	String/G CBName="Spectral (default)"
	String/G NameOfWave2Load=""
	String/G CB_List="Spectral (default);Rainbow;SeaLandAndFire"
	String/G NameOfCS2Load="CS"
	String/G ReweightResultFolder="select"
	String/G Threshold_mode="select"
		
	Variable/G ConcMinThreshold=0
	Variable/G ConcMaxThreshold=0
	Variable/G MinIndex=0
	Variable/G MaxIndex=0
	Variable/G ExtVarBool=0
	Variable/G TimeRef_Bool=0
	Variable/G MinExtVar=0
	Variable/G MaxExtVar=0
	Variable/G ZF_TabVal=0
	Variable/G MaxCSvalue=0
	Variable/G MinCSValue=0
	Variable/G CS_reverse=0
	
	NewDataFolder/O/S root:MassClosure:ExtData
	NewDataFolder/O/S variables
	String/G NameOfWSWave = "select"
	String/G NameOfWDWave = "select"
	String/G Windinput_list = "select"
	String/G WSunit = "select"
	Variable/G WSunitcoeff=1
	Variable/G WSminThreshold=0
	Variable/G Angular_res=0
	Variable/G Radial_res=0
	Variable/G MaxSpeed=0
	Variable/G SmthK1=0
	Variable/G SmthK2=0
	Variable/G RectanglePlot_Box=0
	Variable/G PolarPlot_Box=0
	Variable/G WDstd_Bool=0
	Variable/G WDstd_Thres=999
	Variable/G JP_filterVal=0
	String/G PathToWindData="root:MassClosure:input_data:"
	String/G WindA_list="select;NWR;SWIM;SWIM-2"
	String/G TypeOfWindA="select"
	String/G NameOfWSstdWave="select"
	String/G NameOfWDstdWave="select"
	Variable/G AnglebinWidth=30
	Variable/G ConcBinWidth=1
	Variable/G maxConc=30
	
	NewDataFolder/O/S root:MassClosure:variables


End Function

//Mass Closure Panel
Function OpenMassclosure_panel(ctrlName) : ButtonControl
	string ctrlName
	MC_init()
	dowindow MassClosurePanel
	if(V_flag==1)
		killwindow MassClosurePanel
	endif
	
	NewDataFolder/O/S root:MassClosure	//create this folder if it does not exits
	NewDataFolder/O/S root:MassClosure:Variables
	NewDataFolder/O/S root:MassClosure:ExtData
	NewDataFolder/O/S root:MassClosure:ExtData:PM
	NewDataFolder/O/S root:MassClosure:ExtData:BC
	NewDataFolder/O/S root:MassClosure:ExtData:Variables
	NewDataFolder/O/S root:MassClosure:Data2use
	
	newpanel/N=MassClosurePanel/W=(160,80,560,700)/K=1
	
//	GroupBox LoadDataBox,pos={4,5},size={395,135},title="Input Data",fSize=12,fColor=(52428,1,1),labelBack=(49151,65535,57456),frame=0,font="Arial"
	Button LoadPMDataButt, title="\\f01Load PM data", pos={10,7},fSize=14,size={110,25},font="Arial", fcolor=(16385,49025,65535), proc=LoadPMData
	Button ResetPMDataButt, title="\\f01Reset PM", pos={126,10},fSize=12,size={70,20},font="Arial", fcolor=(65535,49151,49151), proc=ResetLoadPMData
	Button LoadBCDataButt, title="\\f01Load BC data", pos={213,7},fSize=14,size={110,25},font="Arial", fcolor=(49151,49152,65535), proc=LoadBCData
	Button ResetBCDataButt, title="\\f01Reset BC", pos={325,10},fSize=12,size={70,20},font="Arial", fcolor=(65535,49151,49151), proc=ResetLoadBCData

	GroupBox InputDataBox,pos={2,35},size={395,235},title="Input Data",fSize=12,fColor=(52428,1,1),labelBack=(52428,52428,52428),frame=0,font="Arial"
	
	SVar/Z PathToConcData=root:MassClosure:variables:PathToConcData
	SetVariable Set_PathToConcData,title="Path to PM conc.",pos={9,53},size={323,19},value=PathToConcData,fSize=12,noedit=1,font="Arial"
	Button Set_PathToConcData_button,title="\\f01SET",pos={337,53},size={50,20},fSize=14,proc=Set_PathToPMConcData_proc,fColor=(39168,39168,39168),font="Arial"

//	PopupMenu ExtVar_list title="Mass data type",pos={86,88},value="select;"+ InputExtLists(),proc=ExtVar2Use_ZFproc, disable = 0, win=MassClosurePanel,fstyle=1,font="Arial"
	GroupBox InputPMDataBox,pos={5,70},size={390,70},title="PM data",fSize=12,fColor=(52428,1,1),labelBack=(16385,49025,65535),frame=0,font="Arial"
	PopupMenu ConcWave2use_list, fSize=12, pos={12,87}, size={100,20}, value = "select;" + Input_Concwaveselection(), title="Conc. wave", proc = PMConcWave2Use, disable = 0, win=MassClosurePanel,fstyle=1,font="Arial"
	PopupMenu DateWave2use_list, fSize=12,pos={157,87},size={100,20}, value = "select;" + Input_Concwaveselection(), title="Date wave", proc = PMDateWave2Use, disable = 0, win=MassClosurePanel,fstyle=1,font="Arial"
	PopupMenu ExtVar_list, fSize=12, pos={12,112}, size={100,20}, value = "select;Gravimetric;size dist.", title="\f01Data type", proc = ExtdataInput_proc, disable = 0, win=MassClosurePanel,fstyle=1,font="Arial"

	SVar/Z PathToBCData=root:MassClosure:variables:PathToBCData
	SetVariable Set_PathToBCData,title="Path to BC conc.",pos={10,145},size={323,19},value=PathToBCData,fSize=12,noedit=1,font="Arial"
	Button Set_PathToBCData_button,title="\\f01SET",pos={337,145},size={50,20},fSize=14,proc=Set_PathToBCData_proc,fColor=(39168,39168,39168),font="Arial"

	GroupBox InputBCDataBox,pos={5,165},size={390,49},title="BC data",fSize=12,fColor=(52428,1,1),labelBack=(61166,61166,61166),frame=0,font="Arial"
	PopupMenu BCConcWave2use_list, fSize=12, pos={16,188}, size={100,20}, value = "select;" + Input_BCwaveselection(), title="Conc. wave", proc = BCConcWave2Use, disable = 0, win=MassClosurePanel,fstyle=1,font="Arial"
	PopupMenu BCDateWave2use_list, fSize=12, pos={160,188}, size={100,20}, value = "select;" + Input_BCwaveselection(), title="Date wave", proc = BCDateWave2Use, disable = 0, win=MassClosurePanel,fstyle=1,font="Arial"
	Button NoBCData_button,title="\\f01No BC data",pos={320,188},size={70,20},fSize=11,proc=NoBCData_proc,fColor=(39168,39168,39168),font="Arial"

	GroupBox RefDateBox,pos={5,216},size={390,50},title="DateTime reference",fSize=12,fColor=(52428,1,1),labelBack=(49151,65535,49151),frame=0,font="Arial"
//	PopupMenu ACSMDateWave2use_list, fSize=14, pos={173,141}, size={100,20}, value = "select;" + Input_Concwaveselection(), title="ACSM datetime", proc = ACSMDateWave2Use, disable = 0, win=MassClosurePanel,fstyle=1,font="Arial"
	PopupMenu Thres_list title="DateTime ref. wave",value="select;ACSM;Hourly",pos={12,236},proc=DateTimeRef_proc,disable=0,font="Arial",fsize=12,fstyle=1
	Button PlotMassClosure_button,title="\\f01Plot",pos={334,238},size={50,20},fSize=14,proc=PlotMassClosure_proc,fColor=(39168,39168,39168),font="Arial"
	
//	NVar/Z ConcMinThreshold=root:MassClosure:variables:ConcMinThreshold
//	NVar/Z ConcMaxThreshold=root:MassClosure:variables:ConcMaxThreshold
//	SetVariable ConcMinThres_sel,fSize=14,pos={161,85},size={92,20},title="Min", value=ConcMinThreshold,disable = 0, proc=Specific_ConcMinThres_ZFproc,win=MassClosurePanel,font="Arial"
//	SetVariable ConcMaxThres_sel,fSize=14,pos={276,85},size={97,20},title="Max",value=ConcMaxThreshold, disable = 0, proc=Specific_ConcMaxThres_ZFproc,win=MassClosurePanel,font="Arial"

//	PopupMenu Season2use_list, fSize=14, pos={225,174}, size={100,20}, value = "all;each;DJF;MAM;JJA;SON", title="Season", proc = Season2Use_ZFproc, disable = 0, win=MassClosurePanel,font="Arial"
//	SVar/Z Season2use=root:MassClosure:variables:Season2use
//	Button Part_Button,pos={317,110},size={50,20},title="Part",fSize=14,proc=PartPanel_ZFproc,disable=0,font="Arial"
//	Button ExploreConc_butt,pos={157,174},size={55,20},fsize=12,font="Arial",title="Explore",fColor=(13056,13056,0), proc=ExploreConc_proc,disable=0
//	NVAR/Z MinIndex=root:MassClosure:variables:MinIndex
//	NVAR/Z MaxIndex=root:MassClosure:variables:MaxIndex
//	SVAR/Z NameOfConcWave=root:MassClosure:variables:NameOfConcWave

//	if (stringmatch(NameOfConcWave,"select") && !WaveExists(root:MassClosure:data2use:ConcWave))
//		Button Part_Button fColor=(16384,48896,65280)
//	elseif (stringmatch(NameOfConcWave,"select") && WaveExists(root:MassClosure:data2use:ConcWave))
//		wave ConcWave=root:MassClosure:data2use:ConcWave
//		if (MinIndex==0 && MaxIndex==(dimsize(ConcWave,0)-1))
//			Button Part_Button fColor=(16384,48896,65280)
//		else
//			Button Part_Button fColor=(13056,0,0)
//		endif
//	elseif (!stringmatch(NameOfConcWave,"select"))
//		wave ConcWave=root:ZeFir:data2use:ConcWave
//		if (MinIndex==0 && MaxIndex==(dimsize(ConcWave,0)-1))
//			Button Part_Button fColor=(16384,48896,65280)
//		else
//			Button Part_Button fColor=(13056,0,0)
//		endif
//	endif

	SetDataFolder root:ACMCC_Export:
	wave ACSM_time, OM, NO3, SO4, NH4, Cl, CE, numflag_OM,numflag_NO3,numflag_SO4,numflag_NH4,numflag_Cl
// add condition if CE_fphase exist	

// add selection de waves time et concentration comme dans Zefir

// add scale time function

// plot flag, no flag, CE, no CE vs external PM

End Function

Function LoadPMData(ctrlName) : ButtonControl
	string ctrlName
	
	SetDataFolder root:MassClosure:ExtData:PM
	Variable refNum
	String message = "Select one or more files"
	String outputPaths
	String fileFilters = "All Files:.*;"

	Open /D /R /MULT=1 /F=fileFilters /M=message refNum
	outputPaths = S_fileName
	
	Variable colPM
	
	// Ask user which column contains PM concentration
	colPM = 1           // default value
	Prompt colPM, "Column number containing PM concentration:"
	DoPrompt "PM Data Column Selection", colPM
	
	if (V_flag)
		Print "User cancelled"
		return 0
	endif
	
	if (strlen(outputPaths) == 0)
		Print "Cancelled"

	else
    
    Variable numFilesSelected = ItemsInList(outputPaths,"\r")
    Variable i,j, n
    
    String nameofPMfile, nameofPMwaves, Datefile
	Wave/Z Datetime_PM, PMx
    
//    if(waveexists(Datetime_PM)==1)
 //    	Duplicate/O Datetime_PM, Destwave2
//     	Duplicate/O PMx, Mx2
//     	Killwaves/Z Datetime_PM, PMx
//    Endif
    	
    
    for(i=0; i<numFilesSelected; i+=1)
        String path = StringFromList(i,outputPaths,"\r")
       	LoadWave/Q/A/O/J/D/K=1/L={0,1,0,0,1}/V={"\t"," $",0,0}/R={French,2,2,2,1,"DayOfMonth/Month/Year",40} path
    	wave wave0
    	For(j=0;j<numpnts(wave0);j+=1)
   			if(wave0[0] <= Datetime_PM[j])
   			Killwaves wave0
   			Else
       		concatenate/NP=0 {wave0}, Destwave
       		Killwaves wave0
			Endif
		EndFor
    endfor
   	
    if(waveexists(Datetime_PM)==1)
   		Duplicate/O Datetime_PM, Destwave2
   		Killwaves/Z Datetime_PM
     	concatenate/NP=0 {Destwave}, Destwave2
     	Rename Destwave2, Datetime_PM
     	n = numpnts(Destwave2)
//		print n
     	Killwaves/Z Destwave
    Else
   		Rename Destwave, Datetime_PM
   		n = numpnts(Destwave)
//		print n
//   		Killwaves/Z Destwave
    Endif
    
//    n = numpnts(Destwave)
//	print n

    for(i=0; i<numFilesSelected; i+=1)
        String path2 = StringFromList(i,outputPaths,"\r")
		LoadWave/Q/O/J/M/D/K=0/W/L={0,1,0,colPM,1}/V={"\t"," $",0,0} path2
		wave wave0
		Concatenate/NP=0 {wave0}, Mx
//		Rename Mx,PMx
		Killwaves wave0
	endfor
   	
    if(waveexists(PMx)==1)
    	Duplicate/O PMx, Mx2
    	Killwaves/Z PMx
     	concatenate/NP=0 {Mx}, Mx2
     	Rename Mx2, PMx
     	Killwaves/Z Mx
	//	Duplicate/O PMx, PM1
   //		Redimension/N=(dimsize(PMx,0),1) PM1  		

    Else
   		Rename Mx,PMx 
//		Duplicate PMx, PM1
 //  		Redimension/N=(dimsize(PMx,0),1) PM1 
    Endif

	
	Endif
	wave PMx
	Make/O/N=(n) PM1
	PM1[]=PMx[p][0]
   
	
End Function



Function LoadBCData(ctrlName) : ButtonControl
	string ctrlName
	
	SetDataFolder root:MassClosure:ExtData:BC
	Variable refNum
	String message = "Select one or more files"
	String outputPaths
	String fileFilters = "All Files:.*;"//.raw;"
 
	Open /D /R /MULT=1 /F=fileFilters /M=message refNum
	outputPaths = S_fileName
	
	Variable colBC
	
	// Ask user which column contains PM concentration
	colBC = 1           // default value
	Prompt colBC, "Column number containing BC6 concentration:"
	DoPrompt "BC6 Data Column Selection", colBC
	
	if (V_flag)
		Print "User cancelled"
		return 0
	endif
	
	if (strlen(outputPaths) == 0)
		Print "Cancelled"

	else
    
    Variable numFilesSelected = ItemsInList(outputPaths,"\r")
    Variable i
    
    String nameofPMfile, nameofPMwaves, Datefile
	Wave/Z Datetime_BC, BCx
   
    for(i=0; i<numFilesSelected; i+=1)
        String path = StringFromList(i,outputPaths,"\r")
      //print path
      //LoadWave/Q/O/J/M/D/K=0/L={0,0,0,3,0}/V={"\t"," $",0,0} 
//		LoadWave/Z/Q/A/O/J/D/K=1/L={0,1,0,0,1}/V={"\t"," $",0,0}/R={French,2,2,2,1,"DayOfMonth/Month/Year",40} path /Z flag not accepted in Igor 6
		LoadWave/Q/A/O/J/D/K=1/L={0,1,0,0,1}/V={"\t"," $",0,0}/R={French,2,2,2,1,"DayOfMonth/Month/Year",40} path
//      LoadWave/Q/A/J/V={"\t"," $",0,0}/L={0,0,0,1,1}/R={French,2,2,2,1,"Year-Month-DayOfMonth",40} path
       	wave wave0
       	concatenate/NP=0 {wave0}, Destwave
		Killwaves wave0
    endfor
   	
    if(waveexists(Datetime_BC)==1)
   		Duplicate/O Datetime_BC, Destwave2
   		Killwaves/Z Datetime_BC
     	concatenate/NP=0 {Destwave}, Destwave2
     	Rename Destwave2, Datetime_BC
     	Killwaves/Z Destwave
    Else
   		Rename Destwave, Datetime_BC
//   		Killwaves/Z Destwave
    Endif
    
    
    for(i=0; i<numFilesSelected; i+=1)
    	//print i, numFilesSelected
        String path2 = StringFromList(i,outputPaths,"\r")
       // print path2
		//LoadWave/Q/O/J/M/D/K=0/W/L={0,1,0,2,0} path2
		LoadWave/Q/O/J/D/K=1/L={0,1,0,colBC,1}/V={"\t"," $",0,0} path2
		//LoadWave/Q/O/J/M/D/K=1/W/L={0,1,0,colBC,1}/V={" "," $",0,0} path2
		wave wave0
		//print wave0[0][0]	
		Concatenate/NP=0 {wave0}, mBC
//		Rename wave0, mBC
		Killwaves/Z wave0
	endfor
   	
    if(waveexists(BCx)==1)
   		Duplicate/O BCx, mBC2
    	Killwaves/Z BCx
     	concatenate/NP=0 {mBC}, mBC2
     	Rename mBC2, BCx
     	Killwaves/Z mBC  
 	Else
 //   	Concatenate/NP=0 {wave0}, mBC
 		Rename mBC, BCx
 //		killwaves/Z matBC  		
    Endif
    
	Endif
	    
    wave BCx
	
	variable rows=dimsize(BCx,0)
	Make/O/N=(rows) BC6

	BC6[]=BCx[p]//[53]

	

	BC6[]=(BC6[p]==0) ? NaN : BC6[p]
	
	variable H=0.568182
	variable MAC=7.8
	
	duplicate/O BC6 eBC
	eBC=(BC6*7.77/1000)*H/MAC

End Function


Function ResetLoadPMData(ctrlName) : ButtonControl
	string ctrlName
	
	KillDataFolder root:MassClosure:ExtData:PM
	NewDataFolder root:MassClosure:ExtData:PM
//	KillDataFolder root:ExtData:BC

End Function

Function ResetLoadBCData(ctrlName) : ButtonControl
	string ctrlName
	
//	KillDataFolder root:ExtData:PM
	KillDataFolder root:MassClosure:ExtData:BC
	NewDataFolder root:MassClosure:ExtData:BC

End Function

Function ExtdataInput_proc(name,Num,Str) : PopupMenuControl
    String name
    Variable Num
    String Str

    SetDataFolder root:MassClosure
    
    SVAR PM_type
    PM_type = Str

    if (stringmatch(Str,"select"))
        DoAlert/T="WARNING" 0,"Please select a valid option"
        return 0
    endif

    NVAR ApplyPMCorrection

    Variable disableBoxes//, ApplyPMCorrection

    if (stringmatch(Str,"Gravimetric"))
        ApplyPMCorrection = 0 
        disableBoxes = 1
//	print disableBoxes
    elseif (stringmatch(Str,"Size distribution"))
        ApplyPMCorrection = 1
        disableBoxes = 0
 //   print disableBoxes
    endif

 //   CheckBox DiffusionButton, pos={190,134}, title="Diffusion cor.", disable=disableBoxes //
 //   CheckBox DoubleChargeButton,pos={280,135}, title="Double charge cor.", disable=disableBoxes
    CheckBox UsePMcorrection_CB, pos={157,114}, title="Density corr.", proc=density_comp_corr, disable=disableBoxes


//    UpdateMassClosure()

End

Function density_comp_corr()
	SetDataFolder root:massclosure:data2use
	wave PM_ugm3 = root:MassClosure:Extdata:PM:PM_ugm3
	wave eBC = root:MassClosure:Extdata:BC:eBC_ugm3
	Duplicate/O root:ACMCC_Export:OM, OM
	Duplicate/O root:ACMCC_Export:NH4, NH4
	Duplicate/O root:ACMCC_Export:NO3, NO3
	Duplicate/O root:ACMCC_Export:SO4, SO4

	variable dOM, dnh4no3, dnh42SO4, dBC, idex

	dOM = 1.2
	dnh42SO4 = 1.8
	dnh4no3 = 1.7
	dBC = 0.8


//Variable M_NO3, M_NH4, M_SO4, M_NH42SO4, M_NH4NO3

//M_NO3 = 62
//M_NH4 = 18
//M_SO4 = 96
//M_NH42SO4 = 132
//M_NH4NO3 = 80

	Make/O/D/N=(numpnts(OM)) NH42SO4, NH4NO3, NH4_mol_excess, dcorr, dcorr2, Total_Conc_corr_ugm3

	For (idex=0; idex<numpnts(OM); idex+=1)
		Make/O/D/N=(numpnts(OM)) NH42_mol_temp, SO4_mol_temp
		NH42_mol_temp = NH4[p]/18
		SO4_mol_temp = SO4[p]/96
		if(NH42_mol_temp[idex]/2 < SO4_mol_temp[idex])
		NH42SO4[idex] = 132*(NH42_mol_temp[idex]/2)
		Else
		NH42SO4[idex] = 132*(SO4_mol_temp[idex])
		NH4_mol_excess[idex] = NH42_mol_temp[idex] - 2*SO4_mol_temp[idex]
		Endif	
	EndFor

	For (idex=0; idex<numpnts(OM); idex+=1)
		Make/O/D/N=(numpnts(OM)) NO3_mol_temp
		NO3_mol_temp = NO3/62
		if(NH4_mol_excess[idex] < NO3_mol_temp[idex])
		NH4NO3[idex] = 80*(NH4_mol_excess[idex])
		Else
		NH4NO3[idex] = 80*(NO3_mol_temp[idex])
		Endif	
	EndFor

	dcorr = (dOM*OM[p]+dnh4no3*NH4NO3[p]+dnh42SO4*NH42SO4[p]+dBC*eBC[p])/(NH4NO3[p]+NH42SO4[p]+OM[p]+eBC[p])
	//dcorr2 = (dOM*OM[p]+1.75*(NO3[p]+SO4[p]+NH4[p])+dBC*BC[p])/(NO3[p]+SO4[p]+NH4[p]+OM[p]+BC[p])

	dcorr = dcorr[p] < 1 || dcorr[p] > 5 ? 1 : dcorr[p]

	Total_Conc_corr_ugm3 = dcorr[p]*PM_ugm3[p]

	Killwaves/Z OM, NH4, NO3, SO4, BC, SO4_mol_temp, NH4_mol_excess, NH42_mol_temp, NO3_mol_temp 

End Function

Function ACSMcorr_mass_smps()
	SetDataFolder root:ACMCC_Export:
	wave SMPS_conc_ugm3, OM, NH4, NO3, SO4, Cl, BC6

	variable dOM, dnh4no3, dnh42SO4, dBC, idex

	dOM = 1.2
	dnh42SO4 = 1.8
	dnh4no3 = 1.7
	dBC = 0.8


//Variable M_NO3, M_NH4, M_SO4, M_NH42SO4, M_NH4NO3

//M_NO3 = 62
//M_NH4 = 18
//M_SO4 = 96
//M_NH42SO4 = 132
//M_NH4NO3 = 80

	Make/O/D/N=(numpnts(OM)) NH42SO4, NH4NO3, NH4_mol_excess, dcorr, dcorr2, Total_Conc_corr_ugm3

	For (idex=0; idex<numpnts(OM); idex+=1)
		Make/O/D/N=(numpnts(OM)) NH42_mol_temp, SO4_mol_temp
		NH42_mol_temp = NH4[p]/18
		SO4_mol_temp = SO4[p]/96
		if(NH42_mol_temp[idex]/2 < SO4_mol_temp[idex])
		NH42SO4[idex] = 132*(NH42_mol_temp[idex]/2)
		Else
		NH42SO4[idex] = 132*(SO4_mol_temp[idex])
		NH4_mol_excess[idex] = NH42_mol_temp[idex] - 2*SO4_mol_temp[idex]
		Endif	
	EndFor

	For (idex=0; idex<numpnts(OM); idex+=1)
		Make/O/D/N=(numpnts(OM)) NO3_mol_temp
		NO3_mol_temp = NO3/62
		if(NH4_mol_excess[idex] < NO3_mol_temp[idex])
		NH4NO3[idex] = 80*(NH4_mol_excess[idex])
		Else
		NH4NO3[idex] = 80*(NO3_mol_temp[idex])
		Endif	
	EndFor

	dcorr = (dOM*OM[p]+dnh4no3*NH4NO3[p]+dnh42SO4*NH42SO4[p]+dBC*BC6[p])/(NH4NO3[p]+NH42SO4[p]+OM[p]+BC6[p])
	//dcorr2 = (dOM*OM[p]+1.75*(NO3[p]+SO4[p]+NH4[p])+dBC*BC[p])/(NO3[p]+SO4[p]+NH4[p]+OM[p]+BC[p])

	dcorr = dcorr[p] < 1 || dcorr[p] > 5 ? 1 : dcorr[p]

	Total_Conc_corr_ugm3 = dcorr[p]*SMPS_conc_ugm3[p]

	Killwaves/Z SO4_mol_temp, NH4_mol_excess, NH42_mol_temp, NO3_mol_temp 

End Function

Function Set_PathToPMConcData_proc(ctrlName) : ButtonControl
	String ctrlName
	SVAR PathToConcData=root:MassClosure:variables:PathToConcData
	PathToConcData = GetBrowserSelection(0)
	if(stringmatch(PathToConcData,"root"))
		PathToConcData="root:"
	endif
	SVAR/Z PathToExtConcWave=root:MassClosure:ExtData:variables:PathToExtConcWave
//	SVAR/Z PathToWindData=root:MassClosure:Wind_A:variables:PathToWindData
	PathToExtConcWave=PathToConcData
End Function


Function/S Input_Concwaveselection()
	String temp_folder
	temp_folder = getdatafolder(1)
	Svar Concinput_list=root:MassClosure:variables:concinput_list
	Svar PathToConcData=root:MassClosure:variables:PathToConcData
	setdatafolder PathToConcData
	Concinput_list = WaveList("*",";","")
	
	setdatafolder temp_folder
	return Concinput_list
end

Function PMConcWave2Use(name, num, str) : PopupMenuControl
	string name
	variable num
	string str
	string temp_folder
	temp_folder=getdatafolder(1)
	SVAR PathToConcData=root:MassClosure:variables:PathToConcData
	Svar NameOfPMConcWave=root:MassClosure:variables:NameOfPMConcWave
	NameOfPMConcWave=str
	setdatafolder root:
	wave/Z NameOfPMConcWave_w = $(NameOfPMConcWave)
	setdatafolder temp_folder
	NVar/Z ConcMinThreshold=root:MassClosure:variables:ConcMinThreshold
	NVar/Z ConcMaxThreshold=root:MassClosure:variables:ConcMaxThreshold
	
	if (stringmatch(NameOfPMConcWave,"select"))
		ConcMinThreshold=0
		ConcMaxThreshold=0
	else
		SVar PathToConcData=root:MassClosure:variables:PathToConcData
		NVar MaxIndex=root:MassClosure:variables:MaxIndex
		SVAR PathToConcData=root:MassClosure:variables:PathToConcData
		SetDataFolder $PathToConcData
		Duplicate/O $NameOfPMConcWave, root:MassClosure:data2use:PMConcWave
		SetDataFolder root:MassClosure:data2use:
		wave PMConcWave
		
		if (dimsize(PMConcWave,1)>1)
			variable column2use
			string prompt_str="Please choose the column number. 1st column is 0. Max is "
			prompt_str+=num2str(dimsize(PMConcWave,1)-1)
			prompt column2use, prompt_str
			doprompt "Matrix detected !!", column2use
			
			if (column2use>=dimsize(PMConcWave,1))
				do
					prompt_str="WRONG VALUE. 1st column is 0. Max is "
					prompt_str+=num2str(dimsize(PMConcWave,1)-1)
					prompt column2use, prompt_str
					doprompt "Matrix detected !!", column2use
				while (column2use>=dimsize(PMConcWave,1))
			endif
			
			duplicate/O/R=(0,dimsize(PMConcWave,0))(column2use,column2use) PMConcWave temp
			killwaves/Z PMConcWave
			duplicate/O temp PMConcWave
			killwaves/Z temp
		endif
		
		ConcMinThreshold=wavemin(PMConcWave)
		ConcMaxThreshold=wavemax(PMConcWave)
		MaxIndex=numpnts(PMConcWave)-1
	endif	
End Function

Function PMDateWave2Use(name, num, str) : PopupMenuControl
	string name
	variable num
	string str
	Svar NameOfPMDateWave=root:MassClosure:variables:NameOfPMDateWave
	SVAR PathToConcData=root:MassClosure:variables:PathToConcData
	SetDataFolder $PathToConcData
	NameOfPMDateWave=str
	if (!stringmatch(NameOfPMDateWave,"select"))
		Duplicate/O $NameOfPMDateWave, root:MassClosure:data2use:PMDateWave
	endif
End Function

Function Set_PathToBCData_proc(ctrlName) : ButtonControl
	String ctrlName
	SVAR PathToBCData=root:MassClosure:variables:PathToBCData
	PathToBCData = GetBrowserSelection(0)
	if(stringmatch(PathToBCData,"root"))
		PathToBCData="root:"
	endif
	SVAR/Z PathToBCConcData=root:MassClosure:ExtData:variables:PathToBCConcData
	PathToBCConcData=PathToBCData
End Function

Function/S Input_BCwaveselection()
	String temp_folder
	temp_folder = getdatafolder(1)
	Svar BCConcinput_list=root:MassClosure:variables:BCConcinput_list
	Svar PathToBCData=root:MassClosure:variables:PathToBCData
	setdatafolder PathToBCData
	BCConcinput_list = WaveList("*",";","")
	
	setdatafolder temp_folder
	return BCConcinput_list
end

Function BCDateWave2Use(name, num, str) : PopupMenuControl
	string name
	variable num
	string str
	Svar NameOfBCDateWave=root:MassClosure:variables:NameOfBCDateWave
	SVAR PathToBCData=root:MassClosure:variables:PathToBCData
	SetDataFolder $PathToBCData
	NameOfBCDateWave=str
	if (!stringmatch(NameOfBCDateWave,"select"))
		Duplicate/O $NameOfBCDateWave, root:MassClosure:data2use:BCDateWave
	endif
End Function

Function BCConcWave2Use(name, num, str) : PopupMenuControl
	string name
	variable num
	string str
	string temp_folder2
	temp_folder2=getdatafolder(1)
	SVAR PathToBCData=root:MassClosure:variables:PathToBCData
	Svar NameOfBCConcWave=root:MassClosure:variables:NameOfBCConcWave
	NameOfBCConcWave=str
	setdatafolder root:
	wave/Z NameOfBCConcWave_w = $(NameOfBCConcWave)
	setdatafolder temp_folder2
	NVar/Z ConcMinThreshold=root:MassClosure:variables:ConcMinThreshold
	NVar/Z ConcMaxThreshold=root:MassClosure:variables:ConcMaxThreshold
	
	if (stringmatch(NameOfBCConcWave,"select"))
		ConcMinThreshold=0
		ConcMaxThreshold=0
	else
		SVar PathToBCData=root:MassClosure:variables:PathToBCData
		NVar MaxIndex=root:MassClosure:variables:MaxIndex
		SVAR PathToBCData=root:MassClosure:variables:PathToBCData
		SetDataFolder $PathToBCData
		Duplicate/O $NameOfBCConcWave, root:MassClosure:data2use:BCConcWave
		SetDataFolder root:MassClosure:data2use:
		wave BCConcWave
		
		if (dimsize(BCConcWave,1)>1)
			variable column2use
			string prompt_str="Please choose the column number. 1st column is 0. Max is "
			prompt_str+=num2str(dimsize(BCConcWave,1)-1)
			prompt column2use, prompt_str
			doprompt "Matrix detected !!", column2use
			
			if (column2use>=dimsize(BCConcWave,1))
				do
					prompt_str="WRONG VALUE. 1st column is 0. Max is "
					prompt_str+=num2str(dimsize(BCConcWave,1)-1)
					prompt column2use, prompt_str
					doprompt "Matrix detected !!", column2use
				while (column2use>=dimsize(BCConcWave,1))
			endif
			
			duplicate/O/R=(0,dimsize(BCConcWave,0))(column2use,column2use) BCConcWave temp
			killwaves/Z BCConcWave
			duplicate/O temp BCConcWave
			killwaves/Z temp
		endif
		
		ConcMinThreshold=wavemin(BCConcWave)
		ConcMaxThreshold=wavemax(BCConcWave)
		MaxIndex=numpnts(BCConcWave)-1
	endif	
End Function



Function ExploreConc_proc(ctrlName) : ButtonControl
	string ctrlName
	SVAR/Z NameOfPMConcWave=root:MassClosure:variables:NameOfPMConcWave
	SVAR/Z NameOfPMDateWave=root:MassClosure:variables:NameOfPMDateWave
	SVAR/Z NameOfBCConcWave=root:MassClosure:variables:NameOfBCConcWave
	SVAR/Z NameOfBCDateWave=root:MassClosure:variables:NameOfBCDateWave
	
	if (stringmatch(NameOfPMConcWave,"select"))
		DoAlert/T="A problem is detected" 0,"please select first a concentration wave"
		Abort
	endif
	if (stringmatch(NameOfPMDateWave,"select"))
		DoAlert/T="A problem is detected" 0,"please select first a date/time wave"
		Abort
	endif
	if (stringmatch(NameOfBCConcWave,"select"))
		DoAlert/T="A problem is detected" 0,"please select first a concentration wave"
		Abort
	endif
	if (stringmatch(NameOfBCDateWave,"select"))
		DoAlert/T="A problem is detected" 0,"please select first a date/time wave"
		Abort
	endif
	
	SetDataFolder root:MassClosure:data2use
	Wave PMConcWave,PMDateWave, BCConcWave,BCDateWave
//	ExploreVar(DateWave,ConcWave)
End Function

Function NoBCData_proc(ctrlName) : ButtonControl
	String ctrlName
	
//	setdatafolder root:ExtData:BC
	setdatafolder root:MassClosure:ExtData:BC
	wave ACSM_time = root:ACMCC_Export:ACSM_time
	Make/O/D/N=(numpnts(ACSM_time)) eBC
	eBC = 0
	Duplicate/O ACSM_time, DateTime_BC
	
End function

Function DateTimeRef_proc(name, num, str) : PopupMenuControl
	string name
	variable num
	string str
	string temp_folder
	temp_folder=getdatafolder(1)
	setdatafolder root:MassClosure
	Svar Threshold_mode=root:MassClosure:variables:Threshold_mode
	Threshold_mode=str
	setdatafolder root:
	wave/Z Threshold_mode_w = $(Threshold_mode)
	setdatafolder temp_folder
	
	Nvar/Z TimeRef_Bool=root:MassClosure:variables:TimeRef_Bool
	
	if (stringmatch(Threshold_mode,"select"))
//		SetVariable SetPercentile,disable=1
//		SetVariable SetC_crit,disable=1
		DoAlert 0,"please select reference wave"
		Abort
	elseif (stringmatch(Threshold_mode,"Hourly"))
		CreateHourlyWave()
		TimeRef_Bool=0
	elseif (stringmatch(Threshold_mode,"ACSM"))
		TimeRef_Bool=1
	endif
	
//Both native and hourly will be created as the native will be used in the flagging
	
	Avg_eBC()
	Avg_PM()
	Avg_acsm()

	wave/Z PM1_1h, eBC_NRPM_1h, PM1_avg, eBC_NRPM_avg, W_coef
	
	if(TimeRef_Bool==0)
		wave/Z fit_eBC_NRPM_1h
		setdatafolder root:MassClosure
		//(160,80,560,360)
		Display/W=(10,290,390,620)/HOST=MassClosurePanel/N=MassClosureGraph eBC_NRPM_1h vs PM1_1h
		//Display eBC_NRPM_1h vs PM1_1h
		ModifyGraph marker(eBC_NRPM_1h)=19,useMrkStrokeRGB(eBC_NRPM_1h)=1
		CurveFit/Q/TBOX=(0x300)/M=2/W=0 line, eBC_NRPM_1h/X=PM1_1h/D
		Label left "NR-PM + eBC - μg m\\S-3";DelayUpdate
		Label bottom "External PM\\B1\\M - μg m\\S-3"
		SetAxis/A=2/N=1 left 0,*;DelayUpdate
		SetAxis/A/N=1 bottom 0,*;DelayUpdate
		ModifyGraph lsize(fit_eBC_NRPM_1h)=2,rgb(fit_eBC_NRPM_1h)=(0,0,0)
	Elseif(TimeRef_Bool==1)
		wave/Z fit_eBC_NRPM_avg
		setdatafolder root:MassClosure
		Display/W=(10,290,390,620)/HOST=MassClosurePanel/N=MassClosureGraph eBC_NRPM_avg vs PM1_avg	
		//Display eBC_NRPM_avg vs PM1_avg	
		ModifyGraph marker(eBC_NRPM_avg)=19,useMrkStrokeRGB(eBC_NRPM_avg)=1
		CurveFit/Q/TBOX=(0x300)/M=2/W=0 line, eBC_NRPM_avg/X=PM1_avg/D
		Label left "NR-PM + eBC - μg m\\S-3";DelayUpdate
		Label bottom "External PM\\B1\\M - μg m\\S-3";DelayUpdate
		SetAxis/A=2/N=1 left 0,*;DelayUpdate
		SetAxis/A/N=1 bottom 0,*;DelayUpdate
		ModifyGraph lsize(fit_eBC_NRPM_avg)=2,rgb(fit_eBC_NRPM_avg)=(0,0,0)
	Endif
	
	Duplicate/O eBC_NRPM_avg, ratio_eBCNRPM_PM
	ratio_eBCNRPM_PM = eBC_NRPM_avg/PM1_avg
	
End Function

Function CreateHourlyWave()

	wave DayTime=root:ACMCC_Export:ACSM_time
	
	Make/O/D/N=(1+(DayTime[numpnts(DayTime)-1]-DayTime[0])/3600) HourlyTime
	//HourlyTime[0]=DayTime[0]
	HourlyTime[0]=floor(DayTime[0]/3600)*3600
	variable i
	for(i=1;i<numpnts(HourlyTime);i+=1)
		HourlyTime[i]=HourlyTime[i-1]+3600
	endfor
	SetScale d 0, 0, "dat", HourlyTime
//	Variable startTime = floor(DayTime[0]/3600)*3600
//   	Variable endTime = DayTime[numpnts(DayTime)-1]
//	Variable nPoints = floor((endTime - startTime)/3600) + 1
//	
//	Make/O/D/N=(nPoints) HourlyTime
//	Wave HourlyTime
//    	
//    	HourlyTime = startTime + p*3600
//
//// 	HourlyTime[0]=DayTime[0]
////	variable i
////	for(i=1;i<numpnts(HourlyTime);i+=1)
////		HourlyTime[i]=HourlyTime[i-1]+3600
////	endfor
//	SetScale d 0, 0, "dat", HourlyTime
	
End Function

Function Avg_eBC()
	SetDataFolder root:MassClosure
	wave DateTime_BC=root:MassClosure:ExtData:BC:Datetime_BC
	wave eBC=root:MassClosure:ExtData:BC:eBC
	wave HourlyTime=root:MassClosure:HourlyTime
	wave ACSM_time = root:ACMCC_Export:ACSM_time
	Nvar/Z TimeRef_Bool=root:MassClosure:variables:TimeRef_Bool
	
//	print "eBC", TimeRef_Bool
	
	if(TimeRef_Bool==0)
		Std_Conc_avg(eBC, DateTime_BC,HourlyTime)
		wave/Z eBC_avg
		Duplicate/O eBC_avg, eBC_1h
		killwaves/Z eBC_avg
		Std_Conc_avg(eBC, DateTime_BC,ACSM_time)
	Elseif(TimeRef_Bool==1)
		Std_Conc_avg(eBC, DateTime_BC,ACSM_time)
	Endif
	
//	wave eBC_avg
//	eBC_avg=(numtype(eBC_avg[p]==2)) ? 0 : eBC_avg[p]
	
End Function


Function Avg_PM()
	SetDataFolder root:MassClosure
	wave Datetime_PM=root:MassClosure:ExtData:PM:Datetime_PM
	wave PM1=root:MassClosure:ExtData:PM:PM1
	wave HourlyTime=root:MassClosure:HourlyTime
	wave ACSM_time = root:ACMCC_Export:ACSM_time
	Nvar/Z TimeRef_Bool=root:MassClosure:variables:TimeRef_Bool

//	print "PM", TimeRef_Bool
	
	if(TimeRef_Bool==0)
		Std_Conc_avg(PM1, Datetime_PM,HourlyTime)
		wave/Z PM1_avg
		Duplicate/O PM1_avg, PM1_1h
		Std_Conc_avg(PM1, Datetime_PM,ACSM_time)
	Elseif(TimeRef_Bool==1)
		Std_Conc_avg(PM1, Datetime_PM,ACSM_time)
	Endif
	//Add condition for density correction for size distribution data
End Function

Function Avg_ACSM()
	SetDataFolder root:MassClosure
	wave OM = root:ACMCC_Export:OM
	wave SO4 = root:ACMCC_Export:SO4
	wave NO3 = root:ACMCC_Export:NO3
	wave NH4 = root:ACMCC_Export:NH4
	wave Cl = root:ACMCC_Export:Cl
	Duplicate/O OM, NR_PM
	NR_PM = Cl+OM+NO3+NH4+SO4
	wave HourlyTime//=root:HourlyTime
	wave ACSM_time = root:ACMCC_Export:ACSM_time
	Nvar/Z TimeRef_Bool=root:MassClosure:variables:TimeRef_Bool
//	print "ACSM", TimeRef_Bool

	if(TimeRef_Bool==0)
		Std_Conc_avg(NR_PM, ACSM_time,HourlyTime)
		wave/Z NR_PM_avg
		Duplicate/O NR_PM_avg, NR_PM_1h
		Duplicate/O OM, NR_PM_avg
		NR_PM_avg = Cl+OM+NO3+NH4+SO4
	Elseif(TimeRef_Bool==1)
		Duplicate/O NR_PM, NR_PM_avg
	Endif

	wave/z NR_PM_avg, eBC_avg
	Duplicate/O NR_PM_avg, eBC_NRPM_avg
	eBC_NRPM_avg = eBC_avg+NR_PM_avg

	wave/z NR_PM_1h, eBC_1h
	Duplicate/O NR_PM_1h, eBC_NRPM_1h
	eBC_NRPM_1h = eBC_1h+NR_PM_1h
		
	//Add condition for density correction for size distribution data
End Function

Function Std_Conc_avg(Conc_Wave, Date_Wave,Timeline)
	wave Conc_Wave,Date_Wave,Timeline
	
	duplicate/O Conc_wave temp_conc
	duplicate/O Date_Wave, temp_date
	
	temp_date[]=(numtype(temp_conc[p])==2) ? NaN : temp_date[p]
	
	WaveTransform zapNaNs temp_date
	WaveTransform zapNaNs temp_conc
	
	string ConcWaveName=NameOfWave(Conc_Wave)+"_avg"
	Make/O/N=(numpnts(Timeline)) temp_avg
	variable i,j,k
	for (i=0;i<numpnts(Timeline)-1;i+=1)
		j=BinarySearch(temp_date,Timeline[i])
		k=BinarySearch(temp_date,Timeline[i+1])
		if (j==k)
			temp_avg[i]=nan
			continue
		endif
		temp_avg[i]=mean(temp_conc,j,k-1)
	endfor
	temp_avg[numpnts(Timeline)-1]=NaN
	duplicate/O temp_avg $ConcWaveName
	KillWaves temp_avg,temp_conc,temp_date
End Function

Function PlotMassClosure_proc(ctrlName) : ButtonControl
	string ctrlName
	setdatafolder root:massclosure
	Nvar/Z TimeRef_Bool=root:MassClosure:variables:TimeRef_Bool
	wave PM1_avg, eBC_NRPM_avg, PM1_1h, eBC_NRPM_1h
	wave/Z W_coef
	
	if(TimeRef_Bool==0)
		Display/W=(10,290,390,620)/HOST=MassClosurePanel/N=MassClosureGraph eBC_NRPM_1h vs PM1_1h	
		CurveFit/Q/TBOX=(0x300)/M=2/W=0 line, eBC_NRPM_1h/X=PM1_1h/D
		Label left "NR-PM + eBC - μg m\\S-3";DelayUpdate
		Label bottom "External PM\\B1\\M - μg m\\S-3";DelayUpdate

	Elseif(TimeRef_Bool==1)
		Display/W=(10,290,390,620)/HOST=MassClosurePanel/N=MassClosureGraph eBC_NRPM_avg vs PM1_avg	
		CurveFit/Q/TBOX=(0x300)/M=2/W=0 line, eBC_NRPM_avg/X=PM1_avg/D
		Label left "NR-PM + eBC - μg m\\S-3";DelayUpdate
		Label bottom "External PM\\B1\\M - μg m\\S-3";DelayUpdate
	Endif
	
	
End Function


Function/S Input_Datatypewaveselection()
	String temp_folder
	temp_folder = getdatafolder(1)
	Svar Concinput_list=root:MassClosure:variables:concinput_list
	Svar PathToConcData=root:MassClosure:variables:PathToConcData
	setdatafolder PathToConcData
	Concinput_list = WaveList("*",";","")
	
	setdatafolder temp_folder
	return Concinput_list
end 

Function ScatterPlot() 
	Make/O/T/N=6 NameofSpecies = {"NR-PM","OM","NO3","SO4","NH4","Cl"}
	Edit NameofSpecies
	wave/T SerialNumber=root:SerialNumber
	variable i
	for(i=1;i<dimsize(SerialNumber,0);i+=1)
	SetDataFolder $("root:SN"+SerialNumber[i])
	
	Duplicate/O root:SN140113:OM_avg, OM_113
	Duplicate/O root:SN140113:NO3_avg, NO3_113
	Duplicate/O root:SN140113:SO4_avg, SO4_113
	Duplicate/O root:SN140113:NH4_avg, NH4_113
	Duplicate/O root:SN140113:Cl_avg, Cl_113
	Duplicate/O root:SN140113:NR_PM_avg, NRPM_113
	wave NR_PM_avg, OM_avg, NO3_avg,SO4_avg,Cl_avg,NH4_avg
	//first blank 7/11/2025 - 10h05 - 16h
	NR_PM_avg[106,112] = NaN
	OM_avg[106,112] = NaN 
	NO3_avg[106,112] = NaN
	SO4_avg[106,112] = NaN
	Cl_avg[106,112] = NaN
	NH4_avg[106,112] = NaN
	//second blank 20/11/2025 - 12h49 - 17h
	NR_PM_avg[420,426] = NaN
	OM_avg[420,426] = NaN 
	NO3_avg[420,426] = NaN
	SO4_avg[420,426] = NaN
	Cl_avg[420,426] = NaN
	NH4_avg[420,426] = NaN
	
	wave W_coef
	
	String Reg_slopes_SN = "SN"+SerialNumber[i]+"slopes"
	String Reg_PearsR_SN = "SN"+SerialNumber[i]+"PearsR"
	
	Make/O/D/N=6 Regression_slopes, regression_pearsonR
	CurveFit/Q/M=2/W=0 line, NR_PM_avg/X=NRPM_113/D
	Regression_slopes[0] = W_coef[2]
	regression_pearsonR[0] = V_Pr
	CurveFit/Q/M=2/W=0 line, OM_avg/X=OM_113/D
	Regression_slopes[1] = W_coef[2]
	regression_pearsonR[1] = V_Pr
	CurveFit/Q/M=2/W=0 line, NO3_avg/X=NO3_113/D
	Regression_slopes[2] = W_coef[2]
	regression_pearsonR[2] = V_Pr
	CurveFit/Q/M=2/W=0 line, SO4_avg/X=SO4_113/D
	Regression_slopes[3] = W_coef[2]
	regression_pearsonR[3] = V_Pr
	CurveFit/Q/M=2/W=0 line, Cl_avg/X=Cl_113/D
	Regression_slopes[4] = W_coef[2]
	regression_pearsonR[4] = V_Pr
	CurveFit/Q/M=2/W=0 line, NH4_avg/X=NH4_113/D
	Regression_slopes[5] = W_coef[2]
	regression_pearsonR[5] = V_Pr
	
	Duplicate/O Regression_slopes, $Reg_slopes_SN
	Duplicate/O regression_pearsonR, $Reg_PearsR_SN
	Appendtotable $Reg_slopes_SN, $Reg_PearsR_SN
	Killwaves OM_113, NO3_113, SO4_113, NH4_113, Cl_113, NRPM_113, Regression_slopes, regression_pearsonR
	EndFor
	
End Function



Function Online_KillListofWaves(ListofWave)
	string ListOfWave
	variable i
	Variable numFilesSelected = ItemsInList(ListOfWave, ";")
	for(i=0; i<numFilesSelected; i+=1)
		String Wave2Kill = StringFromList(i, ListOfWave, ";")
		KillWaves/Z $Wave2Kill	
	endfor
End Function

Function/S Online_ExtractDateInfo(dt,dateinfo)
	variable dt					// Input date/time value
 	string dateinfo
 	
	String shortDateStr = Secs2Date(dt, -1)		// <day-of-month>/<month>/<year> (<day of week>)
 
	Variable dayOfMonth, month, year, dayOfWeek
	sscanf shortDateStr, "%d/%d/%d (%d)", dayOfMonth, month, year, dayOfWeek
 	
 	string year_txt, month_txt, dayOfMonth_txt
 	
 	if (stringmatch(dateinfo,"year"))
 		year_txt=num2str(year)
 		return year_txt
 	elseif (stringmatch(dateinfo,"month"))
 		if (month<10)
 			month_txt="0"+num2str(month)
 		else
 			month_txt=num2str(month)
 		endif
 		return month_txt
 	elseif (stringmatch(dateinfo,"dayOfMonth"))
 		if (dayOfMonth < 10)
 			dayOfMonth_txt="0"+num2str(dayOfMonth)
 		else
 			dayOfMonth_txt=num2str(dayOfMonth)
 		endif
 		return dayOfMonth_txt
 	endif
End

Function/S Online_ExtractTimeInfo(dt,timeinfo)
	variable dt
	string timeinfo
	
	variable time
	string hour, minute, second
	
	if (stringmatch(timeinfo,"hour"))
		time = mod(dt,24*60*60)
		if (trunc(time/3600) < 10)
			hour="0"+num2str(trunc(time/3600))
		else
			hour=num2str(trunc(time/3600))
		endif
 		return hour
 	elseif (stringmatch(timeinfo,"minute"))
 		time = mod(dt,3600)
 		if (trunc(time/60) < 10)
 			minute="0"+num2str(trunc(time/60))
 		else
 			minute=num2str(trunc(time/60))
 		endif
 		return minute
 	elseif (stringmatch(timeinfo,"second"))
 		time = mod(dt,60)
 		if (trunc(time) < 10)
 			second="0"+num2str(trunc(time))
 		else
 			second=num2str(trunc(time))
 		endif
 		return second
 	endif
	
End Function