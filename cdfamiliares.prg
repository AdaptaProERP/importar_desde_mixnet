// Programa   : CDFAMILIARES
// Fecha/Hora : 19/08/2022 23:22:37
// Propósito  : Club Demócrata, importar activar socios segun archivo SOCIOS.CSV
// Creado Por :
// Llamado por:
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN()
  LOCAL aData,cMemo:="",I,nMax:=0
  LOCAL cFile:="C:\MIXCLUB\COMP99\NMCTATRA.DBF",cRif,cCodigo,cCodCla:="000001"
  LOCAL cVinculo:="",cCodCli,cCodigo,cWhere,nAt,cCodVin,oTable,cCedula,cParent

  CursorWait()

  IF !FILE(cFile)
     ? cFile,"no Existe"
     RETURN .F.
  ENDIF

IF .T.

  EJECUTAR("DPCAMPOSOPCADD","DPCLIENTES","CLI_CATEGO","Socio Propietario"   ,.T.,12976326,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPCLIENTES","CLI_CATEGO","Socio Contribuyente" ,.T.,5505192 ,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPCLIENTES","CLI_CATEGO","Socio Vitalicio"     ,.T.,65535   ,.T.)

  EJECUTAR("DPCAMPOSOPCADD","DPCLIENTESREC","CRC_SEXO","Masculino",.T.,12279296,.T.)
  EJECUTAR("DPCAMPOSOPCADD","DPCLIENTESREC","CRC_SEXO","Femenino" ,.T.,16744703,.T.)

  SQLUPDATE("DPCLIENTES","CLI_CATEGO","Socio Propietario"  ,"CLI_CODCLA"+GetWhere("=","000001"))
  SQLUPDATE("DPCLIENTES","CLI_CATEGO","Socio Contribuyente","CLI_CODCLA"+GetWhere("=","000002"))
  SQLUPDATE("DPCLIENTES","CLI_TRANSP",1,"CLI_TRANSP=0")

  SQLUPDATE("DPCLIENTEPROG","DPG_CODINV","MENSUALIDAD","DPG_NUMDOC"+GetWhere("=","0000000000"))
  SQLUPDATE("DPCLIENTEPROG","DPG_CODINV","ANUALIDAD"  ,"DPG_NUMDOC"+GetWhere("=","0000000001"))

ENDIF

// "AQUI ES"

  close all

  USE (cFile)

// VIEWARRAY(DBSTRUCT())
//
// RETURN 

  SET FILTER TO COND_EMP="A"
  GO TOP

  SQLDELETE("DPCLIENTESREC")

  // oTable:=OpenTable("SELECT * FROM DPCLIENTESREC" ,.F.)
  // oTable:=OpenTable("SELECT * FROM DPCLIENTESREC" ,.F.)
  oTable:=INSERTINTO("DPCLIENTESREC",NIL,10)

  //? RECCOUNT()
  // BROWSE()

  GO TOP

// RETURN 

  
  WHILE !A->(EOF())

     cCodCli:=A->CODTRA
     nAt    :=RAT("-",cCodCli)
     cCedula:=A->CEDULA
     cCodVin:=""
     cParent:=""

     IF nAt>2
       cCodVin:=SUBS(cCodCli,nAt+1,LEN(cCodCli))
       cCodCli:=LEFT(cCodCli,nAt-1)
       cParent:=cCodVin
     ENDIF
 
     cWhere:="CRC_CODIGO"+GetWhere("=",cCedula)+" AND "+;
             "CRC_CODCLI"+GetWhere("=",cCodCli)

      // oTable:=OpenTable("SELECT * FROM DPCLIENTESREC WHERE "+cWhere,.T.)
      //
      // IF oTable:RecCount()=0
      oTable:AppendBlank()
      // oTable:cWhere:=""
      //  ENDIF

      oTable:Replace("CRC_CODIGO",cCedula)
      oTable:Replace("CRC_CODCLI",cCodCli)
      oTable:Replace("CRC_NOMBRE",OemtoAnsi(ALLTRIM(A->APELLIDO)+","+A->NOMBRE))
      oTable:Replace("CRC_ACTIVO",COND_EMP="A")
      oTable:Replace("CRC_FECHA" ,A->FECHA_NAC)
      oTable:Replace("CRC_FCHINI",A->FECHA_ING)

      oTable:Replace("CRC_SEXO"  ,A->SEXO)
      oTable:Replace("CRC_ESTADO","Activo")
      oTable:Replace("CRC_DIR1"  ,A->DIREC1)
      oTable:Replace("CRC_DIR2"  ,A->DIREC2)
      oTable:Replace("CRC_DIR3"  ,A->DIREC3)
      oTable:Replace("CRC_ID"    ,A->CARNET)
      oTable:Replace("CRC_PROFES",OemtoAnsi(A->PROFESION))
      oTable:Replace("CRC_TIPO"  ,"FAMILIAR")
      oTable:Replace("CRC_PARENT",cParent)
      oTable:Replace("CRC_TEL1"  ,A->TELEF1)
      oTable:Replace("CRC_TEL2"  ,A->TELEF2)
      oTable:Replace("CRC_EMAIL" ,A->EMAIL)


//    oTable:Replace("CRC_DESDE",.T.    )

      oTable:lAuditar:=.F.
      oTable:Commit() // oTable:cWhere)
//    oTable:End()
// ? cCodCli,nAt,cCodVin,"cCodVin",cWhere

     // CRC_CODCLI
    
     IF A->(RECNO())>15
      // EXIT
     ENDIF

     A->(DBSKIP())

  ENDDO

  oTable:End()
// ? "OK"

  CLOSE ALL

RETURN .T.
// EOF

