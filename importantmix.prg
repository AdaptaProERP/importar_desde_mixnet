// Programa   : IMPORTANTMIX        
// Fecha/Hora : 29/08/2020 23:04:32
// Propósito  : Importar Anticipos desde MIXNET Caso del Club, Importa Como Cuotas aquellos montos =30 o 60 USD
// Creado Por : Juan Navas
// Llamado por:
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN(cFile,lDelete)
  LOCAL aData:={},aLine:={},nContar:=0
  LOCAL oMovInv,oTable,nCxC,cTipDoc:="CUO",nPrecio,cNumero,nMonto,nValCam

  DEFAULT cFile  :="C:\MIXCLUB\COMP01\mxtrapag.dbf",;
          lDelete:=.F.

  IF !FILE(cFile)
    ? cFile,"NO EXISTE"
    RETURN .T.
  ENDIF

  IF lDelete
    SQLDELETE("DPDOCCLI")
    SQLDELETE("DPMOVINV")
    RepViewDbf(cFile,cFile)
  ENDIF

  nCxC   :=EJECUTAR("DPTIPCXC",cTipDoc)

  oMovInv:=INSERTINTO("DPMOVINV",NIL,100)

  oMovInv:lAuditar:=.F.
  oMovInv:lFileLog:=.T.

  oTable:=INSERTINTO("DPDOCCLI",NIL,100)

  oTable:lAuditar:=.F.
  oTable:lFileLog:=.T.
 
  oTable:EXECUTE("SET FOREIGN_KEY_CHECKS = 0")


 SELECT A
 CLOSE ALL
 USE (cFile)

 
// SET FILTER TO VENCE>=CTOD("01/09/2023") .AND. TIPO="ND"
 GO TOP


 WHILE !A->(EOF()) 

     IF VENCE>=CTOD("01/09/2023") .AND. TIPO="ND"

       nContar++
 
       IF nContar%10=0
          SysRefresh(.T.)
       ENDIF
  
       oDp:oFrameDp:SetText(LSTR(nContar)+" "+LSTR(nMonto))
       // cNumero:=LEFT(B->NUMALB,2)+"00"+RIGHT(B->NUMALB,6)
       cNumero:=A->NUMDOC
       nValCam:=A->CAMBIO
       nMonto :=ROUND(A->IMPORTE/A->CAMBIO,2)

       // todos son anticipos Menores de 30 USD
       IF INT(nMonto)<-30
         EJECUTAR("DPDOCCLICREA",NIL,"ANT",cNumero,A->CODMOVCLI,A->VENCE,oDp:cMonedaExt,"V",NIL,nMonto,IMP_IVA,nValCam,VENCE,NIL,oTable,"N",nCxC*-1)
       ENDIF

       // genera la Cuota cuando es igual a 30 dolares
       IF INT(nMonto)=-30
          EJECUTAR("DPDOCCLICREA",NIL,cTipDoc,cNumero,A->CODMOVCLI,A->VENCE,oDp:cMonedaExt,"V",NIL,nMonto,IMP_IVA,nValCam,VENCE,NIL,oTable,"N",nCxC*0) // cuotas neutras
          SQLUPDATE("DPDOCCLI",{"DOC_TIPORG","DOC_CODTER"},{"MIX",oDp:cCodter},"DOC_TIPDOC"+GetWhere("=","CUO")+" AND DOC_NUMERO"+GetWhere("=",oDp:cNumero))
          EJECUTAR("DPMOVINVCREA",oDp:cSucursal,cTipDoc,cNumero,"CSSP",1,ABS(nMonto),"MENSUAL",1,0,"",VENCE,"V",VENCE,A->MOVCODCLI,"GN",0,nValCam,oMovInv)
       ENDIF
    
       IF INT(nMonto)=-60

          // SEPTIEMBRE
          EJECUTAR("DPDOCCLICREA",NIL,cTipDoc,cNumero,A->CODMOVCLI,A->VENCE,oDp:cMonedaExt,"V",NIL,nMonto/2,IMP_IVA,nValCam,VENCE,NIL,oTable,"N",nCxC*0) // cuotas neutras
          SQLUPDATE("DPDOCCLI",{"DOC_TIPORG","DOC_CODTER"},{"MIX",oDp:cCodter},"DOC_TIPDOC"+GetWhere("=","CUO")+" AND DOC_NUMERO"+GetWhere("=",oDp:cNumero))
          EJECUTAR("DPMOVINVCREA",oDp:cSucursal,cTipDoc,cNumero,"CSSP",1,ABS(nMonto/2),"MENSUAL",1,0,"",VENCE,"V",VENCE,A->MOVCODCLI,"GN",0,nValCam,oMovInv)

          // OCTUBRE
          EJECUTAR("DPDOCCLICREA",NIL,cTipDoc,cNumero,A->CODMOVCLI,FCHFINMES(A->VENCE)+1,oDp:cMonedaExt,"V",NIL,nMonto/2,IMP_IVA,nValCam,VENCE,NIL,oTable,"N",nCxC*0) // cuotas neutras
          SQLUPDATE("DPDOCCLI",{"DOC_TIPORG","DOC_CODTER"},{"MIX",oDp:cCodter},"DOC_TIPDOC"+GetWhere("=","CUO")+" AND DOC_NUMERO"+GetWhere("=",oDp:cNumero))
          EJECUTAR("DPMOVINVCREA",oDp:cSucursal,cTipDoc,cNumero,"CSSP",1,ABS(nMonto/2),"MENSUAL",1,0,"",FCHFINMES(A->VENCE)+1,"V",VENCE,A->MOVCODCLI,"GN",0,nValCam,oMovInv)

       ENDIF

       nPrecio:=nMonto/(1.16)
       SQLUPDATE("DPMOVINV",{"MOV_ASOTIP","MOV_FECHA","MOV_IVA","MOV_PRECIO","MOV_TOTAL","MOV_LISTA"},{"MIX",B->EMISION,16,nPrecio,nPrecio,"A"},"MOV_TIPDOC"+GetWhere("=",cTipDoc)+" AND MOV_DOCUME"+GetWhere("=",cNumero))

    ENDIF

    SELECT A
   
    SKIP 

    IF nContar>5
     // EXIT
    ENDIF

  ENDDO

  SQLUPDATE("DPCLIENTES","CLI_CODMON","DBC")

  ? LSTR(nContar)+" Registros Migrados en "+LSTR(ABS(SECONDS()-nT1)/60)+" Minutos"

  oTable:EXECUTE("SET FOREIGN_KEY_CHECKS = 1")
  oTable:End()
  oMovInv:End()

  SELECT A

  GO TOP


 WHILE !EOF()
   aLine:={}
   AEVAL(DBSTRUCT(),{|a,n| AADD(aLine,FIELDGET(n))})
   AADD(aData,ACLONE(aLine))



   SKIP
 ENDDO

VIEWARRAY(DBSTRUCT())

A->(BROWSE())
ViewArray(aData)

 CLOSE ALL

// oDp:lTracer:=.T.

RETURN 


 oTable:=OpenTable("SELECT * FROM DPDOCCLI",.F.)
 oTable:Appendblank()

ViewArray(oTable:aDefault)

 ? oTable:DOC_CODSUC
 

RETURN 

/*
  LOCAL cFile:="C:\AVICOLA\LIBRO.XLSX"
  LOCAL cDestino,oMeter:=NIL,oSay:=NIL,lAuto:=NIL,nIni:=2,nCant:=NIL,nHead:=NIL,nColGet:=NIL,lStruct:=.F.,cMaxCol:=NIL,aSelect:=NIL

? cFile,FILE(cFile)

  EJECUTAR("XLSTODBF",cFile,cDestino,oMeter,oSay,lAuto,nIni,nCant,nHead,nColGet,lStruct,cMaxCol,aSelect)
*/
  

RETURN 

? SETLICGRT(.t.,.t.)

  IF nT>oCon:nTimeMax 
    EJECUTAR("MYSQLCHKCONN",.T.)
  ENDIF

// oCon:nSeconds,nT
/*
  oCon:=aDataBase[I,2]:oConnect

  ABS(Seconds()-oForm:nSeconds) >= (oForm:nTimeMax)
     MYSQLCHKCONN() // Validar la Apertura de la BD Usuarios Dormidos
   ENDIF
*/

RETURN .T.

PROCE XMAIN()
  LOCAL oDb:=OpenOdbc(oDp:cDsnData),cSql

  SQLUPDATE("DPRECIBOSCLI","REC_ESTADO","Nulo","REC_ACT=0")

  cSql:=[ UPDATE DPDOCCLI ]+;
        [ INNER JOIN DPRECIBOSCLI ON REC_CODSUC=DOC_CODSUC AND REC_NUMERO=DOC_RECNUM  ]+;
        [ SET DOC_ACT=REC_ACT WHERE DOC_TIPDOC="IGT" AND REC_ACT<>DOC_ACT ]

  oDb:Execute(cSql)
  
  SQLUPDATE("DPDOCCLI","DOC_ESTADO","N","DOC_ACT=0")

  oDb:Execute(cSql)

RETURN 

 

/*
  LOCAL cSql,oTable,cWhere

  EJECUTAR("CREATERECORD","DPUNDMED",{"UND_CODIGO","UND_DESCRI","UND_ACTIVO","UND_CANUND" },;
                                     {"PAR"       ,"PAR"       ,.T.         ,1          },;
                                   NIL,.T.,"UND_CODIGO"+GetWhere("=","PAR"))
*/
RETURN 
 
  cSql:=[ SELECT DOC_CODSUC,DOC_TIPDOC,DOC_TIPTRA,DOC_NUMERO,DOC_FECHA,COUNT(*) AS CUANTOS]+;
        [ FROM DPDOCCLI ]+;
        [ WHERE DOC_TIPTRA="D" ]+;
        [ GROUP BY DOC_CODSUC,DOC_TIPDOC,DOC_TIPTRA,DOC_NUMERO,DOC_FECHA ]+;
        [ HAVING CUANTOS>1 ]+;
        [ ORDER BY DOC_CODSUC,DOC_TIPDOC,DOC_TIPTRA,DOC_NUMERO,DOC_FECHA ]
        
// ? CLPCOPY(cSql)

  oTable:=OpenTable(cSql)
  
  WHILE !oTable:Eof()

      cWhere:="DOC_CODSUC"+GetWhere("=",oTable:DOC_CODSUC)+" AND "+;
              "DOC_TIPDOC"+GetWhere("=",oTable:DOC_TIPDOC)+" AND "+;
              "DOC_TIPTRA"+GetWhere("=",oTable:DOC_TIPTRA)+" AND "+;
              "DOC_NUMERO"+GetWhere("=",oTable:DOC_NUMERO)+" AND "+;
              "DOC_RECNUM"+GetWhere("=",""               )+" AND "+;
              "DOC_FECHA" +GetWhere("=",oTable:DOC_FECHA )

      SQLDELETE("DPDOCCLI",cWhere+" LIMIT 1")

      oTable:DbSkip()

  ENDDO

//oTable:Browse()
  oTable:End()

  EJECUTAR("UNIQUETABLAS","DPCLIENTES"  ,"CLI_CODIGO")
  EJECUTAR("UNIQUETABLAS","DPVENDEDOR"  ,"VEN_CODIGO")
  EJECUTAR("UNIQUETABLAS","DPRECIBOSCLI","REC_CODSUC,REC_NUMERO")

RETURN .T.
// EOF

