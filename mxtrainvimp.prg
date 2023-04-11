// Programa   : MXTRAINVIMP
// Fecha/Hora : 01/01/2018 02:34:15
// Propósito  : Importar Productos desde MXCTAINV
// Creado Por : Juan Navas
// Llamado por: DPIMPRXLSRUN   
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN(cCodDef,lChk,lTodos,nCantid,oMemo,oMeterR,oSay,lBrowse,cDir)
   LOCAL cFileDbf,cFileXls,nLinIni
   LOCAL oMov,cGrupo,cMarca,cWhere,cLine,lOk,oEqui,cBarra,cMemoX:="",oSuc,oTable
   LOCAL aSelect:={},aCampos:={}
   LOCAL cField,nAt,n,aVar:={},cVar,cGruNombre:="",cMarNombre:="",oTable
   LOCAL cPrecio_A:="",cPrecio_B:="",cPrecio_C:="",cPrecio_D:="",cPrecio_E:="",cPrecio_L:=""
   LOCAL cUndMed:="",cPeso:="",cCXUNDMED:="",cPRESENTA:=""
   LOCAL cCANT  :="",cCOSTO:="",cLOTE:="",cFCHVENC:="",cCodSuc:="",cCodAlm:=""
   LOCAL cLIMSUC:="SI",cWhereS:="",oTabSuc
   LOCAL n_:=0,cMemo:="",cFileIxl:="",cTable,cCodigo,cTipo
   LOCAL aFields:={},aVars:={}
  

   DEFAULT lChk   :=.F.,;
           lTodos :=.F.,;
           nCantid:=1  ,;
           lBrowse:=.F.,;
           cDir   :="C:\MIXNET\"

//  AEVAL(OpenTable("SELECT * FROM DPPROVEEDOR",.F.):aFields,{|a,n| cMemo:=cMemo+IF(n>1,CRLF,"")+[Replace("]+a[1] })
// ? cMemo
// cMemo:=""

   DEFAULT cCodDef:=SQLGET("DPIMPRXLS","IXL_CODIGO")

   IIF(oSay=NIL,NIL,oSay:SetText("Leyendo Datos desde "+cFileDbf))

   CLOSE ALL

   cFileDbf:=cDir+"MXTRAINV.DBF" 

   IF !FILE(cFileDbf)
      MensajeErr("Archivo "+cFileDbf+" no Existe")
      RETURN .F.
   ENDIF
 
   SELE A
   USE (cFileDbf) SHARED

   cMemo:=""
   AEVAL(DBSTRUCT(),{|a,n| cMemo:=cMemo+IF(n>1,CRLF,"")+[    oMov:Replace("MOV_XXXXXXX"]+",A->"+a[1]+") /"+"/"+a[2]+"("+LSTR(a[3])+")" })
// ? CLPCOPY(cMemo)
// BROWSE()
// CLOSE ALL
// RETURN

   IF RECCOUNT()=0
      MensajeErr("No se realizó la Lectura de Registros, Revise Número de Línea de Lectura")
      CLOSE ALL
      nLinIni++
//    oLinIni:VarPut(nLinIni,.T.) 
      RETURN .F.
   ENDIF

  
   IF lBrowse 
     BROWSE()
     CLOSE ALL
     RETURN NIL
   ENDIF

   cMemoX:="Iniciando Importación"+CRLF+"Leyenda "+CRLF+"I:Incluir M:Modificar B:Barra"

   IIF(oMemo=NIL,NIL,oMemo:VarPut(cMemoX,.T.))

   IF Empty(ALIAS()) .AND. ValType(oMemo)="O"
      oMemo:Append("Archivo "+cFileDbf)
      RETURN .F.
   ENDIF

   IF !oMeterR=NIL
     oMeterR:SetTotal(RECCO())
   ENDUF

   aCampos:=ACLONE(DBSTRUCT())

   AEVAL(aCampos,{|a,n|aCampos[n]  :=ALLTRIM(a[1])})
   AEVAL(aSelect,{|a,n|aSelect[n,3]:=ALLTRIM(a[3])})

   SETEXCLUYE("DPMOVINV"  , "")

   SQLDELETE("DPMOVINV","MOV_USUARI"+GetWhere("=","MIX"))

   BROWSE()

// RETURN 
/*
   AADD(aFields,{"CODART","INV_CODIGO"})
   AADD(aFields,{"NOMART","INV_DESCRI"})
   AADD(aFields,{"GRUPO" ,"INV_GRUPO"})
   AEVAL(aFields,{|a,n| AADD(aFields[n],FIELDPOS(a[1]))})

   AADD(aVars  ,{"PRECIO_A"  ,"cPrecio_A"})
   AADD(aVars  ,{"PRECIO_D"  ,"cPrecio_D"})
   AADD(aVars  ,{"ULT_COSTO" ,"cCosto"   })
   AADD(aVars  ,{"EXISTE_ACT","cCant"    })
   AADD(aVars  ,{"ALTERNO"   ,"cBarra"   })

   AEVAL(aVars,{|a,n| AADD(aVars[n],FIELDPOS(a[1])),PUBLICO(a[2],NIL)}) 
*/

// SET FILTER TO A->CODMOVART<>""
// GO TOP
// BROWSE()
// ? "AQUI ES"
// GO TOP

// RETURN NIL
// oDp:lTracer:=.T.

  oMov:=OpenTable("SELECT * FROM DPMOVINV",.F.)
  oMov:SetForeignkeyOff()

   WHILE !A->(EOF()) 

       IF Empty(A->CODMOVART)
           A->(DbSkip())
           LOOP
       ENDIF

CursorWait()

       IF A->(RECNO())%50=0
          MsgRun("Registro "+LSTR(RECNO())+"/"+LSTR(RECCOUNT()))
       ENDIF

//      cCodigo:=A->CODCLI
      cLine  :=""

//      IF !oMererR=NIL
//        oMeterR:Set(RECNO())  
//      ENDIF

      IIF(oSay=NIL,NIL,oSay:SetText(LSTR(RECCO())+"/"+LSTR(RECNO())))

      // Asigna los Valores en el Objeto
      

      AEVAL(aFields,{|a,n| oMov:Replace(a[2],A->(FIELDGET(a[3])))})
      AEVAL(aVars  ,{|a,n| MOVER(A->(FIELDGET(a[3])),a[2])})

      cTipo:=A->TIPINV
      cTipo:=IF(cTipo="EN","E001","S001")

      IF A->TIPINV="DV"
         cTipo:="E001"
      ENDIF

    oMov:AppendBlank()
    oMov:Replace("MOV_CODIGO" ,A->CODMOVART) //C(15)
    oMov:Replace("MOV_FECHA"  ,A->FECHA_MOV) //D(8)
    oMov:Replace("MOV_HORA"   ,A->HORA)   //C(6)
    oMov:Replace("MOV_CODTRA"   ,cTipo)   //C(2)
    oMov:Replace("MOV_TIPDOC" ,A->ORIGEN) //C(2)

    oMov:Replace("MOV_DOCUME" ,A->NUMDOC) //C(10)
    oMov:Replace("MOV_UNDMED" ,"UND") // A->UNIDAD) //C(3)
//  oMov:Replace("MOV_XXXXXXX",A->REF_BULTO) //N(5)
    oMov:Replace("MOV_CANTID" ,A->CANTIDAD) //N(14)
    oMov:Replace("MOV_COSTO"  ,A->COSTO_TOT) //N(19)
    oMov:Replace("MOV_ORIGEN" ,A->ORIGEN) //C(3)
    oMov:Replace("MOV_CODCTA" ,A->PROV_CLI) //C(10)
    oMov:Replace("MOV_TOTAL"  ,A->VENTA_TOT) //N(17)
    oMov:Replace("MOV_APLORG" ,A->ORIGEN)
    oMov:Replace("MOV_CXUND",1)

    oMov:Replace("MOV_CODALM",oDp:cCodAlm)
    oMov:Replace("MOV_CODSUC",oDp:cSucursal)
    oMov:Replace("MOV_INVACT",1)
    oMov:Replace("MOV_FISICO",IF(LEFT(cTipo,1)="E" ,1,-1))
    oMov:Replace("MOV_LOGICO",IF(LEFT(cTipo,1)="E" ,1,-1))
    oMov:Replace("MOV_CONTAB",IF(LEFT(cTipo,1)="E" ,1,-1))
    oMov:Replace("MOV_METCOS","P")
     oMov:Replace("MOV_ASOTIP",A->TIPINV)

//    oMov:Replace("MOV_XXXXXXX",A->CODVEN) //C(5)
//    oMov:Replace("MOV_XXXXXXX",A->ALMACEN) //C(2)
//    oMov:Replace("MOV_XXXXXXX",A->ASIENTO) //C(8)
//    oMov:Replace("MOV_XXXXXXX",A->FECHA_ASI) //D(8)
//    oMov:Replace("MOV_XXXXXXX",A->CODCON) //C(20)
//    oMov:Replace("MOV_XXXXXXX",A->CODDPTO) //C(10)
//    oMov:Replace("MOV_XXXXXXX",A->CAMBIO) //N(10)
//    oMov:Replace("MOV_XXXXXXX",A->MONEDA) //C(3)

      oMov:Replace("MOV_USUARI","MIX"  )  
      oMov:Commit()
      
      // Si esta en Revision, No agrega producto

      A->(DbSkip())

      IF RECNO()%5=0
         SysRefresh(.T.)
      ENDIF

// IF RECNO()>5
//   EXIT
// ENDIF

   ENDDO

   oMov:End()

   IF(oMemo=NIL,NIL,oMemo:Append(CRLF+"Proceso Concluido"))
 
   EJECUTAR("DPBUILDWHERE")

   CLOSE ALL
  
RETURN lOk

// EOF

