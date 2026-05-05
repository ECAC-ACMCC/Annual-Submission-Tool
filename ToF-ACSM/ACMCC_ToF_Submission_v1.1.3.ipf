#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

StrConstant ACMCC_Export_version="1.1.3"


// History :
// ---------
//   v1.1 : 
//     - first official release
//
//   v1.1.1 : 2023/06/19
//     - date change from native data.
//     - standalone function to correct from previous data loading
//     - changed the name of Python script to be executed
/////////////////////////////////////////////////////////////


///////////////// MENU ////////////////////////////////////////

Menu "ACMCC Annual Submission"
	"Initialize Panel",/q,ACMCC_Initialize_Panel()
End

///////////////// END OF MENU ////////////////////////////////////////

Function ACMCC_Initialize_Panel()
	NewDataFolder/O/S root:ToF_ACSM
	NewDataFolder/O/S root:ACMCC_Export
	Variable/G Number
	String/G ListOfStations="AthensNOA;AthensDEM;ATOLL;Birkenes;Bologna;Cabauw;CAO;CeSMA;CIAO;Granada;HelsinkiSupersite;Hohenpeissenberg;Hyltemossa;Hyytiala;JFJ;Kosetice;KuopioPiojo;Magurele;Manchester;Marseille;Melpitz;MonteCimone;Montseny;PalauReial;ParisBpEst;ParisChatelet;Payerne;PuydeDome;SIRTA;Taunus;UCD;Villum;Zeppelin;Other"
	String/G ToF_Quad_Str="UMR Quad;UMR ToF;UMR ToF-X;HR ToF-X"
	String/G Lens_Str="PM1 Lens;PM2.5 Lens"
//	String/G Spec_Str="UMR ToF;UMR ToF-X;HR ToF-X"
	String/G Vaporizer_Str="Standard Vap.;Capture Vap."
	String/G NextCloud_path=""
	String/G Script_path=""
	String/G Python_path=""
	String/G ACSMsuffix = ""
	String/G PathToACSMFolder=""
	
	String/G DryerStat_path="C:ACSM:DryerStats:"
	String/G Pump_path="C:ACSM:PumpData:"
	String/G SN_str=""
	
	String/G FileName_str=""
	String/G FlagName_str=""
	
	Variable/G StartStop_bool=0
	Variable/G GeneratePMFInput=1
	Variable/G ApplyMiddlebrook=0
	
	Make/N=1/O/T StationNameW,ToF_QuadW,LensW,VaporizerW
	
	NextCloud_path=""
	ToF_QuadW[0]="UMR ToF"
	SN_str=""
	
	Make/O/N=5/T ACSMvar
	Make/O/N=5 LOD
	
	ACSMvar[0]="OM"
	ACSMvar[1]="NO3"
	ACSMvar[2]="SO4"
	ACSMvar[3]="NH4"
	ACSMvar[4]="Cl"
	
	LOD[0]=0.1
	LOD[1]=0.12
	LOD[2]=0.28
	LOD[3]=0.51
	LOD[4]=0.1
	
	String/G TraceonGraph="OM"
	
	Variable/G AutoFlag_InletP=1
	Variable/G AutoFlag_InletPvar=1
	Variable/G AutoFlag_AB=1
	Variable/G AutoFlag_VapT=1
	Variable/G AutoFlag_ConcLOD=1
	Variable/G AutoFlag_Concvar=1
	Variable/G AutoFlag_PMDiff=1
	Variable/G InletPmin=0
	Variable/G InletPmax=0
	Variable/G InletPvar=0.2
	Variable/G AB_warning=8.0e-06
	Variable/G AB_low=100000
	Variable/G AB_high=500000
	Variable/G Concvar=100
	Variable/G VapTmin=500
	Variable/G VapTmax=700
	Variable/G PMDiff=10
	
	Make/O/N=(2,3)/D CS_Bool
	CS_Bool[0][0]=56576
	CS_Bool[0][1]=56576
	CS_Bool[0][2]=56576
	CS_Bool[1][0]=36608
	CS_Bool[1][1]=3840
	CS_Bool[1][2]=3072
	
	String/G VarName="all;OM;NO3;SO4;NH4;Cl"
	String/G FlagList=""
	FlagList += "000: (V) Valid measurement;"
	FlagList += "100: (V) Checked by data originator. Valid measurement, overrides any invalid flags;"
	FlagList += "110: (V) Episode data checked and accepted by data originator. Valid measurement;"
	FlagList += "111: (V) Irregular data checked and accepted by data originator. Valid measurement;"
	FlagList += "456: (I) Invalidated by data originator;"
	FlagList += "559: (V) Unspecified contamination or local influence, but considered valid;"
	FlagList += "599: (I) Unspecified contamination or local influence ;"
	FlagList += "659: (I) Unspecified instrument/sampling anomaly;"
	FlagList += "660: (V) Unspecified instrument/sampling anomaly;"
	FlagList += "999: (I) Missing measurement, unspecified reason;"
	
	Variable/G YearToExport
	
	//Get IE, RIE and CE values
	Make/N=1/D/O IE_NO3, RIE_NH4, RIE_SO4, RIE_NO3, RIE_OM, RIE_Cl
	
//	FlagList += "-1: (?) Other flag - see EBAS website and enter at right;"
	
	ACMCC_Export_Panel()
	
End Function



Function ACMCC_Export_Panel()
	dowindow ExportPanel
	if(V_flag==1)
		killwindow ExportPanel
	endif
	
	newpanel/N=ExportPanel/W=(200,10,605,700)/K=1
	modifypanel fixedSize = 1
	
	SetDrawEnv fsize= 30,fstyle= 0,textrgb= (8704,8704,8704)
	DrawText 40,45,"ACSM Export Tool v."+ACMCC_Export_version
	
	PopupMenu PM_Station, fSize=14, pos={6,55}, size={100,20}, value = "select;"+InputLists("Station"), title="\f01Station Name", proc = StationInput_proc, disable = 0, win=ExportPanel,fstyle=1,font="Arial"	
	wave/T ToF_QuadW=root:ACMCC_Export:ToF_QuadW
//	SetVariable PM_Spectro, fSize=14, pos={200,55}, size={180,20}, value = ToF_QuadW[0], title="\f01Spectrometer", disable = 0, win=ExportPanel,fstyle=0,font="Arial",noedit=1
//	SVAR/Z ToF_Quad_Str=root:ACMCC_Export:ToF_Quad_Str
	PopupMenu PM_Spectro, fSize=14, pos={200,55}, size={180,20}, value = "select;"+InputLIsts("Spectro"), title="\f01Spectrometer", proc = SpectroInput_proc, disable = 0, win=ExportPanel,fstyle=0,font="Arial"//,noedit=1

	SVAR/Z SN_str=root:ACMCC_Export:SN_str
	SetVariable Set_SN, fSize=10, pos={230,80}, size={150,20}, value = SN_str, title="\f02Serial Number", win=ExportPanel,fstyle=2,font="Arial"

	if (stringmatch(ToF_QuadW[0],"UMR Quad"))
		SetVariable Set_SN, noedit=1
	elseif (stringmatch(ToF_QuadW[0],"UMR ToF"))
		SetVariable Set_SN, noedit=0
//	elseif (stringmatch(ToF_QuadW[0],"UMR ToF-X"))
//		SetVariable Set_SN, noedit=0
//	elseif (stringmatch(ToF_QuadW[0],"HR ToF-x"))
//		SetVariable Set_SN, noedit=0
	endif
	
	PopupMenu PM_Lens, fSize=14, pos={6,120}, size={100,20}, value = "select;"+InputLists("Lens"), title="\f01Lens", proc = LensInput_proc, disable = 0, win=ExportPanel,fstyle=1,font="Arial"
	PopupMenu PM_Vap, fSize=14, pos={200,120}, size={100,20}, value = "select;"+InputLists("Vaporizer"), title="\f01Vaporizer", proc = VapInput_proc, disable = 0, win=ExportPanel,fstyle=1,font="Arial"

	SVAR/Z Script_path=root:ACMCC_Export:Script_path
	SetVariable Set_ScriptPath,title="Script Data Folder",pos={10,155},size={323,19},value=Script_path,fSize=12,noedit=1,font="Arial", disable=0
	Button Set_ScriptPath_button,title="\\f01SET",pos={336,155},size={50,20},fSize=14,fColor=(39168,39168,39168),font="Arial", proc=SetScriptPath_proc, disable=0
	
	//SVAR/Z NextCloud_path=root:ACMCC_Export:NextCloud_path
	//SetVariable Set_ExportPath,title="Save Data Folder",pos={7,170},size={323,19},value=NextCloud_path,fSize=12,noedit=1,font="Arial", disable=0
	//Button Set_PathToR_button,title="\\f01SET",pos={336,170},size={50,20},fSize=14,fColor=(39168,39168,39168),font="Arial", proc=SetPath_proc, disable=0
	
	GroupBox GetACSMconc,pos={2,178},size={395,170},title="\\f01I/ ACSM concentrations",fSize=12,fColor=(13056,4352,0),labelBack=(64512,64512,60160),frame=0,font="Arial"

//	SetDrawEnv fstyle= 1 
//	SetDrawLayer UserFront
	SetDrawEnv fsize= 13 
	DrawText 26,210,"Note: Do not 'use the CDCE', data suffix should be _11000"
	DrawText 26,225, "Check calcultate plot errors when generating Time series"

	SVar/Z PathToACSMFolder=root:ACMCC_Export:PathToACSMFolder
	SetVariable Set_PathToACSMData,title="1.Path to final conc.",pos={16,231},size={235,19},value=PathToACSMFolder,fSize=14,noedit=1,font="Arial"
	Button Set_PathToACSMData_button,title="\\f01SET",pos={336,231},size={50,20},fSize=14,proc=Set_PathToACSMFolder_proc,fColor=(39168,39168,39168),font="Arial"
	
//	SVAR/Z ACSMsuffix=root:ACMCC_Export:ACSMsuffix
//	SetVariable Set_ACSMsuffix,title="Species suffix",pos={22,240},size={150,30},value=ACSMsuffix,disable=0,font="Arial",fsize=12

//	Button LoadConcButt, title="\\f01 1.Load Tofware conc. File", pos={64,238},fSize=18,size={280,35},font="Arial", fcolor=(52224,34816,0), proc=LoadACSMConcFile
	Button LoadACSMButt, title="\\f01 2.Load Native Files", pos={118,253},fSize=16,size={185,27},font="Arial", fcolor=(52224,34816,0), proc=LoadACSMDataFiles
	Button CheckLODButton, title="\\f01 3.Check LOD values", pos={10,284},fSize=14,size={150,27},font="Arial", fcolor=(52224,34816,0), proc=CheckLODPanel
	//Button CalculateLODButton, title="\\f02Calculate LOD values", pos={210,255},fSize=10,size={125,15},font="Arial", fcolor=(52224,34816,0), proc=CalculateLODButton_proc
//	CheckBox UseMiddlebrook_CB, title="Use Composition-Dependent CE", pos={175,281}, fsize=14,value=ApplyMiddlebrook, proc=CE_Warning_proc
	Button GetDryerdata_butt, title="4.Dryer", pos={181,286}, size={60,25},font="Arial", fcolor=(52224,34816,0),proc=LoadDryerData//, disable=2
	Button CEpanel_Butt, title="\\f01 5.CDCE panel", pos={276,286},fSize=14,size={110,25},font="Arial", fcolor=(52224,34816,0), proc=CE_ButtonProc
	Button GetACSMButt, title="\\f01 6.Apply", pos={121,314},fSize=18,size={200,30},font="Arial", fcolor=(52224,34816,0), proc=GetACSM_proc
	
//	Button fDiag_butt_cePanel,pos={20,283},size={110,19},proc=sq_CE_ButtonProc,title="CDCE panel"
	
	//Button GetPumpdata_butt, title="Pumps", pos={310,315}, size={60,25},font="Arial", fcolor=(52224,34816,0)
	
	GroupBox GetErrors,pos={2,350},size={395,80},title="\\f01II/ Errors",fSize=12,fColor=(13056,4352,0),labelBack=(61952,61952,65280),frame=0,font="Arial"
//	Button EditErrorParamButt,  title="\\f01Edit Param.", pos={10,380},fSize=12,size={80,35},font="Arial", fcolor=(32768,40704,65280), proc=EditErrorParam_proc
	Button CalcErrorButt, title="\\f01Get Errors", pos={50,380},fSize=14,size={130,35},font="Arial", fcolor=(32768,40704,65280), proc=GetError_proc
	Button CheckErrorButt, title="\\f01Check Error Sanity", pos={215,380},fSize=14,size={150,35},font="Arial", fcolor=(32768,40704,65280), proc=CheckError_proc

	GroupBox GetClosure,pos={2,430},size={395,70},title="\\f01III/ Mass Closure",fSize=12,fColor=(13056,4352,0),labelBack=(29465,51989,60363),frame=0,font="Arial"
	Button ClosureButt, title="\\f01Mass closure panel", pos={79,450},fSize=14,size={245,35},font="Arial", fcolor=(16385,49025,65535), proc=OpenMassclosure_panel

	GroupBox GetFlags,pos={2,500},size={395,70},title="\\f01IV/ Flags",fSize=12,fColor=(13056,4352,0),labelBack=(65280,59648,57600),frame=0,font="Arial"
	Button PreQualifButt, title="\\f01Suggest Flags", pos={10,522},fSize=14,size={150,35},font="Arial", fcolor=(65024,49152,43776), proc=AutoFlagPanel
	Button FlagPanelButt, title="\\f01Open Manual Flag Panel", pos={180,522},fSize=14,size={190,35},font="Arial", fcolor=(65024,49152,43776), proc=OpenFlagPanel_proc
	
	
	Button ExportButt, title="\\f01Export raw txt files", pos={10,580},fSize=14,size={385,35},font="Arial", fcolor=(43264,58112,43008), proc=ExportTxt_proc
	
	//SVAR/Z Script_path=root:ACMCC_Export:Script_path
	//SetVariable Set_ScriptPath,title="Script Data Folder",pos={7,630},size={323,19},value=Script_path,fSize=12,noedit=1,font="Arial", disable=0
	//Button Set_ScriptPath_button,title="\\f01SET",pos={336,630},size={50,20},fSize=14,fColor=(39168,39168,39168),font="Arial", proc=SetScriptPath_proc, disable=0
	
	//SVAR/Z Python_path=root:ACMCC_Export:Python_path
	//SetVariable Set_PythonPath,title="Python Data Folder",pos={7,660},size={323,19},value=Python_path,fSize=12,noedit=1,font="Arial", disable=0
	//Button Set_PythonPath_button,title="\\f01SET",pos={336,660},size={50,20},fSize=14,fColor=(39168,39168,39168),font="Arial", proc=SetPythonPath_proc, disable=0
	
	Button ExecuteScriptButt, title="\\f01Generate NASA-AMES", pos={10,620},fSize=14,size={385,35},font="Arial", fcolor=(39168,39168,39168), proc=ExecuteScript_proc
	
End


Function/S InputLists(option)
	string option
	
	if (stringmatch(option,"Station"))
		SVAR/Z ListOfStations=root:ACMCC_Export:ListOfStations
		return ListOfStations
	endif
	if (stringmatch(option,"Spectro"))
		SVAR/Z ToF_Quad_Str=root:ACMCC_Export:ToF_Quad_Str
		return ToF_Quad_Str
	endif
	if (stringmatch(option,"Lens"))
		SVAR/Z Lens_Str=root:ACMCC_Export:Lens_Str
		return Lens_Str
	endif
	if (stringmatch(option,"Vaporizer"))
		SVAR/Z Vaporizer_Str=root:ACMCC_Export:Vaporizer_Str
		return Vaporizer_Str
	endif
	
End Function


Function SpectroInput_proc(name,num,str) : PopupMenuControl
	string name
	variable num
	string str
	wave/T ToF_QuadW
	SVAR/Z ToF_Quad_Str=root:ACMCC_Export:ToF_Quad_Str
	if(stringmatch(str,"select"))
		DoAlert/T="WARNING" 0,"Please select in the list"
	else
		ToF_Quad_Str[0]=str
		ToF_QuadW[0]=str
//		print ToF_QuadW
	endif
End Function

Function StationInput_proc(name,num,str) : PopupMenuControl
	string name
	variable num
	string str

	SVAR/Z ListOfStations=root:ACMCC_Export:ListOfStations

	wave/T StationNameW=root:ACMCC_Export:StationNameW
	if (stringmatch(str,"other"))
		string temp
		string prompt_str="Please enter the name of the station. Be consistent with previous files !"
		prompt temp, prompt_str
		doprompt "Please verify", temp
		StationNameW[0]=temp
		ListOfStations+=";"+temp
		
	elseif(stringmatch(str,"select"))
		DoAlert/T="WARNING" 0,"Please select in the list the name of your station"
	else
		StationNameW[0]=str
	endif
End Function

Function LensInput_proc(name,num,str) : PopupMenuControl
	string name
	variable num
	string str

	wave/T LensW=root:ACMCC_Export:LensW
	if(stringmatch(str,"select"))
		DoAlert/T="WARNING" 0,"Please select in the list"
	else
		LensW[0]=str
	endif
	
End Function

Function VapInput_proc(name,num,str) : PopupMenuControl
	string name
	variable num
	string str

	wave/T VaporizerW=root:ACMCC_Export:VaporizerW
	if(stringmatch(str,"select"))
		DoAlert/T="WARNING" 0,"Please select in the list"
	else
		VaporizerW[0]=str
	endif
	
	
	NVAR/Z ApplyMiddlebrook=root:ACMCC_Export:ApplyMiddlebrook
	
	if(stringmatch(VaporizerW[0],"Capture Vap."))
		ApplyMiddlebrook=0
		Button CEpanel_Butt, disable=2 //CDCE button greyed
		CheckBox UseMiddlebrook_CB, title="Use Composition-Dependent CE", fsize=14,value=ApplyMiddlebrook,disable=2
	elseif(stringmatch(VaporizerW[0],"Standard Vap."))
		ApplyMiddlebrook=1
		CheckBox UseMiddlebrook_CB, title="Use Composition-Dependent CE", fsize=14,value=ApplyMiddlebrook,disable=0
		Button CEpanel_Butt, disable=0
		
	endif
	
End Function

Function LoadACSMDataFiles(ctrlName) : ButtonControl
	string ctrlName
	
//	NewDataFolder/O/S root:ToF_ACSM
	SetDataFolder root:ToF_ACSM
	Variable refNum
	String message = "Select one or more files"
	String outputPaths
	//String fileFilters = "All Files:.*;"
	String fileFilters = "Data Files (*.txt,*.dat,*.csv):.txt,.dat,.csv;"

 
	Open /D /R /MULT=1 /F=fileFilters /M=message refNum
	outputPaths = S_fileName
 
	if (strlen(outputPaths) == 0)
		Print "Cancelled"

	else
		Variable numFilesSelected = ItemsInList(outputPaths, "\r")
		Variable i
		string nameofACSMfile
		for(i=0; i<numFilesSelected; i+=1)
			String path = StringFromList(i, outputPaths, "\r")

			LoadWave/Q/O/J/M/D/K=0/L={0,1,0,0,0}/V={","," $",0,0} path
			wave wave0
			nameofACSMfile="ACSM_"+num2str(i)
			Rename wave0,$nameofACSMfile
			
		endfor
		string ListofACSMWave=Wavelist("ACSM_*",";","")
		Concatenate/O/NP=0 ListofACSMWave, Mx
		
		KillListofWaves(ListofACSMWave)
		
		ConvertDateTime()
		CheckDoublonAndNaN()
		ConvertDateTime()
		MakeAllParamWaves()
//		Make_ConC_cal_Waves()
		
	endif

End Function

Function ConvertDateTime()

	wave Mx=root:ToF_ACSM:Mx
	variable i//, stringtest
	
	make/O/T/N=(dimsize(Mx,0)) DateStrW
	make/O/D/N=(dimsize(Mx,0)) DateNative //Initially DateW
//	print dimsize(DateNative,0)

	
	DateStrW=juliantodate(datetojulian(Mx[p][0],1,1)+Mx[p][2]-1,1)
//	stringtest=date2secs(Mx[0][0],1,1)
	Variable dayOfMonth, month, year, dayOfWeek
	string shortDateStr
	
	for(i=0;i<numpnts(DateStrW);i+=1)
		//shortDateStr=DateStrW[i]
		//sscanf shortDateStr, "%d/%d/%d", dayOfMonth, month, year
		//DateW[i]=date2secs(year,month,dayOfMonth)+(Mx[i][2]-trunc(Mx[i][2]))*(3600*24)
		DateNative[i]=Mx[i][2]*86400 + date2secs(Mx[i][0],1,1) - 86400
		//if(i==0)
		//print Mx[0][2]*86400 + date2secs(Mx[0][0],1,1) - 85800
		//Endif
	endfor
//	print dimsize(DateStrW,0)

	SetScale d 0,0,"dat",DateNative
	
End Function



Function SetScriptPath_proc(Path_name) : ButtonControl
	String Path_name
	SVAR/Z Script_path=root:ACMCC_Export:Script_path
	
	String temp_folder
	temp_folder = getdatafolder(1)
	
	//define path
	newpath/O/Q path1
	pathinfo path1
	Script_path = S_path
	setdatafolder temp_folder
	
	wave/T StationNameW=root:ACMCC_Export:StationNameW
	//ControlInfo PM_Station
	//string station=S_value
	string station=StationNameW[0]
	string folder=Script_path+"data:"
	NewPath/C/O/Q tempPath folder
	folder=Script_path+"data:"+station
	NewPath/C/O/Q tempPath folder	//create this folder if it does not exits
	folder=Script_path+"data:"+station+":in:"
	NewPath/C/O/Q tempPath folder
	folder=Script_path+"data:"+station+":out:"
	NewPath/C/O/Q tempPath folder

	SVAR/Z NextCloud_path=root:ACMCC_Export:NextCloud_path
	NextCloud_path=Script_path+"data:"+station+":in:"
	
End Function

Function Set_PathToACSMFolder_proc(ctrlName) : ButtonControl
	String ctrlName
	SVAR PathToACSMFolder=root:ACMCC_Export:PathToACSMFolder
	PathToACSMFolder = GetBrowserSelection(0)
	if(stringmatch(PathToACSMFolder,"root"))
		PathToACSMFolder="root:"
	endif
	SVAR/Z PathToACSMConcWave=root:ACMCC_Export:PathToACSMConcWave
	PathToACSMConcWave=PathToACSMFolder
	Duplicate2ToFACSMFolder()
End Function

Function Duplicate2ToFACSMFolder()//(ctrlName) : ButtonControl
//	String ctrlName
	string temp_folder
	SVAR PathToACSMFolder=root:ACMCC_Export:PathToACSMFolder
	SetDataFolder $PathToACSMFolder
	String ACSMExt_Str
	String ACSMsuffix// = root:Tof_ACSM:ACSMsuffix
//	ACSMExt_Str = ACSMsuffix
	temp_folder=getdatafolder(1)
	wave t_base
	String Org_str, SO4_str, NO3_str, NH4_str, Chl_str
	String OrgErr_str, SO4Err_str, NO3Err_str, NH4Err_str, ChlErr_str
	//if(....) string sur type Spectro 
	Org_str = "Org_11000"//+ACSMExt_Str
	SO4_str = "SO4_11000" //+ACSMExt_Str
	NO3_str = "NO3_11000" //+ACSMExt_Str
	NH4_str = "NH4_11000" //+ACSMExt_Str
	Chl_str = "Chl_11000" //+ACSMExt_Str
	OrgErr_str = "Org_1Derr_11000"//+ACSMExt_Str
	SO4Err_str = "SO4_1Derr_11000" //+ACSMExt_Str
	NO3Err_str = "NO3_1Derr_11000" //+ACSMExt_Str
	NH4Err_str = "NH4_1Derr_11000" //+ACSMExt_Str
	ChlErr_str = "Chl_1Derr_11000" //+ACSMExt_Str
	//Elseif(stringmatch(str,"HR TOF-X"))
//	Org_str = "HROrg_11000"//+ACSMExt_Str
//	SO4_str = "HRSO4_11000" //+ACSMExt_Str
//	NO3_str = "HRNO3_11000" //+ACSMExt_Str
//	NH4_str = "HRNH4_11000" //+ACSMExt_Str
//	Chl_str = "HRChl_11000"
	//Endif
//	Make/O/D/N=(numpnts(t_base)) DateW
//	DateW = t_base
	Duplicate/O t_base,root:ToF_ACSM:t_base 
	Duplicate/O $Org_str, root:ToF_ACSM:OM
//	Duplicate/O $Org_str, root:ToF_ACSM:Org
	Duplicate/O $SO4_str, root:ToF_ACSM:SO4
	Duplicate/O $NO3_str, root:ToF_ACSM:NO3
	Duplicate/O $NH4_str, root:ToF_ACSM:NH4
	Duplicate/O $Chl_str, root:ToF_ACSM:Cl
	
	Duplicate/O $OrgErr_str, root:ToF_ACSM:OM_err
//	Duplicate/O $Org_str, root:ToF_ACSM:Org
	Duplicate/O $SO4Err_str, root:ToF_ACSM:SO4_err
	Duplicate/O $NO3Err_str, root:ToF_ACSM:NO3_err
	Duplicate/O $NH4Err_str, root:ToF_ACSM:NH4_err
	Duplicate/O $ChlErr_str, root:ToF_ACSM:Cl_err

	Make_ConC_cal_Waves()

	Display root:ToF_ACSM:OM,root:ToF_ACSM:NO3,root:ToF_ACSM:SO4,root:ToF_ACSM:NH4,root:ToF_ACSM:Cl vs root:ToF_ACSM:t_base
	ModifyGraph mode=7,hbFill=3,toMode=2,rgb(SO4)=(52428,1,1),rgb(OM)=(26205,52428,1),rgb(NO3)=(0,43690,65535),rgb(NH4)=(65535,43690,0),rgb(Cl)=(65535,32768,58981)
	Label bottom " "
	Label left " CE = 0.5, NR-PM\\B1\\M - ug m\\S-3"
	
	
End Function


Function Make_ConC_cal_Waves()
//	SetDataFolder root:tw_globals 
//	variable tw_ck_UTCoffset
//	make/O/D/N=1 UTCoffset=tw_ck_UTCoffset
//	Duplicate/O UTCoffset, root:ToF_ACSM:UTCoffset
	SetDataFolder root:ToF_ACSM
//	wave Mx=root:ToF_ACSM:Mx
	wave t_base=root:ToF_ACSM:t_base
	wave tw_wv_batchRIE=root:tw_UMRfrag:tw_wv_batchRIE
	wave tw_wv_batchCE=root:tw_UMRfrag:tw_wv_batchCE
	wave ugConv_ionspg_filesWave=root:Packages:tw_ACSM2:ABCalib:ugConv_ionspg_filesWave
	wave ABRefWave=root:Packages:tw_ACSM2:ABCalib:ABRefWave
	wave ABsamp=root:Packages:tw_ACSM2:ABCalib:ABsamp
	Duplicate/O t_base, t_base_utc
	Nvar tw_ck_UTCoffset=root:tw_globals:tw_ck_UTCoffset
	t_base_utc -= tw_ck_UTCoffset
	
	variable dt_acsm
	
	dt_acsm = t_base_utc[1]-t_base_utc[0]
//	print dt_acsm
	t_base_utc += dt_acsm

//	Make/O/D/N=(numpnts(t_base_utc)) DateW
//	DateW = t_base_utc	
	Duplicate/O t_base_utc, DateW
	Duplicate/O t_base_utc,  root:ACMCC_Export:ACSM_time

	Make/O/N=(numpnts(t_base)) RIE_OM=tw_wv_batchRIE[1]
	Make/O/N=(numpnts(t_base)) RIE_NO3=tw_wv_batchRIE[2]
	Make/O/N=(numpnts(t_base)) RIE_SO4=tw_wv_batchRIE[3]
	Make/O/N=(numpnts(t_base)) RIE_Cl=tw_wv_batchRIE[4]
	Make/O/N=(numpnts(t_base)) RIE_NH4=tw_wv_batchRIE[5]
	Make/O/N=(numpnts(t_base)) CE=tw_wv_batchCE[1]
	
	wave/T VaporizerW=root:ACMCC_Export:VaporizerW	
	if(stringmatch(VaporizerW[0],"Standard Vap.") & CE[0] != 0.5)
		doAlert 0, "CE is different from 0.5 with a Standard vaporizer, reprocessing needed"
	Elseif(stringmatch(VaporizerW[0],"Capture Vap.") & CE[0] != 1)
		doAlert 0, "CE is different from 1 with a Capture vaporizer, reprocessing needed"
	Endif

	Make/O/N=(numpnts(t_base)) IE_ionspg=ugConv_ionspg_filesWave[0]
	Make/O/N=(numpnts(t_base)) ABref=ABRefWave[0]
	Make/O/N=(numpnts(t_base)) AB_total=ABsamp
	
	Duplicate/O RIE_OM,root:ACMCC_Export:RIE_OM
	Duplicate/O RIE_NO3,root:ACMCC_Export:RIE_NO3
	Duplicate/O RIE_SO4,root:ACMCC_Export:RIE_SO4
	Duplicate/O RIE_NH4,root:ACMCC_Export:RIE_NH4
	Duplicate/O RIE_Cl,root:ACMCC_Export:RIE_Cl
	Duplicate/O IE_ionspg,root:ACMCC_Export:IE_NO3
	 
//	Display OM,NO3,SO4,NH4,Cl vs DateW
//	ModifyGraph mode=7,hbFill=3,toMode=2,rgb(SO4)=(52428,1,1),rgb(OM)=(26205,52428,1),rgb(NO3)=(0,43690,65535),rgb(NH4)=(65535,43690,0),rgb(Cl)=(65535,32768,58981)
//	Label bottom " "
	
	CheckCEandCorrect()
	
End Function

Function CheckCEandCorrect()

    wave CE
    Variable CE_captureV

    if (CE[0] == 1)
        DoAlert 0, "CE = 1 checked"  // no change needed
    else
        DoAlert 0, "Your data are not CDCE corrected and have been multiplied by CE = " + num2str(CE[0])
        wave OM, NO3, SO4, NH4, Cl
        Duplicate/O NO3, NO3_CE1
        Duplicate/O OM, OM_CE1
        Duplicate/O SO4, SO4_CE1
        Duplicate/O NH4, NH4_CE1
        Duplicate/O Cl, Cl_CE1
        NO3_CE1 *= CE
        OM_CE1 *= CE
        SO4_CE1 *= CE
        NH4_CE1 *= CE
        Cl_CE1 *= CE
    endif
    Duplicate/O OM, root:ACMCC_Export:OM
    Duplicate/O NO3, root:ACMCC_Export:NO3
    Duplicate/O SO4, root:ACMCC_Export:SO4
    Duplicate/O NH4, root:ACMCC_Export:NH4
    Duplicate/O Cl, root:ACMCC_Export:Cl
 

End

Function MakeAllParamWaves()

	clean_native_data()
	
	Wave Mx_Adj=root:ToF_ACSM:Mx_Adj

	Make/O/N=(dimsize(Mx_adj,0)) Status=Mx_Adj[p][3]
	Make/O/N=(dimsize(Mx_adj,0)) Cl_nat=Mx_Adj[p][4]
	Make/O/N=(dimsize(Mx_adj,0)) NH4_nat=Mx_Adj[p][5]
	Make/O/N=(dimsize(Mx_adj,0)) NO3_nat=Mx_Adj[p][6]
	Make/O/N=(dimsize(Mx_adj,0)) OM_nat=Mx_Adj[p][7]
	Make/O/N=(dimsize(Mx_adj,0)) SO4_nat=Mx_Adj[p][8]
//	Make/O/N=(dimsize(Mx_adj,0)) RIE_Cl=Mx[p][9]
//	Make/O/N=(dimsize(Mx_adj,0)) RIE_NH4=Mx[p][10]
//	Make/O/N=(dimsize(Mx_adj,0)) RIE_NO3=Mx[p][11]
//	Make/O/N=(dimsize(Mx_adj,0)) RIE_OM=Mx[p][12]
//	Make/O/N=(dimsize(Mx_adj,0)) RIE_SO4=Mx[p][13]
	Make/O/N=(dimsize(Mx_adj,0)) f43=Mx_Adj[p][14]
	Make/O/N=(dimsize(Mx_adj,0)) f44=Mx_Adj[p][15]
	Make/O/N=(dimsize(Mx_adj,0)) f57=Mx_Adj[p][16]
	Make/O/N=(dimsize(Mx_adj,0)) f60=Mx_Adj[p][17]
	Make/O/N=(dimsize(Mx_adj,0)) HOA=Mx_Adj[p][18]
	Make/O/N=(dimsize(Mx_adj,0)) OOA=Mx_Adj[p][19]
//	Make/O/N=(dimsize(Mx_adj,0)) CE=Mx[p][20]
//	Make/O/N=(dimsize(Mx_adj,0)) IE_ionspg=Mx[p][25]
//	Make/O/N=(dimsize(Mx_adj,0)) ABref=Mx[p][26]
//	Make/O/N=(dimsize(Mx_adj,0)) AB_total=Mx[p][27]
	Make/O/N=(dimsize(Mx_adj,0)) AB_bg=Mx_Adj[p][28]
	Make/O/N=(dimsize(Mx_adj,0)) Flow_css=Mx_Adj[p][29]
	Make/O/N=(dimsize(Mx_adj,0)) Flow_p0=Mx_Adj[p][30]
	Make/O/N=(dimsize(Mx_adj,0)) Flow_p1=Mx_Adj[p][31]
	Make/O/N=(dimsize(Mx_adj,0)) n_total=Mx_Adj[p][32]
	Make/O/N=(dimsize(Mx_adj,0)) n_bkgd=Mx_Adj[p][33]
	Make/O/N=(dimsize(Mx_adj,0)) baseline=Mx_Adj[p][34]
	Make/O/N=(dimsize(Mx_adj,0)) Threshold=Mx_Adj[p][35]
	Make/O/N=(dimsize(Mx_adj,0)) mzCal_p1=Mx_Adj[p][36]
	Make/O/N=(dimsize(Mx_adj,0)) mzCal_p2=Mx_Adj[p][37]
	Make/O/N=(dimsize(Mx_adj,0)) ratio40div28=Mx_Adj[p][38]
	Make/O/N=(dimsize(Mx_adj,0)) RBP=Mx_Adj[p][43]
	Make/O/N=(dimsize(Mx_adj,0)) RG=Mx_Adj[p][44]
	Make/O/N=(dimsize(Mx_adj,0)) Lens=Mx_Adj[p][45]
	Make/O/N=(dimsize(Mx_adj,0)) Detector=Mx_Adj[p][46]
	Make/O/N=(dimsize(Mx_adj,0)) HV_Spare=Mx_Adj[p][47]
	Make/O/N=(dimsize(Mx_adj,0)) Pulser=Mx_Adj[p][48]
	Make/O/N=(dimsize(Mx_adj,0)) Lens2=Mx_Adj[p][49]
	Make/O/N=(dimsize(Mx_adj,0)) Defl=Mx_Adj[p][50]
	Make/O/N=(dimsize(Mx_adj,0)) Defl_range=Mx_Adj[p][51]
	Make/O/N=(dimsize(Mx_adj,0)) IonEx=Mx_Adj[p][52]
	Make/O/N=(dimsize(Mx_adj,0)) Lens1=Mx_Adj[p][53]
	Make/O/N=(dimsize(Mx_adj,0)) HB=Mx_Adj[p][54]
	Make/O/N=(dimsize(Mx_adj,0)) IonChamber=Mx_Adj[p][55]
	Make/O/N=(dimsize(Mx_adj,0)) Filament_V=Mx_Adj[p][56]
	Make/O/N=(dimsize(Mx_adj,0)) Filament_Emm=Mx_Adj[p][57]
	Make/O/N=(dimsize(Mx_adj,0)) Filament_I=Mx_Adj[p][58]
	Make/O/N=(dimsize(Mx_adj,0)) Filament_N=Mx_Adj[p][59]
	Make/O/N=(dimsize(Mx_adj,0)) Interlock=Mx_Adj[p][60]
	Make/O/N=(dimsize(Mx_adj,0)) HVp=Mx_Adj[p][61]
	Make/O/N=(dimsize(Mx_adj,0)) HVn=Mx_Adj[p][62]
	Make/O/N=(dimsize(Mx_adj,0)) Turbo_speed=Mx_Adj[p][63]
	Make/O/N=(dimsize(Mx_adj,0)) Turbo_power=Mx_Adj[p][64]
	Make/O/N=(dimsize(Mx_adj,0)) Fore_pc=Mx_Adj[p][65]
	Make/O/N=(dimsize(Mx_adj,0)) TPS_temp=Mx_Adj[p][66]
	Make/O/N=(dimsize(Mx_adj,0)) Press_ioniser=Mx_Adj[p][67]
	Make/O/N=(dimsize(Mx_adj,0)) Press_inlet=Mx_Adj[p][68]
	Make/O/N=(dimsize(Mx_adj,0)) Heater_PWM=Mx_Adj[p][73]
	Make/O/N=(dimsize(Mx_adj,0)) Heater_I=Mx_Adj[p][74]
	Make/O/N=(dimsize(Mx_adj,0)) Heater_V=Mx_Adj[p][75]
	Make/O/N=(dimsize(Mx_adj,0)) Heater_T=Mx_Adj[p][76]

	wave OM, NO3, NH4, SO4, Cl, t_base, DateNative_adj
	Display OM_nat vs DateNative_adj //,NO3_nat,SO4_nat,NH4_nat,Cl_nat
	AppendtoGraph/L=L2 NO3 vs t_base
	AppendtoGraph/L=L2 NO3_nat vs DateNative_adj
	AppendtoGraph/L=L3 SO4 vs t_base
	AppendtoGraph/L=L3 SO4_nat vs DateNative_adj
	AppendtoGraph/L=L4 NH4 vs t_base
	AppendtoGraph/L=L4 NH4_nat vs DateNative_adj
	AppendtoGraph/L=L5 Cl vs t_base	
	AppendtoGraph/L=L5 Cl_nat vs DateNative_adj
	Appendtograph OM vs t_base
	ModifyGraph rgb(OM)=(26205,52428,1),rgb(SO4)=(52428,1,1),rgb(NO3)=(0,43690,65535),rgb(NH4)=(65535,43690,0),rgb(Cl)=(65535,32768,58981)
	
	ModifyGraph axisEnab(Left)={0.81,1},freePos(Left)={0,bottom}
	ModifyGraph axisEnab(L2)={0.61,0.79},freePos(L2)={0,bottom}
	ModifyGraph axisEnab(L3)={0.41,0.59},freePos(L3)={0,bottom}
	ModifyGraph axisEnab(L4)={0.21,0.39},freePos(L4)={0,bottom}
	ModifyGraph axisEnab(L5)={0,0.19},freePos(L5)={0,bottom}
	
	Label left "OM"
	Label L2 "NO3"
	Label L3 "SO4"
	Label L4 "NH4"
	Label L5 "Cl"
	SetAxis Left 0,*
	SetAxis L2 0,*
	SetAxis L3 0,*
	SetAxis L4 0,*
	SetAxis L5 0,*
	Label bottom "Local time"
	legend
	
End Function

Function clean_native_data()

    wave DateNative = root:ToF_ACSM:DateNative
    wave t_base = root:ToF_ACSM:t_base
//    wave t_base_UTC = root:ToF_ACSM:t_base_UTC

    wave Mx = root:ToF_ACSM:Mx
     
    variable n_native = numpnts(DateNative)
    variable n_base   = numpnts(t_base)

    if (n_native == 0 || n_base == 0)
        DoAlert 0, "One of the waves is empty."
        return 0
    elseif (n_native < n_base)
        DoAlert 0, "native data do not cover full period"
    endif

//	Duplicate/O t_base_UTC, DateNative_adj
	Make/O/D/N=(n_base,dimsize(Mx,1)) Mx_adj
	Make/O/D/N=(n_base) DateNative_adj
	
	
	variable i,j
	
	for (i = 0; i < n_base; i += 1)
		j = BinarySearch(DateNative, t_base[i])
//		if(abs(DateNative_NaN[i] - DateNative_NaN[i-1]) > 2*dt_med)
   		DateNative_adj[i] =  DateNative[j]
	    Mx_adj[i][] = Mx[j][q]

   EndFor 
   
   SetScale d 0,0,"dat",DateNative_adj

End




Function KillListofWaves(ListofWave)
	string ListOfWave
	variable i
	Variable numFilesSelected = ItemsInList(ListOfWave, ";")
	for(i=0; i<numFilesSelected; i+=1)
		String Wave2Kill = StringFromList(i, ListOfWave, ";")
		KillWaves/Z $Wave2Kill	
	endfor
End Function


Function CheckLODPanel(ctrlName) : ButtonControl
	string ctrlName
	
	SetDataFolder root:ACMCC_Export
	
	//Get IE, RIE and CE values
	wave/T ACSMvar
	wave LOD

	wave ACSM_time=root:ACMCC_Export:ACSM_time
	wave OM//=root:ToF_ACSM:OM
	wave NO3//=root:ToF_ACSM:NO3
	wave SO4//=root:ToF_ACSM:SO4
	wave NH4//=root:ToF_ACSM:NH4
	wave Cl//=root:ToF_ACSM:Cl
	
	Wave w= $"blank_flag"
	if(waveexists(w)==0)
		duplicate/O OM, blank_flag
		blank_flag=NaN
	else
		wave blank_flag
	endif
	
	NewPanel/N=CheckLOD/W=(10,10,1200,400)/K=1
	Display/HOST=CheckLOD/W=(0.25,0.1,0.95,0.95) OM vs ACSM_time
	AppendToGraph NO3 vs ACSM_time
	AppendToGraph SO4 vs ACSM_time
	AppendToGraph NH4 vs ACSM_time
	AppendToGraph Cl vs ACSM_time
	ModifyGraph rgb(OM)=(26112,52224,0),rgb(NO3)=(0,43520,65280)
	ModifyGraph rgb(SO4)=(52224,0,0),rgb(NH4)=(65280,43520,0)
	ModifyGraph rgb(Cl)=(65280,16384,55552)
	Label bottom " "
	AppendToGraph/R blank_flag vs ACSM_time
	ModifyGraph axRGB(right)=(65535,65535,65535),tlblRGB(right)=(65535,65535,65535),alblRGB(right)=(65535,65535,65535)
	SetAxis right 0,1
	ModifyGraph mode(blank_flag)=3,marker(blank_flag)=16,rgb(blank_flag)=(43520,43520,43520)	
	TextBox/C/B=1/N=text0/F=0/S=3/H={50,1,10}/A=MC "\\Z12\\f02draw a marquee on graph to select a period for LOD calculation"
	
	edit/HOST=CheckLOD/W=(0.01,0.1,0.23,0.6) ACSMvar,LOD

	Button CalculateLOD_but, title="Calculate LOD", pos={80,250}, size={130,25},fsize=14,font="Arial",fColor=(32768,65280,32768),proc=CalculateLOD_proc
	Button DefaultLOD_but, title="Back to Default", pos={80,300}, size={130,25},fsize=14,font="Arial",proc=DefaultLOD_proc

End Function


Function DefaultLOD_proc(ctrlName) : ButtonControl
	string ctrlName
	SetDataFolder root:ACMCC_Export
	wave LOD
	LOD[0]=0.1
	LOD[1]=0.12
	LOD[2]=0.28
	LOD[3]=0.51
	LOD[4]=0.1
End Function

Function CalculateLOD_proc(ctrlName) : ButtonControl
	string ctrlName
	SetDataFolder root:ACMCC_Export
	wave LOD,blank_filter
	
	wave ACSM_time=root:ToF_ACSM:t_base_utc
	wave OM=root:ToF_ACSM:OM
	wave NO3=root:ToF_ACSM:NO3
	wave SO4=root:ToF_ACSM:SO4
	wave NH4=root:ToF_ACSM:NH4
	wave Cl=root:ToF_ACSM:Cl
	
	LOD[0]=CalculateLOD(OM)
	LOD[1]=CalculateLOD(NO3)
	LOD[2]=CalculateLOD(SO4)
	LOD[3]=CalculateLOD(NH4)
	LOD[4]=CalculateLOD(Cl)
	
End Function

Function CalculateLOD(specie)
	wave specie
	
	SetDataFolder root:ACMCC_Export
	wave blank_flag
	
	Extract/O specie, temp,(blank_flag==1)
	WaveStats/Q temp
	variable LOD_var
	LOD_var=3*V_sdev
	return LOD_var
	
End Function


Menu "GraphMarquee"
	"ACMCC: Calculate LOD from Marquee" , Calculate_LOD()
	"ACMCC: Set Threshold", Set_Threshold()
End


Menu "GraphMarquee"
	"ACMCC: Add period to blank" , AddBlank()
	"ACMCC: Remove period to blank",RemoveBlank()
	"ACMCC: Set Threshold", Set_Threshold()
	"ACMCC: Invalidate from External Data", Invalidate_from_ExternalData()
	"ACMCC: Replace by median error", ReplaceMedianError()
	
End

Function AddBlank()

	SetDataFolder root:ACMCC_Export:
	wave blank_flag
	wave ACSM_time=root:ToF_ACSM:DateW
	
	
	GetMarquee bottom
	variable MinIndex,MaxIndex
	MinIndex=BinarySearch(ACSM_time,V_left)
	MaxIndex=BinarySearch(ACSM_time,V_right)
	
	blank_flag[MinIndex, MaxIndex]=1
End Function


Function RemoveBlank()

	SetDataFolder root:ACMCC_Export:
	wave blank_flag
	wave ACSM_time=root:ToF_ACSM:DateW
	
	
	GetMarquee bottom
	variable MinIndex,MaxIndex
	MinIndex=BinarySearch(ACSM_time,V_left)
	MaxIndex=BinarySearch(ACSM_time,V_right)
	
	blank_flag[MinIndex, MaxIndex]=NaN
End Function


Function CE_Warning_proc(ctrlName,checked) : CheckBoxControl
	string ctrlName
	Variable checked
	
	if (checked==1)
		//DoAlert/T="WARNING" 0,"This will only calculate time-dependent CE. It will not correct concentrations. Please make sure that time dependent CE correction have not already been applied on your data"	
		DoAlert/T="WARNING" 0,"Raw data will be corrected from Composition-dependant CE"	
	endif

End Function


Function GetACSM_proc(ctrlName) : ButtonControl
	string ctrlName
	
	NVAR/Z ApplyMiddlebrook=root:ACMCC_Export:ApplyMiddlebrook
	SetDataFolder root:ACMCC_Export
	variable i
	wave DateW=root:ToF_ACSM:DateW
	//Make/N=(numpnts(DateW))/O ACSM_time
	//ACSM_time=DateW
	duplicate/O DateW, ACSM_time // should be UTC time
	Make/N=(numpnts(DateW))/O/T ACSM_time_txt
	For (i=0;i<(numpnts(DateW));i+=1)
		string year=ACMCC_ExtractDateInfo(DateW[i],"year")
		string month=ACMCC_ExtractDateInfo(DateW[i],"month")
		string dayOfMonth=ACMCC_ExtractDateInfo(DateW[i],"dayOfMonth")
		string hour=ACMCC_ExtractTimeInfo(DateW[i],"hour")
		string minute=ACMCC_ExtractTimeInfo(DateW[i],"minute")
		string second=ACMCC_ExtractTimeInfo(DateW[i],"second")
	
		ACSM_time_txt[i]=year+"/"+month+"/"+dayofmonth+" "+hour+":"+minute+":"+second
	
	endfor	
	
	wave/T VaporizerW, LensW, ToF_QuadW
	string temp1=ToF_QuadW[0]
	string temp2=VaporizerW[0]
	string temp3=LensW[0]
	
	Make/O/T/N=(numpnts(DateW)) VaporizerW, LensW, ToF_QuadW
	ToF_QuadW=temp1
	VaporizerW=temp2
	LensW=temp3
	
	wave IE_ionspg=root:ACMCC_Export:IE_ionspg
	wave IE_NO3
	Variable updated_IENO3
	
  	updated_IENO3 = IE_NO3[0]    // default value shown in prompt
	Prompt updated_IENO3, "Check/update IE NO3 value: "
 	DoPrompt "Check/update IE_NO3",updated_IENO3

	wave IE_NO3W=root:ToF_ACSM:IE_ionspg
	wave RIE_OMW=root:ToF_ACSM:RIE_OM
	wave RIE_NH4W=root:ToF_ACSM:RIE_NH4
	wave RIE_NO3W=root:ToF_ACSM:RIE_NO3
	wave RIE_SO4W=root:ToF_ACSM:RIE_SO4
	wave RIE_ClW=root:ToF_ACSM:RIE_Cl
	duplicate/O IE_NO3W IE_NO3
	IE_NO3 = updated_IENO3
	duplicate/O RIE_NO3W RIE_NO3
	duplicate/O RIE_OMW RIE_OM
	duplicate/O RIE_NH4W RIE_NH4
	duplicate/O RIE_SO4W RIE_SO4
	duplicate/O RIE_ClW RIE_Cl
	
	wave CEW=root:ToF_ACSM:CE
	wave CE=root:CE_fPhase
//	duplicate/O CEW CE
	
	wave OrgW=root:ToF_ACSM:OM
	wave NO3W=root:ToF_ACSM:NO3
	wave SO4W=root:ToF_ACSM:SO4
	wave NH4W=root:ToF_ACSM:NH4
	wave ClW=root:ToF_ACSM:Cl
	
	duplicate/O OrgW, OM
	duplicate/O NO3W, NO3
	duplicate/O NH4W, NH4
	duplicate/O SO4W, SO4
	duplicate/O ClW, Cl
	
	SO4*=CEW
	NH4*=CEW
	NO3*=CEW
	Cl*=CEW
	OM*=CEW
	
	NVAR/Z ApplyMiddlebrook=root:ACMCC_Export:ApplyMiddlebrook
	if (ApplyMiddlebrook==1)
//		wave LOD=root:ACMCC_Export:LOD
//		Duplicate/o SO4 PredNH4, NH4_MeasToPredict, ANMF
//		PredNH4=18*(SO4/96*2+NO3/62+Cl/35.45)
//		NH4_MeasToPredict=NH4/PredNH4
//		ANMF=(80/62)*NO3/(NO3+SO4+NH4+OM+Cl)
//		For (i=0;i<(numpnts(SO4));i+=1)
//			If (NH4_MeasToPredict[i]<0)
//				NH4_MeasToPredict[i]=nan
//			EndIf
			//	Nan ANMF points if negative or more than 1
//			If (ANMF[i]<0)
//				ANMF[i]=nan
//			ElseIf (ANMF[i]>1)
//				ANMF[i]=nan
//			EndIf
			
//			If (PredNH4[i]<LOD[3])
//			print LOD[3]
//				CE[i]=0.5
//			ElseIf (NH4_MeasToPredict[i]>=0.75)
				//	Apply Equation 4
//				CE[i]= 0.0833+0.9167*ANMF[i]
//			ElseIf (NH4_MeasToPredict[i]<0.75)
				//	Apply Equation 6
//				CE[i]= 1-0.73*NH4_MeasToPredict[i]
//			EndIf
//		EndFor
		
//		CE=min(1,(max(0.5,CE)))
//		KillWaves ANMF, PredNH4, NH4_MeasToPredict 
		SO4/=CE
		NH4/=CE
		NO3/=CE
		Cl/=CE
		OM/=CE		
		
		//SO4*=CEW/CE
		//NH4*=CEW/CE
		//NO3*=CEW/CE
		//Cl*=CEW/CE
		//OM*=CEW/CE
	endif
	
	wave Mx=root:ToF_ACSM:Mx
	Make/O/N=(numpnts(DateW)) YearW, Start_DOY, Stop_DOY
	YearW=Mx[p][0]
	Start_DOY=Mx[p][1]
	Stop_DOY=Mx[p][2]
	
	duplicate/O root:ToF_ACSM:ABref ABref
	duplicate/O root:ToF_ACSM:AB_total AB_total
	duplicate/O root:ToF_ACSM:Flow_css Flow_css
	duplicate/O root:ToF_ACSM:n_total n_total
	duplicate/O root:ToF_ACSM:n_bkgd n_bkgd
	duplicate/O root:ToF_ACSM:baseline baseline
	duplicate/O root:ToF_ACSM:threshold threshold
	duplicate/O root:ToF_ACSM:mzCal_p1 mzCal_p1
	duplicate/O root:ToF_ACSM:mzCal_p2 mzCal_p2
	duplicate/O root:ToF_ACSM:ratio40div28 ratio40div28
	duplicate/O root:ToF_ACSM:mzCal_p1 mzCal_p1
	duplicate/O root:ToF_ACSM:Lens Lens
	duplicate/O root:ToF_ACSM:Pulser Pulser
	duplicate/O root:ToF_ACSM:Lens2 Lens2
	duplicate/O root:ToF_ACSM:IonEx IonEx
	duplicate/O root:ToF_ACSM:Lens1 Lens1
	duplicate/O root:ToF_ACSM:HB HB
	duplicate/O root:ToF_ACSM:IonChamber IonChamber
	duplicate/O root:ToF_ACSM:Filament_Emm Filament_Emm
	duplicate/O root:ToF_ACSM:Detector Detector
	duplicate/O root:ToF_ACSM:Turbo_speed Turbo_speed
	duplicate/O root:ToF_ACSM:Turbo_power Turbo_power
	duplicate/O root:ToF_ACSM:Fore_pc Fore_pc
	duplicate/O root:ToF_ACSM:Press_inlet Press_inlet
	duplicate/O root:ToF_ACSM:Heater_PWM Heater_PWM
	duplicate/O root:ToF_ACSM:Heater_I Heater_I
	duplicate/O root:ToF_ACSM:Heater_V Heater_V
	duplicate/O root:ToF_ACSM:Heater_T Heater_T
	
	Make/O/N=(numpnts(DateW)) Servo2_PWM,Servo3_PWM
	Servo2_PWM=Mx[p][77]
	Servo3_PWM=Mx[p][78]
	
	
	//Get Dryer Stats
	SetDataFolder root:ACMCC_Export:
	Make/O/N=(numpnts(ACSM_time)) Sampling_Flowrate, RH_In, RH_Out, T_In, T_Out
	Sampling_Flowrate=9.999
	RH_In=99.999
	RH_Out=99.999
	T_In=99.999
	T_Out=99.999
	
	Make/O/N=(numpnts(ACSM_time)) OM_err, NO3_err, SO4_err, NH4_err, Cl_err
	OM_err=999.999
	NO3_err=999.999
	SO4_err=999.999
	NH4_err=999.999
	Cl_err=999.999
	
	Make/O/N=(numpnts(DateW)) numflag_OM
	duplicate/O numflag_OM numflag_NO3,numflag_SO4,numflag_NH4,numflag_Cl	
	Make/O/N=(numpnts(DateW)) ValidBool_OM=0
	duplicate/O ValidBool_OM ValidBool_NO3,ValidBool_SO4, ValidBool_NH4, ValidBool_Cl
	
	FindYearToExport()

End Function


Function/S ACMCC_ExtractDateInfo(dt,dateinfo)
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

Function/S ACMCC_ExtractTimeInfo(dt,timeinfo)
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




Function LoadDryerData(ctrlName) : ButtonControl
	string ctrlName

	NewDataFolder/O/S root:ACMCC_Export:DryerStats
	Variable refNum
	String message = "Select one or more files"
	String outputPaths
	String fileFilters = "All Files:.*;"
 
	Open /D /R /MULT=1 /F=fileFilters /M=message refNum
	outputPaths = S_fileName
	
	if (strlen(outputPaths) == 0)
		Print "Cancelled"

	else
		Variable numFilesSelected = ItemsInList(outputPaths, "\r")
		Variable i
		string nameofDryerfile, nameOfDryerdate
		for(i=0; i<numFilesSelected; i+=1)
			String path = StringFromList(i, outputPaths, "\r")

			//LoadWave/Q/O/J/M/D/K=0/L={0,1,0,0,0}/V={" "," $",0,0} path
			//LoadWave/Q/O/J/M/D/K=0/L={0,1,0,0,0} path
			LoadWave /J/A/B="F=8,N=DateTimeW;F=0,N=InletP;F=0,N=CounterP;F=0,N=PDrop;F=0,N=FlowRate;F=0,N=RHIn;F=0,N=TIn;F=0,N=RHDry;F=0,N=TDry;"/L={0,1,0,0,0}/D/O/Q path
			wave DateTimeW,InletP,CounterP,PDrop,FlowRate,RHIn,TIn,RHDry,TDry	
			concatenate /NP/KILL {DateTimeW}, datW
			concatenate /NP/KILL {InletP}, InletPW
			concatenate /NP/KILL {CounterP}, CounterPW
			concatenate /NP/KILL {PDrop}, PDropW
			concatenate /NP/KILL {FlowRate}, FlowRateW
			concatenate /NP/KILL {RHIn}, RHInW
			concatenate /NP/KILL {TIn}, TInW		
			concatenate /NP/KILL {RHDry}, RHDryW
			concatenate /NP/KILL {TDry}, TDryW		
			
			//LoadWave/A=Dryertime_/Q/J/V={" "," $",0,0}/L={0,8,0,0,1}/R={French,2,2,2,1,"Year/Month/DayOfMonth",40} path
		endfor
		//string ListofDryerWave=Wavelist("Dryer_*",";","")
		//string ListofDateWave=Wavelist("Dryertime_*",";","")
		//Concatenate/O/NP=0 ListofDateWave, Dryerdate
		//Concatenate/O/NP=0 ListofDryerWave, Mx
		
		//KillListofWaves(ListofDryerWave)
		//KillListofWaves(ListofDateWave)
		
		wave ACSMtime=root:ACMCC_Export:ACSM_time
		ACMCC_Avg_WaveList(datW,"InletPW;CounterPW;PDropW;FlowRateW;RHInW;TInW;RHDryW;TDryW",ACSMtime)
		wave InletPW_avg, CounterPW_avg, PDropW_avg, FlowRateW_avg, RHInW_avg, TInW_avg, RHDryW_avg, TDryW_avg
		InletPW_avg[numpnts(ACSMtime)-1]=NaN
		CounterPW_avg[numpnts(ACSMtime)-1]=NaN
		PDropW_avg[numpnts(ACSMtime)-1]=NaN
		FlowRateW_avg[numpnts(ACSMtime)-1]=NaN
		RHInW_avg[numpnts(ACSMtime)-1]=NaN
		TInW_avg[numpnts(ACSMtime)-1]=NaN
		RHDryW_avg[numpnts(ACSMtime)-1]=NaN
		TDryW_avg[numpnts(ACSMtime)-1]=NaN

		RHDryW_avg = (numtype(RHDryW_avg[p]) == 2) ? 0 : RHDryW_avg[p]		

		SetDataFolder root:ACMCC_Export:
		wave T_Out, T_In, RH_Out, RH_In, Sampling_Flowrate, ACSM_time
		T_Out=TDryW_avg
		T_In=TInW_avg
		RH_Out=RHDryW_avg
		RH_In=RHInW_avg
		Sampling_Flowrate=FlowRateW_avg
		
		 T_Out = (numtype(T_Out[p]) == 2) ? 0 : T_Out[p]
		 T_In = (numtype(T_In[p]) == 2) ? 0 : T_In[p]
		 RH_Out = (numtype(RH_Out[p]) == 2) ? 0 : RH_Out[p]
		 RH_In = (numtype(RH_In[p]) == 2) ? 0 : RH_In[p]
		 Sampling_Flowrate = (numtype(Sampling_Flowrate[p]) == 2) ? 0 : Sampling_Flowrate[p]
		Display RH_Out vs ACSM_time
		AppendToGraph RH_In vs ACSM_time
		ModifyGraph rgb(RH_Out)=(0,0,0)
	endif

End Function


Function ACMCC_Avg_WaveList(Date_Wave,ListOfWaves,Timeline)
	wave Date_Wave, Timeline
	string ListOfWaves
	
	variable nbelemlist=ItemsInList(ListofWaves)
	variable i
	string WaveNameToUse
	
	for(i=0;i<nbelemlist;i+=1)
		WaveNameToUse=StringFromList(i,ListofWaves)
		wave temp=$WaveNameToUse
		ACMCC_avg(temp, Date_Wave,Timeline)
	endfor
End Function



Function ACMCC_avg(Conc_Wave, Date_Wave,Timeline)
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
	duplicate/O temp_avg $ConcWaveName
	KillWaves temp_avg,temp_conc,temp_date
End Function

Function GetError_proc(ctrlName) : ButtonControl
	string ctrlName
	
	SVAR/Z PathToACSMFolder=root:ACMCC_Export:PathToACSMFolder
	SetDataFolder PathToACSMFolder
	wave/Z Chl_1Derr_11000, Org_1Derr_11000, NO3_1Derr_11000, NH4_1Derr_11000, SO4_1Derr_11000

	if(waveexists(Chl_1Derr_11000))
		Duplicate/O Chl_1Derr_11000, root:acmcc_export:Cl_err
		Duplicate/O Org_1Derr_11000, root:acmcc_export:OM_err
		Duplicate/O NO3_1Derr_11000, root:acmcc_export:NO3_err
		Duplicate/O NH4_1Derr_11000, root:acmcc_export:NH4_err
		Duplicate/O SO4_1Derr_11000, root:acmcc_export:SO4_err
	Else
		DoAlert 0, "When generating concentration waves _11000, check Calculate,Plot errors in Tofware"
	Endif
	
End Function

Function CheckError_proc(ctrlName) : ButtonControl
	string ctrlName
	
	SetDataFolder root:ACMCC_Export
	wave ACSM_time, OM_err, NO3_err, SO4_err, NH4_err, Cl_err, OM, NO3, SO4, NH4, Cl
	wave/T ACSMvar
	
	SVAR/Z TraceonGraph=root:ACMCC_Export:TraceonGraph
	TraceonGraph="OM"
	dowindow ErrorSanity
	if(V_flag==1)
		killwindow ErrorSanity
	endif
	
	newpanel/N=ErrorSanity/W=(150,80,1000,600)/K=1
	Display/HOST=ErrorSanity/W=(0.05,0.1,0.95,0.95)/N=ErrorGraph/L=L1 OM vs ACSM_time
	AppendtoGraph/R=R1 OM_err vs ACSM_time
	ModifyGraph freePos(L1)={0,bottom}
	ModifyGraph freePos(R1)={0,kwFraction}
	Label bottom " "
	Label L1 "Concentration"
	Label R1 "error"
	ModifyGraph rgb(OM)=(0,0,0)
	ModifyGraph axRGB(R1)=(65280,0,0),tlblRGB(R1)=(65280,0,0),alblRGB(R1)=(65280,0,0)
	ModifyGraph fSize=14

	PopupMenu VarTSerr_PUM title="Timeserie",pos={10,10},value=VarItemList(),fsize=18, proc=VarTSerr_proc
	

End Function

Function VarTSerr_proc(name,num,str) : PopupMenuControl
	string name
	variable num
	string str
	
	SVAR/Z TraceonGraph=root:ACMCC_Export:TraceonGraph
	string previous=TraceonGraph
	string previous_err=previous+"_err"
	
	if(stringmatch(str,"all"))
	
	else
		SetDataFolder root:ACMCC_Export
		TraceonGraph=str
		wave TS=$(TraceonGraph)
		wave TS_err=$(TraceonGraph+"_err")
		replacewave/W=ErrorSanity#ErrorGraph trace=$(previous), TS
		replacewave/W=ErrorSanity#ErrorGraph trace=$(previous_err), TS_err
	endif
	

End Function

Function AutoFlagPanel(ctrlName) : ButtonControl
	string ctrlName
	
	SetDataFolder root:ACMCC_Export:
	wave/T LensW
	
	NVAR/Z AutoFlag_InletP=root:ACMCC_Export:AutoFlag_InletP
	NVAR/Z AutoFlag_InletPvar=root:ACMCC_Export:AutoFlag_InletPvar
	NVAR/Z AutoFlag_AB=root:ACMCC_Export:AutoFlag_AB
	NVAR/Z AutoFlag_VapT=root:ACMCC_Export:AutoFlag_VapT
	NVAR/Z AutoFlag_ConcLOD=root:ACMCC_Export:AutoFlag_ConcLOD
	NVAR/Z AutoFlag_Concvar=root:ACMCC_Export:AutoFlag_Concvar
	NVAR/Z AutoFlag_PMdiff=root:ACMCC_Export:AutoFlag_PMdiff
	
	NVAR/Z InletPmin=root:ACMCC_Export:InletPmin
	NVAR/Z InletPmax=root:ACMCC_Export:InletPmax
	NVAR/Z InletPvar=root:ACMCC_Export:InletPvar
	NVAR/Z AB_warning=root:ACMCC_Export:AB_warning
	NVAR/Z AB_low=root:ACMCC_Export:AB_low
	NVAR/Z AB_high=root:ACMCC_Export:AB_high
	NVAR/Z Concvar=root:ACMCC_Export:Concvar
	NVAR/Z VapTmin=root:ACMCC_Export:VapTmin
	NVAR/Z VapTmax=root:ACMCC_Export:VapTmax
	NVAR/Z PMdiff=root:ACMCC_Export:PMdiff
	
	if(stringmatch(LensW[0],"PM1 Lens"))
		InletPmin=1.6
		InletPmax=2.5
	elseif(stringmatch(LensW[0],"PM2.5 Lens"))
		InletPmin=4.0
		InletPmax=4.8
	endif
	
	dowindow AutoFlagParam
	if(V_flag==1)
		killwindow AutoFlagParam
	endif
	
	newpanel/N=AutoFlagParam/W=(150,80,600,400)/K=1
	
	CheckBox InletP_CB, title="InletP", pos={10,10}, fsize=14, variable=AutoFlag_InletP
	SetVariable InletPmin_Var, title="min InletP", pos={90,10}, value=InletPmin, size={100,15}
	SetVariable InletPmax_Var, title="max InletP", pos={220,10}, value=InletPmax, size={100,15}
 	
 	CheckBox InletPvar_CB, title="InletP variation", pos={10,45}, fsize=14, variable=AutoFlag_InletPvar
 	SetVariable InletPvar_Var, title="abs threshold (torr)", pos={150,45}, value=InletPvar, size={150,15}
 	
 	CheckBox Airbeam_CB, title="Airbeam signal", pos={10,85}, fsize=14, variable=AutoFlag_AB
 	SetVariable AB_Warning_var, title="High limit AB", pos={150,85}, value=AB_high, size={140,15}
 	SetVariable AB_limit_var, title="Low limit AB", pos={295,85}, value=AB_low, size={140,15}

	CheckBox VapT_CB, title="Vap. temperature", pos={10,125}, fsize=14, variable=AutoFlag_VapT
 	SetVariable VapTmin_var, title="VapT min", pos={150,125}, value=VapTmin, size={100,15}
 	SetVariable VapTmax_var, title="VapT max", pos={270,125}, value=VapTmax, size={100,15}
 	
 	CheckBox ConcLOD_CB, title="Concentration LOD", pos={10,165}, fsize=14, variable=AutoFlag_ConcLOD
 	
 	CheckBox Concvar_CB, title="Concentration variation", pos={10,205}, fsize=14, variable=AutoFlag_Concvar
 	SetVariable Concvar_var, title="abs threshold", pos={190,205}, value=Concvar, size={120,15}
 	
 	CheckBox PMdiff_CB, title="Mass Closure", pos={10,240}, fsize=14, variable=AutoFlag_PMdiff,disable=2
 	SetVariable PMdiff_var, title="NR-PM to PM ratio %", pos={170,240}, value=PMdiff, size={170,150}
 	
 	Button AutoFlagButt, title="\\f01AutoFlag", pos={150,270},fSize=14,size={100,35},font="Arial", fcolor=(43264,58112,43008), proc=PreQualif_proc

End Function


Function PreQualif_proc(ctrlName) : ButtonControl
	string ctrlName
	killwindow AutoFlagParam
	
	SetDataFolder root:ACMCC_Export:
	wave ACSM_time
	wave OM, NO3, SO4, NH4,Cl, OM_err,NO3_err,SO4_err,NH4_err,Cl_err,numflag_OM,numflag_NO3,numflag_SO4,numflag_NH4,numflag_Cl, blank_flag
	wave LOD, Press_inlet, AB_total, Heater_T
	wave ValidBool_OM,ValidBool_NO3,ValidBool_SO4, ValidBool_NH4, ValidBool_Cl
	wave eBC_NRPM_avg=root:MassClosure:eBC_NRPM_avg
	wave PM1_avg=root:MassClosure:PM1_avg
	
	Duplicate/O eBC_NRPM_avg, ratio_eBCNRPM_PM
	ratio_eBCNRPM_PM = eBC_NRPM_avg/PM1_avg
	
	ratio_eBCNRPM_PM = numtype(blank_flag[p]) != 2 ? nan : ratio_eBCNRPM_PM [p]
	
	ValidBool_OM=0
	ValidBool_NO3=0
	ValidBool_SO4=0
	ValidBool_NH4=0
	ValidBool_Cl=0
	numflag_OM=0
	numflag_NO3=0
	numflag_SO4=0
	numflag_NH4=0
	numflag_Cl=0
	
	
	NVAR/Z AutoFlag_InletP=root:ACMCC_Export:AutoFlag_InletP
	NVAR/Z AutoFlag_InletPvar=root:ACMCC_Export:AutoFlag_InletPvar
	NVAR/Z AutoFlag_AB=root:ACMCC_Export:AutoFlag_AB
	NVAR/Z AutoFlag_VapT=root:ACMCC_Export:AutoFlag_VapT
	NVAR/Z AutoFlag_ConcLOD=root:ACMCC_Export:AutoFlag_ConcLOD
	NVAR/Z AutoFlag_Concvar=root:ACMCC_Export:AutoFlag_Concvar
	NVAR/Z AutoFlag_PMdiff=root:ACMCC_Export:AutoFlag_PMdiff
	
	NVAR/Z InletPmin=root:ACMCC_Export:InletPmin
	NVAR/Z InletPmax=root:ACMCC_Export:InletPmax
	NVAR/Z InletPvar=root:ACMCC_Export:InletPvar
	//NVAR/Z AB_warning=root:ACMCC_Export:AB_warning
	NVAR/Z AB_low=root:ACMCC_Export:AB_low
	NVAR/Z AB_high=root:ACMCC_Export:AB_high
	NVAR/Z Concvar=root:ACMCC_Export:Concvar
	NVAR/Z VapTmin=root:ACMCC_Export:VapTmin
	NVAR/Z VapTmax=root:ACMCC_Export:VapTmax
	NVAR/Z PMdiff=root:ACMCC_Export:PMdiff
	
	Make/O/N=(numpnts(OM)) AutoFlagBool_OM, AutoFlagBool_NO3, AutoFlagBool_SO4, AutoFlagBool_NH4, AutoFlagBool_Cl, OneWave
	AutoFlagBool_OM=NaN
	AutoFlagBool_NO3=NaN
	AutoFlagBool_SO4=NaN
	AutoFlagBool_NH4=NaN
	AutoFlagBool_Cl=NaN
	OneWave=1
	Make/O/N=8 AutoFlagNb
	Make/O/T/N=8 AutoFlagTxt
	
	AutoFlagNb=p
	AutoFlagTxt[0]="InletP out of boundaries"
	AutoFlagTxt[1]="InletP variation out of boundary"
	AutoFlagTxt[2]="Airbeam too low"
	AutoFlagTxt[3]="Airbeam too high"
	AutoFlagTxt[4]="VapT out of boundaries"
	AutoFlagTxt[5]="Concentration below -3*LOD"
	AutoFlagTxt[6]="Concentration variation out of boundary"
	AutoFlagTxt[7]="Mass Closure variation out of boundary"
	
	Make/O/N=(8,3) AutoFlag_CB
	
	numflag_OM[]=(blank_flag[p]==1 ) ? 659 : numflag_OM[p]
	numflag_NO3[]=(blank_flag[p]==1 ) ? 659 : numflag_NO3[p]
	numflag_SO4[]=(blank_flag[p]==1 ) ? 659 : numflag_SO4[p]
	numflag_NH4[]=(blank_flag[p]==1 ) ? 659 : numflag_NH4[p]
	numflag_Cl[]=(blank_flag[p]==1 ) ? 659 : numflag_Cl[p]
	
	if (AutoFlag_InletP==1)
	
		numflag_OM[]=(Press_inlet[p]>InletPmax || Press_inlet[p]<InletPmin) ? 659 : numflag_OM[p]
		numflag_NO3[]=(Press_inlet[p]>InletPmax || Press_inlet[p]<InletPmin) ? 659 : numflag_NO3[p]
		numflag_SO4[]=(Press_inlet[p]>InletPmax || Press_inlet[p]<InletPmin) ? 659 : numflag_SO4[p]
		numflag_NH4[]=(Press_inlet[p]>InletPmax || Press_inlet[p]<InletPmin) ? 659 : numflag_NH4[p]
		numflag_Cl[]=(Press_inlet[p]>InletPmax || Press_inlet[p]<InletPmin) ? 659 : numflag_Cl[p]
		AutoFlagBool_OM[]=(Press_inlet[p]>InletPmax || Press_inlet[p]<InletPmin) ? 0 : AutoFlagBool_OM[p]
		AutoFlagBool_NO3[]=(Press_inlet[p]>InletPmax || Press_inlet[p]<InletPmin) ? 0 : AutoFlagBool_NO3[p]
		AutoFlagBool_SO4[]=(Press_inlet[p]>InletPmax || Press_inlet[p]<InletPmin) ? 0 : AutoFlagBool_SO4[p]
		AutoFlagBool_NH4[]=(Press_inlet[p]>InletPmax || Press_inlet[p]<InletPmin) ? 0 : AutoFlagBool_NH4[p]
		AutoFlagBool_Cl[]=(Press_inlet[p]>InletPmax || Press_inlet[p]<InletPmin) ? 0 : AutoFlagBool_Cl[p]
		
		Display Press_inlet vs ACSM_time
		Make/O/N=(numpnts(ACSM_time)) minInletPW, maxInletPW
		minInletPW=InletPmin
		maxInletPW=InletPmax
		AppendToGraph minInletPW vs ACSM_time
		AppendToGraph maxInletPW vs ACSM_time
		//SetAxis left 0.5,2.5
		ModifyGraph mode(minInletPW)=7,hbFill(minInletPW)=4,toMode(minInletPW)=1
		ModifyGraph rgb(minInletPW)=(32768,65280,32768)
		ModifyGraph rgb(maxInletPW)=(32768,65280,32768)
		ReorderTraces Press_inlet,{minInletPW,maxInletPW}
		ModifyGraph rgb(Press_inlet)=(0,0,0)
		Label bottom " "
		Label left "InletP (torr)"
		
	
		if(AutoFlag_InletPvar==1)
			
			ModifyGraph axisEnab(left)={0.51,1}
			
			duplicate/O Press_inlet d_press_inlet
			differentiate d_press_inlet
			
			numflag_OM[]=(abs(d_press_inlet[p])>InletPvar) ? 659 : numflag_OM[p]
			numflag_NO3[]=(abs(d_press_inlet[p])>InletPvar) ? 659 : numflag_NO3[p]
			numflag_SO4[]=(abs(d_press_inlet[p])>InletPvar) ? 659 : numflag_SO4[p]
			numflag_NH4[]=(abs(d_press_inlet[p])>InletPvar) ? 659 : numflag_NH4[p]
			numflag_Cl[]=(abs(d_press_inlet[p])>InletPvar) ? 659 : numflag_Cl[p]
			AutoFlagBool_OM[]=(abs(d_press_inlet[p])>InletPvar) ? 1 : AutoFlagBool_OM[p]
			AutoFlagBool_NO3[]=(abs(d_press_inlet[p])>InletPvar) ? 1 : AutoFlagBool_NO3[p]
			AutoFlagBool_SO4[]=(abs(d_press_inlet[p])>InletPvar) ? 1 : AutoFlagBool_SO4[p]
			AutoFlagBool_NH4[]=(abs(d_press_inlet[p])>InletPvar) ? 1 : AutoFlagBool_NH4[p]
			AutoFlagBool_Cl[]=(abs(d_press_inlet[p])>InletPvar) ? 1 : AutoFlagBool_Cl[p]
			
			Make/O/N=(numpnts(ACSM_time)) dInletP,dInletPthres
			dInletP[]=abs(d_press_inlet[p])
			dInletPthres=InletPvar
			AppendToGraph/R dInletP vs ACSM_time
			ModifyGraph rgb(dInletP)=(0,0,0)
			AppendToGraph/R dInletPthres vs ACSM_time
			ModifyGraph lstyle(dInletPthres)=3,lsize(dInletPthres)=3
			ModifyGraph rgb(dInletPthres)=(52224,0,0)
			ModifyGraph axisEnab(right)={0,0.49}
			Label right "\\F'Symbol'D\\F'Arial'InletP"
		endif
	endif
	
	if(AutoFlag_AB==1)
	
		numflag_OM[]=(AB_total[p]<AB_low) ? 659 : numflag_OM[p]
		numflag_NO3[]=(AB_total[p]<AB_low) ? 659 : numflag_NO3[p]
		numflag_SO4[]=(AB_total[p]<AB_low) ? 659 : numflag_SO4[p]
		numflag_NH4[]=(AB_total[p]<AB_low) ? 659 : numflag_NH4[p]
		numflag_Cl[]=(AB_total[p]<AB_low) ? 659 : numflag_Cl[p]
		AutoFlagBool_OM[]=(AB_total[p]<AB_low) ? 2 : AutoFlagBool_OM[p]
		AutoFlagBool_NO3[]=(AB_total[p]<AB_low) ? 2 : AutoFlagBool_NO3[p]
		AutoFlagBool_SO4[]=(AB_total[p]<AB_low) ? 2 : AutoFlagBool_SO4[p]
		AutoFlagBool_NH4[]=(AB_total[p]<AB_low) ? 2 : AutoFlagBool_NH4[p]
		AutoFlagBool_Cl[]=(AB_total[p]<AB_low) ? 2 : AutoFlagBool_Cl[p]
		
		numflag_OM[]=(AB_total[p]>AB_high) ? 659 : numflag_OM[p]
		numflag_NO3[]=(AB_total[p]>AB_high) ? 659 : numflag_NO3[p]
		numflag_SO4[]=(AB_total[p]>AB_high) ? 659 : numflag_SO4[p]
		numflag_NH4[]=(AB_total[p]>AB_high) ? 659 : numflag_NH4[p]
		numflag_Cl[]=(AB_total[p]>AB_high) ? 659 : numflag_Cl[p]
		AutoFlagBool_OM[]=(AB_total[p]>AB_high) ? 3 : AutoFlagBool_OM[p]
		AutoFlagBool_NO3[]=(AB_total[p]>AB_high) ? 3 : AutoFlagBool_NO3[p]
		AutoFlagBool_SO4[]=(AB_total[p]>AB_high) ? 3 : AutoFlagBool_SO4[p]
		AutoFlagBool_NH4[]=(AB_total[p]>AB_high) ? 3 : AutoFlagBool_NH4[p]
		AutoFlagBool_Cl[]=(AB_total[p]>AB_high) ? 3 : AutoFlagBool_Cl[p]
		
		
		Make/O/N=(numpnts(ACSM_time)) AB_lowW,AB_highW
		AB_lowW=AB_low
		AB_highW=AB_high

		Display AB_total vs ACSM_time
		AppendToGraph AB_lowW vs ACSM_time
		AppendToGraph AB_highW vs ACSM_time
		//SetAxis left 4e-08,*
		ModifyGraph mode(AB_lowW)=7,hbFill(AB_lowW)=4,toMode(AB_lowW)=1
		ModifyGraph rgb(AB_lowW)=(32768,65280,32768)
		ModifyGraph rgb(AB_highW)=(32768,65280,32768)
		ReorderTraces AB_total,{AB_lowW,AB_highW}
		Label bottom " "
		Label left "Airbeam signal"
		ModifyGraph rgb(AB_total)=(0,0,0)
	endif
	
	if(AutoFlag_VapT==1)
	
		numflag_OM[]=(Heater_T[p]>VapTmax || Heater_T[p]<VapTmin ) ? 660 : numflag_OM[p]
		numflag_NO3[]=(Heater_T[p]>VapTmax || Heater_T[p]<VapTmin ) ? 660 : numflag_NO3[p]
		numflag_SO4[]=(Heater_T[p]>VapTmax || Heater_T[p]<VapTmin ) ? 660 : numflag_SO4[p]
		numflag_NH4[]=(Heater_T[p]>VapTmax || Heater_T[p]<VapTmin ) ? 660 : numflag_NH4[p]
		numflag_Cl[]=(Heater_T[p]>VapTmax || Heater_T[p]<VapTmin ) ? 660 : numflag_Cl[p]
		AutoFlagBool_OM[]=(Heater_T[p]>VapTmax || Heater_T[p]<VapTmin ) ? 4 : AutoFlagBool_OM[p]
		AutoFlagBool_NO3[]=(Heater_T[p]>VapTmax || Heater_T[p]<VapTmin ) ? 4 : AutoFlagBool_NO3[p]
		AutoFlagBool_SO4[]=(Heater_T[p]>VapTmax || Heater_T[p]<VapTmin ) ? 4 : AutoFlagBool_SO4[p]
		AutoFlagBool_NH4[]=(Heater_T[p]>VapTmax || Heater_T[p]<VapTmin ) ? 4 : AutoFlagBool_NH4[p]
		AutoFlagBool_Cl[]=(Heater_T[p]>VapTmax || Heater_T[p]<VapTmin ) ? 4 : AutoFlagBool_Cl[p]
		
		Make/O/N=(numpnts(ACSM_time)) minVapT, maxVapT
		minVapT=VapTmin
		maxVapT=VapTmax
		Display minVapT vs ACSM_time
		AppendToGraph maxVapT vs ACSM_time
		AppendToGraph Heater_T vs ACSM_time
		ModifyGraph rgb(Heater_T)=(0,0,0)
		SetAxis left 400,*
		ModifyGraph mode(minVapT)=7,hbFill(minVapT)=4,toMode(minVapT)=1
		ModifyGraph rgb(minVapT)=(32768,65280,32768),rgb(maxVapT)=(32768,65280,32768)
		Label bottom " "
		Label left "Vaporizer temperature (°C)"
	endif
	
	if(AutoFlag_ConcLOD==1)
		numflag_OM[]=(OM[p]<(-3)*LOD[0]) ? 459 : numflag_OM[p]
		numflag_NO3[]=(NO3[p]<(-3)*LOD[1]) ? 459 : numflag_NO3[p]
		numflag_SO4[]=(SO4[p]<(-3)*LOD[2]) ? 459 : numflag_SO4[p]
		numflag_NH4[]=(NH4[p]<(-3)*LOD[3]) ? 459 : numflag_NH4[p]
		numflag_Cl[]=(Cl[p]<(-3)*LOD[4]) ? 459 : numflag_Cl[p]
		AutoFlagBool_OM[]=(OM[p]<(-3)*LOD[0]) ? 5 : AutoFlagBool_OM[p]
		AutoFlagBool_NO3[]=(NO3[p]<(-3)*LOD[1]) ? 5 : AutoFlagBool_NO3[p]
		AutoFlagBool_SO4[]=(SO4[p]<(-3)*LOD[2]) ? 5 : AutoFlagBool_SO4[p]
		AutoFlagBool_NH4[]=(NH4[p]<(-3)*LOD[3]) ? 5 : AutoFlagBool_NH4[p]
		AutoFlagBool_Cl[]=(Cl[p]<(-3)*LOD[4]) ? 5 : AutoFlagBool_Cl[p]
	endif
	
	if(AutoFlag_Concvar==1)
		duplicate/O OM d_OM
		duplicate/O NO3 d_NO3
		duplicate/O SO4 d_SO4
		duplicate/O NH4 d_NH4
		duplicate/O Cl d_Cl
		
		differentiate d_OM
		differentiate d_NO3
		differentiate d_SO4
		differentiate d_NH4
		differentiate d_Cl
	
		numflag_OM[]=(abs(d_OM[p])>Concvar) ? 659 : numflag_OM[p]
		numflag_NO3[]=(abs(d_NO3[p])>Concvar) ? 659 : numflag_NO3[p]
		numflag_SO4[]=(abs(d_SO4[p])>Concvar) ? 659 : numflag_SO4[p]
		numflag_NH4[]=(abs(d_NH4[p])>Concvar) ? 659 : numflag_NH4[p]
		numflag_Cl[]=(abs(d_Cl[p])>Concvar) ? 659 : numflag_Cl[p]
		AutoFlagBool_OM[]=(abs(d_OM[p])>Concvar) ? 6 : AutoFlagBool_OM[p]
		AutoFlagBool_NO3[]=(abs(d_NO3[p])>Concvar) ? 6 : AutoFlagBool_NO3[p]
		AutoFlagBool_SO4[]=(abs(d_SO4[p])>Concvar) ? 6 : AutoFlagBool_SO4[p]
		AutoFlagBool_NH4[]=(abs(d_NH4[p])>Concvar) ? 6 : AutoFlagBool_NH4[p]
		AutoFlagBool_Cl[]=(abs(d_Cl[p])>Concvar) ? 6 : AutoFlagBool_Cl[p]
	endif
	
	wave eBC_NRPM_avg = root:MassClosure:eBC_NRPM_avg
	wave PM1_avg = root:MassClosure:PM1_avg
	
		
	if(AutoFlag_PMdiff==1)
		numflag_OM[]=ratio_eBCNRPM_PM[p]>abs(1-PMdiff/100) || ratio_eBCNRPM_PM[p]<abs(1+PMdiff/100) ? 659 : numflag_OM[p]
		numflag_NO3[]=ratio_eBCNRPM_PM[p]>abs(1-PMdiff/100) || ratio_eBCNRPM_PM[p]<abs(1+PMdiff/100)  ? 659 : numflag_NO3[p]
		numflag_SO4[]=ratio_eBCNRPM_PM[p]>abs(1-PMdiff/100) || ratio_eBCNRPM_PM[p]<abs(1+PMdiff/100)  ? 659 : numflag_SO4[p]
		numflag_NH4[]=ratio_eBCNRPM_PM[p]>abs(1-PMdiff/100) || ratio_eBCNRPM_PM[p]<abs(1+PMdiff/100)  ? 659 : numflag_NH4[p]
		numflag_Cl[]=ratio_eBCNRPM_PM[p]>abs(1-PMdiff/100) || ratio_eBCNRPM_PM[p]<abs(1+PMdiff/100)  ? 659 : numflag_Cl[p]
		AutoFlagBool_OM[]= ratio_eBCNRPM_PM[p]>abs(1-PMdiff/100) || ratio_eBCNRPM_PM[p]<abs(1+PMdiff/100) ? 7 : AutoFlagBool_OM[p]
		AutoFlagBool_NO3[]=ratio_eBCNRPM_PM[p]>abs(1-PMdiff/100) || ratio_eBCNRPM_PM[p]<abs(1+PMdiff/100)  ? 7 : AutoFlagBool_NO3[p]
		AutoFlagBool_SO4[]=ratio_eBCNRPM_PM[p]>abs(1-PMdiff/100) || ratio_eBCNRPM_PM[p]<abs(1+PMdiff/100)  ? 7 : AutoFlagBool_SO4[p]
		AutoFlagBool_NH4[]=ratio_eBCNRPM_PM[p]>abs(1-PMdiff/100) || ratio_eBCNRPM_PM[p]<abs(1+PMdiff/100)  ? 7 : AutoFlagBool_NH4[p]
		AutoFlagBool_Cl[]=ratio_eBCNRPM_PM[p]>abs(1-PMdiff/100) || ratio_eBCNRPM_PM[p]<abs(1+PMdiff/100)  ? 7 : AutoFlagBool_Cl[p]
	endif
	
	//ValidBool_OM[]=(flagOM[p]==459 || flagOM[p]==659) ? 1 : ValidBool_OM[p]
//	ValidBool_OM[]=(blank_flag[p] == 1 || numflag_OM[p]==456 || numflag_OM[p]==459 || numflag_OM[p]==460 || numflag_OM[p]==567 || numflag_OM[p]==568 || numflag_OM[p]==591 || numflag_OM[p]==593 || numflag_OM[p]==599 || numflag_OM[p]==635 || numflag_OM[p]==646 || numflag_OM[p]==659 || numflag_OM[p]==677 || numflag_OM[p]==899 || numflag_OM[p]==980 || numflag_OM[p]==999) ? 1 : ValidBool_OM[p]
	ValidBool_OM[]=(numflag_OM[p]==456 || numflag_OM[p]==459 || numflag_OM[p]==460 || numflag_OM[p]==567 || numflag_OM[p]==568 || numflag_OM[p]==591 || numflag_OM[p]==593 || numflag_OM[p]==599 || numflag_OM[p]==635 || numflag_OM[p]==646 || numflag_OM[p]==659 || numflag_OM[p]==677 || numflag_OM[p]==899 || numflag_OM[p]==980 || numflag_OM[p]==999) ? 1 : ValidBool_OM[p]
	ValidBool_NO3[]=(numflag_NO3[p]==456 || numflag_NO3[p]==459 || numflag_NO3[p]==460 || numflag_NO3[p]==567 || numflag_NO3[p]==568 || numflag_NO3[p]==591 || numflag_NO3[p]==593 || numflag_NO3[p]==599 || numflag_NO3[p]==635 || numflag_NO3[p]==646 || numflag_NO3[p]==659 || numflag_NO3[p]==677 || numflag_NO3[p]==899 || numflag_NO3[p]==980 || numflag_NO3[p]==999) ? 1 : ValidBool_NO3[p]
	ValidBool_SO4[]=(numflag_SO4[p]==456 || numflag_SO4[p]==459 || numflag_SO4[p]==460 || numflag_SO4[p]==567 || numflag_SO4[p]==568 || numflag_SO4[p]==591 || numflag_SO4[p]==593 || numflag_SO4[p]==599 || numflag_SO4[p]==635 || numflag_SO4[p]==646 || numflag_SO4[p]==659 || numflag_SO4[p]==677 || numflag_SO4[p]==899 || numflag_SO4[p]==980 || numflag_SO4[p]==999) ? 1 : ValidBool_SO4[p]
	ValidBool_NH4[]=(numflag_NH4[p]==456 || numflag_NH4[p]==459 || numflag_NH4[p]==460 || numflag_NH4[p]==567 || numflag_NH4[p]==568 || numflag_NH4[p]==591 || numflag_NH4[p]==593 || numflag_NH4[p]==599 || numflag_NH4[p]==635 || numflag_NH4[p]==646 || numflag_NH4[p]==659 || numflag_NH4[p]==677 || numflag_NH4[p]==899 || numflag_NH4[p]==980 || numflag_NH4[p]==999) ? 1 : ValidBool_NH4[p]
	ValidBool_Cl[]=(numflag_Cl[p]==456 || numflag_Cl[p]==459 || numflag_Cl[p]==460 || numflag_Cl[p]==567 || numflag_Cl[p]==568 || numflag_Cl[p]==591 || numflag_Cl[p]==593 || numflag_Cl[p]==599 || numflag_Cl[p]==635 || numflag_Cl[p]==646 || numflag_Cl[p]==659 || numflag_Cl[p]==677 || numflag_Cl[p]==899 || numflag_Cl[p]==980 || numflag_Cl[p]==999) ? 1 : ValidBool_Cl[p]
	//ValidBool_NO3[]=(flagNO3[p]==459 || flagNO3[p]==659) ? 1 : ValidBool_NO3[p]
	//ValidBool_SO4[]=(flagSO4[p]==459 || flagSO4[p]==659) ? 1 : ValidBool_SO4[p]
	//ValidBool_NH4[]=(flagNH4[p]==459 || flagNH4[p]==659) ? 1 : ValidBool_NH4[p]
	//ValidBool_Cl[]=(flagCl[p]==459 || flagCl[p]==659) ? 1 : ValidBool_Cl[p]

	
End Function


Function OpenFlagPanel_proc(ctrlName) : ButtonControl
	string ctrlName
	
	dowindow FlagPanel
	if(V_flag==1)
		killwindow FlagPanel
	endif
	
	newpanel/N=FlagPanel/W=(150,80,2000,1000)/K=1

	SetDataFolder root:ACMCC_Export:
	wave ACSM_time, OM, NO3, SO4, NH4, Cl, numflag_OM,numflag_NO3,numflag_SO4,numflag_NH4,numflag_Cl,validbool_OM,validbool_NO3,validbool_SO4,validbool_nh4,validbool_Cl
	wave CS_bool
	wave OneWave, AutoFlagBool_OM, AutoFlagBool_NO3, AutoFlagBool_SO4, AutoFlagBool_NH4, AutoFlagBool_Cl
	Display/HOST=FlagPanel/W=(0.05,0.1,0.95,0.95)/L=L1 OM vs ACSM_time
	AppendToGraph/L=L2 NO3 vs ACSM_time
	AppendToGraph/L=L3 NH4 vs ACSM_time
	AppendToGraph/L=L4 SO4 vs ACSM_time
	AppendToGraph/L=L5 Cl vs ACSM_time
	ModifyGraph axisEnab(L1)={0,0.19},axisEnab(L2)={0.21,0.39}
	ModifyGraph axisEnab(L3)={0.41,0.59},axisEnab(L4)={0.61,0.79}
	ModifyGraph axisEnab(L5)={0.81,1},freePos(L1)={0,bottom},freePos(L2)={0,bottom}
	ModifyGraph freePos(L3)={0,bottom},freePos(L4)={0,bottom},freePos(L5)={0,bottom}
	Label bottom " "
	ModifyGraph rgb(OM)=(26112,52224,0)
	ModifyGraph rgb(NO3)=(0,34816,52224)
	ModifyGraph rgb(NH4)=(52224,0,0)
	ModifyGraph rgb(NH4)=(65280,43520,0),rgb(SO4)=(52224,0,0)
	ModifyGraph rgb(Cl)=(65280,32768,58880)
	AppendToGraph/R=R1 numflag_OM vs ACSM_time
	ModifyGraph axisEnab(R1)={0,0.19},freePos(R1)={0,kwFraction}
	ModifyGraph mode(numflag_OM)=1
	ModifyGraph zColor(numflag_OM)={ValidBool_OM,*,*,cindexRGB,0,CS_Bool}
	AppendToGraph/R=R2 numflag_NO3 vs ACSM_time
	AppendToGraph/R=R3 numflag_NH4 vs ACSM_time
	AppendToGraph/R=R4 numflag_SO4 vs ACSM_time
	AppendToGraph/R=R5 numflag_Cl vs ACSM_time
	ModifyGraph axisEnab(R2)={0.21,0.39},freePos(R2)={0,kwFraction}
	ModifyGraph mode(numflag_NO3)=1
	ModifyGraph zColor(numflag_NO3)={ValidBool_NO3,*,*,cindexRGB,0,CS_Bool}
	ModifyGraph axisEnab(R3)={0.41,0.59},freePos(R3)={0,kwFraction}
	ModifyGraph mode(numflag_NH4)=1
	ModifyGraph zColor(numflag_NH4)={ValidBool_NH4,*,*,cindexRGB,0,CS_Bool}
	ModifyGraph axisEnab(R4)={0.61,0.79},freePos(R4)={0,kwFraction}
	ModifyGraph mode(numflag_SO4)=1
	ModifyGraph zColor(numflag_SO4)={ValidBool_SO4,*,*,cindexRGB,0,CS_Bool}
	ModifyGraph axisEnab(R5)={0.81,1},freePos(R5)={0,kwFraction}
	ModifyGraph mode(numflag_Cl)=1
	ModifyGraph zColor(numflag_Cl)={ValidBool_Cl,*,*,cindexRGB,0,CS_Bool}
	
	ReorderTraces OM,{numflag_OM,numflag_NO3,numflag_NH4,numflag_SO4,numflag_Cl}
	
	ModifyGraph lsize(numflag_OM)=1.5,lsize(numflag_NO3)=1.5,lsize(numflag_NH4)=1.5, lsize(numflag_SO4)=1.5,lsize(numflag_Cl)=1.5
	
	AppendToGraph/R=R11 OneWave vs ACSM_time
	ModifyGraph axisEnab(R11)={0,0.19},freePos(R11)={0,kwFraction}
	ModifyGraph mode(OneWave)=2,lsize(OneWave)=6
	ModifyGraph axRGB(R11)=(65535,65535,65535),tlblRGB(R11)=(65535,65535,65535)
	ModifyGraph alblRGB(R11)=(65535,65535,65535)
	ModifyGraph zColor(OneWave)={AutoFlagBool_OM,0,6,EOSSpectral11,1}
	ModifyGraph axisEnab(R11)={0.17,0.19}
	ModifyGraph lsize(OneWave)=6
	
	AppendToGraph/R=R21 OneWave vs ACSM_time
	ModifyGraph axisEnab(R21)={0,0.19},freePos(R21)={0,kwFraction}
	ModifyGraph mode(OneWave#1)=2,lsize(OneWave#1)=6
	ModifyGraph axRGB(R21)=(65535,65535,65535),tlblRGB(R21)=(65535,65535,65535)
	ModifyGraph alblRGB(R21)=(65535,65535,65535)
	ModifyGraph zColor(OneWave#1)={AutoFlagBool_NO3,0,6,EOSSpectral11,1}
	ModifyGraph axisEnab(R21)={0.37,0.39}
	ModifyGraph lsize(OneWave#1)=6
	
	AppendToGraph/R=R31 OneWave vs ACSM_time
	ModifyGraph axisEnab(R31)={0,0.19},freePos(R31)={0,kwFraction}
	ModifyGraph mode(OneWave#2)=2,lsize(OneWave#2)=6
	ModifyGraph axRGB(R31)=(65535,65535,65535),tlblRGB(R31)=(65535,65535,65535)
	ModifyGraph alblRGB(R31)=(65535,65535,65535)
	ModifyGraph zColor(OneWave#2)={AutoFlagBool_NH4,0,6,EOSSpectral11,1}
	ModifyGraph axisEnab(R31)={0.57,0.59}
	ModifyGraph lsize(OneWave#2)=6
	
	AppendToGraph/R=R41 OneWave vs ACSM_time
	ModifyGraph axisEnab(R41)={0,0.19},freePos(R41)={0,kwFraction}
	ModifyGraph mode(OneWave#3)=2,lsize(OneWave#3)=6
	ModifyGraph axRGB(R41)=(65535,65535,65535),tlblRGB(R41)=(65535,65535,65535)
	ModifyGraph alblRGB(R41)=(65535,65535,65535)
	ModifyGraph zColor(OneWave#3)={AutoFlagBool_SO4,0,6,EOSSpectral11,1}
	ModifyGraph axisEnab(R41)={0.77,0.79}
	ModifyGraph lsize(OneWave#3)=6
	
	AppendToGraph/R=R51 OneWave vs ACSM_time
	ModifyGraph axisEnab(R51)={0,0.19},freePos(R51)={0,kwFraction}
	ModifyGraph mode(OneWave#4)=2,lsize(OneWave#4)=6
	ModifyGraph axRGB(R51)=(65535,65535,65535),tlblRGB(R51)=(65535,65535,65535)
	ModifyGraph alblRGB(R51)=(65535,65535,65535)
	ModifyGraph zColor(OneWave#4)={AutoFlagBool_SO4,0,6,EOSSpectral11,1}
	ModifyGraph axisEnab(R51)={0.97,0.99}
	ModifyGraph lsize(OneWave#4)=6
	
	TextBox/C/N=text1/F=0/A=MC "\\W516 InletP"
	TextBox/C/N=text1 "\\K(0,34816,52224)\\W516 InletP   \\K(0,43520,65280)\\W516 InletP variation   \\K(32768,54528,65280)\\W516 AB too low   \\K(57600,58112,39680)\\W51";DelayUpdate
	AppendText/N=text1 /NOCR "6AB low   \\K(65280,54528,32768)\\W516 VapT   \\K(52224,17408,0)\\W516 Conc < -3*LOD   \\K(39168,0,0)\\W516 Conc variation"
	
	
	PopupMenu FlagList_PUM title="\\f01Flag List",pos={10,10},value=FlagItemList(),fsize=18
	PopupMenu Var_PUM title="\\f01Apply on ",pos={10,50},value=VarItemList(),fsize=18
	Button ApplyFlag_Butt, title="\\f01Apply & Update", pos={250,40},fSize=14,size={150,35},font="Arial", fcolor=(43264,58112,43008),proc=ApplyFlag_proc
	CheckBox HideInvalid_CB, title="Hide Invalid", pos={425,50}, fsize=14,proc=HideInvalid_proc


	
End Function

Function/S FlagItemList()
	String list
	SVAR/Z FlagList=root:ACMCC_Export:FlagList
	list = FlagList
	return list
End

Function/S VarItemList()
	String list
	SVAR/Z VarName=root:ACMCC_Export:VarName
	list = VarName
	return list
End


Function HideInvalid_proc(ctrlName,checked) : CheckBoxControl
	string ctrlName
	variable checked
	//ControlInfo HideInvalid_CB
	//if(V_value==1)
	wave ACSM_time, OM, NO3, SO4, NH4, Cl, numflag_OM,numflag_NO3,numflag_SO4,numflag_NH4,numflag_Cl,validbool_OM,validbool_NO3,validbool_SO4,validbool_nh4,validbool_Cl
	wave CS_bool
	if (checked==1)
		duplicate/O OM OM_temp
		duplicate/O NO3 NO3_temp
		duplicate/O SO4 SO4_temp
		duplicate/O NH4 NH4_temp
		duplicate/O Cl Cl_temp
		
		OM_temp[]=(validbool_OM[p]==1) ? NaN : OM_temp[p]
		NO3_temp[]=(validbool_NO3[p]==1) ? NaN : NO3_temp[p]
		SO4_temp[]=(validbool_SO4[p]==1) ? NaN : SO4_temp[p]
		NH4_temp[]=(validbool_NH4[p]==1) ? NaN : NH4_temp[p]
		Cl_temp[]=(validbool_Cl[p]==1) ? NaN : Cl_temp[p]
		
		ReplaceWave trace= OM, OM_temp
		ReplaceWave trace= NO3, NO3_temp
		ReplaceWave trace= SO4, SO4_temp
		ReplaceWave trace= NH4, NH4_temp
		ReplaceWave trace= Cl, Cl_temp
		
		
	elseif(checked==0)
		wave OM_temp,NO3_temp,SO4_temp,NH4_temp,Cl_temp
		ReplaceWave trace= OM_temp, OM
		ReplaceWave trace= NO3_temp, NO3
		ReplaceWave trace= SO4_temp, SO4
		ReplaceWave trace= NH4_temp, NH4
		ReplaceWave trace= Cl_temp, Cl
	endif
	Killwaves/Z Cl_temp, NH4_temp, SO4_temp,  NO3_temp, OM_temp

End Function

Function ApplyFlag_proc(ctrlName) : ButtonControl
	string ctrlName
	ControlInfo FlagList_PUM
	string Flag_str=S_value
	string Flag_nb_str=flag_str[0,2]
	variable flag_nb_var=str2num(Flag_nb_str)
	
	string IsValid=flag_str[6,6]
	
	ControlInfo Var_PUM
	string Var_str=S_value

	SetDataFolder root:ACMCC_Export:
	wave ACSM_time,OM,NO3,NH4,SO4,Cl,numflag_OM,numflag_NO3,numflag_SO4,numflag_NH4,numflag_Cl,ValidBool_OM,ValidBool_NO3,ValidBool_SO4,ValidBool_NH4,ValidBool_Cl
	GetMarquee bottom
	variable MinIndex,MaxIndex
	MinIndex=BinarySearch(ACSM_time,V_left)
	MaxIndex=BinarySearch(ACSM_time,V_right)
	
	if(stringmatch(Var_str,"all"))
		numflag_OM[MinIndex,MaxIndex]=flag_nb_var
		numflag_NO3[MinIndex,MaxIndex]=flag_nb_var
		numflag_SO4[MinIndex,MaxIndex]=flag_nb_var
		numflag_NH4[MinIndex,MaxIndex]=flag_nb_var
		numflag_Cl[MinIndex,MaxIndex]=flag_nb_var
	
		if(stringmatch(IsValid,"V"))
			ValidBool_OM[MinIndex,MaxIndex]=0
			ValidBool_NO3[MinIndex,MaxIndex]=0
			ValidBool_SO4[MinIndex,MaxIndex]=0
			ValidBool_NH4[MinIndex,MaxIndex]=0
			ValidBool_Cl[MinIndex,MaxIndex]=0
			
		elseif(stringmatch(IsValid,"I"))
			ValidBool_OM[MinIndex,MaxIndex]=1
			ValidBool_NO3[MinIndex,MaxIndex]=1
			ValidBool_SO4[MinIndex,MaxIndex]=1
			ValidBool_NH4[MinIndex,MaxIndex]=1
			ValidBool_Cl[MinIndex,MaxIndex]=1
		endif
	elseif(stringmatch(Var_str,"OM"))
		numflag_OM[MinIndex,MaxIndex]=flag_nb_var
		if(stringmatch(IsValid,"V"))
			ValidBool_OM[MinIndex,MaxIndex]=0
		elseif(stringmatch(IsValid,"I"))
			ValidBool_OM[MinIndex,MaxIndex]=1
		endif
	elseif(stringmatch(Var_str,"NO3"))
		numflag_NO3[MinIndex,MaxIndex]=flag_nb_var
		if(stringmatch(IsValid,"V"))
			ValidBool_NO3[MinIndex,MaxIndex]=0
		elseif(stringmatch(IsValid,"I"))
			ValidBool_NO3[MinIndex,MaxIndex]=1
		endif
	elseif(stringmatch(Var_str,"SO4"))
		numflag_SO4[MinIndex,MaxIndex]=flag_nb_var
		if(stringmatch(IsValid,"V"))
			ValidBool_SO4[MinIndex,MaxIndex]=0
		elseif(stringmatch(IsValid,"I"))
			ValidBool_SO4[MinIndex,MaxIndex]=1
		endif
	elseif(stringmatch(Var_str,"NH4"))
		numflag_NH4[MinIndex,MaxIndex]=flag_nb_var
		if(stringmatch(IsValid,"V"))
			ValidBool_NH4[MinIndex,MaxIndex]=0
		elseif(stringmatch(IsValid,"I"))
			ValidBool_NH4[MinIndex,MaxIndex]=1
		endif
	elseif(stringmatch(Var_str,"Cl"))
		numflag_Cl[MinIndex,MaxIndex]=flag_nb_var
		if(stringmatch(IsValid,"V"))
			ValidBool_Cl[MinIndex,MaxIndex]=0
		elseif(stringmatch(IsValid,"I"))
			ValidBool_Cl[MinIndex,MaxIndex]=1
		endif
	endif

	//ControlInfo HideInvalid_CB
	//HideInvalid_proc("",V_value)	

End Function


Function Set_Threshold()
	string variable2use
	string varList="OM;NO3;NH4;SO4;Cl"
	
	prompt variable2use, "component:", popup, varList
	doprompt "On which component would you like to apply the threshold ?", variable2use

	variable axisNb=whichlistitem(variable2use,varList)+1
	string axis2use="L"+num2str(axisNb)
	
	SetDataFolder root:ACMCC_Export:
	wave ACSM_time
	wave Component = $variable2use
	wave numflag_component=$("numflag_"+variable2use)
	wave validBool_component=$("ValidBool_"+variable2use)
	
	GetMarquee $axis2use
	if(V_top>0)
		numflag_component[]=(Component[p]>V_top) ? 459 : numflag_component[p]
		ValidBool_component[]=(Component[p]>V_top) ? 1 : ValidBool_component[p]
	elseif(V_top<0)
		numflag_component[]=(Component[p]<V_top) ? 459 : numflag_component[p]
		ValidBool_component[]=(Component[p]<V_top) ? 1 : ValidBool_component[p]
	endif
End Function


Function FindYearToExport()

	NVAR/Z YearToExport=root:ACMCC_Export:YearToExport
	wave ACSM_time=root:ACMCC_Export:ACSM_time
	
	SetDataFolder root:ACMCC_Export:
	Make/O/N=(numpnts(ACSM_time)) YearW
	variable i
	for (i=0;i<numpnts(ACSM_time);i+=1)
		yearW[i]=ACMCC_year(ACSM_time[i])
	endfor
	
	
	variable nb_bins=max(2,wavemax(YearW)-wavemin(YearW))
	Make/O/N=(nb_bins) YearW_Hist,YearW_Occurence
	YearW_Hist[]=wavemin(YearW)+p
	
	Histogram/B={wavemin(YearW),1,nb_bins} YearW,YearW_Occurence
	
	WaveStats/Q YearW_Occurence
	YearToExport=YearW_Hist[V_maxRowLoc]
	

End Function


Function ACMCC_year(dt)
	variable dt					// Input date/time value
 
	String shortDateStr = Secs2Date(dt, -1)		// <day-of-month>/<month>/<year> (<day of week>)
 
	Variable dayOfMonth, month, year, dayOfWeek
	sscanf shortDateStr, "%d/%d/%d (%d)", dayOfMonth, month, year, dayOfWeek
 
	return year
End


Function ExportTxt_proc(CtrlName) : ButtonControl
	string ctrlName
	
	variable i
	i=0
	
	SVAR/Z FileName_str=root:ACMCC_Export:FileName_str
	SVAR/Z FlagName_str=root:ACMCC_Export:FlagName_str
	
	SetDataFolder root:ACMCC_Export
	string saveWavesList="ACSM_time_txt;OM;NO3;SO4;NH4;Cl;IE_NO3;RIE_OM;RIE_NO3;RIE_SO4;RIE_NH4;RIE_Cl;CE;"
	saveWavesList+="ABref;AB_total;Flow_css;n_total;n_bkgd;baseline;threshold;mzCal_p1;mzCal_p2;"
	saveWavesList+="ratio40div28;Lens;Pulser;Lens2;IonEx;Lens1;HB;IonChamber;Filament_Emm;Detector;"
	saveWavesList+="Turbo_speed;Turbo_power;Fore_pc;Press_inlet;Heater_PWM;Heater_I;Heater_V;Heater_T;"
	saveWavesList+="Sampling_Flowrate;RH_In;RH_Out;T_In;T_Out;"
	saveWavesList+="OM_err;NO3_err;SO4_err;NH4_err;Cl_err;"
	saveWavesList+="Tof_QuadW;LensW;VaporizerW;"
	
	SetDataFolder root:ACMCC_Export
	wave/T VaporizerW,LensW,ToF_QuadW,StationNameW,ACSM_time_txt
	SVAR/Z SN_str=root:ACMCC_Export:SN_str
	NVAR/Z YearToExport=root:ACMCC_Export:YearToExport
	string filename=StationNameW[0]+"_ACSM-"+SN_str+"_"+num2str(YearToExport)+".txt"
	FileName_str=filename
	string Flagfilename=StationNameW[0]+"_ACSM-"+SN_str+"_FLAGS_"+num2str(YearToExport)+".txt"
	FlagName_str=Flagfilename
	SVAR/Z NextCloud_path=root:ACMCC_Export:NextCloud_path
	NewPath/O/Q SaveFolderPath, NextCloud_path
	
	for (i=0;i<itemsInList(saveWavesList);i+=1)
		wave w = $stringFromList(i,saveWavesList)
		if (i==0)
			Edit /N=ExportTable w
		else
			AppendToTable /W=ExportTable w
		endif
	endfor
	//ModifyTable/W=ExportTable format(ACSM_time)=8
	ModifyTable title(ACSM_time_txt)="ACSM_time"
	saveTableCopy/O/T=1/P=SaveFolderPath/W=ExportTable as filename
	KillWindow ExportTable
	
	saveWavesList=""
	saveWavesList+="ACSM_time_txt;numflag_OM;numflag_NO3;numflag_SO4;numflag_NH4;numflag_Cl;"
	for (i=0;i<itemsInList(saveWavesList);i+=1)
		wave w = $stringFromList(i,saveWavesList)
		if (i==0)
			Edit /N=FlagTable w
		else
			AppendToTable /W=FlagTable w
		endif
	endfor
	//ModifyTable/W=FlagTable format(ACSM_time)=8
	ModifyTable title(ACSM_time_txt)="ACSM_time"
	saveTableCopy/O/T=1/P=SaveFolderPath/W=FlagTable as Flagfilename
	KillWindow FlagTable


End Function


Function ExecuteScript_proc(ctrlName) : ButtonControl
	string ctrlName
	
	SVAR/Z FileName_str=root:ACMCC_Export:FileName_str
	SVAR/Z FlagName_str=root:ACMCC_Export:FlagName_str
	SVAR/Z NextCloud_path=root:ACMCC_Export:NextCloud_path
	SVAR/Z Script_path=root:ACMCC_Export:Script_path
	SVAR/Z Python_path=root:ACMCC_Export:Python_path
	
	string ParsedScript_path=ParseFilePath(5,Script_path,"\\",0,0)
	
	wave/T StationNameW=root:ACMCC_Export:StationNameW
	string station=StationNameW[0]
	
	string Batch_str=""
	Batch_str+="@echo off;"
	Batch_str+="REM set conda_root='C:\Users\lhrivell\Anaconda3\';"//C:\Users\lhrivell\Anaconda3\
	Batch_str+="REM echo '- load conda env -';"
	Batch_str+="REM call %conda_root%\Scripts\activate.bat %conda_root%;"
	Batch_str+="echo '- start process -';"
	Batch_str+="cd " + ParsedScript_path+";"
//	Batch_str+="python C:\\Users\\lhrivell\\actris_acsm_converter\\src\\rawto012.py data"
	Batch_str+="python src\\rawto012.py data\\" +station
	Batch_str+="\\in\\" + FileName_str
	Batch_str+=" data\\" +station
	Batch_str+="\\in\\" + FlagName_str
	Batch_str+=" data\\" +station
	Batch_str+="\\out\\;"
	
	print Batch_str
	//Batch_str+="python src\rawto012.py tests\SIRTA\in\SIRTA_ACSM-140113_2021.txt tests\SIRTA\in\SIRTA_ACSM-140113_FLAGS_2021.txt tests\SIRTA\out\;"
	//Batch_str+="python src\rawto012.py D:\ToF_ACSM_010\data\SIRTA\in\SIRTA_ACSM-010_2025.txt D:\ToF_ACSM_010\data\SIRTA\in\SIRTA_ACSM-010_FLAGS_2025.txt D:\ToF_ACSM_010\data\SIRTA\out\;;"
	
	
	//Batch_str+="cd " + Script_path+";"
	//Batch_str+="py src/rawto012.py "+NextCloud_path+FileName_str+" "+NextCloud_path+FileName_str+" ~/test;"
	Batch_str+="pause"
	Make/T/O/N=(ItemsInList(batch_str, ";")) batch_txt
	batch_txt = StringFromList(p, batch_str, ";")
	
	Newpath/O/Q BatchPath, Script_path
	Save/T/G/O/M="\r\n"/P=BatchPath Batch_txt as "ACSM_converter.bat"
	
	//executescripttext/Z/B "\"C:\\Users\\jepetit\\Downloads\\actris_acsm_converter-master\\ACSM_converter.bat"
//	string batch_path=Script_path+"ToFACSMconverter.bat"
	string batch_path=ParsedScript_path+"ToFACSMconverter.bat"//ACSM_converter.bat"
	
	string batch_txt1
	//sprintf batch_txt1, "cmd.exe /C \"%s\"", "C:\Users\jepetit\Downloads\actris_acsm_converter-master\ACSM_converter.bat"
	sprintf batch_txt1, "cmd.exe /C \"%s\"", batch_path

	executescripttext/Z/B batch_txt1
	
	
End Function


Function CheckDoublonAndNaN()

	SetDataFolder root:ToF_ACSM
	wave DateW, Mx
	Make/O/N=(numpnts(DateW)) d_date
	
	d_date[0]=999
	
	variable i
	for(i=1;i<numpnts(DateW);i+=1)
		d_date[i]=DateW[i]-DateW[i-1]
	endfor

	d_date[]=(numtype(DateW[p])==2) ? 0 : d_date[p]
	
	d_date[]=(d_date[p]!=0) ? 1 : d_date[p]
	
	if (sum(d_date)!=numpnts(d_date))
		Extract/O Mx, Mx_corr, (d_date[p]!=0)
		Redimension/N=(sum(d_date),dimsize(Mx,1)) Mx_corr
	
		duplicate/O Mx_corr, Mx
	endif
	
	Killwaves/Z Mx_corr

End Function


Function Standalone_CorrectDate()

	SetDataFolder root:ACMCC_Export
	wave ACSM_time
	variable i
	wave DateW=root:ToF_ACSM:DateW
	
	if (dimsize(DateW,0)==dimsize(ACSM_time,0))
	
		duplicate/O DateW, ACSM_time
		Make/N=(numpnts(DateW))/O/T ACSM_time_txt
		For (i=0;i<(numpnts(DateW));i+=1)
			string year=ACMCC_ExtractDateInfo(DateW[i],"year")
			string month=ACMCC_ExtractDateInfo(DateW[i],"month")
			string dayOfMonth=ACMCC_ExtractDateInfo(DateW[i],"dayOfMonth")
			string hour=ACMCC_ExtractTimeInfo(DateW[i],"hour")
			string minute=ACMCC_ExtractTimeInfo(DateW[i],"minute")
			string second=ACMCC_ExtractTimeInfo(DateW[i],"second")
		
			ACSM_time_txt[i]=year+"/"+month+"/"+dayofmonth+" "+hour+":"+minute+":"+second
		
		endfor	
	else
		DoAlert/T="WARNING" 0,"Date waves dimension does not match. Please verify."
	endif

End Function




