// Programa   : IMPORTANTMIX        
// Fecha/Hora : 29/08/2020 23:04:32
// Propósito  : Importar Anticipos desde MIXNET Caso del Club, Importa Como Cuotas aquellos montos =30 o 60 USD
// Creado Por : Juan Navas
// Llamado por:
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN(cFile,lDelete,dFchIni)
  LOCAL aData:={},aLine:={},nContar:=0,dFecha,cSql
  LOCAL oMovInv,oTable,nCxC,cTipDoc:="CUO",nPrecio,cNumero,nMonto,nValCam,NT1
  LOCAL nMontoDiv

  DEFAULT cFile  :="C:\MIXCLUB\COMP01\mxtrapag.dbf",;
          lDelete:=.f.

  IF !FILE(cFile)
    ? cFile,"NO EXISTE"
    RETURN .T.
  ENDIF

  DEFAULT dFchIni:=FCHINIMES(oDp:dFecha)

  IF COUNT("DPCLIENTES")<=1
     EJECUTAR("IMPORTMXCLI")  
  ENDIF

  SQLDELETE("DPDOCCLI","DOC_TIPDOC"+GetWhere("=","ANT"))

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
 
  GO TOP
  
  SET DECI TO 2

  NT1:=SECONDS()

  WHILE !A->(EOF()) 

     // IF VENCE>=CTOD("01/09/2023") .AND. TIPO="ND" 
     // .and. "B-289"=ALLTRIM(A->CODMOVCLI)

     IF VENCE>=dFchIni .AND. TIPO="ND" 

       nContar++
 
       IF nContar%10=0
          SysRefresh(.T.)
       ENDIF
  
       
       // cNumero:=LEFT(B->NUMALB,2)+"00"+RIGHT(B->NUMALB,6)
       cNumero:=A->NUMDOC
       nValCam:=A->CAMBIO
       nMonto :=A->IMPORTE
       nMontoDiv:=A->IMPORTE/A->CAMBIO
       // nMonto :=ROUND(A->IMPORTE/A->CAMBIO,2)
       oDp:cNumero:=cNumero
       dFecha :=FCHINIMES(A->VENCE)
//     nValCam:=1

oDp:oFrameDp:SetText(LSTR(nContar)+" "+LSTR(nMonto)+"->$"+LSTR(nMontoDiv))

       // todos son anticipos Menores de 30 USD
       IF ABS(INT(nMonto))<30
         EJECUTAR("DPDOCCLICREA",NIL,"ANT",cNumero,A->CODMOVCLI,dFecha,oDp:cMonedaExt,"V",NIL,nMonto,IMP_IVA,nValCam,dFecha,NIL,oTable,"N",nCxC*-1)
// ? "no puede crear anticipo"
       ENDIF

       // genera la Cuota cuando es igual a 30 dolares
       IF INT(ABS(nMontoDiv))=30

          // nCxC:=0 // Estas Cuotas no podran ser facturadas, solo sirve para evitar que sean generadas en los meses futuros
          EJECUTAR("DPDOCCLICREA",NIL,cTipDoc,cNumero,A->CODMOVCLI,dFecha,oDp:cMonedaExt,"V",NIL,nMonto,IMP_IVA,nValCam,dFecha,NIL,oTable,"N",nCxC*0) // cuotas neutras
          SQLUPDATE("DPDOCCLI",{"DOC_TIPORG","DOC_CODTER"},{"MIX",oDp:cCodter},"DOC_TIPDOC"+GetWhere("=","CUO")+" AND DOC_NUMERO"+GetWhere("=",oDp:cNumero))
          EJECUTAR("DPMOVINVCREA",oDp:cSucursal,cTipDoc,cNumero,"CSSP",1,ABS(nMonto),"MENSUAL",1,0,"",VENCE,"V",dFecha,A->CODMOVCLI,"GN",0,nValCam,oMovInv)

// ? "aqui crea CUOTA anticipo",nMontoDiv,cNumero

       ENDIF
    
       IF ABS(INT(nMontoDiv))=60

          // SEPTIEMBRE
          EJECUTAR("DPDOCCLICREA",NIL,cTipDoc,cNumero,A->CODMOVCLI,dFecha,oDp:cMonedaExt,"V",NIL,nMonto/2,IMP_IVA,nValCam,VENCE,NIL,oTable,"N",nCxC*0) // cuotas neutras
          SQLUPDATE("DPDOCCLI",{"DOC_TIPORG","DOC_CODTER"},{"MIX",oDp:cCodter},"DOC_TIPDOC"+GetWhere("=","CUO")+" AND DOC_NUMERO"+GetWhere("=",oDp:cNumero))
          EJECUTAR("DPMOVINVCREA",oDp:cSucursal,cTipDoc,cNumero,"CSSP",1,ABS(nMonto/2),"MENSUAL",1,0,"",VENCE,"V",VENCE,A->CODMOVCLI,"GN",0,nValCam,oMovInv)

          // OCTUBRE
          EJECUTAR("DPDOCCLICREA",NIL,cTipDoc,cNumero,A->CODMOVCLI,FCHFINMES(dFecha)+1,oDp:cMonedaExt,"V",NIL,nMonto/2,IMP_IVA,nValCam,VENCE,NIL,oTable,"N",nCxC*0) // cuotas neutras
          SQLUPDATE("DPDOCCLI",{"DOC_TIPORG","DOC_CODTER"},{"MIX",oDp:cCodter},"DOC_TIPDOC"+GetWhere("=","CUO")+" AND DOC_NUMERO"+GetWhere("=",oDp:cNumero))
          EJECUTAR("DPMOVINVCREA",oDp:cSucursal,cTipDoc,cNumero,"CSSP",1,ABS(nMonto/2),"MENSUAL",1,0,"",FCHFINMES(dFecha)+1,"V",VENCE,A->CODMOVCLI,"GN",0,nValCam,oMovInv)

       ENDIF

       // 18/11/19
       // nPrecio:=nMonto/(1.16)
       // SQLUPDATE("DPMOVINV",{"MOV_ASOTIP","MOV_IVA","MOV_PRECIO","MOV_TOTAL","MOV_LISTA"},{"MIX",16,nPrecio,nPrecio,"A"},"MOV_TIPDOC"+GetWhere("=",cTipDoc)+" AND MOV_DOCUME"+GetWhere("=",cNumero))

    ENDIF

    SELECT A
   
    SKIP 

    IF nContar>5
     // EXIT
    ENDIF

  ENDDO

  SQLUPDATE("DPCLIENTES","CLI_CODMON","DBC")

  ? LSTR(nContar)+" Registros Migrados en "+LSTR(ABS(SECONDS()-nT1)/60)+" Minutos"

  cSql:=[ UPDATE DPMOVINV ]+;
        [ INNER JOIN DPDOCCLI      ON MOV_CODSUC=DOC_CODSUC AND MOV_TIPDOC=DOC_TIPDOC AND MOV_DOCUME=DOC_NUMERO AND DOC_TIPTRA='D'   AND DOC_VALCAM>0 ]+;
        [ SET MOV_MTODIV=ROUND(MOV_TOTAL/DOC_VALCAM,2), ]+;
        [ MOV_ASOTIP="MIX",MOV_IVA=16,MOV_PRECIO=DOC_BASNET,MOV_LISTA="A",MOV_FECHA=DOC_FECHA ]+;
        [ WHERE MOV_MTODIV=0 OR MOV_MTODIV=MOV_TOTAL OR MOV_MTODIV IS NULL ]

  oTable:Execute(cSql)

  oTable:EXECUTE("SET FOREIGN_KEY_CHECKS = 1")
  oTable:End()
  oMovInv:End()

RETURN .T.
// EOF
