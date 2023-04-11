// Programa   : MXCTAPROIMP
// Fecha/Hora : 01/01/2018 02:34:15
// Propósito  : Importar Productos desde MXCTAINV
// Creado Por : Juan Navas
// Llamado por: DPIMPRXLSRUN   
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN(cCodDef,lChk,lTodos,nCantid,oMemo,oMeterR,oSay,lBrowse)
   LOCAL cFileDbf,cFileXls,nLinIni
   LOCAL oPro,cGrupo,cMarca,cWhere,cLine,lOk,oEqui,cBarra,cMemoX:="",oSuc,oTable
   LOCAL aSelect:={},aCampos:={}
   LOCAL cField,nAt,n,aVar:={},cVar,cGruNombre:="",cMarNombre:="",oTable
   LOCAL cPrecio_A:="",cPrecio_B:="",cPrecio_C:="",cPrecio_D:="",cPrecio_E:="",cPrecio_L:=""
   LOCAL cUndMed:="",cPeso:="",cCXUNDMED:="",cPRESENTA:=""
   LOCAL cCANT  :="",cCOSTO:="",cLOTE:="",cFCHVENC:="",cCodSuc:="",cCodAlm:=""
   LOCAL cLIMSUC:="SI",cWhereS:="",oTabSuc
   LOCAL n_:=0,cMemo:="",cFileIxl:="",cTable,cCodigo
   LOCAL aFields:={},aVars:={}
  

   DEFAULT lChk   :=.F.,;
           lTodos :=.F.,;
           nCantid:=1  ,;
           lBrowse:=.F.

//  AEVAL(OpenTable("SELECT * FROM DPPROVEEDOR",.F.):aFields,{|a,n| cMemo:=cMemo+IF(n>1,CRLF,"")+[Replace("]+a[1] })
// ? cMemo
// cMemo:=""

   DEFAULT cCodDef:=SQLGET("DPIMPRXLS","IXL_CODIGO")

   IIF(oSay=NIL,NIL,oSay:SetText("Leyendo Datos desde "+cFileDbf))

   CLOSE ALL

   cFileDbf:="C:\MIXNET\MXCTAPRO.DBF" 

 
   SELE A
   USE (cFileDbf) SHARED

//   cMemo:=""
//   AEVAL(DBSTRUCT(),{|a,n| cMemo:=cMemo+IF(n>1,CRLF,"")+[Replace("PRO_XXXXXXX"]+",A->"+a[1]+") /"+"/"+a[2]+"("+LSTR(a[3])+")" })
// ? CLPCOPY(cMemo)
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

   SETEXCLUYE("DPPROVEEDOR"  , "")

 BROWSE()

//RETURN 
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

GO TOP
// oDp:lTracer:=.T.

   WHILE !A->(EOF()) 


MsgRun("Registro "+LSTR(RECNO())+"/"+LSTR(RECCOUNT()))
      cCodigo:=A->CODCLI
      cLine  :=""

      IF !oMererR=NIL
        oMeterR:Set(RECNO())  
      ENDIF

      IIF(oSay=NIL,NIL,oSay:SetText(LSTR(RECCO())+"/"+LSTR(RECNO())))

      // Asigna los Valores en el Objeto
      oPro :=OpenTable("SELECT * FROM DPPROVEEDOR",.F.)

      AEVAL(aFields,{|a,n| oPro:Replace(a[2],A->(FIELDGET(a[3])))})
      AEVAL(aVars  ,{|a,n| MOVER(A->(FIELDGET(a[3])),a[2])})

      oPro:Replace("PRO_ACTIVI",A->GRUPO)
      oPro:Replace("PRO_CODIGO",A->CODCLI) //C(10)
      oPro:Replace("PRO_NOMBRE",A->NOMCLI) //C(60)
      oPro:Replace("PRO_ACTIVI",A->GRUPO) //C(5)
      oPro:Replace("PRO_RIF"   ,A->CIF) //C(15)
      oPro:Replace("PRO_DIR1",A->DIREC1) //C(25)
      oPro:Replace("PRO_DIR2",A->DIREC2) //C(25)
      oPro:Replace("PRO_DIR3",A->DIREC3) //C(25)
      oPro:Replace("PRO_DIR4",A->DIREC4) //C(25)
      oPro:Replace("PRO_TEL1",A->TLF1) //C(15)
      oPro:Replace("PRO_TEL2",A->TLF2) //C(15)
      oPro:Replace("PRO_TEL4",A->FAX) //C(15)
//            oPro:Replace("PRO_XXXXXXX",A->ESTATUS) //C(2)
//            oPro:Replace("PRO_XXXXXXX",A->LIM_CRE) //N(9)
//            oPro:Replace("PRO_XXXXXXX",A->DIA_CRE) //N(3)
      oPro:Replace("PRO_DESC",A->DESCUENTO) //N(5)
      oPro:Replace("PRO_OBS1",A->OBSERVA) //C(52)
      oPro:Replace("PRO_OBS2",A->CONTACTO) //C(20)
//            oPro:Replace("PRO_XXXXXXX",A->ZONA) //C(8)
//            oPro:Replace("PRO_XXXXXXX",A->COBRADOR) //C(5)
//            oPro:Replace("PRO_XXXXXXX",A->VENDEDOR) //C(5)
//            oPro:Replace("PRO_XXXXXXX",A->SALDO) //N(19)
//            oPro:Replace("PRO_XXXXXXX",A->FEC_UPAG) //D(8)
      oPro:Replace("PRO_CTACON",A->CODCON) //C(20)
//            oPro:Replace("PRO_XXXXXXX",A->TOT_VEN) //N(19)
//            oPro:Replace("PRO_XXXXXXX",A->REGIMEN) //C(1)
//            oPro:Replace("PRO_XXXXXXX",A->FORMA) //C(2)
//            oPro:Replace("PRO_XXXXXXX",A->BANCO) //C(5)
//            oPro:Replace("PRO_XXXXXXX",A->CTABANCO) //C(15)
      oPro:Replace("PRO_NIT",A->NIT) //C(15)
      oPro:Replace("PRO_FECHA",A->FECHAING) //D(8)
      oPro:Replace("PRO_EMAIL",A->EMAIL) //C(50)
//              oPro:Replace("PRO_XXXXXXX",A->FECHA_MOD) //D(8)
//              oPro:Replace("PRO_XXXXXXX",A->HORA_MOD) //C(6)
      oPro:Replace("PRO_PORIVA",A->PORRIVA) //N(6)
//      oPro:Replace("PRO_XXXXXXX",A->REGMERC) //C(1)
//      oPro:Replace("PRO_XXXXXXX",A->TPROV) //C(2)
      oPro:Replace("PRO_ESTADO",IF(A->INACTIVO,"ACTIVO","INACTIVO")) //L(1)

      oPro:Replace("PRO_ACTIVI" ,BUILDACTIVI(oTable:PRO_ACTIVI))

      oPro:Replace("PRO_CODCLA",SQLGET("DPPROCLA","CLP_CODIGO"))
      oPro:Replace("PRO_TIPO"  ,"Proveedor")
      oPro:Replace("PRO_CODRMU",SQLGET("DPRETMUNTARIFA","TRM_CODIGO"))

      cWhere:="PRO_CODIGO"+GetWhere("=",cCodigo)

      IF Empty(cCodigo)
         cline:="Código Vacio"
      ENDIF

      IF !Empty(cLine)

         lOk:=.F.

         IIF(oMemo=NIL,NIL, oMemo:Append(cLine+CRLF))
         cMemoX  :=cMemoX+IF(Empty(cLine),CRLF,"")+cLine

         A->(DbSkip())
         LOOP

      ENDIF

      cWhere:="PRO_CODIGO"+GetWhere("=",cCodigo)
      oTable:=OpenTable("SELECT * FROM DPPROVEEDOR WHERE "+cWhere,.T.)

      cLine:=CRLF+IIF(oTable:RecCount()=0,"I:","M:")+ALLTRIM(cCodigo)+;
             IF(Empty(cBarra)," "," B:" +ALLTRIM(cBarra))

      IF oTable:RecCount()=0
   
         cWhere:=""
         oTable:AppendBlank()

      ENDIF

      IF(oMemo=NIL,NIL,oMemo:Append(cLine))
      cMemoX  :=cMemoX+cLine

      AEVAL(oTable:aFields,{|a,n| oTable:FieldPut(n,oPro:FieldGet(n)) })

      oTable:Replace("PRO_CODIGO",cCodigo)
      oTable:Replace("PRO_USUARI","MIX"  )  
      
      // Si esta en Revision, No agrega producto

      IF !lChk
         oTable:Commit(cWhere)
      ENDIF

      oTable:End()

      oPro:End()

      A->(DbSkip())

// IF RECNO()>5
//   EXIT
// ENDIF

   ENDDO

   IF(oMemo=NIL,NIL,oMemo:Append(CRLF+"Proceso Concluido"))
 
   EJECUTAR("DPBUILDWHERE")

   CLOSE ALL
  
RETURN lOk

/*
// Genera Actividad Econ¢mica
*/
FUNCTION BUILDACTIVI(cNombre)
  LOCAL cCodigo,oTable

  IF !Empty(cCodigo)

     cCodigo:=SQLGET("DPACTIVIDAD_E","ACT_CODIGO","ACT_DESCRI"+GETWHERE("=",cNombre))

     IF !EMPTY(cCodigo)
       RETURN cCodigo
     ENDIF

  ENDIF

  cCodigo:=SQLINCREMENTAL("DPACTIVIDAD_E","ACT_CODIGO")

  IF !ISSQLFIND("DPACTIVIDAD_E","ACT_CODIGO"+GetWhere("=",cCodigo))
    oTable:=OpenTable("SELECT * FROM DPACTIVIDAD_E",.F.)
    oTable:AppendBlank()
    oTable:Replace("ACT_CODIGO",cCodigo)
    oTable:Replace("ACT_DESCRI",cNombre)
    oTable:Replace("ACT_COMEN1","Desde DP20")
    oTable:Commit()
    oTable:End()
  ENDIF


RETURN cCodigo


// EOF


