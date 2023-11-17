// Programa   : IMPORTANTMIX        
// Fecha/Hora : 29/08/2020 23:04:32
// Propósito  : Importar Anticipos desde MIXNET Caso del Club, Importa Como Cuotas aquellos montos =30 o 60 USD
// Creado Por : Juan Navas
// Llamado por:
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN(cFile,lDelete)
  LOCAL aData:={},aLine:={},nContar:=0,dFecha
  LOCAL oMovInv,oTable,nCxC,cTipDoc:="CUO",nPrecio,cNumero,nMonto,nValCam,NT1

  DEFAULT cFile  :="C:\MIXCLUB\COMP01\mxtrapag.dbf",;
          lDelete:=.f.

  IF !FILE(cFile)
    ? cFile,"NO EXISTE"
    RETURN .T.
  ENDIF

  IF COUNT("DPCLIENTES")<=1
     EJECUTAR("IMPORTMXCLI")  
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
 
  GO TOP

  NT1:=SECONDS()

  WHILE !A->(EOF()) 

     IF VENCE>=CTOD("01/09/2023") .AND. TIPO="ND" 

       // .and. "B-289"=ALLTRIM(A->CODMOVCLI)

       nContar++
 
       IF nContar%10=0
          SysRefresh(.T.)
       ENDIF
  
       
       // cNumero:=LEFT(B->NUMALB,2)+"00"+RIGHT(B->NUMALB,6)
       cNumero:=A->NUMDOC
       nValCam:=A->CAMBIO
       nMonto :=ROUND(A->IMPORTE/A->CAMBIO,2)
       oDp:cNumero:=cNumero
       dFecha :=FCHINIMES(A->VENCE)
//     nValCam:=1

oDp:oFrameDp:SetText(LSTR(nContar)+" "+LSTR(nMonto))

       // todos son anticipos Menores de 30 USD
       IF ABS(INT(nMonto))<30
         EJECUTAR("DPDOCCLICREA",NIL,"ANT",cNumero,A->CODMOVCLI,dFecha,oDp:cMonedaExt,"V",NIL,nMonto,IMP_IVA,nValCam,dFecha,NIL,oTable,"N",nCxC*-1)
// ? "no puede crear anticipo"
       ENDIF

       // genera la Cuota cuando es igual a 30 dolares
       IF INT(nMonto)=-30
          EJECUTAR("DPDOCCLICREA",NIL,cTipDoc,cNumero,A->CODMOVCLI,dFecha,oDp:cMonedaExt,"V",NIL,nMonto,IMP_IVA,nValCam,dFecha,NIL,oTable,"N",nCxC*0) // cuotas neutras
          SQLUPDATE("DPDOCCLI",{"DOC_TIPORG","DOC_CODTER"},{"MIX",oDp:cCodter},"DOC_TIPDOC"+GetWhere("=","CUO")+" AND DOC_NUMERO"+GetWhere("=",oDp:cNumero))
          EJECUTAR("DPMOVINVCREA",oDp:cSucursal,cTipDoc,cNumero,"CSSP",1,ABS(nMonto),"MENSUAL",1,0,"",VENCE,"V",dFecha,A->CODMOVCLI,"GN",0,nValCam,oMovInv)
       ENDIF
    
       IF INT(nMonto)=-60

          // SEPTIEMBRE
          EJECUTAR("DPDOCCLICREA",NIL,cTipDoc,cNumero,A->CODMOVCLI,dFecha,oDp:cMonedaExt,"V",NIL,nMonto/2,IMP_IVA,nValCam,VENCE,NIL,oTable,"N",nCxC*0) // cuotas neutras
          SQLUPDATE("DPDOCCLI",{"DOC_TIPORG","DOC_CODTER"},{"MIX",oDp:cCodter},"DOC_TIPDOC"+GetWhere("=","CUO")+" AND DOC_NUMERO"+GetWhere("=",oDp:cNumero))
          EJECUTAR("DPMOVINVCREA",oDp:cSucursal,cTipDoc,cNumero,"CSSP",1,ABS(nMonto/2),"MENSUAL",1,0,"",VENCE,"V",VENCE,A->CODMOVCLI,"GN",0,nValCam,oMovInv)

          // OCTUBRE
          EJECUTAR("DPDOCCLICREA",NIL,cTipDoc,cNumero,A->CODMOVCLI,FCHFINMES(dFecha)+1,oDp:cMonedaExt,"V",NIL,nMonto/2,IMP_IVA,nValCam,VENCE,NIL,oTable,"N",nCxC*0) // cuotas neutras
          SQLUPDATE("DPDOCCLI",{"DOC_TIPORG","DOC_CODTER"},{"MIX",oDp:cCodter},"DOC_TIPDOC"+GetWhere("=","CUO")+" AND DOC_NUMERO"+GetWhere("=",oDp:cNumero))
          EJECUTAR("DPMOVINVCREA",oDp:cSucursal,cTipDoc,cNumero,"CSSP",1,ABS(nMonto/2),"MENSUAL",1,0,"",FCHFINMES(dFecha)+1,"V",VENCE,A->CODMOVCLI,"GN",0,nValCam,oMovInv)

       ENDIF

       nPrecio:=nMonto/(1.16)
       SQLUPDATE("DPMOVINV",{"MOV_ASOTIP","MOV_IVA","MOV_PRECIO","MOV_TOTAL","MOV_LISTA"},{"MIX",16,nPrecio,nPrecio,"A"},"MOV_TIPDOC"+GetWhere("=",cTipDoc)+" AND MOV_DOCUME"+GetWhere("=",cNumero))

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

RETURN .T.
// EOF
