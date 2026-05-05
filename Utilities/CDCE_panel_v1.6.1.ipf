#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3				// Use modern global access method and strict wave access
#pragma DefaultTab={3,20,4}		// Set default tab width in Igor Pro 9 and later

//Sart of CE panel

//line to integrate the button
//Button CEpanel_Butt, title="\\f01 5.CDCE panel", pos={77,312},fSize=14,size={110,25},font="Arial", fcolor=(52224,34816,0), proc=CE_ButtonProc


//based on 1.52 CDCE Middlebrook AMS UMR Panel
Function CE_ButtonProc(ctrlName) : ButtonControl
	String ctrlName

//	sq_GetIndexNotDoneYet()
	sq_CreatePhaseDepCE() 		// do the calculations for CDCE

End


// CE ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Function taken from A.M. Middlebrook, R. Bahreini, J.L. Jimenez, and M.R. Canagaratna. 
// Evaluation of Composition-Dependent Collection Efficiencies for the Aerodyne Aerosol 
// Mass Spectrometer using Field Data. Aerosol Science and Technology, 46, 258–271, 2012
// DOI:10.1080/02786826.2011.620041 PDF (March 1, 2012) 
// Donna S cleaned up and altered slightly October 2011
//
// Creates the following waves and puts them in the root folder
// PredNH4_CE1 = predicted NH4 with a collection efficiency of 1
// NH4_MeasToPredict = ratio of NH4 measured to predicted (anion and cation balance)
// ANMF = ammonium nitrate mass fraction
// CE_dry = collection efficiency of theoretically dry particles
// CE_fPhase = collection efficiency as a function of its phase, or composition, i.e. H2SO4 droplets vs pure dry HNO3

static constant Mass_NH4=18
static constant Mass_SO4=96
static constant Mass_NO3=62
static constant Mass_Chl=35.45
static constant Mass_NH4NO3=80
static constant DEFAULTCE=0.5  //1.65L

//1.52
// Creates the phase dependent CE panel
Function sq_CreatePhaseDepCE() 

	DoWindow/F CE_Panel
	if (V_flag)
		return 0
	endif
	
	NewDataFolder/o root:CE
	sq_initializeGlobalSVar("root:CE:CEStatsStr", "")
	
//	String/G PathToConcData="root:"
	
	NewPanel/k=1/N=CE_Panel /W=(117,94,780,430) as "CE_Panel"
//	gen_setFont("CE_Panel", 12)
	ModifyPanel fixedSize=1		//1.57L
	ShowTools/A
	SetDrawLayer UserBack
	SetDrawEnv fsize= 18,fstyle= 1
	DrawText 5,22,"Composition Dependent CE"
	SetDrawEnv fsize= 14
//	DrawText 7,38, SQVERSION // "ver. 1.0"		//1.65L
	SetDrawEnv fsize= 10, fstyle=1
	DrawText 6,38,"*Only applicable to ambient, non free trop. data*"
	SetDrawEnv fsize= 10
	DrawText 6,75,"Step 0. Verify your NH4 RIE."
	SetDrawEnv fsize= 10
	DrawText 10,170,"in µg/m3, with CE=1, AB corrected"
	SetDrawEnv fsize= 10
//	DrawText 5,334,"Step 7. (Opt.) Enter CE_fphase in Batch table."
//	SetDrawEnv fsize= 10
	DrawText 5,201,"Step 3. (Optional)"
	SetDrawEnv fsize= 10
	DrawText 5,229,"Step 5. (Optional)"
	SetDrawEnv fsize= 10
	DrawText 2,186,"if NH4<min level, default CE (step 4) will be used"
	SetDrawEnv fsize= 11
	DrawText 5,216,"Step 4. Notice that the default CE will be 0.5"

//	SetVariable Set_PathToConcData,title="Path to conc.",pos={5,23},size={210,19},value=PathToConcData,fSize=12,noedit=1,font="Arial"
//	Button Set_PathToConcData_button,title="\\f01SET",pos={217,22},size={40,20},fSize=14,proc=Set_PathToConcData_proc,fColor=(39168,39168,39168),font="Arial"


	Button ceReviewNH4RIE,pos={168.00,60.00},size={70.00,18.00},proc=CheckCalibButtonCDCE_proc
	Button ceReviewNH4RIE,title="UMR RIEs",fSize=10
	Button buttonCalcTSforCE,pos={4,80},size={205,20},fsize=10,proc=sq_butt_CalcTS_CDCE,title="Step 1. Calculate aerosol TS with CE=1"
	Button buttonCalcTSforCE,fColor=(65280,43520,0)
	Button CEis1_TSGraph,pos={213,80},size={40,20},fsize=10,proc=sq_create_CEis1_TSgraph,title="Graph"
	Button sq_butt_CENH4AcidityGraph,pos={5.00,100.00},size={80.00,20.00},proc=sq_butt_CENH4AcidityGr
	Button sq_butt_CENH4AcidityGraph,title="NH\\B4\\M meas/pred",fSize=10


	GroupBox groupParams,pos={1,126},size={255,153},fsize=11,title="CDCE user parameters"
	GroupBox groupParams,fColor=(1,1,1)
	GroupBox groupOptionalPrelim,pos={0,44},size={255,78},fsize=11,title="Preliminary calculations using CE=1"
	GroupBox groupOptionalPrelim,fColor=(1,1,1)

	//SetVariable CE4LowNH4,pos={5,218},size={245,16},fsize=10,title="Step 4. Set default CE (when comp. indep.)"
	//SetVariable CE4LowNH4,format="%1.2f",limits={0,10,0},fsize=10,value= _NUM:0.45 // 1.63K
	SetVariable NH4DetLim,pos={8.00,140.00},size={249.00,16.00},bodyWidth=35
	SetVariable NH4DetLim,title="Step 2. Set min. NH4 level to LOD for calcs"
	SetVariable NH4DetLim,fSize=11,limits={0,1,0},format="%1.3f",value=_NUM:NaN,noedit=1//,
//	Print numLOD
//	SetVariable NH4DetLim,fSize=11,format="%1.3f",limits={0,1,0},value=_NUM:Nan
	Button Butt_SetNH4LOD,pos={202,155},size={50,20},fsize=10,proc=SetNH4LOD,title="NH4 LOD"
	CheckBox checkUseRH,pos={105,216},size={145,14},fsize=10,title="Use RH of sampling line, %"
	CheckBox checkUseRH,value= 0
	CheckBox checkUseSmooth,pos={97,186},size={112,14},fsize=10,title="Num. pts. to smooth"
	CheckBox checkUseSmooth,value= 0
	SetVariable Num2SmoothVar,pos={220,186},size={30,20},fsize=10,bodyWidth=40,value=_NUM:0
	SetVariable setvarRH,pos={23,235},size={230,16},fsize=10,title="Indicate RH wave of ACSM sampling line",size={230,16}
	SetVariable setvarRH,value= _STR:""

	Button buttonCalcCE,pos={5,283},size={240,20},fsize=10,proc=sq_butt_Calc_CDCE,title="Step 6. Calculate composition dependent CE"
	Button buttonCalcCE,fColor=(65280,43520,0)

	Button buttonCEtoExport,pos={5,306},size={240,20},fsize=10,proc=CDCE2Export,title="Step 7. Move CDCE conc. to ACMCC_export"
	Button buttonCEtoExport,fColor=(65280,43520,0)

	Button ceSetInflectionPoints,pos={3.00,256.00},size={245.00,18.00},proc=sq_butt_CEAdvPanel
	Button ceSetInflectionPoints,title="Advanced users only - Set inflection points, default CE"
	Button ceSetInflectionPoints,fSize=10

	TabControl tabCE,pos={258,0},size={400,330},proc=Sq_CETabProc
//	TabControl tabCE,tabLabel(0)="CE Hist",tabLabel(1)="CDCE vs CE"
	TabControl tabCE,tabLabel(0)="CE Hist",tabLabel(1)="CE Stats",tabLabel(2)="NH4"
	TabControl tabCE,tabLabel(3)="NO3",tabLabel(4)="SO4",tabLabel(5)="OM"
	TabControl tabCE,tabLabel(6)="Cl",value= 0

	// begin tab dependent controls

	TitleBox titleCEStats,pos={262,22},size={188,65},fsize=10,disable=1,frame=0
	TitleBox titleCEStats,variable= root:CE:CEstatsStr
	TitleBox titleTSLegend,pos={495,60},size={100,52},fsize=10,frame=0,title="Gray:CE=user default\r(via mult. offset)\rColors indicate which\rfactor controls CE"
	TitleBox titleTSLegend,frame=0, disable=1
	TitleBox titleTSLegendStats,pos={490,25},size={123,26},fsize=10,disable=1,frame=0

//	PopupMenu ams_todolist_pop,pos={7,96},size={148,21},fsize=10,bodyWidth=120,proc=sq_pop_toDoList,title="Todo"
//	PopupMenu ams_todolist_pop,fSize=10,size={145.00,19.00}
//	PopupMenu ams_todolist_pop,mode=1,popvalue="all",value= #"root:panel:sq_toDoList+\"Get List;\"\t"
		
	Button sq_but_SQ_CECorrGraph,pos={492,121},size={40,20},fsize=10,proc=sq_butt_popThis,title="<- Pop"
	Button sq_but_SQ_CETSGraph,pos={574,121},size={40,20},fsize=10,proc=sq_butt_popThis,title="Pop v"   //1.65L
	Button sq_but_SQ_CEHistGraph title="Pop ^",pos={472,120},fsize=10,proc=sq_butt_popThis,size={40,20}, disable=1

	Button sq_but_SQ_AcidityHistGraph,pos={566,140},size={40,20},fsize=10,disable=1,proc=sq_butt_popThis,title="^ Pop"
	Button sq_but_SQ_ANMFOrgMFHistGraph,pos={307,140},size={40,20},fsize=10,disable=1,proc=sq_butt_popThis,title="Pop v"
	Button sq_but_SQ_RelHumHistGraph,pos={521,140},size={40,20},fsize=10,disable=1,proc=sq_butt_popThis,title="Pop v"
	Button sq_but_SQ_NH4DetLimHistGraph,pos={262,140},size={40,20},fsize=10,disable=1,proc=sq_butt_popThis,title="Pop ^"
	Button sq_but_SQ_CEfphaseTable,pos={393,140},size={100,20},fsize=10,disable=1,proc=sq_butt_popThis,title="CE_fphase Table"

	Button sq_but_CETypeFlagLegend,pos={264,104},size={130,20},fsize=10,proc=sq_butt_CETypeFlagLegend,title="Pop CETypeFlag Legend",disable=1

	// get paramters from last time this was calculated.
	wave/z ANMF_hist = root:CE:ANMF_hist		// any one of several waves could do to check values.
	if (WaveExists(ANMF_hist))		// things were calculated before.  Try to find the last values.
		wave/z CE_fphase = root:CE_fphase		// any one of several waves could do to check values.
		if (WaveExists(CE_fphase) && strlen(Note(CE_fphase))>0)		// assume that nothing has been tampered with
			string CEnote = Note(CE_fphase)
//			print CEnote
			SetWindow CE_panel userdata(defaultCE)=StringByKey("defaultCE",CEnote)
			SetWindow CE_panel userdata(NH4DetLim)=StringByKey("NH4DetLim",CEnote)
			SetWindow CE_panel userdata(todo)=StringByKey("todo",CEnote)
			SetWindow CE_panel userdata(UseRH)=StringByKey("UseRH",CEnote)
			SetWindow CE_panel userdata(RHwave)=StringByKey("RHwave",CEnote)
			SetWindow CE_panel userdata(UseSmooth)=StringByKey("UseSmooth",CEnote)
			SetWindow CE_panel userdata(num2smooth)=StringByKey("num2smooth",CEnote)

//			SetVariable CE4LowNH4,value = _NUM:(str2num(StringByKey("defaultCE",CEnote)))  //1.65L
//			SetVariable NH4DetLim,value= _NUM:(str2num(StringByKey("NH4DetLim",CEnote)))
			SetVariable NH4DetLim,value= _NUM:(str2num(StringByKey("NH4DetLim",CEnote)))
			CheckBox checkUseRH,value= str2num(StringByKey("UseRH",CEnote))
			SetVariable setvarRH,value= _STR:(StringByKey("RHwave",CEnote))					
			CheckBox checkUseSmooth,value=str2num(StringByKey("UseSmooth",CEnote))
			SetVariable Num2SmoothVar,value= _NUM:(str2num(StringByKey("num2smooth",CEnote)))
		endif			
	endif

	Sq_CETabProc("tabCE",0)  // update graphs by simulating  selecting the Total tab

End

Function CheckCalibButtonCDCE_proc(ctrlName) : ButtonControl //For tofware
	string ctrlName
	SetDataFolder root:ACMCC_Export
	wave IE_NO3, RIE_OM, RIE_NO3, RIE_NH4, RIE_SO4, RIE_Cl
	redimension/N=1 IE_NO3, RIE_OM, RIE_NO3, RIE_NH4, RIE_SO4, RIE_Cl 
	//Get IE, RIE and CE values
//	Make/N=1/D/O IE_NO3, RIE_NH4, RIE_SO4, RIE_NO3, RIE_OM, RIE_Cl
//	wave RIE_W=root:RIE
//	RIE_OM=RIE_W[0]
//	RIE_NH4=RIE_W[1]
//	RIE_SO4=RIE_W[2]
//	RIE_NO3=RIE_W[3]
//	RIE_Cl=RIE_W[4]
//	wave MC_NO3=root:Masscalib_nitrate
//	IE_NO3=MC_NO3[0]
	
	edit/K=0 IE_NO3, RIE_OM, RIE_NO3, RIE_NH4, RIE_SO4, RIE_Cl
	
End Function

//Function Set_PathToConcData_proc(ctrlName) : ButtonControl
//	String ctrlName
//	SVAR PathToConcData
//	PathToConcData = GetBrowserSelection(0)
//	if(stringmatch(PathToConcData,"root"))
//		PathToConcData="root:"
//	endif
//	SVAR/Z PathToConcWave=root:CE:PathToConcWave
//	PathToExtConcWave=PathToConcData
//End Function

Function sq_findStr(source,str,method)
	wave /t source
	string str
	variable method
	
	variable num,idex,loc=-1,match
	
	num=numpnts(source)
	
	if (strlen(str) && num)
		for (idex=0;idex<num;idex+=1)
			switch (method&15)
				case 0:
					match=strsearch(upperstr(source[idex]),upperstr(str),0)>-1
					break
				case 1:
					match=stringmatch(upperstr(source[idex]),upperstr(str))
					break
				case 2:
					match=strsearch(upperstr(str),upperstr(source[idex]),0)>-1
					break
				case 4:
					match=cmpStr(str,source[idex],1)==0
					break
			endswitch				
			if (match)
				loc=idex
				break
			endif
		endfor
	endif
	return loc

End

//1.52
// In CDCE panel show Acidity plot in FragChecks Panel
Function sq_butt_CENH4AcidityGr(ctrlName) : ButtonControl
	String ctrlName
	Setdatafolder root:ACMCC_export
	wave NH4, SO4, NO3, Cl//, PredNH4
//	wave/z PredNH4 = root:ToF_ACSM:PredNH4
	
//	if (WaveExists(PredNH4))
//		Display  NH4 vs PredNH4
		//sq_butt_popThis("button_FC_NH4MeasPredGraph")
//	else	
		//Killwaves/Z PredNH4
		Make/O/D/N=(numpnts(NH4)) PredNH4, NH4_MeasToPredict, ANMF
		//Duplicate/o SO4 PredNH4, NH4_MeasToPredict, ANMF
		PredNH4=18*(SO4/96*2+NO3/62+Cl/35.45)
		NH4_MeasToPredict=NH4/PredNH4
		Display  NH4 vs PredNH4
//	endif
	Label bottom "NH4 (predicted) µg m\\S-3"
	Label left "NH4 (measured) µg m\\S-3"
	ModifyGraph mode=3,marker=19,useMrkStrokeRGB=1
	SetDrawEnv xcoord= bottom,ycoord= left;DelayUpdate
	DrawLine 0,0,10,10
	SetAxis/A=2/N=1 left 0,*;DelayUpdate
	SetAxis/A/N=1 bottom 0,*
	CurveFit/M=2/W=0/TBOX=(0x300) line, NH4/X=PredNH4/D
End

Function SetNH4LOD(ctrlName) : ButtonControl
	String ctrlName
	wave NH4_blank = root:ACMCC_Export:NH4_blank
	wave blank_flag=root:ACMCC_Export:blank_flag
	wave LOD=root:ACMCC_Export:LOD
//	wave NH4_CE1
	wave NH4_CE1=root:CE:NH4_CE1	
	variable numLOD
	
	if(numpnts(NH4_blank) > 0)//waveExists(blank_flag))
		Extract/O NH4_CE1, NH4_blank,(blank_flag==1)
		WaveStats/Q NH4_blank
		numLOD=3*V_sdev
	Else
		numLOD = 0.51*0.5
	EndIf

//	Killwaves/Z NH4_blank
//	print numLOD,LOD[3] 
//	Variable NH4DetLim
//	NH4DetLim=numLOD
	SetVariable NH4DetLim,fSize=11,limits={0,1,0},format="%1.3f",value=_NUM:numLOD,noedit=1

End Function

// This function generates time series of NH4, SO4, NO3, Chl, Org using a CE of 1 and then calls CalcCE_fPhase.
// The units of the time series waves is ug/m3 
// Can be used with or without the AB correction, no AB is used here.
//1.52
Function sq_butt_CalcTS_CDCE(ctrlName) : ButtonControl
	String ctrlName
	Setdatafolder root:CE
	wave/Z OM= root:ACMCC_Export:OM
	wave/Z SO4= root:ACMCC_Export:SO4
	wave/Z NH4=root:ACMCC_Export:NH4
	wave/Z NO3= root:ACMCC_Export:NO3
	wave/Z Cl= root:ACMCC_Export:Cl
	wave/Z Chl= root:ACMCC_Export:Chl
	wave/Z Org= root:ACMCC_Export:Org
	
	if (WaveExists(Org))
		Duplicate/O Org, OM
	Endif
	if (WaveExists(Chl))
		Duplicate/O Chl, Cl
	Endif
	// we do not use the AB correction by default because we look at ratios and these ratios should be unaffected

	variable NH4Row, SO4Row, NO3Row, ClRow, OMRow
	variable NH4_CEVal, SO4_CEVal, NO3_CEVal, Cl_CEVal, OM_CEVal
	variable killFlag, numTSeries, UseRH=0, detectorFlag
	Wave NH4_CECorr, SO4_CECorr, NO3_CECorr, Cl_CECorr, OM_CECorr
	string RHWaveStr	, CEnote, dataStr
	variable temp_ms0_graphOutputType

	
// CalcCE_fPhase relies on the CE being 1 (or at least identical) for its calculations so save the old values and replace them when we are done.
	//  Jose suggested that we don't change the CE values in the batch table, in case something goes wrong. 
	NH4_CEVal = 0.5
	SO4_CEVal = 0.5
	NO3_CEVal = 0.5
	Cl_CEVal = 0.5
	OM_CEVal = 0.5

	// prepare global variables in squirrel panel in anticipation of calling CalcCE_fPhase  by default CE and RIE will be 1
//	ms0_speclist="NH4,SO4,NO3,Chl,Org"


	Duplicate/O OM, OM_CE1
	Duplicate/O NH4, NH4_CE1
	Duplicate/O SO4, SO4_CE1
	Duplicate/O NO3, NO3_CE1
	Duplicate/O Cl, Cl_CE1

	// in SQ_MSConc we divide by CE so now we multiply
	NH4_CE1 *= NH4_CEVal	
	SO4_CE1 *= SO4_CEVal
	NO3_CE1 *= NO3_CEVal
	Cl_CE1 *= Cl_CEVal
	OM_CE1 *= OM_CEVal
	

//	wave/z root:CE 
//	if (WaveExists(CE))
//		Org_CDCE/=CE
//		NH4_CDCE/=CE
//		SO4_CDCE/=CE
//		NO3_CDCE/=CE
//		Chl_CDCE/=CE
//	endif

	duplicate/o OM_CE1 root:CE:Total_CE1/wave=Total_CE1
 	Total_CE1 = NH4_CE1+SO4_CE1+NO3_CE1+Cl_CE1+OM_CE1

	Duplicate/O OM_CE1, OM_CDCE
	Duplicate/O NH4_CE1, NH4_CDCE
	Duplicate/O SO4_CE1, SO4_CDCE
	Duplicate/O NO3_CE1, NO3_CDCE
	Duplicate/O Cl_CE1, Cl_CDCE
		
	SetWindow CE_panel //userdata(todo)= sq_toDoWvNm
	
	sq_create_CEis1_TSgraph("") 

End



Function butt_popThis(ctrlName) : ButtonControl
	String ctrlName
	
	sq_WindowIsToBePopped(ctrlName[7, strlen(ctrlName)-1])	// the pop button controls MUST be named correctly, such as button_Mz_PpmGraph

End

Function sq_windowIsToBePopped(NameOfPoppedWindow)
string NameOfPoppedWindow

	string WindowStr="", WindowPrefixStr="", FuncStr=""
	
	WindowPrefixStr=NameOfPoppedWindow[0,1]		// for example "mz"
	WindowStr=NameOfPoppedWindow[3, strlen(NameOfPoppedWindow)-1]
	
	DoWindow/F  $NameOfPoppedWindow
	
	if (V_flag==0)
		if (strsearch(lowerStr(NameOfPoppedWindow), "graph", 0)>=0)			
			Display/W=(50,50,450,450)/N=$NameOfPoppedWindow as NameOfPoppedWindow // a blank graph window
			ShowInfo			//1.51Q
		else
			Edit/W=(50,70,450,350)/N=$NameOfPoppedWindow as NameOfPoppedWindow	// a blank table window
		endif
		
		FuncStr =FunctionList(WindowPrefixStr+"_populate_"+WindowStr, ";", "")
		FuncStr=ReplaceString(";", FuncStr, "")
//		print FuncStr
		if (strlen(FuncStr)>0 && ItemsInList(FuncStr)==1)		
			Execute FuncStr+"()"	
		else
			print WindowPrefixStr+"_populate_"+WindowStr
			Abort "Could not find the function named "+WindowPrefixStr+"_populate_"+WindowStr+" to populate the new window - Aborting from sq_WindowIsToBePopped"
		endif
	endif

End



Function/WAVE gen_returnSelectedWave(ControlName, [DFstr, num, minVal, maxVal, nansOK])
string ControlName, DFstr
variable num, minVal, maxVal, nansOK

	string waveStr
	
	ControlInfo $ControlName 
	waveStr=S_value 
	wave/z selWave = $DFstr+waveStr
	if (!waveExists(selWave) && !ParamIsDefault(num) && numpnts(selWave) != num)
		abort "The wave "+waveStr +" either doesn't exist or doesn't have the correct number of points.  Aborting from gen_returnSelectedWave"
	endif
	
	wavestats/m=1/q selWave
	if (!ParamIsDefault(minVal) && V_min<minVal)
		abort "The wave "+waveStr +" detected values <"+num2str(minVal)+ ". Aborting from gen_returnSelectedWave" 
	endif		
	if (!ParamIsDefault(maxVal) && V_max>maxVal)
		abort "The wave "+waveStr +" detected values >"+num2str(maxVal)+ ". Aborting from gen_returnSelectedWave" 
	endif		
	if (!ParamIsDefault(nansOK) && !nansOK && V_numNans>0)
		abort "The wave "+waveStr +" has "+num2str(V_numNans) + " nans. Aborting from gen_returnSelectedWave" 
	endif

	return selWave
End

//1.52
// After generating time series waves of 5 aerosol species with CE=1, find the time dependent CE
Function sq_butt_Calc_CDCE(ctrlName) : ButtonControl
	String ctrlName

	variable numTSeries, UseRH, NH4_DetLimit, varCE_lowNH4, SmoothVar, SmoothTypeVar, UseSmooth=0
	string RHWaveStr, CENote
	 	
	wave NH4_CE1 = root:CE:NH4_CE1
	wave SO4_CE1 = root:CE:SO4_CE1
 	wave NO3_CE1 = root:CE:NO3_CE1
  	wave Cl_CE1 = root:CE:Cl_CE1
 	wave OM_CE1 = root:CE:OM_CE1

	DoWindow/F CE_Panel
	
	numTSeries = numpnts(NH4_CE1)		// can use any species

	SmoothTypeVar=nan
	SmoothVar=nan
	RHWaveStr=""

	// get user input and do sanity checks
	ControlInfo/w=CE_Panel NH4DetLim
	NH4_DetLimit=V_value
	if ( !(NH4_DetLimit>0))
		abort "The NH4 detection limit must be > 0. Aborting from sq_butt_Calc_CDCE"
	endif
	
//	ControlInfo/w=CE_Panel CE4LowNH4  //1.65L
	varCE_lowNH4=DEFAULTCE // V_value
//	if ( varCE_lowNH4<0.001  || varCE_lowNH4>10 || numtype(varCE_lowNH4)!=0)
//		abort "The CE for low NH4 must be > 0.001 and less than 10.  Aborting from sq_CalcCompDepCE_ButtonProc"
//	endif
	DoWindow/F AdvUserCEPanel //1.65L
	if (V_flag)		// window exists
		// sanity checks
		ControlInfo CE4LowNH4  //1.65L
		if ( ! (V_value > 0 && V_Value < 1) )
			abort "The default CE must be between 0 and 1. Aborting from sq_butt_Calc_CDCE"
		endif
		varCE_lowNH4=V_value  //1.65L
	endif
	
	ControlInfo/w=CE_Panel checkUseSmooth 
	if (V_value)
//		controlinfo/w=ams_panel misc_smooth //1.65L
//		SmoothTypeVar=v_value
		ControlInfo/w=CE_Panel Num2SmoothVar; SmoothVar=V_value 
		if (!(SmoothVar>=1))
			abort "The number of points to smoothe must be >=1. Aborting from sq_butt_Calc_CDCE"
		endif
		UseSmooth=1
	endif
	
	ControlInfo/w=CE_Panel checkUseRH
	if (V_value)
		DoWindow/F CE_Panel //1.65L
		wave/z RHSampleLineWave = gen_returnSelectedWave("setVarRH", DFstr="root:ACMCC_Export:DryerStats:", num=numTSeries, minVal=0, maxVal=110, nansOK=0)
		if (!WaveExists(RHSampleLineWave) )
			abort "Something was wrong with the chosen RH wave. Aborting from sq_butt_Calc_CDCE"
		endif
		RHWaveStr=nameofWave(RHSampleLineWave)
		UseRH=1
	endif

 	//  finally, call the function to calculate CE_fPhase
 	if (WaveExists(RHSampleLineWave))
 		if (SmoothVar>=1)
 			sq_CalcCE_fPhase(NH4_DetLimit,varCE_lowNH4, SO4_CE1, NH4_CE1, NO3_CE1, Cl_CE1, OM_CE1, RH_SampLine= RHSampleLineWave, SmoothVariable=SmoothVar, SmoothTypeVariable=SmoothTypeVar)
 		else
  			sq_CalcCE_fPhase(NH4_DetLimit,varCE_lowNH4, SO4_CE1, NH4_CE1, NO3_CE1, Cl_CE1, OM_CE1, RH_SampLine= RHSampleLineWave)
		endif
 	else
 		if (SmoothVar>=1)
 			sq_CalcCE_fPhase(NH4_DetLimit,varCE_lowNH4, SO4_CE1, NH4_CE1, NO3_CE1, Cl_CE1, OM_CE1, SmoothVariable=SmoothVar, SmoothTypeVariable=SmoothTypeVar)
 		else
	   		sq_CalcCE_fPhase(NH4_DetLimit,varCE_lowNH4, SO4_CE1, NH4_CE1, NO3_CE1, Cl_CE1, OM_CE1)
   		endif
 	endif
 	
	// the result!!		// note that CD_fphase has to be retained in the root folder if it is used in the speccorr_list column
	wave CE_fPhase = root:CE_fPhase
	
	duplicate/o NH4_CE1 root:CE:NH4_CDCE/wave=NH4_CDCE
	duplicate/o SO4_CE1 root:CE:SO4_CDCE/wave=SO4_CDCE
	duplicate/o NO3_CE1 root:CE:NO3_CDCE/wave=NO3_CDCE
	duplicate/o Cl_CE1 root:CE:Cl_CDCE/wave=Cl_CDCE
	duplicate/o OM_CE1 root:CE:OM_CDCE/wave=OM_CDCE

	NH4_CDCE/=CE_fPhase
	SO4_CDCE/=CE_fPhase
	NO3_CDCE/=CE_fPhase
	Cl_CDCE/=CE_fPhase
	OM_CDCE/=CE_fPhase

	duplicate/o OM_CDCE root:CE:Total_CDCE/wave=Total_CDCE
 	Total_CDCE = NH4_CDCE+SO4_CDCE+NO3_CDCE+Cl_CDCE+OM_CDCE
 	
	SetWindow CE_panel userdata(defaultCE)=num2str(varCE_lowNH4)
	SetWindow CE_panel userdata(NH4DetLim)= num2str(NH4_DetLimit)
	SetWindow CE_panel userdata(UseRH)= num2str(UseRH)
	SetWindow CE_panel userdata(RHwave)=RHWaveStr
	SetWindow CE_panel userdata(UseSmooth)=num2str(UseSmooth)
	SetWindow CE_panel userdata(num2smooth)=num2str(SmoothVar)

	// create a wave note for root:CE_fPhase that has all the pertinant info
	CEnote = "defaultCE:"+num2str(varCE_lowNH4)+";"
	CEnote += "NH4DetLim:"+num2str(NH4_DetLimit)+";"
	CEnote += "todo:"+ GetUserData("CE_panel", "", "todo")+";"
	CEnote += "UseRH:"+num2str(UseRH)+";"
	CEnote += "RHwave:"+RHWaveStr+";"
	CEnote += "UseSmooth:"+num2str(UseSmooth)+";"
	CEnote += "num2smooth:"+num2str(SmoothVar)+";"
	
	DoWindow/F AdvUserCEPanel
	if (V_flag) 
		ControlInfo checkUseTheseInflPts
		if (V_value)		// User wants to set their own inflection points.  We use varCE_lowNH4 as the default CE for all cases
			// sanity checks
			ControlInfo CE4LowNH4			//1.65L
			CEnote += "Default CE:"+num2str(V_Value)+";"
			ControlInfo Acidity_inflectionPt
			CEnote += "AcidicCutoff:"+num2str(V_Value)+";"
			ControlInfo Acidity_inflectionPt
			CEnote += "AcidicCutoff:"+num2str(V_Value)+";"
			ControlInfo ANMF_inflectionPt
			CEnote += "ANMFcutoff:"+num2str(V_Value)+";"
			ControlInfo Humidity_inflectionPt
			CEnote += "Humiditycutoff:"+num2str(V_Value)+";"
		endif		// we use user settable inflection points
	endif
	
	Note/K CE_fPhase CEnote

	if (UseRH)
		sq_calcCDCE_extras(UseRH, RHWave =RHSampleLineWave )
	else
		sq_calcCDCE_extras(UseRH)
	endif
	
	ControlInfo/w=CE_Panel tabCE
	sq_plotCEGrs(V_Value)		// update plots

	print "// The CDCE was calculated at "+date()+" "+time()+" with the following parameters: "+CEnote //1.65L
End

Function gen_FindFirst(w, beginPt)
	Wave w
	Variable beginPt

	variable i=beginPt,  n=numpnts(w)

	if (i >= n)
		return n
	endif

	if (i < 0)
		return -1
	endif
		
	if (numtype(w[i])== 0 )	// is w[beginPt] a number?
		return i	
	endif

	do
		i+=1
	while  ( (i <n ) &&  (numtype(w[i])!=0) )		//1.60B
	
	return i

End

Function gen_InterpolateAcrossTime(xWave, yWave)		// assumes x wave is time, is monotonically increasing
wave xWave, yWave

	variable idex, num
	
	num = numpnts(yWave)
	if (num != numpnts(xWave) || num==0 )
		abort "The number of points in the x and y wave must be the same"
	endif
	
	wavestats/q /m=1 yWave
	if (V_npnts==0)
		abort "There must be some non nan points in the wave.  Aborting from gen_InterpolateAcrossTime"
	endif
	
	if (numtype(yWave[0])!=0)
		yWave[0] = yWave[gen_FindFirst(yWave, 0)]
	endif

	if (numtype(yWave[num-1])!=0)
		yWave[num-1] = yWave[gen_Findlast(yWave, num-1)]
	endif

	make/d/FREE/o/n=(num) xwaveNoNan = xWave[p]
	make/d/FREE/o/n=(num) ywaveNoNan = yWave[p]
	// first make non-nan versions
	gen_RemoveNaNsXY(xwaveNoNan, ywaveNoNan)	
	
	for (idex=0;idex<num;idex+=1)
		if(numtype(yWave[idex])!=0)
			ywave[idex] = Interp(xwave[idex], xwaveNoNan, yWaveNoNan)
		endif
	endfor

End

Function gen_RemoveNaNsXY(theXWave, theYWave)
	Wave theXWave
	Wave theYWave

	Variable p, numPoints, numNaNs
	Variable xval, yval
	
	numNaNs = 0
	p = 0											// the loop index
	numPoints = numpnts(theXWave)			// number of times to loop

	do
		xval = theXWave[p]
		yval = theYWave[p]
		if ((numtype(xval)==2) %| (numtype(yval)==2))		// either is NaN?
			numNaNs += 1
		else										// if not an outlier
			theXWave[p - numNaNs] = xval		// copy to input wave
			theYWave[p - numNaNs] = yval		// copy to input wave
		endif
		p += 1
	while (p < numPoints)
	
	// Truncate the wave
	DeletePoints numPoints-numNaNs, numNaNs, theXWave, theYWave
	
	return(numNaNs)
End

//1.52
Function gen_FindLast(w, endPt)		
	Wave w
	Variable endPt

	variable i=endPt, n=numpnts(w)

	if (i >= n)
		return n
	endif

	if (i < 0)
		return -1
	endif

	if (numtype(w[i])==0)// is the w[endPt] a number?
		return i		
	endif

	do
		i-=1
	while  ( (i >=0 ) && (numtype(w[i])!=0)  )		//1.60B
	
	return i

End

//1.52
// does the work of calculating the phase dependent CE
Function sq_CalcCE_fPhase(NH4_DetLimit,varCE_lowNH4, SO4_CE1, NH4_CE1, NO3_CE1, Cl_CE1, OM_CE1, [RH_SampLine, SmoothVariable, SmoothTypeVariable])
	variable NH4_DetLimit,varCE_lowNH4, SmoothVariable, SmoothTypeVariable
	wave SO4_CE1, NH4_CE1, NO3_CE1, Cl_CE1, OM_CE1, RH_SampLine
	//print NH4_DetLimit
	
	// NH4_DL = ammonium detection limit
	// varCE_lowNH4 = CE for points where ammonium is below its detection limit
	// SO4, NH4, NO3, Chl, Org are all calculated using a CE of 1 (and an anticipated speccorr_list value being blank)
	// RH_SampLine = t_series length wave or sampling line RH in % 
	// SmoothVariable = number of points to smooth.  In Middlebrook et al paper data is gaussian smoothed with number of points = 1
	// SmoothTypeVariable is 1=gaussian or 2=boxcar smoothing and is determined by the popup menu in the squirrel misc tab setting
	
	//  all variables below are from Ann's paper.  Use these unless user sets their own inflection points
	variable Eq4_slope = 0.9167		// ANMF equation   if ANMF=.4546 then CE = 0.0833+0.9167*(.4546) = .5
	variable Eq4_intercept = 0.0833	// ANMF equation  Inflection point is .4546
	variable ANMFcutoff =0.4546	// NOT USED IN EQUATIONS but is already determined by Eq 4 slope and intercept

	variable Eq6_slope = -0.73		// acidity equation       if NH4Meas/NH4Predict=.75 then CE = 1 - 0.73*(.75 ) = .4546
	variable Eq6_intercept = 1		// acidity equation
	variable AcidicCutoff = 0.75
//	For Reference:
//	Acidity CE by Quinn et al 2006:
//	CE_Acidity_dry = NH4_MeasToPredict[p]>=0.5 ? varCE_lowNH4 : 1.0-1.1*NH4_MeasToPredict[p])
// 	(5×CEdry -4)+((1-CEdry)/20)×RH)
	variable Eq7_slopeA = 5		// humidity equation
	variable Eq7_interceptA = -4	// humidity equation
	variable Eq7_slopeB = -1		// humidity equation
	variable Eq7_interceptB = 1	// humidity equation
	variable Eq7_slopeC = 20		// humidity equation
	variable humidityCutoff = 80		// 80 %  we need rel hum to be in percent
	 	
	DoWindow/F AdvUserCEPanel
	if (V_flag)		// window exists
		ControlInfo checkUseTheseInflPts
		if (V_value)		// User wants to set their own inflection points.  We use varCE_lowNH4 as the default CE for all cases
						
			// sanity checks
			ControlInfo Acidity_inflectionPt
			if ( ! (V_value > 0 && V_Value < 1) )
				abort "The acidity inflection point must be between 0 and 1. aborting from sq_CalcCE_fPhase"
			endif			
			AcidicCutoff  = V_Value
			Eq6_intercept = 1		// acidity equation... this is retained.  We have two points (0,1) and (defaultCE, AcidicCutoff)
			Eq6_slope = (1-varCE_lowNH4)	/(0-AcidicCutoff)// acidity equation   slope = deltay/deltax
			
			ControlInfo ANMF_inflectionPt
			if ( ! (V_value > 0 && V_Value < 1) )
				abort "The ANMF inflection point must be between 0 and 1. aborting from sq_CalcCE_fPhase"
			endif
			ANMFcutoff = V_Value 	// ANMF equation... this is retained.  We have two points (1,1) and (defaultCE, ANMFcutoff)
			Eq4_slope = (1-varCE_lowNH4)/(1-ANMFcutoff)	
			Eq4_intercept =1-Eq4_slope  // if ANMF=.4546 then CE = 0.0833+0.9167*(.4546) = .5
						
			ControlInfo Humidity_inflectionPt
			if ( ! (V_value > 0 && V_Value < 100 && !ParamisDefault(RH_SampLine) ) )
				abort "The relative humidity inflection point must be between 0 and 100 and an RH wave used. aborting from sq_CalcCE_fPhase"
			endif			
			humidityCutoff=V_Value	// RH equation We have two points (100,1) and (defaultCE, humidityCutoff) 
			//  (5×CEdry-4)+(1-CEdry)/((20)×RH) 
			//  (100-humidityCutoff/100)/(100-humidityCutoff)   +(1-CEdry)/((100-humidityCutoff)×RH) 
			Eq7_slopeA = 100/(100-humidityCutoff) 	//5
			Eq7_interceptA = - humidityCutoff/(100-humidityCutoff) 	// -4
			Eq7_slopeB = -1		// 
			Eq7_interceptB = 1	// 
			Eq7_slopeC = (100-humidityCutoff) 	// 20	
		
		endif
		// sanity checks
		ControlInfo CE4LowNH4  //1.65L
		if ( ! (V_value > 0 && V_Value < 1) )
			abort "The default CE must be between 0 and 1. aborting from sq_CalcCE_fPhase"
		endif
		varCE_lowNH4=V_value  //1.65L

	endif
	
	DoWindow/F CE_Panel  //1.65L
	
	// Create waves of each species to smooth for the calculations.  
	// These waves will be killed automatically when the function is completed.
	duplicate/o SO4_CE1 root:CE:SO4_CE1_smooth	/wave=SO4_CE1_smooth	// the suffix _CE1 indicates that the values were calculated with a CE of 1
	duplicate/o NH4_CE1 root:CE:NH4_CE1_smooth/wave=NH4_CE1_smooth
	duplicate/o NO3_CE1 root:CE:NO3_CE1_smooth/wave=NO3_CE1_smooth
	duplicate/o Cl_CE1 root:CE:Cl_CE1_smooth/wave=Cl_CE1_smooth
	duplicate/o OM_CE1 root:CE:OM_CE1_smooth/wave=OM_CE1_smooth

	// first smooth if applicable	
	if ( !ParamIsDefault(SmoothVariable) && !ParamIsDefault(SmoothTypeVariable) && SmoothVariable>0)
		// interpolate across time   If we don't interpolate we get extra nans where we might not want them
//		gen_InterpolateAcrossTime(root:index:t_series,SO4_CE1_smooth)
//		gen_InterpolateAcrossTime(root:ToF_ACSM:DateW,SO4_CE1_smooth)
		gen_InterpolateAcrossTime(root:ACMCC_Export:ACSM_time,SO4_CE1_smooth)
//		gen_InterpolateAcrossTime(root:ToF_ACSM:DateW,NH4_CE1_smooth)	
		gen_InterpolateAcrossTime(root:ACMCC_Export:ACSM_time,NH4_CE1_smooth)	
//		gen_InterpolateAcrossTime(root:ToF_ACSM:DateW,NO3_CE1_smooth)	
		gen_InterpolateAcrossTime(root:ACMCC_Export:ACSM_time,NO3_CE1_smooth)	
//		gen_InterpolateAcrossTime(root:ToF_ACSM:DateW,OM_CE1_smooth)	
		gen_InterpolateAcrossTime(root:ACMCC_Export:ACSM_time,OM_CE1_smooth)
//		gen_InterpolateAcrossTime(root:ToF_ACSM:DateW,Cl_CE1_smooth)
		gen_InterpolateAcrossTime(root:ACMCC_Export:ACSM_time,Cl_CE1_smooth)
		
		if (SmoothVariable ==2)		// boxcar smoothing
			Smooth/B=(SmoothVariable), SmoothVariable, SO4_CE1_smooth,NH4_CE1_smooth,NO3_CE1_smooth,Cl_CE1_smooth, OM_CE1_smooth			//1.57J
		else
			Smooth SmoothVariable, SO4_CE1_smooth,NH4_CE1_smooth,NO3_CE1_smooth,Cl_CE1_smooth, OM_CE1_smooth	
		endif
		NH4_CE1_smooth = numtype(NH4_CE1[p])==0 ? NH4_CE1_smooth[p] : nan
		SO4_CE1_smooth = numtype(SO4_CE1[p])==0 ? SO4_CE1_smooth[p] : nan
		NO3_CE1_smooth = numtype(NO3_CE1[p])==0 ? NO3_CE1_smooth[p] : nan
		Cl_CE1_smooth = numtype(Cl_CE1[p])==0 ? Cl_CE1_smooth[p] : nan
		OM_CE1_smooth = numtype(OM_CE1[p])==0 ? OM_CE1_smooth[p] : nan		
	endif
	
	variable idex, tempCE, num = numpnts(SO4_CE1)		// can use any wave to get the number of points of waves created below

	SetDataFolder root:CE
	make/o/n=(num)/free PredNH4_CE1
	make/o/n=(num) ANMF, CE_dry, NH4_MeasToPredict		// waves that will be retained in root upon completion of function 
	make/o/n=(num) CE_Acidity, CE_ANMF, CE_Humidity, CETypeFlag
	SetDataFolder root:
	
	make/o/n=(num) root:CE_fPhase/wave=CE_fPhase=nan

	// Get all the parts we need for the CE formulation:  ANMF & NH4_MeasToPredict
	PredNH4_CE1=Mass_NH4*(2*SO4_CE1_smooth/Mass_SO4+NO3_CE1_smooth/Mass_NO3+Cl_CE1_smooth/Mass_Chl)	// presume Org doesn't contribute to acidity 
	  
	NH4_MeasToPredict = NH4_CE1_smooth/PredNH4_CE1
	
	// replace values < 0 with nans
	NH4_MeasToPredict = ( NH4_CE1_smooth[p]<0 || PredNH4_CE1[p]<0 ) ? nan : NH4_MeasToPredict[p] 
	
	ANMF=(Mass_NH4NO3/Mass_NO3)*NO3_CE1_smooth/(NO3_CE1_smooth+SO4_CE1_smooth+NH4_CE1_smooth+OM_CE1_smooth+Cl_CE1_smooth)	
	
	// replace values < 0 and > 1  with nans
	ANMF =  (ANMF[p]<0 ||  ANMF[p]> 1 || NO3_CE1_smooth[p]<0) ? nan : ANMF[p] 

	// Calculate the dry collection efficiency, CE_dry	
	// estimate CE_dry via the measured to predicted.  If >= .75 use  0.0833+0.9167*ANMF[idex]
	// Middlebrook et al describes that when ANMF is high, we typically don't have high acidity and visa versa
	// so that we typically don't have both, competing effects (high ANMF AND high acidity) 
	
//	CETypeFlag=8 means NH4 below detection limit
//	CETypeFlag=3 means NH4 ~= predicted.  Not very acidic
//	CETypeFlag=10 means NH4 < predicted.  Acidic
//	CETypeFlag=12 means no data
//	CETypeFlag =1 means we use the relative humidity in the calculations
	
	CETypeFlag=0
	for (idex=0;idex<num;idex+=1)

		if(numtype(PredNH4_CE1[idex])!=0) 		// typo caught by Will, was PredNH4_CE1[p]
			CE_dry[idex] = nan
			CETypeFlag[idex]=12
		
		elseif (PredNH4_CE1[idex]<NH4_DetLimit)		// we are below NH4 det limit, use default value
//			Print PredNH4_CE1[idex]
			CE_dry[idex]=varCE_lowNH4	// note that in ann's paper this value is nanned
			CETypeFlag[idex]=8		

		elseif(NH4_MeasToPredict[idex]>=AcidicCutoff)		//   not acidic AcidicCutoff = .75, use ANMF equation.
			// note that if ANMF is *small* CE_dry will be < user default CE = varCE_lowNH4
			// ANMF inflection point is built into Eq4_intercept and Eq4_slope
			//  So a CETypeflag of 3 can either mean use default OR use the equation.
			tempCE=Eq4_intercept+ Eq4_slope*ANMF[idex]// if ANMF=.4546 then CE = 0.0833+0.9167*(.4546) = .5
			if (tempCE>varCE_lowNH4)
				CE_dry[idex]=tempCE
				CETypeFlag[idex]=3	// Use ANMF
			else
				CE_dry[idex]=varCE_lowNH4
				CETypeFlag[idex]=4 // Use default
			endif
			
		elseif(NH4_MeasToPredict[idex] <AcidicCutoff)	//   AcidicCutoff = .75
			// if NH4_MeasToPredict is *small* CE_dry will be close to 1
			// Any point in between < AcidicCutoff
			CE_dry[idex]=Eq6_intercept+ Eq6_slope*NH4_MeasToPredict[idex]	// acidity equation       if NH4Meas/NH4Predict=.75 then CE = 1 - 0.73*(.75 ) = .4546
			CETypeFlag[idex]=10

		else 	
			// by default NH4 meas/NH4 precit will always be either >= or < AcidicCutoff
			// so this case just defined where we have nans in time series. 
			CE_dry[idex] = nan
			CETypeFlag[idex]=12
		endif
	endfor
	
	// line below does 2 things.  sets the min CE to varCE_lowNH4 and the max CE to 1
	CE_dry = min(1, (max(varCE_lowNH4,CE_dry)))		// replaced 0.45 with varCE_lowNH4    // retains nans & maximizes values to 1
		
//	For Reference:
//	CE_ANMF by Crosier et al 2007:
//	CE_ANMF = 0.393 + 0.582*ANMF  // where ANMF is calculated ignoring both Org and Chl
//	CE_ANMF by Matthew et al 2008 for pure ANMF:
//	CE_ANMF = ANMF[p]>=0.55 ? 0.24 : 1.0-1.1*ANMF[p])
//	CE_ANMF by Nemitz et al 2011 for EUCAARI :
//	CE_ANMF = ANMF[p]>=0.35 ? 0.5 : need from Eiko Nemtiz (manuscript under preparation)
//	CE_ANMF by Middlebrook et al 2012:
//	CE_ANMF =  ANMF[p]>=0.4 ? 0.45 : 0.0833+0.9167*ANMF[p] identical to max(0.45,0.0833+0.9167*ANMF[p])
			
	if (!ParamIsDefault(RH_SampLine)==1)
		// Apply Equation 7
		CE_fPhase=  (Eq7_slopeA*CE_dry + Eq7_interceptA) + ((Eq7_interceptB + Eq7_slopeB*CE_dry)/Eq7_slopeC )*RH_SampLine		// calculate for all values
//		CE_fPhase= (  (5*CE_dry -4) + (1  -CE_dry)/20) *RH_SampLine		// calculate for all values
//		CE_fPhase= (  (CE_dry -) + (1  -CE_dry)/20) *RH_SampLine		// calculate for all values

		for (idex=0;idex<num;idex+=1)
			if (RH_SampLine[idex]<humidityCutoff || numtype(RH_SampLine[idex]!=0 )	  )	// if dry or we don't have an RH value
				CE_fPhase[idex]=CE_dry[idex]
			elseif(numtype(CE_dry[idex])==0)	// aerosol is wet, keep the CEfPhase formulation
				CETypeFlag[idex]=1		//  keep track of when we use the RH correction
			endif
		endfor
	else
		CE_fPhase=CE_dry
	endIf
	
End
 
 
//1.52
// Calcs stats and other waves for CDCE panel
Function sq_calcCDCE_extras(UseRH, [RHWave])	// Manjula wanted these plots.  Fig 1 (&2,3) in the supplemental part of middlebrook paper 
variable UseRH
wave RHWave

	svar CEStatsStr = root:CE:CEStatsStr
	wave CETypeFlag = root:CE:CETypeFlag
	wave CE_fphase = root:CE_fphase
	wave ANMF = root:CE:ANMF
	wave NH4_MeasToPredict = root:CE:NH4_MeasToPredict
	wave Total_CE1 = root:CE:Total_CE1

	wave Cl_CE1 = root:CE:Cl_CE1
	wave OM_CE1 = root:CE:OM_CE1
	wave NO3_CE1 = root:CE:NO3_CE1
	wave NH4_CE1 = root:CE:NH4_CE1
	wave SO4_CE1 = root:CE:SO4_CE1
	wave Cl_CDCE = root:CE:Cl_CDCE
	wave OM_CDCE = root:CE:OM_CDCE
	wave NO3_CDCE = root:CE:NO3_CDCE
	wave NH4_CDCE = root:CE:NH4_CDCE
	wave SO4_CDCE = root:CE:SO4_CDCE
	
	make/o/n=(6,2) root:CE:SpeciesStats/wave=SpeciesStats 
	variable var1, numNonNans, lowNH4Val, num, defaultCEvar, delta,startHist
	string tempStr, tempColorStr
	
	WaveStats/q/m=0 OM_CE1		// could use any species wave
	numNonNans = V_npnts
	num = numpnts(OM_CE1)
	
	defaultCEvar=str2num(getuserdata("CE_Panel","","defaultCE") )// number	

	// rows are just like tabs: NH4=0, NO3=1, SO4 = 2, Org = 3, Chl = 4
	//avgCE1=SpeciesStats[tabNum-2][0]
	//avgCDCE=SpeciesStats[tabNum-2][1]

	WaveStats/q/m=0 NH4_CE1
	SpeciesStats[0][0]=V_avg/defaultCEvar
	WaveStats/q/m=0 NH4_CDCE
	SpeciesStats[0][1]=V_avg
	
	WaveStats/q/m=0 NO3_CE1
	SpeciesStats[1][0]=V_avg/defaultCEvar
	WaveStats/q/m=0 NO3_CDCE
	SpeciesStats[1][1]=V_avg

	WaveStats/q/m=0 SO4_CE1
	SpeciesStats[2][0]=V_avg/defaultCEvar
	WaveStats/q/m=0 SO4_CDCE
	SpeciesStats[2][1]=V_avg

	WaveStats/q/m=0 OM_CE1
	SpeciesStats[3][0]=V_avg/defaultCEvar
	WaveStats/q/m=0 OM_CDCE
	SpeciesStats[3][1]=V_avg

	WaveStats/q/m=0 Cl_CE1
	SpeciesStats[4][0]=V_avg/defaultCEvar
	WaveStats/q/m=0 Cl_CDCE
	SpeciesStats[4][1]=V_avg
		
	duplicate/o Total_CE1 root:CE:Org_MassFraction/wave=Org_MassFraction
	Org_MassFraction=OM_CE1/Total_CE1
	
	duplicate/o Total_CE1 root:CE:SO4_MassFraction/wave=SO4_MassFraction
	SO4_MassFraction=SO4_CE1/Total_CE1

	setDataFolder root:CE
	Make/N=20/O ANMF_Hist, OrgMF_Hist, SO4MF_Hist, Acidity_Hist, Humidity_Hist, NH4_hist, CE_hist

	// ANMF ranges from 0 to 1
	Histogram/B={0,0.05,20} ANMF,ANMF_Hist
	ANMF_Hist/=numNonNans	//  Sum(y)=1
	ANMF_Hist/=0.05		// resulting in Sum(y)*deltax=1     1.52 E James email regarding units
		
	// Org_MassFraction ranges from 0 to 1
	Histogram/B={0,0.05,20} Org_MassFraction,OrgMF_Hist
	OrgMF_Hist/=numNonNans// resulting in Sum(y)=1
	OrgMF_Hist/=0.05		// resulting in Sum(y)*deltax=1     1.52 E James email regarding units
	
	// SO4_MassFraction ranges from 0 to 1
	Histogram/B={0,0.05,20} SO4_MassFraction,SO4MF_Hist	
	SO4MF_Hist/=numNonNans
	SO4MF_Hist/=0.05		// resulting in Sum(y)*deltax=1     1.52 E James email regarding units

	// NH4_MeasToPredict can range from 0 to 2 (in theory could be more)
	Histogram/B={0,0.05,40} NH4_MeasToPredict,Acidity_Hist	
	Acidity_Hist/=numNonNans
	Acidity_Hist/=0.05		// resulting in Sum(y)*deltax=1     1.52 E James email regarding units

	// we do CE histogram at the end, after we interpolate
	// CE_fphase ranges from user default to 1.  Because CE_fphase has been interpolated to all points, we need to divide by numpnts
//	Histogram/B={0.5,0.025,20} CE_fphase, CE_hist
//	CE_hist/=num

	lowNH4Val=str2num(getuserdata("CE_Panel","","NH4DetLim") )	
	var1 = ceil(Wavemax(NH4_CE1))
	var1 = min(var1, num)
	delta =  ceil(var1/(min(0.1,lowNH4Val))  )		// minimum delta is .1 or user set-able lowNH4Val
	startHist=0
	if (WaveMin(NH4_CE1)<0)
		delta+=1
		startHist=-lowNH4Val
	endif
	Make/N=(delta)/O NH4_hist
	Histogram/B={startHist,lowNH4Val,delta} NH4_CE1,NH4_hist
	NH4_hist/=numNonNans
	NH4_hist/=lowNH4Val  	// resulting in Sum(y)*deltax=1     1.52 E James email regarding units
	
	if (UseRH)		
		// RHWave can range from 0 to 100 (in theory could be more)
		Histogram/B={0,5,20} RHWave,Humidity_Hist
		wavestats/q/m=1 RHWave
		Humidity_Hist/=V_npnts	
		Humidity_Hist/=5  	// resulting in Sum(y)*deltax=1     1.52 E James email regarding units
	else
		Humidity_Hist=nan
	endif
	
	// calculate stats string
	Make/N=14/O root:CE:CETypeFlag_Hist/wave=CETypeFlag_Hist
	Histogram/B={0,1,15} root:CE:CETypeFlag,CETypeFlag_Hist  // not normalized... just get counts of each

	SetDataFolder root:
	ColorTab2Wave dBZ14		// generates M_colors
	wave M_colors = root:M_colors
	
	CEStatsStr=""
	
// number values are mostly arbitrary.  They reflect colors we want to use in  dBZ14 to correspond to NO3, etc
//	CETypeFlag=8 means NH4 below detection limit
//	CETypeFlag=3 means NH4 ~= predicted.  Not acidic and ANMF is bigish
//	CETypeFlag=4 means NH4 ~= predicted.  ANMF is small, use default
//	CETypeFlag=13 means NH4 < predicted.  Acidic
//	CETypeFlag=12 means no data
//	CETypeFlag =1 means we use the relative humidity in the calculations

	sprintf tempStr, "%2.1f", 100*CETypeFlag_Hist[8]/numNonNans		// had 8s in CETypeFlag
	tempColorStr = "\\K("+num2str(M_colors[8-1][0])+","+num2str(M_colors[8-1][1])+","+num2str(M_colors[8-1][2])+") "
	CEStatsStr+=tempColorStr+"CETypeFlag=8, "+ "\\K(1,1,1)"+ "Below Min NH4:\t"+tempStr+"%\r"	
	
	sprintf tempStr, "%2.1f", 100*CETypeFlag_Hist[4]/numNonNans		// had 3s in CETypeFlag
	tempColorStr = "\\K("+num2str(M_colors[4-1][0])+","+num2str(M_colors[4-1][1])+","+num2str(M_colors[4-1][2])+") "
	CEStatsStr+= tempColorStr+"CETypeFlag=4, "+"\\K(1,1,1)"+"neutral, low ANMF:\t"+tempStr+"%\r"	

	sprintf tempStr, "%2.1f", 100*CETypeFlag_Hist[3]/numNonNans		// had 3s in CETypeFlag
	tempColorStr = "\\K("+num2str(M_colors[3-1][0])+","+num2str(M_colors[3-1][1])+","+num2str(M_colors[3-1][2])+") "
	CEStatsStr+= tempColorStr+"CETypeFlag=3, "+"\\K(1,1,1)"+"Used ANMF:\t"+tempStr+"%\r"	
	
	sprintf tempStr, "%2.1f", 100*CETypeFlag_Hist[10]/numNonNans		// had 10s in CETypeFlag
	tempColorStr = "\\K("+num2str(M_colors[10-1][0])+","+num2str(M_colors[10-1][1])+","+num2str(M_colors[10-1][2])+") "
	CEStatsStr+= tempColorStr+"CETypeFlag=10, "+"\\K(1,1,1)"+"Acidic:\t"+tempStr+"%\r"
	
	sprintf tempStr, "%2.1f", 100*CETypeFlag_Hist[1]/numNonNans		// had 1s in CETypeFlag
	tempColorStr = "\\K("+num2str(M_colors[1-1][0])+","+num2str(M_colors[1-1][1])+","+num2str(M_colors[1-1][2])+") "
	CEStatsStr+= tempColorStr+"CETypeFlag=1, "+"\\K(1,1,1)"+"RH high:"+tempStr+"%\r"	

	sprintf tempStr, "%d", CETypeFlag_Hist[12]	// had 12s in CETypeFlag
	tempColorStr = "\\K("+num2str(M_colors[12-1][0])+","+num2str(M_colors[12-1][1])+","+num2str(M_colors[12-1][2])+") "
	CEStatsStr+=tempColorStr+"CETypeFlag=12, "+"\\K(1,1,1)"+ "nan pt after step 1."  ///   \\:\r\t\t"+tempStr

	killwaves/z M_colors
	
	// make wave for plotting
	duplicate/o ANMF  root:CE:CEdefault/wave=CEdefault
	CEdefault = str2num(GetUserData("CE_Panel", "", "defaultCE" ) )

	// interpolate across time  The values in CETypeFlag can tell you if point was interpolated or not
//	wave DateW = root:ToF_ACSM:DateW
	wave DateW = root:ACMCC_Export:ACSM_time
	gen_InterpolateAcrossTime(DateW,root:CE_fphase)	

	Histogram/B={0.5,0.025,20} CE_fphase, CE_hist
	CE_hist/=num
	CE_hist/=0.025  // resulting in Sum(y)*deltax=1     1.52 E James email regarding units

	setDataFolder root:

End 


//1.52
// Advanced users panel for setting inflection points for CDCE panel
Function sq_butt_CEAdvPanel(ctrlName) : ButtonControl
	String ctrlName

	DoWindow/F AdvUserCEPanel
	if (V_flag)
		return 0
	endif

	NewPanel/K=1/N=AdvUserCEPanel /W=(1100,62,1464,400) as "AdvUserCEPanel"
//	gen_setFont("AdvUserCEPanel", 12)  //1.65L
	SetDrawLayer UserBack
	SetDrawEnv fsize= 18,fstyle= 1
	DrawText 26,20,"Advanced Users CE Panel"
	SetDrawEnv fsize= 14,fstyle= 1
	DrawText 4,38,"Options to modify default CE, inflection points"

	SetDrawEnv fsize= 11
	DrawText 3,90,"To correctly set values below in this panel, users must be able to use"
	SetDrawEnv fsize= 11
	DrawText 4,104,"external measurements of aerosol mass loadings and to generate"
	SetDrawEnv fsize= 11
	DrawText 5,120,"plots similar to the non-supplemental figures in Middlebrook et al."

	SetDrawEnv fsize= 10
	DrawText 10,177,"The inflection point at which aerosol is deemed acidic."
	SetDrawEnv fsize= 10
	DrawText 10,189,"For each point if NH4meas/NH4predict < inflection point acidity correction"
	SetDrawEnv fsize= 10
	DrawText 10,242,"The inflection point at which aerosol is deemed mostly AN."
	SetDrawEnv fsize= 10
	DrawText 10,202,"is applied. Else user defined default CE (Step 4.) is used."
	SetDrawEnv fsize= 10
	DrawText 10,255,"For each point if ANMF > inflection point ANMF correction"
	SetDrawEnv fsize= 10
	DrawText 10,269,"is applied. Else user defined default CE (Step 4.) is used."
	SetDrawEnv fsize= 10
	DrawText 10,308,"The inflection point at which aerosol is deemed to be 'wet'."
	SetDrawEnv fsize= 10
	DrawText 10,321,"For each point if RH > inflection point RH correction is applied."
	SetDrawEnv fsize= 10
	DrawText 10,335,"Else previoulsy calculated CE (CE_dry) is used."
	GroupBox group0,pos={5.00,144.00},size={357.00,193.00}
	SetVariable Acidity_inflectionPt,pos={8.00,146.00},size={315.00,17.00},bodyWidth=60
	SetVariable Acidity_inflectionPt,title="Acidity Inflection Point, unitless, Default = 0.75"
	SetVariable Acidity_inflectionPt,value=_NUM:0.75
	SetVariable ANMF_inflectionPt,pos={8.00,209.00},size={322.00,17.00},bodyWidth=60
	SetVariable ANMF_inflectionPt,title="ANMF Inflection Point, unitless, Default = 0.4545"
	SetVariable ANMF_inflectionPt,value=_NUM:0.4545
	SetVariable Humidity_inflectionPt,pos={8.00,277.00},size={330.00,17.00},bodyWidth=60
	SetVariable Humidity_inflectionPt,title="Relative Humidity Inflection Point, %, Default = 80"
	SetVariable Humidity_inflectionPt,value=_NUM:80
	CheckBox checkUseTheseInflPts,pos={6.00,128.00},size={330.00,14.00}	
	CheckBox checkUseTheseInflPts,title="Use inflection points below; you must use an RH wave in step 5"
	CheckBox checkUseTheseInflPts,fStyle=1,value=0
	SetVariable CE4LowNH4,pos={6.00,46.00},size={304.00,17.00},bodyWidth=40
	SetVariable CE4LowNH4,title="Set default CE (when composition independent)"
	SetVariable CE4LowNH4,fSize=12,format="%1.2f"
	SetVariable CE4LowNH4,limits={-inf,inf,0},value=_NUM:0.5

	AutoPositionWindow/E/M=0  //1.65L
	
End


// 1.52
// Creates the time series graph of 5 aerosol species with CE = 1 after step 1 is calculated.
Function sq_create_CEis1_TSgraph(ctrlName) : ButtonControl
	String ctrlName
	
	DoWindow/F CEis1_TSgraph
	if (V_flag)
		return 0
	endif
//	wave/z Org_CE1= root:CE:Org_CE1
	wave/z OM_CE1= root:CE:OM_CE1
	if (!WaveExists(OM_CE1))
		abort "Please press the 'Step 1. Calc...' button."
	endif
	PauseUpdate; Silent 1	
	Display /W=(35.25,42.5,429.75,251)/N=CEis1_TSgraph as "CEis1_TSgraph"
	AppendToGraph root:CE:OM_CE1 vs root:ACMCC_Export:ACSM_time
	AppendToGraph root:CE:NO3_CE1 vs root:ACMCC_Export:ACSM_time
	AppendToGraph root:CE:SO4_CE1 vs root:ACMCC_Export:ACSM_time
	AppendToGraph root:CE:NH4_CE1 vs root:ACMCC_Export:ACSM_time
	AppendToGraph root:CE:Cl_CE1 vs root:ACMCC_Export:ACSM_time
	ModifyGraph lSize=2
	ModifyGraph rgb(OM_CE1)=(0,52224,0),rgb(NO3_CE1)=(0,0,65535)
	ModifyGraph rgb(NH4_CE1)=(65535,43690,0),rgb(Cl_CE1)=(65280,0,52224)
	ModifyGraph gaps=0
	ModifyGraph zero(left)=1
	ModifyGraph nticks(bottom)=9
	ModifyGraph minor(bottom)=1
	ModifyGraph dateInfo(bottom)={0,1,0}
	Label left "µg/m3, CE=1"
	Label bottom " "
	SetAxis/A/E=3 left
End

function CDCE2Export(ctrlName) : ButtonControl
	String ctrlName
	
	SetDataFolder root:CE
	Wave OM_CDCE, SO4_CDCE, NH4_CDCE, NO3_CDCE, Cl_CDCE, Total_CDCE
	wave CE_fphase=root:CE_fphase
	Duplicate/O OM_CDCE, root:ACMCC_Export:OM
	Duplicate/O SO4_CDCE, root:ACMCC_Export:SO4
	Duplicate/O NH4_CDCE, root:ACMCC_Export:NH4
	Duplicate/O NO3_CDCE, root:ACMCC_Export:NO3
	Duplicate/O Cl_CDCE, root:ACMCC_Export:Cl
	Duplicate/O Total_CDCE, root:ACMCC_Export:NRPM1
	Duplicate/O CE_fphase, root:ACMCC_Export:CE //CDCE
	
//	KillWindow/Z CE_Panel
	KillWindow CE_Panel
	
End Function


//1.52
// Link to Middlebrook CDCE paper
//Function sq_CEpaperURL_buttonProc(ctrlName) : ButtonControl
//	String ctrlName
//
//	browseurl /z "http://cires.colorado.edu/jimenez/Papers/2011_AST_Middlebrook_CE.pdf"
//
//End


//1.52
Function Sq_CETabProc(ctrlName,tabNum) : TabControl
	String ctrlName
	Variable tabNum

	// don't display anything if we didn't press the calc CD composition button yet.
	wave/z NO3_CDCE = root:CE:NO3_CDCE		// assume that if this wave exists, all others exist
	if (WaveExists(NO3_CDCE) )
		sq_plotCEGrs(tabNum)
	else
//		DoAlert, 1, "You must first calculate the CDCE before viewing graphs."
	endif

End


//1.52
Function	sq_plotCEGrs(tabNum)
variable tabNum
		
	variable useRH, avgCE1, avgCDCE
	String SpecStr, tempStr, CE1str, CDCEstr
		
 	SetActiveSubwindow CE_Panel
 	
 	useRH = str2num( GetUserData("CE_Panel", "", "UseRH" ))
 	gen_Killsubwindows("CE_Panel")
 	if ( tabNum>=2 )		// individual species
 		SetActiveSubwindow CE_Panel
		
		Display/W=(265,165,615,325)/HOST=CE_Panel
		RenameWindow CE_Panel#G0, SQ_CETSGraph
		SQ_populate_CETSGraph()
		SetActiveSubwindow CE_Panel
		
		Display/W=(265,20,485,140)/HOST=CE_Panel
		RenameWindow  CE_Panel#G0,SQ_CECorrGraph
		SQ_populate_CECorrGraph()
		SetActiveSubwindow CE_Panel
		
		wave SpeciesStats = root:CE:SpeciesStats
		// rows are just like tabs: NH4=0, NO3=1, SO4 = 2, Org = 3, Chl = 4
		SpecStr=StringfromList(tabNum-2, "NH4;NO3;SO4;OM;Cl;")
		avgCE1=SpeciesStats[tabNum-2][0]
		avgCDCE=SpeciesStats[tabNum-2][1]
		sprintf CE1str, "%1.2f",avgCE1
		sprintf CDCEstr, "%1.2f",avgCDCE
		tempStr="Def. CE: "+SpecStr+"  Avg = "+CE1str+"\r"
		tempStr+="CDCE: "+SpecStr+"  Avg = "+CDCEstr
		Titlebox titleTSLegendStats title =tempStr
		TitleBox titleTSLegend, title="Gray:CE=user default\r(via mult. offset)\rColors indicate which\rfactor controls CE", disable=0

 	elseif ( tabNum==1 )		// CE stats
 	
		SetActiveSubwindow CE_Panel
		
		Display/W=(475,20,610,115)/HOST=CE_Panel
		RenameWindow CE_Panel#G0, SQ_CEHistGraph
		SQ_populate_CEHistGraph()
		SetActiveSubwindow CE_Panel

		Display/W=(265,165,615,325)/HOST=CE_Panel
		RenameWindow CE_Panel#G0,SQ_CETSGraph
		SQ_populate_CETSGraph()
		SetActiveSubwindow CE_Panel

		Titlebox titleTSLegendStats title =""
		wave SpeciesStats = root:CE:SpeciesStats
		tempStr = ""
		TitleBox titleTSLegend, title=tempStr
		
	else		// CE parts histograms
	
		DoWindow/F CE_Panel  //1.65L
		Display/W=(265,25,435,140)/HOST=CE_Panel
		RenameWindow CE_Panel#G0,NH4DetLimHist		// bottom left
		sq_populate_NH4DetLimHistGraph()
		SetActiveSubwindow CE_Panel
	
		Display/W=(440,25,610,140)/HOST=CE_Panel
		RenameWindow CE_Panel#G0,AcidityHist		// top left
		sq_populate_AcidityHistGraph()
		SetActiveSubwindow CE_Panel
	
		Display/W=(262,162,435,310)/HOST=CE_Panel
		RenameWindow CE_Panel#G0,ANMFOrgMFHist	// top right
		sq_populate_ANMFOrgMFHistGraph()
		SetActiveSubwindow CE_Panel
		
		if (UseRH)
			Display/W=(440,162,610,287)/HOST=CE_Panel //(440,162,610,287)
			RenameWindow CE_Panel#G0,RelHumHist		// bottom right
			sq_populate_RelHumHistGraph()
			SetActiveSubwindow CE_Panel
		endif
		Titlebox titleTSLegendStats title =""
		TitleBox titleTSLegend, title=""
	endif
			
	DoWindow/F CE_Panel  //1.65L

	Button SQ_but_SQ_CEHistGraph disable = !( tabNum==1)
	Button sq_but_CETypeFlagLegend disable = !( tabNum==1)

	Titlebox titleCEStats disable = !( tabNum==1)
//	Titlebox titleTSLegend disable = ( tabNum==1)
	Titlebox titleTSLegendStats disable = !( tabNum>=1)

	button SQ_but_SQ_CECorrGraph disable = !( tabNum>1)
	
	button SQ_but_SQ_CETSGraph disable = !( tabNum>=1)
	
	Button sq_but_SQ_AcidityHistGraph, disable =  tabNum>=1		// top left
	Button sq_but_SQ_ANMFOrgMFHistGraph, disable =  tabNum>=1	// top right
	Button sq_but_SQ_NH4DetLimHistGraph, disable =  tabNum>=1	// bottom left
	Button SQ_but_SQ_RelHumHistGraph, disable =  tabNum>=1	// bottom right
	Button SQ_but_SQ_CEfphaseTable, disable =  tabNum>=1

	if (!useRH)
		Button SQ_but_SQ_RelHumHistGraph disable=1
	endif
	
	wave/z ANMF_hist = root:CE:ANMF_hist		// any one of several waves could do to check values.
	if (!WaveExists(ANMF_hist))
		button SQ_but_SQ_CECorrGraph disable =1
		button SQ_but_SQ_CETSGraph disable = 1
		Titlebox titleTSLegend disable =1
		Titlebox titleTSLegendStats disable =1
		
		Button sq_but_SQ_AcidityHistGraph, disable =1	// top left
		Button sq_but_SQ_ANMFOrgMFHistGraph, disable =1// top right
		Button sq_but_SQ_NH4DetLimHistGraph, disable = 1	// bottom left
		Button SQ_but_SQ_RelHumHistGraph, disable =1	// bottom right
		Button SQ_but_SQ_CEfphaseTable, disable = 1	
	endif
	
End


// t series 
Function SQ_populate_CETSGraph()

	wave ACSM_time = root:ACMCC_export:ACSM_time
//	Duplicate/O DateW, t_series

	string species, specColorList

	doWindow/f CE_Panel
 	ControlInfo/W=CE_Panel tabCE
	Species= S_value

	if (stringmatch("CE Stats", species))  // CE tab.... show CE1 and CDCE
		wave/z Spec_CE1 =$"root:CE:CEdefault"
		wave/z Spec_CDCE = $"root:CE_fPhase"
	elseif(stringmatch("Total", species))		// 
		wave/z Spec_CE1 =$"root:CE:ToTal_CE1"
		wave/z Spec_CDCE =$"root:CE:Total_CDCE"
	else
		wave/z Spec_CE1 =$"root:CE:"+species+"_CE1"
		wave/z Spec_CDCE = $"root:CE:"+species+"_CDCE"
	endif
	
	if (!WaveExists(Spec_CE1) || !WaveExists(Spec_CDCE) )
		return 0
		// abort "Perhaps you have changed your todo wave.  Could not find waves "+nameofWave(Spec_CE1) +" or "+nameofWave(Spec_CDCE) +"  aborting from SQ_populate_CETSGraph"
	endif
	
	SpecColorList = SQ_getColorListSpecies(Species)

	AppendToGraph Spec_CE1 vs ACSM_time
	AppendToGraph Spec_CDCE vs ACSM_time
	
	ModifyGraph lSize($NameofWave(Spec_CE1))=2
	ModifyGraph rgb($NameOfWave(Spec_CE1))=(34816,34816,34816)
	ModifyGraph rgb($NameofWave(Spec_CDCE))=(str2num(stringFromList(0, SpecColorList)) ,str2num(stringFromList(1, SpecColorList)),str2num(stringFromList(2, SpecColorList)))
	
	SetAxis/A/E=1 left
//	SetAxis/A=2 left
	ModifyGraph gaps=0
	ModifyGraph grid=2
	ModifyGraph gridRGB=(34816,34816,34816)
	ModifyGraph zero(left)=1
	ModifyGraph nticks=9
	ModifyGraph minor=1
	ModifyGraph mode=4,marker=19,msize=1,lsize=1
	ModifyGraph dateInfo(bottom)={0,1,0}
	Label left "µg/m3,"+Species
	Label bottom " "

	variable defaultCE = str2num(GetUserData("CE_Panel", "", "defaultCE" ) )
	if (stringmatch(Species, "CE Stats"))
		SetAxis/A/W=CE_Panel#SQ_CETSGRAPH left  defaultCE*.9,1
	else
		ModifyGraph offset={0,0},muloffset($NameofWave(Spec_CE1))={0,1/defaultCE}
		SetAxis/A/E=1/W=CE_Panel#SQ_CETSGRAPH left
	endif
	ModifyGraph 	zColor($NameofWave(Spec_CDCE))={root:CE:CETypeFlag,1,15,dBZ14,0}
 
 End


//  t series correlation
Function SQ_populate_CECorrGraph()

	variable minTemp, maxTemp
	string SpecColorList, Species
	
	doWindow/f CE_Panel
 	ControlInfo/W=CE_Panel tabCE
	Species = S_value

	if (stringmatch("CE", species))  // CE tab.... show CE1 and CDCE
		wave/z Spec_CE1 =$"root:CE:CEdefault"
		wave/z Spec_CDCE = $"root:CE_fPhase"
	elseif(stringmatch("Tot", species))		// renamed tab Tot instead of Total to save space
		wave/z Spec_CE1 =$"root:CE:ToTal_CE1"
		wave/z Spec_CDCE =$"root:CE:Total_CDCE"
	else		// CE tab.... show CE1 and CDCE
		wave/z Spec_CE1 =$"root:CE:"+species+"_CE1"
		wave/z Spec_CDCE = $"root:CE:"+species+"_CDCE"
	endif
	
	//1.09A
	if (!WaveExists(Spec_CE1) || !WaveExists(Spec_CDCE) )
		return 0
		// abort "Perhaps you have changed your todo wave.  Could not find waves "+nameofWave(Spec_CE1) +" or "+nameofWave(Spec_CDCE) +"  aborting from SQ_populate_CETSGraph"
	endif

	wave/z One2one = root:panel:One2one		//1.07A
	if (!WaveExists(One2One))
		make/o/n=2 root:One2One = {0,1}
		wave One2one = root:One2one		//1.07A
	endif
	
	SpecColorList = SQ_getColorListSpecies(Species)

	if (WhichListItem("one2one", TraceNameList(WinName(1, 1), ";", 1 ))<0 )
		AppendToGraph one2one vs one2one
	endif
	AppendToGraph Spec_CDCE vs Spec_CE1
	
	ModifyGraph mode($NameofWave(Spec_CDCE))=2
	ModifyGraph lSize($NameofWave(Spec_CDCE))=2
	ModifyGraph rgb($NameofWave(Spec_CDCE))=(str2num(stringFromList(0, SpecColorList)) ,str2num(stringFromList(1, SpecColorList)),str2num(stringFromList(2, SpecColorList)))
	
	ModifyGraph rgb($NameOfWave(one2one))=(0,0,0)
	ModifyGraph grid=2
	ModifyGraph gridRGB=(34816,34816,34816)
	ModifyGraph nticks=9
	ModifyGraph minor=1
	Label bottom "µg/m3, CE=user default, "+Species		// +", µg/m3"
	Label left "µg/m3, CE=CD,  "+Species		// +", µg/m3"

	waveStats/q Spec_CDCE
	minTemp = V_min
	maxTemp = V_max 
	waveStats/q Spec_CE1
	minTemp = min(0, min( V_min, minTemp))
	maxTemp = max(V_max, maxTemp)

	if (!stringmatch(Species, "CE Stats"))
		variable defaultCE = str2num(GetUserData("CE_Panel", "", "defaultCE" ) )
		ModifyGraph offset={0,0},muloffset(One2One)={maxTemp,(1/defaultCE)*maxTemp}
	endif

	ModifyGraph 	zColor($NameofWave(Spec_CDCE))={root:CE:CETypeFlag,1,14,dBZ14,0}
	
	SetAxis left minTemp,maxTemp
	SetAxis bottom minTemp, maxTemp

End


//1.52
Function sq_populate_CEHistGraph()
	AppendtoGraph root:CE:CE_hist
	ModifyGraph mode=6
	ModifyGraph rgb=(65280,16384,35840)
	Label left "normalized frequency"
	Label bottom "CE_fphase"
	ModifyGraph grid=2,gridRGB=(34816,34816,34816)
End


//1.52
//Function sq_CEHelpButtonProc(ctrlName) : ButtonControl
//	String ctrlName
//	
//	browseurl /z "http://cires.colorado.edu/jimenez-group/wiki/index.php/ToF-AMS_Analysis_Software#Composition_Dependent_Collection_Efficiency_.28CE_Panel.29"
//
//End


//1.52
Function sq_populate_CEfphaseTable() 

	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:CE:
	wave CETypeFlag,ANMF,NH4_MeasToPredict,NH4_CE1,CE_dry
	AppendtoTable CETypeFlag,::CE_fPhase,ANMF,NH4_MeasToPredict,NH4_CE1,CE_dry
	ModifyTable format(Point)=1,width(Point)=51,width(CETypeFlag)=239,title(CETypeFlag)="8=belowMinNH4;3=ANMF;10=acidic;1=UseRH;12=nan"
	ModifyTable sigDigits(::CE_fPhase)=3,width(::CE_fPhase)=60,sigDigits(ANMF)=3,width(ANMF)=50
	ModifyTable sigDigits(NH4_MeasToPredict)=3,width(NH4_MeasToPredict)=48,sigDigits(NH4_CE1)=3
	ModifyTable width(NH4_CE1)=53,sigDigits(CE_dry)=3,width(CE_dry)=51
	SetDataFolder fldrSav0

	variable useRH = str2num( GetUserData("CE_Panel", "", "UseRH" ))
	if (useRH)
		string RHWaveStr = GetUserData("CE_Panel", "", "RHwave" )
		wave RHwave = $"root:"+RHWaveStr
		AppendToTable RHwave
//		ModifyTable width($NameofWave(RHwave))=44, sigDigits($NameofWave(RHwave))=3
	endif

End


//1.52
Function sq_populate_AcidityHistGraph()
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:CE:
	wave Acidity_Hist
	AppendToGraph Acidity_Hist
	variable mymax =WaveMax(acidity_hist)
	SetDataFolder fldrSav0
	ModifyGraph mode=6
	ModifyGraph grid=2
	ModifyGraph gridRGB=(34816,34816,34816)
	Label left "Normalized Frequency"
	Label bottom "NH4 meas/NH4 predict"
	SetDrawLayer UserBack
	SetDrawEnv xcoord= bottom,ycoord= left,linefgc= (65280,65280,32768),fillpat= 34,fillfgc= (65280,65280,32768),fillbgc= (65280,65280,16384)
	DrawRect 0,0,0.75,mymax		// instead of using .75 perhaps we should attach to humidityCutoff parameter in CE_fphase function
	DrawText 0.2,0.2,"is acidic"
End


Function sq_populate_ANMFHistGraph() 		// in Ann's paper but now combined into sq_populate_ANMFOrgMF_hist_graph
	PauseUpdate; Silent 1		// building window...
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:CE:
	wave ANMF_Hist
	AppendToGraph ANMF_Hist
	SetDataFolder fldrSav0
	ModifyGraph mode=6
	ModifyGraph grid=2
	ModifyGraph gridRGB=(34816,34816,34816)
	Label left "normalized frequency"
	Label bottom "ANMF"
End


Function sq_populate_OrgMFHistGraph()	// in Ann's paper but now combined into sq_populate_ANMFOrgMF_hist_graph
	PauseUpdate; Silent 1		// building window...
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:CE:
	wave OrgMF_Hist
	AppendToGraph OrgMF_Hist
	SetDataFolder fldrSav0
	ModifyGraph mode=6
	ModifyGraph grid=2
	ModifyGraph gridRGB=(34816,34816,34816)
	Label left "normalized frequency"
	Label bottom "Org MF"
End


Function sq_populate_ANMFOrgMFHistGraph() 
	PauseUpdate; Silent 1		// building window...
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:CE:
	wave ANMF_Hist, OrgMF_Hist, SO4MF_Hist
	AppendToGraph ANMF_Hist, OrgMF_Hist, SO4MF_Hist
	SetDataFolder fldrSav0
	ModifyGraph mode=6
	ModifyGraph grid=2
	ModifyGraph gridRGB=(34816,34816,34816)
	Label left "normalized frequency"
	Label bottom "ANMF, OrgMF SO4MF"
	ModifyGraph rgb(ANMF_Hist)=(24576,24576,65280),rgb(OrgMF_Hist)=(0,39168,0), rgb(SO4MF_Hist)=(65280,0,0)
End


Function sq_populate_RelHumHistGraph()
	PauseUpdate; Silent 1		// building window...
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:CE:
	wave Humidity_Hist
	AppendToGraph Humidity_Hist
	variable mymax=WaveMax(humidity_hist)
	SetDataFolder fldrSav0
	ModifyGraph mode=6
	ModifyGraph grid=2
	ModifyGraph gridRGB=(34816,34816,34816)
	Label left "normalized frequency"
	Label bottom "RH, %"
	SetAxis/A/E=1 left
	SetDrawLayer UserBack
	SetDrawEnv xcoord= bottom,ycoord= left,linefgc= (65280,65280,32768),fillpat= 34,fillfgc= (65280,65280,32768),fillbgc= (65280,65280,16384)
	DrawRect 80,0,100,mymax		// instead of using 80 perhaps we should attach to humidityCutoff parameter in CE_fphase function
	DrawText 0.594736842105263,0.160087719298246,"is wet"
End


Function sq_populate_NH4DetLimHistGraph()
	PauseUpdate; Silent 1		// building window...
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:CE:
	wave NH4_hist
	Appendtograph NH4_hist
	SetDataFolder fldrSav0
	ModifyGraph mode=6
	Label left "normalized frequency"
	Label bottom "NH4, CE=1, µg/m3"
	ModifyGraph grid=2
	ModifyGraph gridRGB=(34816,34816,34816)
	ModifyGraph rgb=(52224,34816,0)
	variable lowNH4Val=str2num(getuserdata("CE_Panel","","NH4DetLim") )	
	lowNH4Val = numtype(lowNH4Val)==0 ? lowNH4Val : 0
	SetDrawLayer UserBack
	SetDrawEnv xcoord= bottom,ycoord= left,linefgc= (65280,65280,32768),fillpat= 34,fillfgc= (65280,65280,32768),fillbgc= (65280,65280,16384)
	DrawRect pnt2x(root:CE:NH4_hist, 0 ),0,lowNH4Val,Wavemax(root:CE:NH4_hist)
	SetAxis/A/E=1 left
	DrawText 0.2,0.2,"<NH4 Min"
	ModifyGraph zero(bottom)=1
	ModifyGraph nticks=9

End



//1.52
// Generates small panel with CDCE flag legend
Function sq_butt_CETypeFlagLegend(ctrlName) : ButtonControl
	String ctrlName

	DoWindow/F CETypeFlag_Legend
	if (V_flag)
		return 0
	endif
	
	NewPanel/N=CETypeFlag_Legend/W=(150,77,371,166) as "CETypeFlag_Legend"
	TitleBox title0 variable=root:CE:CEStatsStr, frame=0,pos={1,1}

//	NewPanel/k=1/N=CETypeFlag_Legend/W=(150,77,371,166) as "CETypeFlag_Legend"
//	gen_setFont("CETypeFlag_Legend", 12)
//	TitleBox title0 variable=:CE:CEStatsStr, frame=0,pos={1,1}
	
End

Function gen_Killsubwindows(winstr)
string winStr

	string childwinList = ChildWindowList(winStr)
	variable idex, num
	num=itemsinlist(childwinlist)
	for (idex=0;idex<num;idex+=1)
		KillWindow $winstr+"#"+StringFromList(idex, childwinList)
	endfor
End

// For initializing global strings
Function sq_initializeGlobalSVar(SVarName, SVarVal)
string SVarName
string SVarVal

	svar/z myVar = $SVarName
	if (!SVar_Exists(myVar))
		string/g $SVarName
		SVar/z myVar = $SVarName
		myVar = SVarVal
	endif

End

Function/s SQ_getColorListSpecies(Species)
	string Species
	SetDataFolder root:CE
	//wave col_r=root:frag:col_r
	//wave col_g=root:frag:col_g
	//wave col_b=root:frag:col_b
	Make/O/D/N=5 col_r, col_g, col_b
	col_r={0,65535,65535,0,65535,0}
	col_g={52224,0,43690,0,0,0}
	col_g={0,0,0,65535,52224,0}
	Make/O/T/N=5 col_names
	col_names ={"OM","SO4","NH4","NO3","Cl","Total"}
//	wave /z/t col_names=root:col_names

	variable idex, num
	string returnList = "0;0;0"		// default to black
	
	idex=sq_findstr(col_names,Species, 1)
	
	if (idex>=0)
		return num2str(col_r[idex])+";"+num2str(col_g[idex])+";"+num2str(col_b[idex])
	endif
	
	return returnList

End

// CE end ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


// Error calculations

//^ Fetch function to extract other waves from the info val or parval data sets.
//^  Initial list of extra values were created by Ken D to help with some error calculation issues.
//^ The list of values to extract is intended to be completely modifiable.  That is, no other squirrel functions (as of 1.37C) uses these newly created waves.
//^ Note that it creates two new, somewhat duplicated waves of diag_list_More and diag_loc_More.
//Function sq_correctPre138PToFSticksFetch(index_pos,paramstr,acorn,n_acorns)
	wave index_pos
	string paramstr
	variable acorn
	variable n_acorns
	
	wave source=$stringbykey("acorn_0",paramstr)		//^ PToF_stick_p
	string dest=stringbykey("dest",paramstr)
      	
	sq_dutyCycleCorr(source, acorn==n_acorns-1)		//^ 2nd param indicates whether to kill some items set up for corrections.
	
	//1.14M  UMR
	squirrel_hdf_write(index_pos,source,dest)

End

//^ was originally in SQ err WIP.ipf that James sent on 3/31/2007  // 1.38B
//& Function to calculate errors based on data in Hz
//& Includes only Poisson Stats at the moment.
//& call by:
// squirrel_fetch(all,sq_err_calc,"dest0:mssclosed_p_err;dest1:mssdiff_p_err;samptime0:root:diagnostics:timemsclosed;samptime1:root:diagnostics:timemsopen;","mssclosed_p;mssdiff_p;")
//^  I think James' comments below are dated - 1.38C
//& NEED TO INCLUDE:
//& MS baselines (Poisson)
//& PTOF baselines (Poisson)
//& Electronic noise (integration window dependence)
//LR-Function sq_err_calc(index_pos,paramstr,acorn,n_acorns)
	wave index_pos
	string paramstr
	variable acorn,n_acorns
	
	wave source0=$stringbykey("acorn_0",paramstr)			//^ Closed or PToF  	//OPEN
	wave /z source1=$stringbykey("acorn_1",paramstr)		// Diff or nothing		/CLOSED
	string deststr0=stringbykey("dest0",paramstr)			// Closed or PToF 	 // MSSClosed_p_err
	string sampTimeClosedStr=stringbykey("sampTimeClosed",paramstr)	// Closed or PToF 	// timeMSClosed
	string deststr1=stringbykey("dest1",paramstr)			// Diff or never exists   // MSSDiff_p_err
	string sampTimeOpenStr=stringbykey("sampTimeOpen",paramstr)	// Open or nothing 	// timeMSOpen
	wave /z source2=$stringbykey("acorn_2",paramstr)		// Open		// MSSOpenBaseL_p
	wave /z source3=$stringbykey("acorn_3",paramstr)		// Closed		// MSSClosedBaseL_p

//	wave nSecMSsamplingInterval= root:diagnostics:nSecMSsamplingInterval		//1.54D

//	variable PutInMemory=numtype(numberbykey("PutInMemory",paramstr) == 0) ? 0 : 1		// 1.47E
	variable PutInMemory=numberbykey("PutInMemory",paramstr)
	PutInMemory = numtype(PutInMemory)==0 ? 0 : 1			// GGGRRR bug in 1.49B   ) in the wrong place!
	// if this param is not sent then presume that we do the usual thing and keep file in memory

	wave series_index = root:index:series_index
	wave /z corr_fact= root:diagnostics:corr_fact
	
	wave /z ionSingleStr_wave=root:diagnostics:ionSingleStr
	if (!waveexists(ionSingleStr_wave) || numpnts(ionSingleStr_wave)==0)
		wave ionSingleStr_wave=root:diagnostics:ionSingleStr_logged
	endif

	wave ToFPulserInHz=root:diagnostics:ToFPulserInHz

	variable sigma=numberbykey("sigma",paramstr)^2		//Sigma is the sqrt(1+dSI2) from the formula in James' Word doc
	variable noise=numberbykey("noise",paramstr)
					
//	wave samptimeOpen=$ReplaceString("/", sampTimeOpenStr, ":")
//	wave samptimeClosedTemp = $ReplaceString("/", sampTimeClosedStr, ":")
//	Wave samptimeClosed = sq_AdjustClosedTimeForErrCalcs(sampTimeClosedTemp, sampTimeOpen)
//LR-	wave/wave TimeWaves=sq_GetModifiedTimes()
	wave TimeWaves
//LR-	wave samptimeOpen = TimeWaves[0]
//LR-	wave samptimeClosed = TimeWaves[1]
//LR-	wave TimePToF = TimeWaves[2]

	//1.44B	// Sanna had issues that the dimensions of these two matrices were off by 1
	// we assume that the very last m/z column doesn't matter much....
//	variable numCols0 = dimSize(source0, 1)
//	variable numCols1 = dimSize(source1, 1)

//LR-	if (numCols0 > numCols1)
//LR-		insertpoints/m=1 numCols1, (numCOls0 - numCols1 ), source1
//LR-	elseif (numCols0 < numCols1)
//LR-		deletepoints/m=1 numCols0, numCOls1, source1
//		insertpoints/m=1 numCols0, (numCOls1 - numCols0), source0  //1.59E
//LR-	endif

	sq_findIntegrationWidthNs(dimsize(source0,0),dimsize(source0,1),dimsize(source0,2), index_pos)		//^
	wave IntegrationWidthNs = root:IntegrationWidthNs
	
//	if (!waveexists(source1))		//PToF data
//		wave samptime=$samptimestr0
//		matrixop /o err_tmpPToF=abs(source0) //^ PTOF data
//		wave err_tmpPToF
//		err_tmpPToF *= sigma/samptime[series_index[index_pos[p]]]
//		if (waveexists(corr_fact))
//			err_tmpPToF /=corr_fact[series_index[index_pos[p]]]
//		endif
//		err_tmpPToF *= sqrt(28/(r+1)) 
//		err_tmpPToF += noise*noise*IntegrationWidthNs[p][q][r]*28/((ion_wave[series_index[index_pos[p]]]^2)*ToFPulserInHz[series_index[index_pos[p]]]*(r+1))
//		err_tmpPToF=sqrt(err_tmpPToF)		
//		//1.14M  PToF sticks, should be already trimmed, UMR
//		squirrel_hdf_write(index_pos,err_tmpPToF,deststr0)
//	else //& MSSDiff data - calculate for open
//		wave samptimeClosed=$samptimestr0
//		wave samptimeOpen=$samptimestr1

//LR-		matrixop /o err_tmpClosed=abs(source0)		
//LR-		wave err_tmpClosed
//LR-		matrixop /o err_tmpOpen=abs(source1+source0)		//^ reconstruct open by adding diff and closed
//LR-		wave err_tmpOpen
		// 1.50K addition begin
//LR-		matrixop /o err_tmpClosedBase=abs(source3)		//1.153Err	
//LR-		wave err_tmpClosedBase
//LR-		matrixop /o err_tmpOpenBase=abs(source2)		//^ reconstruct open by adding diff and closed
//LR-		wave err_tmpOpenBase
		// 1.50K addition end
//LR-		err_tmpClosed*=(index_pos[p]<0 ? 0 : sigma/samptimeClosed[series_index[index_pos[p]]])
//LR-		err_tmpOpen*=(index_pos[p]<0 ? 0 : sigma/samptimeOpen[series_index[index_pos[p]]])
		// 1.50K addition begin
//LR-		err_tmpClosedBase*=(index_pos[p]<0 ? 0 : sigma/samptimeClosed[series_index[index_pos[p]]] )
//LR-		err_tmpOpenBase*=(index_pos[p]<0 ? 0 : sigma/samptimeOpen[series_index[index_pos[p]]] )
		// 1.50K addition end
		
		if (waveexists(corr_fact))
			err_tmpClosed/=(index_pos[p]<0 ? 0 : corr_fact[series_index[index_pos[p]]] )
			err_tmpOpen/=(index_pos[p]<0 ? 0 : corr_fact[series_index[index_pos[p]]] )
			// 1.50K addition begin
			err_tmpClosedBase/=(index_pos[p]<0 ? 0 : corr_fact[series_index[index_pos[p]]] )
			err_tmpOpenBase/=(index_pos[p]<0 ? 0 : corr_fact[series_index[index_pos[p]]] )
			// 1.50K addition end
		endif
		
		err_tmpClosed*=sqrt(28/(q+1)) 		// we start our m/z matrix dimension at m/z 1.  When q = 0, m/z = 1 
		err_tmpOpen*=sqrt(28/(q+1))
		// 1.50K addition begin
		err_tmpClosedBase*=sqrt(28/(q+1)) 		// we start our m/z matrix dimension at m/z 1.  When q = 0, m/z = 1 
		err_tmpOpenBase*=sqrt(28/(q+1))
		// 1.50K addition end
		duplicate/o err_tmpClosed err_tmp
		wave err_tmp
		err_tmp = (index_pos[p]<0 ? 0 : noise*noise*IntegrationWidthNs[p][q]*28/((ionSingleStr_wave[series_index[index_pos[p]]]^2)*ToFPulserInHz[series_index[index_pos[p]]]*(q+1))  )
		err_tmpClosed+=err_tmp
		err_tmpOpen+= err_tmp
		// 1.50K addition begin
		err_tmpClosedBase+=err_tmp
		err_tmpOpenBase+= err_tmp
		// 1.50K addition end
		// below, more officially,  it is sqrt(   sqrt(err_tmpOpen)^2 + sqrt(err_tmpClosed)^2 ) 
//		err_tmp=sqrt(err_tmpOpen+err_tmpClosed)	// now the use of err_tmp changes from Electronic error to Diff error	
		err_tmp=sqrt(err_tmpOpen+err_tmpClosed+err_tmpClosedBase+err_tmpOpenBase)	// now the use of err_tmp changes from Electronic error to Diff error	
		// 1.50K addition end
		if (PutInMemory==1)		//1.47E
			squirrel_mem_write(index_pos,err_tmp,deststr1,deststr1)		// Diff
		else
			//1.14M  UMR
			squirrel_hdf_write(index_pos,err_tmp,"MSSDiff_p_err")
		endif
		err_tmpClosed=sqrt(err_tmpClosed+err_tmpClosedBase)
		// change in 1.46E, don't put the closed err in memory, write to hdf
		//1.14M  UMR
		squirrel_hdf_write(index_pos,err_tmpClosed,"MSSClosed_p_err")
		// added in 1.46E
		err_tmpOpen=sqrt(err_tmpOpen+err_tmpOpenBase)
		//1.14M  UMR
		squirrel_hdf_write(index_pos,err_tmpOpen,"MSSOpen_p_err")
//	endif
		
// Need to include some lines of code to add the baseline values to the ion signal waves 
//^This is true for both MS (via saving some baseline parameters info for each run) and PToF (via saving some DC marker values for each run)
	
	if (acorn==n_acorns-1)
		killwaves /z err_tmpClosed,err_tmpOpen, err_tmpPToF, err_tmp, IntegrationWidthNs, err_tmpOpenBase,err_tmpClosedBase, samptimeClosedModified	
		killwaves/z Timewaves
	endif

End

//1.57I
// source dimensions for MS are runs x mz 
// source dimensions for PToF are runs x PToF x mz 
// result  for MS will be runs x mz if product has mz dimension, else runs
// result  for MS will be runs x mz  x PToF if product has if product has mz dimension
// 

//LR-Function/wave sq_ApplyFragWaves(source, specDex, destlist, speclist, product_type, error_flag, matDFStr, numMzSticks, numRunsInThisAcorn, n_t,[index_pos, source_err2])
wave source, index_pos, source_err2
string destlist, speclist, matDFStr
variable specDex, product_type, error_flag, numMzSticks,numRunsInThisAcorn, n_t

	wave series_index = root:index:series_index
	variable  n_dep, depdex, opfaclist_n, opfacdex, runDex
	string destStr, specStr
	
	deststr=stringfromlist(specDex, destlist,"/")
	deststr=ReplaceString("@", deststr, ":" )  //1.25H
	wave dest=$deststr
	wave /z dest_n=$("conc_weight_"+num2str(specdex)),dest_err=$(deststr+"_err")		
	specStr=stringfromlist(specdex,speclist,"/")
				
	Make/O/WAVE/N=(error_flag ? 2 : 1) waveRefs

	// apply frag-converted op wave to data

//	wave op_sparse=root:ms_mats:$(specStr+"_sparse")		// i.e. Org_sparse
//	wave op_vec=root:ms_mats:$(specStr+"_vec")			// i.e. Org_vec
	wave op_sparse=$matDFStr+specStr+"_sparse"		// i.e. Org_sparse
	wave op_vec=$matDFStr+specStr+"_vec"			// i.e. Org_vec

//	// Initialise dependencies 1.46A  JDA
	wave /z opdep=$matDFStr+specStr+"_dep"				// i.e. Org_dep  if using i.e. CO2FracWave then this has dims (10,2)
	wave /z/t opdepstr=$matDFStr+specStr+"_depstr"		// i.e. Org_depStr  if using i.e. CO2FracWave then this has dims (10)  .... all the affected frag entries in 'words'
	if (waveexists(opdep))
		if (!(product_type&2)) // Total product
			make /o/n=(numMzSticks,1,numRunsInThisAcorn) op_dep1=op_vec[p]		// i.e. if mz is 700 and runs are 120 then op_dep1 = 700x1x120 and looks like Org_vec (700) for every layer
		endif
		n_dep=dimsize(opdep,0)		// i.e. 10.. the number of mzs affected
		make /o/n=(n_dep,numRunsInThisAcorn) op_dep2  // i.e. 10x120  big enough to take care of this acorn
		for (depdex=0;depdex<n_dep;depdex+=1)	// for each mz affected
			opfaclist_n=itemsinlist(opdepstr[depdex],"*")-1	// the number of dependencies..i.e. 1.  in theory one could have a frag entry that looked like CO2FracWave*anotherwave*frag_air[28]
			op_dep2[depdex][]=str2num(stringfromlist(opfaclist_n,opdepstr[depdex],"*"))  // work from the end  CO2FracWave*0.00037*1.36*1.28*1.14*frag_air[28]  gets collapsed to  CO2FracWave*0.000734269
			for (opfacdex=0;opfacdex<opfaclist_n;opfacdex+=1)  // for each dependencies..i.e. 1
				wave /z opdepwav=$stringfromlist(opfacdex,opdepstr[depdex],"*")		//  CO2FracWave
				if (!waveexists(opdepwav))
					op_dep2[depdex][]=0
					print "// ***Dependency wave "+stringfromlist(depdex,opdepstr[depdex],"*")+" not found!!***"
					break
				endif
//				op_dep2[depdex][]*= index_pos[q]>=0 ? opdepwav[series_index[index_pos[q]]]	 : 0 //1.20X	// here is where we actually replace CO2FracWave with values within this wave
				for(runDex=0;runDex<numRunsInThisAcorn;rundex+=1 )  	//1.20X
					if (index_pos[runDex]>=0)
						op_dep2[depdex][runDex]*=opdepwav[series_index[index_pos[runDex]]]
					endif
				endfor
			endfor
			if (!(product_type&2))
				op_dep1[opdep[depdex][0]][0][]+=op_dep2[depdex][r]		// recall op_dep1 dims are (numMzSticks,1,numRunsInThisAcorn and op_dep2 dims are  (n_dep,numRunsInThisAcorn) 
			endif
		endfor
	endif  	// endif dependencies exist	
		
// Arrange source data so rows pToF, columns are m/z and layers are time
//	if (dimSource2==0) // MS Data   //1.21G
	variable MSDataFlag = dimsize(source,2)==0 
	
	if (MSDataFlag) // product_type<4) // MS Data  //1.22A
		redimension /n=(numRunsInThisAcorn,numMzSticks,1) source  // runs x mz x fakePTOF
		imagetransform /g=3 transposevol source		// M_VolumeTranspose=imageMatrix [r][q][p]
	else
		 //pTOF Data
		imagetransform /g=4 transposevol source		// M_VolumeTranspose=imageMatrix [q][r][p]
	endif
	wave m_volumetranspose 			
 	// m_volumetranspose for ms  fake PToF x mz x runs 	
 	// m_volumetranspose for PToF  PToF x mz x runs 	
 		
// Perform the operation
	if (product_type&2) // MS product
		make /o/n=(  (product_type&4 && (product_type!=11 && product_type!=14) ) ? (n_t):(1),numMzSticks,numRunsInThisAcorn) mass_tmp
		fastop mass_tmp=(0)
		sq_sparsemult(op_sparse,m_volumetranspose,mass_tmp,"",1)	//1.46A  
		if (waveexists(opdep)) // Apply dependency
			sq_sparsemult(opdep,m_volumetranspose,mass_tmp,NameOfWave(op_dep2),1)
		endif
	else // Total product
		if (waveexists(opdep)) // Dependency
			matrixop /o mass_tmp=m_volumetranspose x op_dep1
		else
			matrixop /o mass_tmp=m_volumetranspose x op_vec
		endif
		if (dimsize(mass_tmp,2)==0)
			redimension /n=(-1,-1,1) mass_tmp
		endif
	endif
		
// Arrange destination data to expected form
//	variable MSDataFlag = dimsize(source,2)==0 //1.22G	
	if (MSDataFlag) // product_type<4) // MS Data  //1.22A
//	if (product_type<4) // source data is MS
		imagetransform /g=3 transposevol mass_tmp		// /g=3 M_VolumeTranspose=imageMatrix [r][q][p]
		matrixop /o mass_tmp=m_volumetranspose[][][0]
		if (product_type<2)
			redimension /n=(numRunsInThisAcorn) mass_tmp
		endif
	else // source data is PTOF
		if (product_type<6)
			imagetransform /g=2 transposevol mass_tmp	// /g=2 M_VolumeTranspose=imageMatrix [r][p][q]
			matrixop /o mass_tmp=m_volumetranspose[][][0]
		else
			imagetransform /g=3 transposevol mass_tmp	// /g=3 M_VolumeTranspose=imageMatrix [r][q][p]
			duplicate /o m_volumetranspose,mass_tmp
		endif
	endif

	// mass_tmp  runs x mz x (PToF) for results with mz dimension
	// mass_tmp  runs x (PToF) for results without mz dimension

	waveRefs[0] = mass_tmp

	if (error_flag)
// Arrange source data so rows pToF, columns are m/z and layers are time
		if (MSDataFlag) // product_type<4) // MS Data
			redimension /n=(numRunsInThisAcorn,numMzSticks,1) source_err2
			imagetransform /g=3 transposevol source_err2 	// /g=3 M_VolumeTranspose=imageMatrix [r][q][p]
		else //pTOF Data
			imagetransform /g=4 transposevol source_err2	// /g=4 M_VolumeTranspose=imageMatrix [q][r][p]
		endif
		wave m_volumetranspose				
			
// Perform the operation
		if (product_type&2) // MS product
			make /o/n=(product_type&4?(n_t):(1),numMzSticks,numRunsInThisAcorn) mass_tmp_err
			fastop mass_tmp_err=(0)
			sq_sparsemult(op_sparse,m_volumetranspose,mass_tmp_err,"",2)		// 1.46A		// imp bug Fix in 1.47H
			if (waveexists(opdep)) // Apply dependency
				sq_sparsemult(opdep,m_volumetranspose,mass_tmp_err,NameOfWave(op_dep2),2) //1.46A // imp bug Fix in 1.47H
			endif
		else // Total product
			if (waveexists(opdep)) // Dependency
				matrixop /o mass_tmp_err=m_volumetranspose x powr(op_dep1,2)  // imp bug Fix in 1.47H
			else
				matrixop /o mass_tmp_err=m_volumetranspose x powr(op_vec,2)  // imp bug Fix in 1.47H
			endif
 			endif
// Arrange destination data to expected form
		if (MSDataFlag) // product_type<4) //MS
			imagetransform /g=3 transposevol mass_tmp_err 	// /g=3 M_VolumeTranspose=imageMatrix [r][q][p]
			matrixop /o mass_tmp_err=m_volumetranspose[][][0]
			if (product_type<2)
				redimension /n=(numRunsInThisAcorn) mass_tmp_err
			endif
		else // PTOF
			if (product_type<6)
				imagetransform /g=2 transposevol mass_tmp_err  	// /g=3 M_VolumeTranspose=imageMatrix [r][p][q]
				matrixop /o mass_tmp_err=m_volumetranspose[][][0]
			else
				imagetransform /g=3 transposevol mass_tmp_err  	// /g=3 M_VolumeTranspose=imageMatrix [r][q][p]
				duplicate /o m_volumetranspose,mass_tmp_err
			endif
		endif
		
		waveRefs[1] = mass_tmp_err

	endif

	if(MSDataFlag)
		redimension /n=(numRunsInThisAcorn,numMzSticks) source  // 1.22A
	endif
	
	return waveRefs

End

// PMF - function below was copied from Igrid Ulbrich's pmf_errPrep_ToF-AMS_OneIOnEquiv_v2.3.ipf
CONSTANT PMF_AVOGADRO=6.0221367e23    //& Avagadro's number
CONSTANT PMF_AW_NO3 = 62  //atomic weight of nitrate, defaults to 62 (it is rounded, not exact)
////////////////////////////////////////////////////////////////////
// identical to pmf_err_minErr1ion_ugm3, except now returns the name of the created igor wave
//LR-Function/s Err_minErr1ion(conv2ugm3Flag, TimeMeasuringWave)
variable conv2ugm3Flag
wave TimeMeasuringWave

	variable idex
	string resultStr
	
	// 0.  get current todo wave
	svar/z sq_toDoWvNm = root:panel:sq_toDoWvNm
	wave toDoWv = $sq_toDoWvNm

	wave rn_series = root:index:rn_series

	NewDataFolder/o root:PMFOutput

	make/O/N=(numpnts(rn_series)) root:PMFOutput:minErr1ion = 1/TimeMeasuringWave	
	wave minErr1ion= root:PMFOutput:minErr1ion 

	// 2.  Hz to ug/m3 correction factor
	if(conv2ugm3Flag == 1)
		
		wave/Z ioneff = root:diagnostics:ioneff
		wave/Z flowrate = root:diagnostics:flowrate
		wave/Z corr_fact = root:diagnostics:corr_fact

		if (!WaveExists(ioneff))
			wave/Z ioneff = root:diagnostics:ioneff_logged
		endif
		make/FREE/o/n=(numpnts(rn_series)) ugfac_wav_tmp
		if(waveexists(ioneff) && waveexists(flowrate))
			ugfac_wav_tmp=(PMF_AW_NO3/PMF_AVOGADRO)*1e12/(ioneff[p]*flowrate[p])     // presumes ioneff exists; you did the AB corrections
			if(waveexists(corr_fact))
				ugfac_wav_tmp*=corr_fact[p]      // if you want to fold in the Airbeam correction factor
			else
				print "Airbeam correction factor was not applied."
			endif	

			// apply to hz wave		
//			duplicate/O minErr1ion_Hz_all, minErr1ion_ugm3_all
			minErr1ion *= ugfac_wav_tmp
//			minErr1ion_ugm3_all *= ugfac_wav_tmp
		else
			print "Conversion to ug/m3 could not be completed because ioneff or flowrate was not available."
		endif
		
		// apply to hz wave
	endif

	// extract current todo from all
	make/o/FREE maskwave      // will be redimensioned correctly
	sq_makeMaskFromTodofindRun(maskwave,toDoWv)   // maskwave makes a wave of 1s and 0s
//	Extract/o minErr1ion_Hz_all, minErr1ion_Hz, maskwave>=0  // hand extract function
//	if(waveexists(minErr1ion_ugm3_all))
//		Extract/o minErr1ion_ugm3_all, minErr1ion_ugm3, maskwave>=0
//	endif
	
	minErr1ion = SelectNumber(maskwave[p] , nan, minErr1ion[p])
	return "root:PMFOutput:minErr1ion"
	
end

Function sq_butt_popThis(ctrlName) : ButtonControl
	String ctrlName
	
	sq_WindowIsToBePopped(ctrlName[7, strlen(ctrlName)-1])	// the pop button controls MUST be named correctly, such as button_Mz_PpmGraph

End
